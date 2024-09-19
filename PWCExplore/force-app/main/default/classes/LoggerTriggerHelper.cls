/*------------------------------------------------------------------------
Author:        Mahith Madwesh
Company:       Salesforce
Description:   Trigger Helper to Handler LoggerTriggerHandler
Inputs:        NA
Test Class:    
---------------------------------------------------------------------------
History
17-12-2020      Mahith Madwesh     Initial Release
----------------------------------------------------------------------------*/
public with sharing class LoggerTriggerHelper {

/*------------------------------------------------------------------------
    Author:        Mahith Madwesh 
    Company:       Salesforce
    Description:   Method to Pass the logger Records to Platform Event
    Inputs:        list of created records
    ---------------------------------------------------------------------------
    History
    17-12-2020      Mahith Madwesh      Initial Release
    ----------------------------------------------------------------------------*/
    public void passLoggerIdToPlatfromEvent(list<Logger__c> loggerRecords){
        
        for(Logger__c l:loggerRecords){
            Asset_Sharing__e newEvent = new Asset_Sharing__e();
            newEvent.Logger_recordId__c = l.Id;
            Eventbus.publish(newEvent);
        }
    }
}