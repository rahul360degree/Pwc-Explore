@RestResource(urlMapping='/PandoInbound')

global class Pando_InboundAPI {
    
    @HttpPatch
    global static void UpdateFreightOrder() {
        
        RestResponse res = RestContext.response;
        string JSONReq= RestContext.request.requestBody.toString();
        
        string response; 
        list<ErrorSuccessResponse> listResponse=new list<ErrorSuccessResponse>();
        
        list<string> freightorderNumber= new list<string>();
        map<string,Freight_Order__c> mapFO = new map<string,Freight_Order__c>();
        
        
        list<RequestJSONWrapper> listRequestJson= (list<RequestJSONWrapper>)JSON.deserialize(JSONReq,list<RequestJSONWrapper>.class);
        
        for(RequestJSONWrapper RequestJson : listRequestJson ){
            if(RequestJson.FreightOrderNumber == null){
                
                ErrorSuccessResponse errorResponse = GenericResponse('Freight Order Number should not null or empty. ', false,null);
                listResponse.add(errorResponse);
            }
            else{
                freightorderNumber.add(RequestJson.FreightOrderNumber);
            }
            if(RequestJson.freight_planning_company == null){
                
            }
            
        }
        if(!freightorderNumber.isempty()){
            
            list<Freight_Order__c> FOlist =[select id ,Freight_Order_Line_No__c, Freight_Order_Number__c,Item__c, Logistics_Company__c from Freight_Order__c where Freight_Order_Number__c =: freightorderNumber];
            
            for(Freight_Order__c FO: FOlist){
                
                mapFO.put(FO.Item__c,FO);
                
            }
        }
        for(RequestJSONWrapper eachFO : listRequestJson){
            
            if( eachFO.FreightOrderNumber == mapFO.get(eachFO.Item).Freight_Order_Number__c && eachFO.FreightOrderLineNo == string.valueOf(mapFO.get(eachFO.Item).Freight_Order_Line_No__c) && eachFO.freight_planning_company == mapFO.get(eachFO.Item).Logistics_Company__c  ){
                
                Freight_Order__c objFO = new Freight_Order__c();
                
                objFO.Id =mapFO.get(eachFO.FreightOrderNumber).id;
                objFO.Vehicle_Number__c = eachFO.vehicle_number;
                objFO.Vehicle_Type__c = eachFo.vehicle_type;
                objFO.Driver_Number__c = eachFO.driver_number;
                objFO.Transporter_Code__c = eachFO.transporter_code;
                objFO.Transporter_Name__c =eachFO.transporter_name;
                objFO.Status__c =eachFO.status;
                objFO.Pick_Up__c = integer.valueOf(eachFO.pick_up_order);
                objFO.Mode_Of_Transport__c = eachFO.mode_of_transport;
                objFO.indent_Id__c = eachFO.indent_id;
                objFo.Drop_Off__c = integer.valueOf( eachFO.drop_off_order);
                objFO.Shipment_Number__c =eachFO.shipment_number;
                objFO.Truck_In__c = date.valueOf(eachFO.truck_in_date_and_time);
                objFo.Truck_Out__c = date.valueOf(eachFO.truck_out_date_and_time);
                objFO.Pando_Quantity__c =integer.valueOf(eachFO.quantity);

                
            }
            
        }
    }
    
    public class RequestJSONWrapper {
        public String FreightOrderNumber;
        public String freight_planning_company;
        public String FreightOrderLineNo;
        public String indent_id;
        public String type;
        public String vehicle_number;
        public String vehicle_type;
        public String driver_number;
        public String transporter_code;
        public String transporter_name;
        public String created_date;
        public String status;
        public String quantity;
        public String pick_up_order;
        public String drop_off_order;
        public String Item;
        public String shipment_number;
        public string mode_of_transport;
        public string truck_in_date_and_time;
        public string truck_out_date_and_time;
        
        
    }
    public class ErrorSuccessResponse{
        public boolean status;
        public string message;
        public string FreightOrderId;
        
    }
    public static ErrorSuccessResponse GenericResponse(string message, boolean status,string FreightOrderId){
        ErrorSuccessResponse errorResponse=new ErrorSuccessResponse();
        errorResponse.status=status;
        errorResponse.message = message;
        errorResponse.FreightOrderId = FreightOrderId;
        return errorResponse;
    }
    
    
}