@isTest
public class TestFileExplorerFolderTrigger {
    @Testsetup static void Createddata(){
        Profile userProfile = [Select Id from Profile where Name = 'System Administrator' LIMIT 1];
        User userToRun = new User(EmailEncodingKey = 'UTF-8', firstName = 'Test', lastname = 'fileexplorer', Alias = 'tuser',
                            languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = userProfile.id,
                            timezonesidkey = 'Asia/Kolkata', email = 'test.user@godrej.com', username = 'test.user@godrej.com', Business_Unit__c = GlobalConstants.MHE_DIVISION_CODE);
       insert userToRun;
    }
    @isTest static void testfileexpfold() {
        //user U  = [select Userrole.name, email from User where userrole.name ='Interio B2B Ho-Natl KAM COO' Limit 1];
        user U  = [select Userrole.name, email from User where lastname ='fileexplorer' LIMit 1];
        System.runAs(U){
        qsyd_FE__FileExplorerFolderTemplate__c feft = new qsyd_FE__FileExplorerFolderTemplate__c(qsyd_FE__IsActive__c = true,qsyd_FE__Label__c ='Zones(CP)');
        insert feft;
        qsyd_FE__FileExplorerFolder__c filexpfol = new qsyd_FE__FileExplorerFolder__c(qsyd_FE__IsDeleted__c = false,ownerid = u.id,qsyd_FE__LinkedEntityId__c = feft.id);
        insert filexpfol;
            }
    }
}