public with sharing class CLITriggerHandler extends VTriggerHandler {
    // Allows unit tests (or other code) to disable this trigger for the transaction
    public static Boolean TriggerDisabled = false;
    /*
        Checks to see if the trigger has been disabled either by custom setting or by running code
    */
    public override Boolean IsDisabled(){
        Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
        if (setting.CLITriggerDisabled__c)
            return true;
        else
            return TriggerDisabled;
    }
    
    /*------------------------------------------------------------------------
    Author:        Kartik Shetty
    Company:       Salesforce
    Description:   Method to handle before Insert event context of Contract Line Item Trigger
    Inputs:        list of inserted records
    Test Class:   

    History
    23-05-2020      Kartik Shetty     Initial Release
    ----------------------------------------------------------------------------*/
    public override void BeforeInsert(list<SObject> newItems) {
        CLIRecordProcessor cliProcessor = new CLIRecordProcessor();
		cliProcessor.populateDatesOnLineFromSR((List<ContractLineItem>) newItems);
		cliProcessor.updateConfigurationLineItemNumber((List<ContractLineItem>) newItems);
        cliProcessor.updateAssetSerialNumber((List<ContractLineItem>) newItems);
        cliProcessor.validateActiveCLIforAsset((List<ContractLineItem>) newItems);
        cliProcessor.populatePriceBookEntryForIntegrationUser((List<ContractLineItem>) newItems);

	}

    /*------------------------------------------------------------------------
    Author:        Kartik Shetty
    Company:       Salesforce
    Description:   Method to handle before Update event context of Contract Line Item Trigger
    Inputs:        list of inserted records
    Test Class:   

    History
    23-05-2020      Kartik Shetty     Initial Release
    ----------------------------------------------------------------------------*/
    public override void BeforeUpdate(map<Id, sObject> newItems, map<Id, sObject> oldItems) {
        CLIRecordProcessor cliProcessor = new CLIRecordProcessor();
        cliProcessor.updateAssetSerialNumber((List<ContractLineItem>) newItems.values());
        cliProcessor.validateActiveCLIforAsset((List<ContractLineItem>) newItems.values());
        cliProcessor.IgnorethePriceChangesFromLN((Map<Id,ContractLineItem>) newItems, (Map<Id,ContractLineItem>) oldItems);
	}
}