@isTest 
public class GlobalConstantsTest {
    @isTest 
    static void constantsCoverage() {
        String strDealer='Dealer';
        Test.startTest();
        system.assertEquals(strDealer, GlobalConstants.ACCOUNT_RECORDTYPE_DEALER);
        Test.stopTest();
    }
}