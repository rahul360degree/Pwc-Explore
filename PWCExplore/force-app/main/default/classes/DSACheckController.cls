/*------------------------------------------------------------------------
Author:        Shreela Nair
Company:       Godrej Infotech
Description:   Controller class for DSA LWC components.
Inputs:        NA
Test Class:    MockDSAResponseGenerator, OLAPDSAExtensionTest

History

----------------------------------------------------------------------------*/
public without sharing class DSACheckController {
    private static DSACheckController DSACHECKCONTROLLER_INSTANCE = new DSACheckController();
    private static final String API_TRANSACTION_SUCCESS_STATUS = System.Label.API_TRANSACTION_SUCCESS_STATUS;
    private static final String API_TRANSACTION_ERROR_STATUS = System.Label.API_TRANSACTION_ERROR_STATUS;
    
    @AuraEnabled
    public static String getAccountDetails(String accountdetails) {
        API_Transactions__c apiTransactionObj = DSACHECKCONTROLLER_INSTANCE.createAPITransactionObject();
        HttpResponse response;
        try {
            response = (new OLAPDSAExtension()).getAccountDetails(accountdetails);
            apiTransactionObj.End_Date__c = System.Now();
            apiTransactionObj.Status__c = API_TRANSACTION_SUCCESS_STATUS;
            insert apiTransactionObj;
            return response.getBody();
        } catch(DSACheckerException ex) {
            System.debug('Error has occurred :: DSACheckController-getAccountDetails');
            apiTransactionObj.End_Date__c = System.Now();
            apiTransactionObj.Status__c = API_TRANSACTION_ERROR_STATUS;
            apiTransactionObj.Error_Message__c = ex.getMessage();
            insert apiTransactionObj;
            throw new DSACheckerException(ex.getMessage());
        }
    }  
    /*------------------------------------------------------------------------
    Author:        Shreela Nair
    Company:       Godrej Infotech
    Description:   Method to create an instance of API_Transactions__c object with pre-populated start date value.
    Inputs:        
    Output Type:   API_Transactions__c
    Test Class:   

    History
    ----------------------------------------------------------------------------*/   
    private API_Transactions__c createAPITransactionObject() {
        API_Transactions__c apiTransactionObj = new API_Transactions__c();
        apiTransactionObj.Start_Date__c = System.now();
        return apiTransactionObj;
    }
    /*------------------------------------------------------------------------
    Author:        Siddhesh Mayekar
    Company:       Salesforce
    Description:   Method to fetch records of Account in Lookup based on Name/Account Code
    Inputs:        String searchKey, String objectName
    Output Type:   String
    Test Class:    

    History

    
    @AuraEnabled(cacheable=true)  
     public static List<sobject> findRecords(String searchKey, String objectName) { 
     string parentCode = '\'9P1%\''; 
     string searchText = '\'' + String.escapeSingleQuotes(searchKey) + '%\'';  
     string query = 'SELECT Id, Name, Account_Code__c FROM ' +objectName+ ' WHERE (Name LIKE '+searchText+' OR Account_Code__c LIKE '+searchText+') AND (NOT Account_Code__c like '+ parentCode +') LIMIT 6';  
     return Database.query('SELECT Id, Name,Account_Code__c FROM ' +objectName+ ' WHERE (Name LIKE '+searchText+' OR Account_Code__c LIKE '+searchText+') AND (NOT Account_Code__c like '+ parentCode +') LIMIT 6');  
    }
    ----------------------------------------------------------------------------*/
    /*------------------------------------------------------------------------
    Author:        Siddhesh Mayekar
    Company:       Salesforce
    Description:   Method to retrieve Account Name using Account Id
    Inputs:        String accId
    Output Type:   String
    Test Class:   

    History
    ----------------------------------------------------------------------------*/   

   @AuraEnabled(cacheable=true)  
   public static List<sobject> findAccountName(String accId) {  
      string accountsID = '\'' + String.escapeSingleQuotes(accId) + '\'';  
     string query = 'SELECT Id, Name FROM Account WHERE Id = '+accountsID+'';  
     return Database.query('SELECT Id, Name FROM Account WHERE Id = '+accountsID+''); 
   } 

}