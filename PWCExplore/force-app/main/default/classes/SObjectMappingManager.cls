public with sharing class SObjectMappingManager {

    public static List<SObject> doMapping(SObjectMapperConfigurator config){

        try{
            //Store object name vs mapping metadata record
            Map<String,List<sObject>> objectNameVsMetadataRecords = new Map<String,List<sObject>>();
            //Store object name vs list of records
            Map<String,List<sObject>> objectNameVsRecords = new Map<String,List<sObject>>();
            //Store all sobject records which will be inserted
            Map<String,sObject> sObjectsMap = new Map<String,sObject>();

            // Joshna - replaced the query fields list with the field list - to optimize save time
            String sRecordTypeFilter=' where RecordType__c like  \'%'+config.quoteRecordTypeDeveloperName+'%\'';
            String sQuery='Select Id, DeveloperName, Label, Source_Object_API_Name__c, Target_Object_Field_API_Name__c, Source_Object_Field_API_Name__c, '
                + 'Transaction_Type__c, RecordType__c' + ' FROM ' + config.metadataName;
            
            sQuery+=sRecordTypeFilter;
            List<sObject> mtdRecords = Database.query(sQuery);
			Set<String> targetFieldNames = new Set<String>();
            
            //Iterate over metadata records and construct map of object name vs metadat records
            for(sObject mtdRecord : mtdRecords){
                if(objectNameVsMetadataRecords.containsKey(String.valueOf(mtdRecord.get('Source_Object_API_Name__c')))){
                    objectNameVsMetadataRecords.get(String.valueOf(mtdRecord.get('Source_Object_API_Name__c'))).add(mtdRecord);
                }else{
                    objectNameVsMetadataRecords.put(String.valueOf(mtdRecord.get('Source_Object_API_Name__c')),new List<sObject>{mtdRecord});
                }
                // Joshna - added this to remove describe call and optimize logic
                targetFieldNames.add((String) mtdRecord.get('Target_Object_Field_API_Name__c'));
            }

            //Get all the fields related to the objects(source object) used for mapping 
            //will be required to validate the field names mentioned in metadata record  
            Map<String,Set<String>> sObjectFieldMap = new Map<String,Set<String>>();
            for(String sObjectName : objectNameVsMetadataRecords.keySet()){
                // Joshna - commented above if block and added below to remove describe calls
                Set<String> fieldList = new Set<String>();
                fieldList.add('Id');
                for (sObject each : objectNameVsMetadataRecords.get(sObjectName)) {
                    fieldList.add((String)each.get('Source_Object_Field_API_Name__c'));
                }
                sObjectFieldMap.put(sObjectName, fieldList);
            }
            //Get all the fields related to the target object used for mapping
            //will be required to validate the field names mentioned in metadata record
            sObjectFieldMap.put(config.targetObjectName, targetFieldNames); //QueryBuilder.getSObjectFields(config.targetObjectName,true));

            //Get record of all source objects used for mapping excluding target object
            for(String sObjectName : sObjectFieldMap.keySet()){
                if(sObjectName == config.targetObjectName) continue;
                
                // Joshna - added the next 2 lines to avoid query when right hand side is blank
                String whereClause = config.objetNameVsWhereClause.get(sObjectName);
                if (String.isBlank(whereClause) || whereClause.contains('null')) continue;
                
                String query = QueryBuilder.build(sObjectName,
                                            sObjectFieldMap.get(sObjectName),
                                            whereClause);
                List<sObject> sObjectRecord = Database.query(query);
                
                if(sObjectRecord != null && !objectNameVsRecords.containsKey(sObjectName)){
                    objectNameVsRecords.put(sObjectName,sObjectRecord);
                }
            }
            //Iterate over metadata record to populate the field of target object
            //If source object can have multiple object then first create equal no of target object records
            for(String objectName : objectNameVsMetadataRecords.keySet()){
                if(objectName == config.sourceObjectName 
                    && objectNameVsRecords.containsKey(objectName)
                    && sObjectFieldMap.containsKey(objectName)
                    && sObjectFieldMap.containsKey(config.targetObjectName)){
                    //Iterate over the mtd record to fill in data    
                    for(sObject sourceObject : objectNameVsRecords.get(config.sourceObjectName)){ 
                        sObject sObj = Schema.getGlobalDescribe().get(config.targetObjectName).newSObject();
                        //Set target object default values    
                        for(String fieldName : config.defaultValues.keySet()){
                            sObj.put(fieldName,config.defaultValues.get(fieldName));
                        }                  
                        for(sObject mtd : objectNameVsMetadataRecords.get(objectName)){
                            String toFieldName = String.valueOf(mtd.get('Target_Object_Field_API_Name__c'));
                            String sObjectFieldName = String.valueOf(mtd.get('Source_Object_Field_API_Name__c'));
                            String transactionType = String.valueOf(mtd.get('Transaction_Type__c'));
                            
                            //Validate if 'To Field' and 'From Field' have correct API Name
                            if(sObjectFieldMap.get(config.targetObjectName).contains(toFieldName)
                                && sObjectFieldMap.get(objectName).contains(sObjectFieldName)
                                && sourceObject.get(sObjectFieldName) != null
                                && (transactionType == config.transactionType || transactionType == GlobalConstants.ALL_TRANSACTION_TYPE)){
                                sObj.put(toFieldName,sourceObject.get(sObjectFieldName));  
                            }    
                        }
                        //Put all the record based on the source object id as key.
                        //This will be used to populate fields related to other object which will be same for all traget object records
                        sObjectsMap.put(String.valueOf(sourceObject.get(config.sourceObjectUniqueField)),sObj); 
                    }
                }
            }

            //Iterate over metadata record to populate the field of target object
            //If source object can have multiple object then first create equal no of target object records
            for(String objectName : objectNameVsMetadataRecords.keySet()){
                if(objectName != config.sourceObjectName 
                    && objectNameVsRecords.containsKey(objectName)
                    && objectNameVsRecords.get(objectName) != null 
                    && objectNameVsRecords.get(objectName).size() > 0
                    && sObjectFieldMap.containsKey(objectName)
                    && sObjectFieldMap.containsKey(config.targetObjectName)){
                    //Iterate over the mtd record to fill in data    
                    for(sObject sobj : sObjectsMap.values()){
                        //populate field from other objects for target object
                        //Iterate over all traget object records
                        for(sObject mtd : objectNameVsMetadataRecords.get(objectName)){
                            String toFieldName = String.valueOf(mtd.get('Target_Object_Field_API_Name__c'));
                            String sObjectFieldName = String.valueOf(mtd.get('Source_Object_Field_API_Name__c'));
                            String transactionType = String.valueOf(mtd.get('Transaction_Type__c'));
                            //Validate if 'To Field' and 'From Field' have correct API Name
                            if(sObjectFieldMap.get(config.targetObjectName).contains(toFieldName)
                                && sObjectFieldMap.get(objectName).contains(sObjectFieldName)
                                && objectNameVsRecords.get(objectName) != null 
                                && objectNameVsRecords.get(objectName).size() > 0
                                && objectNameVsRecords.get(objectName)[0].get(sObjectFieldName) != null
                                && (transactionType == config.transactionType || transactionType == GlobalConstants.ALL_TRANSACTION_TYPE)){  
                                sObj.put(toFieldName,objectNameVsRecords.get(objectName)[0].get(sObjectFieldName));
                            }
                        }
                    }
                }
            }
            return sObjectsMap.values();
        }catch(Exception ex){
        }
        return new List<sObject>();
    }
    
}