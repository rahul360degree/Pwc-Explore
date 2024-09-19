/*------------------------------------------------------------------------
 * Author:        Shailja Mishra
 * Company:       Salesforce
 * Description:   Scheduler class to create Dealer Visits
 * Inputs:        NA
 * Test Class:    CreateDealerVisitsSchedulerTest
 * ---------------------------------------------------------------------------
 * History
 * 05-11-2020      Shailja Mishra     Initial Release
 * ----------------------------------------------------------------------------*/
public class CreateDealerVisitsScheduler Implements Schedulable {
    List<String> PERSONAs = new List<String>{'InterioVFD- Dealer', 'Interio Kitchen-Dealer'};   //{'InterioVFD- Dealer', 'Interio Kitchen-Dealer', 'Interio Kitchen - TSI',  'InterioVFD- Territory Sales In-charge (TSI)'};
	public void execute(SchedulableContext ctx) {
        createDealerVisits();
    }
    
    /*------------------------------------------------------------------------
        * Author:        Shailja Mishra
        * Company:       Salesforce
        * Description:   Responsible for creating Dealer Visits for Interio B2C Dealer personas
        * Inputs:        NA
        * Test Class:    CreateDealerVisitsSchedulerTest
        * ---------------------------------------------------------------------------
        * History
        * 05-11-2020      Shailja Mishra     Initial Release
    * ----------------------------------------------------------------------------*/
    public void createDealerVisits(){
        List<Dealer_Visit__c> dealerVisits = new List<Dealer_Visit__c>();
        Id interioRecordTypeId = Schema.SObjectType.Dealer_Visit__c.getRecordTypeInfosByDeveloperName().get('Interio_B2C').getRecordTypeId();
        for(User u : getUsers()){
            dealerVisits.add(new Dealer_Visit__c(Account_Information__c = u.AccountId,
                                                 Name = u.Name + '-' + u.Business_Unit__c + '-' + String.valueOf(Datetime.now().month()) + '-' + String.valueOf(Datetime.now().Year()),
                                                 OwnerId = u.Id,
                                                 Dealer_Visit_Status__c = 'Draft',
                                                 Visit_Due_Date__c = Datetime.now().addDays(5),
                                                 RecordTypeId = interioRecordTypeId
                                                 
            ));
        }
        
        try{
            if(dealerVisits != null && dealerVisits.size() > 0){
                insert dealerVisits;
            }
        }catch(Exception ex){
            Logger.logError('Create Dealer Visits For Interio B2C Dealer Personas', 'CreateDealerVisitsScheduler', 'createDealerVisits', '', ex);
        }
    }
    
    /*
     * @Description: Responsible for returning users based on set of Personas
     */
    List<User> getUsers(){
         return ([Select Id, Name, Business_Unit__c, AccountId, Account__c From User Where Persona__c IN: PERSONAs And IsActive= true]);
    }
}