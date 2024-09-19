public with sharing class LwcLookupController {
    @AuraEnabled(cacheable=true)  
    public static List<sobject> findRecords(String searchKey, String objectName,string filterValue,string fieldFilterApiName,String contextId) { //Added contextId parameter by Shreela on 11th Sept for SPEP-24
        string searchText = '\'' + String.escapeSingleQuotes(searchKey) + '%\'';
        String query = 'SELECT ';
        String assetStatus = GlobalConstants.ASSET_ACTIVE_STATUS;
        if(objectName.equalsIgnoreCase('Asset')) {
            for(Schema.FieldSetMember field : SObjectType.Asset.FieldSets.AssetFieldSetForPlanSelection.getFields()) {
                query += field.getFieldPath() + ', ';
            }    
        }
        if(objectName.equalsIgnoreCase('Account')) {
             query += 'Account_Code__c, ';
        }
        query += 'Id,Name FROM ' +objectName+ ' WHERE Name LIKE '+searchText;
        if(String.isNotBlank(filterValue) && String.isNotBlank(fieldFilterApiName)) {
            query+= ' AND '+fieldFilterApiName+' =\''+filterValue+'\'';   
        }
        
        //Added this IF Block to filter by entered BP Code too
        if(objectName.equalsIgnoreCase('Account')) {
            query+= ' OR Account_Code__c LIKE '+searchText;  
        }

        if(objectName.equalsIgnoreCase('Asset')) {
            //list<String> assetStatus = GlobalConstants.ASSET_SCRAPPED_STATUS; //earlier
            //String assetStatus = GlobalConstants.ASSET_ACTIVE_STATUS;
            //query+= ' AND Status NOT IN :  assetStatus '; //earlier
            //query+= ' AND Status IN :  assetStatus '; 
            //query+= ' AND Status' =\''+assetStatus+'\'';
            query+= ' AND Status = \''+assetStatus+'\'';//Added so that ONLY Active assets can be looked up from 
        }
        
        //Added by Shreela on 11th Sept 2023  for SPEP- 24
        //Fetching PES Active users in LWC Lookup 
         if(objectName.equalsIgnoreCase(GlobalConstants.User_Object) && contextId == GlobalConstants.contextIdValue) {
             query+= ' AND Business_Unit__c =\''+GlobalConstants.PES_BUSINESS_UNIT+'\' and IsActive=true ';
             
         }

        query+= ' LIMIT 1000';
        return Database.query(query);  
    }
}