/**
 * @Description       : 
 * @Author            : Varun Rajpoot
 * @last modified on  : 01-16-2024
 * @last modified by  : Varun Rajpoot 
 * Modifications Log
 * Ver   Date         Author          Modification
 * 1.0   01-16-2024   Varun Rajpoot   Initial Version
**/
@isTest
public class AutoApprovalEventTriggerTest {
    
    @TestSetup static void createData(){
    	Account acc = new TestAccountBuilder()
            .setRecordTypeId(Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business_Account').getRecordTypeId())
            .getSavedTestRecord();
        
        Address__c addr = createPrimaryAddress();
        addr.Name__c = acc.Name.toUpperCase();
        insert addr;
        
        acc.Primary_Address__c = addr.id;
        acc.Business_Unit__c = GlobalConstants.INTERIO_BUSINESS_UNIT;
        acc.Name.toUpperCase();
        update acc;
            
        //Create Opportunity
        Opportunity opp = new Opportunity(Name = 'Test Opportunity', AccountId = acc.Id, StageName = 'Qualification');
        opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Interio_B2C_Appliances').getRecordTypeId();
        //opp.Pricebook2Id = pricebookRecord.Id;
        opp.Business_Unit__c = GlobalConstants.INTERIO_BUSINESS_UNIT;
        opp.CloseDate = (Date.today()).addMonths(10);
        //opp.Sales_Branch_Name__c = userToRun.Logistic_Company__c;
        insert opp;
        
        // Create User with manager records.
        User level4Manager = createUserRecord(null, 'level4Manager');
        User level3Manager = createUserRecord(level4Manager.Id, 'level3Manager');
        User level2Manager = createUserRecord(level3Manager.Id, 'level2Manager');
        User level1Manager = createUserRecord(level2Manager.Id, 'level1Manager');
        User userToRun = createUserRecord(level1Manager.Id, 'loggedIn');
        
        System.runAs(userToRun) {
        Quote quoteRecord = new Quote();
        quoteRecord.Quantity__c = 1;
        quoteRecord.OpportunityId = opp.Id;
        quoteRecord.RecordTypeId = Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get('Interio_B2C_VFD').getRecordTypeId();
        quoteRecord.Name = 'Quote -'+ system.today();
        insert quoteRecord;
        }
    }
    
    //Test that records are auto-approved where required such as this scenario for Interio_B2C_VFD
	@isTest
    private static void testAutoApproval(){
        List<Quote> quotes = [Select Id, RecordTypeId, CreatedById, Record_Type_Developer_Name__c,
                              Transaction_Type__c, OpportunityId  
                              FROM Quote];
        
        PricingApprovalRequestRecordCreator parCreator = new PricingApprovalRequestRecordCreator();
        parCreator.createPricingApprovalRequestRecord(quotes);
        
        List<Pricing_approval_request__c> pars = [SELECT Id FROM Pricing_approval_request__c WHERE Quote__c IN :quotes];
        
        Test.startTest();
    	//Create an approval request for the change
    	Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
    	req1.setComments('Submitting request for approval.');
    	req1.setObjectId(pars[0].Id);
    	req1.setNextApproverIds(new Id[] {UserInfo.getUserId()});
    	
    	//Submit the approval request for the change
    	Approval.ProcessResult result = Approval.process(req1);
    	
    	//Verify the result
    	System.assert(result.isSuccess());

        
        Auto_Approval_Event__e autoApproval = new Auto_Approval_Event__e();
        autoApproval.Pricing_Approval_Request_Id__c = pars[0].Id;
        autoApproval.Quote_ID__c = quotes[0].Id;
        autoApproval.Related_Quote_Record_Type_ID__c = quotes[0].Record_Type_Developer_Name__c;
        Database.SaveResult sr = EventBus.publish(autoApproval);
        Test.stopTest();	
        list<ProcessInstanceStep > lstAutoApproval=[SELECT Id,StepStatus FROM ProcessInstanceStep 
                                                        WHERE ProcessInstance.TargetObjectId=:pars[0].Id
                                                        AND StepStatus = 'Approved'];
        System.assertEquals(true, lstAutoApproval.size()>0, 'Step should be auto approved');
    }
    
    
    //Test that records being assigned are not auto-approved
	@isTest
    private static void testAssignment(){
        List<Quote> quotes = [Select Id, RecordTypeId, CreatedById, Record_Type_Developer_Name__c,
                              Transaction_Type__c, OpportunityId  
                              FROM Quote];
        //quotes[0].Quantity__c = 3;
        quotes[0].Product_Type__c = 'Home Storage';
        update quotes[0];

        PricingApprovalRequestRecordCreator parCreator = new PricingApprovalRequestRecordCreator();
        parCreator.createPricingApprovalRequestRecord(quotes);
        
        List<Pricing_approval_request__c> pars = [SELECT Id FROM Pricing_approval_request__c WHERE Quote__c IN :quotes];
        Test.startTest();

    	//Create an approval request for the change
    	Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
    	req1.setComments('Submitting request for approval.');
    	req1.setObjectId(pars[0].Id);
    	req1.setNextApproverIds(new Id[] {UserInfo.getUserId()});
    	
    	//Submit the approval request for the change
    	Approval.ProcessResult result = Approval.process(req1);
    	
    	//Verify the result
    	System.assert(result.isSuccess());
        
        pars[0].Approval_Status__c = 'Approved';
        update pars[0];

        
        Auto_Approval_Event__e autoApproval = new Auto_Approval_Event__e();
        autoApproval.Pricing_Approval_Request_Id__c = pars[0].Id;
        autoApproval.Quote_ID__c = quotes[0].Id;
        autoApproval.Related_Quote_Record_Type_ID__c = quotes[0].Record_Type_Developer_Name__c;
        Database.SaveResult sr = EventBus.publish(autoApproval);
        Test.stopTest();	
        
        list<ProcessInstanceStep > lstAutoApproval=[SELECT Id,StepStatus FROM ProcessInstanceStep 
                                                        WHERE ProcessInstance.TargetObjectId=:pars[0].Id
                                                        AND StepStatus = 'Approved'];
        System.assertEquals(true, lstAutoApproval.size()>0, 'Step should be approved');

    }
    
    //Test that records being reassigned are not auto-approved
	@isTest
    private static void testReassignment(){
        List<Quote> quotes = [Select Id, RecordTypeId, CreatedById, Record_Type_Developer_Name__c,
                              Transaction_Type__c, OpportunityId  
                              FROM Quote];
        quotes[0].Quantity__c = 3;
        update quotes[0];

        PricingApprovalRequestRecordCreator parCreator = new PricingApprovalRequestRecordCreator();
        parCreator.createPricingApprovalRequestRecord(quotes);
        
        List<Pricing_approval_request__c> pars = [SELECT Id FROM Pricing_approval_request__c WHERE Quote__c IN :quotes];
        Test.startTest();

    	//Create an approval request for the change
    	Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
    	req1.setComments('Submitting request for approval.');
    	req1.setObjectId(pars[0].Id);
    	req1.setNextApproverIds(new Id[] {UserInfo.getUserId()});
    	//Submit the approval request for the change
    	Approval.ProcessResult result = Approval.process(req1);
    	//Verify the result
    	System.assert(result.isSuccess());
       
        
        Auto_Approval_Event__e autoApproval = new Auto_Approval_Event__e();
        autoApproval.Pricing_Approval_Request_Id__c = pars[0].Id;
        autoApproval.Quote_ID__c = quotes[0].Id;
        autoApproval.Related_Quote_Record_Type_ID__c = quotes[0].Record_Type_Developer_Name__c;
        Database.SaveResult sr = EventBus.publish(autoApproval);
        Test.stopTest();	
        
        list<ProcessInstanceStep > lstAutoApproval=[SELECT Id,StepStatus FROM ProcessInstanceStep 
                                                        WHERE ProcessInstance.TargetObjectId=:pars[0].Id
                                                        AND StepStatus = 'Approved'];
        System.assertEquals(true, lstAutoApproval.size()==0, 'Step should Not be auto approved');

    }

    //Test that the method ruleEvaluator() evaluates expressions correctly
	@isTest
    private static void testRuleEvaluator(){
        
        Pricing_approval_request__c par = new Pricing_approval_request__c();
        par.Approval_Status__c = 'Approval Required';
        par.Submitter_Hierarchy_Level__c = 3;
        
        Test.startTest();

        System.assertEquals(true, DynamicApprovalAssignmentHelper.ruleEvaluator(createApprovalAssignment('Approval_Status__c', 'Text', '=', 'Approval Required'), par));
        System.assertEquals(true,DynamicApprovalAssignmentHelper.ruleEvaluator(createApprovalAssignment('Approval_Status__c', 'Text', '!=', 'Approval'), par));
        
        System.assertEquals(true,DynamicApprovalAssignmentHelper.ruleEvaluator(createApprovalAssignment('Approval_Status__c', 'Multiselect', 'Contains', 'Approval'), par));
        
        System.assertEquals(true,DynamicApprovalAssignmentHelper.ruleEvaluator(createApprovalAssignment('Submitter_Hierarchy_Level__c', 'Decimal', '=', '3'), par));
        System.assertEquals(true,DynamicApprovalAssignmentHelper.ruleEvaluator(createApprovalAssignment('Submitter_Hierarchy_Level__c', 'Decimal', '>=', '3'), par));
        System.assertEquals(true,DynamicApprovalAssignmentHelper.ruleEvaluator(createApprovalAssignment('Submitter_Hierarchy_Level__c', 'Decimal', '<=', '3'), par));
        System.assertEquals(true,DynamicApprovalAssignmentHelper.ruleEvaluator(createApprovalAssignment('Submitter_Hierarchy_Level__c', 'Decimal', '>', '2'), par));
        System.assertEquals(true,DynamicApprovalAssignmentHelper.ruleEvaluator(createApprovalAssignment('Submitter_Hierarchy_Level__c', 'Decimal', '<', '5'), par));

        System.assertEquals(true,DynamicApprovalAssignmentHelper.ruleEvaluator(createApprovalAssignment('Submitter_Hierarchy_Level__c', 'Number', '=', '3'), par));
        System.assertEquals(true,DynamicApprovalAssignmentHelper.ruleEvaluator(createApprovalAssignment('Submitter_Hierarchy_Level__c', 'Number', '>=', '3'), par));
        System.assertEquals(true,DynamicApprovalAssignmentHelper.ruleEvaluator(createApprovalAssignment('Submitter_Hierarchy_Level__c', 'Number', '<=', '3'), par));
        System.assertEquals(true,DynamicApprovalAssignmentHelper.ruleEvaluator(createApprovalAssignment('Submitter_Hierarchy_Level__c', 'Number', '>', '2'), par));
        System.assertEquals(true,DynamicApprovalAssignmentHelper.ruleEvaluator(createApprovalAssignment('Submitter_Hierarchy_Level__c', 'Number', '<', '5'), par));

        Test.stopTest();	

    }

    //Helper to create scenarios for ruleEvaluator; returns desired Approval_Assignment__mdt
    private static Approval_Assignment__mdt createApprovalAssignment(String sField, String sFieldType, String sOperator, String sValue){
     Approval_Assignment__mdt appAssignment = new Approval_Assignment__mdt();
     appAssignment.Criteria_Field__c = sField;
     appAssignment.Criteria_Field_Type__c = sFieldType;
     appAssignment.Criteria_Operator__c = sOperator;
     appAssignment.Criteria_Value__c = sValue;

     return appAssignment;
        
    }
    
    //Helper to create user hierarchy
    private static user createUserRecord(Id managerUserId, String userNameAddOnString){
        //Fetch System Profile
        Profile userProfile = [Select Id from Profile where Name = 'System Administrator' LIMIT 1];
        
        // Create User records.
        User userRec = new User(EmailEncodingKey = 'UTF-8', firstName = 'Test', lastname = 'User', Alias = 'tuser',
                            languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = userProfile.id,
                            timezonesidkey = 'Asia/Kolkata', email = 'test.user@godrej.com',  Business_Unit__c = GlobalConstants.MHE_DIVISION_CODE);

        userRec.Persona__c = 'MHE Sales-KAM';
        userRec.Sub_Division__c = 'B2B';
        userRec.Logistic_Company__c = '5020';
        userRec.Area_Code__c = 'WN1';
        userRec.ManagerId = managerUserId;
        userRec.username = 'test.user5@godrej.com';
        
        if(String.isNotBlank(userNameAddOnString))
        userRec.username = 'test.user5@godrej.com.'+userNameAddOnString;
       
        insert userRec;
        
        return userRec;
    }

    //Helper to create Primary Address
    private static Address__c createPrimaryAddress(){
        ZipCode__c zipcd = new ZipCode__c(City_Name__c ='citytst', StateName__c = 'sttetst', name='zpcdtst');
        insert zipcd;
        Address__c addr = new Address__c(Street__c='strttst',ZipCode__c = zipcd.id);
        return addr;
    }
}