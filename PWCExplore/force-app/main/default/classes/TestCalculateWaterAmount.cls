/*------------------------------------------------------------------------------------
 * Author        :        Stetig Consulting
 * Description   :        Test method to calculate water Amount
 * History
 * --------
 * 08-12-2021     :    Initial Release
 * ----------------------------------------------------------------------------------*/
@isTest
private class TestCalculateWaterAmount {
	
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
                                    Amount__c, Opportunity__c, B_M_C_Consumption_KL__c, WELL_Consumption_KL__c, Remarks__c, Narration__c, Approval_Status__c
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
        
        //Select Id,Rate__c, Start_Date__c, End_Date__c, Charge_Name__c, Charge_Type__c from Rate_Slab__c
        
        Rate_Slab__c rs = new Rate_Slab__c();
        rs.Start_Date__c = date.today().addDays(-5) ;
        rs.End_Date__c = date.today().addDays(5);
        rs.Charge_Type__c =  billList[0].Charge__c;
        rs.Charge_Name__c = Label.BMCConsumption;
        rs.Rate__c = 16;
        insert rs;
        
        Rate_Slab__c rs1 = new Rate_Slab__c();
        rs1.Start_Date__c = date.today().addDays(-5) ;
        rs1.End_Date__c = date.today().addDays(5);
        rs1.Charge_Type__c =  billList[0].Charge__c;
        rs1.Charge_Name__c = Label.WELLConsumption;
        rs1.Rate__c = 19;
        insert rs1;
        
        Id waterRecordTypeId = Schema.SObjectType.Billing__C.getRecordTypeInfosByName().get(ElbConstantsClass.Water_Reimbursement_Charges).getRecordTypeId();
       
        billList[0].recordtypeId = waterRecordTypeId;
        
		billList[0].Billing_Start_Date__c = date.today().addDays(-5);
        billList[0].Billing_End_Date__c = date.today().addDays(5);
 
        billList[0].B_M_C_Consumption_KL__c = 40;
        billList[0].WELL_Consumption_KL__c = 60;
        billList[0]. Amount__c = 100;
        
        update billList;
        
        BillingObjectTriggerHandler.calculateAmountForWater(billList, billMapOld);
        }    
        test.stopTest();
    }
}