/*------------------------------------------------------------------------
Author:        Pankaj Meshram
Company:       GITL
Description:   Processor class for 'Quote Line Item' Records
Inputs:        List of QLI
Test Class:    
History
Last modifiedBy snehal waghmare
14-12-2023     Last modified
----------------------------------------------------------------------------*/
public class UpdateQliListOfApprovers {
    List<QuoteLineItem> listOfApprovers = new List<QuoteLineItem>();
    Boolean isTranTypeMatched;
    //Assign value to current approver
    @InvocableMethod(callout=true label='Get Current Approver')    
    public static void updateCurrentApprover(List<id> ids){  
        handleQuoteSubmit(ids[0],new List<String>());        
    }
    
    public static void handleQuoteSubmit(String quoteId, List<String> qliIds){  
        List<String> lstAllApprovers = new List<String>();
        List<QuoteLineItem> lstCurrAppr = new List<QuoteLineItem>();  
        String query = 'Select Id, QuoteId, Order_Type__c,List_of_Approvers__c,approval_status__c,Requested_WD_CONT_Req_Disc_Basic__c,Req_Net_Rlizd_Bsc_Disc__c,Product_Line_c__c,'
            +' Quote.approval_status__c,Req_WD_Ret_SAC_OnReqDiscBasic__c,'
            +' Requested_Customer_Discount__c,current_approver__c,Pending_with_owner__c,'
            +' Quote.Opportunity.Owner.name,'               
            +' Quote_Record_Type__c,'
            +' Quote.Opportunity.Owner.ManagerId,'
            +' Quote.Opportunity.Owner.Manager.ManagerId,'
            +' Quote.Opportunity.Owner.Manager.Manager.ManagerId,'
            +' Quote.Opportunity.Owner.Manager.Persona__c,'
            +' Quote.Opportunity.Owner.Manager.Manager.Persona__c,'
            +' Quote.Opportunity.Owner.Manager.Manager.Manager.Persona__c,'
            +' Quote.Opportunity.Owner.Manager.Name,'
            +' Quote.Opportunity.Owner.Manager.Manager.Name,'
            +' Quote.Opportunity.Owner.Manager.Manager.Manager.Name,'
            +' Quote.recordtypeID,'
            +' Quote.Interio_Sub_Division__c,'
            +' Quote.Transaction_Type_c__c,'
            +' Quote.Opportunity.Account.Is_Key_Account__c,'
            +' Quote.End_Customer__r.Is_Key_Account__c'
            +' from QuoteLineItem where QuoteId =:quoteId';
        
        query += qliIds.isEmpty()?' ':' AND ID IN: qliIds';
        
        List<QuoteLineItem> newQLIRecords = Database.query(query);
        //Update List of approvers added by pankaj for Interio B2B
        UpdateQliListOfApproversHelper updateApprover = new UpdateQliListOfApproversHelper();
        newQLIRecords = updateApprover.updateDirectBillingCust(newQLIRecords);
        
        //Put Manager Names in Map
        Map<Id,String> MgrIdVsMgrName = new Map<Id,String>();
        for(QuoteLineItem qli:newQLIRecords){
            MgrIdVsMgrName.put(qli.Quote.Opportunity.Owner.ManagerId,qli.Quote.Opportunity.Owner.Manager.Name);
            MgrIdVsMgrName.put(qli.Quote.Opportunity.Owner.Manager.ManagerId,qli.Quote.Opportunity.Owner.Manager.Manager.Name);
            MgrIdVsMgrName.put(qli.Quote.Opportunity.Owner.Manager.Manager.ManagerId,qli.Quote.Opportunity.Owner.Manager.Manager.Manager.Name); 
            
        }
        Integer approvalNotReqQliCount = 0; // Added by snehal waghmare 
        for(QuoteLineItem qli:newQLIRecords){
            
            // Added by snehal waghmare to change  the qli status to approval not required.16-01-23 
            if(qli.Requested_WD_CONT_Req_Disc_Basic__c == 0 && qli.Req_WD_Ret_SAC_OnReqDiscBasic__c == 0 && qli.Requested_Customer_Discount__c== 0 ){
                // if wd cont, dealer margin fields and requested customer disc is 0, approval status not required on QLI
                qli.approval_status__c = GlobalConstants.Approval_Not_Required ;
                approvalNotReqQliCount++ ; 
            }
            if(newQLIRecords.size() > 0 && !String.IsBlank(qli.List_of_Approvers__c)){
                String strOfApprovers = qli.List_of_Approvers__c;            
                lstAllApprovers = strOfApprovers.split(GlobalConstants.Commas);
                
                If(qli.approval_status__c != GlobalConstants.Submitted_for_Approval && qli.approval_status__c != GlobalConstants.APPROVED_STATUS ){// Added by snehal W 30/06/2023
                    qli.Current_Approver__c = lstAllApprovers[0];
                    if(qli.Pending_with_owner__c != ''){
                        qli.Pending_with_owner__c = '';
                    }
                    qli.Pending_with_owner__c = MgrIdVsMgrName.get(qli.Current_Approver__c);
                    qli.approval_status__c = GlobalConstants.Submitted_for_Approval;
                }
                qli.Quote.approval_status__c = GlobalConstants.Submitted_for_Approval;
               // qli.Quote.Approval_Submission_Date__c = System.now(); 
                
            }             
        }
        // Added by snehal waghmare to change the quote status to approval not required. 16-01-23
        if(newQLIRecords.size() == approvalNotReqQliCount){
            newQLIRecords[0].Quote.approval_status__c = GlobalConstants.Approval_Not_Required;
        }
        QLITriggerHandler.TriggerDisabled = true;           
        update newQLIRecords;
        update newQLIRecords[0].Quote; 
    }    
    /*--------------------------------------------------------------------- 
Description- Method to update list of approvers based on Transaction Type
SCenario 1 - Transaction Type = Direct Billing to Customer
-----------------------------------------------------------------------*/
    public void updateDirectBillingCustomer(QuoteLineItem qliRecord,Map<String,Id> grpNameVsGrpId){  
        //Level 1           
        UpdateQliListOfApproversHelper obj = new UpdateQliListOfApproversHelper();
        if(qliRecord.Requested_Customer_Discount__c > 0 && qliRecord.Requested_Customer_Discount__c <= 5 && qliRecord.Req_WD_Ret_SAC_OnReqDiscBasic__c==0  && qliRecord.Requested_WD_CONT_Req_Disc_Basic__c==0 && qliRecord.Req_Net_Rlizd_Bsc_Disc__c > 0 && qliRecord.Req_Net_Rlizd_Bsc_Disc__c <= 5 &&
           ((qliRecord.Quote.Opportunity.Account.Is_Key_Account__c || qliRecord.Quote.End_Customer__r.Is_Key_Account__c) || ((qliRecord.Quote.Interio_Sub_Division__c == GlobalConstants.Interio_Sub_Division_B2B_NON_KAM) && (qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_DESKING || qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_SEATING || qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_STORAGE || qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_OPOS)) ||
            (qliRecord.Quote.Transaction_Type_c__c == GlobalConstants.Transaction_Type_GEM || qliRecord.Quote.Transaction_Type_c__c == GlobalConstants.Transaction_Type_GEM_PAC || qliRecord.Quote.Transaction_Type_c__c == GlobalConstants.Transaction_Type_GEM_RC) ||
            qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_LAB || qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_HEALTHCARE || qliRecord.Product_Line_c__c==GlobalConstants.Product_Line_B2C || qliRecord.Product_Line_c__c==GlobalConstants.Product_Line_WSA)){ 
                obj.handleAssignment(GlobalConstants.Interio_RM_PERSONA,qliRecord,1,'');                 
            } 
        //Level 2
        else if(qliRecord.Requested_Customer_Discount__c > 5 && qliRecord.Requested_Customer_Discount__c <= 10 && qliRecord.Req_WD_Ret_SAC_OnReqDiscBasic__c==0  && qliRecord.Requested_WD_CONT_Req_Disc_Basic__c==0 && qliRecord.Req_Net_Rlizd_Bsc_Disc__c > 5 && qliRecord.Req_Net_Rlizd_Bsc_Disc__c <= 10 &&
                ((qliRecord.Quote.Opportunity.Account.Is_Key_Account__c || qliRecord.Quote.End_Customer__r.Is_Key_Account__c) || ((qliRecord.Quote.Interio_Sub_Division__c ==GlobalConstants.Interio_Sub_Division_B2B_NON_KAM) && (qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_DESKING || qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_SEATING || qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_STORAGE || qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_OPOS)) ||
                 (qliRecord.Quote.Transaction_Type_c__c == GlobalConstants.Transaction_Type_GEM || qliRecord.Quote.Transaction_Type_c__c == GlobalConstants.Transaction_Type_GEM_PAC || qliRecord.Quote.Transaction_Type_c__c == GlobalConstants.Transaction_Type_GEM_RC) ||
                 qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_LAB || qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_HEALTHCARE || qliRecord.Product_Line_c__c==GlobalConstants.Product_Line_B2C || qliRecord.Product_Line_c__c==GlobalConstants.Product_Line_WSA)){ 
                     obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,'');               
                 }
        //Level 3 
        else if(qliRecord.Requested_Customer_Discount__c > 10 && qliRecord.Requested_Customer_Discount__c <= 30 && qliRecord.Req_WD_Ret_SAC_OnReqDiscBasic__c==0  && qliRecord.Requested_WD_CONT_Req_Disc_Basic__c==0 && qliRecord.Req_Net_Rlizd_Bsc_Disc__c > 10 && qliRecord.Req_Net_Rlizd_Bsc_Disc__c <= 30 ){ 
            if(qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_LAB){                
                obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_LAB_QUEUE));                                
            }
            else if(qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_HEALTHCARE){                
                obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_HEALTHCARE_QUEUE));                               
            }
            else if(qliRecord.Product_Line_c__c==GlobalConstants.Product_Line_B2C || qliRecord.Product_Line_c__c==GlobalConstants.Product_Line_WSA){
                obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_B2C_QUEUE));                        
            }
            else{if( (qliRecord.Quote.Opportunity.Account.Is_Key_Account__c || qliRecord.Quote.End_Customer__r.Is_Key_Account__c) &&(qliRecord.Product_Line_c__c != GlobalConstants.Product_Line_LAB || qliRecord.Product_Line_c__c != GlobalConstants.Product_Line_HEALTHCARE || qliRecord.Product_Line_c__c !=GlobalConstants.Product_Line_B2C || qliRecord.Product_Line_c__c !=GlobalConstants.Product_Line_WSA) ){                
                obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_KAM_QUEUE));                
            }
                 if((qliRecord.Quote.Transaction_Type_c__c == GlobalConstants.Transaction_Type_GEM || qliRecord.Quote.Transaction_Type_c__c == GlobalConstants.Transaction_Type_GEM_PAC || qliRecord.Quote.Transaction_Type_c__c == GlobalConstants.Transaction_Type_GEM_RC) && !qliRecord.Quote.Opportunity.Account.Is_Key_Account__c && !qliRecord.Quote.End_Customer__r.Is_Key_Account__c ){
                     obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_GEM_RC_QUEUE));                                     
                 }
                 else if(qliRecord.Quote.Interio_Sub_Division__c ==GlobalConstants.Interio_Sub_Division_B2B_NON_KAM && isProductLineMatched(qliRecord.Product_Line_c__c) && !qliRecord.Quote.Opportunity.Account.Is_Key_Account__c && !qliRecord.Quote.End_Customer__r.Is_Key_Account__c){
                     if(qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_SEATING){               
                         obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_SEATING_QUEUE));              
                     }
                     else if(qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_DESKING){                    
                         obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_DESKING_QUEUE));            
                     }
                     else if(qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_STORAGE){
                         obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_STORAGE_QUEUE));            
                     }
                     else if(qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_OPOS){                    
                         obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_OPOS_QUEUE));            
                     }
                 }
                }             
        }
        //Level 4
        else if(qliRecord.Requested_Customer_Discount__c > 30 && qliRecord.Requested_Customer_Discount__c <= 100 && qliRecord.Req_WD_Ret_SAC_OnReqDiscBasic__c==0  && qliRecord.Requested_WD_CONT_Req_Disc_Basic__c==0 && qliRecord.Req_Net_Rlizd_Bsc_Disc__c > 30 && qliRecord.Req_Net_Rlizd_Bsc_Disc__c <= 100 ){ 
            if(qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_LAB){
                obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_LAB_QUEUE)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_VP_PERSONA));                                   
            }
            else if(qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_HEALTHCARE){
                obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_HEALTHCARE_QUEUE)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_VP_PERSONA));                               
            }           
            else if(qliRecord.Product_Line_c__c==GlobalConstants.Product_Line_B2C || qliRecord.Product_Line_c__c==GlobalConstants.Product_Line_WSA){
                obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_B2C_QUEUE)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_VP_PERSONA));                                 
            } 
            else{if( (qliRecord.Quote.Opportunity.Account.Is_Key_Account__c || qliRecord.Quote.End_Customer__r.Is_Key_Account__c) &&(qliRecord.Product_Line_c__c != GlobalConstants.Product_Line_LAB || qliRecord.Product_Line_c__c != GlobalConstants.Product_Line_HEALTHCARE || qliRecord.Product_Line_c__c !=GlobalConstants.Product_Line_B2C || qliRecord.Product_Line_c__c !=GlobalConstants.Product_Line_WSA) ){                
                obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_KAM_QUEUE)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_VP_PERSONA));               
            }
                 if((qliRecord.Quote.Transaction_Type_c__c == GlobalConstants.Transaction_Type_GEM || qliRecord.Quote.Transaction_Type_c__c == GlobalConstants.Transaction_Type_GEM_PAC || qliRecord.Quote.Transaction_Type_c__c == GlobalConstants.Transaction_Type_GEM_RC) && !qliRecord.Quote.Opportunity.Account.Is_Key_Account__c){
                     obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_GEM_RC_QUEUE)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_VP_PERSONA));                                   
                 }
                 else if(qliRecord.Quote.Interio_Sub_Division__c ==GlobalConstants.Interio_Sub_Division_B2B_NON_KAM && isProductLineMatched(qliRecord.Product_Line_c__c) && !qliRecord.Quote.Opportunity.Account.Is_Key_Account__c && !qliRecord.Quote.End_Customer__r.Is_Key_Account__c){
                     if(qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_SEATING){
                         obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_SEATING_QUEUE)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_VP_PERSONA));              
                     }
                     else if(qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_DESKING ){
                         obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_DESKING_QUEUE)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_VP_PERSONA));                    
                     }
                     else if(qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_STORAGE){
                         obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_STORAGE_QUEUE)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_VP_PERSONA));                    
                     }
                     else if(qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_OPOS){
                         obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_OPOS_QUEUE)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_VP_PERSONA));             
                     }
                 }
                 
                }            
        }
        //Level 5
        else if(qliRecord.Requested_Customer_Discount__c >=0 && qliRecord.Req_WD_Ret_SAC_OnReqDiscBasic__c==0  && qliRecord.Requested_WD_CONT_Req_Disc_Basic__c > 0 && qliRecord.Requested_WD_CONT_Req_Disc_Basic__c <= 10){ 
            if(qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_LAB){
                obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_LAB_QUEUE)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_VP_PERSONA));                                   
            }
            else if(qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_HEALTHCARE){
                obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_HEALTHCARE_QUEUE)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_VP_PERSONA));                              
            }            
            else if(qliRecord.Product_Line_c__c==GlobalConstants.Product_Line_B2C || qliRecord.Product_Line_c__c==GlobalConstants.Product_Line_WSA){
                obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_B2C_QUEUE)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_VP_PERSONA));                                 
            } 
            else{if( (qliRecord.Quote.Opportunity.Account.Is_Key_Account__c || qliRecord.Quote.End_Customer__r.Is_Key_Account__c) &&(qliRecord.Product_Line_c__c != GlobalConstants.Product_Line_LAB || qliRecord.Product_Line_c__c != GlobalConstants.Product_Line_HEALTHCARE || qliRecord.Product_Line_c__c !=GlobalConstants.Product_Line_B2C || qliRecord.Product_Line_c__c !=GlobalConstants.Product_Line_WSA) ){                
                obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_KAM_QUEUE)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_VP_PERSONA));         
            } 
                 if((qliRecord.Quote.Transaction_Type_c__c == GlobalConstants.Transaction_Type_GEM || qliRecord.Quote.Transaction_Type_c__c == GlobalConstants.Transaction_Type_GEM_PAC || qliRecord.Quote.Transaction_Type_c__c == GlobalConstants.Transaction_Type_GEM_RC) && !qliRecord.Quote.Opportunity.Account.Is_Key_Account__c && !qliRecord.Quote.End_Customer__r.Is_Key_Account__c){
                     obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_GEM_RC_QUEUE)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_VP_PERSONA));                                
                 }
                 
                 else if(qliRecord.Quote.Interio_Sub_Division__c ==GlobalConstants.Interio_Sub_Division_B2B_NON_KAM && isProductLineMatched(qliRecord.Product_Line_c__c)&& !qliRecord.Quote.Opportunity.Account.Is_Key_Account__c && !qliRecord.Quote.End_Customer__r.Is_Key_Account__c){
                     if(qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_SEATING){
                         obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_SEATING_QUEUE)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_VP_PERSONA));              
                     }
                     else if(qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_DESKING ){
                         obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_DESKING_QUEUE)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_VP_PERSONA));            
                     }
                     else if(qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_STORAGE){
                         obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_STORAGE_QUEUE)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_VP_PERSONA));            
                     }
                     else if(qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_OPOS){
                         obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_OPOS_QUEUE)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_VP_PERSONA));              
                     }
                 }
                }         
        } 
        //Level 6
        else if(qliRecord.Requested_Customer_Discount__c ==0 && qliRecord.Req_WD_Ret_SAC_OnReqDiscBasic__c==0  && qliRecord.Requested_WD_CONT_Req_Disc_Basic__c > 10){ 
            if(qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_LAB){
                obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_LAB_QUEUE)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_VP_PERSONA)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_BH_PERSONA));                                    
            }
            else if(qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_HEALTHCARE){
                obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_HEALTHCARE_QUEUE)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_VP_PERSONA)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_BH_PERSONA));                             
            }
            else if(qliRecord.Product_Line_c__c==GlobalConstants.Product_Line_B2C || qliRecord.Product_Line_c__c==GlobalConstants.Product_Line_WSA){
                obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_B2C_QUEUE)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_VP_PERSONA)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_BH_PERSONA));                                 
            }  
            else{if(( qliRecord.Quote.Opportunity.Account.Is_Key_Account__c || qliRecord.Quote.End_Customer__r.Is_Key_Account__c) &&(qliRecord.Product_Line_c__c != GlobalConstants.Product_Line_LAB || qliRecord.Product_Line_c__c != GlobalConstants.Product_Line_HEALTHCARE || qliRecord.Product_Line_c__c !=GlobalConstants.Product_Line_B2C || qliRecord.Product_Line_c__c !=GlobalConstants.Product_Line_WSA) ){                
                obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_KAM_QUEUE)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_VP_PERSONA)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_BH_PERSONA));           
            } 
                 if(qliRecord.Quote.Transaction_Type_c__c == GlobalConstants.Transaction_Type_GEM || qliRecord.Quote.Transaction_Type_c__c == GlobalConstants.Transaction_Type_GEM_PAC || qliRecord.Quote.Transaction_Type_c__c == GlobalConstants.Transaction_Type_GEM_RC){
                     obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_GEM_RC_QUEUE)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_VP_PERSONA)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_BH_PERSONA));                                  
                 }
                 else if(qliRecord.Quote.Interio_Sub_Division__c ==GlobalConstants.Interio_Sub_Division_B2B_NON_KAM && isProductLineMatched(qliRecord.Product_Line_c__c)&& !qliRecord.Quote.Opportunity.Account.Is_Key_Account__c && !qliRecord.Quote.End_Customer__r.Is_Key_Account__c){
                     if(qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_SEATING){
                         obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_SEATING_QUEUE)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_VP_PERSONA)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_BH_PERSONA));              
                     }
                     else if(qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_DESKING ){
                         obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_DESKING_QUEUE)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_VP_PERSONA)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_BH_PERSONA));              
                     }
                     else if(qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_STORAGE){
                         obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_STORAGE_QUEUE)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_VP_PERSONA)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_BH_PERSONA));              
                     }
                     else if(qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_OPOS){                   
                         obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_OPOS_QUEUE)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_VP_PERSONA)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_BH_PERSONA));                 
                     }
                 }
                }         
        }
        //Level 7
        else if(qliRecord.Req_WD_Ret_SAC_OnReqDiscBasic__c > 0  && qliRecord.Requested_WD_CONT_Req_Disc_Basic__c == 0){ 
            if(qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_LAB){
                obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_LAB_QUEUE)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_VP_PERSONA));                                   
            }
            else if(qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_HEALTHCARE){
                obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_HEALTHCARE_QUEUE)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_VP_PERSONA));                                        
            }           
            else if(qliRecord.Product_Line_c__c==GlobalConstants.Product_Line_B2C || qliRecord.Product_Line_c__c==GlobalConstants.Product_Line_WSA){
                obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_B2C_QUEUE)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_VP_PERSONA));                                
            }
            else{if( (qliRecord.Quote.Opportunity.Account.Is_Key_Account__c || qliRecord.Quote.End_Customer__r.Is_Key_Account__c) &&(qliRecord.Product_Line_c__c != GlobalConstants.Product_Line_LAB || qliRecord.Product_Line_c__c != GlobalConstants.Product_Line_HEALTHCARE || qliRecord.Product_Line_c__c !=GlobalConstants.Product_Line_B2C || qliRecord.Product_Line_c__c !=GlobalConstants.Product_Line_WSA) ){                
                obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_KAM_QUEUE)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_VP_PERSONA));         
            } 
                 if((qliRecord.Quote.Transaction_Type_c__c == GlobalConstants.Transaction_Type_GEM || qliRecord.Quote.Transaction_Type_c__c == GlobalConstants.Transaction_Type_GEM_PAC || qliRecord.Quote.Transaction_Type_c__c == GlobalConstants.Transaction_Type_GEM_RC) && !qliRecord.Quote.Opportunity.Account.Is_Key_Account__c && !qliRecord.Quote.End_Customer__r.Is_Key_Account__c){
                     obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_GEM_RC_QUEUE)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_VP_PERSONA));                               
                 }
                 else if(qliRecord.Quote.Interio_Sub_Division__c ==GlobalConstants.Interio_Sub_Division_B2B_NON_KAM && isProductLineMatched(qliRecord.Product_Line_c__c) && !qliRecord.Quote.Opportunity.Account.Is_Key_Account__c && !qliRecord.Quote.End_Customer__r.Is_Key_Account__c){
                     if(qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_SEATING){
                         obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_SEATING_QUEUE)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_VP_PERSONA));               
                     }
                     else if(qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_DESKING ){
                         obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_DESKING_QUEUE)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_VP_PERSONA));              
                     }
                     else if(qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_STORAGE){
                         obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_STORAGE_QUEUE)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_VP_PERSONA));              
                     }
                     else if(qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_OPOS){
                         obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_OPOS_QUEUE)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_VP_PERSONA));               
                     }
                 }
                }         
        }
        //Level 8
        else if(qliRecord.Req_WD_Ret_SAC_OnReqDiscBasic__c > 0  && qliRecord.Requested_WD_CONT_Req_Disc_Basic__c > 0 && qliRecord.Requested_WD_CONT_Req_Disc_Basic__c <= 10){ 
            if(qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_LAB){
                obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_LAB_QUEUE)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_VP_PERSONA));                                   
            }
            else if(qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_HEALTHCARE){
                obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_HEALTHCARE_QUEUE)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_VP_PERSONA));                                        
            }           
            else if(qliRecord.Product_Line_c__c==GlobalConstants.Product_Line_B2C || qliRecord.Product_Line_c__c==GlobalConstants.Product_Line_WSA){
                obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_B2C_QUEUE)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_VP_PERSONA));                                
            }
            else{if( (qliRecord.Quote.Opportunity.Account.Is_Key_Account__c || qliRecord.Quote.End_Customer__r.Is_Key_Account__c) &&(qliRecord.Product_Line_c__c != GlobalConstants.Product_Line_LAB || qliRecord.Product_Line_c__c != GlobalConstants.Product_Line_HEALTHCARE || qliRecord.Product_Line_c__c !=GlobalConstants.Product_Line_B2C || qliRecord.Product_Line_c__c !=GlobalConstants.Product_Line_WSA) ){                
                obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_KAM_QUEUE)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_VP_PERSONA));         
            } 
                 if((qliRecord.Quote.Transaction_Type_c__c == GlobalConstants.Transaction_Type_GEM || qliRecord.Quote.Transaction_Type_c__c == GlobalConstants.Transaction_Type_GEM_PAC || qliRecord.Quote.Transaction_Type_c__c == GlobalConstants.Transaction_Type_GEM_RC) && !qliRecord.Quote.Opportunity.Account.Is_Key_Account__c && !qliRecord.Quote.End_Customer__r.Is_Key_Account__c){
                     obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_GEM_RC_QUEUE)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_VP_PERSONA));                               
                 }
                 
                 else if(qliRecord.Quote.Interio_Sub_Division__c ==GlobalConstants.Interio_Sub_Division_B2B_NON_KAM && isProductLineMatched(qliRecord.Product_Line_c__c) && !qliRecord.Quote.Opportunity.Account.Is_Key_Account__c && !qliRecord.Quote.End_Customer__r.Is_Key_Account__c){
                     if(qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_SEATING){
                         obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_SEATING_QUEUE)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_VP_PERSONA));               
                     }
                     else if(qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_DESKING ){
                         obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_DESKING_QUEUE)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_VP_PERSONA));              
                     }
                     else if(qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_STORAGE){
                         obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_STORAGE_QUEUE)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_VP_PERSONA));              
                     }
                     else if(qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_OPOS){
                         obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_OPOS_QUEUE)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_VP_PERSONA));               
                     }
                 }
                }         
        }
        //Level 9
        else if(qliRecord.Requested_WD_CONT_Req_Disc_Basic__c > 10){ 
            
            if(qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_LAB){
                obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_LAB_QUEUE)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_VP_PERSONA)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_BH_PERSONA));                                  
            }
            else if(qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_HEALTHCARE){
                obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_HEALTHCARE_QUEUE)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_VP_PERSONA)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_BH_PERSONA));                              
            }           
            else if(qliRecord.Product_Line_c__c==GlobalConstants.Product_Line_B2C || qliRecord.Product_Line_c__c==GlobalConstants.Product_Line_WSA){
                obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_B2C_QUEUE)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_VP_PERSONA)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_BH_PERSONA));            
            }
            else{if( (qliRecord.Quote.Opportunity.Account.Is_Key_Account__c || qliRecord.Quote.End_Customer__r.Is_Key_Account__c) &&(qliRecord.Product_Line_c__c != GlobalConstants.Product_Line_LAB || qliRecord.Product_Line_c__c != GlobalConstants.Product_Line_HEALTHCARE || qliRecord.Product_Line_c__c !=GlobalConstants.Product_Line_B2C || qliRecord.Product_Line_c__c !=GlobalConstants.Product_Line_WSA) ){                
                obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_KAM_QUEUE)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_VP_PERSONA)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_BH_PERSONA));        
            } 
                 if((qliRecord.Quote.Transaction_Type_c__c == GlobalConstants.Transaction_Type_GEM || qliRecord.Quote.Transaction_Type_c__c == GlobalConstants.Transaction_Type_GEM_PAC || qliRecord.Quote.Transaction_Type_c__c == GlobalConstants.Transaction_Type_GEM_RC) && !qliRecord.Quote.Opportunity.Account.Is_Key_Account__c && !qliRecord.Quote.End_Customer__r.Is_Key_Account__c){
                     obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_GEM_RC_QUEUE)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_VP_PERSONA)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_BH_PERSONA));                                        
                 }
                 else if(qliRecord.Quote.Interio_Sub_Division__c ==GlobalConstants.Interio_Sub_Division_B2B_NON_KAM && isProductLineMatched(qliRecord.Product_Line_c__c) && !qliRecord.Quote.Opportunity.Account.Is_Key_Account__c && !qliRecord.Quote.End_Customer__r.Is_Key_Account__c){
                     if(qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_SEATING){
                         obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_SEATING_QUEUE)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_VP_PERSONA)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_BH_PERSONA));             
                     }
                     else if(qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_DESKING ){
                         obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_DESKING_QUEUE)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_VP_PERSONA)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_BH_PERSONA));             
                     }
                     else if(qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_STORAGE){
                         obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_STORAGE_QUEUE)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_VP_PERSONA)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_BH_PERSONA));             
                     }
                     else if(qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_OPOS){
                         obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_OPOS_QUEUE)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_VP_PERSONA)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_BH_PERSONA));         
                     }
                 }
                }          
        }
    }
    
    //DIRECT_BILLING_TO_CUSTOMER_R_SERIES
    public void directBillingToCustomerRSeries(QuoteLineItem qliRecord,Map<String,Id> grpNameVsGrpId){
        UpdateQliListOfApproversHelper obj = new UpdateQliListOfApproversHelper();
        //Level 1
        if(qliRecord.Requested_Customer_Discount__c >= 0 && qliRecord.Req_WD_Ret_SAC_OnReqDiscBasic__c > 0 && qliRecord.Requested_WD_CONT_Req_Disc_Basic__c >= 0  && qliRecord.Requested_WD_CONT_Req_Disc_Basic__c <= 10 && qliRecord.Req_Net_Rlizd_Bsc_Disc__c >= 0){ 
            
            if(qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_LAB){
                obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_LAB_QUEUE)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_VP_PERSONA));                              
            }
            else if(qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_HEALTHCARE){
                obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_HEALTHCARE_QUEUE)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_VP_PERSONA));                                 
            }                            
            else if(qliRecord.Product_Line_c__c==GlobalConstants.Product_Line_B2C || qliRecord.Product_Line_c__c==GlobalConstants.Product_Line_WSA){
                obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_B2C_QUEUE)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_VP_PERSONA));                                 
            }
            else {
                if((qliRecord.Quote.Opportunity.Account.Is_Key_Account__c || qliRecord.Quote.End_Customer__r.Is_Key_Account__c) && (qliRecord.Product_Line_c__c != GlobalConstants.Product_Line_LAB || qliRecord.Product_Line_c__c != GlobalConstants.Product_Line_HEALTHCARE || qliRecord.Product_Line_c__c != GlobalConstants.Product_Line_B2C || qliRecord.Product_Line_c__c !=GlobalConstants.Product_Line_WSA )){                
                    obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_KAM_QUEUE)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_VP_PERSONA));                
                }
                if((qliRecord.Quote.Transaction_Type_c__c == GlobalConstants.Transaction_Type_GEM || qliRecord.Quote.Transaction_Type_c__c == GlobalConstants.Transaction_Type_GEM_PAC || qliRecord.Quote.Transaction_Type_c__c == GlobalConstants.Transaction_Type_GEM_RC) && !qliRecord.Quote.Opportunity.Account.Is_Key_Account__c && !qliRecord.Quote.End_Customer__r.Is_Key_Account__c){
                    obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_GEM_RC_QUEUE)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_VP_PERSONA));                              
                }
                else if(qliRecord.Quote.Interio_Sub_Division__c ==GlobalConstants.Interio_Sub_Division_B2B_NON_KAM && isProductLineMatched(qliRecord.Product_Line_c__c) && !qliRecord.Quote.Opportunity.Account.Is_Key_Account__c && !qliRecord.Quote.End_Customer__r.Is_Key_Account__c){
                    if(qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_SEATING){                                        
                        obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_SEATING_QUEUE)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_VP_PERSONA));           
                    }
                    else if(qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_DESKING){
                        obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_DESKING_QUEUE)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_VP_PERSONA));        
                    }
                    else if(qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_STORAGE){
                        obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_STORAGE_QUEUE)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_VP_PERSONA));        
                    }
                    else if(qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_OPOS){
                        obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_OPOS_QUEUE)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_VP_PERSONA));                      
                    }
                }
            }
        }
        //Level 2
        else if(qliRecord.Requested_Customer_Discount__c >= 0 && qliRecord.Req_WD_Ret_SAC_OnReqDiscBasic__c > 0 && qliRecord.Requested_WD_CONT_Req_Disc_Basic__c > 10 && qliRecord.Req_Net_Rlizd_Bsc_Disc__c >= 0 ){ 
            if(qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_LAB){
                obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_LAB_QUEUE)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_VP_PERSONA)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_BH_PERSONA));                                       
            }
            else if(qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_HEALTHCARE){
                obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_HEALTHCARE_QUEUE)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_VP_PERSONA)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_BH_PERSONA));                                       
            }                            
            else if(qliRecord.Product_Line_c__c==GlobalConstants.Product_Line_B2C || qliRecord.Product_Line_c__c==GlobalConstants.Product_Line_WSA){
                obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_B2C_QUEUE)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_VP_PERSONA)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_BH_PERSONA));                                       
            }
            else{
                if((qliRecord.Quote.Opportunity.Account.Is_Key_Account__c || qliRecord.Quote.End_Customer__r.Is_Key_Account__c) && (qliRecord.Product_Line_c__c != GlobalConstants.Product_Line_LAB || qliRecord.Product_Line_c__c != GlobalConstants.Product_Line_HEALTHCARE || qliRecord.Product_Line_c__c !=GlobalConstants.Product_Line_B2C || qliRecord.Product_Line_c__c !=GlobalConstants.Product_Line_WSA)){                
                    obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_KAM_QUEUE)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_VP_PERSONA)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_BH_PERSONA));                
                }
                
                if((qliRecord.Quote.Transaction_Type_c__c == GlobalConstants.Transaction_Type_GEM || qliRecord.Quote.Transaction_Type_c__c == GlobalConstants.Transaction_Type_GEM_PAC || qliRecord.Quote.Transaction_Type_c__c == GlobalConstants.Transaction_Type_GEM_RC) && !qliRecord.Quote.Opportunity.Account.Is_Key_Account__c && !qliRecord.Quote.End_Customer__r.Is_Key_Account__c){
                    obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_GEM_RC_QUEUE)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_VP_PERSONA)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_BH_PERSONA));                                       
                }
                else if(qliRecord.Quote.Interio_Sub_Division__c ==GlobalConstants.Interio_Sub_Division_B2B_NON_KAM && isProductLineMatched(qliRecord.Product_Line_c__c) && !qliRecord.Quote.Opportunity.Account.Is_Key_Account__c && !qliRecord.Quote.End_Customer__r.Is_Key_Account__c){
                    if(qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_SEATING){
                        obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_SEATING_QUEUE)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_VP_PERSONA)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_BH_PERSONA));                    
                    }
                    else if(qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_DESKING ){
                        obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_DESKING_QUEUE)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_VP_PERSONA)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_BH_PERSONA));                    
                    }
                    else if(qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_STORAGE){
                        obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_STORAGE_QUEUE)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_VP_PERSONA)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_BH_PERSONA));                    
                    }
                    else if(qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_OPOS){
                        obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_OPOS_QUEUE)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_VP_PERSONA)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_BH_PERSONA));               
                    }
                }
            } 
        }       
    }
    /*---------------------------------------------------------------------------
If transaction type = Scheme, OR WD Display OR   
Stock Liquidation and Order type= Direct Billing To Customer (W Series)  
-----------------------------------------------------------------------------*/
    public void DIRECT_BILLING_TO_CUSTOMER_W_SERIES(QuoteLineItem qliRecord,Map<String,Id> grpNameVsGrpId){  
        
        UpdateQliListOfApproversHelper obj = new UpdateQliListOfApproversHelper();
        isTranTypeMatched = isTransactionTypeMatched(qliRecord.Quote.Transaction_Type_c__c);
        if(isTranTypeMatched){
            //Level 1               
            if(qliRecord.Req_Net_Rlizd_Bsc_Disc__c > 0 && qliRecord.Req_Net_Rlizd_Bsc_Disc__c <= 15 &&
               ((qliRecord.Quote.Interio_Sub_Division__c ==GlobalConstants.Interio_Sub_Division_B2B_KAM) || ((qliRecord.Quote.Interio_Sub_Division__c == GlobalConstants.Interio_Sub_Division_B2B_NON_KAM) && (qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_DESKING || qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_SEATING || qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_STORAGE || qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_OPOS)) ||
                qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_LAB || qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_HEALTHCARE || qliRecord.Product_Line_c__c==GlobalConstants.Product_Line_B2C || qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_WSA)){ 
                    obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,'');                
                } 
            
            //Level 2
            else if(qliRecord.Req_Net_Rlizd_Bsc_Disc__c > 15 && qliRecord.Req_Net_Rlizd_Bsc_Disc__c <= 30){
                
                if(qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_LAB){
                    obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_LAB_QUEUE));                                       
                }
                else if(qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_HEALTHCARE){
                    obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_HEALTHCARE_QUEUE));                                        
                }
                else if(qliRecord.Product_Line_c__c==GlobalConstants.Product_Line_B2C || qliRecord.Product_Line_c__c==GlobalConstants.Product_Line_WSA){
                    obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_B2C_QUEUE));                                        
                } 
                else if((qliRecord.Quote.Opportunity.Account.Is_Key_Account__c || qliRecord.Quote.End_Customer__r.Is_Key_Account__c) && (qliRecord.Product_Line_c__c != GlobalConstants.Product_Line_LAB || qliRecord.Product_Line_c__c != GlobalConstants.Product_Line_HEALTHCARE || qliRecord.Product_Line_c__c !=GlobalConstants.Product_Line_B2C || qliRecord.Product_Line_c__c !=GlobalConstants.Product_Line_WSA)){                
                    obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_KAM_QUEUE));                
                }   
                
                else if(qliRecord.Quote.Interio_Sub_Division__c ==GlobalConstants.Interio_Sub_Division_B2B_NON_KAM && isProductLineMatched(qliRecord.Product_Line_c__c) && !qliRecord.Quote.Opportunity.Account.Is_Key_Account__c && !qliRecord.Quote.End_Customer__r.Is_Key_Account__c){
                    if(qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_SEATING){
                        obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_SEATING_QUEUE));                
                    }
                    else if(qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_DESKING ){
                        obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_DESKING_QUEUE));                    
                    }
                    else if(qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_STORAGE){
                        obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_STORAGE_QUEUE));                    
                        
                    }
                    else if(qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_OPOS){
                        obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_OPOS_QUEUE));                    
                    }
                }
            }
            //Level 3
            else if(qliRecord.Req_Net_Rlizd_Bsc_Disc__c > 30){ 
                if(qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_LAB){
                    obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_LAB_QUEUE)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_VP_PERSONA));                                       
                }
                else if(qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_HEALTHCARE){
                    obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_HEALTHCARE_QUEUE)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_VP_PERSONA));                                        
                }               
                else if(qliRecord.Product_Line_c__c==GlobalConstants.Product_Line_B2C || qliRecord.Product_Line_c__c==GlobalConstants.Product_Line_WSA){
                    obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_B2C_QUEUE)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_VP_PERSONA));                                        
                }
                else if((qliRecord.Quote.Opportunity.Account.Is_Key_Account__c || qliRecord.Quote.End_Customer__r.Is_Key_Account__c) && (qliRecord.Product_Line_c__c != GlobalConstants.Product_Line_LAB || qliRecord.Product_Line_c__c != GlobalConstants.Product_Line_HEALTHCARE || qliRecord.Product_Line_c__c !=GlobalConstants.Product_Line_B2C || qliRecord.Product_Line_c__c !=GlobalConstants.Product_Line_WSA)){                
                    obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_KAM_QUEUE)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_VP_PERSONA));                
                } 
                else if(qliRecord.Quote.Interio_Sub_Division__c ==GlobalConstants.Interio_Sub_Division_B2B_NON_KAM && isProductLineMatched(qliRecord.Product_Line_c__c) && !qliRecord.Quote.Opportunity.Account.Is_Key_Account__c && !qliRecord.Quote.End_Customer__r.Is_Key_Account__c){
                    if(qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_SEATING){
                        obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_SEATING_QUEUE)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_VP_PERSONA));                
                    }
                    else if(qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_DESKING ){
                        obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_DESKING_QUEUE)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_VP_PERSONA));                    
                    }
                    else if(qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_STORAGE){
                        obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_STORAGE_QUEUE)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_VP_PERSONA));                    
                    }
                    else if(qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_OPOS){
                        obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_OPOS_QUEUE)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_VP_PERSONA));                    
                    }
                }
            }
        }else{
            /*---------------------------------------------------------------------------
If transaction type= IS OTHER THAN Scheme, OR WD Display OR   
Stock Liquidation and Order type= Direct Billing To Customer (W Series)  
-----------------------------------------------------------------------------*/
            //Level 1               
            if(qliRecord.Requested_WD_CONT_Req_Disc_Basic__c == 0 && qliRecord.Req_Net_Rlizd_Bsc_Disc__c > 0 && qliRecord.Req_Net_Rlizd_Bsc_Disc__c <= 15 && !isTransactionTypeMatched(qliRecord.Quote.Transaction_Type_c__c)&&
               ((qliRecord.Quote.Interio_Sub_Division__c ==GlobalConstants.Interio_Sub_Division_B2B_KAM) || ((qliRecord.Quote.Interio_Sub_Division__c == GlobalConstants.Interio_Sub_Division_B2B_NON_KAM) && (qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_DESKING || qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_SEATING || qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_STORAGE || qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_OPOS)) ||
                (qliRecord.Quote.Transaction_Type_c__c == GlobalConstants.Transaction_Type_GEM || qliRecord.Quote.Transaction_Type_c__c == GlobalConstants.Transaction_Type_GEM_PAC || qliRecord.Quote.Transaction_Type_c__c == GlobalConstants.Transaction_Type_GEM_RC) ||
                qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_LAB || qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_HEALTHCARE || qliRecord.Product_Line_c__c==GlobalConstants.Product_Line_B2C || qliRecord.Product_Line_c__c==GlobalConstants.Product_Line_WSA)){ 
                    obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,'');                
                } 
            
            //Level 2
            else if(qliRecord.Requested_WD_CONT_Req_Disc_Basic__c == 0 && qliRecord.Req_Net_Rlizd_Bsc_Disc__c > 15 && qliRecord.Req_Net_Rlizd_Bsc_Disc__c <= 30){               
                if(qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_LAB){
                    obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_LAB_QUEUE));                                       
                }
                else if(qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_HEALTHCARE){
                    obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_HEALTHCARE_QUEUE));                                        
                }
                else if(qliRecord.Product_Line_c__c==GlobalConstants.Product_Line_B2C || qliRecord.Product_Line_c__c==GlobalConstants.Product_Line_WSA){
                    obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_B2C_QUEUE));                                        
                } 
                else{
                    if((qliRecord.Quote.Opportunity.Account.Is_Key_Account__c || qliRecord.Quote.End_Customer__r.Is_Key_Account__c) && (qliRecord.Product_Line_c__c != GlobalConstants.Product_Line_LAB || qliRecord.Product_Line_c__c != GlobalConstants.Product_Line_HEALTHCARE || qliRecord.Product_Line_c__c !=GlobalConstants.Product_Line_B2C || qliRecord.Product_Line_c__c !=GlobalConstants.Product_Line_WSA)){                
                        obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_KAM_QUEUE));                
                    } 
                    
                    if((qliRecord.Quote.Transaction_Type_c__c == GlobalConstants.Transaction_Type_GEM || qliRecord.Quote.Transaction_Type_c__c == GlobalConstants.Transaction_Type_GEM_PAC || qliRecord.Quote.Transaction_Type_c__c == GlobalConstants.Transaction_Type_GEM_RC) && !qliRecord.Quote.Opportunity.Account.Is_Key_Account__c && !qliRecord.Quote.End_Customer__r.Is_Key_Account__c){
                        obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_GEM_RC_QUEUE));                                        
                    }
                    else if(qliRecord.Quote.Interio_Sub_Division__c ==GlobalConstants.Interio_Sub_Division_B2B_NON_KAM && isProductLineMatched(qliRecord.Product_Line_c__c) && !qliRecord.Quote.Opportunity.Account.Is_Key_Account__c && !qliRecord.Quote.End_Customer__r.Is_Key_Account__c){
                        if(qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_SEATING){
                            obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_SEATING_QUEUE));                
                        }
                        else if(qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_DESKING ){
                            obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_DESKING_QUEUE));                    
                        }
                        else if(qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_STORAGE){
                            obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_STORAGE_QUEUE));                    
                        }
                        else if(qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_OPOS){
                            obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_OPOS_QUEUE));                    
                        }
                    }
                }          
            }
            //Level 3
            else if((qliRecord.Requested_WD_CONT_Req_Disc_Basic__c == 0 && qliRecord.Req_Net_Rlizd_Bsc_Disc__c > 30 && qliRecord.Req_Net_Rlizd_Bsc_Disc__c <= 100) || (qliRecord.Requested_WD_CONT_Req_Disc_Basic__c > 0 && qliRecord.Requested_WD_CONT_Req_Disc_Basic__c <= 10 && qliRecord.Req_Net_Rlizd_Bsc_Disc__c > 0 && qliRecord.Req_Net_Rlizd_Bsc_Disc__c <= 100)){ 
                
                if(qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_LAB){
                    obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_LAB_QUEUE)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_VP_PERSONA));                                       
                }
                else if(qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_HEALTHCARE){
                    obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_HEALTHCARE_QUEUE)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_VP_PERSONA));                                        
                }               
                else if(qliRecord.Product_Line_c__c==GlobalConstants.Product_Line_B2C || qliRecord.Product_Line_c__c==GlobalConstants.Product_Line_WSA){
                    obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_B2C_QUEUE)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_VP_PERSONA));                                        
                }
                else{
                    if((qliRecord.Quote.Opportunity.Account.Is_Key_Account__c || qliRecord.Quote.End_Customer__r.Is_Key_Account__c) && (qliRecord.Product_Line_c__c != GlobalConstants.Product_Line_LAB || qliRecord.Product_Line_c__c != GlobalConstants.Product_Line_HEALTHCARE || qliRecord.Product_Line_c__c !=GlobalConstants.Product_Line_B2C || qliRecord.Product_Line_c__c !=GlobalConstants.Product_Line_WSA)){                
                        obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_KAM_QUEUE)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_VP_PERSONA));                
                    } 
                    
                    if((qliRecord.Quote.Transaction_Type_c__c == GlobalConstants.Transaction_Type_GEM || qliRecord.Quote.Transaction_Type_c__c == GlobalConstants.Transaction_Type_GEM_PAC || qliRecord.Quote.Transaction_Type_c__c == GlobalConstants.Transaction_Type_GEM_RC) && !qliRecord.Quote.Opportunity.Account.Is_Key_Account__c && !qliRecord.Quote.End_Customer__r.Is_Key_Account__c){
                        obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_GEM_RC_QUEUE)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_VP_PERSONA));                                        
                    }
                    else if(qliRecord.Quote.Interio_Sub_Division__c ==GlobalConstants.Interio_Sub_Division_B2B_NON_KAM && isProductLineMatched(qliRecord.Product_Line_c__c) && !qliRecord.Quote.Opportunity.Account.Is_Key_Account__c && !qliRecord.Quote.End_Customer__r.Is_Key_Account__c){
                        if(qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_SEATING){
                            obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_SEATING_QUEUE)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_VP_PERSONA));                
                        }
                        else if(qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_DESKING ){
                            obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_DESKING_QUEUE)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_VP_PERSONA));                    
                        }
                        else if(qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_STORAGE){
                            obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_STORAGE_QUEUE)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_VP_PERSONA));                    
                        }
                        else if(qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_OPOS){
                            obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_OPOS_QUEUE)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_VP_PERSONA));                    
                        }
                    }
                }
            }
            
            //Level 4
            else if(qliRecord.Requested_WD_CONT_Req_Disc_Basic__c > 10 && qliRecord.Req_Net_Rlizd_Bsc_Disc__c > 0 && qliRecord.Req_Net_Rlizd_Bsc_Disc__c <= 100){ 
                if(qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_LAB){
                    obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_LAB_QUEUE)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_VP_PERSONA)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_BH_PERSONA));                                  
                }
                else if(qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_HEALTHCARE){
                    obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_HEALTHCARE_QUEUE)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_VP_PERSONA)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_BH_PERSONA));                              
                }               
                else if(qliRecord.Product_Line_c__c==GlobalConstants.Product_Line_B2C || qliRecord.Product_Line_c__c==GlobalConstants.Product_Line_WSA){
                    obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_B2C_QUEUE)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_VP_PERSONA)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_BH_PERSONA));            
                }
                else{
                    if((qliRecord.Quote.Opportunity.Account.Is_Key_Account__c || qliRecord.Quote.End_Customer__r.Is_Key_Account__c) && (qliRecord.Product_Line_c__c != GlobalConstants.Product_Line_LAB || qliRecord.Product_Line_c__c != GlobalConstants.Product_Line_HEALTHCARE || qliRecord.Product_Line_c__c !=GlobalConstants.Product_Line_B2C || qliRecord.Product_Line_c__c !=GlobalConstants.Product_Line_WSA)){                
                        obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_KAM_QUEUE)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_VP_PERSONA)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_BH_PERSONA));        
                    } 
                    
                    if((qliRecord.Quote.Transaction_Type_c__c == GlobalConstants.Transaction_Type_GEM || qliRecord.Quote.Transaction_Type_c__c == GlobalConstants.Transaction_Type_GEM_PAC || qliRecord.Quote.Transaction_Type_c__c == GlobalConstants.Transaction_Type_GEM_RC) && !qliRecord.Quote.Opportunity.Account.Is_Key_Account__c && !qliRecord.Quote.End_Customer__r.Is_Key_Account__c){
                        obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_GEM_RC_QUEUE)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_VP_PERSONA)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_BH_PERSONA));                                        
                    }
                    else if(qliRecord.Quote.Interio_Sub_Division__c ==GlobalConstants.Interio_Sub_Division_B2B_NON_KAM && isProductLineMatched(qliRecord.Product_Line_c__c) && !qliRecord.Quote.Opportunity.Account.Is_Key_Account__c && !qliRecord.Quote.End_Customer__r.Is_Key_Account__c){
                        if(qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_SEATING){
                            obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_SEATING_QUEUE)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_VP_PERSONA)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_BH_PERSONA));             
                        }
                        else if(qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_DESKING ){
                            obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_DESKING_QUEUE)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_VP_PERSONA)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_BH_PERSONA));             
                        }
                        else if(qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_STORAGE){
                            obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_STORAGE_QUEUE)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_VP_PERSONA)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_BH_PERSONA));             
                        }
                        else if(qliRecord.Product_Line_c__c== GlobalConstants.Product_Line_OPOS){
                            obj.handleAssignment(GlobalConstants.Interio_ZH_PERSONA,qliRecord,1,grpNameVsGrpId.get(GlobalConstants.Interio_B2B_OPOS_QUEUE)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_VP_PERSONA)+GlobalConstants.Commas+grpNameVsGrpId.get(GlobalConstants.Interio_BH_PERSONA));         
                        }
                    }
                }
            }
        }
    }
    Private Boolean isTransactionTypeMatched(String TransactionType){        
        Boolean isTranTypeMatched = (TransactionType == GlobalConstants.Transaction_Type_Scheme || TransactionType == GlobalConstants.Transaction_Type_WD_Display || TransactionType == GlobalConstants.Transaction_Type_Stock_Liquidation) ? true : false;
        return isTranTypeMatched; 
    }
    Private Boolean isProductLineMatched(String productLine){ 
        Boolean isProdLineMatched = (productLine == GlobalConstants.Product_Line_SEATING || productLine == GlobalConstants.Product_Line_DESKING || productLine == GlobalConstants.Product_Line_STORAGE || productLine == GlobalConstants.Product_Line_OPOS || productLine == GlobalConstants.Product_Line_WSA) ? true : false;
        return isProdLineMatched; 
    }
}