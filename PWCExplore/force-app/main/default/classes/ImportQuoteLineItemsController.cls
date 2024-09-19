/*------------------------------------------------------------------------------------
 * Author        :        Sumit
 * Company       :        Salesforce
 * Description   :        Controller for ImportQuoteLineItems component
 * Inputs        :        
 * Test Class    :    
 * History
 * --------
 * 03-06-2020      Sumit Swami     Initial Release
 * 04-06-2020      Joshna Palla    Added fields and error handling
 * ----------------------------------------------------------------------------------*/
public class ImportQuoteLineItemsController {
    // Method called from component on load to fetch related quotes
    // This method will only fetch quotes where line items are already available
    @AuraEnabled
    public static List<Quote> fetchQuotes(String quoteId) {
        List<Quote> quoteList = new List<Quote>();
        if(String.isNotBlank(quoteId)) {
            String OpportunityId = [SELECT OpportunityId FROM Quote WHERE Id = :quoteId].OpportunityId;
            if (String.isNotBlank(OpportunityId)) {
                for (Quote each : [SELECT Id, Name, QuoteNumber, (SELECT Id FROM QuoteLineItems)
                                   FROM Quote
                                   WHERE OpportunityId = :OpportunityId]) {
                    if (each.Id != quoteId && !each.QuoteLineItems.isEmpty()) {
                        quoteList.add(each);
                    }
                }
            }
        } else {
            throw getAuraException(System.Label.Import_Invalid_Quote);
        }
        return quoteList;
    }
    
    // Method to fetch quote line items for selected quotes
    // A maximum volume of 250-300 is expected for quotes, so pagination is handled in component
    @AuraEnabled
    public static List<QuoteLineItem> fetchQuoteLineItems(String quoteId) {
        List<QuoteLineItem> quoteLineItems = new List<QuoteLineItem>();
        if (String.isNotBlank(quoteId)) {
            quoteLineItems = [SELECT Quote.QuoteNumber, Product2.Name, Description, Quantity FROM QuoteLineItem WHERE QuoteId = :quoteId];
        } else {
            throw getAuraException(System.Label.Import_Invalid_Quote);
        }
        return quoteLineItems;
    }
    
    // Method to clone quote line items and map it to the new quote
    @AuraEnabled
    public static void importQLIRecords(List<QuoteLineItem> lstQLI, Id ogQuoteId){
        List<QuoteLineItem> newLineItems = new List<QuoteLineItem>();
        for (QuoteLineItem each : Database.query(QueryBuilder.build('QuoteLineItem', 'Id IN :lstQLI', false))) {
            QuoteLineItem newLineItem = each.clone(false, false, false, false);
            newLineItem.QuoteId = ogQuoteId;
            newLineItems.add(newLineItem);
        }
        try {
            if (Schema.sObjectType.QuoteLineItem.isCreateable()) {
                insert newLineItems;
            } else {
                throw getAuraException(System.Label.Import_Access_Restricted);
            }
        } catch (DMLException ex) {
            throw getAuraException(ex.getMessage());
        }
    }
    
    private static AuraHandledException getAuraException(String message) {
        AuraHandledException newException = new AuraHandledException(message);
        newException.setMessage(message);
        return newException;
    }
}