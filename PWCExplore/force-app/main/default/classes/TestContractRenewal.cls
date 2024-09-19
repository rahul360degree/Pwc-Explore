/*------------------------------------------------------------------------------------
* Author        :        Stetig Consulting
* Description   :        Test method for contract renewal
* History
* --------
* 10-12-2021     :    Initial Release
* ----------------------------------------------------------------------------------*/
@isTest
public with sharing class TestContractRenewal {
    static testmethod void testContractRenewal() {
        Id accoundId = LeaseTestDataFactory.createAccount();
        
        test.StartTest();
        Id leasingUserId = LeaseTestDataFactory.createLeasingUser();
        User u = [Select Id from User where Id =: leasingUserId];
        System.RunAs(u) {
            Id contactId = LeaseTestDataFactory.createContact(accoundId);
            Id oppId = LeaseTestDataFactory.createOpportunity(accoundId); 
            Id hotId = LeaseTestDataFactory.CreateHoT(oppId);
            LeaseTestDataFactory.tagPremise(hotId, oppId);
            
            List<HEAD_OF_TERMS__c> hotList = [Select Id, Name, Licence_End_Date__c, Reason_for_change_in_contract_date__c,
                                              Contract_Closure_Date__c
                                              from HEAD_OF_TERMS__c where Id = :hotId];
            system.assertEquals(hotList.size(), 1);
            contractRenewal.getHotData(hotList[0].Id);
            
            contractRenewal.updateHotFields(hotId, system.today().addMonths(24), 'Testing contract renewal code coverage', system.today());
        }
        test.stopTest();
    }
}