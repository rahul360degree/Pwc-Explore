@isTest
public class GVLC_Product_Scheduler_Test {
    @testSetup static void setup() {
        Account newAccount = new Account();
        newAccount.Name = 'Test Account';
        insert newAccount;
        
        
        Address__c address = new Address__c();
        address.Address_Type__c = 'B2B';
        address.Address_Format__c = 'ADR';
        address.Name__c = 'Nuvoco Plant Pune';
        address.Telephone__c = '8765432111';
        address.Email__c = 'punetest1234@nuvoco.com';
        address.Building__c = 'Avenues';
        address.Street2__c = '1st Street';
        insert address;
        
        Asset newAsset = new Asset();
        newAsset.Name= 'test Asset';
        newAsset.AccountId = newAccount.id;
        newAsset.Status = 'Pending QR Codes';
        newAsset.Coverage__c = 'KFTWC01200001';
        newAsset.Type_of_Warranty__c = 'Special Warranty';
        newAsset.Address_Code__c = address.id;
        insert newAsset;
    }
    @isTest
    static void testScheduler() {
        // Schedule the job
        Test.startTest();
        Datetime nextExecutionTime = Datetime.now().addMinutes(1);
        String jobId = System.schedule('GVLC Product Scheduler', '0 ' + nextExecutionTime.minute() + ' * * * ?', new GVLC_Product_Scheduler());
        Test.stopTest();
        
        System.assertEquals(1, [SELECT COUNT() FROM CronTrigger WHERE Id = :jobId]);
    }
}