trigger BilledSalesOutStandingTrigger on Billed_Sales_Outstandings__c (before insert,after update,before update) {
    TriggerDispatcher.Run(new BilledSalesTriggerHandler());
}