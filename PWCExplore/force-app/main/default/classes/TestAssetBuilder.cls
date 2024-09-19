@isTest
public with sharing class TestAssetBuilder {
    Asset assetInstance;
    public TestAssetBuilder() {
        assetInstance = new Asset();
        assetInstance.Name = 'Test Asset record';
        assetInstance.SerialNumber = 'AX001';
    }

    public TestAssetBuilder setAccountId(Id accountId) {
        assetInstance.AccountId = accountId;
        return this;
    }

    public TestAssetBuilder setContactId(Id contactId) {
        assetInstance.ContactId = contactId;
        return this;
    }

    public Asset getTestRecord() {
        return assetInstance;
    }
}