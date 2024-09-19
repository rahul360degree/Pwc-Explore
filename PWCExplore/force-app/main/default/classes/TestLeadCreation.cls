/*------------------------------------------------------------------------------------
 * Author        :        Stetig Consulting
 * Description   :        Test method for lead creation
 * History
 * --------
 * 06-12-2021     :    Initial Release
 * ----------------------------------------------------------------------------------*/
@isTest
public with sharing class TestLeadCreation {
    static testmethod void testLeadCreation() {
        Id accoundId1 = LeaseTestDataFactory.createAccountFromName('Test Stetig Ltd.');
        Id contactId1 = LeaseTestDataFactory.createContact(accoundId1);
        
        Id ipcAccoundId = LeaseTestDataFactory.createIpcAccountFromName('Test Ipc Ltd.');
        Id ipcContactId = LeaseTestDataFactory.createContact(ipcAccoundId);
        
        List<Account> ipcAccountList = [select Id, Name, ParentId, RecordTypeId, Account_Code__c, Account_Series__c, Type 
                            from Account 
                            where Id =: ipcAccoundId];
		test.StartTest();
        Id leasingUserId = LeaseTestDataFactory.createLeasingUser();
        User u = [Select Id from User where Id =: leasingUserId];
        System.RunAs(u) {
            
		parentAccountSearchController.fetchRecordTypes(ElbConstantsClass.LEAD_API);
        parentAccountSearchController.getLeadRecordTypeId();
        parentAccountSearchController.fetchContactDetails(contactId1);
        parentAccountSearchController.getContacts(accoundId1);
        parentAccountSearchController.fetchChildAccountId(accoundId1);
        
        //Testing scenario where account contact is present and ipc contact is not there
        parentAccountSearchController.IpcContactWrapper contactwrap = new parentAccountSearchController.IpcContactWrapper();
        contactwrap.updatedAccountIdIpc = accoundId1;
        contactwrap.updatedContactEmailIpc = 'test.acc@gmail.com';
        contactwrap.updatedContactMobileIpc = '7777666655';
        contactwrap.updatedContactNameIpc = 'Test Ipc Contact';
        parentAccountSearchController.createNewContactIpcRecord(contactwrap);
        parentAccountSearchController.LeadObjectWrapper leadwrap = new parentAccountSearchController.LeadObjectWrapper();
        leadwrap.updatedContactOld = contactId1;
        leadwrap.updatedParentAccountId = accoundId1;
        leadwrap.updatedParentAccountName = 'Test Stetig Ltd.';
        parentAccountSearchController.createNewLeadRecord(leadwrap);
        
        //Testing scenario where account contact is present and ipc contact is there
        parentAccountSearchController.IpcContactWrapper contactwrap1 = new parentAccountSearchController.IpcContactWrapper();
        contactwrap1.updatedAccountIdIpc = accoundId1;
        contactwrap1.updatedContactEmailIpc = 'test.acc@gmail.com';
        contactwrap1.updatedContactMobileIpc = '7777666655';
        contactwrap1.updatedContactNameIpc = 'Test Ipc Contact';
        parentAccountSearchController.createNewContactIpcRecord(contactwrap1);
        parentAccountSearchController.LeadObjectWrapper leadwrap1 = new parentAccountSearchController.LeadObjectWrapper();
        leadwrap1.updatedContactOld = contactId1;
        leadwrap1.updatedContactIdIpc = ipcContactId;
        leadwrap1.updatedParentAccountId = accoundId1;
        leadwrap1.updatedContactValueIpc = ipcAccoundId;
        leadwrap1.updatedContactNameIpc = contactwrap1.updatedContactNameIpc;
        leadwrap1.updatedAccountName = 'Test Stetig';
        leadwrap1.updatedName = 'Test';
        leadwrap1.updatedFirstName = ' ';
        leadwrap1.updatedLastName = ' ';
        parentAccountSearchController.createNewLeadRecord(leadwrap1);
        
        //Testing when both account contact and ipc contact is not present
        parentAccountSearchController.IpcContactWrapper contactwrap2 = new parentAccountSearchController.IpcContactWrapper();
        contactwrap2.updatedAccountIdIpc = accoundId1;
        contactwrap2.updatedContactEmailIpc = 'test.acc@gmail.com';
        contactwrap2.updatedContactMobileIpc = '7777666655';
        contactwrap2.updatedContactNameIpc = 'Test Ipc Contact';
        parentAccountSearchController.createNewContactIpcRecord(contactwrap2);
        parentAccountSearchController.LeadObjectWrapper leadwrap2 = new parentAccountSearchController.LeadObjectWrapper();
        leadwrap2.updatedParentAccountId = accoundId1;
        leadwrap2.updatedName = 'Test Name';
        leadwrap2.updatedFirstName = 'Test';
        leadwrap2.updatedLastName = 'Name';
        parentAccountSearchController.createNewLeadRecord(leadwrap2);
        
        parentAccountSearchController.getIpcAccounts(ipcAccountList[0].Name);
        parentAccountSearchController.fetchContactIpc(ipcAccoundId);
            
        SearchController.fetchLookupData('Test','Account');
        SearchController.fetchDefaultRecord((RecordTypeUtils.getInstance()).getRecordTypeId('Account', 'Business_Account'),'Account');
        }
        test.stopTest();
    }
}