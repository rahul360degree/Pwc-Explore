@isTest 
public with sharing class AttachPaymentReceiptControllerTest {
    
    @testSetup
    
    static void createData(){
         //create appliance user
         Profile appliancesProfile = [SELECT Id FROM Profile WHERE Name = 'Appliances Sales User'];
         User appliancesUser = new TestUserBuilder().setProfileId(appliancesProfile.Id)
         .setBusinessUnit('H').setSalaryCode('25345').getSavedTestRecord(); 

         //create interio user
         Profile interioProfile = [SELECT Id FROM Profile WHERE Name = 'Interio B2C VFD Sales Marketing Logistic User'];
         User interioUser = new TestUserBuilder().setProfileId(interioProfile.Id)
         .setBusinessUnit('W').setSalaryCode('769198').getSavedTestRecord();
        
        //create account
        System.runAs(appliancesUser){
            Account partnerAccount = new TestAccountBuilder()
                    .setRecordTypeId(Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Dealer').getRecordTypeId())
                    .setBusinessUnit('H').getSavedTestRecord();
                        
           
            /*Account accountRecord1 = new Account(LastName='Test Account', PersonMobilePhone='7902112113', Business_Unit__c = 'H',PersonEmail='invalid@test.com' );
            accountRecord1.RecordTypeId = (RecordTypeUtils.getInstance()).getRecordTypeId('Account', 'Customer');
            insert accountRecord1; */
            
            //create Order
             Order orderRecord= new TestOrderBuilder().setAccountId(partnerAccount.Id)
                    .setRecordTypeId(Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('Appliance_Primary').getRecordTypeId())
                    .setBusinessUnit('H').getSavedTestRecord();
           }
        
        //create interio account
        System.runAs(interioUser){
            Account partnerAccount1 = new TestAccountBuilder()
                    .setRecordTypeId(Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Dealer').getRecordTypeId())
                    .setBusinessUnit('W').getSavedTestRecord();
             
           /* Account accountRecord = new Account(LastName='Test Account', PersonMobilePhone='7902112113', Business_Unit__c = 'W', Branch_Code__c = 'P');
            accountRecord.RecordTypeId = (RecordTypeUtils.getInstance()).getRecordTypeId('Account', 'Customer');
            insert accountRecord; */
            
            //create Order
             Order orderRecord1= new TestOrderBuilder().setAccountId(partnerAccount1.Id)
                    .setRecordTypeId(Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('Interio_B2C_VFD_Primary').getRecordTypeId())
                    .setBusinessUnit('W').getSavedTestRecord();
        }

    }
     
    @isTest
    private static void validAdvancePaymentReceiptAttachmentForAuraCmp(){
        
        //get order
        Order orderRec=[Select Id From Order Limit 1];
                
        //create advance payment detail
        Advance_Payment_Details__c advPaymentRec=new Advance_Payment_Details__c();
        TestAdvancePaymentDetailBuilder advPaymentDetail=new TestAdvancePaymentDetailBuilder();
        advPaymentRec=advPaymentDetail.setPaymentMode(GlobalConstants.PAYMENT_MODE_EMI);
        advPaymentRec=advPaymentDetail.setBankName('HDFC Bank');
        advPaymentRec=advPaymentDetail.setReferenceNumber('126GT');
        advPaymentRec=advPaymentDetail.setEMIVendor('Snapmint');
        advPaymentRec=advPaymentDetail.setEMIScheme('Snapmint 9/3');
        advPaymentRec=advPaymentDetail.setOrder(orderRec.Id);
        advPaymentRec.Delivery_Order_Number__c = 'abc';
        advPaymentRec.Credit_Card_Last_four_digits__c = '5678';
        advPaymentRec.Credit_Debit_Card_Approval_Code__c = 'abc';
        advPaymentRec.Type_of_Transaction__c = 'Advance Receipt';
        advPaymentRec.Transaction_Type__c = '328';
        advPaymentRec.Mode_of_Advance_Payment__c ='Cash';
        //Added by Namrata 09-03-2023 for jira SIEPB-69
        advPaymentRec.Amount__c = 2000; 
       
         Test.startTest();
         Insert advPaymentRec;
         
         AttachPaymentReceiptController.createAttachmentRecord(advPaymentRec.Id);                        
        
         try{
             AttachPaymentReceiptController.createAttachmentRecord(advPaymentRec.Id);
             
         }catch(Exception ex){
            
         }
             Id contentDocumentIdcheck = [SELECT ContentDocumentId FROM ContentVersion].ContentDocumentId;
             Test.setMock(HttpCalloutMock.class, new mockTinyUrlService());
             AttachPaymentReceiptController.mailAttachmentToUser('Payment_Receipt-' + advPaymentRec.Name + '.pdf', advPaymentRec.Id, contentDocumentIdcheck);
             //Test.setMock(HttpCalloutMock.class, new mockPaymentReceiptResponseClass());
        Test.stopTest();
        System.assertEquals(1, [select count() from ContentDocumentLink where LinkedEntityId = :advPaymentRec.id], 'Payment Receipt Generated Attached');
        
    } 
    
    @isTest
    private static void validAdvancePaymentReceiptAttachmentForAuraCmp2(){
        
        String URL = '';
        
        User applianceUser=[Select Id From User Limit 1];
        Account accountRecord2 = new Account(LastName='Test Account1', PersonMobilePhone='7902112112', Business_Unit__c = 'H',PersonEmail='invalid1@test.com' );
        accountRecord2.RecordTypeId =(RecordTypeUtils.getInstance()).getRecordTypeId('Account', 'Customer');
        insert accountRecord2; 
        
        //get order
        Order orderRec=[Select Id From Order Limit 1];
        orderRec.AccountId = accountRecord2.Id;
        update orderRec;
                
        //create advance payment detail
        Advance_Payment_Details__c advPaymentRec=new Advance_Payment_Details__c();
        TestAdvancePaymentDetailBuilder advPaymentDetail=new TestAdvancePaymentDetailBuilder();
        advPaymentRec=advPaymentDetail.setPaymentMode(GlobalConstants.PAYMENT_MODE_EMI);
        advPaymentRec=advPaymentDetail.setBankName('HDFC Bank');
        advPaymentRec=advPaymentDetail.setReferenceNumber('126GT');
        advPaymentRec=advPaymentDetail.setEMIVendor('Snapmint');
        advPaymentRec=advPaymentDetail.setEMIScheme('Snapmint 9/3');
        advPaymentRec=advPaymentDetail.setOrder(orderRec.Id);
        advPaymentRec.Delivery_Order_Number__c = 'abc';
        advPaymentRec.Credit_Card_Last_four_digits__c = '5678';
        advPaymentRec.Credit_Debit_Card_Approval_Code__c = 'abc';
        advPaymentRec.Type_of_Transaction__c = 'Advance Receipt';
        advPaymentRec.Transaction_Type__c = '328';
        advPaymentRec.Mode_of_Advance_Payment__c ='Cash'; 
        //Added by Namrata 09-03-2023 for jira SIEPB-69
        advPaymentRec.Amount__c = 3000; 
        
        Blob bodyBlob=Blob.valueOf('Dummy Body'); 
        
        ContentVersion contentVersion = new ContentVersion(
            Title='Payment_Receipt-' + advPaymentRec.Name + '.pdf', 
            PathOnClient ='SampleTitle.pdf',
            VersionData = bodyBlob, 
            origin = 'H'
        );
             
        insert contentVersion;
        
        
        //insert contentVersion;
         Test.startTest();
         Insert advPaymentRec;
         contentVersion = [SELECT Id, Title, ContentDocumentId 
                          FROM ContentVersion WHERE Id = :contentVersion.Id LIMIT 1];
         ContentDocumentLink contentlink = new ContentDocumentLink();
         contentlink.LinkedEntityId = advPaymentRec.id;
         contentlink.contentdocumentid = contentVersion.contentdocumentid;
         contentlink.ShareType = 'V';
        
         insert contentlink;
         
             AttachPaymentReceiptController.createAttachmentRecord(advPaymentRec.Id);
             Test.setMock(HttpCalloutMock.class, new mockTinyUrlService());
             //Test.setMock(HttpCalloutMock.class, new mockPaymentReceiptResponseClass());
        
        Test.stopTest();
    
    }     

    @isTest private static void validAdvancePaymentReceiptAttachmentForAuraCmpForInterio(){
        //get user
        User interioB2CUser=[SELECT Id 
                             FROM User WHERE Business_Unit__c = 'W' AND Sub_Division__c = 'B2C' Limit 1];
       
        //get order       
        Order orderRec =[SELECT Id 
                         FROM Order WHERE Business_Unit__c = 'W' AND Sub_Division__c = 'B2C' LIMIT 1];
       
        Advance_Payment_Details__c advPayRec=new Advance_Payment_Details__c();
        advPayRec.Transaction_Type__c = '328';
        advPayRec.Bank_Provider_Name__c = 'Citibank India';
        advPayRec.Reference_Number__c = 'test 1';
        advPayRec.Type_of_Transaction__c = 'Advance Receipt';
        advPayRec.Mode_of_Advance_Payment__c = 'Cash';
        advPayRec.Transaction_Entry_Date__c = System.today();
        advPayrec.Order__c = orderRec.Id;
        advPayrec.LC__c = '100' ;
        advPayrec.BC__c = '100';
        advPayrec.CC__c = '100';
        //advPayrec.Order__c = '8012h000000MpcSAAS';
        //Added by Namrata 09-03-2023 for jira SIEPB-69
        advPayrec.Amount__c = 2000; 


       // Test.startTest();
        Insert advPayRec;
        AttachPaymentReceiptController.createAttachmentRecord(advPayRec.Id);
        
        try{
            AttachPaymentReceiptController.createAttachmentRecord(advPayRec.Id);
        }catch(Exception ex){
            
        }
      //  Test.stopTest();
        System.assertEquals(1, [select count() from ContentDocumentLink where LinkedEntityId = :advPayRec.id], 'Payment Receipt Generated Attached');
    }
}