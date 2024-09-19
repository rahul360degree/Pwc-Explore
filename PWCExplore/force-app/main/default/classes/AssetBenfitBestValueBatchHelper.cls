/*-----------------------------------------------------------------------------------
* Author        :        Mahith Madwesh
* Company       :        Salesforce
* Description   :        Batch job Helper for Updating Asset Benefit Best Value on Assets
* Inputs        :        
* Test Class    :         AssetBenfitBestValueBatchHelperTest.cls
* History
* --------
* 23-11-2020      Mahith Madwesh     Initial Release
* 12-03-2023      PSM			     Added the best asset benefit record to the asset 
* ---------------------------------------------------------------------------------*/
public with sharing class AssetBenfitBestValueBatchHelper {
    
    
    public list<Asset> UpdatebestValueBenifit(list<Asset> assetRecords){
        list<Asset> assetsToUpdate = new list<Asset>();   
        list<string> picklistValues = [SELECT Id, Label, Value__c, Description__c FROM Application_Settings__mdt where Label = 'Asset Benifit Best Value'].get(0).Value__c.split(' > ');                                      
        for(asset a:assetRecords){
            
            Asset assetRecord = new Asset();
            //Field update to bypass the validation :: Past date can't be edited
            assetRecord.Is_System_Update__c = true;
            //GCP-22
            if(a.Asset_Benefits__r.size() == 0 && Schema.sObjectType.Asset.isCreateable()){
                
                //reset the benefits
                assetRecord.Audits__c = '';
                assetRecord.Asset_Benefit__c = null;
                assetRecord.Scheduled_PM_Visits_Number__c = 0;
                assetRecord.Scheduled_PM_Visits__c = '';
                assetRecord.Operator__c = '';
                assetRecord.BD_Visits__c = '';
                assetRecord.BD_Visits_Number__c = 0;
                assetRecord.Parts_Support__c = '';
                assetRecord.Remote_Assistance__c = '';
                assetRecord.Reports_Dashboards__c = '';
                assetRecord.Stationed_Manpower__c = '';
                assetRecord.Supervisor__c = '';
                assetRecord.Equipment_Type__c = '';
                assetRecord.Id = a.Id;
                assetRecord.Recalculation_Required__c = false;
                
                //Reset all the existing dates
                for(Integer i=1; i < 13; i++){
                    String fieldName = 'Scheduled_PM_Visit_' + i +'__c';
                    assetRecord.put(fieldName, Null);
                }
                
                //add asset to update list 
                assetsToUpdate.add(assetRecord);
                
            } else{
                //To store the Asset Benefit Record to check if it is legacy or not
                Asset_Benefit__c tempBenefit = new Asset_Benefit__c();
                
                assetRecord.Date_of_Commissioning__c = a.Date_of_Commissioning__c;
                
                assetRecord.Id = a.Id;
                assetRecord.Product_Purchased_Warranty_Start_Date__c = a.Product_Purchased_Warranty_Start_Date__c;
                assetRecord.Product_Purchased_Warranty_End_Date__c = a.Product_Purchased_Warranty_End_Date__c;
                
                map<Id,Asset_Benefit__c> relationShipMap = getMaxPMvisit(a.Asset_Benefits__r);
                
                for(Id id : relationShipMap.keySet())
                {
                    assetRecord.Asset_Benefit__c =  id;
                    assetRecord.Asset_Benefit__r =  relationShipMap.get(id);//PSM - Added the best asset benefit record to the asset record SMF-104  
                    assetRecord.Scheduled_PM_Visits_Number__c = relationShipMap.get(id).Scheduled_PM_Visits_Number__c;
                    tempBenefit = relationShipMap.get(id);
                    if((relationShipMap.get(id).Contract_Line_Item__r <> NULL) && relationShipMap.get(id).Contract_Line_Item__r.ServiceContract.Approved_Date__c!=null && relationShipMap.get(id).Contract_Line_Item__r.endDate!=null){
                        assetRecord.Asset_Benefit_CLI_Start_Date__c = relationShipMap.get(id).Contract_Line_Item__r.ServiceContract.Approved_Date__c;//added approved date for MHE-SMF-139 
                        assetRecord.Asset_Benefit_CLI_End_Date__c = relationShipMap.get(id).Contract_Line_Item__r.endDate;
                    }
                }
                
                assetRecord.BD_Visits_Number__c = getMaxBdVisitValue(a.Asset_Benefits__r);
                
                map<string,string> BenifitBestValuesMap = getPicklistBestValue(a.Asset_Benefits__r,picklistValues);
                for(string s : BenifitBestValuesMap.keySet()){
                    if(s == 'PM visits'){
                        assetRecord.Scheduled_PM_Visits__c = BenifitBestValuesMap.get(s);
                    }
                    if(s == 'Operator'){
                        assetRecord.Operator__c = BenifitBestValuesMap.get(s);
                    }
                    if(s == 'BD Visits'){
                        assetRecord.BD_Visits__c = BenifitBestValuesMap.get(s);   
                    }
                    if(s == 'Part Support'){
                        assetRecord.Parts_Support__c = BenifitBestValuesMap.get(s);   
                    }
                    if(s == 'Remote Assitance'){
                        assetRecord.Remote_Assistance__c = BenifitBestValuesMap.get(s);   
                    }
                    if(s == 'Reports'){
                        assetRecord.Reports_Dashboards__c = BenifitBestValuesMap.get(s);   
                    }
                    if(s == 'Supervisor'){
                        assetRecord.Supervisor__c = BenifitBestValuesMap.get(s);   
                    }
                    if(s == 'Equipment Type'){
                        assetRecord.Equipment_Type__c = BenifitBestValuesMap.get(s);                       
                    }
                    if(s == 'Station Manpower'){
                        assetRecord.Stationed_Manpower__c = BenifitBestValuesMap.get(s);                       
                    }
                    if(s == 'Audits'){
                        assetRecord.Audits__c = BenifitBestValuesMap.get(s);                      
                    }     
                }
                system.debug('Asset Record with updated Data'+assetRecord);
                system.debug('Asset Beneft Record with updated Data'+tempBenefit);
                if(!tempBenefit.Is_Legacy_Benefit__c && tempBenefit.Name != GlobalConstants.ASSET_STD_WARRANTY){
                    /*if(assetRecord.Asset_Benefit_CLI_Start_Date__c!=null //redundant else if
                        && assetRecord.Asset_Benefit_CLI_End_Date__c != null){
                        populatePMVisitDates(assetRecord);
                        }else if(assetRecord.Product_Purchased_Warranty_Start_Date__c != null 
                        && assetRecord.Product_Purchased_Warranty_End_Date__c != null){
                        system.debug('Asset Record for populating report'+assetRecord);
                        populatePMVisitDates(assetRecord);
                        }*/
                    if((assetRecord.Asset_Benefit_CLI_Start_Date__c!=null && assetRecord.Asset_Benefit_CLI_End_Date__c != null)|| 
                       (assetRecord.Product_Purchased_Warranty_Start_Date__c != null && assetRecord.Product_Purchased_Warranty_End_Date__c != null))
                           populatePMVisitDates(assetRecord);
                           
                }
                else if(!tempBenefit.Is_Legacy_Benefit__c && tempBenefit.Name == GlobalConstants.ASSET_STD_WARRANTY){
                           //populate the standard warranty Date
                           populateStandardWarrantyPMDates(assetRecord,tempBenefit);
                }
                assetRecord.Recalculation_Required__c = false;
                assetsToUpdate.add(assetRecord);
            }
            //assetsToUpdate.add(assetRecord); moved it inside
        }
        return assetsToUpdate;
    }
    
        
    /*------------------------------------------------------------------------
    Author:        Mahith Madwesh
    Company:       Salesforce
    Description:   method to find the max value of BD Visit
    Inputs:        NA
    Test Class:    
    History
    23-11-2020      Mahith Madwesh    Initial Release
    ----------------------------------------------------------------------------*/
    public  Double getMaxBdVisitValue(List<Asset_Benefit__c> assetBenifitRecords ){
        
        Double maxValue;
        
        list<double> pmVisitNumber = new List<Double>();
        
        for(Asset_Benefit__c ab:  assetBenifitRecords){
            pmVisitNumber.add(ab.BD_Visits_Number__c);
        }
        
        pmVisitNumber.sort();
        
        
        for(integer i =0;i<pmVisitNumber.size();i++){
            if(i==pmVisitNumber.size()-1){
                maxvalue = pmVisitNumber[i];
            }
        }
        
        
        return maxValue;
    }
    
    
    /*------------------------------------------------------------------------
    Author:        Mahith Madwesh
    Company:       Salesforce
    Description:   method to populae Date for PM scheduling 
    Inputs:        Asset record
    Test Class:    
    History
    23-11-2020      Mahith Madwesh    Initial Release
	12-03-2023		PSM				  Populating the PM dates depending on EWP or otherwise option 
    ----------------------------------------------------------------------------*/
    public Asset populatePMVisitDates(Asset assetRecord){
        
        Datetime warrantyStartDate;
        Datetime warrantyEndDate;
        Datetime dateOfCommissioning;
        //Fetch Warranty Start Date of asset 
        if(assetRecord.Asset_Benefit_CLI_Start_Date__c!=null){
            warrantyStartDate = assetRecord.Asset_Benefit_CLI_Start_Date__c;
        }else if(assetRecord.Product_Purchased_Warranty_Start_Date__c!=null){
            warrantyStartDate = assetRecord.Product_Purchased_Warranty_Start_Date__c;
        }
        if(assetRecord.Date_of_Commissioning__c!=null)
            dateOfCommissioning=assetRecord.Date_of_Commissioning__c;
        //Fetch Warranty End Date of asset 
        if(assetRecord.Asset_Benefit_CLI_End_Date__c!=null){
            warrantyEndDate = assetRecord.Asset_Benefit_CLI_End_Date__c;
        }else if(assetRecord.Product_Purchased_Warranty_End_Date__c!=null){
            warrantyEndDate = assetRecord.Product_Purchased_Warranty_End_Date__c;
        }
        
        Integer noOfScheduledVisits = Integer.valueOf(assetRecord.Scheduled_PM_Visits_Number__c);//Fetch Number of PM Scheduled Visit of asset 														   
        Integer noOfDaysInBetween = Date.valueOf(warrantyStartDate).daysBetween(Date.valueOf(warrantyEndDate));//Calculate the No of days in between Start Date & End date
        
        //Calculate the No of days in between every visit
        Decimal visitInterval;
        if (noOfScheduledVisits > 0){//added to avoid null error 
             visitInterval = (noOfDaysInBetween-Integer.valueOf(System.Label.Ten))/noOfScheduledVisits;
        }
        Integer roundedVisitInterval;
        if (visitInterval != null) {
               roundedVisitInterval = Integer.valueOf(visitInterval.round(system.roundingMode.DOWN));
        }
        //Initialize Final visit date
        Date finalVisitDate = system.today();
        Date visitDate;
        
        //Reset all the existing dates
        for(Integer i=1; i < 13; i++){
            String fieldName = 'Scheduled_PM_Visit_' + i +'__c';
            system.debug('fieldName: '+fieldName);
            assetRecord.put(fieldName, Null);
        }
        
        //Populate dates
        for(Integer j=1; j <= assetRecord.Scheduled_PM_Visits_Number__c ; j++){
            String visitFieldName = 'Scheduled_PM_Visit_' + j +'__c';
            system.debug('visitFieldName: '+visitFieldName);
            system.debug('assetRecord.Asset_Benefit__r.plan__r.name:'+assetRecord.Asset_Benefit__r.plan__r.name);
            if(j <= noOfScheduledVisits){ 
                if (assetRecord.Asset_Benefit__r.plan__r.name==GlobalConstants.ASSET_SILVER_EWP_WARRANTY)
                    if(j==1)
                    	visitDate = Date.valueof(dateOfCommissioning).addDays((Integer.valueOf(System.label.THIRTY)));//PSM SMF-104 Changing the 1st Sch date for EWP plan
                    else 
                    	visitDate = Date.valueof(dateOfCommissioning).addDays(Integer.valueOf(System.label.NINETY) * (j-1));//PSM SMF-104 Changing the rest of the Sch dates for EWP plan
                else 
                	visitDate = Date.valueof(warrantyStartDate).addDays((Integer.valueOf(System.label.TEN))+(roundedVisitInterval * (j-1)));//PSM SMF-104 Changing the Sch dates for Contracts and subscriptions    
                
            }
            
                //Check if Visit Date is Sunday
                Datetime visitDateTime = DateTime.newInstance(visitDate, Time.newInstance(0, 0, 0, 0));
                String visitDay = visitDateTime.format('EEEE');
                
                //Check if Visit Date is Sunday
                if(visitDay.equalsIgnoreCase(System.label.Week_Day_Sunday))
                    //Check if Next date is before Warranty end date else make it Previous date
                    if(visitDate.addDays(1) <= warrantyEndDate)
                        finalVisitDate = visitDate.addDays(1);
                    else
                        finalVisitDate = visitDate.addDays(-1);  
                else 
                    finalVisitDate = visitDate;
                
                //Update the visit date
                assetRecord.put(visitFieldName, finalVisitDate);
            }
        
        if (assetRecord.Scheduled_PM_Visit_1__c > Date.Today())
        {
            assetRecord.Case_Creation_Status__c = NULL;
        }
        return assetRecord;    
    }
    
    /*------------------------------------------------------------------------
    Author:        Mahith Madwesh
    Company:       Salesforce
    Description:   method to get Max PM visit number and Asset Benifit Id 
    Inputs:        Asset record
    Test Class:    
    History
    23-11-2020      Mahith Madwesh    Initial Release
    ----------------------------------------------------------------------------*/
    public map<Id,Asset_Benefit__c> getMaxPMvisit(List<Asset_Benefit__c> assetBenifitRecords){
        map<Id,Asset_Benefit__c> finalResult = new  map<Id,Asset_Benefit__c>();
        Double maxValue;
        list<double> pmVisitNumber = new List<Double>();
        for(Asset_Benefit__c ab:  assetBenifitRecords){
            pmVisitNumber.add(ab.Scheduled_PM_Visits_Number__c);
        }
        pmVisitNumber.sort();  
        for(integer i =0;i<pmVisitNumber.size();i++){
            if(i==pmVisitNumber.size()-1){
                maxvalue = pmVisitNumber[i];
            }
        }    
        for(Asset_Benefit__c ab1:  assetBenifitRecords){
            if(maxValue == ab1.Scheduled_PM_Visits_Number__c){
                System.debug('MAx value in map>>>>'+maxValue);
                finalResult.put(ab1.Id,ab1);
            }
        }   
        return finalResult;
    }
    
    /*------------------------------------------------------------------------
    Author:        Mahith Madwesh
    Company:       Salesforce
    Description:   method to find the best picklist value Based on 
    Application Setting mdt
    Inputs:        NA
    Test Class:    
    History
    23-11-2020      Mahith Madwesh    Initial Release
    ----------------------------------------------------------------------------*/
    public map<string,string> getPicklistBestValue(List<Asset_Benefit__c> assetBenifitRecords,list<string> picklistValues ){
        
        map<string,string> finalResult = new map<string,string>();
        
        if(picklistValues.size()>0){
            list<Integer> tempPMValues = new list<Integer>();
            list<Integer> tempOperatorValues = new list<Integer>();
            list<Integer> tempBDValues = new list<Integer>();
            list<Integer> tempPartValues = new list<Integer>();
            list<Integer> tempRemoteAssitanceValues = new list<Integer>();
            list<Integer> tempReportsValues = new list<Integer>();
            list<Integer> tempSuperVisorValues = new list<Integer>();
            list<Integer> tempEquipmentTypeValues = new list<Integer>();
            list<Integer> tempStationManpowerValues = new list<Integer>();
            list<Integer> tempAuditValues = new list<Integer>();
            for(Asset_Benefit__c ab: assetBenifitRecords){
                
                if(ab.Scheduled_PM_Visits__c!=null || picklistValues.indexOf(ab.Scheduled_PM_Visits__c)!=-1){
                    tempPMValues.add(picklistValues.indexOf(ab.Scheduled_PM_Visits__c));
                }
                
                if(ab.Operator__c!=null || picklistValues.indexOf(ab.Operator__c)!=-1){
                    tempOperatorValues.add(picklistValues.indexOf(ab.Operator__c));
                }
                
                if(ab.BD_Visits__c!=null || picklistValues.indexOf(ab.BD_Visits__c)!=-1){
                    tempBDValues.add(picklistValues.indexOf(ab.BD_Visits__c));
                }
                
                if(ab.Parts_Support__c!=null || picklistValues.indexOf(ab.Parts_Support__c)!=-1){
                    tempPartValues.add(picklistValues.indexOf(ab.Parts_Support__c));
                }
                
                if(ab.Remote_Assistance__c!=null || picklistValues.indexOf(ab.Remote_Assistance__c)!=-1){
                    tempRemoteAssitanceValues.add(picklistValues.indexOf(ab.Remote_Assistance__c));
                }
                
                if(ab.Reports_Dashboards__c!=null || picklistValues.indexOf(ab.Reports_Dashboards__c)!=-1){  
                    tempReportsValues.add(picklistValues.indexOf(ab.Reports_Dashboards__c));
                }
                
                if(ab.Supervisor__c!=null || picklistValues.indexOf(ab.Supervisor__c)!=-1){   
                    tempSuperVisorValues.add(picklistValues.indexOf(ab.Supervisor__c));
                }
                
                if(ab.Equipment_Type__c!=null || picklistValues.indexOf(ab.Equipment_Type__c)!=-1){   
                    tempEquipmentTypeValues.add(picklistValues.indexOf(ab.Equipment_Type__c));
                }
                
                if(ab.Stationed_Manpower__c!=null || picklistValues.indexOf(ab.Stationed_Manpower__c)!=-1){   
                    tempStationManpowerValues.add(picklistValues.indexOf(ab.Stationed_Manpower__c));
                }
                
                if(ab.Audits__c!=null || picklistValues.indexOf(ab.Audits__c)!=-1){   
                    tempAuditValues.add(picklistValues.indexOf(ab.Audits__c));
                }
                
                
            }
            tempPMValues.sort();
            tempOperatorValues.sort();
            tempBDValues.sort();
            tempPartValues.sort();
            tempRemoteAssitanceValues.sort();
            tempReportsValues.sort();
            tempSuperVisorValues.sort();
            tempEquipmentTypeValues.sort();
            tempStationManpowerValues.sort();
            tempAuditValues.sort();
            
            
            if(tempPMValues.size()>0){
                finalResult.put('PM visits',picklistValues[tempPMValues[0]]);
            }
            
            if(tempOperatorValues.size()>0){
                finalResult.put('Operator',picklistValues[tempOperatorValues[0]]);
            }
            
            if(tempBDValues.size()>0){
                finalResult.put('BD Visits',picklistValues[tempBDValues[0]]);
            }
            
            if(tempPartValues.size()>0){
                finalResult.put('Part Support',picklistValues[tempPartValues[0]]);
            }
            
            if(tempRemoteAssitanceValues.size()>0){
                finalResult.put('Remote Assitance',picklistValues[tempRemoteAssitanceValues[0]]);
            }
            
            if(tempReportsValues.size()>0){
                finalResult.put('Reports',picklistValues[tempReportsValues[0]]);
            }
            
            if(tempSuperVisorValues.size()>0){
                finalResult.put('Supervisor',picklistValues[tempSuperVisorValues[0]]);
            }
            
            if(tempEquipmentTypeValues.size()>0){
                finalResult.put('Equipment Type',picklistValues[tempEquipmentTypeValues[0]]);
            }
            
            if(tempStationManpowerValues.size()>0){
                finalResult.put('Station Manpower',picklistValues[tempStationManpowerValues[0]]);
            }
            
            if(tempAuditValues.size()>0){
                finalResult.put('Audits',picklistValues[tempAuditValues[0]]);
            }
            
        }
        return finalResult;
    }
    
    
    /*------------------------------------------------------------------------
    Author:        Mahith Madwesh
    Company:       Salesforce
    Description:   Method to populate Std Warranty PM Dates 
    Application Setting mdt
    Inputs:        NA
    Test Class:    
    History
    23-11-2020      Mahith Madwesh    Initial Release
    --------------------------------------------------------------------------*/
    public Asset populateStandardWarrantyPMDates(Asset assetRecord, Asset_Benefit__c assetBenifitRecord){
        DateTime warrantyStartDate;  
        if(assetRecord.Date_of_Commissioning__c!=null){
            warrantyStartDate = assetRecord.Date_of_Commissioning__c;
            
            Datetime visitDateTime = DateTime.newInstance(Date.valueOf(warrantyStartDate).addDays(30), Time.newInstance(0, 0, 0, 0));
            String visitDay = visitDateTime.format('EEEE');
            
            //Check if Visit Date is Sunday
            if(visitDay.equalsIgnoreCase(System.label.Week_Day_Sunday)){
                assetRecord.Scheduled_PM_Visit_1__c = Date.valueOf(warrantyStartDate).addDays(30).addDays(1);
            }else{
                assetRecord.Scheduled_PM_Visit_1__c = Date.valueOf(warrantyStartDate).addDays(30);
            }     
            Datetime visitDateTime1 = DateTime.newInstance(Date.valueOf(warrantyStartDate).addDays(90), Time.newInstance(0, 0, 0, 0));
            String visitDay1 = visitDateTime1.format('EEEE');
            
            //Check if Visit Date is Sunday
            if(visitDay1.equalsIgnoreCase(System.label.Week_Day_Sunday)){
                assetRecord.Scheduled_PM_Visit_2__c = Date.valueOf(warrantyStartDate).addDays(90).addDays(1);
            }else{
                assetRecord.Scheduled_PM_Visit_2__c = Date.valueOf(warrantyStartDate).addDays(90);
            }
            Datetime visitDateTime2 = DateTime.newInstance(Date.valueOf(warrantyStartDate).addDays(180), Time.newInstance(0, 0, 0, 0));
            String visitDay2 = visitDateTime2.format('EEEE');
            
            //Check if Visit Date is Sunday
            if(visitDay2.equalsIgnoreCase(System.label.Week_Day_Sunday)){
                assetRecord.Scheduled_PM_Visit_3__c = Date.valueOf(warrantyStartDate).addDays(180).addDays(1);
            }else{
                assetRecord.Scheduled_PM_Visit_3__c = Date.valueOf(warrantyStartDate).addDays(180);
            }                        
        }       
        return assetRecord;
    }          
}