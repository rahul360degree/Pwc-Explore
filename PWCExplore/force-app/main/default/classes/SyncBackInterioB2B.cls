/**
* @description       : On sync Back Update Quote Line Item to Opportunity Line Item
* @author            : snehalw@godrej.com
* @group             : 
* @last modified on  : 23-11-2023
* @last modified by  : snehalw@godrej.com
**/
public class SyncBackInterioB2B {
    
    @invocableMethod
    public static void updateOppLineItem(List<Id> quoteId){
        Map<Id, Decimal> quoteLineItemMap = new Map<Id, Decimal>();// To store OpportunityLineitemId and finalorderBookingprice for each QLI
        for (QuoteLineItem quoteLineItem : [SELECT Id,Opportunity_Line_Item_ID__c,Final_Order_Booking_price__c,Quote_Record_Type__c  FROM QuoteLineItem WHERE QuoteId IN:quoteId AND Quote_Record_Type__c='Interio_B2B_Finished_Good']) {
            quoteLineItemMap.put(quoteLineItem.Opportunity_Line_Item_ID__c, quoteLineItem.Final_Order_Booking_price__c);
        }
        
        List<OpportunityLineItem> oppLineItemsToUpdate = new List<OpportunityLineItem>();
        
        for (OpportunityLineItem oppLineItem : [SELECT Id,UnitPrice  FROM OpportunityLineItem WHERE Id IN :quoteLineItemMap.keySet()]) {
           if(quoteLineItemMap.get(oppLineItem.Id) != Null){
                oppLineItem.UnitPrice = quoteLineItemMap.get(oppLineItem.Id);
                oppLineItemsToUpdate.add(oppLineItem);
           }           
        }
        if (!oppLineItemsToUpdate.isEmpty()) {
            update oppLineItemsToUpdate;
        }
    }    
}