/*------------------------------------------------------------------------------------
* Author        :        Stetig Consulting
* Description   :        Test methods for billing an order creation
* History
* --------
* 07-12-2021     :    Initial Release
* ----------------------------------------------------------------------------------*/
@isTest
public with sharing class TestOrderCreation {
    static testmethod void testOrderCreation() {
        Id accoundId = LeaseTestDataFactory.createAccountFromName('Test Stetig Order');
        
        List<Account> accList = [Select Id, Name, Integration_Status__c, Account_Code__c,createdById
                                 from Account where Id = :accoundId];
        system.assertEquals(accList.size(), 1);
        /*Added by poonam*/
        Branch__c branchRec = new Branch__c(		
            Business_Partner__c = accList[0].Id
        );
        insert branchRec;
            
            Tax_Number__c taxnumberRec = new Tax_Number__c(
            Business_Partner__c = accList[0].Id,
			Tax_Number__c = 'FGHJK4567W',
            Category__c = 'PAN',
            Un_registered__c = 'No'
        );
        insert taxnumberRec;
        /*Added by poonam*/
         accList[0].Sub_division__c='B2B';           //added by pankaj 19 may 2023
        accList[0].user__c=accList[0].createdById; //added by pankaj 19 may 2023
        accList[0].Construction_Lob__c='WPS'; //added by pankaj 19 may 2023
        accList[0].Construction_Sub_Lob__c='WPS-MUM'; //added by pankaj 19 may 2023
        accList[0].Integration_Status__c = 'Synced';
        update accList;
        
        Id contactId = LeaseTestDataFactory.createContact(accoundId);
        Id oppId = LeaseTestDataFactory.createOpportunity(accoundId); 
        Id hotId = LeaseTestDataFactory.CreateHoT(oppId);
        
        List<HEAD_OF_TERMS__c> hotList = [Select Id, Name, Licence_End_Date__c, Reason_for_change_in_contract_date__c,
                                          Contract_Closure_Date__c
                                          from HEAD_OF_TERMS__c where Id = :hotId];
        system.assertEquals(hotList.size(), 1);
        
        Id billId = LeaseTestDataFactory.createBill(hotId, oppId);
        List<Billing__c> billList = new List<Billing__c>();
        
        billList = [Select Id, Name, Charge__c, Head_Of_Terms__c, Billing_Start_Date__c, Billing_End_Date__c,
                                    Amount__c, Opportunity__c, Remarks__c, Narration__c, Approval_Status__c
                                    from Billing__c where Id = :billId];
        system.assertEquals(billList.size(), 1);
        
        Map<Id, Billing__c> billMapOld = new Map<Id, Billing__c>();
        if(!billList.isEmpty()){
            for(Billing__c bill: billList){
                if(!billMapOld.containsKey(bill.Id)) {
                    billMapOld.put(bill.Id, bill);
                } else {
                    billMapOld.get(bill.Id);
                }
            }
        }
        
        List<User> userList = [Select Id, Name, Business_Unit__c, Salary_Code__c
                                   from User 
                                   where Business_Unit__c=: ElbConstantsClass.BUSINESS_UNIT_CONSTRUCTION_LEASING AND 
                                   Salary_Code__c =: ElbConstantsClass.USER_SALARY_CODE_RAJEEV LIMIT 1];
        
        List<Billing__c> newbillList = new List<Billing__c>();
        Billing__c newbill = new Billing__c();
        newbill.Id = billList[0].Id;
        newbill.Approval_Status__c = 'Approved';
        newbillList.add(newbill);
        update newbillList;

        test.StartTest();
        
        User u = new User();
        if(!userList.isEmpty()){
            u = [Select Id from User where Id =: userList[0].Id];
        } else {
            Id billingUserId = LeaseTestDataFactory.createBillingUser();
            u = [Select Id from User where Id =: billingUserId];
        }
        
        System.RunAs(u) {
        PrimaryRecordCreationHandler.createOrderandLineItem(newbillList, billMapOld);
        }
        test.stopTest();
    }
    
    
}