/*------------------------------------------------------------------------
 Author:        Mahith Madwesh
 Company:       Salesforce
 Description:   Handler class for 'Competitor visit' Trigger
 Inputs:        NA
 Test Class:
 History
 08-11-2020     Mahith Madwesh     Initial Release
 ----------------------------------------------------------------------------*/
public with sharing class CompetitorVisitTriggerHandler extends VTriggerHandler {
	// Allows unit tests (or other code) to disable this trigger for the transaction
	public static Boolean TriggerDisabled = false;
	/*
	 Checks to see if the trigger has been disabled either by custom setting or by running code
	 */
	public override Boolean IsDisabled() {
		Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
		if ( setting.CompetitorVisitTriggerDisabled__c )
			return true;
		else
			return TriggerDisabled;
	}

	/*------------------------------------------------------------------------
	 Author:       Mahith Madwesh
	 Company:       Salesforce
	 Description:   Method to handle before insert for Competitor visit
	 Inputs:        list of inserted records
	 Test Class:

	 History
	 08-04-2020      Kishor Kumar     Initial Release
	 ----------------------------------------------------------------------------*/
	public override void BeforeInsert(list<SObject> newItems) {
		CompetitorVisitTriggerHandlerHelper helper = new CompetitorVisitTriggerHandlerHelper();
		helper.checkForDuplicate(( List<Competitor_Visit__c> )newItems);
	}
}