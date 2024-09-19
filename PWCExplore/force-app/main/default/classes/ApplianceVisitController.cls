/**
 * @Description       : 
 * @Author            : Varun Rajpoot
 * @last modified on  : 10-17-2023
 * @last modified by  : Varun Rajpoot
 * Modifications Log
 * Ver   Date         Author          Modification
 * 1.0   09-29-2023   Varun Rajpoot   Initial Version
**/
public with sharing class ApplianceVisitController {
    
    @AuraEnabled(cacheable=true)
    public static Map<String,Integer> getVisitRecordConfig(){
        Map<String,Integer> temp = new Map<String,Integer>();
        for(BU_Role_Catego_Wise_Dealer_Visit_Records__mdt config: [Select Id,Account_Team_Member_Role__c,Dealer_Retailer_Category__c,Number_Of_Dealer_Visits__c
         from BU_Role_Catego_Wise_Dealer_Visit_Records__mdt 
         where Business_Unit__c='H']){
            temp.put(config.Account_Team_Member_Role__c+'-'+config.Dealer_Retailer_Category__c.trim(),Integer.valueOf(config.Number_Of_Dealer_Visits__c));
         }
         return temp;
    }

    @AuraEnabled(cacheable=true)
    public static List<AccountTeamMember> getAccountTeamMember(){
        // Add filter for recordtype also
        List<AccountTeamMember> teamMember= [select Id, AccountId,TeamMemberRole,
                                         Account.Retailer_Category__c,
                                Account.Dealer_Category__c,	
                                Account.RecordType.DeveloperName,
                                Account.Name
                                from AccountTeamMember 
                                where 
                                Account.Business_Unit__c = 'H' 
                                AND UserId =: userinfo.getUserId()

                            ];

        return teamMember;
    }

    @AuraEnabled
    public static PJP__c createPJP(PJP__c record){
        try {
            String existingPJPId = doesRecordExist(record);
            boolean doesRecordExist= (String.isBlank(existingPJPId))?false:true;
            if(doesRecordExist){
                String message = 'Auto Generated PJP Already Exist For This Month.';
                AuraHandledException error = new AuraHandledException(message);
                error.setMessage(message);
                throw error;
            }else{
                insert record;
            }

            
            return record;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }


    private static String doesRecordExist(PJP__c record){
     List<PJP__C> existingRecord = [Select Id from PJP__C where name =:record.Name and CreatedById=: UserInfo.getUserId() limit 1] ;
     if(existingRecord.isEmpty()){
        return '';
     }else{
        return existingRecord[0].Id;
     }
     
    }



    @AuraEnabled
    public static List<Dealer_Visit__c> createVisits(List<Dealer_Visit__c> records){
        try {
            insert records;
            return records;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable = true)
    public static User getUserDetail(){
        try {
            return [Select Id,Name, Area_Code__c from User where Id=:UserInfo.getUserId()];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}