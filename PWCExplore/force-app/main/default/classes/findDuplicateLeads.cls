/*------------------------------------------------------------------------
Author:        Pankaj Meshram
Company:       GITL
Description:   Find duplicate Lead records in CSV and Lead table 
Inputs:        NA
Test Class:    LeadTriggerTest
History
30-03-2022     Pankaj Meshram     Initial Release
----------------------------------------------------------------------------*/
public class findDuplicateLeads {
    public static void checkDuplicateLeads(List<Lead> leadList){
        Set<String> csvMobilePhoneVsZipCode = new Set<String>();
        Set<String> phoneList = new Set<String>();
        Set<String> zipCodeList = new Set<String>();
        //Duplicate check in CSV
        for(Lead csvLeads:leadList){  
            if(csvLeads.Business_Unit__c == GlobalConstants.APPLIANCE_BUSINESS_UNIT){                
                if(csvMobilePhoneVsZipCode.contains(csvLeads.Phone+'_'+csvLeads.MobilePhone+'_'+csvLeads.ZipCode__c) || 
                   csvMobilePhoneVsZipCode.contains(csvLeads.MobilePhone+'_'+csvLeads.Phone+'_'+csvLeads.ZipCode__c) ||
                   csvMobilePhoneVsZipCode.contains(csvLeads.MobilePhone+'_'+csvLeads.ZipCode__c) || 
                   csvMobilePhoneVsZipCode.contains(csvLeads.Phone+'_'+csvLeads.ZipCode__c)){            
                   csvLeads.addError(Label.Duplicate_lead_found_either_in_CSV_or_salesforce);
                }else{
                    if(csvLeads.Phone != Null && csvLeads.MobilePhone != Null && csvLeads.ZipCode__c != Null){
                        csvMobilePhoneVsZipCode.add(csvLeads.Phone+'_'+csvLeads.MobilePhone+'_'+csvLeads.ZipCode__c);
                        csvMobilePhoneVsZipCode.add(csvLeads.MobilePhone+'_'+csvLeads.Phone+'_'+csvLeads.ZipCode__c);
                    }
                    else if(csvLeads.Phone != Null && csvLeads.ZipCode__c != Null) 
                        csvMobilePhoneVsZipCode.add(csvLeads.Phone+'_'+csvLeads.ZipCode__c);
                    else{
                        csvMobilePhoneVsZipCode.add(csvLeads.MobilePhone+'_'+csvLeads.ZipCode__c); 
                    }
                    phoneList.add(csvLeads.Phone);
                    phoneList.add(csvLeads.MobilePhone);
                    zipCodeList.add(csvLeads.ZipCode__C);               
                }
            }
        }
        //Check Duplicate in DataBase           
        List<Lead> existingLeads = [SELECT Id,Phone,MobilePhone,ZipCode__c,Business_Unit__c FROM Lead where (Phone In:phoneList OR MobilePhone IN:phoneList) AND ZipCode__c IN:zipCodeList AND (status='New' OR status='Contacted' OR status='Working') AND Business_Unit__c =: GlobalConstants.APPLIANCE_BUSINESS_UNIT];  
        Map<String,Id> leadMobilePhoneZipIdMap = new Map<String,Id>();
        if(existingLeads.size() > 0){
            for(Lead lds : existingLeads) {
                if(lds.Business_Unit__c == GlobalConstants.APPLIANCE_BUSINESS_UNIT){
                    if(lds.Phone !=Null && lds.ZipCode__c !=Null && lds.ZipCode__c !=Null){
                        leadMobilePhoneZipIdMap.put(lds.Phone+'_'+lds.MobilePhone+'_'+lds.ZipCode__c, lds.Id);
                        leadMobilePhoneZipIdMap.put(lds.MobilePhone+'_'+lds.Phone+'_'+lds.ZipCode__c, lds.Id);
                    }else if(lds.Phone !=Null && lds.ZipCode__c !=Null)                      
                      leadMobilePhoneZipIdMap.put(lds.Phone+'_'+lds.ZipCode__c, lds.Id);
                    else
                      leadMobilePhoneZipIdMap.put(lds.MobilePhone+'_'+lds.ZipCode__c, lds.Id);                    
                }
            }
        }
        
    
        for (Lead csvLeadVsDBLead : leadList) {
            if(csvLeadVsDBLead.Business_Unit__c == GlobalConstants.APPLIANCE_BUSINESS_UNIT){                
                 if (leadMobilePhoneZipIdMap.containsKey(csvLeadVsDBLead.Phone+'_'+csvLeadVsDBLead.MobilePhone+'_'+csvLeadVsDBLead.ZipCode__c) ||
                     leadMobilePhoneZipIdMap.containsKey(csvLeadVsDBLead.MobilePhone+'_'+csvLeadVsDBLead.Phone+'_'+csvLeadVsDBLead.ZipCode__c) ||
                     leadMobilePhoneZipIdMap.containsKey(csvLeadVsDBLead.Phone+'_'+csvLeadVsDBLead.ZipCode__c) ||
                     leadMobilePhoneZipIdMap.containsKey(csvLeadVsDBLead.MobilePhone+'_'+csvLeadVsDBLead.ZipCode__c)){
                       csvLeadVsDBLead.adderror(Label.Duplicate_lead_found_either_in_CSV_or_salesforce);
                 } 
            }

        }    
    }
}