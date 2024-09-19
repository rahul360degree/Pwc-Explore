@isTest 
public class FileExplorerFolderTriggerTest {
    @Testsetup static void Createddata(){
        Profile userProfile = [Select Id from Profile where Name = 'System Administrator' LIMIT 1];
        User userToRun = new User(EmailEncodingKey = 'UTF-8', firstName = 'Test', lastname = 'fileexplorer', Alias = 'tuser',
                                  languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = userProfile.id,
                                  timezonesidkey = 'Asia/Kolkata', email = 'test.user@godrej.com', username = 'test.user@godrej.com', Business_Unit__c = GlobalConstants.MHE_DIVISION_CODE);
        insert userToRun;
    }
    @isTest static void testfileexpfold() {
        user objUser  = [select Userrole.name, email from User where lastname = 'fileexplorer' Limit 1];
        System.runAs(objUser){ 
            Account accountRecord = new Account( FirstName = 'Test', LastName ='Person Account', PersonEmail = 'test@invalid.com', 
                                                RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Customer').getRecordTypeId());
            insert accountRecord;
            
            
            qsyd_FE__FileExplorerFolderTemplate__c feft = new qsyd_FE__FileExplorerFolderTemplate__c(qsyd_FE__IsActive__c = true,qsyd_FE__Label__c ='Zones');
            insert feft;
            qsyd_FE__FileExplorerFile__c filexpfol = new qsyd_FE__FileExplorerFile__c(qsyd_FE__IsDeleted__c = false,ownerid = objUser.id,qsyd_FE__LinkedEntityId__c = accountRecord.id);
            insert filexpfol;
            system.debug('check '+filexpfol.id);
        }
        
    }
    private static Address__c createPrimaryAddress(){
        ZipCode__c zipcd = new ZipCode__c(City_Name__c ='citytst', StateName__c = 'sttetst', name='zpcdtst');
        insert zipcd;
        Address__c addr = new Address__c(Street__c='strttst',ZipCode__c = zipcd.id,Name__c='Account for test class');
        return addr;
    }
}