/**
 * @description       : 
 * @author            : Poonam C
 * @group             : 
 * @last modified on  : 08-22-2023
 * @last modified by  : Varun Rajpoot
 * Modifications Log
 * Ver   Date         Author          Modification
 * 1.0   08-11-2023   Varun Rajpoot   Initial Version
**/
public class SaveProductFieldDetail {
        
    @AuraEnabled
	public static String saveRecordDetails(sObject rec) {
        try {
            if (rec instanceof Lead) {
                Lead leadRecord = (Lead)rec;
                update leadRecord;
            } else if (rec instanceof Opportunity) {
                Opportunity oppRecord = (Opportunity)rec;
                update oppRecord;
            } else if (rec instanceof Quote) {
                Quote quoteRecord = (Quote)rec;
                update quoteRecord;
            }
            return 'SUCCESS';
        } 
        catch (Exception e) {
            System.debug(e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
	}

    @AuraEnabled(cacheable=true)
    public static List<Boolean> getDefaultRecordValue(sObject rec){
        List<Boolean> defaultValues = new List<Boolean>();
        if(rec instanceof Lead){
            Lead objLead = (Lead)rec;
        defaultValues.add(objLead.Estimated_Project_AAC_Qty_in_CBM__c!=0 && objLead.Estimated_Project_AAC_Qty_in_CBM__c!= null); 
        defaultValues.add(objLead.Estimated_Project_Duroplast_Qty_Bag__c!=0 && objLead.Estimated_Project_Duroplast_Qty_Bag__c!= null); 
        defaultValues.add(objLead.Estimated_Project_EasyFix_Qty_Bag__c!=0 && objLead.Estimated_Project_EasyFix_Qty_Bag__c!= null);
        defaultValues.add(objLead.Est_Project_Solid_Concrete_Block_Nos__c!=0 && objLead.Est_Project_Solid_Concrete_Block_Nos__c!= null);
        defaultValues.add(objLead.Estimated_Project_Pavers_in_Sqm__c!=0 && objLead.Estimated_Project_Pavers_in_Sqm__c!= null);
        defaultValues.add(objLead.Estimated_Project_Curb_Stone_in_Nos__c!=0 && objLead.Estimated_Project_Curb_Stone_in_Nos__c!= null);
        defaultValues.add(objLead.Estimated_Project_Tilefix_Qty_Bag__c!=0 && objLead.Estimated_Project_Tilefix_Qty_Bag__c!= null);  //added by poonam (SCF - 102)
            
        }else if (rec instanceof Opportunity){
            Opportunity objopp = (Opportunity)rec;
        defaultValues.add(objopp.Estimated_Project_AAC_Qty_in_CBM__c!=0 && objopp.Estimated_Project_AAC_Qty_in_CBM__c!= null);
        defaultValues.add(objopp.Estimated_Project_Duroplast_Qty_Bag__c!=0 && objopp.Estimated_Project_Duroplast_Qty_Bag__c!= null);
        defaultValues.add(objopp.Estimated_Project_EasyFix_Qty_Bag__c!=0 && objopp.Estimated_Project_EasyFix_Qty_Bag__c!= null);
        defaultValues.add(objopp.Est_Project_Solid_Concrete_Block_Nos__c!=0 && objopp.Est_Project_Solid_Concrete_Block_Nos__c!= null);
        defaultValues.add(objopp.Estimated_Project_Pavers_in_Sqm__c!=0 && objopp.Estimated_Project_Pavers_in_Sqm__c!= null);
        defaultValues.add(objopp.Estimated_Project_Curb_Stone_in_Nos__c!=0 && objopp.Estimated_Project_Curb_Stone_in_Nos__c!= null);
        defaultValues.add(objopp.Estimated_Project_Tilefix_Qty_Bag__c!=0 && objopp.Estimated_Project_Tilefix_Qty_Bag__c!= null); //added by poonam (SCF - 102)

        }else if (rec instanceof Quote){
            Quote objq = (Quote)rec; 
        defaultValues.add(objq.Estimated_Project_AAC_Qty_in_CBM__c!=0 && objq.Estimated_Project_AAC_Qty_in_CBM__c!= null);
        defaultValues.add(objq.Estimated_Project_Duroplast_Qty_Bag__c!=0 && objq.Estimated_Project_Duroplast_Qty_Bag__c!= null);
        defaultValues.add(objq.Estimated_Project_EasyFix_Qty_Bag__c!=0 && objq.Estimated_Project_EasyFix_Qty_Bag__c!= null);
        defaultValues.add(objq.Est_Project_Solid_Concrete_Block_Nos__c!=0 && objq.Est_Project_Solid_Concrete_Block_Nos__c!= null);
        defaultValues.add(objq.Estimated_Project_Pavers_in_Sqm__c!=0 && objq.Estimated_Project_Pavers_in_Sqm__c!= null);
        defaultValues.add(objq.Estimated_Project_Curb_Stone_in_Nos__c!=0 && objq.Estimated_Project_Curb_Stone_in_Nos__c!= null);
        defaultValues.add(objq.Estimated_Project_Tilefix_Qty_Bag__c!=0 && objq.Estimated_Project_Tilefix_Qty_Bag__c!= null);//added by poonam (SCF - 102)
        }
        return defaultValues;
    }
    //End new
}