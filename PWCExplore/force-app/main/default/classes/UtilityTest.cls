@isTest
public class UtilityTest {
    
    @testSetup
    public static void createData(){
        Profile userProfile = [Select Id from Profile where Name = 'System Administrator' LIMIT 1];
        // Create User record.
        User member = new User(EmailEncodingKey = 'UTF-8', firstName = 'Test', lastname = 'User interio', Alias = 'tuser',
                            languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = userProfile.id,
                            timezonesidkey = 'Asia/Kolkata', email = 'test.user@godrej.com', username = 'test.user@godrej.com', Business_Unit__c = GlobalConstants.INTERIO_BUSINESS_UNIT);

        member.Persona__c = 'InterioVFD- Dealer';
        member.Interio_Sub_Division__c = 'VFD';
        member.Logistic_Company__c = '2000';
        member.Area_Code__c = 'WN1';
        insert member;
        
        insertQueuesAndQueueMembers(member.Id);
        
        System.runAs(member){
            Pricebook2 standardPricebook = new Pricebook2(Id = Test.getStandardPricebookId(), IsActive = true );
            standardPricebook.PriceList_Code__c = 'SP1';
            standardPricebook.LN_PriceList_Code__c = 'SP1';
            update standardPricebook;
            
            Id leadB2BRecordTypeId=Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Interio_MHE_SSG_B2B').getRecordTypeId();
            Lead Ld = new Lead();
            ld.RecordTypeId=leadB2BRecordTypeId;
            Ld.LastName='Rao test';
            Ld.Age__c='21-30';
            Ld.MobilePhone= '9561378400';
            Ld.How_did_the_customer_find_the_store_loca__c= 'Just Dial';
            Ld.Source_of_Awareness__c='Exhibitions';
            Ld.LeadSource='Email';
            Ld.Business_Unit__c= 'W';
            Ld.Status='New';
            Ld.Company__c='test comp';
            //Ld.Interio_Sub_Division__c='B2B';
            //ld.segment__C = 'NA';
            ld.sub_division__C = 'B2B';
            //ld.Business_Unit__c 
        insert Ld;
        }
    }
    
    public static void insertQueuesAndQueueMembers(id memberId){
        Group interioQueue = new Group(Name='test interio queue', type='Queue');
        insert interioQueue;
        QueuesObject queueType = new QueueSObject(QueueID = interioQueue.id, SobjectType = 'Lead');
        insert queueType;
        
        GroupMember grpMember = new GroupMember();
		grpMember.UserOrGroupId = memberId;
		grpMember.GroupId = interioQueue.Id;

		insert grpMember;
    }
    
    @isTest
    public static void testRecordLockCheck(){
        Id leadId=[Select Id From Lead where Name='Rao test' Limit 1].Id;
        Map<Id,Boolean> idVsIfLocked=Utility.recordLockCheck(new List<Id>{leadId});
        System.assertEquals(0, idVsIfLocked.size());
    }
    
    @isTest
    public static void testFetchStandardPriceBookDetail(){
        Utility u=new Utility();
        List<Pricebook2> pricebookList = u.fetchStandardPriceBookDetail();
        System.assertNotEquals(0, pricebookList.size());
    }
    
    @isTest
    public static void testFetchRecordTypeId(){
        Utility u=new Utility();
        Id recordTypeId =u.fetchRecordTypeId('Lead','Interio_MHE_SSG_B2B');
        System.assertNotEquals(null, recordTypeId);
    }
    
    @isTest
    public static void testFetchRecordTypes(){
        Utility u=new Utility();
        System.assertNotEquals(0, u.fetchRecordTypes('Lead').size());
    }
    
    @isTest
    public static void testGetPicklistValues(){
        System.assertNotEquals(0, Utility.getPicklistValues('Lead','Business_Unit__c').size());
    }
    
    @isTest
    public static void testGetQueueNameVsIds(){
        Set<String> queueNames=new Set<String>();
        for(Group g:[Select Id,DeveloperName,Name From Group where Type='Queue' And Name='test interio queue']){
            queueNames.add(g.DeveloperName);
        }
        System.assertNotEquals(0, Utility.getQueueNameVsIds(queueNames).size());
    }
    
    @isTest
    public static void testGetQueueMembers(){
        Set<String> queueNames=new Set<String>();
        queueNames.add('test queue 2');
        for(Group g:[Select Id,DeveloperName From Group where Type='Queue' And Name='test interio queue']){
            queueNames.add(g.DeveloperName);
        }
        System.assertNotEquals(0, Utility.getQueueMembers(queueNames).size());
    }
    
    @isTest
    public static void testGetOutOfOfficeAndInactiveUsers(){
        System.assertEquals(0, Utility.getOutOfOfficeAndInactiveUsers(new Set<Id>()).size());
    }
    
    @isTest
    public static void testGetPicklistLabel() {
        Utility.getPicklistLabels('Claim_Requests__c', 'Approval_Status__c');
    } 

    @isTest
    public static void testGetFieldsetName() {
        Utility.getFieldSetInfo('Consolidated_Overriden_Benefit_fieldset','Case');
    }

    @isTest
    public static void testGetQueueName() {
        Utility.getQueueNameVsDeveloperName(new Set<String>{'H_Appliance_Lead_Queue'});
    }
    
    @isTest
    public static void testgetMonthsBetween() {
        Utility.getMonthsBetween(System.today(),System.today().addMonths(1));
    }
    //Added by Shreela on 9th Feb 2024 for SMEPB 143
    @isTest
    public static void testgetEmailTemplate() {
        Utility.getEmailTemplate('MHE_Resolution_to_Customer');
    }
    
    @isTest
    public static void testgetOrgWideEmailAddress() {
        Utility.getOrgWideEmailAddress(GlobalConstants.One_CRM);
    }
}