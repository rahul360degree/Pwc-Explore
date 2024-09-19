/*------------------------------------------------------------------------
 * Author:        Manasi Londhe
 * Company:       Salesforce
 * Description:   Test class for 'AdvancePaymentTriggerHandler' and 'AdvancePaymentTriggerHandlerHelper' Apex classes
 * Inputs:        NA
 * ---------------------------------------------------------------------------
 * History
 * 18-11-2020      Manasi Londhe     Initial Release
 * ----------------------------------------------------------------------------*/
@isTest
public class AdvancePaymentDetailTriggerTest {

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
            
          
                   
            //create Order
             Order orderRecord1= new TestOrderBuilder().setAccountId(partnerAccount1.Id)
                    .setRecordTypeId(Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('Interio_B2C_VFD_Primary').getRecordTypeId())
                    .setBusinessUnit('W').getSavedTestRecord();
        }
           
    }
    
    @isTest
    public Static void processingFeesDPMonthEMICountShouldBeGreaterThan0(){
        //get user
        User applianceUser=[Select Id,Salary_Code__c From User WHERE Salary_Code__c = '25345' Limit 1];
              
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
        advPaymentRec.Amount__c = 2000; //Added by Namrata 24-02-2023 for jira SIEPB-69    
        //added by jalaj 13-07-2021
        advPaymentRec = advPaymentDetail.setTypeOfTransaction('Advance Receipt');
       	//advPaymentRec = advPaymentDetail.setLogisticCompany('5010');
        advPaymentRec = advPaymentDetail.setTransactionType('328');
        advPaymentRec.Mode_of_Advance_Payment__c = 'Cash';
        
        system.runAs(applianceUser){
            Test.startTest();
        	Insert advPaymentRec;
            Test.stopTest();
        }
        Advance_Payment_Details__c advPaymentRecord=[Select Id,Processing_Fees__c,DP_Month__c,EMI_Count__c From Advance_Payment_Details__c Where Id=:advPaymentRec.Id];
        System.assert(advPaymentRecord.Processing_Fees__c>0 && advPaymentRecord.DP_Month__c>0 && advPaymentRecord.EMI_Count__c>0);
    }
    
    @isTest
    public Static void processingFeesDPMonthEMICountShouldBeNull(){
        //get user
        User applianceUser=[Select Id,Salary_Code__c From User WHERE Salary_Code__c = '25345' Limit 1];
        
        //get order
        Order orderRec=[Select Id From Order Limit 1];
        
        //create advance payment detail
        Advance_Payment_Details__c advPaymentRec=new Advance_Payment_Details__c();
        TestAdvancePaymentDetailBuilder advPaymentDetail=new TestAdvancePaymentDetailBuilder();
        advPaymentRec=advPaymentDetail.setPaymentMode(GlobalConstants.PAYMENT_MODE_OTHERS);
        advPaymentRec=advPaymentDetail.setOrder(orderRec.Id);
        advPaymentRec.Bank_Provider_Name__c = 'Axis Bank';
        advPaymentRec.Reference_Number__c = '123';
        advPaymentRec.Credit_Card_Last_four_digits__c = '5678';
        advPaymentRec.Credit_Debit_Card_Approval_Code__c = 'abc';
        advPaymentRec.Amount__c = 3000; //Added by Namrata 24-02-2023 for jira SIEPB-69
                
        //added by jalaj 13-07-2021
        //advPaymentRec = advPaymentDetail.setLogisticCompany('5010');
        advPaymentRec = advPaymentDetail.setTypeOfTransaction('Advance Receipt');
        advPaymentRec = advPaymentDetail.setTransactionType('328');
        advPaymentRec.Mode_of_Advance_Payment__c = 'Cash';
        
        system.runAs(applianceUser){
            Test.startTest();
        	Insert advPaymentRec;
            Test.stopTest();
        }
        Advance_Payment_Details__c advPaymentRecord=[Select Id,Processing_Fees__c,DP_Month__c,EMI_Count__c From Advance_Payment_Details__c Where Id=:advPaymentRec.Id];
        System.assert(advPaymentRecord.Processing_Fees__c==null && advPaymentRecord.DP_Month__c==null && advPaymentRecord.EMI_Count__c==null);
    }
    
    @isTest
    public Static void dPMonthEMICountShouldBeUpdatedWhenSchemeIsEdited(){
        Map<String,Advanced_Payment_Scheme_Details__mdt> schemeNameVsMDTRecord=new Map<String,Advanced_Payment_Scheme_Details__mdt>();
        //get user
        User applianceUser=[Select Id,Salary_Code__c From User WHERE Salary_Code__c = '25345' Limit 1];
        
        //get order
        Order orderRec=[Select Id From Order Limit 1];
        
        //create advance payment detail
        Advance_Payment_Details__c advPaymentRec=new Advance_Payment_Details__c();
        TestAdvancePaymentDetailBuilder advPaymentDetail=new TestAdvancePaymentDetailBuilder();
        advPaymentRec=advPaymentDetail.setPaymentMode(GlobalConstants.PAYMENT_MODE_EMI);
       // advPaymentRec=advPaymentDetail.setBankName('HDFC');
        advPaymentRec=advPaymentDetail.setReferenceNumber('126GT');
        advPaymentRec=advPaymentDetail.setEMIVendor('Snapmint');
        advPaymentRec=advPaymentDetail.setEMIScheme('Snapmint 9/3');
        advPaymentRec=advPaymentDetail.setOrder(orderRec.Id);
        advPaymentRec.Delivery_Order_Number__c = 'abc';
        advPaymentRec.Credit_Card_Last_four_digits__c = '5678';
        advPaymentRec.Credit_Debit_Card_Approval_Code__c = 'abc';
        advPaymentRec.Amount__c = 1000; //Added by Namrata 24-02-2023 for jira SIEPB-69
                
        //added by jalaj 13-07-2021
        //advPaymentRec = advPaymentDetail.setLogisticCompany('5010');
        advPaymentRec = advPaymentDetail.setTypeOfTransaction('Advance Receipt');
        advPaymentRec = advPaymentDetail.setTransactionType('328');
        advPaymentRec.Mode_of_Advance_Payment__c = 'Cash';
        
        system.runAs(applianceUser){
            Test.startTest();
        	Insert advPaymentRec;
            Test.stopTest();
        }
        
        //get metadata records
        Set<String> schemes=new Set<String>{'Snapmint 9/3','Snapmint 10/1'};
        for(Advanced_Payment_Scheme_Details__mdt apdSchemeDetail:[Select Scheme_Name__c,Processing_Fee__c,EMI_Count__c,Down_payment__c
                                                                    From Advanced_Payment_Scheme_Details__mdt
                                                                    Where Scheme_Name__c In :schemes]){
               schemeNameVsMDTRecord.put(apdSchemeDetail.Scheme_Name__c,apdSchemeDetail);
        }
        
        Advance_Payment_Details__c advPaymentRecord=[Select Id,Processing_Fees__c,DP_Month__c,EMI_Count__c From Advance_Payment_Details__c Where Id=:advPaymentRec.Id];
        System.assert(advPaymentRecord.Processing_Fees__c==schemeNameVsMDTRecord.get('Snapmint 9/3').Processing_Fee__c 
                      && advPaymentRecord.DP_Month__c==schemeNameVsMDTRecord.get('Snapmint 9/3').Down_payment__c 
                      && advPaymentRecord.EMI_Count__c==schemeNameVsMDTRecord.get('Snapmint 9/3').EMI_Count__c );
        
        //Edit Scheme
        advPaymentRecord.EMI_Scheme__c='Snapmint 10/1';
        Update advPaymentRecord;
        Advance_Payment_Details__c advPayRecord=[Select Id,Processing_Fees__c,DP_Month__c,EMI_Count__c From Advance_Payment_Details__c Where Id=:advPaymentRec.Id];
        System.assert(advPayRecord.Processing_Fees__c==schemeNameVsMDTRecord.get('Snapmint 10/1').Processing_Fee__c 
                      && advPayRecord.DP_Month__c==schemeNameVsMDTRecord.get('Snapmint 10/1').Down_payment__c 
                      && advPayRecord.EMI_Count__c==schemeNameVsMDTRecord.get('Snapmint 10/1').EMI_Count__c );
        
        advPaymentRecord.EMI_Scheme__c=null;
        Update advPaymentRecord;
        Advance_Payment_Details__c advPayRecord2=[Select Id,Processing_Fees__c,DP_Month__c,EMI_Count__c From Advance_Payment_Details__c Where Id=:advPaymentRec.Id];
        System.assertEquals(0,advPayRecord2.DP_Month__c);
               
    }
    
     @isTest
    public static void getDocumentNumber(){
         //get user
       // User interioB2CUser=[Select Id From User WHERE Business_Unit__c = 'W' AND Sub_Division__c = 'B2C' Limit 1];
        
          Profile interioProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
          User interioB2CUser = new TestUserBuilder().setProfileId(interioProfile.Id)
          .setBusinessUnit('W').setSalaryCode('769090').setLogisticCompany('5010').getSavedTestRecord();
               
		//get order       
        Order orderRec =[SELECT Id FROM Order WHERE Business_Unit__c = 'W' AND Sub_Division__c = 'B2C' LIMIT 1];
       //	Order orderRec =[SELECT Id FROM Order LIMIT 1];
        
        System.debug('orderRec value'+orderRec);
        Advance_Payment_Details__c advPayRec=new Advance_Payment_Details__c();
        TestAdvancePaymentDetailBuilder advPaymentDetails=new TestAdvancePaymentDetailBuilder();
        advPayRec=advPaymentDetails.setBankName('Citibank India');
        advPayRec=advPaymentDetails.setReferenceNumber('test 1');
        advPayRec=advPaymentDetails.setTransactionEntryDate(System.today());
        advPayRec=advPaymentDetails.setOrder(orderRec.Id);
        
        //added by jalaj 13-07-2021
        //advPayRec = advPaymentDetails.setLogisticCompany('5010');
        advPayRec = advPaymentDetails.setTransactionType('328');
        advPayRec = advPaymentDetails.setModeOfAdvancePayment('Cash');
        advPayRec = advPaymentDetails.setTypeOfTransaction('Advance Receipt');
        advPayRec.BC__c = 'WR';
        advPayRec.LC__c = '075';
        advPayRec.CC__c = 'WF';
      	advPayRec.Amount__c = 2000; //Added by Namrata 24-02-2023 for jira SIEPB-69
        
        Insert advPayRec;
                
        // for second record
        
        Advance_Payment_Details__c advPayRec2=new Advance_Payment_Details__c();
        TestAdvancePaymentDetailBuilder advPaymentDetails2=new TestAdvancePaymentDetailBuilder();
        advPayRec2=advPaymentDetails2.setBankName('Citibank India');
        advPayRec2=advPaymentDetails2.setReferenceNumber('test 2');
        advPayRec2=advPaymentDetails2.setTransactionEntryDate(System.today());
        advPayRec2=advPaymentDetails2.setOrder(orderRec.Id);
        
        //added by jalaj 13-07-2021
        //advPayRec2 = advPaymentDetails2.setLogisticCompany('5010');
        advPayRec2 = advPaymentDetails2.setTransactionType('328');
        advPayRec2 = advPaymentDetails2.setModeOfAdvancePayment('Cash');
        advPayRec2 = advPaymentDetails2.setTypeOfTransaction('Advance Receipt');
        advPayRec2.BC__c = 'WR';
        advPayRec2.LC__c = '075';
        advPayRec2.CC__c = 'WF';
       	advPayRec2.Amount__c = 2000; //Added by Namrata 24-02-2023 for jira SIEPB-69
        
        
        system.runAs(interioB2CUser)
        {
            System.debug('interioB2CUser' + interioB2CUser);
            Test.startTest();
                       
            advPayRec.Doc_Number__c = null;
            Update advPayRec;
            Insert advPayRec2;
        
        Advance_Payment_Details__c advPayRec3=new Advance_Payment_Details__c();
        TestAdvancePaymentDetailBuilder advPaymentDetails3=new TestAdvancePaymentDetailBuilder();
        advPayRec3=advPaymentDetails3.setBankName('Citibank India');
        advPayRec3=advPaymentDetails3.setReferenceNumber('test 3');
        advPayRec3=advPaymentDetails3.setTransactionEntryDate(System.today());
        advPayRec3=advPaymentDetails3.setOrder(orderRec.Id);    

        //added by jalaj 13-07-2021
        //advPayRec3 = advPaymentDetails3.setLogisticCompany('5010');
        advPayRec3=advPaymentDetails3.setTransactionType('328');
        advPayRec3=advPaymentDetails3.setModeOfAdvancePayment('Cash');
        advPayRec3 = advPaymentDetails3.setTypeOfTransaction('Advance Receipt');
        advPayRec3.BC__c = 'WR';
        advPayRec3.LC__c = '075';
        advPayRec3.CC__c = 'WF';
      	advPayRec3.Amount__c = 2000; //Added by Namrata 24-02-2023 for jira SIEPB-69
            
        Insert advPayRec3;
        Test.stopTest();
            //system.assertEquals('WF', advPayRec3.CC__c);//gcp22
        }
    }
    
    @isTest
    public static void deleteAPDRecord(){
         //get user        
          Profile interioProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
          User interioB2CUser = new TestUserBuilder().setProfileId(interioProfile.Id)
          .setBusinessUnit('W').setSalaryCode('769090').setLogisticCompany('5010').getSavedTestRecord();
               
		//get order       
        Order orderRec =[SELECT Id FROM Order WHERE Business_Unit__c = 'W' AND Sub_Division__c = 'B2C' LIMIT 1];
        
        Advance_Payment_Details__c advPayRec=new Advance_Payment_Details__c();
        TestAdvancePaymentDetailBuilder advPaymentDetails=new TestAdvancePaymentDetailBuilder();
        advPayRec=advPaymentDetails.setBankName('Citibank India');
        advPayRec=advPaymentDetails.setReferenceNumber('test 1');
        advPayRec=advPaymentDetails.setTransactionEntryDate(System.today());
        advPayRec=advPaymentDetails.setOrder(orderRec.Id);
        //advPayRec = advPaymentDetails.setLogisticCompany('5010');
        advPayRec = advPaymentDetails.setTransactionType('328');
        advPayRec = advPaymentDetails.setModeOfAdvancePayment('Cash');
        advPayRec = advPaymentDetails.setTypeOfTransaction('Advance Receipt');
        advPayRec.BC__c = 'WR';
        advPayRec.LC__c = '075';
        advPayRec.CC__c = 'WF';
        advPayRec.Amount__c = 1000; //Added by Namrata 24-02-2023 for jira SIEPB-69
        //advPayRec.Integration_Status__c = 'Synced';
              
        system.runAs(interioB2CUser)
        {
            Test.startTest();
            Insert advPayRec;
            delete advPayRec;
            Test.stopTest();
        }
        //system.assertEquals('WF', advPayRec.CC__c);//gcp22
    }
}