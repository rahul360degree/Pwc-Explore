/*------------------------------------------------------------------------
Author:        Kartik Shetty
Company:       Salesforce
Description:   Apex class called from the genericLookupLWCComponent
Inputs:        NA
Test Class:    GenericLookupComponentControllerTest
History
15-10-2020      Kartik Shetty     Initial Release
----------------------------------------------------------------------------*/
public with sharing class GenericLookupComponentController {

    /*------------------------------------------------------------------------
    Author:        Kartik Shetty
    Company:       Salesforce
    Description:   Method to get object records along with the fields based on the search key and filter fields passed from LWC component
    Inputs:        String searchKey, String objectName, String fieldNames, String additionalFieldsToGet
    Outputs:       List<sObject>
    Test Class:   

    History
    ----------------------------------------------------------------------------*/
    @AuraEnabled
    public static List<sObject> findRecords(String searchKey, String objectName, String fieldNames, String additionalFieldsToGet) {
        try {
            Integer recordRetrievelLimit = 50000;
            String query = 'SELECT Id';

            // Create string to get all the fields.
            if(String.isNotBlank(additionalFieldsToGet)) {
                List<String> fieldsToGet = additionalFieldsToGet.split(',');
                for(String fieldAPIName : fieldsToGet) {
                    query += ', ' + fieldAPIName.trim();
                }
            }
            
            String searchText = '\'%' + String.escapeSingleQuotes(searchKey) + '%\'';
            query += ' FROM ' + objectName + ' WHERE ';

            // Fields to filter/search the data.
            List<String> filterFields = fieldNames.split(',');
            Boolean firstField = true;
            for(String filterFieldAPIName : filterFields) {
                if(!firstField) {
                    query += ' OR ';
                }
                query += filterFieldAPIName.trim() + ' LIKE ' + searchText;
                firstField = false;
            }
            query += ' LIMIT ' + recordRetrievelLimit;
            System.debug(query);
            return Database.query(query);
        } catch(LookupComponentControllerException exceptionObj) {
            throw new LookupComponentControllerException(exceptionObj.getMessage());
        }
    } 

    public class LookupComponentControllerException extends Exception {}
}