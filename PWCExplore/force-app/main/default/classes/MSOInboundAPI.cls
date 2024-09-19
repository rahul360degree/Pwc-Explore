@RestResource(urlMapping='/CreateMS_Order')
Global class MSOInboundAPI {
    @HttpPost
    global static void CreateMS_Order() {
        boolean flag;
        list<ErrorSuccessResponse> listResponse=new list<ErrorSuccessResponse>();
        String response;
        
        // Obtain the incoming REST request.
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        
        try{
            // Deserialize the JSON request body into a list of JSONRequestWrapper objects.
            List<JSONRequestWrapper> RequestWrappers = (List<JSONRequestWrapper>) JSON.deserialize(req.requestbody.toString(), List<JSONRequestWrapper>.class); 
            
            List<Account> newAccListToInsert = new List<Account>();
            Map<String, JSONRequestWrapper> ReqwrapperMap = new Map<String,JSONRequestWrapper>();
            Map<String, Account> wrapperAccMap = new Map<String,Account>();
            
            list<string> soltoaccount =new list<string>();
            list<string> soltoaddress =new list<string>();
            
            list<string> shiptoaddress= new list<string>();
            list<string> shiptoaccount =new list<string>();
            
            list<string> warehouse=new list<string>();
            map<string,Warehouse__c> Warhousemap=new map<string,Warehouse__c>();
            
            map<string,Account> shipto_soldtoaccmap=new map<string,Account>();
            map<string,Address_by_BP__c> shipto_soldtoAddressmap=new map<string,Address_by_BP__c>();
            
            list<string> Salesofficecode=new list<string>();
            map<string,Sales_Office__c> Sales_Servicemapp=new map<string,Sales_Office__c>();
            
            List<MSOItemWrapper> MSOItemWrapperlist = new List<MSOItemWrapper>();
            set<string> ItemCode = new set<string>();
            
            
            // Iterate through each JSONRequestWrapper object to create or update Account records.
            for(JSONRequestWrapper eachAcc : RequestWrappers){
                
                soltoaccount.add(eachAcc.soldtoBusinessPartner);
                soltoaddress.add(eachAcc.soldToAddress);
                Salesofficecode.add(eachAcc.serviceOffice);
                //warehouse.add(eachAcc.MS_Order.Warehouse);
                
                ReqwrapperMap.put(eachAcc.MSONumber, eachAcc);
                system.debug('ReqwrapperMap:'+ReqwrapperMap);
                
            }
            for(JSONRequestWrapper eachMSO : RequestWrappers) {
                
                MSOItemWrapperlist.addAll(eachMSO.MSOItems);
            }
            for(MSOItemWrapper Item: MSOItemWrapperlist){
                ItemCode.add(Item.ItemCode);
                shiptoaddress.add(Item.shiptoaddress);
                shiptoaccount.add(Item.shiptoaccount);
                warehouse.add(Item.Warehouse);
            }
            
            
            
            list<Account> shiptosoldtoBP =[select id, Account_Code__c from account where Account_Code__c =:soltoaccount  or Account_Code__c =: shiptoaccount ];
            system.debug('shiptosoldtoBP'+shiptosoldtoBP);
            if(!shiptosoldtoBP.isempty()){
                for(Account a: shiptosoldtoBP){
                    shipto_soldtoaccmap.put(a.Account_Code__c,a);
                    
                }
            }
            list<Address_by_BP__c>  shiptosoldtoaddresBP =[select id,Address_Code_Formula__c from Address_by_BP__c where Address_Code_Formula__c =:shiptoaddress or Address_Code_Formula__c =:soltoaddress ];
            system.debug('shiptosoldtoaddresBP'+shiptosoldtoaddresBP);
            if(!shiptosoldtoaddresBP.isempty()){
                for(Address_by_BP__c address: shiptosoldtoaddresBP){
                    shipto_soldtoAddressmap.put(address.Address_Code_Formula__c,address);
                    
                }
            }
            list<Sales_Office__c>  Sales_Serviceoffice =[select id,LN_Sales_Office_Code__c from Sales_Office__c where LN_Sales_Office_Code__c =: Salesofficecode];
            system.debug('Sales_Serviceoffice'+Sales_Serviceoffice);
            if(!Sales_Serviceoffice.isempty()){
                for(Sales_Office__c salesoffice: Sales_Serviceoffice){
                    Sales_Servicemapp.put(salesoffice.LN_Sales_Office_Code__c,salesoffice);
                    
                }
            }
            
            list<Warehouse__c>  warehouselist =[select id,Warehouse__c from Warehouse__c where Warehouse__c =: warehouse];
            system.debug('warehouselist'+warehouselist);
            if(!warehouselist.isempty()){
                for(Warehouse__c War: warehouselist){
                    Warhousemap.put(War.Warehouse__c,War);
                    
                }
                system.debug('Warhousemap'+Warhousemap);
            }
            
            system.debug('ItemCode size:'+ItemCode.size());
            
            list<Product2>  productitemcode =[select id, Item__c from Product2 where Item__c =: ItemCode];
            system.debug('productitemcode size:'+productitemcode.size());
            system.debug('productitemcode'+productitemcode);
            map<string,Product2> ProductItemcodemap=new map<string,Product2>();
            
            if(!productitemcode.isempty()){
                for(Product2 prcode: productitemcode){
                    ProductItemcodemap.put(prcode.Item__c,prcode);
                    
                }
            }
            
            List<ReturnOrder> MS_orderToInsert = new List<ReturnOrder>();
            Map<String, ReturnOrder> MSOrderMap = new Map<String,ReturnOrder>();
            system.debug('ReqwrapperMap.keySet() '+ReqwrapperMap.keySet());
            
            for(JSONRequestWrapper MSOwrap : RequestWrappers){
                if( String.isBlank(MSOwrap.soldtoBusinessPartner) || String.isBlank(MSOwrap.soldToAddress)){
                    
                    ErrorSuccessResponse errorResponse1= GenericResponse('Sold to Business partner , Sold to address should not be null.',false,null);
                    listResponse.add(errorResponse1);
                    
                }
                else if(String.isBlank(MSOwrap.orderDate) || String.isBlank(MSOwrap.serviceOffice) ){
                    ErrorSuccessResponse errorResponse2= GenericResponse('Order Date, Service Office should not be null.',false,null);
                    listResponse.add(errorResponse2);
                    
                }
                else if(String.isBlank(MSOwrap.MSONumber) || String.isBlank(MSOwrap.logisticsCompanyBranch)){
                    
                    ErrorSuccessResponse errorResponse3= GenericResponse('MSO Number,Company should not be null.',false,null);
                    listResponse.add(errorResponse3);
                }
                else if(!shipto_soldtoaccmap.containsKey(MSOwrap.soldtoBusinessPartner)){
                    ErrorSuccessResponse errorResponse4= GenericResponse('Sold to Business partner does not exist in salesforce.',false,null);
                    listResponse.add(errorResponse4);
                    flag = false;
                }
                else if(!shipto_soldtoAddressmap.containsKey(MSOwrap.soldToAddress)){
                    ErrorSuccessResponse errorResponse5= GenericResponse('Sold to Address does not exist in salesforce.',false,null);
                    listResponse.add(errorResponse5);
                }
                else if(!Sales_Servicemapp.containsKey(MSOwrap.serviceOffice)){
                    ErrorSuccessResponse errorResponse6= GenericResponse('Service office does not exist in salesforce.',false,null);
                    listResponse.add(errorResponse6);
                }
                else if(!Sales_Servicemapp.containsKey(MSOwrap.serviceOffice)){
                    
                }
                else{
                    
                    ReturnOrder ordObj = new ReturnOrder();
                    ordObj.Order_Date__c = String.isNotBlank(MSOwrap.orderDate) ? date.valueOf(MSOwrap.orderDate) : null;
                    ordObj.MSO_Number__c =String.isNotBlank(MSOwrap.MSONumber) ? MSOwrap.MSONumber: null;
                    ordObj.Status = 'Approved';
                    //ordObj.Integration_Status__c = 'Synced';
                    ordObj.Infor_status__c = String.isNotBlank(MSOwrap.status) ? MSOwrap.status: null; // 'Approved';
                    
                    ordObj.Sold_to_Business_Partner__c = String.isNotBlank(MSOwrap.soldtoBusinessPartner) ? shipto_soldtoaccmap.get(MSOwrap.soldtoBusinessPartner).id : null;
                    ordObj.Sold_To_Address__c = String.isNotBlank(MSOwrap.soldToAddress) ? shipto_soldtoAddressmap.get(MSOwrap.soldToAddress).id : null;
                    ordObj.Sales_Service_Office__c = String.isNotBlank(MSOwrap.serviceOffice) ? Sales_Servicemapp.get(MSOwrap.serviceOffice).id : null;
                    
                    
                    ordObj.Logistics_Company_Branch__c = String.isNotBlank(MSOwrap.logisticsCompanyBranch) ? MSOwrap.logisticsCompanyBranch: null;
                    // ordObj.Sales_Order_Series__c = String.isNotBlank(ReqwrapperMap.get(accId).MS_Order.salesOrderSeries) ? ReqwrapperMap.get(accId).MS_Order.salesOrderSeries: null;
                    ordObj.Business_Unit__c = String.isNotBlank(MSOwrap.businessUnit) ? MSOwrap.businessUnit: null;
                    ordObj.Sub_Division__c = String.isNotBlank(MSOwrap.subDivision) ? MSOwrap.subDivision: null;
                    
                    MS_orderToInsert.add(ordObj);
                    MSOrderMap.put(MSOwrap.MSONumber, ordObj);
                     flag=true;

                    
                }
                
                
                
            }
            if(productitemcode.size() == ItemCode.size()){
                if(MS_orderToInsert.size()>0){
                    //insert MS_orderToInsert;
                    upsert MS_orderToInsert MSO_Number__c;
                    for(ReturnOrder RitemObj : MS_orderToInsert){
                            ErrorSuccessResponse successresponse=new ErrorSuccessResponse();
                            successresponse.status=true;
                            successresponse.message='Success: Maintenance Sales Order Created Successfully ';
                            successresponse.MSOID=RitemObj.Id ;
                            listResponse.add(successresponse);
                        }
                   
                }
                List<ReturnOrderLineItem> orderItemToInsert = new List<ReturnOrderLineItem>();
                if(flag == true){
                    for(MSOItemWrapper eachItem: MSOItemWrapperlist){
                        
                        ReturnOrderLineItem itemObj = new ReturnOrderLineItem();
                        
                        itemObj.QuantityReturned = String.isNotBlank(string.valueOf(eachItem.Quantity)) ? eachItem.Quantity : Null;
                        itemObj.Product2Id = String.isNotBlank(eachItem.ItemCode) ? ProductItemcodemap.get(eachItem.ItemCode).id : null;
                        itemObj.Type__c= String.isNotBlank(eachItem.LineItemType) ? eachItem.LineItemType : null;
                        itemObj.Ship_To_Address__c = String.isNotBlank(eachItem.shipToAddress) ? shipto_soldtoAddressmap.get(eachItem.shipToAddress).id : null;
                        itemObj.Ship_To_Account__c = String.isNotBlank(eachItem.shipToAccount) ? shipto_soldtoaccmap.get(eachItem.shipToAccount).id : null;
                        itemObj.ReturnOrderId = String.isNotBlank(eachItem.MSOReferenceNumber) ? MSOrderMap.get(eachItem.MSOReferenceNumber).id : null;
                        itemObj.MSO_Line_Position__c =  String.isNotBlank(eachItem.MSOLineNumber) ? Integer.valueOf(eachItem.MSOLineNumber) : null;
                        itemObj.Warehouse__c = String.isNotBlank(eachItem.Warehouse) ?  Warhousemap.get(eachItem.Warehouse).id : null;
                        itemObj.Line_Status__c = String.isNotBlank(eachItem.lineStatus) ? eachItem.lineStatus: null;
                        itemObj.Order_Line_Reference_Ext__c = String.isNotBlank(eachitem.Order_Line_Reference_Ext) ? eachitem.Order_Line_Reference_Ext : null;
                        
                        system.debug('itemObj -->'+itemObj);
                        orderItemToInsert.add(itemObj);
                    }
                    if(orderItemToInsert.size()>0){
                         //insert orderItemToInsert;
                         upsert orderItemToInsert Order_Line_Reference_Ext__c;
                       /* for(ReturnOrderLineItem RitemObj : orderItemToInsert){
                            ErrorSuccessResponse successresponse=new ErrorSuccessResponse();
                            successresponse.status=true;
                            successresponse.message='Success: Maintenance Sales Order Created Successfully ' + RitemObj.ReturnOrderId;
                            successresponse.MSOLineitemID=RitemObj.Id ;
                            listResponse.add(successresponse);
                        }*/
                    }
                    
                }
                
            }
            else{
                ErrorSuccessResponse errorResponse=new ErrorSuccessResponse();
                
                errorResponse.status=false;
                errorResponse.message = 'Item code does not Exist in salesforce';
                errorResponse.MSOID=null;
                listResponse.add(errorResponse);
                
            }
            
            res.addHeader('Content-Type', 'application/json');
            response =JSON.serialize(listResponse);
            system.debug('response :'+response);
            system.debug('listResponse :'+listResponse);
            res.responseBody = Blob.valueOf(response);
            
        }catch(Exception e){
            System.debug('Error '+e.getMessage());
            System.debug('Error '+e.getLineNumber());
            
            ErrorSuccessResponse errorResponse=new ErrorSuccessResponse();
            
            errorResponse.status=false;
            errorResponse.message = e.getMessage();
            errorResponse.MSOID=null;
            listResponse.add(errorResponse);
            response =JSON.serialize(listResponse);
            res.addHeader('Content-Type', 'application/json');
            res.responseBody = Blob.valueOf(response);
        }
        
        
    }
    public class JSONRequestWrapper{
        //public String GUID;
        public String orderDate;
        public String status;
        public String soldtoBusinessPartner;
        public String soldToAddress;
        public String logisticsCompanyBranch;
        public String serviceOffice;
        //public String salesOrderSeries;
        public String businessUnit;
        public String subDivision;
        public String MSONumber;
        //public MSOWrapper MS_Order;
        public List<MSOItemWrapper> MSOItems;
    }
    /* public class MSOWrapper {
public String orderDate;
//public String status;
public String soldtoBusinessPartner;
public String soldToAddress;
public String logisticsCompanyBranch;
public String serviceOffice;
//public String salesOrderSeries;
public String businessUnit;
public String subDivision;
public String MSONumber;
//public string Warehouse;
}*/
    public class MSOItemWrapper {
        public Decimal Quantity;
        public String ItemCode;
        public String LineItemType;
        public String MSOReferenceNumber;
        public String ReasonForReturn;
        public String MSOLineNumber;
        public String shipToAddress;
        public String shipToAccount;
        public string Warehouse;
        public string lineStatus;
         public string Order_Line_Reference_Ext;
        
        
    }
    public class ErrorSuccessResponse{
        public boolean status;
        public string message;
        public string MSOID;
        
    }
    public static ErrorSuccessResponse GenericResponse(string message, boolean status,string MSOID){
        ErrorSuccessResponse errorResponse=new ErrorSuccessResponse();
        errorResponse.status=status;
        errorResponse.message = message;
        errorResponse.MSOID = MSOID;
        return errorResponse;
    }
}