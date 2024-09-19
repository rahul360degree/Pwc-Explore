/*------------------------------------------------------------------------
Author:        Kishor Kumar
Company:       Salesforce
Description:   Class to contain business logic for Opportunity Trigger
Inputs:        NA
Test Class:    
History
08-04-2020      Kishor Kumar     Initial Release
01-07-2020      Kartik Shetty    Added method to ensure that opportunity's sales branch field value is valid.
15-10-2020      Kartik Shetty    Added methods fr warehouse defaulting and validation.
----------------------------------------------------------------------------*/
public without sharing class OpportunityFieldPopulator {
    
    public void populateDefaults(list<Opportunity> newItems){
        map<Id, User> userMap = new map<Id, User>();
        
        try{
            //Fetch details from logged In user records
            for(User userRec: [SELECT Id, Zone__c, Logistic_Company__c , ContactId, area_code__c,Interio_Sub_Division__c, Salary_Code__c
                               FROM User 
                               WHERE Id  =: userInfo.getUserId()]){
                                   userMap.put(userRec.Id, userRec);
                               }
            
            Id rentalRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
                .get(GlobalConstants.OPPORTUNITY_MHE_RENTALS_RECORDTYPE_APINAME).getRecordTypeId();
            
            //Populate Defaults
            for(Opportunity opp : newItems){
                // Default record type to rental for internal users to avoid error during lead conversion
                // For external users an error will appear as dealers shouldn't create rental deals and don't have access to that record type
                if (opp.MHE_Division__c == GlobalConstants.MHE_SUB_DIVISION_RENTAL && userMap.get(UserInfo.getUserId()).ContactId == null) {
                    opp.RecordTypeId = rentalRecordTypeId;
                }
                
                if(userMap.containsKey(userInfo.getUserId()) && userMap.get(userInfo.getUserId()) != null){
                    //Populate Sales Zone
                    if(String.isBlank(opp.Sales_Zone__c))
                        opp.Sales_Zone__c = userMap.get(userInfo.getUserId()).Zone__c;
                    
                    //Populate Sales Branch
                    if(String.isBlank(opp.Sales_Branch_Name__c) && String.isBlank(opp.Previous_Service_Contract__c))
                        opp.Sales_Branch_Name__c = userMap.get(userInfo.getUserId()).Logistic_Company__c;
                    
                    //If Internal Sales Rep is not populated then loggedIn user as Internal Sales Rep
                    if(opp.Internal_Sales_Rep__c == null && String.isNotBlank(userMap.get(userInfo.getUserId()).Salary_Code__c)){
                        //Added by Alpana Sahay on 30th September 2022
                        if ((String.isBlank(userMap.get(userInfo.getUserId()).Contactid) && 
                             opp.Business_Unit__c==GlobalConstants.APPLIANCE_BUSINESS_UNIT ) || 
                            (opp.Business_Unit__c!=GlobalConstants.APPLIANCE_BUSINESS_UNIT) )
                        {
                            opp.Internal_Sales_Rep__c = userMap.get(userInfo.getUserId()).Id;
                        } 
                        //Ended by Alpana Sahay on 30th September 2022                       
                    }
                    
                    //Populate Interio Subdivision with Logged in User Interio Subdivision, if not populated
                    if(opp.Interio_Sub_Division__c == null){
                        opp.Interio_Sub_Division__c = userMap.get(userInfo.getUserId()).Interio_Sub_Division__c;
                    }
                    
                    //Populate area code from user on opportunity
                    if(String.isBlank(opp.Area_Code__c))
                        opp.Area_Code__c = userMap.get(userInfo.getUserId()).Area_Code__c;
                    
                }
            }
            
        }catch(Exception ex){
            Logger.logError('OpportunityFieldPopulator', 'populateDefaults', '', ex);
        }
    }
    
    public void validateStage(List<Opportunity> newOpps,Map<Id,Opportunity> oldOpps){
        List<Opportunity> applicableOpportunities=new List<Opportunity>();
        Set<Id> opportunityIds=new Set<Id>();
        if(oldOpps==null){
            for(Opportunity opp:newOpps){
                if( (opp.Business_Unit__c==GlobalConstants.BUSINESS_UNIT_MHE_DIVISION ||   
                     (opp.Business_Unit__c==GlobalConstants.INTERIO_BUSINESS_UNIT && GlobalConstants.interioB2CSubDivisions.contains(opp.Interio_Sub_Division__c)))
                   && (opp.StageName==GlobalConstants.OPPORTUNITY_STAGE_OFFER || opp.StageName==GlobalConstants.OPPORTUNITY_STAGE_NEGOTIATION))
                    opp.addError(System.Label.Cannot_change_Opportunity_stage_to_Offer_Negotiation);
            }
        }
        else{
            for(Opportunity opp:newOpps){
                if(opp.StageName!=oldOpps.get(opp.Id).StageName &&
                   (opp.Business_Unit__c==GlobalConstants.BUSINESS_UNIT_MHE_DIVISION ||   
                    (opp.Business_Unit__c==GlobalConstants.INTERIO_BUSINESS_UNIT && GlobalConstants.interioB2CSubDivisions.contains(opp.Interio_Sub_Division__c)))
                   && (opp.StageName==GlobalConstants.OPPORTUNITY_STAGE_OFFER || opp.StageName==GlobalConstants.OPPORTUNITY_STAGE_NEGOTIATION)){
                       applicableOpportunities.add(opp);
                       opportunityIds.add(opp.Id);
                   }
            }
        }
        if(applicableOpportunities.size()>0){
            Map<Id,Opportunity> idVsOpportunity=new Map<Id,Opportunity>([Select Id,(Select Id From  OpportunityLineItems) From Opportunity Where Id In :opportunityIds]);
            for(Opportunity opp:applicableOpportunities){
                if(idVsOpportunity!=null && idVsOpportunity.size()>0 && idVsOpportunity.containsKey(opp.Id) &&  
                   (idVsOpportunity.get(opp.Id).OpportunityLineItems).Size()<1)
                    opp.addError(System.Label.Cannot_change_Opportunity_stage_to_Offer_Negotiation);
            }
        }
        
    }
    
    /*------------------------------------------------------------------------
Author:        Kartik Shetty
Company:       Salesforce
Description:   Method to prepopulate warehouse lookup field on the opportunity record.
Inputs:        List<Opportunity> opportunityRecords
----------------------------------------------------------------------------*/
    public void populateOpportunityWarehouse(List<Opportunity> opportunityRecords) {
        List<Opportunity> opportunityWarehousesToDefault = new List<Opportunity>();
        
        for(Opportunity opportunityRecord : opportunityRecords) {
            if(opportunityRecord.WarehouseCode__c == null) {
                System.debug('Inside populateOpportunityWarehouse');
                opportunityWarehousesToDefault.add(opportunityRecord);
            }
        }
        
        System.debug(opportunityWarehousesToDefault.size());
        if(opportunityWarehousesToDefault.size() > 0) {
            (new InventoryUtilityController()).populateApplianceAndNormalOpportunityWarehouse(opportunityWarehousesToDefault);
        }
    }
    
    /*------------------------------------------------------------------------
Author:        Kartik Shetty
Company:       Salesforce
Description:   Method to validate whether the correct warehouse record is being populated on the opportunity records.
Inputs:        Map<Id, Opportunity> newRecordMap, List<Opportunity> oldRecords
----------------------------------------------------------------------------*/
    public void validateOpportunityWarehouses(Map<Id, Opportunity> newRecordMap, List<Opportunity> oldRecords) {
        InventoryUtilityController inventoryUtilityControllerObj = new InventoryUtilityController();
        
        if(oldRecords.size() == 0) {
            inventoryUtilityControllerObj.validateApplianceAndNormalOpportunityWarehouse(newRecordMap.values());
        } else {
            List<Opportunity> opportunityWarehousesToValidate = new List<Opportunity>();
            
            for(Opportunity oldOpportunityRecord : oldRecords) {
                Opportunity newOpportunityRecord = newRecordMap.get(oldOpportunityRecord.Id);
                if(newOpportunityRecord.WarehouseCode__c != null && oldOpportunityRecord.WarehouseCode__c != newOpportunityRecord.WarehouseCode__c) {
                    opportunityWarehousesToValidate.add(newOpportunityRecord);
                }
            }
            
            if(opportunityWarehousesToValidate.size() > 0) {
                inventoryUtilityControllerObj.validateApplianceAndNormalOpportunityWarehouse(opportunityWarehousesToValidate);
            }
        }
    }
    
    /*------------------------------------------------------------------------
Author:        Kartik Shetty
Company:       Salesforce
Description:   Method to update the warehouse lookup of child records if parent record is updated.
Inputs:        Map<Id, Opportunity> newRecordMap, List<Opportunity> oldRecords
----------------------------------------------------------------------------*/
    public void updateOpportunityProductWarehouses(Map<Id, Opportunity> newRecordMap, List<Opportunity> oldRecords) {
        // Create a set of opportunityIds which will be used to query opp products.
        Set<Id> opportunityIds = new Set<Id>();
        Set<Id> setFetchNewDuration = new Set<Id>();
        
        for(Opportunity oldOppRecord : oldRecords) {
            Opportunity newOppRecord =  newRecordMap.get(oldOppRecord.Id);
            if(oldOppRecord.WarehouseCode__c != newOppRecord.WarehouseCode__c) {
                opportunityIds.add(newOppRecord.Id);
            }
            //Added here by Praful - 22-Feb-2021 
            if(oldOppRecord.Duration_Unit__c != newOppRecord.Duration_Unit__c && oldOppRecord.Duration__c != newOppRecord.Duration__c
               && oldOppRecord.Contract_Start_Date__c != newOppRecord.Contract_Start_Date__c){
                   opportunityIds.add(newOppRecord.Id);
               }
        }
        
        // Get opp products and iterate over them to update their warehouse lookup values to that of their respective opportunity
        List<OpportunityLineItem> oppLineItems = new List<OpportunityLineItem>();
        for(OpportunityLineItem oppLineItem : [Select Id, OpportunityId, Warehouse__c FROM OpportunityLineItem WHERE OpportunityId IN :opportunityIds]) {
            oppLineItem.Warehouse__c = newRecordMap.get(oppLineItem.OpportunityId).WarehouseCode__c;
            
            //Added here by Praful - 22-Feb-2021 
            oppLineItem.Contract_End_Date__c = newRecordMap.get(oppLineItem.OpportunityId).Contract_End_Date__c;
            
            oppLineItems.add(oppLineItem);
        }
        
        if(oppLineItems.size() > 0) {
            update oppLineItems;
        }
    }
    
    /*------------------------------------------------------------------------
Author:        Anupam Mishra
Company:       Godrej
Description:   Method to update end date based on start date, duration and unit.
Inputs:        Map<Id, Opportunity> newRecordMap, Map<Id, Opportunity> oldRecordMap
----------------------------------------------------------------------------*/
    public void populateEndDate(Map<Id, Opportunity> newRecordMap, Map<Id, Opportunity> oldRecordMap){
        
        for(Opportunity opp : newRecordMap.values())
        {
            Opportunity oldOpp = oldRecordMap.get(opp.Id);
            if( oldOpp.Duration_Unit__c != opp.Duration_Unit__c || oldOpp.Duration__c != opp.Duration__c || oldOpp.Contract_Start_Date__c != opp.Contract_Start_Date__c)
            {
                populateEndDate(newRecordMap.values());
            }
        }
    }
    
    /*------------------------------------------------------------------------
Author:        Anupam Mishra
Company:       Godrej
Description:   Method to update end date based on start date, duration and unit.
Inputs:        List<Opportunity> newRecords
----------------------------------------------------------------------------*/
    public void populateEndDate(List<Opportunity> newRecords){
        
        for(Opportunity opp : newRecords)
        {
            opp.Contract_End_Date__c = getEndDateBasedOnDuration(opp.Contract_Start_Date__c, opp.Duration__c, opp.Duration_Unit__c);
        }
    }
    
    /*------------------------------------------------------------------------
Author:        Anupam Mishra
Company:       Godrej
Description:   Method to update end date based on start date, duration and unit.
Inputs:        List<Opportunity> newRecords
----------------------------------------------------------------------------*/
    public date getEndDateBasedOnDuration(Date startDate, Decimal intDuration, String strDurationUnit){
        
        if( strDurationUnit != null && intDuration != null && startDate != null )
        {
            switch on strDurationUnit {
                when 'Day' {
                    return startDate.addDays((integer)intDuration)-1;
                }
                when 'Week' {
                    return startDate.addDays((integer)(intDuration*7 ))-1;
                }
                when 'Month' {
                    return startDate.addMonths((integer)intDuration)-1;
                }
                when 'Quarter' {
                    return startDate.addMonths((integer)intDuration*3)-1;
                }
                when 'Year' {
                    return startDate.addMonths((integer)(12 * intDuration))-1;
                }
                when else {
                    return null;
                }
            }
        }else{
            return null;
        }
        
        
    }
    
    /*------------------------------------------------------------------------  
* @description       : Updating Opportunity NO for  PES division
* @author            : snehalw@godrej.com
* @group             : 
* @last modified on  : 10-03-2023
* @last modified by  : snehalw@godrej.com
----------------------------------------------------------------------------*/
    public void updateOpportunityNumbers(List<Opportunity> opportunities) {
        
        
       // To get curent financial year
        String currentFiscalYear = [SELECT FiscalYearSettings.Name FROM Period WHERE Type = 'Year' AND StartDate <= TODAY AND EndDate >= TODAY].FiscalYearSettings.Name;
        // converting to integer
        Integer PreviousYear = Integer.ValueOf (currentFiscalYear )- 1;
        // to get financial year in format 22-23
        String financialYear = String.valueOf(PreviousYear).substring(2, 4) + currentFiscalYear.substring(2, 4);
    
        // Collecting all the necessary data for the query
        Set<String> sectorSet = new Set<String>();
        Set<String> firms = new Set<String>();
        for (Opportunity opp : opportunities) {
            sectorSet.add(opp.Sector__c);
            firms.add(opp.Firm_BQ__c);
        }
        
        // Querying the Opportunity object to get the maximum auto number for the given sectors and firms
        Map<String, Opportunity> maxOpportunityBySector = new Map<String, Opportunity>();
        List<Opportunity> oppList = [SELECT Opportunity_No__c, Sector__c, Firm_BQ__c
                                     FROM Opportunity
                                     WHERE Sector__c IN :sectorSet AND Firm_BQ__c IN :firms AND Opportunity_No__c 
                                     LIKE :'%'+ financialYear + '/%'
                                     ORDER BY CreatedDate DESC LIMIT 1 ];
        
        for (Opportunity opp : oppList) {
            String sectorInitial = opp.Sector__c.substring(0, 1);
            String key = opp.Firm_BQ__c + '/' + sectorInitial;
            if (!maxOpportunityBySector.containsKey(key)) {
                maxOpportunityBySector.put(key, opp);
            }
        }
        Id pesRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('PES').getRecordTypeId();
        
        // Updating the Opportunity records
        for (Opportunity opp : opportunities) {
            if (opp.RecordTypeId == pesRecordTypeId && opp.Sector__c != null) {
                String firm = opp.Firm_BQ__c;
                String sectorInitial = opp.Sector__c.substring(0, 1);// To take sector initial letter
                
                // Get the maximum auto number for the given sector and firm
                String key = firm + '/' + sectorInitial;
                Opportunity maxOpportunity = maxOpportunityBySector.get(key);
                Integer autoNumber = 1;
                if (maxOpportunity != null) {
                    String autoNumberStr = maxOpportunity.Opportunity_No__c.substringAfterLast('/');
                    autoNumber = Integer.valueOf(autoNumberStr) + 1;
                }
                
                
                if (opp.Firm_BQ__c == GlobalConstants.OPPORTUNITY_FIRM) {	
                    opp.Opportunity_No__c = GlobalConstants.OPPORTUNITY_NO_CONSTANT_GPE + '/' + sectorInitial + '/' + financialYear + '/' + String.valueOf(autoNumber);
                } else if (opp.Firm_BQ__c == GlobalConstants.OPPORTUNITY_BQ) {	 
                    opp.Opportunity_No__c = GlobalConstants.OPPORTUNITY_NO_CONSTANT_GPE + '/BQ/' + sectorInitial + '/' + financialYear + '/' + String.valueOf(autoNumber);
                }
            }
        }
    }
    
    // Added by rohit jadhav on 31 July 2023 for PED
     public void validateOpportunityFieldsForPED(List<Opportunity> newItems) {
        Id pedBQRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get(GlobalConstants.PED_BQ_OPPORTUNITY_RT).getRecordTypeId();
        Id pedFirmRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get(GlobalConstants.PED_FIRM_OPPORTUNITY_RT).getRecordTypeId();
        List<Opportunity> opportunityList=new List<Opportunity>();
        Set<String> projectNameSet=new Set<String>();
        Set<String> regionSet=new Set<String>();
        Set<String> endUserSet=new Set<String>();
        Map<String,Lead> leadMap=new Map<String,Lead>();
        for(Opportunity opp : newItems){
                if (opp.Converted_Lead__c==null && (opp.RecordTypeId == pedBQRecordTypeId || opp.RecordTypeId == pedFirmRecordTypeId) &&
                   (opp.Project_Name__c==null || opp.End_User__c==null || opp.PED_Region__c==null)) {
                    opp.addError('Project Name, Lead Region, End User is Mandatory.');
                }
        }
    }
    
     // Added by rohit jadhav on 31 July 2023 for PED
    public void checkLeadIsPresentForPED(List<Opportunity> newItems) {
        Id pedLeadRecordTypeId=Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get(GlobalConstants.PED_Lead_RT).getRecordTypeId();
        Id pedBQRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get(GlobalConstants.PED_BQ_OPPORTUNITY_RT).getRecordTypeId();
        Id pedFirmRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get(GlobalConstants.PED_FIRM_OPPORTUNITY_RT).getRecordTypeId();
        List<Opportunity> opportunityList=new List<Opportunity>();
        Set<String> projectNameSet=new Set<String>();
        Set<String> regionSet=new Set<String>();
        Set<String> endUserSet=new Set<String>();
        Map<String,Lead> leadMap=new Map<String,Lead>();
        for(Opportunity opp : newItems){
                if (opp.Converted_Lead__c==null && (opp.RecordTypeId == pedBQRecordTypeId || opp.RecordTypeId == pedFirmRecordTypeId)) {
                    opportunityList.add(opp);
                    projectNameSet.add(opp.Project_Name__c);
                    regionSet.add(opp.PED_Region__c);
                    endUserSet.add(opp.End_User__c);
                }
        }
        if(!opportunityList.isEmpty()){
            for(Lead LeadRecord:[Select Id,Project_Name__c,PED_Region__c,End_User__c,Name_of_New_End_User__c  from Lead where RecordTypeId=:pedLeadRecordTypeId and Project_Name__c IN :projectNameSet and PED_Region__c IN :regionSet and End_User__c IN :endUserSet]){
                leadMap.put(LeadRecord.Project_Name__c+'-'+LeadRecord.PED_Region__c+'-'+LeadRecord.End_User__c+'-'+LeadRecord.Name_of_New_End_User__c ,LeadRecord);
            }
            if(!leadMap.isEmpty()){
                for(Opportunity opp : opportunityList){
                    if(leadMap.containsKey(opp.Project_Name__c+'-'+opp.PED_Region__c+'-'+opp.End_User__c+'-'+opp.Name_of_New_End_User__c))
                    {
                        Lead leadRecord=leadMap.get(opp.Project_Name__c+'-'+opp.PED_Region__c+'-'+opp.End_User__c+'-'+opp.Name_of_New_End_User__c);
                        opp.addError('Lead with Project Name: '+leadRecord.Project_Name__c +' , End User:  '+leadRecord.End_User__c +
                                     ' , Lead Region:  '+leadRecord.PED_Region__c +' is already created.Please go to Lead Record and create opportunity from opportunity related list.'+
                                     '\n Following is the Lead Record Link :'+'\n'+ URL.getOrgDomainUrl().toExternalForm()+'/lightning/r/Quote/'+leadRecord.Id+'/view');
                    }
                }
            }
        }
    }
    
     // Added by rohit jadhav on 31 July 2023 for PED
    public void updateBalanceOpportunityValueOnLeadForPED(Map<Id, Opportunity> newRecordMap, Map<Id, Opportunity> oldRecordMap) {
        Set<String> leadIdSet=new Set<String>();
        Map<String,Decimal> OpportunityMap=new Map<String,Decimal>();
        Map<String,Decimal> LeadMap=new Map<String,Decimal>();
        List<Lead> leadRecordToUpdate=new List<Lead>();
        Id pedFirmRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get(GlobalConstants.PED_FIRM_OPPORTUNITY_RT).getRecordTypeId();
        Set<String> firmOpportunitySet=new Set<String>();
        try{
            for(Opportunity opp : newRecordMap.values()){
                if (opp.Converted_Lead__c!=null && opp.Opportunity_Value__c!=null && ( trigger.isInsert
                                                   || opp.Converted_Lead__c != oldRecordMap.get(opp.Id).Converted_Lead__c
                                                   || opp.Opportunity_Value__c != oldRecordMap.get(opp.Id).Opportunity_Value__c
                                                   || opp.Package__c != oldRecordMap.get(opp.Id).Package__c
                                                   || opp.Currency__c != oldRecordMap.get(opp.Id).Currency__c
                                                   || opp.RecordTypeId != oldRecordMap.get(opp.Id).RecordTypeId)) {
                    leadIdSet.add(opp.Converted_Lead__c);
                }
            }
            if(!leadIdSet.isEmpty())
            {
                String newLeadId='';
                String oldLeadId='';
                Decimal balanceValue=0;
                for(Opportunity oppRecord:[Select Id,Opportunity_Value__c,Package__c,Converted_Lead__c,Unit_Opportunity__c,Conversion_Rate__c,
                                           Converted_Lead__r.Opportunity_Value__c,Converted_Lead__r.Unit_Opportunity__c,EQUIPMENT_TYPE__c,
                                           Converted_Lead__r.Opportunity_Value_In_Cr__c,RecordTypeId from Opportunity
                                           where Converted_Lead__c IN: leadIdSet order by Converted_Lead__c,
                                           Package__c,EQUIPMENT_TYPE__c]){
                    Decimal tempValue;
                    LeadMap.put(oppRecord.Converted_Lead__c,oppRecord.Converted_Lead__r.Opportunity_Value_In_Cr__c);
                    if(oppRecord.RecordTypeId==pedFirmRecordTypeId)
                    {
                        tempValue=oppRecord.Unit_Opportunity__c==GlobalConstants.Unit_Million ? oppRecord.Opportunity_Value__c * oppRecord.Conversion_Rate__c * 0.1 : oppRecord.Opportunity_Value__c;
                        OpportunityMap.put(oppRecord.Converted_Lead__c+'-'+oppRecord.Package__c,tempValue);   
                        firmOpportunitySet.add(oppRecord.Converted_Lead__c+'-'+oppRecord.Package__c);           
                    }
                    if(!firmOpportunitySet.contains(oppRecord.Converted_Lead__c+'-'+oppRecord.Package__c)){
                         if(!OpportunityMap.isEmpty() && OpportunityMap.containsKey(oppRecord.Converted_Lead__c+'-'+oppRecord.Package__c)){
                            tempValue=oppRecord.Unit_Opportunity__c==GlobalConstants.Unit_Million ? oppRecord.Opportunity_Value__c * oppRecord.Conversion_Rate__c * 0.1 : oppRecord.Opportunity_Value__c;   
                            if(tempValue > OpportunityMap.get(oppRecord.Converted_Lead__c+'-'+oppRecord.Package__c)){
                                OpportunityMap.put(oppRecord.Converted_Lead__c+'-'+oppRecord.Package__c,tempValue);
                            }
                        }else{
                            tempValue=oppRecord.Unit_Opportunity__c==GlobalConstants.Unit_Million ? oppRecord.Opportunity_Value__c * oppRecord.Conversion_Rate__c * 0.1 : oppRecord.Opportunity_Value__c;
                            OpportunityMap.put(oppRecord.Converted_Lead__c+'-'+oppRecord.Package__c,tempValue);            
                        }                          
                    }
                }
                if(!OpportunityMap.isEmpty())
                {
                    for(String key:OpportunityMap.keySet())
                    {
                        String leadId=key.substringBefore('-');
                        if(LeadMap.containsKey(leadId)){
                            LeadMap.put(leadId,LeadMap.get(leadId)-OpportunityMap.get(key));
                        }                        
                    }
                    for(String key:LeadMap.keySet())
                    {
                        Lead leadRecord=new Lead(Id=key,Balance_Opportunity_Value__c=LeadMap.get(key));
                        leadRecordToUpdate.add(leadRecord);
                    }
                } 
                if(!leadRecordToUpdate.isEmpty())
                {
                    update leadRecordToUpdate;
                }
            }
        }catch(Exception ex){
            Logger.logError('OpportunityFieldPopulator', 'updateBalanceOpportunityValueOnLeadForPED', '', ex);
        }
    }
}