/*------------------------------------------------------------------------
Author:        Saurabh Mehta
File Name:     BillingObjectTriggerHandler.cls
Company:       Stetig
Description:   Class is used to calculate the water consumtion on billing
Inputs:        NA
Last Modified: 07/10/2021
Test Class:    
----------------------------------------------------------------------------*/

public class BillingObjectTriggerHandler {
    
    	// Method is used to calculateAmountForWater for BMC & Well Water
    	public static void calculateAmountForWater(List<Billing__c> newBillingList, Map<id,Billing__c> oldBillingMap){
        
        List<Billing__c> finalBillingRecordList = new List<Billing__c>();
	
        Map<Id, List<Rate_Slab__c>> mapchargeSlab = new Map<Id, List<Rate_Slab__c>>();
		Set<Id> billChargeSet = new Set<Id>();
            
        Id waterRecordTypeId = Schema.SObjectType.Billing__C.getRecordTypeInfosByName().get(ElbConstantsClass.Water_Reimbursement_Charges).getRecordTypeId();
        
		//popualte the set
		for(Billing__c bilRecord : newBillingList) {
			 if(bilRecord.charge__c != null && bilRecord.recordtypeId == waterRecordTypeId &&  bilRecord.Billing_Start_Date__c !=null && bilRecord.Billing_End_Date__c != null) {
			   billChargeSet.add(bilRecord.charge__c);
			   finalBillingRecordList.add(bilRecord);
			}
		}
		
		if(!billChargeSet.isEmpty()) {
			//QUery the rate slab
			List<Rate_Slab__c> slabrateList = [Select Id,Rate__c, Start_Date__c, End_Date__c, Charge_Name__c,Charge_Type__c from Rate_Slab__c where Charge_Type__c =: billChargeSet LIMIT 20000];
			//populate Map
			for(Rate_Slab__c slb : slabrateList) {
				if(mapchargeSlab.containsKey(slb.Charge_Type__c)) {
					mapchargeSlab.get(slb.Charge_Type__c).add(slb);
				} else {
					mapchargeSlab.put(slb.Charge_Type__c, new List<Rate_Slab__c>{slb});
				}
				
			}
			
			//perform calculation for each billrecord
            for(Billing__c bilRecord : finalBillingRecordList) {
				List<String> bmcCRate = new List<String>();
				List<String> wellCRate = new List<String>();
				decimal totalAmount = 0;
				decimal bmcAmount = 0;
				decimal wellAmount = 0;
				Integer totalBillsDay = bilRecord.Billing_Start_Date__c.daysBetween(bilRecord.Billing_End_Date__c)+1;
				
				//populate  BMC and well consumtion rate
				for(Rate_Slab__c slb : mapchargeSlab.get(bilRecord.charge__c)) {
					List < Date > startDates = new List < Date > ();
                    startDates.add(slb.Start_Date__c);
                    startDates.add(bilRecord.Billing_Start_Date__c);
                    startDates.sort();
                    Date MaxStartDate = startDates[(startDates.size() - 1)];
                            
                    List < Date > endDates = new List < Date > ();
                    endDates.add(slb.End_Date__C);
                    endDates.add(bilRecord.Billing_End_Date__c);
                    endDates.sort();
                    Date MinEndDate = endDates[0];
                            
                    Integer overlapDays = MaxStartDate.daysBetween(MinEndDate) + 1;
					if(slb.Charge_Name__c == Label.BMCConsumption) {
						Integer slabdays = overlapDays;
						if (overlapDays > 0)
						bmcCRate.add(slb.Rate__c+':'+slabdays);
					}
					if(slb.Charge_Name__c == Label.WELLConsumption) {
						Integer slabdays = overlapDays;
						if (overlapDays > 0)
						wellCRate.add(slb.Rate__c+':'+slabdays);
							
					}
					
				} 
				
				for(String bmc : bmcCRate) {
					List<String> ChargeAndDays = bmc.split(':');
				
					bmcAmount += ((bilRecord.B_M_C_Consumption_KL__c/totalBillsDay)* Decimal.ValueOf(ChargeAndDays[0]) * Integer.ValueOf(ChargeAndDays[1]));
				}
				
				for(String well : wellCRate) {
					List<String> ChargeAndDays = well.split(':');
					wellAmount += ((bilRecord.WELL_Consumption_KL__c/totalBillsDay) * Decimal.ValueOf(ChargeAndDays[0]) * Integer.ValueOf(ChargeAndDays[1]));
				}
				
				//calculate amount
				totalAmount = bmcAmount + wellAmount;
				bilRecord.Amount__c = totalAmount;
			}
		}
    }   
}