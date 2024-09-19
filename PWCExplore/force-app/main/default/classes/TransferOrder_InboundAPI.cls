@RestResource(urlMapping='/Transfer_OrderInbound')
Global class TransferOrder_InboundAPI {
    @HttpPost
    global static void createOrder() {
        // Obtain the incoming REST request.
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        string message;
        string response; 
        list<ErrorSuccessResponse> listResponse=new list<ErrorSuccessResponse>();
        
        try{
            string JSONReq= RestContext.request.requestBody.toString();
            system.debug('JSONReq :'+JSONReq);
             ErrorSuccessResponse errorResponse=new ErrorSuccessResponse();         
            list<Transfer_Order__c> InsertTransferOrder=new list<Transfer_Order__c>();
            
            set<string> fromwarehouse =new set<string>();
            set<string> towarehouse =new set<string>();
            set<string> itemcode =new set<string>();
            
            list<RequestJSONWrapper> TransferOrderReq= (list<RequestJSONWrapper>)JSON.deserialize(JSONReq,list<RequestJSONWrapper>.class);
            
            for(RequestJSONWrapper eachTO : TransferOrderReq){
                
                //ErrorSuccessResponse errorResponse=new ErrorSuccessResponse();
                if(String.isNotBlank(eachTO.fromWarehouse) ){
                    fromwarehouse.add(eachTO.fromWarehouse); 
                    system.debug('from warehouse26 :'+eachTO.fromWarehouse);
                }
                else{
                    system.debug('from warehouse should not be null or empty');
                    //message ='from warehouse should not be null or empty';
                    break;
                    
                }
                if(String.isNotBlank(eachTO.toWarehouse)){
                    towarehouse.add(eachTO.toWarehouse);
                }
                else{
                    system.debug('To warehouse should not be null or empty');
                    
                }
                if(String.isNotBlank(eachTO.itemcode)){
                    itemcode.add(eachTO.itemcode);
                }
                else{
                    
                    system.debug('To warehouse should not be null or empty');
                    
                }
                
                
            }
            
            list<warehouse__c> fromwarehouslist =[select id,Warehouse__c from warehouse__c where Warehouse__c =: fromwarehouse];
            system.debug('fromwarehouslist :'+fromwarehouslist);
            map<string,warehouse__c> mapfromwarehouse =new  map<string,warehouse__c>();
            if(!fromwarehouslist.isEmpty()){
                for(warehouse__c fromware : fromwarehouslist){
                    mapfromwarehouse.put(fromware.Warehouse__c,fromware);             
                }             
                
            }            
            list<warehouse__c> towarehouslist =[select id,Warehouse__c from warehouse__c where Warehouse__c =: towarehouse];
            
            map<string,warehouse__c> map_towarehouse =new  map<string,warehouse__c>();
            if(!towarehouslist.isEmpty()){
                for(warehouse__c each_towarehouse : towarehouslist){
                    map_towarehouse.put(each_towarehouse.Warehouse__c,each_towarehouse);             
                }             
                
            }
            
            list<Product2>  productitemcode =[select id, Item__c from Product2 where Item__c =: itemcode];
            system.debug('productitemcode'+productitemcode);
            map<string,Product2> ProductItemcodemap=new map<string,Product2>();
            
            if(!productitemcode.isempty()){
                for(Product2 prcode: productitemcode){
                    ProductItemcodemap.put(prcode.Item__c,prcode);
                    
                }
            }
            
            for(RequestJSONWrapper eachTO : TransferOrderReq){
                
                if( String.isBlank(eachTO.fromWarehouse) || String.isBlank(eachTO.toWarehouse) || String.isBlank(eachTO.itemcode) ){
                    
                    ErrorSuccessResponse errorResponse1= GenericResponse('itemcode, from warehouse, To warehouse should not be null or empty.',false,null);
                    listResponse.add(errorResponse1);
                    
                }
                else if(String.isBlank(eachTO.logisticCompanyNumber) || String.isBlank(eachTO.transferordernumber) || String.isBlank(eachTO.requestPosition)){
                    ErrorSuccessResponse errorResponse2= GenericResponse('logistic Company Number,  Transfer Order Number, Request Position should not be null or empty',false,null); 
                    listResponse.add(errorResponse2);
                }
                else if(!mapfromwarehouse.containsKey(eachTO.fromWarehouse)){
                    
                    ErrorSuccessResponse errorResponse3 = GenericResponse('From Warehouse does '+eachTO.fromWarehouse+ ' not exist  in Salesforce.',false,null);
                    listResponse.add(errorResponse3);
                    
                }
                else if(!map_towarehouse.containsKey(eachTO.toWarehouse) ){ 
                    
                    ErrorSuccessResponse errorResponse4= GenericResponse('To Warehouse does '+ eachTO.toWarehouse +' not exist  in Salesforce.', false,null);
                    listResponse.add(errorResponse4);
                    
                }
                else if(!ProductItemcodemap.containsKey(eachTO.itemcode)){
                    
                    ErrorSuccessResponse errorResponse5=GenericResponse('Item Code '+ eachTO.toWarehouse +' not exist  in Salesforce.', false,null);
                    listResponse.add(errorResponse5);
                    
                }
                
                else {
                    
                    Transfer_Order__c ObjTransferOrder=new Transfer_Order__c();
                    
                    ObjTransferOrder.TO_Number__c =eachTO.transferordernumber;
                    ObjTransferOrder.From_Warehouse__c = mapfromwarehouse.get(eachTO.fromWarehouse).id;
                    ObjTransferOrder.To_Warehouse__c =map_towarehouse.get(eachTO.toWarehouse).id;
                    ObjTransferOrder.Logistics_Company_Branch__c = eachTO.logisticCompanyNumber;
                    ObjTransferOrder.Order_Type__c = eachTO.orderType;
                    ObjTransferOrder.Item_Code__c = eachTO.itemcode;
                    ObjTransferOrder.Product__c =ProductItemcodemap.get(eachTO.itemcode).id;  
                    ObjTransferOrder.Sales_Order_Series__c = eachTO.orderSeries;
                    ObjTransferOrder.Line_Position__c =Integer.valueOf(eachTO.requestPosition);
                    ObjTransferOrder.Transfer_Order_Unit__c = eachTO.transferunit;
                    ObjTransferOrder.Transfer_Quantity__c =Integer.valueOf(eachTO.transferQty);
                    ObjTransferOrder.Integration_Status__c = 'Synced';
                    ObjTransferOrder.Infor_status__c = 'Approved';
                    
                    InsertTransferOrder.add(ObjTransferOrder);
                    
                }  
                
            }
            if(!InsertTransferOrder.isempty()){
                insert InsertTransferOrder;
                for(Transfer_Order__c TOresponse :InsertTransferOrder ){
                    
                    ErrorSuccessResponse successResponse = GenericResponse('Transfer Order Created successfully.', true, TOresponse.id);
                    listResponse.add(successResponse);
                   /* errorResponse.status=true;
                    errorResponse.message = 'Transfer Order Created successfully.' ;
                    errorResponse.TransferOrderId=TOresponse.id;
                    listResponse.add(errorResponse);*/
                    
                }  
            }           
            
            system.debug('listResponse :'+listResponse);
            response =JSON.serialize(listResponse); 
            system.debug('response :'+response);
            res.addHeader('Content-Type', 'application/json');
            res.responseBody = Blob.valueOf(response);
            
        }
        catch(Exception ex){
            
            System.debug('Error '+ex.getMessage());
            System.debug('Error '+ex.getLineNumber());
            ErrorSuccessResponse errorResponse = GenericResponse(ex.getMessage(), false,null);
                        
            response =JSON.serialize(listResponse);
            res.addHeader('Content-Type', 'application/json');
            res.responseBody = Blob.valueOf(response);
        }
    }
    public static ErrorSuccessResponse GenericResponse(string message, boolean status,string TransferOrderId){
        ErrorSuccessResponse errorResponse=new ErrorSuccessResponse();
        errorResponse.status=status;
        errorResponse.message = message;
        errorResponse.TransferOrderId = TransferOrderId;
        return errorResponse;
    }
    
    public class RequestJSONWrapper {
        public String logisticCompanyNumber;
        public String fromWarehouse;
        public String toWarehouse;
        public String orderType;
        public String orderSeries;
        public String requestPosition;
        public String itemCode;
        public String transferunit;
        public String transferQty;
        public String transferordernumber;
    }
    public class ErrorSuccessResponse{
        public boolean status;
        public string message;
        public string TransferOrderId;
        
    }
    
}