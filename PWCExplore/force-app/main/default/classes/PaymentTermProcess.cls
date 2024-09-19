/*------------------------------------------------------------------------
Author:        Anupam Mishra
Company:       GITL
Description:   Process Payment Term
Inputs:        map of order lines
Test Class:   PaymentTermProcessTest
----------------------------------------------------------------------------*/

public without sharing class PaymentTermProcess {
    
    Map<Id,OrderItem> idVsItem=new Map<Id,OrderItem>();
    Id integrationAdminProfileId;
    
    public void processPaymentTerm(Map<Id,OrderItem> newItems) {
    
            Set<Id> orderItemsIds=newItems.keySet();        
            List<OrderItem> orderItems=getOrderItemRecords(orderItemsIds);
            List<Payment_Term__c> PaymentTermsMatrices=getPaymentMatrixRecords(orderItems); 
            Map<Id,List<Payment_Term__c>> itemIdVsMatricesFound=getItemsVsMatricesMatched(orderItems,PaymentTermsMatrices);       
            stampPaymentTermsCode(orderItems,itemIdVsMatricesFound);
                 
                  try{  
                   
                     doDml();
                     
                  }
                  catch(exception ex){
                    
                     Logger.logError('Payment Term', '', '', ex);
                  }
            
     }
    
   
    public void doDml(){
    
         OrderItemTriggerHandler.TriggerDisabled=true;
         Update idVsItem.values();
         OrderItemTriggerHandler.TriggerDisabled=false;
    }

    public void updateOrderItem(OrderItem item,Payment_Term__c matrix){ 
        Id matrixId=matrix.Id; 
        orderItem orderProduct=new orderItem();
        orderProduct.OrderId=item.OrderId;
        orderProduct.Payment_terms__c= matrix.Payment_Terms__c;
        orderProduct.Payment_Terms_Code__c= matrix.Payment_term_code__c;
        orderProduct.Id=item.Id;
        if(!idVsItem.containsKey(orderProduct.Id)){
            idVsItem.put(orderProduct.Id,orderProduct);
        }
        
    }


    public List<OrderItem> getOrderItemRecords(Set<Id> orderItemIds){
        return [Select Id,Product2.Name,Order.Area__c,Order.Sales_Office__c,Order.Internal_Sales_Representative__r.Zone__c,
                Order.External_Sales_Representative__r.Zone__c,Order.Sold_to_Business_Partner__r.Account_Code__c,Order.AccountId,
                Order.Sales_Price_List__c,Order.Branch__r.Channel__c,Order.Payment_Terms__c,Product2.Product_Class__c,Product2.Item_Group__c,Product2.Item_Type__c,Product2.Product_Line__c,Product2Id,
                Order.Business_Unit__c,Order.Sales_Type__c,Order.Sales_Order_Series__c,Order.Sold_to_Business_Partner__c,Order.Line_of_Business__c,Price_Origin__c,Product2.Price_Group__c,Order.Owner.ProfileId     
                From OrderItem
                Where Id In :orderItemIds And Order.Sales_Type__c= :GlobalConstants.SALES_TYPE_PRIMARY
                ];
        
    }

    public List<Payment_Term__c> getPaymentMatrixRecords(List<OrderItem> orderItems){
        Set<String> orderLineAreas=new Set<String>();
        Set<Id> salesOffices=new Set<Id>();
        Set<String> zones=new Set<String>();
        Set<Id> salesPriceLists=new Set<Id>();
        Set<String> channels=new Set<String>();
        Set<String> productClasses=new Set<String>();
        Set<String> itemGroups=new Set<String>();
        Set<String> itemTypes=new Set<String>();
        Set<String> productLines=new Set<String>();
        Set<Id> product2Ids=new Set<Id>();
        Set<String> paymentTerms=new Set<String>();
        Set<String> businessUnits=new Set<String>();
        Set<String> PaymentTermCode=new Set<String>();
        Set<String> ItemCodes=new Set<String>();
        Set<String> BPCodes=new Set<String>();
         Set<String> LOB=new Set<String>();
        Set<String> OrderSeries=new Set<String>();
  
        
        for(OrderItem item:orderItems){
            if(item.Order.Area__c!=null) 
              orderLineAreas.add(item.Order.Area__c);
            if(item.Order.Sales_Office__c!=null)
              salesOffices.add(item.Order.Sales_Office__c);    
            if(item.Order.Internal_Sales_Representative__c!=null && item.Order.Internal_Sales_Representative__r.Zone__c!=null)
              zones.add(item.Order.Internal_Sales_Representative__r.Zone__c); 
            else if(item.Order.External_Sales_Representative__c!=null && item.Order.External_Sales_Representative__r.Zone__c!=null)
              zones.add(item.Order.External_Sales_Representative__r.Zone__c); 
            if(item.Order.Sales_Price_List__c!=null)
              salesPriceLists.add(item.Order.Sales_Price_List__c);
            if(item.Order.Branch__r.Channel__c!=null)
              channels.add(item.Order.Branch__r.Channel__c);
            if(item.Product2.Product_Class__c!=null)
              productClasses.add(item.Product2.Product_Class__c);
            if(item.Product2.Item_Group__c!=null)
              itemGroups.add(item.Product2.Item_Group__c);          
            if(item.Product2.Item_Type__c!=null)
              itemTypes.add(item.Product2.Item_Type__c);
            if(item.Product2.Product_Line__c!=null)
              productLines.add(item.Product2.Product_Line__c);
            if(item.Product2Id!=null)
              product2Ids.add(item.Product2Id);
            if(item.Order.Business_unit__c!=null)
               businessUnits.add(item.Order.Business_unit__c);
             if(item.Order.AccountId!=null)
               BPCodes.add(item.Order.AccountId);
             if(item.Order.Line_of_Business__c!=null)
               LOB.add(item.Order.Line_of_Business__c);
              if(item.Order.Sales_Order_Series__c!=null)
               OrderSeries.add(item.Order.Sales_Order_Series__c);
        }
        
                
        
          List<String> strFieldsForNullCheck = new List<String>{'Area_Code__c','Sales_Service_Office__c',
                                                       'Zone__c','Price_List__c','Channel__c','Product_Class_new__c',
                                                       'Item_Group__c','Item_Type__c','Product_Line__c','Item_Code__c',
                                                       'Order_Series__c','BP_Code__c','Line_of_Business__c'
                                               };

            Integer cntNull = 0;
            Integer latestCntNull = 0;
            Payment_Term__c  paymentTermToBeApplied;
            List<Payment_Term__c> lstPaymentTerms = new List<Payment_Term__c>();
            List<Payment_Term__c> PaymentTermsMatrices= new List<Payment_Term__c>();
            Payment_Term__c PayTerms = new Payment_Term__c();                        
            for(Payment_Term__c pt : [ 
                Select Id,Payment_term_code__c,Order_Series__c,Area_Code__c,Sales_Service_Office__c,Line_of_Business__c,
                                                                   Zone__c,Price_List__c,Channel__c,Product_Class_new__c,
                                                                   Item_Group__c,Item_Type__c,Product_Line__c,Item_Code__c,
                                                                   Payment_Terms__c,Business_Unit__c,BP_Code__c
                                                                   From Payment_Term__c
                                                                   Where ( Area_Code__c=null Or Area_Code__c In :orderLineAreas) And 
                                                                       (Order_Series__c=null Or Order_Series__c In :OrderSeries) And
                                                                       (Line_of_Business__c=null Or Line_of_Business__c In :LOB) And 
                                                                       (Sales_Service_Office__c=null Or Sales_Service_Office__c In :salesOffices ) And
                                                                       (Zone__c=null Or Zone__c In :zones) And 
                                                                       (Price_List__c=null Or Price_List__c In :salesPriceLists) And 
                                                                       (Channel__c=null Or Channel__c In :channels) And 
                                                                       (Product_Class_new__c=null Or Product_Class_new__c In :productClasses) And 
                                                                       (Item_Group__c=null Or Item_Group__c In :itemGroups) And 
                                                                       (Item_Type__c=null Or Item_Type__c In :itemTypes) And 
                                                                       (Product_Line__c=null Or Product_Line__c In :productLines) And
                                                                       (Item_Code__c In :product2Ids or Item_Code__c = null) And
                                                                       (BP_Code__c= null or BP_Code__c In : BPCodes)And                                                                                                                    
                                                                       (Business_Unit__c=null Or Business_Unit__c In :businessUnits) And
                                                                       (Status__c='Active')And
                                                                        (Start_Date__c=null OR Start_Date__c<=TODAY)  And
                                                                        (End_Date__c=null OR End_Date__c>=TODAY)  ORDER BY  Start_Date__c DESC]){
                
                lstPaymentTerms.add(pt);
            }
              
            if(lstPaymentTerms.size()>0){
                paymentTermToBeApplied = lstPaymentTerms[0];
                for(Payment_Term__c p : lstPaymentTerms){
                cntNull = 0;
                
                    for (String s:strFieldsForNullCheck){
                        if ((p.get(s) == null) || (String.valueOf(p.get(s)) == ''))
                        {                                                 
                            cntNull++;
                        }
             }
             
                if(cntNull < latestCntNull)
                
                {
                    
                    paymentTermToBeApplied = p;
                    
                }
                
                latestCntNull = cntNull; 
               
            
             }
                                
                PaymentTermsMatrices.add(paymentTermToBeApplied);
                 
          }  
                                                                 
                   return PaymentTermsMatrices;
      }
            
    
    
    /*------------------------------------------------------------------------
    Author:        Anupam Mishra
    Company:       GITL
    Description:   Returns a Map of order Item and payment Terms matched matched
    ----------------------------------------------------------------------------*/
    public Map<Id,List<Payment_Term__c>> getItemsVsMatricesMatched(List<OrderItem> orderItems,List<Payment_Term__c> PaymentTermsMatrices){      
        Map<Id,List<Payment_Term__c>> itemIdVsMatricesFound=new Map<Id,List<Payment_Term__c>>();
        for(OrderItem item:orderItems){
            for(Payment_Term__c matrix:PaymentTermsMatrices){                     
                if( (matrix.Area_Code__c==null || (matrix.Area_Code__c==item.Order.Area__c)) &&
                    (matrix.Sales_Service_Office__c==null || (matrix.Sales_Service_Office__c==item.Order.Sales_Office__c)) && 
                    (matrix.Zone__c==null || (matrix.Zone__c==item.Order.Internal_Sales_Representative__r.Zone__c||matrix.Zone__c==item.Order.External_Sales_Representative__r.Zone__c )) &&
                    (matrix.Price_List__c==null || (matrix.Price_List__c==item.Order.Sales_Price_List__c)) &&
                    (matrix.Channel__c==null || (matrix.Channel__c==item.Order.Branch__r.Channel__c)) &&
                    (matrix.Product_Class_new__c==null || (matrix.Product_Class_new__c==item.Product2.Product_Class__c)) &&
                    (matrix.Item_Group__c==null || (matrix.Item_Group__c==item.Product2.Item_Group__c)) &&                   
                    (matrix.Item_Type__c==null || (matrix.Item_Type__c==item.Product2.Item_Type__c)) &&
                    (matrix.Product_Line__c==null || (matrix.Product_Line__c==item.Product2.Product_Line__c)) &&
                    (matrix.Item_Code__c==item.Product2Id  || (matrix.Item_Code__c==null)  ) &&
                    (matrix.BP_Code__c==null || (matrix.BP_Code__c==item.Order.AccountId ))&&
                   
                    (matrix.Business_Unit__C==null || (matrix.Business_Unit__C==item.Order.Business_Unit__C)) 
                    ){
                    if(!itemIdVsMatricesFound.containsKey(item.Id))   
                        itemIdVsMatricesFound.put(item.Id,new List<Payment_Term__c>{matrix});   
                    else
                        itemIdVsMatricesFound.get(item.Id).add(matrix); 
                    }
              }
         }
      
        return itemIdVsMatricesFound;
   }

     /*------------------------------------------------------------------------
    Description:   Update order line with correct  Payment term.  
    ----------------------------------------------------------------------------*/
    public void stampPaymentTermsCode(List<OrderItem> orderItems,Map<Id,List<Payment_Term__c>> itemIdVsMatricesFound){
        for(OrderItem item:orderItems){           
            if(itemIdVsMatricesFound.containsKey(item.Id)){                            
                if(itemIdVsMatricesFound.get(item.Id).size()==1){
                  updateOrderItem(item,itemIdVsMatricesFound.get(item.Id)[0]); 
                }
               
            }
        }     
}
}