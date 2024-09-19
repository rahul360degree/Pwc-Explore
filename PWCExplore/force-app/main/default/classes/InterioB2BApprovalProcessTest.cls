/**
* @description       : 
* @author            : jadhavr@godrej.com
* @group             : 
* @last modified on  : 01-18-2023
* @last modified by  : jadhavr@godrej.com
**/

@isTest
public class InterioB2BApprovalProcessTest {
    @testSetup
    public static void createData(){       
        Profile profile = [SELECT Id FROM Profile WHERE Name =:GlobalConstants.SYSTEM_ADMIN_PROFILE_NAME];
        User runningAdminUser =new TestUserBuilder()
            .setProfileId(profile.Id)
            .setLastName('Admin User')
            .getTestRecord();        
        runningAdminUser.IsActive = true;
        runningAdminUser.Persona__c =GlobalConstants.Interio_HO_PERSONA;
        insert runningAdminUser;
        
        System.runAs(runningAdminUser)
        { 
            User userRec1 = new TestUserBuilder()
                .setProfileId(profile.Id)
                .setLastName('Admin User1')
                .setLogisticCompany('5020')
                .setBusinessUnit(GlobalConstants.INTERIO_BUSINESS_UNIT)
                .getTestRecord();        
            userRec1.Sub_Division__c = GlobalConstants.B2B_SUBDIVISION;
            userRec1.Area_Code__c = 'WN1';
            userRec1.IsActive = true;    
            userRec1.ManagerId=runningAdminUser.Id;
            userRec1.Persona__c ='Manager';
            insert userRec1;
            
            User userRec2 = new TestUserBuilder()
                .setProfileId(profile.Id)
                .setLogisticCompany('5020')
                .setLastName('Admin User2')
                .setBusinessUnit(GlobalConstants.INTERIO_BUSINESS_UNIT)
                .getTestRecord();        
            userRec2.Sub_Division__c = GlobalConstants.B2B_SUBDIVISION;
            userRec2.Area_Code__c = 'WN1';
            userRec2.IsActive = true; 
            userRec2.ManagerId=userRec1.Id;
            userRec2.Persona__c =GlobalConstants.PERSONA_SalesPerson;
            insert userRec2;
            
            Account acc = new TestAccountBuilder()
                .setRecordTypeId(Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(GlobalConstants.BUSINESS_ACCOUNT_RT).getRecordTypeId())
                .setBusinessUnit(GlobalConstants.INTERIO_BUSINESS_UNIT)
                .getSavedTestRecord();
            
            Opportunity oppRecord=new TestOpportunityBuilder()
                .setRecordTypeId(Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Interio_B2B').getRecordTypeId())
                .setAccountId(acc.Id)
                .getTestRecord();
            oppRecord.Order_Type__c=GlobalConstants.DIRECT_BILLING_TO_CUSTOMER;
            oppRecord.Interio_Sub_Division__c=GlobalConstants.Interio_Sub_Division_B2B_KAM;
            oppRecord.OwnerId=userRec2.Id;
            insert oppRecord;
            
            Product2 product = new TestProductBuilder()
                .setItemCode('00001')
                .setProductCode('00001')
                .setIsActive(true)
                .setComponentType(GlobalConstants.BASE_PRODUCT_COMPONENT_TYPE)
                .setProductLine(GlobalConstants.Product_Line_DESKING)
                .getTestRecord();                
            product.Is_Independent_product__c = false;
            product.Product_Line__c=GlobalConstants.Product_Line_DESKING;
            product.Product_Type__c=GlobalConstants.Product_Line_DESKING;
            product.Product_Class__c='DTWHAA';
            product.Is_Generic_Product__c= true;
            product.Is_New_Equipment__c=true;  
            insert product;
            
            Id pricebookId = Test.getStandardPricebookId();
            PricebookEntry pbe = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = product.Id, UnitPrice = 100, IsActive = true);
            insert pbe;            
            
            GlobalConstants.SKIP_QUOTE_LOCK = true;    
            QliTriggerHandler.TriggerDisabled = true;
            
            Quote quoteRecord = new TestQuoteBuilder()
                .setRecordTypeId(Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get(GlobalConstants.Interio_B2B_Finished_Good_RT).getRecordTypeId())
                .setOpportunityId(oppRecord.Id)
                .setPricebook2Id(pricebookId)                  
                .getTestRecord();  
            quoteRecord.Approval_Status__c=GlobalConstants.Submitted_for_Approval;
            insert quoteRecord;
            
            QuoteLineItem qli = new TestQuoteLineItemBuilder()
                .setQuoteId(quoteRecord.Id)
                .setPriceBookEntryId(pbe.Id)
                .setUnitPrice(pbe.UnitPrice)
                .getTestRecord();  
            
            qli.Product2Id = pbe.Product2Id;            	
            qli.Requested_Customer_Discount__c = 5;
            qli.Req_Net_Rlizd_Bsc_Disc__c=4;
            qli.List_of_Approvers__c=runningAdminUser.Id;
            qli.Current_Approver__c=runningAdminUser.Id;
            insert qli;
            
            Quote_Approval_History__c quoteApprovalHistory=new Quote_Approval_History__c();
            quoteApprovalHistory.Approval_Comments__c=GlobalConstants.Submitted_for_Approval;
            quoteApprovalHistory.Status__c=GlobalConstants.Submitted_for_Approval;
            quoteApprovalHistory.Quote__c=quoteRecord.Id;
            insert quoteApprovalHistory;
            
            Group  grp=new Group();
            grp.Name='Test';
            grp.Type='Queue';
            insert grp;
            
            GroupMember grpMember=new GroupMember();
            grpMember.GroupId=grp.Id;
            grpMember.UserOrGroupId=runningAdminUser.Id;
            insert grpMember; 
        }
    }
    
    static testMethod void test_submitForApproval(){
        Test.startTest(); 
        QuoteTriggerHandler.TriggerDisabled = true;
        User adminUser = [Select Id,LastName From User where LastName='Admin User' Limit 1];  
        User adminUser1 = [Select Id,LastName From User where LastName='Admin User1' Limit 1]; 
        Group groupRecord=[Select Id,Name from Group where Name='Test' Limit 1];
        List<QuoteLineItem> qliList=new List<QuoteLineItem>();
        System.runAs(adminUser1){
            
            qliList=[Select id,Quote.Id,Quote.Name,Approval_Status__c,Current_Approver__c,List_of_Approvers__c,Quote.Total_List_Price__c,
                     Quote.Req_Cust_Disc__c,Quote.Total_Sales_Price__c, Quote.App_Cust_Disc__c, Quote.Total_Approved_Customer_Discount_Price__c,
                     Quote.Req_WD_Retention_SAC_Amnt_Req_Disc_Bsc__c,Quote.Req_WD_Retention_SAC_Amnt_Req_Cons_Bsc__c, Quote.Appr_WD_Ret_SAC_Amt_appr_Disc_Bsc__c,
                     Quote.Appr_WD_Ret_SAC_Amt_on_cons_Bsc__c,Quote.Appr_WD_CONT_Amt_On_Cons_Bsc__c,Quote.Appr_WD_CONT_Cons_Basic__c,
                     Quote.Req_WD_CONT_Amt_on_Req_Disc_bsc__c,Quote.Req_WD_CONT_amt_on_cons_bsc__c, Quote.Appr_WD_CONT_Amt_On_Appr_Disc_Bsc__c,
                     Quote.Req_Net_Rlizd_Basic_Rate_Cons__c,Quote.Appr_Net_Rlizd_Basic_Rate_Cons__c, Quote.COP__c, Quote.Requested_COP_Factor__c,
                     Quote.Approved_COP_Factor__c,Quote.Req_WD_Ret_Disc_Basic__c, Quote.Req_WD_Ret_Cons_Basic__c, Quote.Appr_WD_Ret_Disc_Basic__c, 
                     Quote.Appr_WD_Ret_Cons_Basic__c,Quote.Req_WD_CONT__c, Quote.Req_WD_CONT_Cons_Basic__c, Quote.Appr_WD_CONT_Disc_Basic__c,Quote.Opportunity.Owner.Name,
                     Quote.Req_Net_Rlizd_Disc_Cons_Basic__c, Quote.Appr_Net_Relzd_Bsc_Disc_On_Cons_Bsc__c, Quote.Approval_Status__c,Quote.LOBSummaryTotal__c,Approved_Customer_Discount__c,
                     Approved_WD_Retention_On_ReqDiscbasic__c,Approved_WD_CONT__c from QuoteLineItem];
            
            InterioB2BApprovalProcess.submitForApproval(qliList,GlobalConstants.Submitted_for_Approval);
            
            try{
                InterioB2BApprovalProcess.submitForApproval(null,null);          
            }
            catch(AuraHandledException ex){
                system.debug('Exception -->'+ex.getMessage());
            }
            for(QuoteLineItem qli:qliList){
                qli.Current_Approver__c=adminUser1.Id;
                qli.List_of_Approvers__c=adminUser1.Id+','+groupRecord.Id+','+groupRecord.Id;
            }
            update qliList;
            InterioB2BApprovalProcess.submitForApproval(qliList,GlobalConstants.APPROVED_STATUS );
        }
        System.runAs(adminUser){
            InterioB2BApprovalProcess.submitForApproval(qliList,GlobalConstants.APPROVED_STATUS );
        }
        Test.stopTest();
    }
    
    static testMethod void test_resubmit(){
        Test.startTest(); 
        User adminUser2 = [Select Id,LastName From User where LastName='Admin User2' Limit 1];  
        system.debug(adminUser2);
        System.runAs(adminUser2){
            
            List<QuoteLineItem> qliList=[Select id,Quote.Id,Quote.Name,Approval_Status__c,Current_Approver__c,List_of_Approvers__c,Quote.Total_List_Price__c,
                                         Quote.Req_Cust_Disc__c,Quote.Total_Sales_Price__c, Quote.App_Cust_Disc__c, Quote.Total_Approved_Customer_Discount_Price__c,
                                         Quote.Req_WD_Retention_SAC_Amnt_Req_Disc_Bsc__c,Quote.Req_WD_Retention_SAC_Amnt_Req_Cons_Bsc__c, Quote.Appr_WD_Ret_SAC_Amt_appr_Disc_Bsc__c,
                                         Quote.Appr_WD_Ret_SAC_Amt_on_cons_Bsc__c,Approved_Customer_Discount__c,Approved_WD_Retention_On_ReqDiscbasic__c,Approved_WD_CONT__c,
                                         Quote.Req_WD_CONT_Amt_on_Req_Disc_bsc__c,Quote.Req_WD_CONT_amt_on_cons_bsc__c, Quote.Appr_WD_CONT_Amt_On_Appr_Disc_Bsc__c,
                                         Quote.Appr_WD_CONT_Amt_On_Cons_Bsc__c,
                                         Quote.Req_Net_Rlizd_Basic_Rate_Cons__c,Quote.Appr_Net_Rlizd_Basic_Rate_Cons__c, Quote.COP__c, Quote.Requested_COP_Factor__c,
                                         Quote.Approved_COP_Factor__c,Quote.Req_WD_Ret_Disc_Basic__c, Quote.Req_WD_Ret_Cons_Basic__c, Quote.Appr_WD_Ret_Disc_Basic__c, 
                                         Quote.Appr_WD_Ret_Cons_Basic__c,Quote.Req_WD_CONT__c, Quote.Req_WD_CONT_Cons_Basic__c, Quote.Appr_WD_CONT_Disc_Basic__c,
                                         Quote.Appr_WD_CONT_Cons_Basic__c,Quote.Req_Net_Rlizd_Disc_Cons_Basic__c, Quote.Appr_Net_Relzd_Bsc_Disc_On_Cons_Bsc__c, Quote.Approval_Status__c,Quote.LOBSummaryTotal__c from QuoteLineItem];
            
            InterioB2BApprovalProcess.submitForApproval(qliList,GlobalConstants.Submitted_for_Approval);
            InterioB2BApprovalProcess.submitForApproval(qliList,GlobalConstants.STATUS_Resubmitted);
        }
        Test.stopTest();
    }
    
    static testMethod void test_quoteList(){
        Test.startTest();
        User adminUser1 = [Select Id,LastName From User where LastName='Admin User' Limit 1];  
        User adminUser3 = [Select Id,LastName From User where LastName='Admin User2' Limit 1];  
        Set<Id> queueIds = new Set<Id> ();
        
        System.runAs(adminUser3){
            try{
                InterioB2BApprovalProcess.quoteList();          
            }
            catch(AuraHandledException ex){
                system.debug('Exception -->'+ex.getMessage());
            } 
            List<QuoteLineItem> qliList=[Select id,Quote.Id,Quote.Name,Approval_Status__c,Current_Approver__c,List_of_Approvers__c,Quote.Total_List_Price__c,
                                         Quote.Req_Cust_Disc__c,Quote.Total_Sales_Price__c, Quote.App_Cust_Disc__c, Quote.Total_Approved_Customer_Discount_Price__c,
                                         Quote.Req_WD_Retention_SAC_Amnt_Req_Disc_Bsc__c,Quote.Req_WD_Retention_SAC_Amnt_Req_Cons_Bsc__c, Quote.Appr_WD_Ret_SAC_Amt_appr_Disc_Bsc__c,
                                         Quote.Appr_WD_Ret_SAC_Amt_on_cons_Bsc__c,Approved_Customer_Discount__c,Approved_WD_Retention_On_ReqDiscbasic__c,Approved_WD_CONT__c,
                                         Quote.Req_WD_CONT_Amt_on_Req_Disc_bsc__c,Quote.Req_WD_CONT_amt_on_cons_bsc__c, Quote.Appr_WD_CONT_Amt_On_Appr_Disc_Bsc__c,
                                         Quote.Appr_WD_CONT_Amt_On_Cons_Bsc__c,Quote.LOBSummaryTotal__c,
                                         Quote.Req_Net_Rlizd_Basic_Rate_Cons__c,Quote.Appr_Net_Rlizd_Basic_Rate_Cons__c, Quote.COP__c, Quote.Requested_COP_Factor__c,
                                         Quote.Approved_COP_Factor__c,Quote.Req_WD_Ret_Disc_Basic__c, Quote.Req_WD_Ret_Cons_Basic__c, Quote.Appr_WD_Ret_Disc_Basic__c, 
                                         Quote.Appr_WD_Ret_Cons_Basic__c,Quote.Req_WD_CONT__c, Quote.Req_WD_CONT_Cons_Basic__c, Quote.Appr_WD_CONT_Disc_Basic__c,
                                         Quote.Appr_WD_CONT_Cons_Basic__c,Quote.Req_Net_Rlizd_Disc_Cons_Basic__c, Quote.Appr_Net_Relzd_Bsc_Disc_On_Cons_Bsc__c, Quote.Approval_Status__c from QuoteLineItem];            
            InterioB2BApprovalProcess.submitForApproval(qliList,GlobalConstants.Submitted_for_Approval);           
            qliList[0].Approval_Status__c=GlobalConstants.Submitted_for_Approval;
            update qliList;
        }
        System.runAs(adminUser1){
            InterioB2BApprovalProcess.quoteList();        
        }
        Test.stopTest();
    }
    
    static testMethod void test_createApprovalComments(){
        Test.startTest();
        User adminUser = [Select Id,LastName From User where LastName='Admin User1' Limit 1];  
        System.runAs(adminUser){
            
            Quote quote=[Select Id from Quote LIMIT :1];
            Quote_Approval_History__c qahRecord=new Quote_Approval_History__c();
            qahRecord.Approval_Comments__c=GlobalConstants.APPROVED_STATUS ;
            qahRecord.Quote__c=quote.ID;
            qahRecord.Status__c=GlobalConstants.APPROVED_STATUS ;
            
            List<Quote_Approval_History__c> approvalComments=new List<Quote_Approval_History__c>();
            approvalComments.add(qahRecord);
            
            try{
                InterioB2BApprovalProcess.createApprovalComments(null);          
            }
            catch(AuraHandledException ex){
                system.debug('Exception -->'+ex.getMessage());
            }
            
            InterioB2BApprovalProcess.createApprovalComments(approvalComments);
            InterioB2BApprovalProcess.wrapInfo(quote.Id);
        }        
        Test.stopTest();
    }
    @isTest
    static void testGetPreviouslyApprovedApproversEmails() {
        
        Quote quote=[Select Id from Quote LIMIT :1];
        Quote_Approval_History__c qahRecord=new Quote_Approval_History__c();
        qahRecord.Approval_Comments__c=GlobalConstants.APPROVED_STATUS ;
        qahRecord.Quote__c=quote.ID;
        qahRecord.Status__c=GlobalConstants.APPROVED_STATUS ;
        
        List<Quote_Approval_History__c> approvalComments=new List<Quote_Approval_History__c>();
        approvalComments.add(qahRecord);
        
        Test.startTest();
        Set<String> result = InterioB2BApprovalProcess.getPreviouslyApprovedApproversEmails(quote.Id);
        Test.stopTest();
        
    }
    
}