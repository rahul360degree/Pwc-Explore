/*------------------------------------------------------------------------
Author:        Kishor Kumar
Company:       Salesforce
Description:   Class to create Pricing Approval Request Record on insertion of Quote record
Inputs:        NA
Test Class:    
History
06-04-2020      Kishor Kumar     Initial Release
----------------------------------------------------------------------------*/
public without sharing class PricingApprovalRequestRecordCreator {
    
    /*------------------------------------------------------------------------
    Author:        Kishor Kumar
    Company:       Salesforce
    Description:   Method to create 'Pricing Approval Request' for every Quote record created in SF
    Inputs:        List of created Quote records
    Test Class:    
    History
    06-04-2020      Kishor Kumar     Initial Release
    ----------------------------------------------------------------------------*/
    public void createPricingApprovalRequestRecord(list<Quote> quotes){
        String recordTypeName = 'Customer_Quote';
        Map<Id,Pricing_approval_request__c> mapPricingRecordsToCreate = new Map<Id,Pricing_approval_request__c>();
        Map<Id,Quote> mapQuote=new Map<Id,Quote>();
        set<Id> createdByIds = new set<Id>();
        map<Id, User> managerMap = new map<Id, User>();
        set<Id> quoteIds = new set<Id>();
        Set<String> accountIds = new Set<String>();
        map<Id, Integer> quoteIdVsPricingRecordCount = new map<Id, Integer>();
        Id customerQuoteId;
        
        set<Id> quoteRecordTypeIds = new set<Id>();
        
        set<String> quoteRtDevNames =  GlobalConstants.QUOTE_RT_FOR_APPROVAL;    
        
        User reportToUser;
        User loggedInUser = [Select Id,Account.OwnerId,ContactId,Contact.ReportsToId FROM USER WHERE Id =: UserInfo.getUserId()];
        if(loggedInUser.ContactId != null && loggedInUser.Contact.ReportsToId != null){
            reportToUser = [Select Id FROM User WHERE ContactId =: loggedInUser.Contact.ReportsToId LIMIT 1];
        }
        
        //Fetch Record types from Utility Class
        Utility utilityVar = new Utility();
        map<String, Id> rtNameVsId =  utilityVar.fetchRecordTypes(GlobalConstants.QUOTE_SOBJECT_API_NAME);
        
        if(!rtNameVsId.isEmpty()){
            for(String rtDevName : rtNameVsId.keySet()){
                if(quoteRtDevNames.contains(rtDevName)){
                    quoteRecordTypeIds.add(rtNameVsId.get(rtDevName));
                } else if (rtDevName.equals(recordTypeName)) {
                   customerQuoteId = rtNameVsId.get(rtDevName);
                }
            }
        }
        Set<String> oppIds = new Set<String>();
        for(Quote quoteRec : quotes){
            if(quoteRecordTypeIds.contains(Id.valueOf(quoteRec.RecordTypeId))){
                createdByIds.add(quoteRec.CreatedById);
                quoteIds.add(quoteRec.Id);
            }
            //For MHE Parts Secondary Order
            if(quoteRec.Record_Type_Developer_Name__c ==  GlobalConstants.QUOTE_RECORDTYPE_DEV_NAME_MHE_PARTS
                && quoteRec.Transaction_Type__c == GlobalConstants.ORDER_TYPE_SECONDARY){
                oppIds.add(quoteRec.OpportunityId);
            }
        }
        
        Map<Id,Opportunity> opps = new Map<Id,Opportunity>([Select Id,AccountId,Account.OwnerId FROM Opportunity WHERE Id IN : oppIds]);

        for(Quote qote : [Select Id, (Select Id From Pricing_approval_requests__r) 
                            FROM Quote 
                            WHERE Id IN: quoteIds ]){
            quoteIdVsPricingRecordCount.put(qote.Id, (qote.Pricing_approval_requests__r).size());
        }
        

        //Added Role_Name__c,Persona__c by Shreela on 29th April 2022
        for(User userRec : [Select Id, ManagerId, Manager.ManagerId, Manager.Manager.ManagerId, Manager.Manager.Manager.ManagerId,Role_Name__c,Persona__c,Service_Manager__c,ContactId //Added Service Manager and Contact by Shreela on 23rd Nov 2023 for SMEPB - 130
                            from User 
                            Where Id IN: createdByIds]){
            managerMap.put(userRec.Id, userRec);
        }
        //ended by Shreela on 29th April 2022
        
        for(Quote quoteRec : quotes){
            if (quoteRec.RecordTypeId == customerQuoteId)
                continue;
            if(quoteIdVsPricingRecordCount.isEmpty() || (!quoteIdVsPricingRecordCount.isEmpty() && 
                                                         quoteIdVsPricingRecordCount.containsKey(quoteRec.Id) && 
                                                         quoteIdVsPricingRecordCount.get(quoteRec.Id) < 1)){
                                                             
                Pricing_approval_request__c par = new Pricing_approval_request__c();
                par.Quote__c = quoteRec.Id;
                par.Name = 'PAR-'+ quoteRec.Name;
                par.Approval_Status__c = quoteRec.Approval_Status__c;
                
                //Added by Shreela Nair and Namrata Negi on 26th August 2022                                             
                if(quoteRec.Record_Type_Developer_Name__c == GlobalConstants.QUOTE_RECORDTYPE_APPLIANCE){
                       par.Level_1_Approver__c = quoteRec.Level_1_Approver__c;
                       par.Level_2_Approver__c = quoteRec.Level_2_Approver__c;
                       par.Level_3_Approver__c = quoteRec.Level_3_Approver__c;
                } 
                //Ended by Shreela Nair and Namrata Negi on 26th August 2022                                             
                
                //For MHE Parts , Secondary Order Type , Dealer Account Owner should be the First Approver
                if(quoteRec.Record_Type_Developer_Name__c ==  GlobalConstants.QUOTE_RECORDTYPE_DEV_NAME_MHE_PARTS
                    && quoteRec.Transaction_Type__c == GlobalConstants.ORDER_TYPE_SECONDARY
                    && opps != null
                    && opps.containsKey(quoteRec.OpportunityId)
                    && loggedInUser != null 
                    && loggedInUser.ContactId != null){
                    par.Dealer_Account_Owner__c = loggedInUser.Account.OwnerId;
                    if(reportToUser != null)
                        par.Dealer_Manager__c = reportToUser.Id;
                }
                                                             
                if(!managerMap.isEmpty()){
                    
                    //Added by Shreela on 23rd Nov 2023 for SMEPB - 130
                     if(managerMap.get(quoteRec.CreatedById).ContactId != null && managerMap.get(quoteRec.CreatedById).Service_Manager__c != null){
                         par.Service_Manager__c = managerMap.get(quoteRec.CreatedById).Service_Manager__c;
                     }
                    //Ended by Shreela on 23rd Nov 2023 for SMEPB - 130
                    
                    if(quoteRec.Record_Type_Developer_Name__c == System.Label.Interio_B2B_APO_recordtype 
                        || quoteRec.Record_Type_Developer_Name__c == System.Label.Interio_B2B_Finished_Good_rectype) {
                        par.Interio_B2B_Level_2__c = managerMap.get(quoteRec.CreatedById).ManagerId;
                    }                                           

                    if(managerMap.get(quoteRec.CreatedById).ManagerId != null){
                        
                        par.Interio_B2C_VFD_Zonal_Head__c = managerMap.get(quoteRec.CreatedById).Manager.ManagerId;
                        if(quoteRec.Record_Type_Developer_Name__c == System.Label.Interio_B2B_APO_recordtype 
                            || quoteRec.Record_Type_Developer_Name__c == System.Label.Interio_B2B_Finished_Good_rectype){
                            par.Interio_B2B_Level_3__c = managerMap.get(quoteRec.CreatedById).Manager.ManagerId;
                        }                            

                        if(managerMap.get(quoteRec.CreatedById).Manager.ManagerId != null){
                            
                            if(quoteRec.Record_Type_Developer_Name__c == System.Label.Interio_B2B_APO_recordtype 
                                || quoteRec.Record_Type_Developer_Name__c == System.Label.Interio_B2B_Finished_Good_rectype){
                                par.Interio_B2B_Level_4__c = managerMap.get(quoteRec.CreatedById).Manager.Manager.ManagerId;
                            }

                            if(managerMap.get(quoteRec.CreatedById).Manager.Manager.ManagerId != null){
                                if(quoteRec.Record_Type_Developer_Name__c == System.Label.Interio_B2B_APO_recordtype 
                                    || quoteRec.Record_Type_Developer_Name__c == System.Label.Interio_B2B_Finished_Good_rectype){
                                    par.Interio_B2B_Level_7__c = managerMap.get(quoteRec.CreatedById).Manager.Manager.Manager.ManagerId;
                                }
                            }
                        }
                    }
                    
                    //for populating MHE Sales Manager and Regional Manager(Regional Head)
                    if(managerMap.get(quoteRec.CreatedById).ManagerId != null){
                        //added by  on 29th April 2022 for JIRA SMEPB-23
                        if(managerMap.get(quoteRec.CreatedById).Persona__c == GlobalConstants.MHE_CSG_HEAD_PERSONA && (managerMap.get(quoteRec.CreatedById).Role_Name__c == GlobalConstants.SALES_MANAGER_ROLE_2 || managerMap.get(quoteRec.CreatedById).Role_Name__c == GlobalConstants.SALES_MANAGER_ROLE_3)){
                                par.MHE_Sales_Manager__c = managerMap.get(quoteRec.CreatedById).Id;
                                
                        }
                        //ended by Shreela on 29th April 2022 for JIRA SMEPB-23
                        else{
                        par.MHE_Sales_Manager__c = managerMap.get(quoteRec.CreatedById).ManagerId;
                        }
                        if(managerMap.get(quoteRec.CreatedById).Manager.ManagerId != null){
                            //added by Shreela on 29th April 2022 for JIRA SMEPB-23
                            if((managerMap.get(quoteRec.CreatedById).Persona__c == GlobalConstants.MHE_SALES_ENGINEER_PERSONA2 && managerMap.get(quoteRec.CreatedById).Role_Name__c == GlobalConstants.SALES_MANAGER_ROLE_1) ||
                               (managerMap.get(quoteRec.CreatedById).Persona__c == GlobalConstants.MHE_CSG_HEAD_PERSONA && (managerMap.get(quoteRec.CreatedById).Role_Name__c == GlobalConstants.SALES_MANAGER_ROLE_2 || managerMap.get(quoteRec.CreatedById).Role_Name__c==GlobalConstants.SALES_MANAGER_ROLE_3 || managerMap.get(quoteRec.CreatedById).Role_Name__c==GlobalConstants.SALES_MANAGER_ROLE_4))){//added SALES_MANAGER_ROLE_4 role condition by Shreela on 22nd July 2022 for Tkt#30551942 
                                   par.MHE_Regional_Manager__c = managerMap.get(quoteRec.CreatedById).ManagerId;
                                   
                            }
                            //ended by Shreela on 29th April 2022 for JIRA SMEPB-23
                            else{
                            par.MHE_Regional_Manager__c = managerMap.get(quoteRec.CreatedById).Manager.ManagerId;
                            }
                        }
                    }
                }
                mapPricingRecordsToCreate.put(quoteRec.Id,par);
                mapQuote.put(quoteRec.Id,quoteRec);
            }
        }
        
        if(mapPricingRecordsToCreate.size() > 0){
            try{
                insert mapPricingRecordsToCreate.values();
                
            } catch(Exception ex){
                Logger.logError('PricingApprovalRequestRecordCreator', 'createPricingApprovalRequestRecord', '', ex);
            }
            
        }
    }

}