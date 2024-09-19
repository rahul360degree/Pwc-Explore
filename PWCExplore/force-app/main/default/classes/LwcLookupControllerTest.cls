/*------------------------------------------------------------------------
Author:        Kishor Kumar
Company:       Salesforce
Description:   Test class for LwcLookupController
Inputs: 

History
12-09-2023     Shreela Nair    For covering LOC written to fetch only PES Active  users for SPEP - 24


----------------------------------------------------------------------------*/
@isTest
public class LwcLookupControllerTest {
	
    @testsetup
    private static void testData() {
        Account newAccount = new Account();
        newAccount.Name = 'Test Account';
        insert newAccount;
        
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
        
        Asset newAsset = new Asset();
        newAsset.Name= 'Test Asset';
        newAsset.AccountId = newAccount.id;
        newAsset.Address_Code__c = address.id;		//Added by pc
        newAsset.Status = 'Active';//Added Active instead of Purchased as now only Active assets are to be shown
        insert newAsset;
        
        // Create User record  by Shreela on 12th Sept 2023 for SPEP - 24
        Profile userProfile = [Select Id from Profile where Name = 'PES Sales And Marketing User' LIMIT 1];
        User userToRun = new User(EmailEncodingKey = 'UTF-8', firstName = 'Test', lastname = 'PES User', Alias = 'tpesuser',
                                  languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = userProfile.id,
                                  timezonesidkey = 'Asia/Kolkata', email = 'test.pesuser@godrej.com', username = 'test.pesuser@godrej.com',
                                  Business_Unit__c = GlobalConstants.PES_BUSINESS_UNIT,IsActive=true);
        
        insert userToRun;
    }
    
    @isTest private static void testfindRecords(){
        test.startTest();        
        Asset newAsset = [SELECT Id, Name, Status FROM Asset WHERE Name = 'Test Asset' LIMIT 1];
        
        List<sobject> sobjList = LwcLookupController.findRecords('Tes', 'Asset',newAsset.Status, 'Status','');//Modified by Shreela on 12th Sept 2023 for SPEP-24
        test.stopTest();          
        System.assert(sobjList.size() > 0);
            
    }
    
    //Added by Shreela on 12th Sept 2023 for SPEP-24
    @isTest private static void testfindRecords2(){
        test.startTest();        
        User us = [Select Id,Name,Business_Unit__c FROM User LIMIT 1]; 
        
        List<sobject> sobjList = LwcLookupController.findRecords('Tes', 'User','', '',GlobalConstants.contextIdValue);
        test.stopTest();   
        Boolean recExist = false;
        // Loop through the list
        for (SObject obj : sobjList) {
            if (obj.get('Name') == 'Test PES User') {
                recExist = true;
                break; // Exit the loop once the condition satisfies
            }
        }
        
        Assert.areEqual(true,recExist);
        
    }
}