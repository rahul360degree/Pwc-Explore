@isTest
public class CreateWarrantyClaimRequestForAssetTest {
    @TestSetup
    static void makeData(){
        Account accountRecord = createAccountRecord();
        insert accountRecord;
        
        Contact contactRecord = createContactRecord(accountRecord.Id);
        insert contactRecord;
        
        //Create Address Record						//Added by pc
            Address__c address = new Address__c();
            address.Address_Type__c = 'B2B';
            address.Address_Format__c = 'ADR';
            address.Name__c = 'Nuvoco Plant Pune';
            address.Telephone__c = '8765432111';
            address.Email__c = 'punetest1234@nuvoco.com';
            address.Building__c = 'Avenues';
            address.Street2__c = '1st Street';
            insert address;

        Asset assetRecord = createAssetRecord(accountRecord.Id, contactRecord.Id);
        assetRecord.Address_Code__c = address.id;			//Added by pc
        insert assetRecord;
        
    }

    @isTest
    public static void createClaimRequestRecordShouldPass() {
        Test.startTest();
        List<Asset> assets = [SELECT Id,Equipment_Serial_No__c from Asset];
        assets[0].Status = 'Active';
        assets[0].Type_of_Warranty__c = 'Not Applicable';
        update assets;
        List<Claim_Requests__c> claims = [SELECT ID from Claim_Requests__c WHERE Asset__c =: assets[0].ID];
        System.assertEquals(claims.size(),1,'Incorrect number of claim requests made');
        Test.stopTest();
    }

    private static Account createAccountRecord() {
        Account accountRecord = new Account(Name='Test Attach Payment', Industry='Apparel', Type='Institution', Account_Code__c='TPA');
        accountRecord.RecordTypeId = (RecordTypeUtils.getInstance()).getRecordTypeId('Account', 'Business_Account');
        return accountRecord;
    }

    private static Asset createAssetRecord(Id accountId, Id contactId) {
        Asset assetRecord = new TestAssetBuilder().setAccountId(accountId).setContactId(contactId).getTestRecord();
        return assetRecord;
    }

    private static Contact createContactRecord(Id accountId) {
        Contact contactRecord = new TestContactBuilder().setAccountId(accountId).getTestRecord();
        return contactRecord;
    }
}