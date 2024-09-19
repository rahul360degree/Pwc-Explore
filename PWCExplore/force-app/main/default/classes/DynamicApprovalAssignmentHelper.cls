/*------------------------------------------------------------------------
Author:        Subhojit
Company:       Salesforce
Description:   Class to auto approve 'Pricing Approval Request' records
Inputs:        map of created records
Test Class:    AutoApprovalEventTriggerTest

History
04-04-2020      Subhojit     Initial Release
----------------------------------------------------------------------------*/
public with sharing class DynamicApprovalAssignmentHelper{


 public static void allocateApprover(String sSPRRefId, String sQuoteId,String sRecDeveloperName){

     List<Approval_Assignment__mdt> lstSPRRule=new List<Approval_Assignment__mdt>();
     List<Pricing_approval_request__c> lstPAR=new List<Pricing_approval_request__c>();
     List<ProcessInstanceWorkitem> lstPendningApproval=new List<ProcessInstanceWorkitem>();
     List<Group> lstQueue=new List<Group>();
     Set<String> setFields=new Set<String>();
     Set<String> setQueueName=new Set<String>();
     Set<String> setQueueId=new Set<String>();
     Map<String,Id> mapQueueNameId=new map<String,Id>();
     Map<Id,Id> mapExsistingAssignedApprovalQueue=new Map<Id,Id>();
      Map<Id,Id> mapAutoApproveAssignedApprovalQueue=new Map<Id,Id>();
     Map<Id,Approval_Assignment__mdt> mapSPR=new Map<Id,Approval_Assignment__mdt>();
     Map<String,boolean> mapMatchedRule=new Map<String,boolean>();
     List<Approval.ProcessWorkitemRequest> lstAutoApproveItem=new List<Approval.ProcessWorkitemRequest>();
     List<ProcessInstanceWorkitem> lstPIItem=new List<ProcessInstanceWorkitem>();
     String sQuery='SELECT ID,{0} FROM Pricing_approval_request__c WHERE ID=:sSPRRefId';

     lstSPRRule=[select Id,Criteria_Field__c,Criteria_Field_Type__c,Criteria_Operator__c,Criteria_Value__c,Operation_Type__c,RecordType__c,Source_Queue_Name__c,Target_Queue_Name__c
              from Approval_Assignment__mdt where RecordType__c=:sRecDeveloperName];
     lstPendningApproval=[SELECT Id,ActorId,OriginalActorId FROM ProcessInstanceWorkitem where ProcessInstance.TargetObjectId=:sSPRRefId];

     for(Approval_Assignment__mdt oSPRVar: lstSPRRule){
         setFields.add(oSPRVar.Criteria_Field__c);
        if(oSPRVar.Source_Queue_Name__c!=null) 
         setQueueName.add(oSPRVar.Source_Queue_Name__c);
        if(oSPRVar.Target_Queue_Name__c!=null) 
         setQueueName.add(oSPRVar.Target_Queue_Name__c); 
        mapSPR.put(oSPRVar.Id,oSPRVar);
     }
     for(ProcessInstanceWorkitem oPIVar: lstPendningApproval){
         setQueueId.add(oPIVar.ActorId);
         mapExsistingAssignedApprovalQueue.put(oPIVar.ActorId,oPIVar.Id);
         mapAutoApproveAssignedApprovalQueue.put(oPIVar.ActorId,oPIVar.Id);
     }    
     String sQueryField=String.join((new List<String>(setFields)),',');
     system.debug(sQuery);
     sQuery=String.format(sQuery,new List<Object>{sQueryField});
     System.debug(sQuery);
     lstPAR=(List<Pricing_approval_request__c>)Database.query(sQuery);
     lstQueue=[select Id, Name, DeveloperName, Type from Group where Type = 'Queue' and ((DeveloperName IN :setQueueName )or (Id IN :setQueueId))];
     for(group oGRVar: lstQueue){
         mapQueueNameId.put(oGRVar.DeveloperName,oGRVar.Id);
     }
    if(lstPAR.size()>0){ 
     for(Approval_Assignment__mdt oSPRVar: lstSPRRule)
       mapMatchedRule.put(oSPRVar.Id,ruleEvaluator(oSPRVar,lstPAR[0]));
       system.debug(mapMatchedRule);
    

    } 
   
    for(String sSPRId: mapMatchedRule.keySet()){
       
        Approval_Assignment__mdt oSPRRef=mapSPR.get(sSPRId);
         if(!mapMatchedRule.get(sSPRId)) 
           continue;
        if( (oSPRRef.Operation_Type__c=='Reassignment')){
        //Reassignment Block
           string sTargetQueue=oSPRRef.Target_Queue_Name__c;
           String sTargetQueueId=mapQueueNameId.get(sTargetQueue);
           string sSourceQueue=oSPRRef.Source_Queue_Name__c;
           String sSourceQueueId=mapQueueNameId.get(sSourceQueue);
           String sPRItemVar=mapExsistingAssignedApprovalQueue.get(sSourceQueueId);
           mapAutoApproveAssignedApprovalQueue.remove(sSourceQueueId);
           ProcessInstanceWorkitem piWVar=new ProcessInstanceWorkitem(Id=sPRItemVar);
           piWVar.ActorId=sSourceQueueId;
           piWVar.OriginalActorId=sTargetQueueId;
           lstPIItem.add(piWVar);

        }
        else if(oSPRRef.Operation_Type__c=='Assignment'){
        // Assignment Block / Auto Approval Block
           
           string sTargetQueue=oSPRRef.Target_Queue_Name__c;
           String sTargetQueueId=mapQueueNameId.get(sTargetQueue);
         
           mapAutoApproveAssignedApprovalQueue.remove(sTargetQueueId);
            system.debug(mapAutoApproveAssignedApprovalQueue);
              
        }
    }
  
    for(String sAppReqVarId:mapAutoApproveAssignedApprovalQueue.values()){
        Approval.ProcessWorkitemRequest prWkItem = new Approval.ProcessWorkitemRequest();

                prWkItem.setWorkItemID(sAppReqVarId);
                prWkItem.setComments(System.label.System_Approval_Comment);
                prWkItem.setAction('Approve');
                lstAutoApproveItem.add(prWkItem); 
                system.debug(prWkItem);

    }
   
    if(lstPIItem.size()>0)
     update lstPIItem;   // Reassignment
    if(lstAutoApproveItem.size()>0){
      Approval.ProcessResult[] appResult = Approval.process(lstAutoApproveItem); // Auto Approval
      system.debug(appResult);
     } 
 }
  
 @TestVisible private static boolean ruleEvaluator(Approval_Assignment__mdt oSPRRef, Pricing_approval_request__c oPARVar){
     Object FieldvalObj;
     String Fieldval;
     sObject sObjavar=oPARVar;
     if(oSPRRef.Criteria_Field__c.contains('.')){
         String ParentField=oSPRRef.Criteria_Field__c.subStringbefore('.');
         String NextChunkField=oSPRRef.Criteria_Field__c.subStringAfter('.');
         sObjavar=sObjavar.getsObject(ParentField);
         if(sObjavar!=null)
           FieldvalObj=sObjavar.get(NextChunkField);
             
         }
         else{
            FieldvalObj=sObjavar.get(oSPRRef.Criteria_Field__c); 
         }
         
        if(FieldvalObj!=null){
            Fieldval=String.valueOf(FieldvalObj);
            //For Number 
            if(oSPRRef.Criteria_Field_Type__c=='Number'){
                Integer iNumbervar=Integer.valueOf(Fieldval);
                if(oSPRRef.Criteria_Operator__c=='='){
                    if(iNumbervar==Integer.valueOf(oSPRRef.Criteria_Value__c))
                      return true;
                     
                }
                else if(oSPRRef.Criteria_Operator__c=='>='){
                    if(iNumbervar>=Integer.valueOf(oSPRRef.Criteria_Value__c))
                      return true;
                     
                }
                else if(oSPRRef.Criteria_Operator__c=='>'){
                    if(iNumbervar>Integer.valueOf(oSPRRef.Criteria_Value__c))
                      return true;
                     
                }
                 else if(oSPRRef.Criteria_Operator__c=='<'){
                    if(iNumbervar<Integer.valueOf(oSPRRef.Criteria_Value__c))
                      return true;
                     
                }
                else if(oSPRRef.Criteria_Operator__c=='<='){
                    if(iNumbervar<=Integer.valueOf(oSPRRef.Criteria_Value__c))
                      return true;
                     
                }
            }
            //For Decimal
           else  if(oSPRRef.Criteria_Field_Type__c=='Decimal'){
                Decimal dNumbervar=Decimal.valueOf(Fieldval);
                if(oSPRRef.Criteria_Operator__c=='='){
                    if(dNumbervar==Decimal.valueOf(oSPRRef.Criteria_Value__c))
                      return true;
                     
                }
                else if(oSPRRef.Criteria_Operator__c=='>='){
                    if(dNumbervar>=Decimal.valueOf(oSPRRef.Criteria_Value__c))
                      return true;
                     
                }
                else if(oSPRRef.Criteria_Operator__c=='>'){
                    if(dNumbervar>Decimal.valueOf(oSPRRef.Criteria_Value__c))
                      return true;
                     
                }
                 else if(oSPRRef.Criteria_Operator__c=='<'){
                    if(dNumbervar<Decimal.valueOf(oSPRRef.Criteria_Value__c))
                      return true;
                     
                }
                else if(oSPRRef.Criteria_Operator__c=='<='){
                    if(dNumbervar<=Decimal.valueOf(oSPRRef.Criteria_Value__c))
                      return true;
                     
                }
            }
            // For String  
            else  if(oSPRRef.Criteria_Field_Type__c=='Text'){
                String sStringrvar=Fieldval;
                if(oSPRRef.Criteria_Operator__c=='='){
                    if(sStringrvar==String.valueOf(oSPRRef.Criteria_Value__c))
                      return true;
                     
                }
                else if(oSPRRef.Criteria_Operator__c=='!='){
                    if(sStringrvar!=String.valueOf(oSPRRef.Criteria_Value__c))
                      return true;
                     
                }
                
            }
            // For Multiselect
              else  if(oSPRRef.Criteria_Field_Type__c=='Multiselect'){
                String sStringrvar=Fieldval;
                List<String> lstval=oSPRRef.Criteria_Value__c.split(';');
                boolean isMatch=true;
               for(String sCriteriavar: lstval) {
                if(oSPRRef.Criteria_Operator__c=='Contains'){
                    if(!sStringrvar.contains(sCriteriavar))
                      isMatch=false;
                     
                 }
                
               } 
               return isMatch;
            } 
        }
        
  
   return false;

     }






 }