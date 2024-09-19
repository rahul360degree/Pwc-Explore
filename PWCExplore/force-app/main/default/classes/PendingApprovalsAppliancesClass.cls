/**
* @Author            : Ashwin Thale
* @class name  : PendingApprovalsAppliancesClass.apxc
* @description  : 
* @created date  : 14-11-2023
* @last modified on  : 20-12-2023
* @last modified by  : Ashwin Thale
* Modifications Log	 : Additional code added for Order Planned Delivery Date Update.
* Ver   Date         Author          Modification
* 1.0   14-11-2023   Ashwin Thale   Initial Version
**/

public with sharing class PendingApprovalsAppliancesClass {
    
    @AuraEnabled public List<ProcessInstanceStep> procInstStepsList;
    @AuraEnabled public List<ProcessInstanceWorkitem> procInstWorkItemList;
    @AuraEnabled public List<Order> ordList;
    
    @AuraEnabled 
    public static PendingApprovalsAppliancesClass doInit(String sObjectName) {
        return new PendingApprovalsAppliancesClass(sObjectName);
    }
    
    public PendingApprovalsAppliancesClass(String sObjectName) {
        
        String userId = UserInfo.getUserId();
        sObjectName = String.isEmpty(sObjectName)?'Order':sObjectName;  
        
        //Process Instance Work Item
        procInstWorkItemList = getProcessInstanceWorkRecords(sObjectName,userId);//Get Process Instance Work Item List 
        Set<Id> procInstObjIdSet = getProcInstWorkObjectIds(procInstWorkItemList);//Get Process Instance Id Set from Process Instance Work Item
        Set<Id> procInstWrkTargObjIdSet = getProcInstTargObjIds(procInstWorkItemList);//Get Order ID Set from Process Instance Work Item
        
        //Orders
        ordList = getOrderRecords(procInstWrkTargObjIdSet,userId);//Get Order List
        
        //Process Instance Step
        procInstStepsList= getProcessInstanceStepsRecords(sObjectName,procInstObjIdSet);//Get Process Instance Steps
    }
    
    //Process Instance Work Records 
    public List<ProcessInstanceWorkitem> getProcessInstanceWorkRecords(string sObjectName,string userId) {
        try{
            String procInstQuery = ' SELECT Id, ProcessInstanceId, OriginalActorId, ActorId, ProcessInstance.TargetObject.Type, ProcessInstance.TargetObject.Name, ProcessInstance.Status, '
                +'ProcessInstance.ProcessDefinition.DeveloperName, ProcessInstance.ProcessDefinition.Type, ProcessInstance.ProcessDefinition.TableEnumOrId, ProcessInstance.TargetObjectId '
                +'FROM ProcessInstanceWorkitem WHERE ProcessInstance.TargetObject.Type  =: sObjectName AND ActorId =: userId ';
            List<ProcessInstanceWorkitem> procInstRecords = Database.query(procInstQuery);
            return procInstRecords;
        }catch(Exception ex){
            throw new AuraHandledException(ex.getMessage()); 
        }
    } 
    
    //Process Instance Work Object Set
    public Set<Id> getProcInstWorkObjectIds(List<ProcessInstanceWorkitem> procInstWorkItemList){
        try{
            Set<Id> setProcessInstanceId = new Set<Id>();
            for(ProcessInstanceWorkitem procItem:procInstWorkItemList){setProcessInstanceId.add(procItem.ProcessInstanceId);}
            return setProcessInstanceId;
        }catch(Exception ex){
            throw new AuraHandledException(ex.getMessage()); 
        }
    }
    
    //Process Instance Object Set
    public Set<Id> getProcInstTargObjIds(List<ProcessInstanceWorkitem> procInstWorkItemList){
        try{
            Set<Id> setTargetObjectId = new Set<Id>();
            for(ProcessInstanceWorkitem workItem:procInstWorkItemList){setTargetObjectId.add(workItem.ProcessInstance.TargetObjectId);}
            return setTargetObjectId;
        }catch(Exception ex){throw new AuraHandledException(ex.getMessage()); }
    }
    
    //Process Order Records
    public List<Order> getOrderRecords(Set<Id> procInstWrkTargObjIdSet, String userId) {
        try{
            String strBusinessUnit = GlobalConstants.APPLIANCE_BUSINESS_UNIT;
            String ordquery = ' SELECT Id, OwnerId, Business_Unit__c, Account.Name, AccountId, Quote.Name, QuoteId, OrderNumber, OpportunityId, Opportunity.Name, '
                +' Logistics_Company_Branch__c, Sold_to_Business_Partner__c, Sold_to_Business_Partner__r.Name, Planned_Delivery_Date__c, '
                +' Level_1_Approvers__c, Level_2_Approvers__c, Level_3_Approvers__c, Additional_Disc_Percent__c, Total_Percent_Additional_Disc_Appliances__c, '
                +' (SELECT Id, Product2Id, Product2.Name, Product2.Tax_Rate__c, Item_Code__c, Per_Unit_Price__c, OrderId, UnitPrice, Quantity, Discount_Amount_Per_Unit_For_Appliances__c, Applied_Discount_Matrix_Level_2_Amount__c FROM OrderItems) '
                +' FROM Order '
                +' Where ID IN:procInstWrkTargObjIdSet AND (Level_1_Approvers__c =: userId OR Level_2_Approvers__c =: userId OR Level_3_Approvers__c =: userId) '
                +' AND Business_Unit__c =: strBusinessUnit ';
            List<Order> ordRecords = Database.query(ordquery);
            return ordRecords;
        }catch(Exception ex){
            throw new AuraHandledException(ex.getMessage()); 
        }
    } 
    
    //Process Instance Step Records
    public List<ProcessInstanceStep> getProcessInstanceStepsRecords(string sObjectName, Set<Id> procInstObjIdSet) {
        try{
            String procInstQuery = ' SELECT Id, ProcessInstanceId, StepStatus, OriginalActorId, ActorId, Actor.Name, Comments, StepNodeId, '
                +' ProcessInstance.TargetObjectId, ProcessInstance.SubmittedById, ProcessInstance.SubmittedBy.Name, '
                +' ProcessInstance.LastActorId, ProcessInstance.LastActor.Name, ProcessInstance.CompletedDate, CreatedDate '
                +' FROM ProcessInstanceStep '
                +' Where ProcessInstance.TargetObject.Type  =: sObjectName AND ProcessInstanceId IN:procInstObjIdSet '
                +' ORDER BY CreatedDate DESC ';
            List<ProcessInstanceStep> procInstStepsList = Database.query(procInstQuery);
            return procInstStepsList;
        }catch(Exception ex){
            throw new AuraHandledException(ex.getMessage()); 
        }
    }   
    
    //Approve selected items
    @AuraEnabled
    public static boolean submitForApproval(List<String> RecordIds,List<String> OrderIds,string buttonName){
        try {
            String strIdDate,strDate,strOrdId;
            Map<Id,DateTime> mapPlanDevDate = new Map<Id,DateTime>();
            DateTime dateTimeConv;
            
            for(String objOrd:OrderIds) {
                system.debug('objOrder = '+objOrd);
                List<String> idDateList = objOrd.split('-',3);
                if(idDateList.size()>2) {
                    strOrdId=idDateList[1];
                    strDate=idDateList[2];
                    if(String.isNotBlank(strDate)) {
                        dateTimeConv = (DateTime)JSON.deserialize('"'+strDate+'"', DateTime.class);
                        mapPlanDevDate.put(strOrdId,dateTimeConv);
                    }
                }
            }
            
            if(mapPlanDevDate.size()>0) {
				List<Order> lstOrder = [Select Id, Planned_Delivery_Date__c From Order Where ID IN : mapPlanDevDate.keySet()];
                if(lstOrder.size()>0) {
                    
                    for(Order objOrd : lstOrder) {
                        objOrd.Planned_Delivery_Date__c = mapPlanDevDate.get(objOrd.Id);
                    }
                    //Update lstOrder;
                    Database.saveResult[] saveList = Database.update(lstOrder, true);
                    System.debug('DML Result = '+saveList);
                    
                    for(Database.saveResult dmlSuccess: saveList)
                    {
                        if (dmlSuccess.isSuccess())
                        {
                            System.debug('Record was successful = '+dmlSuccess.getID());
                        }
                        else
                        {
                            System.debug('Record was Unsuccessful = '+dmlSuccess.getID()+' because of following errors:');
                            
                            for(Database.error dmlError: dmlSuccess.getErrors())
                            {
                                System.debug(dmlError.getStatusCode()+' '+dmlError.getMessage());
                                System.debug('Fields failed to update are :'+dmlError.getFields());
                            }
                        }
                    }
                }                    
            }
            
            List<Approval.ProcessWorkitemRequest> requests = new List<Approval.ProcessWorkitemRequest>();
            String strIdComment,strComment,strId='';  
            
            for(String objOrd:RecordIds) {
                system.debug('objComment = '+objOrd);
                List<String> idCommentList = objOrd.split('-');
                
                if(idCommentList.size()>1) {
                    strId=idCommentList[0];
                    strComment=idCommentList[1];
                }
                else {
                    strId=idCommentList[0];
                    strComment='';
                }
                
                Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
                req.setWorkitemId(strId);
                
                if(buttonName==GlobalConstants.APPROVED) {  
                    req.setAction('Approve');
                    req.setComments(strComment);
                }
                if(buttonName==GlobalConstants.Rejected) {  
                    req.setAction('Reject');
                    req.setComments(strComment);
                }
                requests.add(req);
            }
            Approval.ProcessResult[] processResults = Approval.process(requests);
            String errorMsg='';
            boolean success=true;
            
            for(Approval.ProcessResult result:processResults){
                if(!result.isSuccess()){
                    for(Database.Error errorList: result.getErrors()){
                        errorMsg +='; '+errorList.getMessage();        
                    }
                }
            }
            
            if(String.isEmpty(errorMsg)) {
                return true;
            }
            else {
                throw new AuraHandledException(errorMsg);
            }
        } 
        catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
}