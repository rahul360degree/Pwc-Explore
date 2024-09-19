/*------------------------------------------------------------------------
Author:        Kishor Kumar
Company:       Salesforce
Description:   class for OLI Handler 
Inputs:        NA
Test Class:    
History
25-05-2020      Kishor Kumar     Initial Release
----------------------------------------------------------------------------*/

public with sharing class OLIFieldPopulator {
    
    /*------------------------------------------------------------------------
    Author:        Kishor Kumar
    Company:       Salesforce
    Description:   This class is used to create the sequence of the Order Line Item. 
    Inputs:        NA
    Test Class:    
    History
    25-05-2020      Kishor Kumar     Initial Release
    ----------------------------------------------------------------------------*/
    
    public void populateOLISequence(list<OrderItem> orderProducts){
        map<Id, OrderItem> orderIdVsLatestOLI = new map<Id, OrderItem>();
        map<Id, list<OrderItem>> orderIdVsOLIS = new map<Id, list<OrderItem>>();
        Set<Id> product2Set = new Set<Id>();//Added by Namrata on 10/05/22
        try{ 
            for(OrderItem oli : orderProducts){                
                if(oli.Order_Line_Position__c == null){
                    if(orderIdVsOLIS.isEmpty() || !orderIdVsOLIS.containsKey(oli.OrderId)){
                        orderIdVsOLIS.put(oli.OrderId, new list<OrderItem> {oli});
                    } else {
                        orderIdVsOLIS.get(oli.OrderId).add(oli);
                    }
                }
                product2Set.add(oli.Product2Id);
            }
            //Added by Namrata on 10/05/22
            // Map of all the order ids where order line position is not null,  business unit is MHE division and Enquiry category is outright Sales
            Map<Id, Order> orderMap = new Map<Id, Order>([Select Id,business_unit__c, MHE_division__c,
                                                          (Select Id, Order_Line_Position__c,Skip_Generic_SPR__c,OrderId,Product2.component_type__c 
                                                           FROM OrderItems 
                                                           WHERE Order_Line_Position__c != null
                                                           ORDER BY Order_Line_Position__c DESC LIMIT 1) 
                                                          FROM Order WHERE ID IN : orderIdVsOLIS.keySet() ]);
            Map<Id,String> Productmap = new Map<Id,String>();
            if(!product2Set.isEmpty()){
                for(Product2 product:[select id,name,item__c,component_type__c from product2 where id in:product2Set and Component_Type__c =:GlobalConstants.BASE_PRODUCT_COMPONENT_TYPE]){
                    productmap.put(product.Id,product.component_type__c);
                }
            }
            //End by Namrata on 10/05/2022
            
            If(orderMap <> null){
                for(Order orderRec :orderMap.values()){
                    if(!((orderRec.OrderItems).isEmpty())){
                        orderIdVsLatestOLI.put(orderRec.Id, orderRec.OrderItems[0]);
                        //product2Set.add(oli.Product2Id);
                    }
                }
            }
            
            //Check orderIdVsOLIS is not empty
            if(!orderIdVsOLIS.isEmpty()){
                // Fetches order ids and checks for order line item
                for(Id orderId : orderIdVsOLIS.keyset()){ 
                    //if Order has no existing OLI
                    if(orderIdVsLatestOLI.isEmpty() || !orderIdVsLatestOLI.containsKey(orderId)){
                        Integer seq = GlobalConstants.OLI_SEQUENCE_FIRST_NUMBER;
                        Integer position_number = 1 ;
                        //This for loop checks every order line item and set order line position
                        for(OrderItem olItem : orderIdVsOLIS.get(orderId)){
                            // Added by Namrata on 10-05-2022
                            // Set order line position If Product component type is base product or not
                            if(productmap.get(olItem.Product2Id) == GlobalConstants.BASE_PRODUCT_COMPONENT_TYPE 
                               && orderMap.get(olItem.OrderId).business_unit__c == GlobalConstants.BUSINESS_UNIT_MHE_DIVISION 
                               && orderMap.get(olItem.OrderId).MHE_division__c == GlobalConstants.MHE_SUB_DIVISION_EQUIPMENT){
                                   olItem.Order_Line_Position__c = Integer.valueOf(GlobalConstants.OLI_SEQUENCE_FIRST_NUMBER* position_number);
                                   position_number += 1 ;
                               }// Ended by Namrata on 10-05-2022
                            //added by sushant on 8-12-2022  Jira no.SIF-61 This is related to an issue in which the order line data is being pushed into INFOR from SF
                            else if( orderMap.get(olItem.OrderId).business_unit__c==GlobalConstants.INTERIO_BUSINESS_UNIT &&
                                    (olItem.Order_interio_Subdiv__c==GlobalConstants.INTERIO_VFD || olItem.Order_interio_Subdiv__c==GlobalConstants.INTERIO_KITCHEN||
                                     olItem.Order_interio_Subdiv__c==GlobalConstants.INTERIO_SCRIPT) ){
                                         olItem.Order_Line_Position__c = olItem.Order_Interio_Position__c;
                                     }   //   ended by sushant 8-12-2022  Jira no.SIF-61 This is related to an issue in which the order line data is being pushed into INFOR from SF
                            else{
                                olItem.Order_Line_Position__c = seq;
                                seq = seq + Integer.valueOf(System.Label.OLI_Sequence_Incrementer);                                
                            }
                        }
                    } else {//Order has already existing OLIs
                        Integer nexSeq = Integer.valueOf(Integer.valueOf(orderIdVsLatestOLI.get(orderId).Order_Line_Position__c) + Integer.valueOf(System.Label.OLI_Sequence_Incrementer));
                        for(OrderItem olItem : orderIdVsOLIS.get(orderId)){
                            olItem.Order_Line_Position__c = nexSeq;
                            nexSeq = nexSeq + Integer.valueOf(System.Label.OLI_Sequence_Incrementer);                            
                        }
                    }
                }
            }
        }catch(Exception ex){
            Logger.logError('OLIFieldPopulator', 'populateOLISequence', '', ex);
        }
    }
    
    /*------------------------------------------------------------------------
    Author:        Vikrant mahantare
    Description:   Method to handle Before Insert/Update event context of Orderitem Trigger
    Inputs:        map of created records
    Test Class:   
    ----------------------------------------------------------------------------*/
    
    public void orderSplit(list<OrderItem> orderProducts){  
        try {
            Map<String,Product2> mapStrProdctType= new Map<String,Product2>();
            Map<String,Product2> mapStrProdctItemGrp= new Map<String,Product2>();
            Map<String,order> mapStrOrderLog= new Map<String,order>();
            Map<String,order> mapStrOrderBU= new Map<String,order>();
            Set<Id> ids = new Set<Id>();
            Set<Id> idsp = new Set<Id>();
            Boolean isCheck=false;
            
            //ASHWIN THALE - ORDER SPLIT AVOID - JIRA SAEPB-122 - START
            Map<ID,OrderItem> mapOrdItem = new Map<ID,OrderItem>();
            Map<ID,String> mapRecordType = new Map<ID,String>();
            String strRecType;
            
            for(OrderItem objOrdPrd : orderProducts) {
                ids.add(objOrdPrd.orderid);
                idsp.add(objOrdPrd.Product2Id);
                mapOrdItem.put(objOrdPrd.Stock_File__c,objOrdPrd);
            }
            
            Map<ID,Stock_File__c> mapStockFile = new Map<ID, Stock_File__c>([SELECT Applicable_Date__c, Consumed_Quantity__c, Description__c, From_Logistics_Company__c, From_Warehouse__c, 
                                                       Is_Active__c, Item__c, Quantity__c, Stockfile_Number__c, To_Logistics_Company__c, is_Hub__c, Item_Code__c, 
                                                       Item_Name__c, Remaining_Quantity__c, Warehouse_Code__c, Quantity_Split_Required__c, Name, Id FROM Stock_File__c
                                                       Where ID IN : mapOrdItem.keySet()]);
            system.debug('mapStockFile='+mapStockFile);
            //ASHWIN THALE - ORDER SPLIT AVOID - JIRA SAEPB-122 - END
            
            Integer intPosi;
            Decimal linecreated;
            Integer actlinecreated;
            Integer lastlinequantity;
            list<OrderItem> neworditem = new list<OrderItem>();
            
            List<order> ord = [Select Logistics_Company_Branch__c,Business_unit__c,RecordType.DeveloperName From Order where ID = :ids];  //RecordType.DeveloperName added 
            for(Order ords: ord){
                mapStrOrderLog.put(ords.Logistics_Company_Branch__c,ords);
                mapStrOrderBU.put(ords.Business_unit__c,ords);
                mapRecordType.put(ords.Id,ords.RecordType.DeveloperName);
            }
            system.debug('mapRecordType='+mapRecordType);
            List<Product2> prd = [Select Product_Type__c,Item_Group__c from Product2 where id = :idsp];
            for(Product2 prds: prd){
                mapStrProdctType.put(prds.Product_Type__c,prds);
                mapStrProdctItemGrp.put(prds.Item_Group__c,prds);
            }
            List<Quantity_split__c> ordsplit = [Select branch__c,Division__c,Item_Group__c,Product_type__c,Quantity_Split__c from Quantity_split__c where Item_Group__c IN:mapStrProdctItemGrp.keyset() and branch__c IN:mapStrOrderLog.keyset()];   //Added by pankaj on 15-02-2022     
            for(OrderItem oli : orderProducts){            
                for(Quantity_split__c osplit : ordsplit){
                    if(mapStrOrderLog.containsKey(osplit.branch__c) && mapStrOrderBU.containsKey(osplit.Division__c) && mapStrProdctType.containsKey(osplit.Product_type__c)  && mapStrProdctItemGrp.containsKey(osplit.Item_Group__c)){
                        Integer putQuantity = Integer.valueOf(oli.Quantity);
                        if (oli.Quantity > osplit.Quantity_Split__c){
                            
                            //ASHWIN THALE - ORDER SPLIT AVOID - JIRA SAEPB-122 - START
                            isCheck=false;
                            if(mapStockFile.containsKey(oli.Stock_File__c) && mapRecordType.containsKey(oli.OrderId))
                            {
                            	Stock_File__c objStock = mapStockFile.get(oli.Stock_File__c);
                                strRecType = String.ValueOf(mapRecordType.get(oli.OrderId));
                                If(objStock.Quantity_Split_Required__c && strRecType == GlobalConstants.APPLIANCE_DIRECT_BILLING){
                                	oli.Quantity = osplit.Quantity_Split__c;
                                    isCheck=true;
                                }
                             }
                             //ASHWIN THALE - ORDER SPLIT AVOID - JIRA SAEPB-122 - END
                            
                            linecreated = putQuantity/osplit.Quantity_Split__c;                            
                            actlinecreated = Integer.valueOf(linecreated.round(System.RoundingMode.DOWN));//commented due to Redundant code 
                            lastlinequantity = math.mod(putQuantity, Integer.valueOf(osplit.Quantity_Split__c));
                            for(integer i=0; i< actlinecreated -1;i++){
                                OrderItem orditem = oli.clone(false, true, true, false);
                                If(isCheck) {
                                    orditem.Quantity = osplit.Quantity_Split__c;
                                    neworditem.add(orditem);
                                }
                            }
                            if (lastlinequantity != 0){
                                OrderItem orditem = oli.clone(false, true, true, false);
                                If(isCheck) {
                                    orditem.Quantity = lastlinequantity;
                                    neworditem.add(orditem);
                                }
                            }
                        }
                    }              
                }
            }
            
            System.debug('neworditem===>'+neworditem);
            //Added by pankaj on 8/2/22 for creating unique positions
            if(neworditem.size() > 0){
                //Added by pankaj on 25 july 2022 to update correct order line position while editing quanitity /SAEPB-34      
                for(OrderItem ordItems:neworditem){
                    ordItems.Order_Line_Position__c = Null;            
                }//End by pankaj 
                
                //Cloned OLIs
                System.enqueueJob(new OrderLineItemsSplit(neworditem));
            }   //end by pankaj    
        }
        catch (Exception ex) {
            Logger.logError('OLIFieldPopulator', 'orderSplit', '', ex);
        }
    }
    
    /*------------------------------------------------------------------------
    Author:        Pankaj Mershram
    Description:   Method to handle Before delete event context of Orderitem Trigger
    Inputs:        List of deleted records
    Test Class:
    
    History
    30-08-2022      Pankaj Meshram     Initial Release  - Update Order_Line_Position__c on product delete 
    ----------------------------------------------------------------------------*/   
    
    public void updateOLISequenceOnDelete(list<OrderItem> orderProducts){
        try {
            List<Id> lstOrderIds = new List<Id>();
            List<Id> lstOrderProductIds = new List<Id>();
            List<orderItem> lstOrdItms = new List<orderItem>();
            for(OrderItem ordItm:orderProducts){
                lstOrderIds.add(ordItm.OrderId);
                lstOrderProductIds.add(ordItm.id);
            }        
            List<orderItem> lstOrdItmWithPosition = [Select id,Order_Line_Position__c,order.Business_unit__c from OrderItem where OrderId IN:lstOrderIds and id Not IN:lstOrderProductIds];        
            integer newSequence = Integer.valueOf(System.Label.OLI_Sequence_Incrementer);
            for(OrderItem ordLine:lstOrdItmWithPosition){
                if(ordLine.order.Business_unit__c == GlobalConstants.APPLIANCE_BUSINESS_UNIT){
                    ordLine.Order_Line_Position__c = newSequence;
                    newSequence = newSequence + Integer.valueOf(System.Label.OLI_Sequence_Incrementer);
                    lstOrdItms.add(ordLine);                             
                }
            }
            if(lstOrdItms.size() > 0)
                update lstOrdItms;
        }
        catch (Exception ex) {
            Logger.logError('OLIFieldPopulator', 'updateOLISequenceOnDelete', '', ex);
        }
    }
}