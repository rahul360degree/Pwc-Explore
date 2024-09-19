/*------------------------------------------------------------------------
Author:        Kishor Kumar
Company:       Salesforce
Description:   Controller class to display consolidated Plan benefits on Case record
Inputs:        NA
Test Class:    
History
18-11-2020      Kishor Kumar     Initial Release
----------------------------------------------------------------------------*/
public with sharing class ConsolidatedPlanBenefitsViewController {
    
    /*------------------------------------------------------------------------
    Author:        Kishor Kumar
    Company:       Salesforce
    Description:   method to fetch Contract benefit details for a case
    Inputs:        NA
    Test Class:    
    History
    18-11-2020      Kishor Kumar     Initial Release
    ----------------------------------------------------------------------------*/
    @AuraEnabled
    public static String getContractBenefitDetails(String parentRecordId){
		Map<String, String> fieldApiVsLabelMap = new Map<String,String>();
        List<Case> cases = new List<Case>();
        String result = '[]';
        list<PlanBenefitWrapper> planBenefitWrapperList = new list<PlanBenefitWrapper>();
        try{
            //get fields from fieldset
            String fieldJson = getFieldSet('Asset', 'ConsolidatedAssetPlanBenefitView');
            
            for(Object obj : (list<Object>)JSON.deserializeUntyped(fieldJson)){
                Map<String, Object> objMap = (Map<String, Object>)obj;
                fieldApiVsLabelMap.put((String)objMap.get('apiName'), (String)objMap.get('label'));
            }
           
            List<String> fieldsToQuery = new List<String>();
            
            //append Asset field reference to query field
            for(String field : fieldApiVsLabelMap.Keyset()){
                fieldsToQuery.add('Asset.'+ field);
            }
            
            String query = 'SELECT ' + String.join(fieldsToQuery, ',') + ' FROM Case' +
               				 +' WHERE Id = \'' +  parentRecordId + '\' LIMIT 1';
            //Fetch data          
            cases = Database.query(query);
            
            //Create wrapper with api Name, Label & values for fields
            if(cases.size() > 0) {
                Sobject assetSobj = cases[0].getSobject('Asset');
                for(String queriedField : fieldApiVsLabelMap.Keyset()){
                    planBenefitWrapperList.add(New PlanBenefitWrapper(fieldApiVsLabelMap.get(queriedField), queriedField, String.valueOf(assetSobj.get(queriedField))));
                }
                result = JSON.serialize(planBenefitWrapperList);
            }
        }
        catch(Exception e){
            result += e.getLineNumber() + ' : ' + e.getMessage();
        }
        return result;
    }
    
    /*------------------------------------------------------------------------
    Author:        Kishor Kumar
    Company:       Salesforce
    Description:   method to fetch Account benefit details for a case
    Inputs:        NA
    Test Class:    
    History
    18-11-2020      Kishor Kumar     Initial Release
    ----------------------------------------------------------------------------*/
    @AuraEnabled
    public static String getAccountBenefitDetails(String parentRecordId){
		Map<String, String> fieldApiVsLabelMap = new Map<String,String>();
        List<Case> cases = new List<Case>();
        String result = '[]';
        list<PlanBenefitWrapper> planBenefitWrapperList = new list<PlanBenefitWrapper>();
        try{
            //get fields from fieldset
            String fieldJson = getFieldSet('Asset_Benefit__c', 'ConsolidatedPlanView');
            
            for(Object obj : (list<Object>)JSON.deserializeUntyped(fieldJson)){
                Map<String, Object> objMap = (Map<String, Object>)obj;
                fieldApiVsLabelMap.put((String)objMap.get('apiName'), (String)objMap.get('label'));
            }
           
            List<String> fieldsToQuery = new List<String>();
            
            //append Asset field reference to query field
            for(String field : fieldApiVsLabelMap.Keyset()){
                fieldsToQuery.add('Account.Asset_Benefit__r.'+ field);
            }
            
            String query = 'SELECT ' + String.join(fieldsToQuery, ',') + ' FROM Case' +
               				 +' WHERE Id = \'' +  parentRecordId + '\' LIMIT 1';
            //Fetch data          
            cases = Database.query(query);
            
            //Create wrapper with api Name, Label & values for fields
            if(cases.size() > 0) {
                Sobject accountSobj = cases[0].getSobject('Account');
                Sobject assetBenefitSobj = accountSobj.getSobject('Asset_Benefit__r');
                for(String queriedField : fieldApiVsLabelMap.Keyset()){
                    planBenefitWrapperList.add(New PlanBenefitWrapper(fieldApiVsLabelMap.get(queriedField), queriedField, String.valueOf(assetBenefitSobj.get(queriedField))));
                }
                result = JSON.serialize(planBenefitWrapperList);
            }
        }
        catch(Exception e){
            result += e.getLineNumber() + ' : ' + e.getMessage();
        }
        return result;
    }

    /*------------------------------------------------------------------------
    Author:        Kishor Kumar
    Company:       Salesforce
    Description:   method to fetch Overriden benefit details for a case
    Inputs:        NA
    Test Class:    
    History
    27-11-2020      Kishor Kumar     Initial Release
    ----------------------------------------------------------------------------*/
    @AuraEnabled
    public static String getOverridenBenefitDetails(String parentRecordId){
		Map<String, String> fieldApiVsLabelMap = new Map<String,String>();
        List<Case> cases = new List<Case>();
        String result = '[]';
        list<PlanBenefitWrapper> planBenefitWrapperList = new list<PlanBenefitWrapper>();
        try{
            //get fields from fieldset
            String fieldJson = getFieldSet('Case', 'Consolidated_Overriden_Benefit_fieldset');
            
            for(Object obj : (list<Object>)JSON.deserializeUntyped(fieldJson)){
                Map<String, Object> objMap = (Map<String, Object>)obj;
                fieldApiVsLabelMap.put((String)objMap.get('apiName'), (String)objMap.get('label'));
            }
           
            List<String> fieldsToQuery = new List<String>();
            fieldsToQuery.addAll(fieldApiVsLabelMap.Keyset());

            String query = 'SELECT ' + String.join(fieldsToQuery, ',') + ' FROM Case' +
               				 +' WHERE Id = \'' +  parentRecordId + '\' LIMIT 1';
            //Fetch data          
            cases = Database.query(query);
            
            //Create wrapper with api Name, Label & values for fields
            if(cases.size() > 0) {
                for(String queriedField : fieldApiVsLabelMap.Keyset()){
                    planBenefitWrapperList.add(New PlanBenefitWrapper(fieldApiVsLabelMap.get(queriedField), queriedField, String.valueOf(cases[0].get(queriedField))));
                }
                result = JSON.serialize(planBenefitWrapperList);
            }
        }
        catch(Exception e){
            result += e.getLineNumber() + ' : ' + e.getMessage();
        }
        return result;
    }

    /*------------------------------------------------------------------------
    Author:        Kishor Kumar
    Company:       Salesforce
    Description:   method to recalculate Plan benefits on UI
    Inputs:        NA
    Test Class:    
    History
    26-11-2020      Kishor Kumar     Initial Release
    ----------------------------------------------------------------------------*/
    @AuraEnabled
    public static Boolean recalculateBenefitDetails(String parentRecordId){

        Id assetId = [SELECT Id, AssetId FROM CASE WHERE Id =: parentRecordId LIMIT 1].AssetId;

        return AssetBestValueQuickActionController.updateBenifitBestValueOnAsset(assetId);
    }
    
    /*------------------------------------------------------------------------
    Author:        Kishor Kumar
    Company:       Salesforce
    Description:   method to fetch fieldset fields for an object
    Inputs:        NA
    Test Class:    
    History
    18-11-2020      Kishor Kumar     Initial Release
    ----------------------------------------------------------------------------*/
    public static String getFieldSet(String sObjectName, String fieldSetName) {
        String result = '';
        try{
            SObjectType objToken = Schema.getGlobalDescribe().get(sObjectName);
            Schema.DescribeSObjectResult d = objToken.getDescribe();
            Map<String, Schema.FieldSet> FsMap = d.fieldSets.getMap();
            if(FsMap.containsKey(fieldSetName))
                for(Schema.FieldSetMember f : FsMap.get(fieldSetName).getFields()) {
                    if(result != ''){
                        result += ',';
                    }
                    String jsonPart = '{';
                    jsonPart += '"apiName":"' + f.getFieldPath() + '",';
                    //jsonPart += '"required":"' + (f.getDBRequired() || f.getRequired()) + '",';
                    //jsonPart += '"type":"' + (f.getType()) + '",';
                    jsonPart += '"label":"' + f.getLabel() + '"';
                    jsonPart += '}';
                    result += jsonPart;
            }
        }
        catch(Exception e){
            result += e.getLineNumber() + ' : ' + e.getMessage();
        }
        return '['+result +']';
    }
    
    //Wrapper Class for plan Benefits
    public class PlanBenefitWrapper {
        @auraEnabled public String fieldLabel {get;set;}
        @auraEnabled public String fieldApiName{get;set;}
        @auraEnabled public String fieldValue{get;set;}
        
        public PlanBenefitWrapper(String fieldLabel, String fieldApiName, String fieldValue){
            this.fieldLabel = fieldLabel;
            this.fieldApiName = fieldApiName;
            this.fieldValue = fieldValue;
        }
    }
}