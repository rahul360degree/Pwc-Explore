/*------------------------------------------------------------------------
Author:        Kishor Kumar
Company:       Salesforce
Description:   Handler class for QuoteApproval component
Inputs:        NA
Test Class:   

History
06-04-2020      Kishor Kumar     Initial Release
----------------------------------------------------------------------------*/
public with sharing class QuoteApprovalHandler {
    
    /*------------------------------------------------------------------------
Author:        Kishor Kumar
Company:       Salesforce
Description:   Update Approvers for Quote Approval process
Inputs:        Parent quote Id
Test Class:   

History
06-04-2020      Kishor Kumar     Initial Release
----------------------------------------------------------------------------*/
    @AuraEnabled
    public static String updateApprovers(Id quoteId){
        Quote quote = [Select Id,RecordType.DeveloperName from Quote where Id=:quoteId];
        if(quote.RecordType.DeveloperName == 'Interio_B2B_Finished_Good'){
            return quote.RecordType.DeveloperName;
        }

        list<Pricing_approval_request__c> pricingRecordsToUpdate = new list<Pricing_approval_request__c>();
        map<Id, User> managerMap = new map<Id, User>();
        Map<String, Id> userNameToIdMap = new Map<String, Id>();
        
        //Map to contains Kitchen Submitter Hierarchy
        map<String, list<Approval_Submitter_Hierarchy_mapping__mdt>> approvalSubmitterHierarchyMap = new map<String, list<Approval_Submitter_Hierarchy_mapping__mdt>>();
        
        set<Id> quoteRecordTypeIds = new set<Id>();
        Quote quoteRec;
        
        set<String> quoteRtDevNames =  GlobalConstants.QUOTE_RT_FOR_APPROVAL;         
        Map<String, String> mheRentalUsersMap = new Map<String, String>();
        Map<String, Integer> submitterHierarchyMap = new Map<String, Integer>{
            GlobalConstants.MHE_MARKETING_MANAGER_PERSONA => 2,
                GlobalConstants.MHE_LOB_HEAD_PERSONA => 3,
                GlobalConstants.MHE_SALES_MANAGER_PERSONA => 1,
                GlobalConstants.MHE_MARKETING_MANAGER_PERSONA2 => 2,
                GlobalConstants.MHE_LOB_HEAD_PERSONA2 => 3,
                GlobalConstants.MHE_FUNCTIONAL_HEAD_PERSONA => 4,
                GlobalConstants.MHE_FUNCTIONAL_HEAD_PERSONA2 => 4
                };
                    String lobKey = 'MHERentalSPR_LOBHead';
        String productManagerKey = 'MHERentalSPR_ProductManager';
        String functionalHeadKey = 'MHERentalSPR_FunctionalHead';
        
        if(String.isNotBlank(quoteId)){
            //Fetch Quote Record types from Utility Class
            Utility utilityVar = new Utility();
            map<String, Id> rtNameVsId =  utilityVar.fetchRecordTypes(GlobalConstants.QUOTE_SOBJECT_API_NAME);
            
            if(!rtNameVsId.isEmpty()){
                for(String rtDevName : rtNameVsId.keySet()){
                    if(quoteRtDevNames.contains(rtDevName)){
                        quoteRecordTypeIds.add(rtNameVsId.get(rtDevName));
                    }
                }
            }
            
            //Fetch Approval Hierarchy Metadata mappings
            for(Approval_Submitter_Hierarchy_mapping__mdt sHierarchy : [SELECT Quote_Business_Unit__c, Submitter_Level__c, Quote_Submitter_Persona__c, Category__c  
                                                                        FROM Approval_Submitter_Hierarchy_mapping__mdt]){
                                                                            
                                                                            if(!approvalSubmitterHierarchyMap.containsKey(sHierarchy.Quote_Business_Unit__c)){
                                                                                approvalSubmitterHierarchyMap.put(sHierarchy.Quote_Business_Unit__c, new list<Approval_Submitter_Hierarchy_mapping__mdt>{sHierarchy});
                                                                            } else {
                                                                                approvalSubmitterHierarchyMap.get(sHierarchy.Quote_Business_Unit__c).add(sHierarchy);
                                                                            }              
                                                                        }
            
            map<Id, Quote> quoteDetail = new map<Id, Quote>([Select Id, CreatedById, Approval_Status__c, RecordType.DeveloperName, Category__c, Transaction_Type__c,
                                                             CreatedBy.ManagerId, CreatedBy.Manager.ManagerId, CreatedBy.Manager.Manager.ManagerId,
                                                             //CreatedBy.Manager.Manager.Manager.ManagerId,
                                                             (SELECT Id, Price_Difference__c, Is_New_Equipment__c, Is_Generic_Product__c,Skip_Generic_SPR__c
                                                              FROM QuoteLineItems)
                                                             FROM Quote  
                                                             WHERE Id =: quoteId 
                                                             AND RecordTypeId IN: quoteRecordTypeIds 
                                                             LIMIT 1]);
            if(!quoteDetail.isEmpty()){
                quoteRec = quoteDetail.get(Id.valueOf(quoteId));
                if (quoteRec.Approval_Status__c == GlobalConstants.APPROVAL_NOT_REQUIRED_STATUS
                    || quoteRec.Approval_Status__c == GlobalConstants.APPROVED_STATUS
                    || quoteRec.Approval_Status__c == GlobalConstants.Submitted_for_Approval) {
                        return System.Label.Approval_Not_Required;
                    }
                
                if (quoteRec.RecordType.DeveloperName == GlobalConstants.QUOTE_RECORDTYPE_DEV_NAME_MHE_RENTAL) {
                    ApplicationSettingUtil appSettingObj = ApplicationSettingUtil.getInstance();
                    if (!appSettingObj.developerNameWithValueMap.isEmpty()) {
                        if (appSettingObj.developerNameWithValueMap.containsKey(lobKey.toUpperCase())) {
                            mheRentalUsersMap.put(lobKey, appSettingObj.developerNameWithValueMap.get(lobKey.toUpperCase()));
                        }
                        if (appSettingObj.developerNameWithValueMap.containsKey(productManagerKey.toUpperCase())) {
                            mheRentalUsersMap.put(productManagerKey, appSettingObj.developerNameWithValueMap.get(productManagerKey.toUpperCase()));
                        }
                        if (appSettingObj.developerNameWithValueMap.containsKey(functionalHeadKey.toUpperCase())) {
                            mheRentalUsersMap.put(functionalHeadKey, appSettingObj.developerNameWithValueMap.get(functionalHeadKey.toUpperCase()));
                        }
                    }
                }
                //added Role_Name__c by Shreela on 11th May 2022
                for(User userRec : [Select Id, ManagerId, Manager.ManagerId, Manager.Manager.ManagerId, Manager.Manager.Manager.ManagerId,Role_Name__c,
                                    Manager.UserRole.Name, Manager.Manager.UserRole.Name, UserName, Persona__c, 
                                    Manager.Persona__c, Manager.Manager.Persona__c, Manager.Manager.Manager.Persona__c, Manager.Manager.Manager.Manager.Persona__c 
                                    FROM User 
                                    WHERE (Id =: quoteDetail.get(Id.valueof(quoteId)).createdById OR UserName IN : mheRentalUsersMap.values())
                                    AND IsActive = TRUE]){
                                        managerMap.put(userRec.Id, userRec);
                                        userNameToIdMap.put(userRec.UserName, userRec.Id);
                                    }
            }
            
            
            for(Pricing_approval_request__c par : [SELECT Id, Regional_Sales_manager__c, Is_Generic_Product__c, Is_New_Equipment__c, Territory_Sales_manager__c, Approval_Status__c, 
                                                   Interio_Script_Store_Manager__c, Interio_KITCHEN_TSI__c, Interio_Script_HO_Sales_Support_Manager__c, SSG_SFS_Sales_Marketing_Head__c,
                                                   Interio_Script_Retails_Operation_Head__c, Interio_KITCHEN_Zonal_Head__c,   
                                                   Maximum_Price_Difference__c, MHE_Sales_Manager__c, MHE_Regional_Manager__c, MHE_Marketing_Manager__c, MHE_LOB_Head__c     
                                                   FROM Pricing_approval_request__c 
                                                   WHERE Quote__c =: quoteId LIMIT 1]){
                                                       if(!managerMap.isEmpty()){
                                                           par.Interio_B2B_Level_2__c = managerMap.get(quoteDetail.get(quoteId).CreatedById).ManagerId;
                                                           
                                                           if(managerMap.get(quoteDetail.get(quoteId).CreatedById).ManagerId != null){
                                                               par.Interio_B2C_VFD_Zonal_Head__c = managerMap.get(quoteDetail.get(quoteId).CreatedById).Manager.ManagerId;
                                                               par.Interio_B2B_Level_3__c = managerMap.get(quoteDetail.get(quoteId).CreatedById).Manager.ManagerId;
                                                               
                                                               if(managerMap.get(quoteDetail.get(quoteId).CreatedById).Manager.ManagerId != null){
                                                                   
                                                                   par.Interio_B2B_Level_4__c = managerMap.get(quoteDetail.get(quoteId).CreatedById).Manager.Manager.ManagerId;
                                                                   
                                                                   if(managerMap.get(quoteDetail.get(quoteId).CreatedById).Manager.Manager.ManagerId != null){
                                                                       par.Interio_B2B_Level_7__c = managerMap.get(quoteDetail.get(quoteId).CreatedById).Manager.Manager.Manager.ManagerId;
                                                                   }
                                                               }
                                                           }
                                                           
                                                           
                                                           system.debug('>>>>>>>> QuoteApprovalHandler - MHE MHE_Equipments Secondary >>>> BEFORE >>>>>');
                                                           
                                                           //for populating MHE Sales Manager and Regional Manager(Reagional Head)
                                                           if(quoteRec.RecordType.DeveloperName == 'MHE_Equipments' && quoteRec.Transaction_Type__c == 'Secondary' 
                                                              //&& quoteRec.ContactId != null
                                                             ){
                                                                 system.debug('>>>>>>>> QuoteApprovalHandler - MHE MHE_Equipments Secondary >>>>143>>>>>');
                                                                 
                                                                 if(managerMap.get(quoteRec.CreatedById).ManagerId != null && managerMap.get(quoteRec.CreatedById).Manager.ManagerId != null){
                                                                     par.MHE_Sales_Manager__c = managerMap.get(quoteRec.CreatedById).Manager.ManagerId;
                                                                     
                                                                     if(managerMap.get(quoteRec.CreatedById).Manager.Manager.ManagerId != null){
                                                                         par.MHE_Regional_Manager__c = managerMap.get(quoteRec.CreatedById).Manager.Manager.ManagerId;
                                                                     }
                                                                     
                                                                     if(managerMap.get(quoteRec.CreatedById).Manager.Manager.Manager.ManagerId != null){
                                                                         par.MHE_LOB_Head__c = managerMap.get(quoteRec.CreatedById).Manager.Manager.Manager.ManagerId;
                                                                     }
                                                                 }
                                                             }
                                                           else
                                                               if(managerMap.get(quoteRec.CreatedById).ManagerId != null){
                                                                   //added by Shreela on 29th April 2022 for JIRA SMEPB-23 
                                                                   if(managerMap.get(quoteRec.CreatedById).Persona__c == GlobalConstants.MHE_CSG_HEAD_PERSONA && (managerMap.get(quoteRec.CreatedById).Role_Name__c == GlobalConstants.SALES_MANAGER_ROLE_2 || managerMap.get(quoteRec.CreatedById).Role_Name__c == GlobalConstants.SALES_MANAGER_ROLE_3)){
                                                                       par.MHE_Sales_Manager__c = managerMap.get(quoteRec.CreatedById).Id;
                                                                       
                                                                   }
                                                                   //ended by Shreela on 29th April 2022 for JIRA SMEPB-23
                                                                   else{
                                                                       par.MHE_Sales_Manager__c = managerMap.get(quoteRec.CreatedById).ManagerId;// MHE_SALES_ENGINEER_PERSONA2 and role SALES_MANAGER_ROLE_1
                                                                   }
                                                               }
                                                           if(managerMap.get(quoteRec.CreatedById).Manager.ManagerId != null){
                                                               //added by Shreela on 29th April 2022 for JIRA SMEPB-23
                                                               if((managerMap.get(quoteRec.CreatedById).Persona__c == GlobalConstants.MHE_SALES_ENGINEER_PERSONA2 && 
                                                                   managerMap.get(quoteRec.CreatedById).Role_Name__c == GlobalConstants.SALES_MANAGER_ROLE_1) ||
                                                                  (managerMap.get(quoteRec.CreatedById).Persona__c == GlobalConstants.MHE_CSG_HEAD_PERSONA && 
                                                                   (managerMap.get(quoteRec.CreatedById).Role_Name__c == GlobalConstants.SALES_MANAGER_ROLE_2 || 
                                                                    managerMap.get(quoteRec.CreatedById).Role_Name__c== GlobalConstants.SALES_MANAGER_ROLE_3 || 
                                                                    managerMap.get(quoteRec.CreatedById).Role_Name__c== GlobalConstants.SALES_MANAGER_ROLE_4 ))){
                                                                        //added SALES_MANAGER_ROLE_4 role condition by Shreela on 22nd July 2022 for Tkt#30551942 
                                                                      	par.MHE_Regional_Manager__c = managerMap.get(quoteRec.CreatedById).ManagerId;
                                                                  }
                                                               //ended by Shreela on 29th April 2022 for JIRA SMEPB-23
                                                               else{
                                                                   par.MHE_Regional_Manager__c = managerMap.get(quoteRec.CreatedById).Manager.ManagerId;
                                                               }
                                                           }
                                                       }
                                                       
                                                       //Logic to populate Kitchen Hierarchy 
                                                       par = ApprovalSubmitterHierarchyCreator.createHierarchyForKitchen(quoteRec, par, managerMap, approvalSubmitterHierarchyMap);
                                                       
                                                       //Logic to populate Interio Script Hierarchy 
                                                       par = ApprovalSubmitterHierarchyCreator.createHierarchyForInterioScript(quoteRec, par, managerMap, approvalSubmitterHierarchyMap);
                                                       
                                                       //Logic to populate SSG_SFS Hierarchy 
                                                       //par = ApprovalSubmitterHierarchyCreator.createHierarchyForSSG_SFS(quoteRec, par, managerMap, approvalSubmitterHierarchyMap);
                                                       
                                                       //Logic to populate Regular/Key Hierarchy for SSG
                                                       par = ApprovalSubmitterHierarchyCreator.createHierarchyForSSG_Regular_Key(quoteRec, par, managerMap, approvalSubmitterHierarchyMap);
                                                       
                                                       
                                                       /* This logic uses the persona to identify the submitting user's hierarchy. At all levels, if the approver of that
* level has created a quote, they need not approve it. Only the next level approval is required
*/
                                                       if (quoteRec.RecordType.DeveloperName == GlobalConstants.QUOTE_RECORDTYPE_DEV_NAME_MHE_RENTAL) {
                                                           Integer hierarchyLevel = 0;
                                                           if (submitterHierarchyMap.containsKey(managerMap.get(quoteRec.CreatedById).Persona__c)) {
                                                               hierarchyLevel = submitterHierarchyMap.get(managerMap.get(quoteRec.CreatedById).Persona__c);
                                                           }
                                                           if (hierarchyLevel >= 1) {
                                                               par.MHE_Sales_Manager__c = null;
                                                           }
                                                           if (hierarchyLevel <= 2 && mheRentalUsersMap.containsKey(productManagerKey) && userNameToIdMap.containsKey(mheRentalUsersMap.get(productManagerKey))) {
                                                               par.MHE_Marketing_Manager__c = userNameToIdMap.get(mheRentalUsersMap.get(productManagerKey));
                                                           }
                                                           if (hierarchyLevel <= 3 && mheRentalUsersMap.containsKey(lobKey) && userNameToIdMap.containsKey(mheRentalUsersMap.get(lobKey))) {
                                                               par.MHE_LOB_Head__c = userNameToIdMap.get(mheRentalUsersMap.get(lobKey));
                                                           }
                                                           if (hierarchyLevel <= 4 && mheRentalUsersMap.containsKey(functionalHeadKey) && userNameToIdMap.containsKey(mheRentalUsersMap.get(lobKey))) {
                                                               // Reusing an existing field for approvers
                                                               par.Interio_B2B_Level_7__c = userNameToIdMap.get(mheRentalUsersMap.get(functionalHeadKey));
                                                           }
                                                           par.Submitter_Hierarchy_Level__c = hierarchyLevel;
                                                       }
                                                       // Need this update in following scenario: 
                                                       // When deal is created with generic products/new equipment
                                                       // Once quote is created, as the pricing approval request field is not populated until after the 
                                                       // record is saved, the quote line item trigger won't have any reference to the field and the update
                                                       // for below fields is skipped
                                                       par.Maximum_Price_Difference__c = 0;
                                                       if (!quoteRec.QuoteLineItems.isEmpty()) {
                                                           for (QuoteLineItem each : quoteRec.QuoteLineItems) {
                                                               if (each.Is_New_Equipment__c) {
                                                                   par.Is_New_Equipment__c = true;
                                                               }
                                                               //Added by Pankaj on 05/10/2021//Skip_Generic_SPR__c added for setting flag false in PAR i.e par.Is_Generic_Product__c if there is freight item
                                                               if (each.Is_Generic_Product__c && !each.Skip_Generic_SPR__c) {
                                                                   par.Is_Generic_Product__c = true;
                                                               }
                                                               if (each.Price_Difference__c > par.Maximum_Price_Difference__c) {
                                                                   par.Maximum_Price_Difference__c = each.Price_Difference__c;
                                                               }
                                                           }
                                                       }
                                                       
                                                       pricingRecordsToUpdate.add(par);
                                                   }
            
            update pricingRecordsToUpdate;
        }
        return null;
    }
    
    /*------------------------------------------------------------------------
Author:        Kishor Kumar
Company:       Salesforce
Description:   Submit Pricing_approval_request__c record for Approval
Inputs:        Parent Quote id
Test Class:   

History
06-04-2020      Kishor Kumar     Initial Release
----------------------------------------------------------------------------*/
    @AuraEnabled
    public static String submitForApproval(Id quoteId, String approvalText){
        String recordStatus = '';
        list<Quote> quoteRecs = new list<Quote>([SELECT Id, Approval_Status__c FROM Quote WHERE Id =: quoteId]);
        
        list<Pricing_approval_request__c> pricingRecs = new list<Pricing_approval_request__c>([SELECT Id, Category__c,  
                                                                                               Requested_Customer_discount_max__c,Approval_Status__c,
                                                                                               Quote_Record_Type_Developer_Name__c,
                                                                                               Dealer_Margin_Dealer_order__c,
                                                                                               Scope_of_Installation__c
                                                                                               FROM Pricing_approval_request__c 
                                                                                               WHERE Quote__c =: quoteId Limit 1]);
        
        /*Commented By pankaj on 12 july 2022 This functinality Not required as per division
        if(pricingRecs[0].Quote_Record_Type_Developer_Name__c =='SSG' && 
        (
            ( (pricingRecs[0].Category__c =='Regular' || pricingRecs[0].Category__c =='Regular Swift') && QuoteApprovalHandler_Helper.isAutoApproved_SSG_Regular(pricingRecs[0])) ||
            ( (pricingRecs[0].Category__c =='Key' || pricingRecs[0].Category__c =='Key Swift') && QuoteApprovalHandler_Helper.isAutoApproved_SSG_Key(pricingRecs[0])) || 
            (pricingRecs[0].Category__c =='Life Cycle Services' && QuoteApprovalHandler_Helper.isAutoApproved_SSG_LCS(pricingRecs[0]))
        )
        
        ){
            pricingRecs[0].Approval_Status__c = 'Approved';
            update pricingRecs;
            return 'Approval not required';
        }*/
        
        
        //Create an approval request
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments(approvalText);
        req1.setObjectId(pricingRecs[0].Id);
        // Submit on behalf of a specific submitter
        req1.setSubmitterId(userInfo.getUserId()); 
        // Submit the record to specific process 
        switch on pricingRecs[0].Quote_Record_Type_Developer_Name__c {
            /*Commented by pankaj 12 july 2022 as below part is not in use
            when 'SSG' {
                if((pricingRecs[0].Category__c == 'Regular' || pricingRecs[0].Category__c == 'Regular Swift') && 
                   quoteRecs[0].Approval_Status__c == 'Approval Not Required' || quoteRecs[0].Approval_Status__c == 'Rejected'){                                                              //|| quoteRecs[0].Approval_Status__c == 'Rejected'   == COMMENTEDBY PANKAJ 9/7/2022 TO SUBMIT REJCTED QUOTES
                       req1.setProcessDefinitionNameOrId('SSG_Over_Outflow_For_Regular');
                       System.debug('approval process===>'+req1);
                   } else if(pricingRecs[0].Category__c == 'SFS Imported' || pricingRecs[0].Category__c == 'SFS In-house')
                   {
                       // req1.setProcessDefinitionNameOrId('Pricing_Request_Approvals_SFS');
                       //  //Added by Vikrant on 14-04-2021 added category for Ticket#30356659
                       req1.setProcessDefinitionNameOrId('SSG_Quote_Approvals_Regular_Key');
                   }else if(pricingRecs[0].Category__c == 'Life Cycle Services')
                   {
                       
                       req1.setProcessDefinitionNameOrId('SSG_Life_Cycle_Services_V1');
                   }
            }*/
            when 'Interio_B2C_VFD' {
                req1.setProcessDefinitionNameOrId('Interio_B2C_VFD_Approval');
            }
            when 'MHE_Rental' {
                req1.setProcessDefinitionNameOrId('MHE_RenTRUST_Approval');
            }
            when else {
                recordStatus = 'No approval process found. Please contact System administrator.';
                
            }
        }
        
        req1.setSkipEntryCriteria(false);
        
        try{
            // Submit the approval request for the account
            Approval.ProcessResult result = Approval.process(req1);
            
            // Verify the result
            if(result.isSuccess()){
                Quote quoteRec = new Quote();
                quoteRec.Id = quoteId;
                quoteRec.Approval_Status__c = GlobalConstants.Submitted_for_Approval;
                
                try{
                    //Set EXECUTE_METHOD to false
                    GlobalConstants.EXECUTE_METHOD = false;
                    update quoteRec;
                    
                    recordStatus ='Quote successfully submitted for approval!!';
                } catch (exception ex){
                    recordStatus = ''+ex.getMessage();
                }
            }else {
                Database.Error[] errors = result.getErrors();
                recordStatus = ''+errors[0].getMessage();
            }            
        } catch (exception e){
            recordStatus = ''+e.getMessage();
        }
        
        return recordStatus;
    }
}