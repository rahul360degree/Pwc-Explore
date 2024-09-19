/*------------------------------------------------------------------------
Author:        Kartik Shetty
Company:       Salesforce
Description:   Processor class for 'Tax Number' Records
Inputs:        NA
Test Class:    
History
10-06-2020      Kartik Shetty     Initial Release.
----------------------------------------------------------------------------*/
public with sharing class TaxNumberRecordProcessor {
    private Map<Integer, String> panTaxNumberRecords_ErrorMessage = new Map<Integer, String>();
    private Map<Integer, String> gstTaxNumberRecords_ErrorMessage = new Map<Integer, String>();
    
    private final static String GSTIN_VALUES = 'GSTIN';
    private final static String PAN_VALUES = 'PAN';
    private final static String UNREGISTERED_NO = 'No';
    private final static String ONE_TO_BP_NO = 'No';
    
    // Function to get Associated accounts and their existing Tax Number records.
    private List<Account> getAssociatedAccountRecords(List<Id> accountIds) {
        List<Account> associatedAccounts = new List<Account>([Select Id, One_Time_Business_Partner__c, 
                                                              (Select Id, Un_registered__c, Category__c, Tax_Number__c FROM Tax_Numbers__r WHERE Category__c = :PAN_VALUES)
                                                              FROM Account WHERE Id = :accountIds
                                                             ]);
        return associatedAccounts;
    }
    
    // Function to get tax number records of type PAN and GST and their associated Accounts and existing child tax number records.
    private Map<String, List<sObject>> get_PAN_GST_AndAssociatedAccountRecords(List<Tax_Number__c> taxNumberRecords) {
        List<Tax_Number__c> panTaxNumberRecords = new List<Tax_Number__c>();
        List<Tax_Number__c> gstTaxNumberRecords = new List<Tax_Number__c>();
        List<Account> associatedAccounts = new List<Account>();
        Map<String, List<sObject>> dataMapToReturn = new Map<String, List<sObject>>();
        
        List<Id> accountIdsToFetch = new List<Id>();
        
        // Split out PAN and GST Tax Number records.
        for(Tax_Number__c taxNumberRecord : taxNumberRecords) {
            if(taxNumberRecord.Category__c != null && 
               taxNumberRecord.Un_registered__c == UNREGISTERED_NO) {
                   if(taxNumberRecord.Category__c.toUpperCase() == PAN_VALUES) {
                       panTaxNumberRecords.add(taxNumberRecord);
                       accountIdsToFetch.add(taxNumberRecord.Business_Partner__c);
                   } else if(taxNumberRecord.Category__c.toUpperCase() == GSTIN_VALUES) {
                       gstTaxNumberRecords.add(taxNumberRecord);
                       accountIdsToFetch.add(taxNumberRecord.Business_Partner__c);
                   }
               }
        }
        
        // Get the associated account records for both PAN and GST Tax Number records.
        if(accountIdsToFetch.size() > 0) associatedAccounts = getAssociatedAccountRecords(accountIdsToFetch);
        
        // Store the records into Map and return the Map.
        dataMapToReturn.put('PAN_RECORDS', panTaxNumberRecords);
        dataMapToReturn.put('GST_RECORDS', gstTaxNumberRecords);
        dataMapToReturn.put('ACCOUNT_RECORDS', associatedAccounts);
        return dataMapToReturn;
        
    }
    
    // Main input function.
    public void performTaxNumberValidations(List<Tax_Number__c> taxNumberRecords) {
        Profile profile = [Select Id,Name from Profile where id=:Userinfo.getProfileId() ];
                if(profile.name!='Integration Administrator'){
                
        // Identify and seperate the GST and PAN based Tax Number records.
        Map<String, List<sObject>> recordMap = get_PAN_GST_AndAssociatedAccountRecords(taxNumberRecords);
        
        List<Tax_Number__c> panTaxNumberRecords = (List<Tax_Number__c>) recordMap.get('PAN_RECORDS');
        List<Tax_Number__c> gstTaxNumberRecords = (List<Tax_Number__c>) recordMap.get('GST_RECORDS');
        Map<Id, Account> associatedAccountRecords = new Map<Id, Account>((List<Account>) recordMap.get('ACCOUNT_RECORDS'));
        
        // Perform PAN and GST specific validations.
        if(panTaxNumberRecords.size() > 0) {
            performPanBasedValidations(panTaxNumberRecords, associatedAccountRecords);
            throwErrorOnScreenForRecords(panTaxNumberRecords, panTaxNumberRecords_ErrorMessage);
        }
        if(gstTaxNumberRecords.size() > 0) {
            performGSTBasedValidations(gstTaxNumberRecords, associatedAccountRecords);
            throwErrorOnScreenForRecords(gstTaxNumberRecords, gstTaxNumberRecords_ErrorMessage);
        }
        }
    }
    
    // Method to perform PAN based validations.
    private void performPanBasedValidations(List<Tax_Number__c> panTaxNumberRecords, Map<Id, Account> associatedAccountMap) {
        for(Integer i = 0; i < panTaxNumberRecords.size(); i++) {
            Account associatedAccount = associatedAccountMap.get(panTaxNumberRecords[i].Business_Partner__c);
            pan_LengthValidation(panTaxNumberRecords[i], i);
            if(associatedAccount.One_Time_Business_Partner__c == ONE_TO_BP_NO) {
                pan_PatternValidation(panTaxNumberRecords[i], i);
            }
        }
    }
    
    private void pan_LengthValidation(Tax_Number__c panTaxNumberRecord, Integer index) {
        Integer PAN_NUMBER_LENGTH = 10;
        if(panTaxNumberRecord.Tax_number__c.length() != PAN_NUMBER_LENGTH) {
            addErrorMessage(index, System.Label.PAN_Number_length, panTaxNumberRecords_ErrorMessage);
        }
    }
    
    private void pan_PatternValidation(Tax_Number__c panTaxNumberRecord, Integer index) {
        Integer PAN_NUMBER_LENGTH = 10;
        if( panTaxNumberRecord.Tax_number__c.length() == PAN_NUMBER_LENGTH && !((panTaxNumberRecord.Tax_Number__c).substring(0, 5)).isAlpha() ) {
            addErrorMessage(index, System.Label.PAN_first_five_characters, panTaxNumberRecords_ErrorMessage);
        }
        if( panTaxNumberRecord.Tax_number__c.length() == PAN_NUMBER_LENGTH && !((panTaxNumberRecord.Tax_Number__c).substring(5, 9)).isNumeric()) {
            addErrorMessage(index, System.Label.PAN_five_to_nine_characters_message, panTaxNumberRecords_ErrorMessage);
        }
        if( panTaxNumberRecord.Tax_number__c.length() == PAN_NUMBER_LENGTH && !((panTaxNumberRecord.Tax_Number__c).substring(9, 10)).isAlpha() ) {
            addErrorMessage(index, System.Label.PAN_last_character_should_be_alphabetic, panTaxNumberRecords_ErrorMessage);
        }
    }
    
    // Method to perform GST based validations.
    private void performGSTBasedValidations(List<Tax_Number__c> gstTaxNumberRecords, Map<Id, Account> associatedAccountMap) {
        for(Integer i=0; i < gstTaxNumberRecords.size(); i++) {
            Account associatedAccount = associatedAccountMap.get(gstTaxNumberRecords[i].Business_Partner__c);
            gst_LengthValidation(gstTaxNumberRecords[i], i);
            if(associatedAccount.One_Time_Business_Partner__c == ONE_TO_BP_NO) {
                gst_PatternValidation(gstTaxNumberRecords[i], i);
                checkForMatchingPANFromGST(gstTaxNumberRecords[i], i, associatedAccount.Tax_Numbers__r);
            }   
        }   
    }
    
    private void gst_LengthValidation(Tax_Number__c gstTaxNumberRecord, Integer index) {
        Integer GST_NUMBER_LENGTH = 15;
        if(gstTaxNumberRecord.Tax_number__c.length() != GST_NUMBER_LENGTH) {
            addErrorMessage(index, System.Label.GST_character_limit, gstTaxNumberRecords_ErrorMessage);
        }
    }
    
    private void gst_PatternValidation(Tax_Number__c gstTaxNumberRecord, Integer index) {
        Integer GST_NUMBER_LENGTH = 15;
        if( gstTaxNumberRecord.Tax_number__c.length() == GST_NUMBER_LENGTH && !((gstTaxNumberRecord.Tax_Number__c).substring(0, 2)).isNumeric() ) {
            addErrorMessage(index, System.Label.GST_first_two_characters, gstTaxNumberRecords_ErrorMessage);
        }
        if( gstTaxNumberRecord.Tax_number__c.length() == GST_NUMBER_LENGTH && !((gstTaxNumberRecord.Tax_Number__c).substring(2, 7)).isAlpha()) {
            addErrorMessage(index, System.Label.GST_three_to_seven_should_be_alphabetic, gstTaxNumberRecords_ErrorMessage);
        }
        if( gstTaxNumberRecord.Tax_number__c.length() == GST_NUMBER_LENGTH && !((gstTaxNumberRecord.Tax_Number__c).substring(7, 11)).isNumeric() ) {
            addErrorMessage(index, System.Label.GST_character_eight_to_eleven_should_be_numeric, gstTaxNumberRecords_ErrorMessage);
        }
        if( gstTaxNumberRecord.Tax_number__c.length() == GST_NUMBER_LENGTH && !((gstTaxNumberRecord.Tax_Number__c).substring(11, 12)).isAlpha() ) {
            addErrorMessage(index, System.Label.GST_twelfth_character_should_be_alphabetic, gstTaxNumberRecords_ErrorMessage);
        }
        if( gstTaxNumberRecord.Tax_number__c.length() == GST_NUMBER_LENGTH && !((gstTaxNumberRecord.Tax_Number__c).substring(12, 15)).isAlphanumeric()) {
            addErrorMessage(index, System.Label.GST_characters_thirteen_to_fifteen_should_be_only_alphabetic_or_numeric, gstTaxNumberRecords_ErrorMessage);
        }
    }
    
    // Function to get matching PAN records from Tax Number records that are associated with same account.
    private void checkForMatchingPANFromGST(Tax_Number__c gstTaxNumberRecord, Integer index, List<Tax_Number__c> siblingTaxNumberRecords) {
        Set<String> siblingPAN_Numbers = new Set<String>();
        Integer GST_NUMBER_LENGTH = 15;
        for(Tax_Number__c taxNumberRecord : siblingTaxNumberRecords) {
            siblingPAN_Numbers.add(taxNumberRecord.Tax_Number__c);
        }
        String PAN_STRING = gstTaxNumberRecord.Tax_Number__c.length() == GST_NUMBER_LENGTH ? (gstTaxNumberRecord.Tax_Number__c).substring(2, 12) : null;
        if(PAN_STRING!= null && !siblingPAN_Numbers.contains(PAN_STRING)) {
            addErrorMessage(index, System.Label.No_matching_PAN_from_GST, gstTaxNumberRecords_ErrorMessage);
        }
    }
    
    private void addErrorMessage(Integer key, String errorMessage, Map<Integer, String> errorHolderDS) {
        String message = 'There are some errors with this record: <br>';
        if(errorHolderDS.containsKey(key)) {
            message = errorHolderDS.get(key);
        }
        message = message + errorMessage + '<br>';
        errorHolderDS.put(key, message);
    }
    
    private void throwErrorOnScreenForRecords(List<Tax_Number__c> listRecordHolders, Map<Integer, String> errorHolderDS) {
        for(Integer i=0; i<listRecordHolders.size(); i++) {
            if(errorHolderDS.containsKey(i)) {
                listRecordHolders[i].addError(errorHolderDS.get(i), false);
            }
        }
    }
/*------------------------------------------------------------------------
Author:        Alpana Sahay
Company:       GITL
Description:   Method to get the tax details from SOAP Request and associate it 
               either with Actual account or dummy account
Inputs:        List of Tax Number records
Test Class:    TaxNumberRecordProcessorTest
History
21-10-2022      Alpana     Initial Release.
----------------------------------------------------------------------------*/
    public void populateDefaults(List<Tax_Number__c> taxNumberRecords){
        Profile profile = [Select Id,Name from Profile where id=:Userinfo.getProfileId() ];
                if(profile.name=='Integration Administrator'){
        List <String> lstBPCodes = New list <String>();
        Map<String,Id> mapAccounts= new Map<String,Id>();             
        for(Integer i=0; i < taxNumberRecords.size(); i++) { 
            if (taxNumberRecords[i].Tax_Number_Ext__c != null){    
                lstBPCodes.add((taxNumberRecords[i].Tax_Number_Ext__c).substring(0,9));
                if (lstBPCodes.Size()>0){                
                    mapAccounts = createAccountMap(lstBPCodes);
                } 
            }  
        }        
        for(Integer i=0; i < taxNumberRecords.size(); i++) { 
            if (mapAccounts.containsKey((taxNumberRecords[i].Tax_Number_Ext__c)))
            {
                taxNumberRecords[i].Business_Partner__c = mapAccounts.get((taxNumberRecords[i].Tax_Number_Ext__c).substring(0,9));
            }
            else
            {
                taxNumberRecords[i].Business_Partner__c = System.Label.Dummy_Account;
            }
        } 
        
        }       
    }    
/*------------------------------------------------------------------------
Author:       Alpana Sahay
Company:      GITL
Description:  Method to get the account from SOAP Request
Inputs:       List of Account records
Test Class:   TaxNumberRecordProcessorTest 
History
21-10-2022    Alpana     Initial Release.
----------------------------------------------------------------------------*/
    private Map<String,Id> createAccountMap(List<String> lstBPCodes)
    {
        Map<String,Id> mapAccounts= new Map<String,Id>();
        List<Account> associatedAccounts = new List<Account>([Select Id, Account_Code__c, One_Time_Business_Partner__c
                                                              FROM Account WHERE Account_Code__c = :lstBPCodes            
                                                             ]);
        for(Integer i=0; i < associatedAccounts.size(); i++) {                       
            mapAccounts.put(associatedAccounts[i].Account_Code__c,associatedAccounts[i].Id );
        }
        return mapAccounts;        
    }    
}