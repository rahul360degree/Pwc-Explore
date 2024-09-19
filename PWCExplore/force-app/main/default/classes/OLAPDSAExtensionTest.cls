@isTest
public class OLAPDSAExtensionTest{

    @IsTest
    static void findAccountNameInformation() {
        Profile userProfile = [Select Id from Profile where Name = 'System Administrator' LIMIT 1];
        // Create User record.
        User userToRun = new User(EmailEncodingKey = 'UTF-8', firstName = 'WarehouseTest', lastname = 'User', Alias = 'tuser',
                            languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = userProfile.id,
                            timezonesidkey = 'Asia/Kolkata', email = 'test.user@godrej.com', username = 'warehousetest.user@godrej.com', Business_Unit__c = GlobalConstants.MHE_DIVISION_CODE);
        
        
        insert userToRun;
        System.runAs(userToRun) {
            Test.startTest();
            String accId ='0011h00000G1OjiAAB';
            List<sobject>  fieldString = DSACheckController.findAccountName(accId);
            Test.stopTest();
            System.assertNotEquals(null, fieldString);
        }

    }
    
    /*@IsTest
    static void findRecordsInformation() {
        Profile userProfile = [Select Id from Profile where Name = 'System Administrator' LIMIT 1];
        // Create User record.
        User userToRun = new User(EmailEncodingKey = 'UTF-8', firstName = 'WarehouseTest', lastname = 'User', Alias = 'tuser',
                            languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = userProfile.id,
                            timezonesidkey = 'Asia/Kolkata', email = 'test.user@godrej.com', username = 'warehousetest.user@godrej.com', Business_Unit__c = GlobalConstants.MHE_DIVISION_CODE);
        insert userToRun;
        System.runAs(userToRun) {
            Test.startTest();
            String  searchKey ='3HXOOO';
            String objectName = 'Account' ;
            List<sobject>  Stringvalue = DSACheckController.findRecords(searchKey,objectName);
            Test.stopTest();
            System.assertNotEquals(null, Stringvalue);
        }

    } */
    
        @IsTest
    static void findAccountCodeInformation() {
        Profile userProfile = [Select Id from Profile where Name = 'System Administrator' LIMIT 1];
        // Create User record.
        User userToRun = new User(EmailEncodingKey = 'UTF-8', firstName = 'WarehouseTest', lastname = 'User', Alias = 'tuser',
                            languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = userProfile.id,
                            timezonesidkey = 'Asia/Kolkata', email = 'test.user@godrej.com', username = 'warehousetest.user@godrej.com', Business_Unit__c = GlobalConstants.MHE_DIVISION_CODE);
        insert userToRun;
        System.runAs(userToRun) {
            Test.startTest();
            String accId ='0011h00000G1OjiAAA';
            String accName = 'Vijay Brothers' ;
            List<sobject>  Stringvalue = OLAPDSAExtension.findAccountCode(accId,accName);
            Test.stopTest();
            System.assertNotEquals(null, Stringvalue);
        }

    }
    
    @IsTest
    static void IsDealerInformation() {
        Profile userProfile = [Select Id from Profile where Name = 'System Administrator' LIMIT 1];
        // Create User record.
        User userToRun = new User(EmailEncodingKey = 'UTF-8', firstName = 'WarehouseTest', lastname = 'User', Alias = 'tuser',
                            languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = userProfile.id,
                            timezonesidkey = 'Asia/Kolkata', email = 'test.user@godrej.com', username = 'warehousetest.user@godrej.com', Business_Unit__c = GlobalConstants.MHE_DIVISION_CODE);
        
        
        insert userToRun;
        System.runAs(userToRun) {
            Test.startTest();
            String uid ='0011h00000G1OjiAAC';
            List<sobject>  fieldString = OLAPDSAExtension.IsDealer(uid);
            Test.stopTest();
            System.assertNotEquals(null, fieldString);
        }

    }

    
    
   @IsTest
    static void getAccountDetails() {   
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new MockDSAResponseGenerator());
            String requestObj = '{"BPCode":"3HX000001" ,"CloseBalYear":"2020","CloseBalMonth":"1","TransFromYear":"2020","TransFromMonth":"2","TransToYear":"2020","TransToMonth":"2","TransFromdt":"2019-05-01","TransTodt":"2019-05-28"}';
            String response = DSACheckController.getAccountDetails(requestObj);
            Test.stopTest();
            System.assertNotEquals(null, response);
    }
    
    
    @isTest
    static void testExceptionClass() {
           DSACheckerException exceptionObj = new DSACheckerException('msg', 'error');
  }
}