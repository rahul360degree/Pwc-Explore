/*------------------------------------------------------------------------
Author:        Manasi Londhe
Company:       Salesforce
Description:   Helper class for Advance Payment Detail trigger
Inputs:        
Test Class:   

History
06-11-2020      Manasi Londhe     Initial Release
----------------------------------------------------------------------------*/ 

public with sharing class AdvancePaymentDetailTriggeHandlerHelper {
    Boolean SKIP_BEFORE;
    /*------------------------------------------------------------------------
Author:        Manasi Londhe
Company:       Salesforce
Description:   Method to set advance payment fields based on EMI Scheme selected
US=>W00116 
Sprint 2
Phase 3B
Inputs:        new records/map of updated records
Test Class:   
History
06-11-2020      Manasi Londhe     Initial Release
----------------------------------------------------------------------------*/ 
    public void populateDetailsAsPerSchemeSelected(List<Advance_Payment_Details__c> advancePaymentDetailRecs,Map<Id,Advance_Payment_Details__c> oldAdvancePaymentRecs){
        List<Advance_Payment_Details__c> advancePaymentRecords=new List<Advance_Payment_Details__c>();
        Set<String> schemes=new Set<String>();
        Map<String,Advanced_Payment_Scheme_Details__mdt> schemeNameVsMDTRecord=new Map<String,Advanced_Payment_Scheme_Details__mdt>();
        for(Advance_Payment_Details__c apd:advancePaymentDetailRecs){//new insert
            /**/
            if(((oldAdvancePaymentRecs!=null && apd.EMI_Scheme__c!=oldAdvancePaymentRecs.get(apd.Id).EMI_Scheme__c)||oldAdvancePaymentRecs==null) 
               && apd.Payment_Mode__c==GlobalConstants.PAYMENT_MODE_EMI) {
                   if(apd.EMI_Scheme__c!=null){                           
                       advancePaymentRecords.add(apd);
                       schemes.add(apd.EMI_Scheme__c);
                   }
                   else{
                       apd.EMI_Count__c=0;
                       apd.DP_Month__c=0;
                       apd.Processing_Fees__c=0;
                   }
               }
            
        }
        
        
        if(schemes.size()>0){
            for(Advanced_Payment_Scheme_Details__mdt apdSchemeDetail:[Select Scheme_Name__c,Processing_Fee__c,EMI_Count__c,Down_payment__c
                                                                      From Advanced_Payment_Scheme_Details__mdt
                                                                      Where Scheme_Name__c In :schemes]){
                                                                          schemeNameVsMDTRecord.put(apdSchemeDetail.Scheme_Name__c,apdSchemeDetail);
                                                                      }
            for(Advance_Payment_Details__c apd:advancePaymentRecords){
                if(schemeNameVsMDTRecord.containsKey(apd.EMI_Scheme__c)){
                    apd.EMI_Count__c=schemeNameVsMDTRecord.get(apd.EMI_Scheme__c).EMI_Count__c;
                    apd.DP_Month__c=schemeNameVsMDTRecord.get(apd.EMI_Scheme__c).Down_payment__c;
                    apd.Processing_Fees__c=schemeNameVsMDTRecord.get(apd.EMI_Scheme__c).Processing_Fee__c;
                }
                else{
                    apd.EMI_Count__c=0;
                    apd.DP_Month__c=0;
                    apd.Processing_Fees__c=0; 
                }
                //Calculating the Expected advance Payment amount for APD using Down Payment, Card Charge and Processing Fees(SAF-196) 
                if(apd != null && apd.Business_Unit__c==GlobalConstants.APPLIANCE_BUSINESS_UNIT && apd.Payment_Mode__c==GlobalConstants.PAYMENT_MODE_EMI){
                    apd.Expected_Advance_Payment__c=(((apd.DP_Month__c + apd.EMI_Count__c ) != 0)?(apd.Loan_Amount__c / ( apd.DP_Month__c + apd.EMI_Count__c )) * apd.DP_Month__c:0)+ apd.EMI_Card_Charge__c+apd.Processing_Fees__c;   
                }
            }
        }
    }
    
    //added by Jalaj 30/04/2021
    public void updateDocumentNumberAsPerTransactionType(List<Advance_Payment_Details__c> advancePaymentDetailRecs){
        for(Advance_Payment_Details__c apd:advancePaymentDetailRecs){
            if (apd.Transaction_Type__c!=null){
                List<Advance_Payment_Details__c> advancePaymentRecords=[SELECT Id, Name, Transaction_Type__c, Doc_Number__c
                                                                        FROM Advance_Payment_Details__c
                                                                        WHERE Transaction_Type__c =: apd.Transaction_Type__c
                                                                        //ORDER by Doc_Number__c, CreatedDate DESC];
                                                                        ORDER by CreatedDate];
                Integer apdSize = advancePaymentRecords.size();                
                if(apdSize > 0){
                    Integer newApdSize = apdSize - 1;                   
                    Advance_Payment_Details__c newApd = advancePaymentRecords[newApdSize];
                    
                    if (newApd.Doc_Number__c != null){
                        Integer docNumber = Integer.valueOf(newApd.Doc_Number__c);
                        apd.Doc_Number__c = String.valueOf(apdSize + 1);
                        
                        if (apdSize < docNumber){
                            apd.Doc_Number__c = String.valueOf(docNumber + 1);    
                        }
                        else{
                            apd.Doc_Number__c = String.valueOf(apdSize + 1);
                        }
                    }
                    else{
                        apd.Doc_Number__c = String.valueOf(apdSize + 1);
                    }
                }
                else{
                    apd.Doc_Number__c = String.valueOf(apdSize + 1);
                }
            }
        }
    }
    
    //added by Jalaj 13-07-2021
    
    public void deletionNotAllowedAfterSyncToInfor(List<Advance_Payment_Details__c> advancePaymentDetailRecs, string executionContext){
        Id profileId = UserInfo.getProfileId();
        String profileName =[Select Id, Name from Profile where Id=:profileId].Name;
        System.debug('Profile Name'+profileName);
        
        for(Advance_Payment_Details__c advPayDetail:advancePaymentDetailRecs){
            if(executionContext=='delete' && ProfileName != 'System Administrator'){
                if(advPayDetail.Integration_Status__c == 'Synced')
                    advPayDetail.AddError('Cannot delete the record once it is synced to Infor');
            }
        }
    }
    //Added by Shreela and Namrata on 24-02-2023 for Jira SIEPB-69
    public void skipAdvancePaymentDetailGenerationForInterioB2C(List<Advance_Payment_Details__c> advancePaymentDetailRecs){
        Set<Id> orderId = new Set<Id>();
        Decimal lmt = decimal.valueOf(System.label.Total_APD_Amount_Limit); //Should not cross 2 Lakh 
        for(Advance_Payment_Details__c apd : advancePaymentDetailRecs){  //For fetching Order Id
            orderId.add(apd.Order__c);
        }
        Map<Id,Decimal> orderIdVsApdAmount = new Map<Id,Decimal>();
        for(Order ord : [ SELECT Id, Business_Unit__c,(SELECT Id,Order__c,Mode_of_Advance_Payment__c,Amount__c,RecordType.DeveloperName FROM Child_AdvancePaymentDetails__r) 
                         FROM Order 
                         WHERE Id IN: orderId]){ //Fetching Amount of All Existing APDs for particular Order
                             Decimal existingAmount =0;
                             for(Advance_Payment_Details__c apd : ord.Child_AdvancePaymentDetails__r){
                                 if (apd.Order__c == ord.Id && apd.Mode_of_Advance_Payment__c == GlobalConstants.PAYMENT_MODE_CASH && apd.RecordType.DeveloperName == GlobalConstants.APD_INTERIO_RECORDTYPE_NAME){
                                     existingAmount+=apd.Amount__c;
                                 }  
                             }
                             orderIdVsApdAmount.put(ord.Id, existingAmount); //Fetch existing amount of All APD's for particular Order
                         }
        for(Advance_Payment_Details__c apd:advancePaymentDetailRecs){
            Decimal finalAmt = 0;
            if(apd.Mode_of_Advance_Payment__c == GlobalConstants.PAYMENT_MODE_CASH && apd.Business_Unit__c == GlobalConstants.INTERIO_BUSINESS_UNIT){
                finalAmt=orderIdVsApdAmount.get(apd.Order__c)+apd.Amount__c;
            }
            if(finalAmt>=lmt){
                apd.addError(System.label.Total_APD_Amount_should_not_exceed_2_lakh);
            }
        }
    }
    //Ended by Shreela and Namrata on 24-02-2023 for Jira SIEPB-69  
}