public with sharing class ClaimRequestTriggerApproverHelper {
    public static final Id WARRANTY_TYPE_RECORDTYPE_ID = Schema.SObjectType.Claim_Requests__c.getRecordTypeInfosByDeveloperName().get(GlobalConstants.CLAIM_REQUEST_WARRANTY).getRecordTypeId();
    public static final Id ADHOC_CLAIM_REQUEST_RECORDTYPE_ID = Schema.SObjectType.Claim_Requests__c.getRecordTypeInfosByDeveloperName().get(GlobalConstants.CLAIM_REQUEST_RECORDTYPE_ADHOC).getRecordTypeId();
    public static final Id INVOICE_SUBMISSION_REQUEST_RECORDTYPE_ID = Schema.SObjectType.Claim_Requests__c.getRecordTypeInfosByDeveloperName().get(GlobalConstants.CLAIM_REQUEST_INVOICE_SUBMISSION_REQUEST).getRecordTypeId();
    public static final Id CONTRACT_RECORDTYPE_ID = Schema.SObjectType.Claim_Requests__c.getRecordTypeInfosByDeveloperName().get(GlobalConstants.CLAIM_REQUEST_CONTRACTS).getRecordTypeId();
    public static final Id CREDIT_NOTE_RECORDTYPE_ID = Schema.SObjectType.Claim_Requests__c.getRecordTypeInfosByDeveloperName().get(GlobalConstants.CLAIM_REQUEST_RECORDTYPE_CREDIT_NOTE).getRecordTypeId();
    public static final Id SCC_RECORDTYPE_ID = Schema.SObjectType.Claim_Requests__c.getRecordTypeInfosByDeveloperName().get(GlobalConstants.CLAIM_REQUEST_RECORDTYPE_SCC).getRecordTypeId();
    public static final Id CLAIM_REQUEST_RECORDTYPE_ID = Schema.SObjectType.Claim_Requests__c.getRecordTypeInfosByDeveloperName().get(GlobalConstants.CLAIM_REQUEST_RECORDTYPE_CLAIM_REQUEST).getRecordTypeId();
    public static final String RECORD_TYPE_CUSTOM_FIELD_VALUE_CREDIT_NOTE = 'Credit Note';
    public static final String STOCK_AND_SELL_CATEGORY_A = 'Stock & Sell - Category A';

    /*--------------------------------------------------------------------------
    Author:        Shailja Mishra 
    Company:       Salesforce
    Description:   Populate approvers for SCC and Credit Notes on Claim requests
                   User Story => W-000364, W-000370 Sprint 3
    Inputs:        list of new claimRequests
    ---------------------------------------------------------------------------
    History
    09-12-2020      Shailja Mishra     Initial Release
    --------------------------------------------------------------------------*/
    public void populateApproversForCreditNoteAndSCCClaims(List<Claim_Requests__c> claimRequests){
        //
        List<Id> ownerIds = new List<Id>();
        List<Id> orderIds = new List<Id>();
        List<Id> claimRequestIds = new List<Id>();
        Set<String> areaCodes = new Set<String>();
        Map<Id, User> idVsUser = new Map<Id, User>();
        Map<Id, Claim_Requests__c> idVsClaimRequest = new Map<Id, Claim_Requests__c>();
        Map<Id, Order> idVsOrder = new Map<Id, Order>();
        Map<String, String> mheDivisionVsLOBHead = new Map<String, String>();
        Map<String, String> mheDivisionVsCheckerId = new Map<String, String>();
        //
        for(Claim_Requests__c cr : claimRequests){
            ownerIds.add(cr.OwnerId);
            /*if(cr.Area_Code__c != null){
                areaCodes.add(cr.Area_Code__c);
            }*/
            // Adding this extra logic to use common quick action
            if (cr.RecordTypeId == SCC_RECORDTYPE_ID && cr.Request_Type__c == STOCK_AND_SELL_CATEGORY_A) {
                cr.RecordTypeId = CREDIT_NOTE_RECORDTYPE_ID;
                cr.Record_Type__c = RECORD_TYPE_CUSTOM_FIELD_VALUE_CREDIT_NOTE;
            }
            if((cr.RecordTypeId == CREDIT_NOTE_RECORDTYPE_ID || cr.RecordTypeId == SCC_RECORDTYPE_ID) && cr.Claim_Request__c != null){
                claimRequestIds.add(cr.Claim_Request__c);
                areaCodes.add(cr.Area_Code__c);
            }
        }
        
        if(claimRequestIds.size() > 0){
            List<Area_Code_Branch_Champion__mdt> areaMappings = [Select Id, Area_Code__c, Branch_Champion_salary_code__c, Branch_head_Salary_code__c From Area_Code_Branch_Champion__mdt Where Area_Code__c IN: areaCodes and BU_Division__c='MHE'];
            Map<String, String> areaCodeVsalaryCodes = new Map<String, String>();
            Set<String> salaryCodes = new Set<String>();
            for(Area_Code_Branch_Champion__mdt mdt : areaMappings){
                areaCodeVsalaryCodes.put(mdt.Area_Code__c, mdt.Branch_head_Salary_code__c);
                salaryCodes.add(mdt.Branch_head_Salary_code__c);
            }
            
            Map<String, User> salaryCodeVsUser = new Map<String, User>();
            List<User> userFromSalaryCode = [Select Id, Area_Code__c, Salary_Code__c From User Where Salary_Code__c IN: salaryCodes];
            for(User ur : userFromSalaryCode){
                salaryCodeVsUser.put(ur.Salary_Code__c, ur);
            }
            
            idVsUser = getUsers(ownerIds);
            mheDivisionVsLOBHead = getMHEDivisionVsLOBHead(GlobalConstants.MHE_Division_Vs_MetadataLOB);
            mheDivisionVsCheckerId = getMHEDivisionVsLOBHead(GlobalConstants.MHE_Division_Vs_MetadataChecker);
            for(Claim_Requests__c request : claimRequests){
                if(!idVsUser.isEmpty() && idVsUser.containsKey(request.OwnerId)){
                    request.Level_1__c = idVsUser.get(request.OwnerId).ManagerId;
                }
                string area= request.Area_Code__c;
                if(String.isNotBlank(area)) {
                    if(areaCodeVsalaryCodes.containsKey(area)) {
                        if(salaryCodeVsUser.containsKey(areaCodeVsalaryCodes.get(area))) {
                            request.Level_2__c = salaryCodeVsUser.get(areaCodeVsalaryCodes.get(area)).Id;
                        } else {
                         request.addError('No user found for Salary code: '+areaCodeVsalaryCodes.get(area));   
                        }
                    } else {
                        request.addError('No Branch head Salary code found for area: '+area);   
                    }
                    
                }
                string mheDivision = request.MHE_Division__c;   
                request.Level_4__c = mheDivisionVsLOBHead.get(mheDivision); 
                request.Level_3__c = mheDivisionVsCheckerId.get(mheDivision);
            }
        }
    }

    /*------------------------------------------------------------------------
    Author:        Abhishek Chaturvedi
    Company:       Salesforce
    Description:   
                   User Story => W-000362 Sprint 3
    Inputs:        list of inserted records
    Test Class:   
    ---------------------------------------------------------------------------
    History
    08-12-2020      Abhishek Chaturvedi      Initial Release
    -----------------------------------------------------------------------*/

    public void populateApproversOnClaimRequestRecords(List<Claim_Requests__c> newItems) {
        Map<String,String> MHEDivisionVsMetadataMapping = new Map<String,String>{
            'Outright Equipment' => 'WriteOff_Receivable_LOB_Equipments',
            'Spare Parts' => 'WriteOff_Receivable_LOB_Parts_Contracts',
            'Contracts' => 'WriteOff_Receivable_LOB_Parts_Contracts',
            'Equipment Rental' => 'WriteOff_Receivable_LOB_Rentals',
            'Godrej RenTRUST' => 'WriteOff_Receivable_LOB_Rentals',
            'Outright Sales' =>'WriteOff_Receivable_LOB_Equipments'

        };
        Id claimRecordTypeId = CLAIM_REQUEST_RECORDTYPE_ID;
        Set<Id> orderRecordsToQuery = new Set<Id>();
        Map<Id,List<Claim_Requests__c>> orderVsScc = new Map<Id,List<Claim_Requests__c>>();
        //For Annexure A : Order and Order Product are populated along with Godrej sales Order and godrej order product
        //For annexure B : Only Godrej Sales order and godrej Order product are populated
        for(Claim_Requests__c newItem : newItems) {
            if(newItem.recordTypeId == claimRecordTypeId) {
                if(newItem.Order__c != NULL && newItem.Order_Product__c != NULL) {
                    orderRecordsToQuery.add(newItem.Order__c);
                    if(orderVsScc.containsKey(newItem.Order__c)) {
                        orderVsScc.get(newItem.Order__c).add(newItem);
                    } else {
                        orderVsScc.put(newItem.Order__c,new List<Claim_Requests__c>{newItem});
                    }
                } else if(newItem.Godrej_Sales_Order__c != NULL){
                    orderRecordsToQuery.add(newItem.Godrej_Sales_Order__c);
                    if(orderVsScc.containsKey(newItem.Godrej_Sales_Order__c)) {
                        orderVsScc.get(newItem.Godrej_Sales_Order__c).add(newItem);
                    } else {
                        orderVsScc.put(newItem.Godrej_Sales_Order__c,new List<Claim_Requests__c>{newItem});
                    }
                }
            }
        }

        if(orderRecordsToQuery.size() > 0) {
            List<Order> orderRecords = [SELECT Id,MHE_Division__c,Area__c,OwnerId FROM Order WHERE Id IN :orderRecordsToQuery];
            Set<String> areasInOrders = new Set<String>();
            Map<Id,String> orderVsArea = new Map<Id,String>();
            Map<String,List<Order>> divisionVsOrder = new Map<string,List<Order>>();  
            for(Order orderRecord : orderRecords) {
                areasInOrders.add(orderRecord.Area__c);
                orderVsArea.put(orderRecord.Id,orderRecord.Area__c);
                if(orderRecord.MHE_Division__c != NULL) {
                    string divisionLobHeadKey = MHEDivisionVsMetadataMapping.get(orderRecord.MHE_Division__c);
                    if(divisionVsOrder.containsKey(divisionLobHeadKey)) {
                        divisionVsOrder.get(divisionLobHeadKey).add(orderRecord);
                    } else {
                        divisionVsOrder.put(divisionLobHeadKey,new List<Order>{orderRecord});
                    }
                } else {
                    orderRecord.addError(System.Label.ClaimRequestMHEDivisionNotPopulated);
                }
            }

            Map<String,String> areaCodeVsRegionalManagerSalaryCode = new Map<String,String>();
            Map<String,String> areaCodeVsBranchHeadSalaryCode = new Map<String,String>();
            Map<String,String> salaryCodeVsUserId = new Map<String,String>();
            for(Area_Code_Branch_Champion__mdt  championMdt:[Select Area_Code__c,Branch_head_Salary_code__c,Regional_Manager_Salary_Code__c From Area_Code_Branch_Champion__mdt
                                                                    Where Area_Code__c in :areasInOrders and BU_Division__c='MHE']){
                                                                        areaCodeVsRegionalManagerSalaryCode.put(championMdt.Area_Code__c,championMdt.Regional_Manager_Salary_Code__c);
                                                                        areaCodeVsBranchHeadSalaryCode.put(championMdt.Area_Code__c,championMdt.Branch_head_Salary_code__c);
            }
            Set<String> salaryCodesToQuery = new Set<String>(areaCodeVsRegionalManagerSalaryCode.values());
            salaryCodesToQuery.addAll(areaCodeVsBranchHeadSalaryCode.values());
            for(User u:[Select Id,Salary_Code__c From User Where Salary_Code__c in :salaryCodesToQuery]){
                salaryCodeVsUserId.put(u.Salary_Code__c,u.Id);
            }

            List<Application_Settings__mdt> lobHeads = [SELECT Id, DeveloperName, Value__c, Description__c 
                                                    FROM Application_Settings__mdt 
                                                    WHERE DeveloperName IN :divisionVsOrder.keySet()];
            
            Set<Id> userIdsToQuery = new Set<Id>();
            for(Application_Settings__mdt lobHead : lobHeads) {
                userIdsToQuery.add(lobHead.value__c);
            }
            Map<Id,Id> userIdVsManagerId = new Map<Id,Id>();
            for(User userRecord : [SELECT Id,ManagerId FROM User WHERE Id IN :userIdsToQuery]) {
                userIdVsManagerId.put(userRecord.Id,userRecord.ManagerId);
            }
            for(Application_Settings__mdt lobHead : lobHeads) {
                for(Order order : divisionVsOrder.get(lobHead.DeveloperName)) {
                    for(Claim_Requests__c request : orderVsScc.get(order.Id)) {
                        if(request.Order__c != NULL && request.Order_Product__c != NULL) {
                            request.Level_2__c = lobHead.Value__c;
                            request.Level_3__c = userIdVsManagerId.get(lobHead.Value__c);
                        } else if(request.Order__c == NULL && request.Order_Product__c == NULL) {
                            request.Level_1__c = order.OwnerId;
                            request.Level_4__c = lobHead.Value__c;
                            request.Level_5__c = userIdVsManagerId.get(lobHead.Value__c);
                        }
                    }
                }
            }
            //Order and Order product != NULL => Annexure A otherwise Annexure B 
            for(Claim_Requests__c newItem : newItems) {
                if(newItem.recordTypeId == claimRecordTypeId) {
                    if(newItem.Order__c != NULL && orderVsArea.containsKey(newItem.Order__c)) {
                        String orderArea = orderVsArea.get(newItem.Order__c);
                        if(orderArea != NULL && areaCodeVsRegionalManagerSalaryCode.containsKey(orderArea)) {
                            string salaryCode = areaCodeVsRegionalManagerSalaryCode.get(orderArea);
                            if(salaryCode != NULL && salaryCodeVsUserId.containsKey(salaryCode)) {
                                string userId = salaryCodeVsUserId.get(salaryCode);
                                if(userId != NULL) {
                                    if(newItem.Order__c != NULL && newItem.Order_Product__c != NULL) {
                                        newItem.Level_1__c = userId;
                                    }
                                } else {
                                    newItem.addError(System.Label.ClaimRequestLevel1UserNotFoundError);
                                }
                            } else {
                                newItem.addError(System.Label.ClaimRequestUserNotFoundForSalaryCode);
                            }
                        } else {
                            newItem.addError(System.Label.ClaimRequestCheckOrderAreaAndSal);
                        }
                    } else if(newItem.Godrej_Sales_Order__c != NULL && orderVsArea.containsKey(newItem.Godrej_Sales_Order__c)) {
                        String orderArea = orderVsArea.get(newItem.Godrej_Sales_Order__c);
                        if(orderArea != NULL && areaCodeVsRegionalManagerSalaryCode.containsKey(orderArea)) {
                            string salaryCode = areaCodeVsRegionalManagerSalaryCode.get(orderArea);
                            if(salaryCode != NULL && salaryCodeVsUserId.containsKey(salaryCode)) {
                                string userId = salaryCodeVsUserId.get(salaryCode);
                                if(userId != NULL) {
                                    if(newItem.Order__c == NULL && newItem.Order_Product__c == NULL) {
                                        newItem.Level_3__c = userId;
                                    }
                                } else {
                                    newItem.addError(System.Label.ClaimRequestLevel1UserNotFoundError);
                                }
                            } else {
                                newItem.addError(System.Label.ClaimRequestUserNotFoundForSalaryCode);
                            }
                        }
                        //Level 2 - Annexure B type claims
                        if(newItem.Order__c == NULL && newItem.Order_Product__c == NULL) {
                            if(orderArea != NULL && areaCodeVsBranchHeadSalaryCode.containsKey(orderArea)) {
                                string salaryCode = areaCodeVsBranchHeadSalaryCode.get(orderArea);
                                if(salaryCode != NULL && salaryCodeVsUserId.containsKey(salaryCode)) {
                                    string userId = salaryCodeVsUserId.get(salaryCode);
                                    if(userId != NULL) {
                                        newItem.Level_2__c = userId;
                                    } else {
                                        newItem.addError(System.Label.ClaimRequestLevel2UserNotFoundError);
                                    }
                                } else {
                                    newItem.addError(System.Label.ClaimRequestUserNotFoundForSalaryCode);
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    /*------------------------------------------------------------------------
    Author:        Manasi Londhe 
    Company:       Salesforce
    Description:   This method will populate Service contract and level1,level2,level3 approvers on invoice submission request
                   User Story => W-000283 Sprint 3
    Inputs:        list of new records  
    ---------------------------------------------------------------------------
    History
    20-11-2020      Manasi Londhe     Initial Release
    -----------------------------------------------------------------------*/
    
    public void populateISRApprovers(List<Claim_Requests__c> claimRequests){
        Id InvoiceSubmissionRecordTypeId=INVOICE_SUBMISSION_REQUEST_RECORDTYPE_ID;
        Id contractRecordTypeId=CONTRACT_RECORDTYPE_ID;
        Set<String> mdtNames=new Set<String>{GlobalConstants.CONTRACT_EXECUTION_MANAGER,GlobalConstants.MHE_CSG_HEAD,GlobalConstants.LEVEL_2_ISR_APPROVER_WARRANTY_CONTRACTS};
        Map<String,Id> approverVsUserId=new Map<String,Id>();
        Map<Id,String> claimRequestsVsAreaCode=new Map<Id,String>();
        Map<String,String> areaCodeVsSalaryCode=new Map<String,String>();
        Map<String,String> areaCodeVsBranchHeadSalaryCode=new Map<String,String>();
        Map<String,Id> salaryCodeVsUserId=new Map<String,Id>();
        Set<Id> claimRequestIds=new Set<Id>();
        Map<String,String> areacodeVsFinanceEmail=new Map<String,String>();
        Map<Id,Claim_Requests__c> idVsClaim=new Map<Id,Claim_Requests__c>(); 
        List<Id> ownerIds = new List<Id>();
        Map<Id, User> idVsUser = new Map<Id, User>();        
        
        for(Claim_Requests__c request:claimRequests){
            if(request.RecordTypeId==InvoiceSubmissionRecordTypeId){
                System.debug(request.RecordTypeId+'****'+InvoiceSubmissionRecordTypeId);
              claimRequestIds.add(request.Claim_Request__c);
            }
        }
        
        idVsClaim=new Map<Id,Claim_Requests__c>([Select Id,RecordTypeId,Service_Contract__c,Area_Code__c From Claim_Requests__c Where Id in :claimRequestIds]);
        System.debug(idVsClaim);
        System.debug(claimRequests);
        for(Claim_Requests__c cr:idVsClaim.values()){
            if(cr.Area_Code__c!=null && (cr.RecordTypeId==contractRecordTypeId || cr.RecordTypeId==WARRANTY_TYPE_RECORDTYPE_ID || cr.RecordTypeId==ADHOC_CLAIM_REQUEST_RECORDTYPE_ID)){
                claimRequestsVsAreaCode.put(cr.Id,cr.Area_Code__c);
            }
        }
        for(Area_Code_Branch_Champion__mdt  championMdt:[Select Area_Code__c,Branch_Champion_salary_code__c,Branch_head_Salary_code__c,Finance_User_Email__c,Sales_SPOC__c From Area_Code_Branch_Champion__mdt
                                                                    Where Area_Code__c in :claimRequestsVsAreaCode.values() and BU_Division__c='MHE']){
           //Added by pankaj on 28-06-2021 for Ticket#30389402 — CHANGE REQUIRED IN DEALER INVOICE APPROVAL FLOW                                                             
          for(Claim_Requests__c claimReq:idVsClaim.values()){
              if(claimReq.RecordTypeId!=WARRANTY_TYPE_RECORDTYPE_ID){
                   areaCodeVsSalaryCode.put(championMdt.Area_Code__c,championMdt.Sales_SPOC__c);
                     areaCodeVsBranchHeadSalaryCode.put(championMdt.Area_Code__c,championMdt.Branch_head_Salary_code__c);
                     areacodeVsFinanceEmail.put(championMdt.Area_Code__c,championMdt.Finance_User_Email__c);                                                                
                }
                else{
                   areaCodeVsSalaryCode.put(championMdt.Area_Code__c,championMdt.Branch_Champion_salary_code__c);
                     areaCodeVsBranchHeadSalaryCode.put(championMdt.Area_Code__c,championMdt.Branch_head_Salary_code__c);
                     areacodeVsFinanceEmail.put(championMdt.Area_Code__c,championMdt.Finance_User_Email__c);                      
                }
            }                                                               
        }
        Set<String> salarycodes=new Set<String>();
        salarycodes.addAll(areaCodeVsSalaryCode.values());
        salarycodes.addAll(areaCodeVsBranchHeadSalaryCode.values());
        for(User u:[Select Id,Salary_Code__c From User Where Salary_Code__c in :salarycodes]){
            salaryCodeVsUserId.put(u.Salary_Code__c,u.Id);
            system.debug('salaryCodeVsUserId---->'+salaryCodeVsUserId);
        }
        for(Application_Settings__mdt applicationSetting:[Select Label,Value__c From Application_Settings__mdt
                                                            Where Label in :mdtNames and value__c!=null]){
                                                                approverVsUserId.put(applicationSetting.Label,applicationSetting.Value__c);
        }

        for(Claim_Requests__c request:claimRequests){
            if(request.RecordTypeId==InvoiceSubmissionRecordTypeId){
                   
                Claim_Requests__c associatedClaim=idVsClaim.get(request.Claim_Request__c);
                if(claimRequestsVsAreaCode.containsKey(request.Claim_Request__c)){
                
                    if(areaCodeVsSalaryCode.containsKey(claimRequestsVsAreaCode.get(request.Claim_Request__c))
                       && salaryCodeVsUserId.containsKey(areaCodeVsSalaryCode.get(claimRequestsVsAreaCode.get(request.Claim_Request__c)))){  
                        request.Level_1__c=salaryCodeVsUserId.get(areaCodeVsSalaryCode.get(claimRequestsVsAreaCode.get(request.Claim_Request__c)));
                    }
                    If (associatedClaim.RecordTypeId==CONTRACT_RECORDTYPE_ID){               
                        ownerIds.add(request.OwnerId);
                        idVsUser = getServiceManager(ownerIds);           
                        if(!idVsUser.isEmpty() && idVsUser.containsKey(request.OwnerId)){
                          request.Level_1__c = idVsUser.get(request.OwnerId).Service_Manager__c;
                        }   
                       }                     
                   
                    if(associatedClaim.RecordTypeId==ADHOC_CLAIM_REQUEST_RECORDTYPE_ID){
                        if(areaCodeVsBranchHeadSalaryCode.containsKey(claimRequestsVsAreaCode.get(request.Claim_Request__c))
                          && salaryCodeVsUserId.containsKey(areaCodeVsBranchHeadSalaryCode.get(claimRequestsVsAreaCode.get(request.Claim_Request__c)))){
                            request.Level_2__c=salaryCodeVsUserId.get(areaCodeVsBranchHeadSalaryCode.get(claimRequestsVsAreaCode.get(request.Claim_Request__c))); 
                        }
                        if(areacodeVsFinanceEmail.containsKey(claimRequestsVsAreaCode.get(request.Claim_Request__c))){
                            request.Finance_Email__c=areacodeVsFinanceEmail.get(claimRequestsVsAreaCode.get(request.Claim_Request__c));
                        }
                       
                      }
                    }
                
                if(associatedClaim<>null && associatedClaim.RecordTypeId!=ADHOC_CLAIM_REQUEST_RECORDTYPE_ID){
                    request.Level_2__c=approverVsUserId.containsKey(GlobalConstants.LEVEL_2_ISR_APPROVER_WARRANTY_CONTRACTS)?approverVsUserId.get(GlobalConstants.LEVEL_2_ISR_APPROVER_WARRANTY_CONTRACTS):null;
                    request.level_3__c=approverVsUserId.containsKey(GlobalConstants.CONTRACT_EXECUTION_MANAGER)?approverVsUserId.get(GlobalConstants.CONTRACT_EXECUTION_MANAGER):null;
                }

                if(associatedClaim<>null)
                    request.Service_Contract__c=associatedClaim.Service_Contract__c;
            }        
        }
    }

    /*------------------------------------------------------------------------
    Author:        Shailja Mishra 
    Company:       Salesforce
    Description:   Populate approvers for Service Contract and Warranty type on Claim requests
                   User Story => W-000280, W-000288 Sprint 3
    Inputs:        list of new claimRequests
    ---------------------------------------------------------------------------
    History
    24-11-2020      Shailja Mishra     Initial Release
    -----------------------------------------------------------------------*/
    public void populateApproversForAMC_CMC_ServiceContractsAndWarranty(List<Claim_Requests__c> claimRequests){
        Set<String> mdtNames=new Set<String>{GlobalConstants.CONTRACT_EXECUTION_MANAGER_DEV_NAME,
                                             GlobalConstants.MHE_CONTRACT_RENTAL_CLAIM_REQUEST_APPROVER,
                                             GlobalConstants.MHE_CONTRACT_CONTRACT_CLAIM_REQUEST_APPROVER};
        
        Map<String, String> mheDivisionVsLOBHead = new Map<String, String>();
        List<Id> assetIds = new List<Id>();
        List<Id> serviceContractIds = new List<Id>();
        Map<Id, ServiceContract> idVsServiceContract = new Map<Id, ServiceContract>();
        Map<Id, Asset> idVsAsset = new Map<Id, Asset>();
        for(Claim_Requests__c request : claimRequests){
            if(request.RecordTypeId == CONTRACT_RECORDTYPE_ID){
                serviceContractIds.add(request.Service_Contract__c);
            }
            if(request.RecordTypeId == WARRANTY_TYPE_RECORDTYPE_ID){
                assetIds.add(request.Asset__c);
            }
        }
        
        List<Application_Settings__mdt> applicationSettings = [Select DeveloperName, Label, Value__c From Application_Settings__mdt
                                                               Where DeveloperName IN: mdtNames and value__c != null];
        
        idVsServiceContract = new Map<Id, ServiceContract>([Select Id, MHE_Division__c From ServiceContract Where Id IN: serviceContractIds]);
        idVsAsset = new Map<Id, Asset>([Select Id, MHE_Division__c From Asset Where Id IN: assetIds]);
        mheDivisionVsLOBHead = getMHEDivisionVsLOBHead(GlobalConstants.MHE_Division_Vs_MetadataLOB);
        
        String rentalsApprover = '';
        String mheContractsApprover = '';
        String contractExecutionManager = '';
        for(Application_Settings__mdt mdt : applicationSettings){
            if(mdt.DeveloperName.equals(GlobalConstants.CONTRACT_EXECUTION_MANAGER_DEV_NAME)){
                contractExecutionManager = mdt.Value__c;
            }
            if(mdt.DeveloperName.equals(GlobalConstants.MHE_CONTRACT_RENTAL_CLAIM_REQUEST_APPROVER)){
                rentalsApprover = mdt.Value__c;
            }
            if(mdt.DeveloperName.equals(GlobalConstants.MHE_CONTRACT_CONTRACT_CLAIM_REQUEST_APPROVER)){
                mheContractsApprover = mdt.Value__c;
            }
        }
        
        Set<Id> userIds = new Set<Id>((List<Id>)mheDivisionVsLOBHead.values());
        Map<Id, User> idVsUser = new Map<Id, User>([Select Id, ManagerId, Manager.ManagerId From User Where Id IN : userIds]);
        
        for(Claim_Requests__c request : claimRequests){
            if(request.RecordTypeId == CONTRACT_RECORDTYPE_ID
               ||request.RecordTypeId == WARRANTY_TYPE_RECORDTYPE_ID){
                request.Level_1__c = String.isNotBlank(contractExecutionManager) ? Id.valueOf(contractExecutionManager) : null;
                
                    if( (!idVsServiceContract.isEmpty() && idVsServiceContract.containsKey(request.Service_Contract__c) && idVsServiceContract.get(request.Service_Contract__c).MHE_Division__c.equals(GlobalConstants.MHE_SUB_DIVISION_CONTRACT))
                        ||(!idVsAsset.isEmpty() && idVsAsset.containsKey(request.Asset__c))){
                        request.Level_2__c = String.isNotBlank(mheContractsApprover) ? Id.valueOf(mheContractsApprover) : null;
                    }
                    if(!idVsServiceContract.isEmpty() && idVsServiceContract.containsKey(request.Service_Contract__c) && idVsServiceContract.get(request.Service_Contract__c).MHE_Division__c.equals(GlobalConstants.MHE_SUB_DIVISION_RENTAL)){
                        request.Level_2__c = String.isNotBlank(rentalsApprover) ? Id.valueOf(rentalsApprover) : null;
                    }
               
                string mheDivision = '';   
                if(!idVsServiceContract.isEmpty() && idVsServiceContract.containsKey(request.Service_Contract__c)) {
                    mheDivision = idVsServiceContract.get(request.Service_Contract__c).MHE_Division__c;
                } else if(!idVsAsset.isEmpty() && idVsAsset.containsKey(request.Asset__c)) {
                    mheDivision = GlobalConstants.MHE_SUB_DIVISION_CONTRACT;
                }
                request.Level_3__c = mheDivisionVsLOBHead.get(mheDivision); 
                if(!idVsUser.isEmpty()){
                    request.Level_4__c = idVsUser.containsKey(request.Level_3__c) ? idVsUser.get(request.Level_3__c).ManagerId : null;
                    request.Level_5__c = idVsUser.containsKey(request.Level_3__c) ? idVsUser.get(request.Level_3__c).Manager.ManagerId : null; 
                }
            }
        }
    }

    /*--------------------------------------------------------------------------
    Author:        Shailja Mishra 
    Company:       Salesforce
    Description:   Populate approvers for AdHoc Claim requests
                   User Story => W-000295 Sprint 3
    Inputs:        list of new claimRequests
    ---------------------------------------------------------------------------
    History
    09-12-2020      Shailja Mishra     Initial Release
    --------------------------------------------------------------------------*/
    public void populateApproversForAdHocClaims(List<Claim_Requests__c> claimRequests){
        List<Id> caseIds = new List<Id>();
        List<Area_Code_Branch_Champion__mdt> areaMappings = new List<Area_Code_Branch_Champion__mdt>();
        Set<String> areaCodes = new Set<String>();
        Map<Id, User> idVsUser = new Map<Id, User>();
        Map<Id, Case> idVsCase = new Map<Id, Case>();
        Map<String, String> mheDivisionVsLOBHead = new Map<String, String>();
        Map<String, String> mheDivisionVsCheckerId = new Map<String, String>();
        Map<String, String> areaCodeVsalaryCodes = new Map<String, String>();
        
        //
        for(Claim_Requests__c cr : claimRequests){
            if(cr.Area_Code__c != null && cr.recordTypeId == ADHOC_CLAIM_REQUEST_RECORDTYPE_ID){
                areaCodes.add(cr.Area_Code__c);
                caseIds.add(cr.Case_Number__c);
            }
        }
        
        if(areaCodes.size() > 0){
            areaMappings = [Select Id, Area_Code__c, Branch_Champion_salary_code__c, Branch_head_Salary_code__c From Area_Code_Branch_Champion__mdt Where Area_Code__c IN: areaCodes and BU_Division__c='MHE'];
            Set<String> salaryCodes = new Set<String>();
            for(Area_Code_Branch_Champion__mdt mdt : areaMappings){
                areaCodeVsalaryCodes.put(mdt.Area_Code__c, mdt.Branch_head_Salary_code__c);
                salaryCodes.add(mdt.Branch_head_Salary_code__c);
            }
            
            Map<String, User> salaryCodeVsUser = new Map<String, User>();
            List<User> userFromSalaryCode = [Select Id, Area_Code__c, Salary_Code__c From User Where Salary_Code__c IN: salaryCodes];
            for(User ur : userFromSalaryCode){
                salaryCodeVsUser.put(ur.Salary_Code__c, ur);
            }
            
            //idVsUser = getUsers(ownerIds);
            idVsCase = new Map<Id, Case>([Select Id, MHE_Division__c From Case Where Id IN: caseIds]);
            mheDivisionVsLOBHead = getMHEDivisionVsLOBHead(GlobalConstants.MHE_Division_Vs_MetadataLOB);
            Set<Id> userIds = new Set<Id>((List<Id>)mheDivisionVsLOBHead.values());
            List<Id> userIdList = new List<Id>((Set<Id>)userIds);
            idVsUser = getUsers(userIdList);
            for(Claim_Requests__c request : claimRequests){
                
                if(areaCodeVsalaryCodes.containsKey(request.Area_Code__c) && salaryCodeVsUser.containsKey(areaCodeVsalaryCodes.get(request.Area_Code__c))){
                    request.Level_1__c = salaryCodeVsUser.get(areaCodeVsalaryCodes.get(request.Area_Code__c)).Id;
                }
                
                string mheDivision = 'Contracts';   
                /*if(!idVsCase.isEmpty() && idVsCase.containsKey(request.Case_Number__c)) {
                    mheDivision = idVsCase.get(request.Case_Number__c).MHE_Division__c;
                }*/ 
                //populate LOB Head
                request.Level_2__c = mheDivisionVsLOBHead.get(mheDivision); 
                if(!idVsUser.isEmpty()){
                    request.Level_3__c = idVsUser.containsKey(request.Level_2__c) ? idVsUser.get(request.Level_2__c).ManagerId : null;
                }
            }
        }
    }

    /*------------------------------------------------------------------------
    Author:        Shailja Mishra 
    Company:       Salesforce
    Description:   Populate approvers for Service Contract and Warranty type on Claim requests
                   User Story => W-000280, W-000288 Sprint 3
    Inputs:        list of new claimRequests
    ---------------------------------------------------------------------------
    History
    24-11-2020      Shailja Mishra     Initial Release
    -----------------------------------------------------------------------*/
    public Map<Id, User> getUsers(List<Id> userIds){
        return new Map<Id, User>([Select Id, ManagerId, Manager.ManagerId From User Where Id IN: userIds]);
    }

    /*------------------------------------------------------------------------
    Author:        Shailja Mishra 
    Company:       Salesforce
    Description:   Method is reponsible for returning map of MHEDivision Vs LOB Head UserID
                   User Story => W-000280, W-000288 Sprint 3
    Inputs:        list of new claimRequests
    ---------------------------------------------------------------------------
    History
    24-11-2020      Shailja Mishra     Initial Release
    -----------------------------------------------------------------------*/
    public Map<String, String> getMHEDivisionVsLOBHead(Map<String, String> mheDivisionVsLOB){
        Set<String> metadataDevNames = new Set<String>((List<String>)mheDivisionVsLOB.values());
        List<Application_Settings__mdt> settings = [Select Id, DeveloperName, Value__c, Description__c 
                                                    From Application_Settings__mdt 
                                                    Where DeveloperName IN: metadataDevNames];
        Map<String, String> mheDivisionVsLOBHead = new Map<String, String>();
        for(String mheDivision : mheDivisionVsLOB.keySet()){
            mheDivisionVsLOBHead.put(mheDivision, '');
        }
        
        
        for(String mheDivision : mheDivisionVsLOB.keySet()){
            for(Application_Settings__mdt setting : settings){
                if( setting.DeveloperName.containsIgnoreCase(mheDivisionVsLOB.get(mheDivision)) ){
                    mheDivisionVsLOBHead.put(mheDivision, setting.Value__c);
                    break;
                }
            }
        }
        return mheDivisionVsLOBHead;
    }
    /*------------------------------------------------------------------------
    Author:        Alpana Sahay 
    Company:       GITL  
    Description:   This method will return Service Manager of Invoice Submitter                   
    Inputs:        List of User Ids 
    ---------------------------------------------------------------------------
    History
    06-09-2021      Alpana Sahay     Initial Release
    -----------------------------------------------------------------------*/
    public Map<Id, User> getServiceManager(List<Id> userIds){
        return new Map<Id, User>([Select Id, Service_Manager__c From User Where Id IN: userIds]);
    }
    
}