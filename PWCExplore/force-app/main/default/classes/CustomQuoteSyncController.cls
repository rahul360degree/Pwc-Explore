public class CustomQuoteSyncController {
    
    @AuraEnabled
    public static String startSyncWithQuote(String recordId) {
        String returnVal = 'NA';
        List<Quote> quoteList = new List<Quote>([SELECT Id, OpportunityId 
                                                 FROM Quote
                                                 WHERE Id = :recordId]);
        if(!quoteList.isEmpty()) {
            Opportunity opp = new Opportunity(Id = quoteList[0].OpportunityId, SyncedQuoteID = recordId );
            update opp;
            returnVal = recordId;
        }
        return returnVal;
    }
    
    @AuraEnabled
    public static String stopSyncWithQuote(String recordId) {
        String returnVal = 'NA';
        List<Quote> quoteList = new List<Quote>([SELECT Id, OpportunityId , Opportunity.SyncedQuoteID
                                                 FROM Quote
                                                 WHERE Id = :recordId]);
        if(!quoteList.isEmpty()) {
            if(String.isNotBlank(quoteList[0].Opportunity.SyncedQuoteID) 
               && (quoteList[0].Opportunity.SyncedQuoteID == recordId )) {
                Opportunity opp = new Opportunity(Id = quoteList[0].OpportunityId, SyncedQuoteID = NULL );
                update opp;
            }
            returnVal = recordId;
        }
        return returnVal;

    }
}