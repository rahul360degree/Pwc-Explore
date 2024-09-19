/*------------------------------------------------------------------------
 * Author:        Shailja Mishra
 * Company:       Salesforce
 * Description:   Test class for MHEReceivablesApprovalHelper
 * Inputs:        NA
 * ---------------------------------------------------------------------------
 * History
 * 18-11-2020      Shailja Mishra     Initial Release
 * ----------------------------------------------------------------------------*/
@isTest
public class MHEReceivableApprovalHelperTest {
    @testsetup
    public static void testData() {
        Profile userProfile = [Select Id from Profile where Name = 'System Administrator' LIMIT 1];
        List<User> mheUsers = new List<User> {
            new TestUserBuilder().setLastName('SalesUser').setProfileId(userProfile.Id)
                .setBusinessUnit('K').getTestRecord(),
            new TestUserBuilder().setLastName('TeritorySalesManager').setProfileId(userProfile.Id)
                .setBusinessUnit('K').setAllowBusinessAccountCreation(true).setPersona('MHE Sales-Functional Head').getTestRecord(),
            new TestUserBuilder().setLastName('RegionalSalesManager').setProfileId(userProfile.Id)
                .setBusinessUnit('K').setAllowBusinessAccountCreation(true).setPersona('MHE Sales-Regional Head').getTestRecord(),
            new TestUserBuilder().setLastName('NationalSalesManager').setProfileId(userProfile.Id)
                .setBusinessUnit('K').setAllowBusinessAccountCreation(true).setPersona('MHE Sales-Marketing Manager').getTestRecord(),
            new TestUserBuilder().setLastName('MarketingHead').setProfileId(userProfile.Id)
                .setBusinessUnit('K').setAllowBusinessAccountCreation(true).setPersona('MHE Sales-Sales Head').getTestRecord()
        };
        insert mheUsers;
        
        mheUsers[0].ManagerId = mheUsers[1].Id;
        mheUsers[1].ManagerId = mheUsers[2].Id;
        mheUsers[2].ManagerId = mheUsers[3].Id;
        mheUsers[3].ManagerId = mheUsers[4].Id;
        update mheUsers;
        
        
        Billed_Sales_Outstandings__c bsoRec = new TestBilledSalesOutstandingsBuilder().setOwnerId(mheUsers[0].Id)
            .setBusinessUnit('K').getSavedTestRecord();
        Receivable__c receivableRec = new TestReceivableBuilder().setOwnerId(mheUsers[0].Id).setBCCode('KW')
            .setInvoice(bsoRec.Id).getSavedTestRecord();
    }
    
    @isTest private static void setFieldValuesWithEmptyWrapper(){
        Test.startTest();
        MHEReceivablesApprovalHelper.setFieldValues(new List<MHEReceivablesApprovalHelper.WriteOffReceivableWrapper>());
        Test.stopTest();
        List<Billed_Sales_Outstandings__c> billedSales = [Select Id, Approver_1__c from Billed_Sales_Outstandings__c Where Approver_1__c != null];
        System.assert(billedSales.size() == 0);
    }
    
    @isTest private static void setFieldValues(){
        Billed_Sales_Outstandings__c rc = [Select Id, OwnerId From Billed_Sales_Outstandings__c];
        MHEReceivablesApprovalHelper.WriteOffReceivableWrapper wrapper = new MHEReceivablesApprovalHelper.WriteOffReceivableWrapper();
        wrapper.receivableRecord = rc;
        
        List<MHEReceivablesApprovalHelper.WriteOffReceivableWrapper> wrappers = new List<MHEReceivablesApprovalHelper.WriteOffReceivableWrapper>();
        wrappers.add(wrapper);
        
        Test.startTest();
        MHEReceivablesApprovalHelper.setFieldValues(wrappers);
        Test.stopTest();
        List<Billed_Sales_Outstandings__c> billedSales = [Select Id, Approver_1__c from Billed_Sales_Outstandings__c Where Approver_1__c != null];
        System.assert(billedSales.size() == 1);
    }
}