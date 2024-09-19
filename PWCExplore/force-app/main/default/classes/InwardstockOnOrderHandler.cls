public class InwardstockOnOrderHandler {
    @AuraEnabled
    public static List<OrderItem> getOrderItemData(Id orderId){
        try {
            List<OrderItem> orderItemList = [SELECT ID,OrderItemNumber,Item_Code__c,Product2.Name FROM OrderItem WHERE OrderId =: orderId];
            System.debug(orderItemList);
            return orderItemList;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}