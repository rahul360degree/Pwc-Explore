/**
 * @Description       : // Called from OLIFieldPopulator.orderSplit
 * @Author            : Varun Rajpoot
 * @last modified on  : 12-22-2023
 * @last modified by  : Varun Rajpoot
 * Modifications Log
 * Ver   Date         Author          Modification
 * 1.0   12-22-2023   Varun Rajpoot   Initial Version
**/
public with sharing class OrderLineItemsSplit implements Queueable,Database.AllowsCallouts{
    List<OrderItem> orderItems;
    public  OrderLineItemsSplit(List<OrderItem> orderItems){
        this.orderItems = orderItems;
    }
    
    //Queueable method to update the status
    public void execute(QueueableContext context) {
            insert orderItems;
     }
}