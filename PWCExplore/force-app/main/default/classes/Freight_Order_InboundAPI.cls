@RestResource(urlMapping='/FreightOrderInbound')

global class Freight_Order_InboundAPI {
    @HttpPost
    global static void createOrder() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        string response; 
        list<ErrorSuccessResponse> listResponse=new list<ErrorSuccessResponse>();
        
        try{
            string JSONReq= RestContext.request.requestBody.toString();
            list<Freight_Order__c> insertFO = new list<Freight_Order__c>();
           // system.debug('JSONReq :'+JSONReq);
            ErrorSuccessResponse errorResponse=new ErrorSuccessResponse();         
            
            set<string> MSOitemcode =new set<string>();
            list<string> MSOordernumber =new list<string>();
            
            list<string> ordernumber =new list<string>();
             set<string> itemcode =new set<string>();
            map<string,RequestJSONWrapper> mapitem =new map<string,RequestJSONWrapper>();
            map<string,ReturnOrderLineItem> mapMSOLI =new map<string,ReturnOrderLineItem>();
             map<string,OrderItem> mapSOLI =new map<string,OrderItem>();
            
            list<RequestJSONWrapper> freightrOrderReq= (list<RequestJSONWrapper>)JSON.deserialize(JSONReq,list<RequestJSONWrapper>.class);
            system.debug('freightrOrderReq'+freightrOrderReq);
            for(RequestJSONWrapper eachFO : freightrOrderReq){
                
                mapitem.put(eachFO.Item,eachFO);
                
                system.debug('Originating_OrderOrigin:'+ eachFO.Originating_OrderOrigin);
                if(eachFO.Originating_OrderOrigin == 'Maintenance Sales'){
                    MSOordernumber.add(eachFO.Originating_OrderNumber);
                    MSOitemcode.add(eachFO.Item);
                    //mapitem.put(eachFO.Item,eachFO);
                    
                }
                else{
                    
                    ordernumber.add(eachFO.Originating_OrderNumber);
                    itemcode.add(eachFO.Item);
                     system.debug('Originating_OrderOrigin:'+ eachFO.Originating_OrderOrigin);
                    
                }
                
            }
            list<ReturnOrderLineItem> MSOlineitemlist=[ select id,MSO_Number__c,Item_Code__c,MSO_Line_Position__c,ReturnOrderId from ReturnOrderLineItem where Item_Code__c =:MSOitemcode and MSO_Number__c =:MSOordernumber ];
            
            list<orderitem> salesorder = [select id,OrderId,order.OrderReferenceNumber,Item_Code__c,Order_Line_Position__c,Order_Number__c from orderitem where order.OrderReferenceNumber =:ordernumber and Item_Code__c =:itemcode];
            system.debug('salesorder :'+salesorder);
            for(ReturnOrderLineItem MSOlineitem :MSOlineitemlist){
                system.debug('MSOlineitem.Item_Code__c'+MSOlineitem.Item_Code__c);
                
                if(mapitem.containsKey(MSOlineitem.Item_Code__c)){
                    system.debug('true45');
                    if( Integer.valueOf(mapitem.get(MSOlineitem.Item_Code__c).Originating_OrderLineNumber) == MSOlineitem.MSO_Line_Position__c && mapitem.get(MSOlineitem.Item_Code__c).Originating_OrderNumber == MSOlineitem.MSO_Number__c  ){
                        mapMSOLI.put(MSOlineitem.Item_Code__c,MSOlineitem);
                        system.debug('true48');
                    }
                    
                }
            }
            for(OrderItem orderitems :salesorder){
                 if(mapitem.containsKey(orderitems.Item_Code__c)){
                    system.debug('true62');
                    if( Integer.valueOf(mapitem.get(orderitems.Item_Code__c).Originating_OrderLineNumber) == orderitems.Order_Line_Position__c && mapitem.get(orderitems.Item_Code__c).Originating_OrderNumber == orderitems.Order_Number__c ){
                        mapSOLI.put(orderitems.Item_Code__c,orderitems);
                        system.debug('true65');
                    }
                    
                }
                
                
            }
            //system.debug('mapSOLI :'+mapSOLI);
            
            //Error Handling.
            for(RequestJSONWrapper eachFO : freightrOrderReq){
                if( String.isBlank(eachFO.FreightOrderNumber) || String.isBlank(eachFO.Originating_OrderOrigin) || String.isBlank(eachFO.FreightOrderLineNo) ){
                    
                    ErrorSuccessResponse errorResponse1= GenericResponse('Freight Order Number, Originating Order Origin, Freight Order Line No. should not be null or empty.',false,null);
                    listResponse.add(errorResponse1);
                    
                }else if( String.isBlank(eachFO.Originating_OrderNumber) || String.isBlank(eachFO.Originating_OrderLineNumber) ){
                    
                    ErrorSuccessResponse errorResponse2= GenericResponse('Originating Order Number , Originating Order Line Number should not be null or empty.',false,null);
                    listResponse.add(errorResponse2);
                    
                }
                else if( String.isBlank(eachFO.Item)  || String.isBlank(eachFO.Originating_OrderLineSequence)){
                    
                    ErrorSuccessResponse errorResponse3= GenericResponse('itemcode,Line Sequence should not be null or empty.',false,null);
                    listResponse.add(errorResponse3);
                    
                }
                
                else{
                    Freight_Order__c objFO =new Freight_Order__c();
                    //system.debug('msoid :'+mapMSOLI.get(eachFO.Item).ReturnOrderId);
                    if(mapMSOLI.containsKey(eachFO.Item)){
                        system.debug('msoid :'+mapMSOLI.get(eachFO.Item).ReturnOrderId);
                        objFO.MS_Order__c =mapMSOLI.get(eachFO.Item).ReturnOrderId;
                      
                    }else{
                        objFO.Related_Order__c =mapSOLI.get(eachFO.Item).OrderId;
                        
                    }
                                        
                    objFO.Freight_Order_Number__c = eachFO.FreightOrderNumber;
                    objFO.Logistics_Company__c = eachFO.LogisticsCompany;
                    objFO.Freight_Order_Line_No__c = Integer.valueOf(eachFO.FreightOrderLineNo);
                    objFO.Freight_Order_Header_Status__c = eachFO.FreightOrderHeaderStatus;
                    objFO.Ship_From_Company__c = eachFO.ShipFromCompany;
                    objFO.Originating_Order_Origin__c = eachFO.Originating_OrderOrigin;
                    objFO.Originating_OrderLineNumber__c = Integer.valueOf(eachFO.Originating_OrderLineNumber);
                    objFO.Originating_OrderNumber__c = eachFO.Originating_OrderNumber;
                    objFO.Originating_OrderLineSequence__c = Integer.valueOf(eachFO.Originating_OrderLineSequence);
                    objFO.Project__c = eachFO.Project;
                    objFO.Item__c = eachFO.Item;
                    objFO.Unit__c = eachFO.unit;
                    objFO.Blocked__c = eachFO.blocked;
                    objFO.DeliveryTerms__c =eachFO.DeliveryTerms;
                    objFO.DeliveryTerms_Description__c = eachFO.DeliveryTerms_Description;
                    objFO.TransactionType__c = eachFO.TransactionType;
                    objFO.Standard_Route__c = eachFO.StandardRoute;
                    objFO.Planned_Load_DateTime__c = date.valueOf(eachFO.Planned_Load_DateTime);
                    objFO.Planned_Unload_DateTime__c = date.valueOf(eachFO.Planned_Unload_DateTime);
                    
                    insertFO.add(objFO);
                    
                }
                
            }
            if(!insertFO.isempty()){
                insert insertFO;
                for( Freight_Order__c fo:insertFO){
                    ErrorSuccessResponse successResponse = GenericResponse('Freight Order Created successfully.', true, fo.id);
                    listResponse.add(successResponse);

                }
            }
            system.debug('listResponse :'+listResponse);
            response =JSON.serialize(listResponse); 
            system.debug('response :'+response);
            res.addHeader('Content-Type', 'application/json');
            res.responseBody = Blob.valueOf(response);
            
        }catch(Exception ex){
            
             System.debug('Error '+ex.getLineNumber());
            System.debug('ex.getMessage() '+ex.getMessage());
            
            ErrorSuccessResponse errorResponse = GenericResponse(ex.getMessage(), false,null);
            listResponse.add(errorResponse);
                        
            response =JSON.serialize(listResponse);
            res.addHeader('Content-Type', 'application/json');
            res.responseBody = Blob.valueOf(response);
            
        }
        
    }
    
    public static ErrorSuccessResponse GenericResponse(string message, boolean status,string FreightOrderId){
        ErrorSuccessResponse errorResponse=new ErrorSuccessResponse();
        errorResponse.status=status;
        errorResponse.message = message;
        errorResponse.FreightOrderId = FreightOrderId;
        return errorResponse;
    }
    
    public class RequestJSONWrapper {
        public String FreightOrderNumber;
        public String LogisticsCompany;
        public String FreightOrderLineNo;
        public String FreightOrderHeaderStatus;
        public String ShipFromCompany;
        public String Originating_OrderOrigin;
        public String Originating_OrderLineNumber;
        public String Originating_OrderNumber;
        public String Originating_OrderLineSequence;
        public String Project;
        public String Item;
        public String unit;
        public String Blocked;
        public String DeliveryTerms;
        public String DeliveryTerms_Description;
        public String TransactionType;
        public String StandardRoute;
        public string Planned_Load_DateTime;
        public string Planned_Unload_DateTime;
    }
    public class ErrorSuccessResponse{
        public boolean status;
        public string message;
        public string FreightOrderId;
        
    }
}