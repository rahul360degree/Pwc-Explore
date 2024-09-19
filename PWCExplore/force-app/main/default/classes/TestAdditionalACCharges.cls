/*------------------------------------------------------------------------------------
 * Author        :        Stetig Consulting
 * Description   :        Test method for Additional AC charges
 * History
 * --------
 * 08-12-2021     :    Initial Release
 * ----------------------------------------------------------------------------------*/
@isTest
Private class TestAdditionalACCharges {

    static testmethod void testAdditionAC() {
        test.StartTest();
        Id leasingUserId = LeaseTestDataFactory.createLeasingUser();
        Id accoundId = LeaseTestDataFactory.createAccount('Test Stetig Consultancy Bill');
        User u = [Select Id from User where Id =: leasingUserId];
        System.RunAs(u) {
        Id contactId = LeaseTestDataFactory.createContact(accoundId);
        Id oppId = LeaseTestDataFactory.createOpportunity(accoundId); 
        Id hotId = LeaseTestDataFactory.CreateHoT(oppId);
        
        List<HEAD_OF_TERMS__c> hotList = [Select Id, Name, Licence_End_Date__c, Reason_for_change_in_contract_date__c,
                                          Contract_Closure_Date__c
                                          from HEAD_OF_TERMS__c where Id = :hotId];
        system.assertEquals(hotList.size(), 1);
        
        Id billId = LeaseTestDataFactory.createBill(hotId, oppId);
        
        List<Billing__c> billList = [Select Id, Name, Charge__c, Head_Of_Terms__c, Billing_Start_Date__c, Billing_End_Date__c,
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

        Rate_Slab__c rs = new Rate_Slab__c();
        rs.Start_Date__c = date.today().addDays(-5) ;
        rs.End_Date__c = date.today().addDays(5);
        rs.Charge_Type__c =  billList[0].Charge__c;
        rs.Rate__c = 18;
        insert rs;
        
        Id AdditionalACTypeId = Schema.SObjectType.Billing__C.getRecordTypeInfosByDeveloperName().get(ElbConstantsClass.Additional_AC_Charges).getRecordTypeId();
        billList[0].recordtypeId = AdditionalACTypeId;
        
		billList[0].Billing_Start_Date__c = date.today().addDays(-2);
        billList[0].Billing_End_Date__c = date.today().addDays(2);
        billList[0].Total_Extra_Usage_in_Hours__c = 10;
        update billList;
        
        
        AdditionalACChargesHandler.calculateACCharges(billList, billMapOld);
        }      
        test.stopTest();
    }

}