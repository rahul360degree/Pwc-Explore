//Dealer Users need to Convert Leads to Accounts for which they have read only access; hence "without sharing"
public without sharing class LeadConversionController{
    @AuraEnabled
    public static String convertLead(Id inputValue, Id existingAccountId) {
        
        Lead lead = [SELECT Id, Business_Unit__c, Sub_Division__c, RecordType.Name FROM Lead WHERE Id = :inputValue];
        Database.LeadConvert lc = new database.LeadConvert();
        lc.setLeadId(inputValue);
        
        if(String.isNotBlank(existingAccountId))
            lc.setAccountId(existingAccountId);
        
        //LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted = true LIMIT 1]; //Comment added by Mrunali Chaudhari for SLEPBS-61 (15 Jan 2024)
        lc.setConvertedStatus(GlobalConstants.QUALIFIED); // Set GlobalConstants.QUALIFIED insted of convertStatus.MasterLabel for by Mrunali Chaudhari SLEPBS-61 (15 Jan 2024)
        
        try{ 
            Database.LeadConvertResult lcr = Database.convertLead(lc);
            return String.valueOf(lcr.getOpportunityId());
        } catch(Exception ex){
            AuraHandledException newException = new AuraHandledException(ex.getMessage());
            newException.setMessage(ex.getMessage());
            throw newException;
        }
    }
    //Added by Namrata on 12-01-2023 for Jira SMEPB-59 for hiding checkbox to create new account for some profiles
    @AuraEnabled
    public static boolean skipCreateNewAccount(){
        boolean newAccountCreation = true;
        try{
            Profile pr =[Select Id,Name From Profile Where Id =:UserInfo.getProfileId()];
            String prName = pr.Name;
         
            if(prName == GlobalConstants.MHE_SALES_USER_PROFILE_NAME ||prName == GlobalConstants.MHE_DEALER_SALES_REP_PARTNER_USER_PROFILE_NAME || prName == GlobalConstants.MHE_DEALER_SALES_MANAGER_PARTNER_USER_PROFILE_NAME || prName == GlobalConstants.MHE_SALES_KAM_FUNCTIONAL_USER_PROFILE_NAME){
            
					newAccountCreation = false; 
             }
        }
        catch(Exception ex){
            Logger.logError('LeadConversionController', 'SkipCreateNewAccount', '', ex);
        }
         return boolean.valueof(newAccountCreation);
    }
    //Ended by Namrata 
    
    @AuraEnabled
    public static Lead getLeadData(String recordId) {
        return [SELECT Id, Name,Distributor_1__c,Sub_Division__c,Business_Unit__c FROM Lead where Id=:recordId];
    }
    
}