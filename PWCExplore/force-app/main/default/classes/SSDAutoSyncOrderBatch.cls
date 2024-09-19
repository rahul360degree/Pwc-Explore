/**
* @description       : sync failed orders should auto sync
* @author            : snehalw@godrej.com
* @group             : 
* @last modified on  : 17-08-2023
* @last modified by  : snehalw@godrej.com
**/
public class SSDAutoSyncOrderBatch implements Schedulable {
    public void execute(SchedulableContext context) {
        // Get the failed orders
        List<Order> failedOrders = [SELECT Id,Business_Unit__c,Integration_Status__c FROM Order
                                    where Business_Unit__c =: GlobalConstants.SSD_BUSINESS_UNIT AND Integration_Status__c =: GlobalConstants.INTEGRATION_STATUS_SYNC_FAILED];
        
        // Convert failed orders to ready to sync
        List<Order> ordersToUpdate = new List<Order>();
        for (Order orderStatus : failedOrders) {
            orderStatus.Integration_Status__c = GlobalConstants.INTEGRATION_STATUS_READY_TO_SYNC; // Set the status to ready to sync
            ordersToUpdate.add(orderStatus);
        }              
        update ordersToUpdate;
    }
}