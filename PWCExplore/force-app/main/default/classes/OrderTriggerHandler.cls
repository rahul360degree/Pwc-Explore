/*------------------------------------------------------------------------
Author:        Kishor Kumar
Company:       Salesforce
Description:   Handler class for Order Trigger
Inputs:        NA
Test Class:    
History
02-04-2020      Kishor Kumar     Initial Release
07-07-2020      Kartik Shetty    Method to populate order type field based on opportunity type.
10-07-2020      Kartik Shetty    Method to enforce validation rules on order.
----------------------------------------------------------------------------*/
public with sharing class OrderTriggerHandler extends VTriggerHandler {
    
    // Allows unit tests (or other code) to disable this trigger for the transaction
    public static Boolean TriggerDisabled = false;
 
    /*
        Checks to see if the trigger has been disabled either by custom setting or by running code
    */
    public override Boolean IsDisabled(){
        Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
        if (setting.OrderTriggerDisabled__c)
            return true;
        else 
            return TriggerDisabled;
    }
    
    
    /*------------------------------------------------------------------------
    Author:        Kishor Kumar
    Company:       Salesforce
    Description:   Method to handle before Insert event context of Order Trigger
    Inputs:        list of inserted records
    Test Class:   

    History
    02-04-2020      Kishor Kumar     Initial Release
    07-07-2020      Kartik Shetty    Method to populate order type field based on opportunity type.
    ----------------------------------------------------------------------------*/   
    public override void BeforeInsert(list<SObject> newItems){        
        OrderFieldPopulator fieldPopulator = new OrderFieldPopulator();
        fieldPopulator.populatePriceBookonOrder((list<Order>)newItems,null);
        fieldPopulator.calculateOrderAmount((list<Order>)newItems,null); //Modified by Shreela on 30th March 2023
        //fieldPopulator.calculateOrderAmount((list<Order>)newItems); 
        fieldPopulator.populateOrderTypeField( (List<Order>) newItems);
        SoldToPricebookUtility.setDefaultAtOrder((list<Order>)newItems); 
        fieldPopulator.populateDefaults((list<Order>)newItems);
        fieldPopulator.populateShipToOnOrder((list<Order>)newItems);       
        fieldPopulator.CheckForActiveSoldToBranch((list<Order>)newItems,null);
        SharingUtility.setParentContacts(newItems, null, false, false);
        //Update Approver on Order 
        fieldPopulator.populateApproversForInternalUsers((list<Order>)newItems);
        fieldPopulator.populateApproverForExternalUser((list<Order>)newItems);
        //validate Planned Delivery Date
        fieldPopulator.validatePlannedDeliveryDate(null,(list<Order>)newItems); //Modified by Shreela on 28th June 2022
        fieldPopulator.populateEndCustomerOnOrder((list<Order>)newItems);
        
        // Warehouse defaulting function.
        fieldPopulator.populateDefaultOrderWarehouses((List<Order>) newItems);
        GlobalConstants.isBeforeInsert =true;//Added by pankaj on 5/12/2022 for SMEPB-48
        fieldPopulator.populateMHESanctionApprovalFields( (List<Order>) newItems); //SMF-59:Adding sanction for MHE
        fieldPopulator.populateMHELeadTimeBOMDiscountFields((List<Order>) newItems);// //Added by pankaj on 4th april 2023 for SMEPB-85
        fieldPopulator.SendOrderToLNonUpdateofNewAPD((list<Order>)newItems,null);//added for SAF-196
    }
    
    /*------------------------------------------------------------------------
    Author:        Kishor Kumar
    Company:       Salesforce
    Description:   Method to handle Befor Update event context of Order Trigger
    Inputs:        map of created records
    Test Class:   

    History
    02-04-2020      Kishor Kumar     Initial Release
    07-07-2020      Kartik Shetty    Method to populate order type field based on opportunity type.
    10-07-2020      Kartik Shetty    Method to enforce validation rules on order.
    ----------------------------------------------------------------------------*/
    public override void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        OrderFieldPopulator fieldPopulator = new OrderFieldPopulator();
        fieldPopulator.orderValidations( (Map<Id, Order>) newItems, (Map<Id, Order>) oldItems);
        fieldPopulator.populatePriceBookonOrder((list<Order>)newItems.values(),(Map<Id,Order> )oldItems);
        fieldPopulator.calculateOrderAmount((list<Order>)newItems.values(),(Map<Id,Order> )oldItems); //Modified by Shreela on 30th March 2023
        //fieldPopulator.calculateOrderAmount((list<Order>)newItems.values());
        fieldPopulator.populateOrderTypeField( (List<Order>) newItems.values());
        fieldPopulator.populateShipToOnOrder((list<Order>)newItems.values());
        fieldPopulator.populateOrderReferenceNumberExt((list<Order>)newItems.values());
        fieldPopulator.CheckForActiveSoldToBranch((list<Order>)newItems.Values(),(Map<Id,Order>)oldItems);
        fieldPopulator.checkForOrderSubmitterForSSG((map<Id, Order>) newItems, (map<Id, Order>) oldItems);
        //validate Planned Delivery Date
        fieldPopulator.validatePlannedDeliveryDate((map<Id, Order>) oldItems,(list<Order>)newItems.values()); //Modified by Shreela on 28th June 2022
        //update intent field on update
        fieldPopulator.updateIntentOnUpdate((map<Id, Order>)newItems, (map<Id, Order>)oldItems);
        //update External Approver(Appliances) on Order 
        fieldPopulator.populateApproverForExternalUser((map<Id, Order>)newItems, (map<Id, Order>)oldItems);
        
        // Warehouse defaulting and validation functions.
        fieldPopulator.populateDefaultOrderWarehouses((List<Order>) newItems.values());
        fieldPopulator.validateOrderWarehouses((Map<Id, Order>) newItems, (List<Order>) oldItems.values());
		fieldPopulator.restrictUpdatesOnApprovedMHEOrders((Map<Id,Order>) newItems,(Map<Id,Order>) oldItems); // SMEB41 Added to restrict updates post approval is sought      
        SharingUtility.setParentContacts(newItems.values(), oldItems, false, false);
        //Added by pankaj on 5/12/2022 for SMEPB-48
        if(GlobalConstants.isBeforeInsert ==False){
        	fieldPopulator.mheEquipOrderValidation((List<Order>) newItems.values());//Added by Pankaj on 5 dec 2022
        }
        fieldPopulator.populateMHELeadTimeBOMDiscountFields((List<Order>) newItems.values());//Added by pankaj on 4th april 2023 for SMEPB-85
        fieldPopulator.SendOrderToLNonUpdateofNewAPD((list<Order>)newItems.values(),(Map<Id,Order> )oldItems);//added for SAF-196
    }

    /*------------------------------------------------------------------------
    Author:        Pawan
    Company:       Salesforce
    Description:   Method to handle After Insert event context of Order Trigger
    Inputs:        map of created records
    Test Class:   

    History
    02-04-2020      Pawan     Initial Release
    ----------------------------------------------------------------------------*/
    public override void AfterInsert(map<Id, sObject> newItems){
        OrderFieldPopulator fieldPopulator = new OrderFieldPopulator();
        fieldPopulator.createOrderItems(newItems);
        
        //ADDED BY PRAFUL - ADDED RECURSION HANDLE
        if(GlobalConstants.ALLOW_TRIGGER_TO_EXECUTE){
            for(Order newRecord : (List<Order>)newItems.values()){
                GD_CheckBalance.callAPIfuture(newRecord.Id);
                break;
            }
        }
    }
    
    /*------------------------------------------------------------------------
    Author:        Manasi Londhe
    Company:       Salesforce
    Description:   Method to handle after Update event context of Order Trigger
    Inputs:        map of created records
    Test Class:   

    History
    18-05-2020      Manasi Londhe   Initial Release
    ----------------------------------------------------------------------------*/
    public override void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        
        //ADDED BY PRAFUL - ADDED RECURSION HANDLE
        if(GlobalConstants.ALLOW_TRIGGER_TO_EXECUTE){
            for(Order newRecord : (List<Order>)newItems.values()){
                GD_CheckBalance.callAPIfuture(newRecord.Id);
                break;
            }
        }
        
        DiscountMatrixProcessor processor=new DiscountMatrixProcessor();
        processor.updateDiscountCodeOnOrderUpdate((Map<Id, Order>)newItems,(Map<Id,Order>) oldItems);
        
        OrderFieldPopulator fieldPopulator = new OrderFieldPopulator();
        fieldPopulator.updateOrderItemWarehouses((Map<Id, Order>) newItems, (List<Order>) oldItems.values());
        fieldPopulator.generateClaimRequestForOrders((Map<Id, Order>)newItems,(Map<Id,Order>) oldItems);
        fieldPopulator.OrderNotificationToMheOutrightUser((Map<Id,Order>)newItems,(Map<Id,Order>) oldItems); //Added By Shreela on 5th April2022 for Jira number - SMEPB 19 
        }
    
}