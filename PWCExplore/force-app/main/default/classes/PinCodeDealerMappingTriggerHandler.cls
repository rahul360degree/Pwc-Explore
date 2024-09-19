/*------------------------------------------------------------------------
Author:        Mahith Madwesh
Company:       Salesforce
Description:   Handler class for pinCodeDealerMapping Trigger
Inputs:        NA
Test Class:    
History
15-12-2020      Mahith Madwesh     Initial Release
----------------------------------------------------------------------------*/
public without sharing class PinCodeDealerMappingTriggerHandler extends VTriggerHandler {
    // Allows unit tests (or other code) to disable this trigger for the transaction
    public static Boolean TriggerDisabled = false;
    
    /*
Checks to see if the trigger has been disabled either by custom setting or by running code
*/
    public override Boolean IsDisabled(){
        Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
        if (setting.Fire_pinCodeDealerMappingTriggerDisabled__c)
            return true;
        else 
            return TriggerDisabled;
    }
    
    /*------------------------------------------------------------------------
Author:        Mahith Madwesh 
Company:       Salesforce
Description:   Method to handle Before Insert event context of Trigger
Inputs:        list of created records
Test Class:   
---------------------------------------------------------------------------
History
15-12-2020      Mahith Madwesh     Initial Release
----------------------------------------------------------------------------*/
    public override void AfterInsert(map<Id, sObject> newItems){
        pincodeDealerTriggerHelper helper = new pincodeDealerTriggerHelper();
        helper.getPincodeDealerUpdates((list<Pin_Code_Dealer_Mapping__c>)newItems.values(),'insert');
    }
    
    
    /*------------------------------------------------------------------------
Author:        Mahith Madwesh 
Company:       Salesforce
Description:   Method to handle Before Update event context of Trigger
Inputs:        list of created records
Test Class:   
---------------------------------------------------------------------------
History
15-12-2020      Mahith Madwesh     Initial Release
----------------------------------------------------------------------------*/
    /*public override void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
       pincodeDealerTriggerHelper helper = new pincodeDealerTriggerHelper();
       helper.getPincodeDealerUpdates((list<Pin_Code_Dealer_Mapping__c>)newItems.values(),'insert');
        
    } */ //Commented this code by Shreela for SMEPB 134 on 8th Jan 2024
    
    /*------------------------------------------------------------------------
Author:        Mahith Madwesh 
Company:       Salesforce
Description:   Method to handle Before Delete event context of Trigger
Inputs:        list of created records
Test Class:   
---------------------------------------------------------------------------
History
15-12-2020      Mahith Madwesh     Initial Release
----------------------------------------------------------------------------*/
    public override void BeforeDelete(Map<Id, SObject> oldItems){
        pincodeDealerTriggerHelper helper = new pincodeDealerTriggerHelper();
        helper.getPincodeDealerUpdates((list<Pin_Code_Dealer_Mapping__c>)oldItems.values(),'delete');
    }
    /*------------------------------------------------------------------------
Author:        Dhiren Modi, Shreela Nair
Company:       Salesforce
Description:   Method to handle After Update event context of Trigger
Inputs:        Map of New records,Map of old  records
Test Class:   
---------------------------------------------------------------------------   */
    public override void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        pincodeDealerTriggerHelper helper = new pincodeDealerTriggerHelper();
        helper.getPincodeDealerUpdates((list<Pin_Code_Dealer_Mapping__c>)newItems.values(),'insert');
    }
}