/**
 * @Description       : SIEPB-119: Added Validation to stop duplicate Records
 * @Author            : Varun Rajpoot
 * @last modified on  : 12-08-2023
 * @last modified by  : Varun Rajpoot
 * Modifications Log
 * Ver   Date         Author          Modification
 * 1.0   12-08-2023   Varun Rajpoot   Initial Version
**/
public class DailyWalkInTriggerHelper {
    public void duplicateCheck(list<Daily_Walk_Ins__c> newItems){        
        Id currecntUserId = UserInfo.getUserId();
        List<User> user = [Select Id,Business_Unit__c 
                            from User 
                            where 
                            Id=: currecntUserId 
                            and Business_Unit__c =: GlobalConstants.INTERIO_BUSINESS_UNIT
                            and Sub_Division__c =: GlobalConstants.B2C_SUBDIVISION
                            ];
        if(!user.isEmpty()){
            Map<Date,Daily_Walk_Ins__c> walkinMap = new Map<Date,Daily_Walk_Ins__c>();
            for(Daily_Walk_Ins__c walkIn:newItems){ 
                walkinMap.put(walkIn.Date_of_Captured__c,walkIn);
            }
            List<Daily_Walk_Ins__c> duplicateWalkIn = [Select Id,CreatedById
                                                       from Daily_Walk_Ins__c
                                                       where
                                                       CreatedById =:currecntUserId
                                                       AND Date_of_Captured__c IN: walkinMap.keySet()
                                                       and ID NOT IN: newItems
                                                      ];
            if(!duplicateWalkIn.isEmpty()){
                for(Daily_Walk_Ins__c walkIn:newItems)
                {
                    walkIn.Date_of_Captured__c.addError(System.Label.Duplicate_Walk_In);
                }
            }
        }
    }
}