/*------------------------------------------------------------------------
Author:        Kishor Kumar
Company:       Salesforce
Description:   Handler class for Order Trigger
Inputs:        NA
Test Class:    
History
02-04-2020      Kishor Kumar     Initial Release
----------------------------------------------------------------------------*/
public with sharing class OrderItemTriggerHandler extends VTriggerHandler {
    
    // Allows unit tests (or other code) to disable this trigger for the transaction
    public static Boolean TriggerDisabled = false;
 
    /*
        Checks to see if the trigger has been disabled either by custom setting or by running code
    */
    public override Boolean IsDisabled(){
        Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
        if (setting.OrderProductTriggerDisabled__c)
            return true;
        else 
            return TriggerDisabled;
    }
    
    
    /*------------------------------------------------------------------------
    Author:        Kishor Kumar
    Company:       Salesforce
    Description:   Method to handle before Insert event context of OLI Trigger
    Inputs:        list of inserted records
    Test Class:   

    History
    25-05-2020      Kishor Kumar     Initial Release
    ----------------------------------------------------------------------------*/
    public override void BeforeInsert(list<SObject> newItems){
        OLIFieldPopulator populator = new OLIFieldPopulator();
        //populator.populateOLISequence((list<OrderItem>)newItems);//Commented by pankaj and added after splitting (populator.orderSplit())
        OrderLineTriggerHelper helper = new OrderLineTriggerHelper();
        helper.updateSalesPrice((List<OrderItem>) newItems);
        helper.validateSalesPrice((List<OrderItem>)newItems);
        helper.populateOLIWarehouse((List<OrderItem>) newItems);
        MaterialRequestManager mrm = new MaterialRequestManager();
        mrm.validateOrderProducts((List<OrderItem>)newItems);
         // added by Vikrant for payment term for Order Split
        populator.orderSplit((list<OrderItem>)newItems);
        populator.populateOLISequence((list<OrderItem>)newItems);//Added by pankaj on 14/02/2022
        
    }
    
    
    /*------------------------------------------------------------------------
    Author:        Kishor Kumar
    Company:       Salesforce
    Description:   Method to handle before Insert event context of Order Trigger
    Inputs:        list of inserted records
    Test Class:   

    History
    02-04-2020      Kishor Kumar     Initial Release
    ----------------------------------------------------------------------------*/
    public override void afterInsert(Map<Id, SObject> newItems){
       OrderLineTriggerHelper helper = new OrderLineTriggerHelper();
       helper.populateExchangeNotificationId(newItems);
       DiscountMatrixProcessor processor=new DiscountMatrixProcessor();
       processor.processDiscountMatrix((Map<Id,OrderItem>)newItems);
       MaterialRequestManager mrm = new MaterialRequestManager();
       mrm.updateSRProducts((Map<Id,OrderItem>)newItems);
       // added by Anupam for payment term on 28-04-2021
       PaymentTermProcess PTprocessor=new PaymentTermProcess();
       PTprocessor.processPaymentTerm((Map<Id,OrderItem>)newItems);       
    }

    /*------------------------------------------------------------------------
    Author:        Manasi Londhe
    Company:       Salesforce
    Description:   Method to handle Befor Update event context of Order Trigger
    Inputs:        map of created records
    Test Class:   

    History
    18-05-2020      Manasi Londhe     Initial Release
    ----------------------------------------------------------------------------*/
    public override void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        OLIFieldPopulator populator = new OLIFieldPopulator();
        DiscountMatrixProcessor processor=new DiscountMatrixProcessor();
        processor.reverseCalculateLevel2To11DiscountFields((List<OrderItem>)newItems.Values(),(Map<Id,OrderItem>)oldItems);
        OrderLineTriggerHelper helper = new OrderLineTriggerHelper();
        helper.validateSalesPrice((Map<Id, OrderItem>)newItems, (Map<Id,OrderItem>)oldItems);
        helper.updateDiscountFieldsOnUnitPriceUpdate((List<OrderItem>)newItems.Values(),(Map<Id,OrderItem>)oldItems);
        helper.populateOLIWarehouse( (List<OrderItem>) newItems.values());
        helper.validateOLIWarehouses( (Map<Id, OrderItem>) newItems, (List<OrderItem>) oldItems.values());
        MaterialRequestManager mrm = new MaterialRequestManager();
        mrm.validateOrderProducts((Map<Id,OrderItem>)newItems,(Map<Id,OrderItem>)oldItems);
        // added by Vikrant for payment term for Order Split
        populator.orderSplit((list<OrderItem>)newItems.Values());
        populator.populateOLISequence((list<OrderItem>)newItems.Values());

   }
    
    /*------------------------------------------------------------------------
    Author:        Kishor Kumar
    Company:       Salesforce
    Description:   Method to handle Befor Update event context of Order Trigger
    Inputs:        map of created records
    Test Class:   

    History
    02-04-2020      Kishor Kumar     Initial Release
    ----------------------------------------------------------------------------*/
    public override void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
         OrderLineTriggerHelper helper = new OrderLineTriggerHelper();        
         helper.populateExchangeNotificationId(newItems);
         
         
         
         
         
         // Add all new method just above this method
         helper.disableTriggerExecution();//Disable trigger at the end of trigger after update 
    }
   
     /*------------------------------------------------------------------------
    Author:        Pankaj Meshram
    Company:       GITL
    Description:   Method to handle Before Delete event context of Order Trigger
    Inputs:        map of created records
    Test Class:   

    History
    30-08-2022      Pankaj Meshram     Initial Release
    ----------------------------------------------------------------------------*/
    public override void beforeDelete(Map<Id, SObject> oldItems){
         OLIFieldPopulator populator = new OLIFieldPopulator();        
         populator.updateOLISequenceOnDelete((list<OrderItem>) oldItems.Values());
       
    }

}