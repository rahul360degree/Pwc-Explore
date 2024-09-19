public class OpportunityChatterPostHelper {
    public static ConnectApi.BatchInput getFeedItem(Id userId,Id OpportunityId,String prefix){
        ChatterUtility utilityInstance = new ChatterUtility()
            .setSubjectId(OpportunityId)
            .addTextWithMarkupType('Hi,', ConnectApi.MarkupType.PARAGRAPH)
            .addMention(userId)
            .addTextWithMarkupType(prefix, ConnectApi.MarkupType.PARAGRAPH);
        ConnectApi.FeedItemInput feedItemInput = utilityInstance.build();
        ConnectApi.BatchInput batchInput = new ConnectApi.BatchInput(feedItemInput);
        return batchInput;
    }
    
    public static void postChatterFeed(List<Opportunity> oppList, Date weekAfterCloseDate,Date dayBeforeCloseDate){
        List<ConnectApi.BatchInput> postFeedItems = new List<ConnectApi.BatchInput>();
        for(Opportunity opp: oppList){
            String postFix;
            if(opp.CloseDate == dayBeforeCloseDate){
                postFix = 'Your Opportunity '+opp.Name+' is due tomorrow.'; 
            }
            else{
                if(opp.CloseDate == weekAfterCloseDate){
                    postFix  = 'Your Opportunity '+opp.Name+' is overdue by a week';  
                }
            }
            postFeedItems.add(getFeedItem(opp.OwnerId,opp.Id,postFix));
            
            
        } 
        
        if(!postFeedItems.IsEmpty()){
            if (!Test.isRunningTest()) {
                List<ConnectApi.BatchResult> feedElement = ConnectApi.ChatterFeeds.postFeedElementBatch(Network.getNetworkId(), postFeedItems);
                
                for(ConnectApi.BatchResult batchResult: feedElement){
                    if (!batchResult.isSuccess()) {
                        System.debug('Error '+batchResult.getErrorMessage());
                    }
                }
            }
        }
        
        
    }
    
    
}