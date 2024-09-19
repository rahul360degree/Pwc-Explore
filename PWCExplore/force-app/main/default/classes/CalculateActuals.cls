/*------------------------------------------------------------------------
Author:        Manasi Londhe
Company:       Salesforce
Description:   batch class to calculate actuals of sales rep.
Inputs:        
Test Class:    CalculateActualsTest
History
30-11-2020      Manasi Londhe     Initial Release
----------------------------------------------------------------------------*/
public with sharing class CalculateActuals implements Database.Batchable<sObject>{
    public Database.QueryLocator start(Database.BatchableContext bc){
        String targetRecordType=GlobalConstants.RECEIVABLE_TARGET;
        String outstandingType=GlobalConstants.RECEIVABLE_TYPE_OUTSTANDING;
        String normType=GlobalConstants.RECEIVABLE_TYPE_NORM;
        return Database.getQueryLocator('Select Id,End_Date__c,Start_Date__c,OwnerId,Owner.Name,Type__c,RecordType.DeveloperName,Sales_Representative__c,Business_Unit__c From Receivable__c Where End_Date__c>=TODAY And RecordType.DeveloperName=\''+targetRecordType+'\' And (Type__c=\''+outstandingType+'\' OR Type__c=\''+normType+'\')');
    }

    public Void execute(Database.BatchableContext bc, List<Receivable__c> lineItems){
        Map<Id,Map<String,Receivable__c>> ownerVsTypeVsTargetRecord=new Map<Id,Map<String,Receivable__c>>(); 
        String actualRecordTypeId=Schema.SObjectType.Receivable__c.getRecordTypeInfosByDeveloperName().get(GlobalConstants.RECEIVABLE_ACTUAL).getRecordTypeId();
        List<Receivable__c> actualLineItemsToInsert=new List<Receivable__c>();
        Map<Id,Map<String,Double>> ownerVsCustomerTypeVsOustandingAmount=new Map<Id,Map<String,Double>>();
        Map<Id,Map<String,Double>> ownerVsCustomerTypeVsNetBilledSales=new Map<Id,Map<String,Double>>();
        Set<String> queueNames=new Set<String>();
        Map<String,Id> queueNameVsQueueId=new Map<String,Id>();
        Map<String,Id> queueDevNameVsQueueId=new Map<String,Id>();
        Map<Id,Set<String>> queuememberVsQueues=new Map<Id,Set<String>>();
        for(Receivable__c rec:lineItems){
            if(!ownerVsTypeVsTargetRecord.containsKey(rec.OwnerId)){
                Map<String,Receivable__c> typeVsRec=new Map<String,Receivable__c>{rec.Type__c=>rec};
                ownerVsTypeVsTargetRecord.put(rec.OwnerId,typeVsRec);
            }
            else{
                ownerVsTypeVsTargetRecord.get(rec.ownerId).put(rec.Type__c,rec);
            }
            queueNames.add(rec.Owner.Name);
            queueNameVsQueueId.put(rec.Owner.Name,rec.OwnerId);
        }
        Map<String,String> nameVsDevName=Utility.getQueueNameVsDeveloperName(queueNames);
        for(String queueName:queueNameVsQueueId.keySet()){
            if(nameVsDevName.containsKey(queueName)){
            	queueDevNameVsQueueId.put(nameVsDevName.get(queueName),queueNameVsQueueId.get(queueName));
            }
        }
        Map<String,List<Id>> queueVsQueueMembers=Utility.getQueueMembers(new Set<String>(nameVsDevName.values()));
        for(String queue:queueVsQueueMembers.keyset()){
            for(Id memberId:queueVsQueueMembers.get(queue)){
                if(!queuememberVsQueues.containsKey(memberId)){
                    queuememberVsQueues.put(memberId,new Set<String>{queue});
                }
                else if(queuememberVsQueues.containsKey(memberId)){
                    queuememberVsQueues.get(memberId).add(queue);
                }
            }
        }
        for(Receivable__c rec:[Select Id,RecordType.DeveloperName,OwnerId,Balance_in_Home_Currency__c,Net_Billed_Sales__c,Document_Date__c,Customer_Type__c
                               From Receivable__c
                               Where OwnerId in :queuememberVsQueues.keySet()
                               And ((RecordType.DeveloperName=:GlobalConstants.RECEIVABLE_RECORDTYPE And Balance_in_Home_Currency__c>0) Or RecordType.DeveloperName=:GlobalConstants.RECEIVABLE_INVOICE)]){
                                String customerType=rec.Customer_Type__c;
                                Double balanceAmount=rec.Balance_in_Home_Currency__c;
                                Double netBilledSalesAmount=rec.Net_Billed_Sales__c!=null?rec.Net_Billed_Sales__c:0;
                                for(String queueName:queuememberVsQueues.get(rec.OwnerId)){
                                       Id queueId=queueDevNameVsQueueId.get(queueName);
                                       if(rec.RecordType.DeveloperName==GlobalConstants.RECEIVABLE_RECORDTYPE){
                                           if(!ownerVsCustomerTypeVsOustandingAmount.containsKey(queueId)){
                                              ownerVsCustomerTypeVsOustandingAmount.put(queueId,new Map<String,Double>{customerType=>balanceAmount});
                                           }
                                           else{
                                               if(!ownerVsCustomerTypeVsOustandingAmount.get(queueId).containsKey(customerType)){
                                                  ownerVsCustomerTypeVsOustandingAmount.get(queueId).put(customerType,balanceAmount);
                                               }
                                               else{
                                                   Double balAmt=ownerVsCustomerTypeVsOustandingAmount.get(queueId).get(customerType)+balanceAmount;
                                                   ownerVsCustomerTypeVsOustandingAmount.get(queueId).put(customerType,balAmt);
                                               }
                                           }
                                       }
                                       else{
                                            Receivable__c targetRecord=ownerVsTypeVsTargetRecord.containsKey(queueId) && ownerVsTypeVsTargetRecord.get(queueId).containsKey(GlobalConstants.RECEIVABLE_TYPE_NORM)?ownerVsTypeVsTargetRecord.get(queueId).get(GlobalConstants.RECEIVABLE_TYPE_NORM):null;
                                            if(targetRecord!=null 
                                               && rec.Document_Date__c!=null 
                                               && rec.Document_Date__c>=targetRecord.Start_Date__c 
                                               && rec.Document_Date__c<=System.today()){
                                                if(!ownerVsCustomerTypeVsNetBilledSales.containsKey(queueId)){
                                                    ownerVsCustomerTypeVsNetBilledSales.put(queueId,new Map<String,Double>{customerType=>netBilledSalesAmount});
                                                }
                                                else{
                                                    if(!ownerVsCustomerTypeVsNetBilledSales.get(queueId).containsKey(customerType)){
                                                        ownerVsCustomerTypeVsNetBilledSales.get(queueId).put(customerType,netBilledSalesAmount);
                                                    }
                                                    else{
                                                        Double netAmt=ownerVsCustomerTypeVsNetBilledSales.get(queueId).get(customerType)+netBilledSalesAmount;
                                                        ownerVsCustomerTypeVsNetBilledSales.get(queueId).put(customerType,netAmt);
                                                    }
                                                }
                                            }
                                        }
                                }
                            }
            for(Id owner:ownerVsCustomerTypeVsOustandingAmount.KeySet()){
                Receivable__c targetRecord=ownerVsTypeVsTargetRecord.containsKey(owner) && ownerVsTypeVsTargetRecord.get(owner).containsKey(GlobalConstants.RECEIVABLE_TYPE_OUTSTANDING)?ownerVsTypeVsTargetRecord.get(owner).get(GlobalConstants.RECEIVABLE_TYPE_OUTSTANDING):null;
                if(targetRecord!=null){
                    for(String customerType:ownerVsCustomerTypeVsOustandingAmount.get(owner).KeySet()){
                        actualLineItemsToInsert.add(new Receivable__c(OwnerId=owner,
                                                                RecordTypeId=actualRecordTypeId,
                                                                Type__c=GlobalConstants.RECEIVABLE_TYPE_OUTSTANDING,
                                                                Balance_in_Home_Currency__c=ownerVsCustomerTypeVsOustandingAmount.get(owner).get(customerType),
                                                                Start_Date__c=targetRecord.Start_Date__c,
                                                                End_Date__c=System.today(),
                                                                Business_Unit__c=targetRecord.Business_Unit__c,
                                                                Customer_Type_Actual__c=customerType));
                    }
                }
            }

            for(Id owner:ownerVsCustomerTypeVsNetBilledSales.KeySet()){
                Receivable__c targetRecord=ownerVsTypeVsTargetRecord.containsKey(owner) && ownerVsTypeVsTargetRecord.get(owner).containsKey(GlobalConstants.RECEIVABLE_TYPE_NORM)?ownerVsTypeVsTargetRecord.get(owner).get(GlobalConstants.RECEIVABLE_TYPE_NORM):null;
                if(targetRecord!=null){
                    for(String customerType:ownerVsCustomerTypeVsNetBilledSales.get(owner).KeySet()){
                        Double balanceAmount=(ownerVsCustomerTypeVsOustandingAmount.containsKey(owner) && ownerVsCustomerTypeVsOustandingAmount.get(Owner).ContainsKey(customerType))?(ownerVsCustomerTypeVsOustandingAmount.get(owner).get(customerType)):0;
                        actualLineItemsToInsert.add(new Receivable__c(OwnerId=owner,
                                                                RecordTypeId=actualRecordTypeId,
                                                                Type__c=GlobalConstants.RECEIVABLE_TYPE_NORM,
                                                                Balance_in_Home_Currency__c=balanceAmount,
                                                                Invoice_Amount__c=ownerVsCustomerTypeVsNetBilledSales.get(Owner).get(customerType),
                                                                Start_Date__c=targetRecord.Start_Date__c,
                                                                End_Date__c=System.today(),
                                                                Business_Unit__c=targetRecord.Business_Unit__c,
                                                                Customer_Type_Actual__c=customerType));
                    }
                }
            }

            if(actualLineItemsToInsert.Size()>0){
                Insert actualLineItemsToInsert;
            }
        
    }

    public Void finish(Database.BatchableContext bc) {
            AsyncApexJob apexJobInst = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems FROM AsyncApexJob
                                    WHERE Id = :bc.getJobId()];
           Logger.logError('Calculate Actuals Job Status', CalculateActuals.class.getName(), 'Job Status: ' + apexJobInst.JobItemsProcessed
            + ' of ' + apexJobInst.TotalJobItems + ' jobs processed with ' + apexJobInst.NumberOfErrors + ' errors');
    }
}