public class Transfer_OrderControllerCallout {
    public static void TransferOrderCallout(Id recordid){
       
        try{

            List<Transfer_Order__c> lstTransferOrder = [Select Id,Transfer_Order_Unit__c, Name,From_Warehouse__c, Item_Code__c, Line_Position__c, Logistics_Company_Branch__c, MSO__c,
                                                        MSO_Line_Item__c, Order__c,Transfer_Quantity__c, Order_Product__c, Order_Type__c, Product__c,
                                                        Sales_Order_Series__c, SF_Id__c, TO_Number__c, To_Warehouse__c,MSO__r.ReturnOrderNumber, MSO__r.MSO_Number__c
                                                        from Transfer_Order__c where Id =: recordid ];
            
            System.debug('>>>>>>lstTransferOrder>>>>>>>'+lstTransferOrder);
            if(lstTransferOrder != null && lstTransferOrder.size() == 1){
                
                string FromWarehousecode =[select id,Warehouse__c from warehouse__c where id =: lstTransferOrder[0].From_Warehouse__c limit 1].Warehouse__c;
                string ToWarehousecode =[select id,Warehouse__c from warehouse__c where id =: lstTransferOrder[0].To_Warehouse__c limit 1].Warehouse__c;
                string ItemCode =[select id, Item__c from Product2 where id =: lstTransferOrder[0].Product__c limit 1].Item__c;
                
                
                RequestJSONWrapper objRW=new RequestJSONWrapper();
                objRW.logisticCompanyNumber = lstTransferOrder[0].Logistics_Company_Branch__c;
                objRW.itemCode = ItemCode;
                objRW.fromWarehouse = FromWarehousecode;
                objRW.orderSeries = lstTransferOrder[0].Sales_Order_Series__c;
                objRW.orderType =lstTransferOrder[0].Order_Type__c;
                objRW.requestPosition = string.valueOf(lstTransferOrder[0].Line_Position__c);
                objRW.toWarehouse =lstTransferOrder[0].To_Warehouse__c;
                objRW.unit = lstTransferOrder[0].Transfer_Order_Unit__c;
                objRW.transferQty = string.valueOf(lstTransferOrder[0].Transfer_Quantity__c);
                objRW.vendorName ='SFDC Service Cloud';
                
                String JSONData = JSON.serialize(objRW);
                Http h = new Http();
                
                HttpRequest request = new HttpRequest();
                request.setEndpoint('https://servicecloudtest.godrej.com/ServiceCloudWS/api/LNIntegration/warehouseTransferOrder');
                request.setMethod('POST');       
                request.setHeader('Content-Type', 'application/json');
                request.setHeader('Authorization','Basic U2FtZWVyOkF2aGFk');
                request.setBody(JSONData);
                HttpResponse res = h.send(request); 
                System.debug('Response: '+ res);
                System.debug('Response code: '+  res.getStatusCode());
                
            }
        }
        catch(Exception ex){
            
        }
        
        
    }
    
    public class RequestJSONWrapper {
        public String documentID;
        public String logisticCompanyNumber;
        public String fromWarehouse;
        public String toWarehouse;
        public String orderType;
        public String orderSeries;
        public String requestPosition;
        public String itemCode;
        public String unit;
        public String transferQty;
        public String vendorRequestID;
        public String vendorName;
    }
    
}