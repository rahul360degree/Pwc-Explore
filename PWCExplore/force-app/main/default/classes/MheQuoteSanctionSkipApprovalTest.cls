@isTest
public class MheQuoteSanctionSkipApprovalTest {
    static testmethod void testValidation(){
        User user = [Select Id from User where Id=:userinfo.getUserId()];
        System.runAs(user) {
            Test.startTest();
            MheQuoteSanctionSkipApprovalValidation.skipLockedValidation();
            System.assertEquals(GlobalConstants.SKIP_QUOTE_LOCK, true);
            Test.stopTest();
        }
        
    }
}