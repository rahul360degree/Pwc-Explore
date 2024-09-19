/*------------------------------------------------------------------------
Author:        Nupoor Sharma
Company:       Salesforce
Description:   Helper for creating renewal opportunities
Inputs:        
Test Class:    MHERentalRenewalBatchTest

History
17-06-2020      Nupoor Sharma     Initial Release
----------------------------------------------------------------------------*/
public without sharing class RenewalHelper 
{

    /**************************************************   Generic Helper Methods  *************************************************************/
    
    /* 
     * getApplicationSetting()
     * Purpose - Fetches the Application_Settings__mdt value for a provided DeveloperName
     * @return String - Value for the specified application setting
     */
    public static String getApplicationSetting(String developerName)
    {
        String settingVal = 'Application Setting Not Found';
        ApplicationSettingUtil appSettingObj = ApplicationSettingUtil.getInstance();
        
        if(!appSettingObj.developerNameWithValueMap.isEmpty() 
           && appSettingObj.developerNameWithValueMap.containsKey(developerName.toUpperCase()) )
                settingVal = appSettingObj.developerNameWithValueMap.get(developerName.toUpperCase());
        
        return settingVal;
    }
    

    /* 
     * createLog()
     * Purpose - Helps create one record of Application Log
     */
    public static Application_Log__c createLog(String sourceClassName, String sourceMethodName, String referenceId, String errorMessage)
    {
        Application_Log__c logRecord = new Application_Log__c(Type__c = GlobalConstants.LOG_TYPE.ERROR.name(),
                                                              Source_Apex_Class__c = sourceClassName,
                                                              Source_Function__c = sourceMethodName,
                                                              Message__c = 'ERROR: ' + errorMessage,
                                                              Record_ID__c = referenceId,
                                                              User__c = UserInfo.getUserId());
        return logRecord;    
    }


    /* prepareMetadata()
     * @param sourceObjectAPIName - Source Object API Name from Renewals_Mapping__mdt data
     * @param targetObjectAPIName - Target Object API Name from Renewals_Mapping__mdt data
     * @param recordTypeDeveloperName - recordtype for which the Renewals_Mapping__mdt data applies
     * @return Map<String, String> - Source Field API Name as key and Target Field API Name as value
     */
    public static Map<String, String> prepareMetadata(String sourceObjectAPIName, 
                                                      String targetObjectAPIName, 
                                                      String recordTypeDeveloperName){
        Map<String, String> fieldMap = new Map<String, String>();
        List<Renewals_Mapping__mdt> renewalsMappingList = new List<Renewals_Mapping__mdt>([SELECT Id, 
                                                                                                  RecordType_DeveloperName__c,
                                                                                                  Source_Object__c,
                                                                                                  Source_Field_API_Name__c,
                                                                                                  Target_Object__c,
                                                                                                  Target_Field_API_Name__c 
                                                                                           FROM Renewals_Mapping__mdt
                                                                                           WHERE Source_Object__c = :sourceObjectAPIName
                                                                                           AND Target_Object__c = :targetObjectAPIName
                                                                                           AND RecordType_DeveloperName__c = :recordTypeDeveloperName]);
       if(!renewalsMappingList.isEmpty()){
           for(Renewals_Mapping__mdt metaObj : renewalsMappingList){
               
               fieldMap.put(metaObj.Source_Field_API_Name__c, metaObj.Target_Field_API_Name__c);
           }
       }
       return fieldMap;
    }
    
    
    /*
     * getFieldValue()
     * Purpose : returns the field value from the Sobject through multiple levels
     * eg: getFieldValue(quoteLineItemObj, 'Quote.Opportunity.Account.CreatedBy.Profile.Name')
     */
    public static Object getFieldValue(SObject sObj, String sourceField)
    {
        Object returnVal = NULL;
        Integer count = sourceField.countMatches('.');
        if(count == 0){
            returnVal = sObj.get(sourceField);
        } else {
            List<String> fieldNames = sourceField.split('\\.');
            if((count == 1) && (sObj.getSObject(fieldNames[0]) <> NULL ))
                returnVal = sObj.getSObject(fieldNames[0]).get(fieldNames[1]);
            else if((count == 2) 
                    && (sObj.getSObject(fieldNames[0]) <> NULL ) 
                    && (sObj.getSObject(fieldNames[0]).getSObject(fieldNames[1]) <> NULL ))
                returnVal = sObj.getSObject(fieldNames[0]).getSObject(fieldNames[1]).get(fieldNames[2]);
            else if((count == 3) 
                    && (sObj.getSObject(fieldNames[0]) <> NULL ) 
                    && (sObj.getSObject(fieldNames[0]).getSObject(fieldNames[1]) <> NULL )
                    && (sObj.getSObject(fieldNames[0]).getSObject(fieldNames[1]).getSObject(fieldNames[2]) <> NULL ))
                returnVal = sObj.getSObject(fieldNames[0]).getSObject(fieldNames[1]).getSObject(fieldNames[2]).get(fieldNames[3]);
            else if((count == 4) 
                    && (sObj.getSObject(fieldNames[0]) <> NULL ) 
                    && (sObj.getSObject(fieldNames[0]).getSObject(fieldNames[1]) <> NULL )
                    && (sObj.getSObject(fieldNames[0]).getSObject(fieldNames[1]).getSObject(fieldNames[2]) <> NULL )
                    && (sObj.getSObject(fieldNames[0]).getSObject(fieldNames[1]).getSObject(fieldNames[2]).getSObject(fieldNames[3]) <> NULL ))
                returnVal = sObj.getSObject(fieldNames[0]).getSObject(fieldNames[1]).getSObject(fieldNames[2]).getSObject(fieldNames[3]).get(fieldNames[4]);
            else if((count == 5) 
                    && (sObj.getSObject(fieldNames[0]) <> NULL ) 
                    && (sObj.getSObject(fieldNames[0]).getSObject(fieldNames[1]) <> NULL )
                    && (sObj.getSObject(fieldNames[0]).getSObject(fieldNames[1]).getSObject(fieldNames[2]) <> NULL )
                    && (sObj.getSObject(fieldNames[0]).getSObject(fieldNames[1]).getSObject(fieldNames[2]).getSObject(fieldNames[3]) <> NULL )
                    && (sObj.getSObject(fieldNames[0]).getSObject(fieldNames[1]).getSObject(fieldNames[2]).getSObject(fieldNames[3]).getSObject(fieldNames[4]) <> NULL ))
                returnVal = sObj.getSObject(fieldNames[0]).getSObject(fieldNames[1]).getSObject(fieldNames[2]).getSObject(fieldNames[3]).getSObject(fieldNames[4]).get(fieldNames[5]);
        }
        return returnVal;
    }
    

    /* 
     * processOpportunities()
     * @param extendedList - List of ServiceContracts with all fields required for mapping
     * @param scMap - Source Field API Name (on ServiceContract) as key and Target Field API Name (on Opportunity) as value
     * @return List<Opportunity> - Opportunity records formed with Renewals Mapping config
     */
    public static List<Opportunity> processOpportunities(List<SObject> extendedList, Map<String, String> scMap)
    {
        List<Opportunity> oppList = new List<Opportunity>();
        for(SObject scObj : extendedList)
        {
            Opportunity renewalOppty = new Opportunity();
            renewalOppty.StageName = 'Qualification';
            renewalOppty.CloseDate = System.today().addDays(30);
            for(String sourceField : scMap.keyset())
            {
                    renewalOppty.put(scMap.get(sourceField), getFieldValue(scObj, sourceField));
            }
            oppList.add(renewalOppty);
        }
        return oppList;
    }


    
    /* 
     * processOpportunityLineItems()
     * @param extendedList - List of ServiceContracts with all fields required for mapping
     * @param cliMap - Source Field API Name (on ContractLineItem) as key and Target Field API Name (on OpportunityLineItem) as value
     * @param contractID_opptyID_Map - Service Contract Id as key with newly created renewal Opportunity ID as value
     * @param relationshipName - Relationship name to extract line items
     * @return List<OpportunityLineItem> - OLI formed with the Renewals Mapping Config
     */
    public static List<OpportunityLineItem> processOpportunityLineItems(List<SObject> extendedList, 
                                                                        Map<String, String> cliMap, 
                                                                        Map<ID,ID> contractID_opptyID_Map,
                                                                        String relationshipName)
    {
        List<OpportunityLineItem> oliList = new List<OpportunityLineItem>();
        for(SObject scObj : extendedList)
        {
            String opportunityId = contractID_opptyID_Map.get(scObj.Id);
            if( !scObj.getSObjects(relationshipName).IsEmpty() && (opportunityId <> NULL) )
            {
                for(SObject cliObj : scObj.getSObjects(relationshipName))
                {
                    OpportunityLineItem renewalOLI = new OpportunityLineItem();
                    renewalOLI.OpportunityId = opportunityId;
                    renewalOLI.TotalPrice = 0;
                    for(String sourceField : cliMap.keyset())
                    {
                            renewalOLI.put(cliMap.get(sourceField), getFieldValue(cliObj, sourceField) );
                    }
                    oliList.add(renewalOLI);
                }
            }
        }
        return oliList;
    }



}