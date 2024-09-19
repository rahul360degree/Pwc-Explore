/*------------------------------------------------------------------------
Author:        Nupoor Sharma
Company:       Salesforce
Description:   Helper class for Service Form Trigger Handler
Inputs:        NA
Test Class:    
History
16-12-2020      Nupoor Sharma     Initial Release
----------------------------------------------------------------------------*/
public without sharing class ServiceFormTriggerHelper {
	
    /*------------------------------------------------------------------------
    Author:        Nupoor Sharma
    Company:       Salesforce
    Description:   Methos to share service form records with case team members & case owner
    Inputs:        NA
    Test Class:    
    History
    16-12-2020      Nupoor Sharma     Initial Release
    ----------------------------------------------------------------------------*/
    public void shareWithCaseTeam(Map<Id, Service_Form__c> newItems){
        //Service_Form__c object is only used for MHE
        Map<ID,Case> caseMap = new Map<ID,Case>();
        for(Service_Form__c newObj : newItems.values())
        {
            if(String.isNotBlank(newObj.Case__c)){
            caseMap.put(newObj.Case__c, new Case( Id = newObj.Case__c ));
            }
        }
        if(caseMap.size()>0)
            ShareServiceFormsWithCaseTeam.shareForCase(caseMap.values());
    }
    
    /*------------------------------------------------------------------------
    Author:        Amit Shingavi
    Company:       Salesforce
    Description:   Method to now to allow users to create multiple job card for the same day against a SR
    Inputs:        NA
    Test Class:    
    History
    17-12-2020      Amit Shingavi     Initial Draft
    ----------------------------------------------------------------------------*/
    public void validatetheJobCardForms(List<Service_Form__c> newItems){
        Id jobCardRTId = Schema.SObjectType.Service_Form__c.getRecordTypeInfosByDeveloperName().get(GlobalConstants.SERVICE_FORM_JOB_CARD_RECORD_TYPE_DEV_NAME).getRecordTypeId();
        List<Service_Form__c> lstToValidte = new List<Service_Form__c>();
        List<String> uniqueStrings = new List<String>();
        Set<Id> nonUniqueIds = new Set<Id>();
        Set<Id> caseIds = new Set<Id>();

        for(Service_Form__c sfItr : newItems){
            if(sfItr.recordTypeId == jobCardRTId){
                uniqueStrings.add(String.valueOf(sfItr.Case__c).substring(0,15)+String.valueOf(Date.Today()));
            	lstToValidte.add(sfItr);
                caseIds.add(sfItr.Case__c);
            }
        }
	   
       //Identify the existing record in case the job card is already created for the same day
       Map<Id,Case> nonUniqueMap = new Map<Id, Case>([SELECT Id,(SELECT Id 
                                                                   FROM Service_Forms__r 
                                                                  WHERE Job_Card_Unique__c IN:uniqueStrings) 
                                                        FROM Case
                                                       WHERE Id IN:caseIds]);  
       
       for(Service_Form__c sfItr : lstToValidte){
          if(nonUniqueMap.get(sfItr.Case__c).Service_Forms__r.size() > 0){
             sfItr.addError(System.Label.Job_Card_Unique);
          }
       }
    }

    /*------------------------------------------------------------------------
    Author:        Mahith Madwesh
    Company:       Salesforce
    Description:   Method to populate EHM from Case on to the Job Card
    Inputs:        NA
    Test Class:    
    History
    29-12-2020      Mahith Madwesh     Initial Draft
    ----------------------------------------------------------------------------*/
    public void populateOldEHM(List<Service_Form__c> newItems){
        Id jobCardRTId = Schema.SObjectType.Service_Form__c.getRecordTypeInfosByDeveloperName().get(GlobalConstants.SERVICE_FORM_JOB_CARD_RECORD_TYPE_DEV_NAME).getRecordTypeId();
        Set<Id> caseIds = new set<Id>();
        for(Service_Form__c sf: newItems){
            if(sf.RecordTypeId == jobCardRTId){
                 caseIds.add(sf.Case__c);
            }
        }
        map<Id,Service_Form__c> serviceFormsMap = new map<Id,Service_Form__c>();

        list<Service_Form__c> serviceRequests = [SELECT Id,Equipment_Hour_Meter__c,Old_EHM__c,CreatedDate,Case__c FROM Service_Form__c WHERE 
                                                                Case__c IN:caseIds AND recordTypeId =:jobCardRTId ORDER BY CreatedDate DESC ];
        Map<Id,Case> serviceCaseMap = new map<Id,Case>([SELECT Id,AssetId,Asset.Asset_Hour_Meter__c,Asset.Base_Asset_Hour_Meter__c FROM Case Where Id IN: caseIds]);                                                        

         for(Service_Form__c sf1: serviceRequests){
             if(sf1.Equipment_Hour_Meter__c!=null){
             serviceFormsMap.put(sf1.Case__c,sf1);
             }
        }
        // && serviceFormsMap.get(Sf2.Case__c).Id!= sf2.Id 

        for(Service_Form__c sf2: newItems){
            if(sf2.recordTypeId == jobCardRTId){
               if(serviceFormsMap.keyset().contains(sf2.Case__c)){
                   sf2.Old_EHM__c = serviceFormsMap.get(sf2.Case__c).Equipment_Hour_Meter__c;
               }else if(serviceCaseMap.containsKey(sf2.Case__c) && serviceCaseMap.get(sf2.Case__c).AssetId!=null && serviceCaseMap.get(sf2.Case__c).Asset.Asset_Hour_Meter__c!=null){
                   sf2.Old_EHM__c =serviceCaseMap.get(sf2.Case__c).Asset.Asset_Hour_Meter__c - ( serviceCaseMap.get(sf2.Case__c).Asset.Base_Asset_Hour_Meter__c <> null ? serviceCaseMap.get(sf2.Case__c).Asset.Base_Asset_Hour_Meter__c : 0 );
               } 
                
            }
        }
    }

    /*------------------------------------------------------------------------
    Author:        Mahith Madwesh
    Company:       Salesforce
    Description:   Before Closing Service Request if there is any In-Progress
                    Job Cards. If there is then it cannot be closed
    Inputs:        Service Request Records

    History
    31-12-2020      Mahith Madwesh     Initial Release
    ----------------------------------------------------------------------------*/
    public void populateBranchChampion(list<Service_Form__c> newItems){
        set<Id> caseIds = new set<Id>();
        map<string,string> BranchChampionSalaryCodeAreaCodeMapping = new Map<String,String>();
        map<string,string> areaCodeAddressMapping = new Map<String,String>();
        map<string,string> areaCodeBranchChampionMap = new map<string,string>();
        Id jobCardRTId = Schema.SObjectType.Service_Form__c.getRecordTypeInfosByDeveloperName().get(GlobalConstants.SERVICE_FORM_JOB_CARD_RECORD_TYPE_DEV_NAME).getRecordTypeId();
        for(Service_Form__c sf: newItems){
            if(sf.Case__c!=null && sf.recordTypeId==jobCardRTId){
                caseIds.add(sf.Case__c);
            }
        }

        system.debug('Case Records>>>>'+caseIds);

        map<Id,Case> caseIdMap = new map<Id,Case>([SELECT Id, Asset.Area_code__c,Dealer_Supervisor__r.Email,Dealer_Supervisor__c, AssetId FROM Case WHERE Id IN :caseIds AND Asset.Area_code__c!=null AND AssetId!=null]);

         system.debug('caseIdMap>>>>'+caseIdMap);
        //Fetch Metadata Records for Internal Technician Details
        for(Area_Code_Branch_Champion__mdt mapping : [SELECT Branch_Champion_Queue_API_Name__c,Area_Code__c,BU_Division__c, Branch_Champion_salary_code__c, Address__c
                                                                    FROM Area_Code_Branch_Champion__mdt 
                                                                    WHERE BU_Division__c = :GlobalConstants.MHE_BU_DIVISION]){
            BranchChampionSalaryCodeAreaCodeMapping.put(mapping.Branch_Champion_salary_code__c,mapping.Area_Code__c);                                                            
            areaCodeAddressMapping.put(mapping.Area_Code__c, mapping.Address__c);
        }

        system.debug('Area_Code_Branch_Champion__mdt>>>>'+BranchChampionSalaryCodeAreaCodeMapping);

        for(User u : [SELECT Id, Salary_Code__c,Email, Area_Code__c FROM User 
                                                WHERE Salary_Code__c IN : BranchChampionSalaryCodeAreaCodeMapping.keySet()
                                                AND isActive = true]){
                    //   if(BranchChampionSalaryCodeAreaCodeMapping.containsKey(u.Salary_Code__c)){
                          areaCodeBranchChampionMap.put(BranchChampionSalaryCodeAreaCodeMapping.get(u.Salary_Code__c),u.Email);
                    //   }                              
            }

            system.debug('areaCodeBranchChampionMap>>>>'+areaCodeBranchChampionMap);

            for(Service_Form__c sf1:newItems){
                system.debug('inside first loop>>>>');
                  if(sf1.Case__c!=null && caseIdMap.containsKey(sf1.Case__c) && sf1.recordTypeId==jobCardRTId ){
                      case c = caseIdMap.get(sf1.Case__c);
                      if(c.Dealer_Supervisor__c!=null){
                            sf1.Dealer_Supervisor_Email__c = c.Dealer_Supervisor__r.Email; 
                      }
                      if(c.AssetId!=null && c.Asset.area_code__c!=null && areaCodeBranchChampionMap.containsKey(c.Asset.Area_Code__c) ){
                          system.debug('Branch Champion Mail>>>>'+areaCodeBranchChampionMap.get(c.Asset.Area_Code__c));
                        sf1.Branch_Champion_Email__c =areaCodeBranchChampionMap.get(c.Asset.Area_Code__c);
                        sf1.Area_Address__c = ((areaCodeAddressMapping.get(c.Asset.area_code__c) <> NULL) ? areaCodeAddressMapping.get(c.Asset.area_code__c) : NULL);
                	  }
                  }
                
            }
    }
    
    /*------------------------------------------------------------------------
    Author:        Nupoor Sharma
    Company:       Salesforce
    Description:   Method to validate a customer signature is addded before a job card is Submitted
    Inputs:        NA
    Test Class:    
    History
    08-02-2021      Nupoor Sharma     Initial Draft
    ----------------------------------------------------------------------------*/
    public void mandateSignatureToSubmit(List<Service_Form__c> newList, Map<Id, Service_Form__c> oldMap){
        Set<ID> formsToValidate = new Set<ID>();
        for(Service_Form__c newObj : newList){
            if(newObj.Status__c == GlobalConstants.SERVICE_FORM_STATUS_SUBMITTED
               && ((oldMap==NULL) || (oldMap.get(newObj.Id).Status__c <> GlobalConstants.SERVICE_FORM_STATUS_SUBMITTED)) ){
                   formsToValidate.add(newObj.ID);
               }
        }
        if(!formsToValidate.isEmpty()){
            Set<ID> formsWithSignatureSet = new Set<ID>();
            String signatureprefix = System.Label.Signature_Prefix + '%';
            List<ContentDocumentLink> cdlList = new List<ContentDocumentLink>([SELECT Id, LinkedEntityId
                                                                               FROM ContentDocumentLink 
                                                                               WHERE LinkedEntityId IN :formsToValidate 
                                                                               AND ContentDocument.Title LIKE :signatureprefix 
                                                                               AND ContentDocument.LatestPublishedVersion.Is_System_Generated_Signature__c = TRUE]);
            if(!cdlList.isEmpty()){
                for(ContentDocumentLink cdl : cdlList){
                    formsWithSignatureSet.add(cdl.LinkedEntityId);
                }
            }
            for(Service_Form__c newObj : newList){
                if(formsToValidate.contains(newObj.Id) && !formsWithSignatureSet.contains(newObj.Id)){
                	newObj.addError(System.Label.AddSignatureError);
                }
            }
        }
        
    }

}