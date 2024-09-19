/*------------------------------------------------------------------------
Author:        Shailja Mishra
Company:       Salesforce
Description:   Responsible for alerting Missed Visits to relevant personas
Inputs:        NA
Test Class:    AlertMissedDealerVisitSchedulerTest
---------------------------------------------------------------------------
History
20-10-2020      Shailja Mishra     Initial Release
----------------------------------------------------------------------------*/
public class AlertMissedCompetitorVisitScheduler Implements Schedulable{
    public void execute(SchedulableContext ctx) {
        chatterPostsForMissedVisits();
    }
    
    /*--------------------------------------------------------------------------
	  Author:        Shailja Mishra
	  Company:       Salesforce
	  Description:   Responsible for alerting Missed Visits to relevant 'personas'
	  Inputs:        NA
	  Test Class:    AlertMissedCompetitorVisitSchedulerTest
	----------------------------------------------------------------------------
	  History
	  20-10-2020      Shailja Mishra     Initial Release
	----------------------------------------------------------------------------*/
    public static void chatterPostsForMissedVisits(){
        List<String> personas = getPersonas();
        Map<Id, User> idVsUser = getUsers(personas);
        Set<Id> notVisitedUserIds = new Set<Id>();
        Set<Id> visitedUserIds = new Set<Id>();
        List<ConnectApi.BatchInput> batchInputs = new List<ConnectApi.BatchInput>();
        List<ConnectApi.FeedItemInput> feedInputs = new List<ConnectApi.FeedItemInput>();
        Map<Id, Integer> idVsCompetitorVisitCount = new Map<Id, Integer>();
        
        if(!idVsUser.isEmpty()){
            //add all userIds in the set
            notVisitedUserIds.addAll(idVsUser.keySet());            
            
            //Integer currentmonth = Date.today().month();
            for(Competitor_Visit__c competitorVisit : [Select Id, Owner.Id, Person_accompanying_on_Visit__c 
                                                       From Competitor_Visit__c 
                                                       Where (Owner.Id IN : idVsUser.keySet() Or Person_accompanying_on_Visit__c IN : idVsUser.keySet()) 
                                                       And CreatedDate = Last_Month]){
                                                           if(competitorVisit.Person_accompanying_on_Visit__c != null){
                                                               visitedUserIds.add(competitorVisit.Person_accompanying_on_Visit__c);
                                                           }else{
                                                               visitedUserIds.add(competitorVisit.Owner.Id);
                                                           }
                                                       }
            //remove all the UserIds who has Competitor Visits
            notVisitedUserIds.removeAll(visitedUserIds);
            
            //Insert default count as 0
            for(Id ownerId : notVisitedUserIds){
                idVsCompetitorVisitCount.put(ownerId, 0);
            }
            
            //get the count of competitor visit created in last 90 days
            AggregateResult[] ars = [Select Count(Id) ct, Owner.Id oid From Competitor_Visit__c Where (Owner.Id IN : notVisitedUserIds Or Person_accompanying_on_Visit__c IN : notVisitedUserIds) 
                                                       And CreatedDate = LAST_N_DAYS:90 group by Owner.Id, Person_accompanying_on_Visit__c];
            //put count of Competitor visits in map
            for(AggregateResult ar : ars){
                Id ownerId = (Id)ar.get('oid');
                Integer count = (Integer)ar.get('ct');
                if(idVsCompetitorVisitCount.containsKey(ownerId)){
                    count = idVsCompetitorVisitCount.get(ownerId) > 0 ? (count + idVsCompetitorVisitCount.get(ownerId)) : count;
                    idVsCompetitorVisitCount.put(ownerId, count);
                }else{
                    idVsCompetitorVisitCount.put(ownerId, count);
                }
            }
            
            //post chatter to the users who missed competitor visits
            if(!idVsCompetitorVisitCount.isEmpty()){
                for(Id usrId : idVsCompetitorVisitCount.keySet()){
                    if(idVsUser.containsKey(usrId)){
                        ChatterUtility utilityInstance = new ChatterUtility()
                            .setSubjectId(usrId)
                            .addMention(usrId)
                            .addTextWithMarkupType(' '+ System.Label.Competitor_Visits_Missed_Alert_Message + idVsCompetitorVisitCount.get(usrId) + '.', ConnectApi.MarkupType.PARAGRAPH)
                            .addMention(idVsUser.get(usrId).ManagerId).addMention(idVsUser.get(usrId).Manager.ManagerId);
                        
                        ConnectApi.FeedItemInput feedItemInput = utilityInstance.build();
                        ConnectApi.BatchInput batchInput = new ConnectApi.BatchInput(feedItemInput);
                        feedInputs.add(feedItemInput);
                        batchInputs.add(batchInput);
                    }
                }
            }
        }
        
        if (batchInputs.size() > 0 && batchInputs != null) {
            try {
                if (Test.isRunningTest()) {
                    ChatterUtility.postChatterForTestClass(feedInputs);
                } else {
                    ConnectApi.ChatterFeeds.postFeedElementBatch(Network.getNetworkId(), batchInputs);
                }
            } catch(Exception feedPostException) {
                Logger.logError('Competitor Visit Alerts', AlertMissedCompetitorVisitScheduler.class.getName(), 'execute', null, feedPostException);
            }
        }
        
        
    }
    
    /*
     * @Description: Responsible for returning listed Personas in metadata record  
     */ 
    private static List<String> getPersonas(){
        List<Application_Settings__mdt> mdts = [Select Id, Values__c From Application_Settings__mdt Where DeveloperName = 'Alert_Missed_Competitor_Visits_Persona' Limit 1];
        if(mdts.size() > 0){
            List<String> personas = mdts[0].Values__c.split('\\,');
            return personas;
        }
        return new List<String>();
    }
    
    /*
     * @Description: Responsible for returing user records based on List of Personas
     */
    private static Map<Id, User> getUsers(List<String> personas){
        return (new Map<Id, User>([Select Id, Name, ManagerId, Manager.ManagerId
                                   From User 
                                   Where Persona__c IN: personas And IsActive = true]));
    }
    
}