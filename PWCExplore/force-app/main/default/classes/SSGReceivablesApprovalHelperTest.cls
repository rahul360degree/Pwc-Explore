/*------------------------------------------------------------------------
 * Author:        Shailja Mishra
 * Company:       Salesforce
 * Description:   Test class for SSGReceivablesApprovalHelper
 * Inputs:        NA
 * ---------------------------------------------------------------------------
 * History
 * 18-11-2020      Shailja Mishra     Initial Release
 * ----------------------------------------------------------------------------*/
@isTest
public class SSGReceivablesApprovalHelperTest {
    @testsetup
    public static void testData() {
        Profile userProfile = [Select Id from Profile where Name = 'System Administrator' LIMIT 1];
        List<User> ssgUsers = new List<User> {
            new TestUserBuilder().setLastName('SalesUser').setProfileId(userProfile.Id)
                .setBusinessUnit('G').getTestRecord(),
            new TestUserBuilder().setLastName('TeritorySalesManager').setProfileId(userProfile.Id)
                .setBusinessUnit('G').setAllowBusinessAccountCreation(true).setPersona('SSG- Territory Sales Manager').getTestRecord(),
            new TestUserBuilder().setLastName('RegionalSalesManager').setProfileId(userProfile.Id)
                .setBusinessUnit('G').setAllowBusinessAccountCreation(true).setPersona('SSG- Regional sales manager (Domestic )').getTestRecord(),
            new TestUserBuilder().setLastName('NationalSalesManager').setProfileId(userProfile.Id)
                .setBusinessUnit('G').setAllowBusinessAccountCreation(true).setPersona('SSG- National sales manager (Regular)').getTestRecord(),
            new TestUserBuilder().setLastName('MarketingHead').setProfileId(userProfile.Id)
                .setBusinessUnit('G').setAllowBusinessAccountCreation(true).setPersona('SSG- Sales & Marketing Head').getTestRecord()
        };
        insert ssgUsers;
        
        ssgUsers[0].ManagerId = ssgUsers[1].Id;
        ssgUsers[1].ManagerId = ssgUsers[2].Id;
        ssgUsers[2].ManagerId = ssgUsers[3].Id;
        ssgUsers[3].ManagerId = ssgUsers[4].Id;
        update ssgUsers;
        
        Billed_Sales_Outstandings__c bsoRec = new TestBilledSalesOutstandingsBuilder().setOwnerId(ssgUsers[0].Id).setBusinessUnit('G').getSavedTestRecord();
    }
    
    @isTest private static void setFieldValuesWithEmptyWrapper(){
        Test.startTest();
        SSGReceivablesApprovalHelper.setFieldValues(new List<SSGReceivablesApprovalHelper.WriteOffReceivableWrapper>());
        Test.stopTest();
        List<Billed_Sales_Outstandings__c> billedSales = [Select Id, Approver_1__c from Billed_Sales_Outstandings__c Where Approver_1__c != null];
        System.assert(billedSales.size() == 0);
    }
    
    @isTest private static void setFieldValues(){
        Billed_Sales_Outstandings__c rc = [Select Id, OwnerId From Billed_Sales_Outstandings__c];
        SSGReceivablesApprovalHelper.WriteOffReceivableWrapper wrapper = new SSGReceivablesApprovalHelper.WriteOffReceivableWrapper();
        wrapper.receivableRecord = rc;
        
        List<SSGReceivablesApprovalHelper.WriteOffReceivableWrapper> wrappers = new List<SSGReceivablesApprovalHelper.WriteOffReceivableWrapper>();
        wrappers.add(wrapper);
        
        Test.startTest();
        SSGReceivablesApprovalHelper.setFieldValues(wrappers);
        Test.stopTest();
        List<Billed_Sales_Outstandings__c> billedSales = [Select Id, Approver_1__c from Billed_Sales_Outstandings__c Where Approver_1__c != null];
        System.assert(billedSales.size() == 1);
    }
}