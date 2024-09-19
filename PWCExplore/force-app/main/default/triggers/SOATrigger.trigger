trigger SOATrigger on Statement_of_Account__c (after update) {
	TriggerDispatcher.Run(new SOATriggerHandler());
}