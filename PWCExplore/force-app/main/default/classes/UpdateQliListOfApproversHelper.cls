/*------------------------------------------------------------------------
Author:        Pankaj Meshram
Company:       GITL
Description:   Processor class for 'Quote Line Item' Records
Inputs:        List of QLI
Test Class:    
History
14-09-2022     Pankaj Meshram     Initial Release
16-09-2022     Last modified
29-09-2022     Last modified
02-11-2022     Last modified      Added new method for W Series and removed old methods
----------------------------------------------------------------------------*/
public class UpdateQliListOfApproversHelper {   
    Map<id,QuoteLineItem> IdVsQLIs = new Map<id,QuoteLineItem>();
    Map<String,Id> grpNameVsGrpId = new Map<String,Id>();
    Map<String,Integer> personaOrderedMap = new Map<String,Integer>();
	//Map<Id,String> UserNameVsId = new Map<Id,String>();
    public List<QuoteLineItem>  updateDirectBillingCust(List<QuoteLineItem> newQLIRecords){
        personaMap();
        for(Group grpVar:[select Id,name from Group where  Type = 'Queue' AND NAME like '%Interio B2B%']){
            grpNameVsGrpId.put(grpVar.Name,grpVar.id);
        } 
        for(User userVar:[select Id,name,UserName,Persona__c from user where Business_unit__c='W' and (Persona__c=:GlobalConstants.Interio_VP_PERSONA OR Persona__c=:GlobalConstants.Interio_BH_PERSONA)]){       
            grpNameVsGrpId.put(userVar.Persona__c,userVar.id);           
        }
          
        for(QuoteLineItem qliVar:newQLIRecords){
            UpdateQliListOfApprovers updateQli = new UpdateQliListOfApprovers();
            qliVar.List_of_Approvers__c= '';
            if(qliVar.Quote_Record_Type__c == GlobalConstants.Interio_B2B_Finished_Good_RT && qliVar.Order_Type__c != Null){                  
                if(qliVar.Order_Type__c == GlobalConstants.DIRECT_BILLING_TO_CUSTOMER){                     
                    updateQli.updateDirectBillingCustomer(qliVar,grpNameVsGrpId);
                }
                else if(qliVar.Order_Type__c == GlobalConstants.DIRECT_BILLING_TO_CUSTOMER_R_SERIES){                  
                    updateQli.directBillingToCustomerRSeries(qliVar,grpNameVsGrpId);                       
                }
                else if(qliVar.Order_Type__c == GlobalConstants.DIRECT_BILLING_TO_CUSTOMER_W_SERIES){                    
                    updateQli.DIRECT_BILLING_TO_CUSTOMER_W_SERIES(qliVar,grpNameVsGrpId);                       
                }
            }            
        }//end of for
        return newQLIRecords;
    }//end of method  
    
    private void personaMap(){
        personaOrderedMap.put('Sales Person',1);
        personaOrderedMap.put('Manager',2);
        personaOrderedMap.put('Regional Manager',3);
        personaOrderedMap.put('Zonal Head',4);
        personaOrderedMap.put('Head Officer',5);
        personaOrderedMap.put('Vice President',6);
        personaOrderedMap.put('Business Head',7);
    }



    public void handleAssignment(String lastPersona,QuoteLineItem qliRecord,integer index,String hoQueue){
        personaMap();
        String currentPersona='';
        String currentUserId='';
        String currentOwnerName='';
        if(index==1){
            if(String.isEmpty(qliRecord.Quote.Opportunity.Owner.ManagerId)){
                        //through error
            }else{
                currentPersona = qliRecord.Quote.Opportunity.Owner.Manager.Persona__c;
                currentUserId = qliRecord.Quote.Opportunity.Owner.ManagerId;
                currentOwnerName = qliRecord.Quote.Opportunity.Owner.Manager.Name;
            }
        }else if(index==2){
            if(String.isEmpty(qliRecord.Quote.Opportunity.Owner.Manager.ManagerId)){
                        //through error
            }else{
                currentPersona = qliRecord.Quote.Opportunity.Owner.Manager.Manager.Persona__c;
                currentUserId = qliRecord.Quote.Opportunity.Owner.Manager.ManagerId;
                currentOwnerName = qliRecord.Quote.Opportunity.Owner.Manager.Manager.Name;
            }
        }else if(index==3){
            system.debug('i am in index 3');
            if(String.isEmpty(qliRecord.Quote.Opportunity.Owner.Manager.Manager.ManagerId)){
                        //through error
            }else{                
                    currentPersona = qliRecord.Quote.Opportunity.Owner.Manager.Manager.Manager.Persona__c;
                    currentUserId = qliRecord.Quote.Opportunity.Owner.Manager.Manager.ManagerId;
                    currentOwnerName = qliRecord.Quote.Opportunity.Owner.Manager.Manager.Manager.Name;                
            }
        }
        else{            
            return ;
            
        }
        
        //Add error message Map must contains both persona
        System.debug('currentPersona: '+personaOrderedMap.get(currentPersona));
        System.debug('lastPersona: '+personaOrderedMap.get(lastPersona));
        if(personaOrderedMap.get(currentPersona) <= personaOrderedMap.get(lastPersona)){ 
        	if(hoQueue != '' && currentPersona == GlobalConstants.Interio_ZH_PERSONA){
				currentUserId=currentUserId+GlobalConstants.Commas+hoQueue;
			}
            qliRecord.List_of_Approvers__c = String.isEmpty(qliRecord.List_of_Approvers__c)?currentUserId: (qliRecord.List_of_Approvers__c+GlobalConstants.Commas+currentUserId) ; 
            
           /* if(qliRecord.Current_Approver__c== currentUserId){
                if(qliRecord.Pending_with_owner__c != ''){
                    qliRecord.Pending_with_owner__c = '';
                }
                qliRecord.Pending_with_owner__c = currentOwnerName;
                
            }*/
            
            index++;
            handleAssignment(lastPersona,qliRecord,index,hoQueue);
        }else{
            return ;
        }
        System.debug('list approval:: '+qliRecord.List_of_Approvers__c);
    }


}