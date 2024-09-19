/*------------------------------------------------------------------------------------
 * Author        :        Joshna
 * Company       :        Salesforce
 * Description   :        Test Builder for Dealer Visit
 * History
 * --------
 * 06-11-2020      Joshna Palla     Initial Release
 * ----------------------------------------------------------------------------------*/
@isTest
public with sharing class TestDealerVisitBuilder {
    Dealer_Visit__c dealerVisitInstance;

    public TestDealerVisitBuilder() {
        dealerVisitInstance = new Dealer_Visit__c();
    }

    public TestDealerVisitBuilder setAccountInformation(Id accountId) {
        dealerVisitInstance.Account_Information__c = accountId;
        return this;
    }

    public TestDealerVisitBuilder setRecordTypeId(Id recordTypeId) {
        dealerVisitInstance.RecordTypeId = recordTypeId;
        return this;
    }

    public Dealer_Visit__c getTestRecord() {
        return dealerVisitInstance;
    }

    public Dealer_Visit__c getSavedTestRecord() {
        insert dealerVisitInstance;
        return dealerVisitInstance;
    }
}