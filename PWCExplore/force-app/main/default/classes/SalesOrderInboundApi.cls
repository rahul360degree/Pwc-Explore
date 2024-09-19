@RestResource(urlMapping='/CreateSALES_Order')
global class SalesOrderInboundApi {
    
    
    
    @HttpPost
    global static void CreateSALES_Order() {
        
        // Obtain the incoming REST request.
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        
         try {
            //String jsonString = req.requestBody.toString();
            //List<BulkAPIHelper.OrderWrapper> orders = (List<BulkAPIHelper.OrderWrapper>) JSON.deserialize(jsonString, List<BulkAPIHelper.OrderWrapper>.class);
            
             List<SalesOrderBulkAPIHelper.JSONRequestWrapper> requestWrapperList = (List<SalesOrderBulkAPIHelper.JSONRequestWrapper>) JSON.deserialize(req.requestbody.toString(), List<SalesOrderBulkAPIHelper.JSONRequestWrapper>.class); 
        
             
            Map<String, Id> mapOrderRefAndId = SalesOrderBulkAPIHelper.generateCSVOrders(requestWrapperList);
            
            // Now you have the CSV data, you can proceed to send it to the Bulk API
            // Write your code here to send csvData to Bulk API
            
            // For now, let's just return the CSV data as the response
            res.statusCode = 200;
            //res.responseBody = Blob.valueOf(csvData);
        } catch (Exception e) {
            res.statusCode = 500;
            res.responseBody = Blob.valueOf('Error: ' + e.getMessage());
        }
        
        
        
        /*
        
        // Deserialize the JSON request body into a list of JSONRequestWrapper objects.
        List<JSONRequestWrapper> requestWrapperList = (List<JSONRequestWrapper>) JSON.deserialize(req.requestbody.toString(), List<JSONRequestWrapper>.class); 
        
        
        Integer chunkSize = 500;
        
        for(Integer i = 0; i <= requestWrapperList.size() ; i += chunkSize){
            
            List<JSONRequestWrapper> orderChunkList = new List<JSONRequestWrapper>();
            
            for(Integer j = i; j < Math.min(i + chunkSize, requestWrapperList.size()); j++){
                
                orderChunkList.add(requestWrapperList[j]); 
            }
            
            processOrderChunk(orderChunkList, req, res);
        }
    }    
    
    public static void processOrderChunk(List<JSONRequestWrapper> JSONRequestWrapperList, RestRequest req, RestResponse res){
        
        try{
            
            List<OrderWrapper> orderWrapperList = new List<OrderWrapper>();
            
            List<OrderProductWrapper> orderProductWrapperList = new List<OrderProductWrapper>();
            
            for(JSONRequestWrapper eachJSONRec : JSONRequestWrapperList) {
                orderWrapperList.add(eachJSONRec.orderRec);
                orderProductWrapperList.addAll(eachJSONRec.orderProducts);
            }
             
            
            
            List<Order> ordersToInsert = new List<Order>();
            List<OrderItem> orderItemToInsert = new List<OrderItem>();
            
            for(OrderWrapper orderWrapRec : orderWrapperList){
                Order ordObj = new Order();
                ordersToInsert.add(ordObj);
                
            }
            
            if(ordersToInsert.size()>0){
                insert ordersToInsert;
            }
            
            
            for(OrderProductWrapper eachItem: orderProductWrapperList){
                OrderItem itemObj = new OrderItem();
                orderItemToInsert.add(itemObj);
            }
            
            if(orderItemToInsert.size()>0){
                insert orderItemToInsert;
            } 
            
            res.statusCode = 200;
            res.addHeader('Content-Type', 'application/json');
            res.responseBody = Blob.valueOf(JSON.Serialize(new Map<String, String>{'success'=> 'true', 'message'=>'Success: Sales Order Created Successfully'}));
        }catch(Exception e){
            System.debug('Error '+e.getMessage());
            System.debug('Error '+e.getLineNumber());
            res.statusCode = 500;
            res.addHeader('Content-Type', 'application/json');
            res.responseBody = Blob.valueOf(JSON.Serialize(new Map<String, String>{'success'=> 'false', 'message'=>e.getMessage()}));
        }

*/
        
        
    }
    
    
    
         
}