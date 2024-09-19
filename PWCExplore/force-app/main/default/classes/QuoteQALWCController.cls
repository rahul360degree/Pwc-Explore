/*------------------------------------------------------------------------
Author:        Kishor Kumar
Company:       Salesforce
Description:   Controller class for Plan Benefit Selector UI
Inputs:        NA
Test Class:    
History
13-11-2020      Kishor Kumar     Initial Release
----------------------------------------------------------------------------*/
public without sharing class QuoteQALWCController {

    /*------------------------------------------------------------------------
    Author:        Nupoor Sharma
    Company:       Salesforce
    Description:   Finalize Quote
    Inputs:        Quote Id
    Test Class:    
    History
    12-01-2020     Nupoor Sharma     Demo Feedback
    ----------------------------------------------------------------------------*/
    @AuraEnabled
    public static boolean finalizeQuote(Id quoteId){
        List<Quote> currentQuote = [SELECT Id,Status, (Select Id from Service_Contracts__r) FROM Quote WHERE Id =: quoteId];
        if(currentQuote != NULL && currentQuote.size() > 0 && (currentQuote[0].Service_Contracts__r==NULL || currentQuote[0].Service_Contracts__r.size()==0)) {
            if(currentQuote[0].Status.equalsIgnoreCase(GlobalConstants.QUOTE_STATUS_FINALIZED)) {
                return true;
            } else {
                currentQuote[0].Status = GlobalConstants.QUOTE_STATUS_FINALIZED;
                try{
                    update currentQuote;
                    return true;
                }
                catch(Exception ex)
                {
                    throw new AuraHandledException((ex.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION') ? ex.getMessage().substringAfter('FIELD_CUSTOM_VALIDATION_EXCEPTION,') : ex.getMessage() ));
                }
            }
        } else {
            throw new AuraHandledException(System.Label.FinalizeQuoteError);
        }
    }


    /*------------------------------------------------------------------------
    Author:        Nupoor Sharma
    Company:       Salesforce
    Description:   Adds default plan benefits based on products selected
    Inputs:        Quote Id
    Test Class:    
    History
    12-01-2020     Nupoor Sharma     Demo Feedback
    ----------------------------------------------------------------------------*/
    @AuraEnabled
    public static boolean addDefaultBenefits(Id quoteId){
        Boolean returnVal = false;
        Map<ID, ID> quote_benefit_Map = new Map<ID, ID>();
        Map<ID, String> qliToAddDefaults = new Map<ID, String>();
        Map<Id, QuoteLineItem> quoteLines = new Map<Id, QuoteLineItem>([SELECT Id, Asset__c, Product2.Plan_Type__c,
                                                                        (SELECT Id,Plan__c, Plan__r.Plan_Identifier__c from Asset_Benefits__r order by Plan__r.Plan_Type__c Desc)
                                                                        FROM QuoteLineItem 
                                                                        WHERE QuoteId = :quoteId]);
        if(quoteLines.size()>0)
        {
            for(String qliKey : quoteLines.keyset())
            {
                QuoteLineItem qli = quoteLines.get(qliKey);
                if(String.IsNotBlank(qli.Product2.Plan_Type__c))
                {
                    if(qli.Asset_Benefits__r <> NULL)
                    {
                        Boolean defaultFound = false;
                        for(Asset_Benefit__c abenefit : qli.Asset_Benefits__r)
                        {
                            if( abenefit.Plan__c<>NULL 
                                && String.isNotBlank(abenefit.Plan__r.Plan_Identifier__c) 
                                && qli.Product2.Plan_Type__c.equalsIgnoreCase(abenefit.Plan__r.Plan_Identifier__c))
                                {
                                    quote_benefit_Map.put(qli.Id, abenefit.Id);
                                    defaultFound = true;
                                    break;
                                }
                        }
                        if(defaultFound==false)
                        {
                            qliToAddDefaults.put(qli.Id, qli.Product2.Plan_Type__c);
                        }
                    }
                    else 
                    {
                        qliToAddDefaults.put(qli.Id, qli.Product2.Plan_Type__c);
                    }
                }
            }

            if(!qliToAddDefaults.isEmpty())
            {
                Map<String, Plan__c> planMap = new Map<String, Plan__c>();
                //get all Basic plans for the selected plan types
                List<Plan__c> planList = new List<Plan__c>([SELECT Id, Name, Plan_Identifier__c, BD_Visits_Number__c, Scheduled_PM_Visits_Number__c, Audits__c,
                                                            BD_Visits__c, Equipment_Type__c, Operator__c, Parts_Support__c, Remote_Assistance__c, 
                                                            Reports_Dashboards__c, Scheduled_PM_Visits__c, Stationed_Manpower__c, Supervisor__c
                                                            FROM Plan__c 
                                                            WHERE Plan_Identifier__c IN : qliToAddDefaults.values() AND Plan_Type__c = 'Basic']);
                for(Plan__c planObj : planList)
                {
                    planMap.put(planObj.Plan_Identifier__c, planObj);
                }

                List<Asset_Benefit__c> assetBenefitsToInsert = new List<Asset_Benefit__c>();
                //Add default benefits for these QLI records
                for(ID qliKey : qliToAddDefaults.keySet())
                {
                    QuoteLineItem qli = quoteLines.get(qliKey);
                    if(planMap.get(qliToAddDefaults.get(qliKey))<> NULL)
                    {
                        Plan__c referPlan = planMap.get(qliToAddDefaults.get(qliKey));

                        //Adding default asset benefit
                        Asset_Benefit__c benefitRec = new Asset_Benefit__c(Quote_Line_Item__c = qli.Id,Plan__c = referPlan.Id,Name = referPlan.Name,Asset__c = qli.Asset__c);
                        benefitRec.Is_Active__c = false;
                        benefitRec.Audits__c = referPlan.Audits__c;
                        benefitRec.BD_Visits__c = referPlan.BD_Visits__c;
                        benefitRec.Equipment_Type__c = referPlan.Equipment_Type__c;
                        benefitRec.Operator__c = referPlan.Operator__c;
                        benefitRec.Parts_Support__c = referPlan.Parts_Support__c;
                        benefitRec.Remote_Assistance__c = referPlan.Remote_Assistance__c;
                        benefitRec.Reports_Dashboards__c = referPlan.Reports_Dashboards__c;
                        benefitRec.Scheduled_PM_Visits__c = referPlan.Scheduled_PM_Visits__c;
                        benefitRec.Stationed_Manpower__c = referPlan.Stationed_Manpower__c;
                        benefitRec.Supervisor__c = referPlan.Supervisor__c;
                        benefitRec.BD_Visits_Number__c = referPlan.BD_Visits_Number__c;
                        benefitRec.Scheduled_PM_Visits_Number__c = referPlan.Scheduled_PM_Visits_Number__c;
                        assetBenefitsToInsert.add(benefitRec);
                    }
                }
                insert assetBenefitsToInsert;
                returnVal = true;
            }
    
        }
        return returnVal;
    }

    
    /*------------------------------------------------------------------------
    Author:        Kishor Kumar
    Company:       Salesforce
    Description:   Fetch QLI & other details to display on UI on load
    Inputs:        NA
    Test Class:    
    History
    13-11-2020      Kishor Kumar     Initial Release
    ----------------------------------------------------------------------------*/
  @auraEnabled
    public static List<LineItemInitWrapper> getQuoteLineItemsFromQuoteRecId(string quoteId) {
        List<LineItemInitWrapper> returnWrapper = new List<LineItemInitWrapper>();
        
        //Create Query strin with fieldset fields
        String query = 'SELECT ';
        for(Schema.FieldSetMember field : SObjectType.QuoteLineItem.FieldSets.LineItemPlanSelectorFieldSet.getFields()) {
            query += field.getFieldPath() + ', ';
        }
        string assetBenefitQuery = 'SELECT ';
        for(Schema.FieldSetMember field : SObjectType.Asset_Benefit__c.FieldSets.AssetBenefitForPlanSelection.getFields()){
            assetBenefitQuery += field.getFieldPath() + ', ';
        }
        query += 'Id,Asset__c,Asset__r.Name,Quote.Sold_To_Business_Partner__c,('+assetBenefitQuery+' Id,Name,Plan__c,Plan__r.Name,Plan__r.Plan_Type__c,Asset__c FROM Asset_Benefits__r) FROM QuoteLineItem WHERE QuoteId=\''+quoteId+'\' LIMIT 100';
        
        //Fetch QLI details
        List<QuoteLineItem> quoteLineItems = Database.query(query);
        
        for(integer i=0;i < quoteLineItems.size(); i++) {
            List<Plan__c> existingPlans = new List<Plan__c>();
            List<AssetBenefitWrapper> assetBenefitWrapperList = new List<AssetBenefitWrapper>();
            List<AssetBenefitFieldWrapper> wrapper = new List<AssetBenefitFieldWrapper>();
            
            //initialize wrapper instance
            LineItemInitWrapper item = new LineItemInitWrapper();
            item.lineItem = quoteLineItems[i];
            item.selectedAssetId = quoteLineItems[i].Asset__c;
            if(quoteLineItems[i].Asset__c != NULL) {
                item.selectedAssetName = quoteLineItems[i].Asset__r.Name;
            }
            
            //create wrapper for all the existing asset benefit record for individual QLI
            for(Asset_Benefit__c benefit : quoteLineItems[i].Asset_Benefits__r) {
                existingPlans.add(new Plan__c(Id = benefit.Plan__c, Name = benefit.Plan__r.Name));
                assetBenefitWrapperList.add(new AssetBenefitWrapper(benefit,true));
            }
            item.plans = existingPlans;
            item.existingAssetBenefits = assetBenefitWrapperList;
            
            //Fetching fields set data to display on UI as header 
      String fieldJson = getFieldSet('Asset_Benefit__c', 'AssetBenefitForPlanSelection');
            for(Object obj : (list<Object>)JSON.deserializeUntyped(fieldJson)){
                Map<String, Object> objMap = (Map<String, Object>)obj;
                //Create Wrapper dynamically
                if(((String)objMap.get('type')).equalsIgnoreCase('Picklist')){
                    wrapper.add(new AssetBenefitFieldWrapper((String)objMap.get('label'),(String)objMap.get('apiName'),(String)objMap.get('type'), getselectOptions(Schema.getGlobalDescribe().get('Asset_Benefit__c').newSObject(), (String)objMap.get('apiName'))));
                } else {
                    wrapper.add(new AssetBenefitFieldWrapper((String)objMap.get('label'),(String)objMap.get('apiName'),(String)objMap.get('type'), new Map<string,string>()));
                }
            }            
            
            item.assetBenefitFields = wrapper;
            returnWrapper.add(item);
        }
        return returnWrapper;
    }
    
    /*------------------------------------------------------------------------
    Author:        Kishor Kumar
    Company:       Salesforce
    Description:   Handle Save of QLI screen
    Inputs:        QLI wrapper
    Test Class:    
    History
    13-11-2020      Kishor Kumar     Initial Release
    ----------------------------------------------------------------------------*/
    @auraEnabled
    public static String saveQuoteLineItems(List<LineItemWrapper> wrapper) {
        Set<Id> lineItemIds = new Set<Id>();
        Map<Id,Id> lineItemIdVsAssetId = new Map<Id,Id>();
        List<QuoteLineItem> lineItemsToUpdateList = new List<QuoteLineItem>();
        Map<String,QuoteLineItem> lineItemsToUpdate = new Map<String,QuoteLineItem>();
        Set<Id> lineItemsWithAssetDeleted = new Set<Id>();
        Map<Id,Asset> selectedAssetmap = new Map<Id,Asset>();
        Map<String,String> recordIdVsErrorMessage = new Map<String,String>();
        
        for(LineItemWrapper lineItem : wrapper){
            lineItemIds.add(lineItem.lineItemId);
            lineItemIdVsAssetId.put(lineItem.lineItemId,lineItem.selectedAsset);
            if(lineItem.selectedAsset == NULL) {
                lineItemsWithAssetDeleted.add(lineItem.lineItemId);
            }
        } 
        
        //fetch asset details to populate aging & attachment from selected asset
        selectedAssetmap = new map<Id, Asset>([SELECT Id, Age__c, Attachment__c,Equipment_Serial_No__c,Date_of_Commissioning__c FROM Asset Where Id IN: lineItemIdVsAssetId.values()]);
    
        //Fetch the Asset benefits to be deleted
        map<Id, Asset_Benefit__c> assetBenefitToDelete = new map<Id, Asset_Benefit__c>([SELECT Id FROM Asset_Benefit__c WHERE Quote_Line_Item__c =:lineItemsWithAssetDeleted]);
    
        for(QuoteLineItem lineItem : [SELECT Id,Asset__c, Asset__r.Age__c, Asset__r.Attachment__c, Ageing__c, Attachment__c,Product2.Plan_Type__c,
                                            (SELECT Id,Plan__c,Asset__c,To_be_deleted__c FROM Asset_Benefits__r) 
                                      FROM QuoteLineItem WHERE ID IN :lineItemIds]) {
            //Asset has been updated on lineItem
            if(lineItemIdVsAssetId.containsKey(lineItem.Id) && lineItemIdVsAssetId.get(lineItem.Id) != lineItem.Asset__c){
                
                if(lineItemIdVsAssetId.get(lineItem.Id) != null){
                    QuoteLineItem itemToUpdate = new QuoteLineItem(Id = lineItem.Id,
                                                               Asset__c = lineItemIdVsAssetId.get(lineItem.Id),
                                                               Ageing__c = selectedAssetmap.containsKey(Id.valueOf(lineItemIdVsAssetId.get(lineItem.Id))) ?  selectedAssetmap.get(Id.valueOf(lineItemIdVsAssetId.get(lineItem.Id))).Age__c : 0,
                                                               Attachment__c = selectedAssetmap.containsKey(Id.valueOf(lineItemIdVsAssetId.get(lineItem.Id))) ?  selectedAssetmap.get(Id.valueOf(lineItemIdVsAssetId.get(lineItem.Id))).Attachment__c : '',
                                                               Asset_Serial_Number__c = selectedAssetmap.containsKey(Id.valueOf(lineItemIdVsAssetId.get(lineItem.Id))) ? selectedAssetmap.get(Id.valueOf(lineItemIdVsAssetId.get(lineItem.Id))).Equipment_Serial_No__c : ''
                                                               );

                    if(selectedAssetmap.containsKey(Id.valueOf(lineItemIdVsAssetId.get(lineItem.Id)))  
                        && selectedAssetmap.get(Id.valueOf(lineItemIdVsAssetId.get(lineItem.Id))).Date_of_Commissioning__c != null){
                        DateTime dt = selectedAssetmap.get(Id.valueOf(lineItemIdVsAssetId.get(lineItem.Id))).Date_of_Commissioning__c;
                        itemToUpdate.Date_of_Dispatch__c = Date.newinstance(dT.year(), dT.month(), dT.day());
                    } 
                    if(!lineItemsToUpdate.containsKey(lineItem.Id)){
                        lineItemsToUpdate.put(lineItem.Id,itemToUpdate);
                    }
                    //lineItemsToUpdate.add(itemToUpdate);
                } else {
                    QuoteLineItem itemToUpdate = new QuoteLineItem(Id = lineItem.Id,
                                                                   Asset__c = null,
                                                                   Ageing__c = 0,
                                                                   Attachment__c =  ''
                                                                   );
                    if(!lineItemsToUpdate.containsKey(lineItem.Id)){
                        lineItemsToUpdate.put(lineItem.Id,itemToUpdate);
                    }
                    //lineItemsToUpdate.add(itemToUpdate);
                }
                //Check the asset benefits to see if there are any asset benefits with old asset stamped on them
                Id selectedAsset = lineItemIdVsAssetId.get(lineItem.Id);
                for(Asset_Benefit__c benefit : lineItem.Asset_Benefits__r) {
                    //If Asset on QLI is blank or asset is changed then all the existing Benefit records associated to old Asset should be deleted
                    if((benefit.Asset__c != NULL) && (benefit.Asset__c != selectedAsset && selectedAsset != NULL) || benefit.To_be_deleted__c == true) {
                        assetBenefitToDelete.put(benefit.Id, benefit);
                    }
                }
            }

            if(!lineItemsToUpdate.containsKey(lineItem.Id) && lineItem.Product2.Plan_Type__c != null){
                QuoteLineItem itemToUpdate = new QuoteLineItem();
                itemToUpdate.Id = lineItem.Id;
                itemToUpdate.Contract_Type__c = lineItem.Product2.Plan_Type__c;
                lineItemsToUpdate.put(lineItem.Id,itemToUpdate);
            }else if(lineItemsToUpdate.containsKey(lineItem.Id) && lineItem.Product2.Plan_Type__c != null){
                QuoteLineItem itemToUpdate = lineItemsToUpdate.get(lineItem.Id);
                itemToUpdate.Contract_Type__c = lineItem.Product2.Plan_Type__c;
                lineItemsToUpdate.put(lineItem.Id,itemToUpdate);
            }            

            //Delete to be deleted asset Benefit records
            for(Asset_Benefit__c benefitToDel : lineItem.Asset_Benefits__r) {
                if(benefitToDel.To_be_deleted__c)
                    assetBenefitToDelete.put(benefitToDel.Id, benefitToDel);
            }
        }

        //Perform DMLs 
        try{
            //Delete irrelevant Asset Benefit records
            delete assetBenefitToDelete.values();
            
            //Update QLI with selected asset
            if(lineItemsToUpdate.size() > 0){
                lineItemsToUpdateList.addAll(lineItemsToUpdate.values());

                Database.SaveResult[] srList = Database.update(lineItemsToUpdateList,false);
                Integer index = 0;
                // Iterate through each returned result
                for (Database.SaveResult sr : srList) {
                    if (!sr.isSuccess()) {
                        String errorMessage = '';
                        // Operation failed, so get all errors                
                        for(Database.Error err : sr.getErrors()) {
                            errorMessage += String.isBlank(errorMessage) ? err.getMessage() : ', '+ err.getMessage();
                        }
                        recordIdVsErrorMessage.put(lineItemsToUpdateList.get(index).Id,errorMessage);
                    }
                    index++;
                }
            } 
            System.debug('recordIdVsErrorMessage :: ' + recordIdVsErrorMessage);
            if(recordIdVsErrorMessage.size() > 0) {
                return JSON.serialize(recordIdVsErrorMessage);
            }
            return 'SUCCESS';
        } catch(Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }
  
    /*------------------------------------------------------------------------
    Author:        Kishor Kumar
    Company:       Salesforce
    Description:   Handle Cancel of QLI screen
    Inputs:        Quote Id
    Test Class:    
    History
    13-11-2020      Kishor Kumar     Initial Release
    ----------------------------------------------------------------------------*/
    @auraEnabled
    public static void handleCancel(Id quoteId) {
        List<Asset_Benefit__c> assetBenefitToDelete = new List<Asset_Benefit__c>();
        for(QuoteLineItem lineItem : [SELECT Id,Asset__c,(SELECT Id,Plan__c,Asset__c,To_be_deleted__c FROM Asset_Benefits__r) FROM QuoteLineItem WHERE QuoteId =:quoteId]) {
            for(Asset_Benefit__c benefit : lineItem.Asset_Benefits__r) {
                //If Asset on QLI is blank or asset is changed then all the existing Benefit records associated to old Asset should be deleted
                if(benefit.Asset__c != lineItem.Asset__c || benefit.To_be_deleted__c == true || lineItem.Asset__c == NULL) {
                    assetBenefitToDelete.add(benefit);
                }
            }
        }
        
        //Perform DMLs 
        try{
            //Delete irrelevant Asset Benefit records
            delete assetBenefitToDelete;
        } catch(Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    @auraEnabled
    public static List<PlanSelectionColumnWrapper> getPlanSelectionComponentColumns() {
        List<PlanSelectionColumnWrapper> columnsToShow = new List<PlanSelectionColumnWrapper>();
        for(Schema.FieldSetMember field : SObjectType.Plan__c.FieldSets.SelectPlanFieldSet.getFields()) {
            columnsToShow.add(new PlanSelectionColumnWrapper(field.getLabel(),field.getFieldPath()));
        }
        return columnsToShow;
    }
    
    @auraEnabled
    public static List<PlanSelectionColumnWrapper> getAssetBenefitComponentColumns() {
        List<PlanSelectionColumnWrapper> columnsToShow = new List<PlanSelectionColumnWrapper>();
        for(Schema.FieldSetMember field : SObjectType.Asset_Benefit__c.FieldSets.AssetBenefitForPlanSelection.getFields()) {
            columnsToShow.add(new PlanSelectionColumnWrapper(field.getLabel(),field.getFieldPath()));
        }
        return columnsToShow;
    }

    @auraEnabled
    public static List<PlanSelectionColumnWrapper> getLineItemColumns() {
        List<PlanSelectionColumnWrapper> columnsToShow = new List<PlanSelectionColumnWrapper>();
        for(Schema.FieldSetMember field : SObjectType.QuoteLineItem.FieldSets.LineItemPlanSelectorFieldSet.getFields()) {
            columnsToShow.add(new PlanSelectionColumnWrapper(field.getLabel(),field.getFieldPath()));
        }
        return columnsToShow;
    }
  
    /*------------------------------------------------------------------------
    Author:        Kishor Kumar
    Company:       Salesforce
    Description:   Fetch all the Plans to display on Plan selection Screen
    Inputs:        QLI id, Selected asset Id
    Test Class:    
    History
    13-11-2020      Kishor Kumar     Initial Release
    ----------------------------------------------------------------------------*/
    @auraEnabled
    public static List<AssetBenefitWrapper> getAllPlansForLineItem(Id lineItemId,Id selectedAssetId){
        List<AssetBenefitWrapper> result = new List<AssetBenefitWrapper>();
        Set<Id> existingPlans = new Set<Id>();
        
        QuoteLineItem qli = [Select Id, Product2.Plan_Type__c from QuoteLineItem where id = :lineItemId];

        //Fetch Contract RT details
        Id contractRecordTypeId = Schema.SObjectType.Plan__c.getRecordTypeInfosByDeveloperName().get('Contract').getRecordTypeId();
        
        //Create Query string to fetch already created Asset benefit records
        string assetBenefitQuery = 'SELECT ';
        for(Schema.FieldSetMember field : SObjectType.Asset_Benefit__c.FieldSets.AssetBenefitForPlanSelection.getFields()){
            assetBenefitQuery += field.getFieldPath() + ', ';
        }
        /*
        if(selectedAssetId == NULL) {
            assetBenefitQuery += ' Id,Name,Plan__c,Plan__r.Name,Plan__r.Plan_Type__c FROM Asset_Benefit__c WHERE To_be_deleted__c = false AND Quote_Line_Item__c = \''+lineItemId+'\' AND Asset__c = NULL ';
        } else {
            assetBenefitQuery += ' Id,Name,Plan__c,Plan__r.Name,Plan__r.Plan_Type__c FROM Asset_Benefit__c WHERE To_be_deleted__c = false AND Quote_Line_Item__c = \''+lineItemId+'\' AND Asset__c =\''+selectedAssetId+'\'';
        }*/

        assetBenefitQuery += ' Id,Name,Plan__c,Plan__r.Name,Plan__r.Plan_Type__c FROM Asset_Benefit__c WHERE To_be_deleted__c = false AND Quote_Line_Item__c = \''+lineItemId+'\'';
        
        //Fetch existing asset benefit 
        List<Asset_Benefit__c> assetBenefits = Database.query(assetBenefitQuery);
        
        for(Asset_Benefit__c benefit : assetBenefits){
            result.add(new AssetBenefitWrapper(benefit,true));
            existingPlans.add(benefit.Plan__c);
        }

        //Create Query string to fetch Plans
        string planQuery = 'SELECT ';
        for(Schema.FieldSetMember field : SObjectType.Asset_Benefit__c.FieldSets.AssetBenefitForPlanSelection.getFields()){
            planQuery += field.getFieldPath() + ', ';
        }
        planQuery += 'Id,Name,Plan_Type__c FROM Plan__c WHERE Id NOT IN :existingPlans ';

        if(String.isNotBlank(qli.Product2.Plan_Type__c)){
            String basicplan = qli.Product2.Plan_Type__c;
            planQuery += 'AND (Plan_Identifier__c =  :basicplan OR Plan_Type__c = \'Add on\') '; 
        }
        planQuery += 'AND Is_Standard_Plan__c = false AND Is_Active__c = true AND RecordTypeId=\''+contractRecordTypeId+'\' ORDER BY Plan_Type__c Desc LIMIT 100';
       
        //Fetch Plan details
        List<Plan__c> plansToShow = Database.query(planQuery);

        //create Dummy wrapper with plan defaulted values to show all the plans on Plan selection screen
        for(Plan__c plan : plansToShow){
            result.add(new AssetBenefitWrapper(plan,false));
        }
        return result;
    }
  
    /*------------------------------------------------------------------------
    Author:        Kishor Kumar
    Company:       Salesforce
    Description:   Handle Save & validate of Selected plans
    Inputs:        Selected plans, QLI id, selected asset Id
    Test Class:    
    History
    13-11-2020      Kishor Kumar     Initial Release
    ----------------------------------------------------------------------------*/
    @auraEnabled
    public static void saveSelectedPlans(List<SObject> plansSelected,Id lineItemId,Id assetId) {
        Set<Id> assetBenefitsSelected = new Set<Id>();
        set<Id> planIds = new set<Id>();
        set<Id> deltaPlanIds = new set<Id>();
        map<Id, Plan__c> planMap = new map<Id, Plan__c>();
        List<Asset_Benefit__c> benefitRecordsToUpsert = new List<Asset_Benefit__c>();
        //List<Asset_Benefit__c> deselectedBenefitsToDelete = new List<Asset_Benefit__c>();
         QuoteLineItem qli = [SELECT Id, Number_Of_Shifts__c, Duration_Of_Contract__c, Quote.RecordTypeId,Quoteid 
            FROM QuoteLineItem WHERE Id = :lineItemId
        ];
        
        //fetch all the selected plan Id
        for(SObject selectedPlan : plansSelected){
            if(!selectedPlan.getSobjectType().getDescribe().fields.getMap().containsKey('Quote_Line_Item__c')){
                planIds.add((Id)selectedPlan.get('Id'));
                
            } 
            //If modifying existing plan
            else if(selectedPlan.getSobjectType().getDescribe().fields.getMap().containsKey('Quote_Line_Item__c')){
                planIds.add((Id)selectedPlan.get('Plan__c'));
            }
        }
        
        //get all the selected plan details
        planMap = new map<Id, Plan__c>([SELECT Id, Name, BD_Visits_Number__c, Scheduled_PM_Visits_Number__c, Audits__c,
                                                    BD_Visits__c, Equipment_Type__c, Operator__c, Parts_Support__c, Remote_Assistance__c, 
                                                    Reports_Dashboards__c, Scheduled_PM_Visits__c, Stationed_Manpower__c, Supervisor__c   
                                                FROM Plan__c 
                                            WHERE Id IN : planIds]);
        
        for(SObject plan : plansSelected){
            if(plan.getSobjectType().getDescribe().fields.getMap().containsKey('Quote_Line_Item__c')){
                //Existing asset benefit
                assetBenefitsSelected.add((Id)plan.get('Id'));
                Asset_Benefit__c benefitRec = new Asset_Benefit__c(Id = (Id)plan.get('Id'),Asset__c = assetId, Plan__c = (Id)plan.get('Plan__c'), Is_Active__c = false);

                for(Schema.FieldSetMember field : SObjectType.Asset_Benefit__c.FieldSets.AssetBenefitForPlanSelection.getFields()){
                    benefitRec.put(field.getFieldPath(),plan.get(field.getFieldPath()));
                }
                benefitRecordsToUpsert.add(benefitRec);

            } else {
                //Adding new plan
                Asset_Benefit__c benefitRec = new Asset_Benefit__c(Quote_Line_Item__c = lineItemId,Plan__c = (Id)plan.get('Id'),Name = (string)plan.get('Name'),Asset__c = assetId);
                
                //Map other fields
                benefitRec.Is_Active__c = false;
                benefitRec.Audits__c = planMap.get(benefitRec.Plan__c).Audits__c;
                benefitRec.BD_Visits__c = planMap.get(benefitRec.Plan__c).BD_Visits__c;
                benefitRec.Equipment_Type__c = planMap.get(benefitRec.Plan__c).Equipment_Type__c;
                benefitRec.Operator__c = planMap.get(benefitRec.Plan__c).Operator__c;
                benefitRec.Parts_Support__c = planMap.get(benefitRec.Plan__c).Parts_Support__c;
                benefitRec.Remote_Assistance__c = planMap.get(benefitRec.Plan__c).Remote_Assistance__c;
                benefitRec.Reports_Dashboards__c = planMap.get(benefitRec.Plan__c).Reports_Dashboards__c;
                benefitRec.Scheduled_PM_Visits__c = planMap.get(benefitRec.Plan__c).Scheduled_PM_Visits__c;
                benefitRec.Stationed_Manpower__c = planMap.get(benefitRec.Plan__c).Stationed_Manpower__c;
                benefitRec.Supervisor__c = planMap.get(benefitRec.Plan__c).Supervisor__c;
                
                //Map/override filedset values
                for(Schema.FieldSetMember field : SObjectType.Asset_Benefit__c.FieldSets.AssetBenefitForPlanSelection.getFields()){
                    benefitRec.put(field.getFieldPath(),plan.get(field.getFieldPath()));
                }
                
                benefitRecordsToUpsert.add(benefitRec);
            }
        }
        
        //validate asset benefit data with plan for selected BD visit & PM visit count
        
        //get selected plan Ids
        for(Asset_Benefit__c assetBenefit : benefitRecordsToUpsert){
            if(assetBenefit.Plan__c != null && !planMap.containsKey(Id.valueOf(assetBenefit.Plan__c))){
                deltaPlanIds.add(assetBenefit.Plan__c);
            }
        }
        
        //fetch Plan details to validate
        if(deltaPlanIds.size() > 0){
            for(Plan__c deltaPlan : [SELECT Id, Name, BD_Visits_Number__c, Scheduled_PM_Visits_Number__c, Audits__c,
                                         BD_Visits__c, Equipment_Type__c, Operator__c, Parts_Support__c, Remote_Assistance__c, 
                                         Reports_Dashboards__c, Scheduled_PM_Visits__c, Stationed_Manpower__c, Supervisor__c   
                                     FROM Plan__c 
                                     WHERE Id IN : deltaPlanIds]){
                 planMap.put(deltaPlan.Id, deltaPlan);                        
            }
        }
         Quote quo = [select id,Opportunity.Contract_Start_Date__c,Opportunity.Contract_End_Date__c from Quote where id= :qli.QuoteId];
        Date startDate = quo.Opportunity.Contract_Start_Date__c;
		Date endDate = quo.Opportunity.Contract_End_Date__c;
		Integer noOfDays = startDate.daysBetween( endDate );
        system.debug( 'Output is ' + noOfDays );
        //validate Asset benefit values
    for(Asset_Benefit__c assetBenefit : benefitRecordsToUpsert){
            if(assetBenefit.Plan__c != null && planMap.containsKey(assetBenefit.Plan__c)){
                //Set 0 for null values
                assetBenefit.BD_Visits_Number__c = assetBenefit.BD_Visits_Number__c == null ? 0 : assetBenefit.BD_Visits_Number__c;
                planMap.get(assetBenefit.Plan__c).BD_Visits_Number__c = planMap.get(assetBenefit.Plan__c).BD_Visits_Number__c == null ? 0 : planMap.get(assetBenefit.Plan__c).BD_Visits_Number__c;
                
                
               //commented by Anupam on 11/4/2021 to allow downward revision of BD Visits
                //Bd visit count validation
               /* if(Integer.valueOf(assetBenefit.BD_Visits_Number__c) < Integer.valueOf(planMap.get(assetBenefit.Plan__c).BD_Visits_Number__c)){
                    throw new AuraHandledException('BD Visit count for \''+planMap.get(assetBenefit.Plan__c).Name+'\' Plan can\'t be less than the plan defaulted Value- '+ planMap.get(assetBenefit.Plan__c).BD_Visits_Number__c);
                }
                */
                 if(noOfDays>364){
                //PM Schedule Visit count validation
                if(Integer.valueOf(assetBenefit.Scheduled_PM_Visits_Number__c) < Integer.valueOf(planMap.get(assetBenefit.Plan__c).Scheduled_PM_Visits_Number__c)){
                    throw new AuraHandledException('Scheduled PM Visit count for \''+planMap.get(assetBenefit.Plan__c).Name+'\' Plan can\'t be less than the plan defaulted Value- '+ planMap.get(assetBenefit.Plan__c).Scheduled_PM_Visits_Number__c);
                }
            }
            }
        }    
        
        //If any existing plans are deselected then needs to be deleted
        for(Asset_Benefit__c benefitsToMarkDelete : [SELECT Id FROM Asset_Benefit__c 
                                                     WHERE Quote_Line_Item__c =: lineItemId 
                                                     AND Id NOT IN :assetBenefitsSelected]) {
            benefitsToMarkDelete.To_be_deleted__c = true;
            benefitRecordsToUpsert.add(benefitsToMarkDelete); 
            //deselectedBenefitsToDelete.add(benefitsToMarkDelete);  
        }
        
        //Perform DML
        try {
            //Insert/Update new/updated plan benefit records
            //upsert benefitRecordsToUpsert;
            List<Database.upsertResult> results = Database.upsert(benefitRecordsToUpsert,true);

            for(Database.upsertResult result : results) {
                if (!result.isSuccess()) {
                    throw new AuraHandledException(result.getErrors()[0].getMessage());
                }
            }
            
            //Update to be delete later
            //update deselectedBenefitsToDelete;
        } catch(DmlException e){
            if(e.getMessage().containsIgnoreCase('_EXCEPTION,'))
                throw new AuraHandledException(e.getMessage().substringAfterLast('_EXCEPTION,'));
            else 
                throw new AuraHandledException(e.getMessage());
        } catch(Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }
  
    /*------------------------------------------------------------------------
    Author:        Kishor Kumar
    Company:       Salesforce
    Description:   To check if Quote is already finalized
    Inputs:        Quote Id
    Test Class:    
    History
    13-11-2020      Kishor Kumar     Initial Release
    ----------------------------------------------------------------------------*/
    @AuraEnabled
    public static boolean isQuoteFinalized(Id quoteId){
        List<Quote> currentQuote = [SELECT Id,Status FROM Quote WHERE Id =: quoteId];
        if(currentQuote != NULL && currentQuote.size() > 0) {
            if(currentQuote[0].Status.equalsIgnoreCase('Finalized')) {
                return true;
            } else {
                return false;
            }
        } else {
            throw new AuraHandledException('Quote not found.');
        }
    }
    
    
    //Wrapper class to create Plan Table Header
    public class PlanSelectionColumnWrapper {
        @auraEnabled public string label {get;set;}
        @auraEnabled public string fieldName {get;set;}
        
        public PlanSelectionColumnWrapper(){}
        
        public PlanSelectionColumnWrapper(string label,string fieldName) {
            this.label = label;
            this.fieldName = fieldName;
        }
    }
    
    //Wsrapper class for QLI screen
    public class LineItemWrapper {
        @auraEnabled public Id lineItemId {get;set;}
        @auraEnabled public List<Id> plans{get;set;}
        @auraEnabled public Id selectedAsset{get;set;}
        
        public LineItemWrapper(Id lineItemId,List<Id> plans,Id selectedAsset) {
            this.lineItemId = lineItemId;
            this.plans = plans;
            this.selectedAsset = selectedAsset;
        }
        
        public LineItemWrapper() {
          this.plans = new List<Id>();   
        }
    }
  
    //Wrapper class for QLI with other details
    public class LineItemInitWrapper {
        @auraEnabled public QuoteLineItem lineItem {get;set;}
        @auraEnabled public Id selectedAssetId {get;set;}
        @auraEnabled public String selectedAssetName {get;set;}
        @auraEnabled public List<Plan__c> plans {get;set;}
        @auraEnabled public List<AssetBenefitFieldWrapper> assetBenefitFields {get;set;}
        @auraEnabled public List<AssetBenefitWrapper> existingAssetBenefits {get;set;}

        public LineItemInitWrapper(QuoteLineItem lineItem,Id selectedAssetId,String selectedAssetName,List<Plan__c> plans) {
            this.lineItem = lineItem;
            this.selectedAssetId = selectedAssetId;
            this.selectedAssetName = selectedAssetName;
            this.plans = plans;
        }

        public LineItemInitWrapper() {
            this.plans = new List<Plan__c>();
        }
    }

    private List<AssetbenefitFieldWrapper> getAssetBenefitFieldDetails() {
        return new List<AssetBenefitFieldWrapper>();
    }
  
    //Wrapper calss for Asset benefit records
    public class AssetBenefitWrapper{
        @auraEnabled public Object assetBenefit {get;set;}
        @auraEnabled public boolean isSelected {get;set;}

        public AssetBenefitWrapper(Object benefit, boolean isSelected) {
            this.assetBenefit = benefit;
            this.isSelected = isSelected;
        }
    }
  
    //Wrapper class to display Asset benefit fields
    public class AssetBenefitFieldWrapper {
        @auraEnabled public string fieldLabel {get;set;}
        @auraEnabled public string fieldApiName {get;set;}
        @auraEnabled public string fieldType {get;set;}
        @auraEnabled public Map<string,string> fieldOptionsValueVsLabel {get;set;}

        public AssetbenefitFieldWrapper(){
            this.fieldOptionsValueVsLabel = new Map<string,string>();
        }

        public AssetBenefitFieldWrapper(string label,string apiName,string fieldType,Map<string,string> valueVsLabel) {
            this.fieldLabel = label;
            this.fieldApiName = apiName;
            this.fieldType = fieldType;
            this.fieldOptionsValueVsLabel = valueVsLabel;
        }
    }
    
    //Method to fetch Picklist values 
    public static map <String, String> getselectOptions(sObject objObject, string fieldApiName) {
          map <String, String> optionApiVsLabel = new map <String, String>();
        
          // Get the object type of the SObject.
          Schema.sObjectType objType = objObject.getSObjectType();
         
          // Describe the SObject using its object type.
          Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
         
          // Get a map of fields for the SObject
          map <String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap();
         
          // Get the list of picklist values for this field.
          list <Schema.PicklistEntry> values = fieldMap.get(fieldApiName).getDescribe().getPickListValues();
         
          // Add these values to the map.
          for (Schema.PicklistEntry picklistval: values) {
             optionApiVsLabel.put(picklistval.getValue(), picklistval.getLabel());
          }
        
          return optionApiVsLabel;
    }
    
    //Method to fetch fieldset
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
                    jsonPart += '"type":"' + (f.getType()) + '",';
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
}