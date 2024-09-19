/*------------------------------------------------------------------------
    Author:        Manasi Londhe 
    Company:       Salesforce
    Description:   Helper class for ServiceContractTrigger 
    Inputs:        NA
    Test Class:   
    ---------------------------------------------------------------------------
    History
    26-11-2020      Manasi Londhe     Initial Release
    09-11-2020      Kishor Kumar     Initial Release
----------------------------------------------------------------------------*/
public with sharing class ServiceContractTriggerHelper {

    public static Set<Id> duplicateFoundSCIds=new Set<Id>();
    public static Map<String,Id> serialNoVsAssetId=new Map<String,Id>();

    public void createClaimRequest(List<ServiceContract> serviceContracts,Map<Id,ServiceContract> oldItems){
        Set<String> mdtLabels=new Set<String>{GlobalConstants.CONTRACT_EXECUTION_MANAGER,
                                              'MHE Contract C Request Contract Approver',
                                               GlobalConstants.MARKETING_MANAGER_CONTRACTS};
        Map<String,String> labelVsValue=new Map<String,String>();
        Set<String> applicableContractTypes=new Set<String>{GlobalConstants.CMT_CONTRACT_TYPE,
                                                            GlobalConstants.CMP_CONTRACT_TYPE,
                                                            GlobalConstants.CMD_CONTRACT_TYPE,
                                                            GlobalConstants.CMG_CONTRACT_TYPE,
                                                            GlobalConstants.PMC_CONTRACT_TYPE,
                                                            GlobalConstants.EWP_CONTRACT_TYPE};
                                                                    
        List<ServiceContract> finalContracts=new List<ServiceContract>();
        List<ServiceContract> ewpContracts=new List<ServiceContract>();
        Set<Id> ewpServiceContractIds=new Set<Id>();
        List<Claim_Requests__c> claimRequestsToInsert=new List<Claim_Requests__c>();
        Id contractRecordTypeId=Schema.SObjectType.Claim_Requests__c.getRecordTypeInfosByDeveloperName().get(GlobalConstants.CLAIM_REQUEST_CONTRACTS).getRecordTypeId();
        List<Application_Settings__mdt> appSettings=[Select Label,Value__c From Application_Settings__mdt 
                                                     Where Label in :mdtLabels 
                                                     And value__c!=null];
        for(Application_Settings__mdt mdt:appSettings){
            labelVsValue.put(mdt.Label,mdt.Value__c);
        }
        for(ServiceContract sc:serviceContracts){
            if(sc.MHE_Division__c==GlobalConstants.MHE_DIVISION_CONTRACTS 
               && applicableContractTypes.contains(sc.Contract_Type__c) 
               && oldItems!=null 
               && sc.Approval_Status__c!=oldItems.get(sc.Id).Approval_Status__c 
               && sc.Approval_Status__c==GlobalConstants.APPROVED){
               //&& sc.Status__c==GlobalConstants.SERVICE_CONTRACT_ACTIVE_STATUS){
                finalContracts.add(sc);
                if(sc.Contract_Type__c==GlobalConstants.EWP_CONTRACT_TYPE){
                    ewpServiceContractIds.add(sc.Id);
                }
            }
        }
        List<Claim_Requests__c> ewpClaimsToInsert=new List<Claim_Requests__c>();
        List<Claim_Requests__c> ewpClaims=new List<Claim_Requests__c>();
        List<FeedItem> FeedItemList = New List<FeedItem>();
        Map<Id,ServiceContract> idVsSCRecord=ClaimRequestTriggerDefaultHelper.getServiceContractData(ewpServiceContractIds);
        for(ServiceContract sc:finalContracts){
            If(labelVsValue.containsKey(GlobalConstants.MARKETING_MANAGER_CONTRACTS)){
                Id marketingManagerContractsId=Id.valueOf(labelVsValue.get(GlobalConstants.MARKETING_MANAGER_CONTRACTS));
                if(sc.Contract_Type__c==GlobalConstants.EWP_CONTRACT_TYPE){
                    ewpClaims.add(new Claim_Requests__c(OwnerId=marketingManagerContractsId,recordTypeId=contractRecordTypeId,Service_Contract__c=sc.Id,Is_System_Generated__c=true,Marketing_Manager__c=marketingManagerContractsId));
                }
                else{
                    claimRequestsToInsert.add(new Claim_Requests__c(OwnerId=marketingManagerContractsId,recordTypeId=contractRecordTypeId,Service_Contract__c=sc.Id,Is_System_Generated__c=true,Marketing_Manager__c=marketingManagerContractsId));
                }
            }
        }
        Insert claimRequestsToInsert;
        checkForDuplicateWarrantyClaim(ewpClaims,idVsSCRecord);
        for(Claim_Requests__c ewpClaim:ewpClaims){
            Id assetId=serialNoVsAssetId.containsKey(ewpClaim.Equipment_Serial_No__c)?serialNoVsAssetId.get(ewpClaim.Equipment_Serial_No__c):null;
            if(!duplicateFoundSCIds.contains(ewpClaim.Service_Contract__c)){
                ewpClaimsToInsert.add(ewpClaim);
            }
            else if(assetId!=null){
                FeedItemList.addall(sendNotifications(labelVsValue,idVsSCRecord,ewpClaim,assetId));
            }
        }
        Insert ewpClaimsToInsert;
        Insert FeedItemList;
    }
    
    public List<FeedItem> sendNotifications(Map<String,String> labelVsValue,Map<Id,ServiceContract> idVsSCRecord,claim_Requests__c cr,Id assetId){
        List<String> notificationMessage=(System.Label.EWP_Notification_Message).split('--');
        List<FeedItem> FeedItemList = New List<FeedItem>(); 
        for(String label:labelVsValue.keySet()){
            FeedItem post = new FeedItem();
            post.ParentId = Id.valueOf(labelVsValue.get(label));
            post.Body = notificationMessage[0]+cr.Equipment_Serial_No__c+notificationMessage[1]+idVsSCRecord.get(cr.Service_Contract__c).Name+' ('+System.Url.getOrgDomainUrl() + '/' + cr.Service_Contract__c+').\n'+notificationMessage[2];
            post.LinkUrl = System.Url.getOrgDomainUrl() + '/' + assetId; 
            post.title='Asset Record';
            FeedItemList.add(post);
        }
        return FeedItemList;
    }
    
    public void checkForDuplicateWarrantyClaim(List<Claim_Requests__c> claimRequests,Map<Id,ServiceContract> idVsSCRecord){
         for(Claim_Requests__c cr:claimRequests){
            if(idVsSCRecord.containsKey(cr.Service_Contract__c)){
                ServiceContract scRec=idVsSCRecord.get(cr.Service_Contract__c);
                List<String> serialNos=new List<String>();
                for(ContractLineItem item:scRec.ContractLineItems){
                    if(item.Asset.Equipment_Serial_No__c!=null){
                           serialNos.add(item.Asset.Equipment_Serial_No__c);
                       }
                 }
                 if(serialNos.size()>0){
                 string serialNo=String.join(serialNos, ',');
                        if(serialNo.length()>155){
                            string subSerialNo = serialNo.subString(0,155);
                            cr.Equipment_Serial_No__c = subSerialNo.subString(0,subSerialNo.lastIndexOf(',')); 
                        }else {                                              
                            cr.Equipment_Serial_No__c=String.join(serialNos, ',');
                        }
               
                   }  
             }
        }
        ClaimRequestTriggerDefaultHelper.checkDuplicateWarrantyClaimForEWPContracts(claimRequests,idVsSCRecord);
    }
    
    

    
    /*------------------------------------------------------------------------
    Author:        Kishor Kumar
    Company:       Salesforce
    Description:   Methos to deactivate all the associated asset Benefit records
                    once Service Contract becomes inactive
    Inputs:        NA
    Test Class:    ServiceContractTriggerHelperTest
    History
    09-11-2020      Kishor Kumar     Initial Release
    ----------------------------------------------------------------------------*/
    public void deactivateAllAssetBenefitsForInactiveServiceContract(map<Id,ServiceContract> newServiceContracts, map<Id,ServiceContract> oldServiceContracts){
        set<Id> inactiveServiceContractIds = new set<Id>();
        list<Asset_Benefit__c> inactiveAssetBenefits = new list<Asset_Benefit__c>();
        
        //Fetch the Inactive values from Metadata record
        String inactiveValue = [SELECT Id, Value__c 
                                    FROM Application_Settings__mdt 
                                    WHERE DeveloperName = 'MHE_Service_Contract_Inactive_Values' LIMIT 1].Value__c;
            
        list<String> inactiveValues = inactiveValue.split(',');            
        
        //Get all the Inactive Service Contract Ids
        for(Id scId : newServiceContracts.keySet()){
           if(oldServiceContracts.containsKey(scId) 
              && oldServiceContracts.get(scId).Status__c == GlobalConstants.SERVICE_CONTRACT_ACTIVE_STATUS 
              && inactiveValues.contains(newServiceContracts.get(scId).Status__c)){
                inactiveServiceContractIds.add(scId);
            }
        }
        
        //update all the associated active Asset Benefit records to Inactive
        if(inactiveServiceContractIds.size() > 0){
            for(Asset_Benefit__c assetBenefit : [SELECT Id, Is_Active__c 
                                                    FROM Asset_Benefit__c 
                                                    WHERE Contract_Line_Item__r.ServiceContractId IN: inactiveServiceContractIds 
                                                    AND Is_Active__c = true]){
                                                        
               assetBenefit.Is_Active__c = false;                                        
               inactiveAssetBenefits.add(assetBenefit); 
            }
        }
    
        try{
            if(inactiveAssetBenefits.size() > 0)
                update inactiveAssetBenefits;
        } catch(Exception ex){
            Logger.logError('ServiceContractTriggerHelper', 'deactivateAllAssetBenefitsForInactiveServiceContract', '', ex);
        }
    }
    
    /*------------------------------------------------------------------------
    Author:        Amit Shingavi
    Company:       Salesforce
    Description:   Method to Populate Contract Renewal Duration and Unit 
    Inputs:        map of updated records
    Test Class:   

    History
    11-01-2020      Amit Shingavi    Initial Draft
    ----------------------------------------------------------------------------*/
    public void populateTheContractRenewals(map<Id,ServiceContract> newServiceContracts, map<Id,ServiceContract> oldServiceContracts){
        for(ServiceContract src : newServiceContracts.values()){
            src.Contract_Renewal_Period__c = src.Duration__c;
            src.Contract_Renewal_Period_Unit__c = src.Duration_Unit__c;
        }        
    }
    
    /*------------------------------------------------------------------------
    Author:        Amit Shingavi
    Company:       Salesforce
    Description:   Populate Integration status and Unique key on the lines
    Inputs:        map of updated records
    Test Class:   

    History
    11-01-2020      Amit Shingavi    Initial Draft
    ----------------------------------------------------------------------------*/
    public void populateIntegrationStatusOnLines(map<Id,ServiceContract> newServiceContracts, map<Id,ServiceContract> oldServiceContracts){
        Set<Id> contractIds = new Set<Id>();
        List<ContractLineItem> cliItemstoUpdate = new List<ContractLineItem>();
        for(ServiceContract src : newServiceContracts.values()){
            if(src.Integration_Status__c == 'Synced' && 
               src.Integration_Status__c != oldServiceContracts.get(src.Id).Integration_Status__c){
                    contractIds.add(src.Id);
            }
        }
        
        for(ContractLineItem cliItr : [SELECT Id,
                                              ServiceContract.Branch__c,
                                              ServiceContract.Infor_Service_Contract_ID__c,
                                              Configuration_Line_Number__c, 
                                              Contract_Change_Number__c,
                                              Unique_Service_Contract_Line_Key__c
                                         FROM ContractLineItem 
                                        WHERE ServiceContractId IN:contractIds]){
            String uniqueKey = cliItr.ServiceContract.Branch__c +'_' + 
                               cliItr.ServiceContract.Infor_Service_Contract_ID__c + '_' + 
                               cliItr.Contract_Change_Number__c  + '_' +
                               cliItr.Configuration_Line_Number__c;
                                            
            cliItemstoUpdate.add(
                new ContractLineItem(Id = cliItr.Id, 
                                     Integration_Status__c = 'Synced', 
                                     Unique_Service_Contract_Line_Key__c = String.isBlank(cliItr.Unique_Service_Contract_Line_Key__c) ? 
                                                                           uniqueKey : cliItr.Unique_Service_Contract_Line_Key__c)
            );
        }   
        
        try{
            update cliItemstoUpdate;
       } catch(Exception ex){
            Logger.logError('ServiceContractTriggerHelper', 'populateIntegrationStatusOnLines', '', ex);
       }
           
        
    }
    
    /*------------------------------------------------------------------------
    Author:        Amit Shingavi
    Company:       Salesforce
    Description:   Update the service contract owner to the sales rep user
    Inputs:        map of updated records
    Test Class:   

    History
    19-01-2020      Amit Shingavi    Initial Draft
    ----------------------------------------------------------------------------*/
    public void populateIntegrationDefaults(Map<Id,ServiceContract> newServiceContracts){
        List<ServiceContract> serContractLst = new List<ServiceContract>();
        List<Pricebook2> contractPricebook = [SELECT Id 
                                                FROM Pricebook2 
                                               WHERE Name =: System.Label.MHE_SF_Local_Contract_PB];
        for(ServiceContract scItr : [SELECT Id, Sales_Rep_Code__c,OwnerId 
                                       FROM ServiceContract 
                                      WHERE Id IN: newServiceContracts.keySet() AND  
                                            CreatedBy.Profile.Name =: System.Label.Integration_User_Profile_Name
                                            ]){
            serContractLst.add(new ServiceContract(Id = scItr.id, 
                                                 ownerid = String.isNotBlank(scItr.Sales_Rep_Code__c) ? scItr.Sales_Rep_Code__c : scItr.OwnerId,
                                                 pricebook2Id = !contractPricebook.isEmpty() ? contractPricebook[0].Id : null));
        }
        try{
            update serContractLst; 
        }catch(Exception ex){
            Logger.logError('ServiceContractTriggerHelper', 'assignServiceContractToSalesRep', '', ex);
        }
               
    }
    
     /*------------------------------------------------------------------------
    Author:        Amit Shingavi
    Company:       Salesforce
    Description:   Update the service contract owner to the sales rep user
    Inputs:        map of updated records
    Test Class:   

    History
    19-01-2020      Amit Shingavi    Initial Draft
    ----------------------------------------------------------------------------*/
    public void populateDefaultsOnLines(map<Id,ServiceContract> newServiceContracts, map<Id,ServiceContract> oldServiceContracts){
        
        List<ContractLineItem> cliItemstoUpdate = new List<ContractLineItem>();
        Set<Id> contractIds = new Set<Id>();
        Set<Id> contractChangeDurationIds = new Set<Id>();
        
        for(ServiceContract src : newServiceContracts.values()){
            
            ServiceContract oldScr = oldServiceContracts.get(src.Id);
            
            if(src.Contract_Template__c != oldScr.Contract_Template__c ){
                contractIds.add(src.Id);
            }
            //Added here by Praful - 22-Feb-2021
            if( src.Duration_Unit__c != oldScr.Duration_Unit__c || src.Duration__c != oldScr.Duration__c || src.startDate != oldScr.startDate ){
                contractChangeDurationIds.add(src.Id);
            }
        }
        
        if(contractIds.size() > 0 || contractChangeDurationIds.size() > 0){
            for(ContractLineItem cliItr : [SELECT Id, ServiceContractId,
                                                  ServiceContract.Contract_Template__c,
                                                  ServiceContract.Duration_Unit__c,
                                                  ServiceContract.Duration__c,
                                                  ServiceContract.startDate,
                                                  ServiceContract.EndDate
                                             FROM ContractLineItem 
                                            WHERE ServiceContractId IN:contractIds OR ServiceContractId IN:contractChangeDurationIds ]){
               
                ContractLineItem cli = new ContractLineItem(Id = cliItr.Id);
                
                if(contractIds.contains(cliItr.ServiceContractId))
                    cli.Contract_Template__c = cliItr.ServiceContract.Contract_Template__c;
                
                //Added here by Praful - 22-Feb-2021
                if(contractChangeDurationIds.contains(cliItr.ServiceContractId)){
                    cli.Duration_Unit__c = cliItr.ServiceContract.Duration_Unit__c;
                    cli.Duration__c = (cliItr.ServiceContract.Duration__c!=null ? decimal.valueOf(cliItr.ServiceContract.Duration__c) : null );
                    cli.startDate = cliItr.ServiceContract.startDate;
                    cli.EndDate = cliItr.ServiceContract.EndDate;
                    system.debug('>>>> contractChange fields called >>>>');
                }
                cliItemstoUpdate.add(cli);
            }   
        }
        try{
            update cliItemstoUpdate;
       } catch(Exception ex){
            Logger.logError('ServiceContractTriggerHelper', 'populateDefaultsOnLines', '', ex);
       }
    }
    
    //Added by Praful - 22-Feb-2021
    public void populateContractDuration(map<Id,ServiceContract> newServiceContracts, map<Id,ServiceContract> oldServiceContracts){
        
        for(ServiceContract newSCRec : newServiceContracts.values())
        {
            ServiceContract oldSCRec = oldServiceContracts.get(newSCRec.Id);
            
            if( newSCRec.Duration_Unit__c != null && newSCRec.Duration__c != null && newSCRec.startDate != null 
                && ( newSCRec.Duration_Unit__c != oldSCRec.Duration__c || newSCRec.Duration__c != oldSCRec.Duration__c || newSCRec.startDate != oldSCRec.startDate )
                ){
                newSCRec.EndDate = getEndDateBasedOnDuration(newSCRec.startDate, decimal.valueOf(newSCRec.Duration__c), newSCRec.Duration_Unit__c);
            }
        }    
        
    }
    
    //Added by Praful - 22-Feb-2021
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
    Author:        Karthik Daroji
    Company:       PWC
    Description:   Method to auto select the next approver based on the Service Request approval process metadata
    Inputs:        NA
    Test Class:    ServiceContractTriggerHelperTest
    History
    22-05-2024      Karthik Daroji     Initial Release
    ----------------------------------------------------------------------------*/
    
    public void ServiceContractNextApproverSelector(map<Id,ServiceContract> newServiceContracts, map<Id,ServiceContract> oldServiceContracts){
        
        system.debug('ServiceContractNextApproverSelector called --------- ');
        List<ServiceContract> SerConSubmittedForApprovalList = new List<ServiceContract>();
        
        for(ServiceContract serConRec : newServiceContracts.values()) {
            if(serConRec.ApprovalStatus != oldServiceContracts.get(serConRec.Id).ApprovalStatus){
                switch on serConRec.ApprovalStatus {
                    when 'Submitted for Approval' {
                        ProcessInstanceWorkitem piwi = [SELECT Id, ActorId, ProcessInstance.TargetObjectId FROM ProcessInstanceWorkitem WHERE ProcessInstance.TargetObjectId = :serConRec.Id];
                        system.debug('piwi --------- ' + piwi);
                        piwi.ActorId = '005C4000002SA9pIAG';
                        update piwi;
                    }
                    when 'Level 1 Approved' {
                        
                    }
                    when 'Level 2 Approved' {
                        
                    }
                    when 'Level 3 Approved' {
                        
                    }
                    when 'Level 4 Approved' {
                        
                    }
                }
            }
        }
        
        
    }
    
    
    
    
}