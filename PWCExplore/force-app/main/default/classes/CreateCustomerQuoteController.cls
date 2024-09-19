/*------------------------------------------------------------------------------------
 * Author        :        Joshna
 * Company       :        Salesforce
 * Description   :        Controller for CreateCustomerQuote component
 * Inputs        :        
 * Test Class    :    
 * History
 * --------
 * 03-06-2020      Joshna Palla     Initial Release
 * ----------------------------------------------------------------------------------*/
public with sharing class CreateCustomerQuoteController {
    static String recordTypeName = 'Customer_Quote';
    @AuraEnabled 
    public static String createCustomerQuote(String recordId) {
        Quote customerQuote;
        if (String.isNotBlank(recordId)) {
            Quote sourceQuote;
            for (Quote each: Database.query(QueryBuilder.build('Quote', 'Id = :recordId', false))) {
                sourceQuote = each;
                break;
            }
            if (sourceQuote != null) {
                customerQuote = sourceQuote.clone(false, false, false, false);
            }
        } else {
            throw new AuraHandledException(System.Label.Import_Invalid_Quote);
        }
        if (customerQuote != null) {
            try {
                customerQuote.Primary_Quote__c = recordId;
                customerQuote.Pricing_approval_request__c = null;
                customerQuote.RecordTypeId = Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get(recordTypeName).getRecordTypeId();
                if (Schema.sObjectType.Quote.isCreateable()) {
                    insert customerQuote;
                    return String.valueOf(customerQuote.Id);
                } else {
                    throw new AuraHandledException(System.Label.Import_Access_Restricted);
                }
            } catch (DMLException ex) {
                throw new AuraHandledException(ex.getMessage());
            }
        }
        return null;
    }
}