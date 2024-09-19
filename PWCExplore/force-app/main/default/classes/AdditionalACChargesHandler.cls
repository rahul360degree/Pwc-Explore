/*------------------------------------------------------------------------
Author:        Saurabh Mehta
File Name:     AdditionalACChargesHandler.Cls
Company:       Stetig
Description:   This class is used to calculate Additional AC charges for Billing
Inputs:        NA
Last Modified: 07/10/2021
Test Class:    
----------------------------------------------------------------------------*/

public class AdditionalACChargesHandler {

// Method is used to calculate Ac charges
public static void calculateACCharges(List<Billing__c> newBillingList, Map<id,Billing__c> oldBillingMap){
           
        Id AdditionalACTypeId = Schema.SObjectType.Billing__C.getRecordTypeInfosByDeveloperName().get(ElbConstantsClass.Additional_AC_Charges).getRecordTypeId();
        List<Billing__c> finalBillingRecordList = new List<Billing__c>();
        Map<Id, List<Rate_Slab__c>> mapchargeSlab = new Map<Id, List<Rate_Slab__c>>();
        Set<Id> billChargeSet = new Set<Id>();
        
        //popualte the set
        for(Billing__c bilRecord : newBillingList) {
            if(bilRecord.charge__c != null && bilRecord.recordtypeId == AdditionalACTypeId && bilRecord.Billing_Start_Date__c !=null && bilRecord.Billing_End_Date__c != null) {
               billChargeSet.add(bilRecord.charge__c);
               finalBillingRecordList.add(bilRecord);
            }
        }
        if(!billChargeSet.isEmpty()) {
            
            //QUery the rate slab
            List<Rate_Slab__c> slabrateList = [Select Id,Rate__c, Start_Date__c, End_Date__c, Charge_Name__c, Charge_Type__c from Rate_Slab__c where Charge_Type__c =: billChargeSet LIMIT 20000];
            
            //populate Map
            for(Rate_Slab__c slb : slabrateList) {
                if(mapchargeSlab.containsKey(slb.Charge_Type__c)) {mapchargeSlab.get(slb.Charge_Type__c).add(slb);}
                else{ mapchargeSlab.put(slb.Charge_Type__c, new List<Rate_Slab__c>{slb});}
            }
            //calcualte the value
            for(Billing__c bilRecord : finalBillingRecordList) {
                
                decimal perhourRate = 0;
                 for(Rate_Slab__c slb : mapchargeSlab.get(bilRecord.charge__c)) {
                
                    if(slb.Start_Date__c<= bilRecord.Billing_Start_Date__c && slb.End_Date__c>= bilRecord.Billing_End_Date__c){
                        
                        if(slb.Charge_Name__c == Label.ChargeNameExtraUsage) {perhourRate = slb.Rate__c;}
                    }
                     if(perhourRate != 0){
                         break;
                     }
                }  
                //calculate amount
                bilRecord.Amount__c = (perhourRate * bilRecord.Total_Extra_Usage_in_Hours__c);  
            }
        }   
    }   
}