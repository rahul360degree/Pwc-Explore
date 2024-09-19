/*------------------------------------------------------------------------
Author:        Manasi Londhe
Company:       Salesforce
Description:   Process Discount Matrix 
Inputs:        map of order lines
Test Class:    DiscountMatrixProcessorTest

History
09-05-2020      Manasi Londhe     Initial Release
----------------------------------------------------------------------------*/

public without sharing class DiscountMatrixProcessor {
    
    Map<Id,OrderItem> idVsItem=new Map<Id,OrderItem>();
    Map<String,String> mapDiscountMethod = new Map<String,String>();
    Id integrationAdminProfileId;
    Boolean isNetDiscount = false;
    
    public void processDiscountMatrix(Map<Id,OrderItem> newItems) {
        
        Set<Id> orderItemsIds=newItems.keySet();
        List<OrderItem> orderItems=getOrderItemRecords(orderItemsIds);
        List<Discount_Matrix__c> discountsMatrices=getDiscountMatrixRecords(orderItems);
        constructMapDiscountMethod(discountsMatrices);
        //commented by Praful - 11-08-2020
        //if(discountsMatrices.size()>0){
        Map<Id,List<Discount_Matrix__c>> itemIdVsMatricesFound=getItemsVsMatricesMatched(orderItems,discountsMatrices);
        stampDiscountMatrixCode(orderItems,itemIdVsMatricesFound);
        try{  
            doDml();
        }
        catch(exception ex){
            Logger.logError('DiscountMatrixProcessor', '', '', ex);
        }
        //}
    }
    /*------------------------------------------------------------------------
Company:       GITL
Description:   Method to map DiscountMethod
Inputs:        List of Discount Matrix
Test Class:    DiscountMatrixProcessorTest
History
03-08-2022     Santosh J     Initial Release
Feature : SAF-130[Net Discount feature in Salesforce]
User Story : SAEPB-41
----------------------------------------------------------------------------*/
    //03-Aug
    
    private void constructMapDiscountMethod(List<Discount_Matrix__c> discountsMatrices)
    {
        for (Discount_Matrix__c dm:discountsMatrices)
        {
            mapDiscountMethod.put(String.valueOf(dm.Id), dm.Gross_Net__c);
        }
        System.Debug('mapDiscountMethod ' + mapDiscountMethod);
    }
    /*------------------------------------------------------------------------
Company:       GITL
Description:   Method to calculate net discount on Order Product on Orders
Inputs:        
Test Class:    DiscountMatrixProcessorTest
History
03-08-2022     Santosh J     Initial Release
Feature : SAF-130[Net Discount feature in Salesforce]
User Story : SAEPB-41
----------------------------------------------------------------------------*/
    private void processGrossNet()
    {
        List<OrderItem> lstOI = idVsItem.values();
        System.Debug('lstOI ' + lstOI);
        idVsItem.clear();
        for(OrderItem oi: lstOI)
        {
            System.Debug('in the oi for loop');

            Decimal currentLevelDiscount = 0;
            Decimal latestDiscountedBasic = oi.UnitPrice;
            for(Integer i = 2; i< 12; i++)
            {
                //System.Debug('map value ' + mapDiscountMethod.get((String)oi.get('Applied_Discount_Matrix_Level_'+ i +'_Code__c')));
                System.Debug('disc amount ' + (Decimal)oi.get('Applied_Discount_Matrix_Level_'+ i +'_Amount__c'));
                

                if ((i == 1) || (mapDiscountMethod.get((String)oi.get('Applied_Discount_Matrix_Level_'+ i +'_Code__c'))=='1'))
                {
                    currentLevelDiscount = (Decimal)oi.get('Applied_Discount_Matrix_Level_'+ i +'_Amount__c');
                    latestDiscountedBasic = latestDiscountedBasic - currentLevelDiscount;
                }
                else if (mapDiscountMethod.get((String)oi.get('Applied_Discount_Matrix_Level_'+ i +'_Code__c'))=='2')
                {
                    currentLevelDiscount = (Decimal)oi.get('Applied_Discount_Matrix_L'+ i +'_Percentage__c')*latestDiscountedBasic/100; 
                    oi.put('Applied_Discount_Matrix_Level_'+ i +'_Amount__c', currentLevelDiscount);
                    latestDiscountedBasic = latestDiscountedBasic - currentLevelDiscount;
                }

                System.Debug('currentLevelDiscount ' + i + ' ' + currentLevelDiscount);
                System.Debug('latestDiscountedBasic ' + i + ' ' + latestDiscountedBasic);
                
            }
            
            
            idVsItem.put(oi.Id,oi);
            System.Debug('end of the oi for loop');
        }
        
    }
    
    /*------------------------------------------------------------------------
Company:       GITL
Description:   Method to calculate net discount on Order Product for Orders
if Discount Method is defined as Net in Discount Matrix
Inputs:        
Test Class:    DiscountMatrixProcessorTest
History
03-08-2022     Santosh J     Modified
Feature : SAF-130[Net Discount feature in Salesforce]
User Story : SAEPB-41
----------------------------------------------------------------------------*/      
    public void doDml(){
        OrderItemTriggerHandler.TriggerDisabled=true;        
        //03-Aug  
        if(isNetDiscount)
        {
            processGrossNet();
        }
        Update idVsItem.values();
        OrderItemTriggerHandler.TriggerDisabled=false;
    }
    
    public void updateOrderItem(OrderItem item,Discount_Matrix__c matrix){
        String level=matrix.Level__c; 
        Id matrixId=matrix.Id; 
        orderItem orderProduct=new orderItem();
        orderProduct.unitPrice=item.UnitPrice;
        orderProduct.Quantity=item.Quantity;
        orderProduct.OrderId=item.OrderId;
        orderProduct.Id=item.Id;
        orderProduct=calculateDiscountOrPercentage(orderProduct,matrix);
        orderProduct.put('Applied_Discount_Matrix_Level_'+level+'_Code__c',matrixId);
        if(!idVsItem.containsKey(orderProduct.Id)){
            idVsItem.put(orderProduct.Id,orderProduct);
        }
        else{
            idVsItem.get(orderProduct.Id).put('Applied_Discount_Matrix_Level_'+level+'_Code__c',orderProduct.get('Applied_Discount_Matrix_Level_'+level+'_Code__c'));
            if(level=='1'){
                idVsItem.get(orderProduct.Id).Discount_Amount__c=orderProduct.Discount_Amount__c;
                idVsItem.get(orderProduct.Id).Line_Discount__c=orderProduct.Line_Discount__c;
            }
            else{
                idVsItem.get(orderProduct.Id).put('Applied_Discount_Matrix_Level_'+level+'_Amount__c',orderProduct.get('Applied_Discount_Matrix_Level_'+level+'_Amount__c'));
                idVsItem.get(orderProduct.Id).put('Applied_Discount_Matrix_L'+level+'_Percentage__c',orderProduct.get('Applied_Discount_Matrix_L'+level+'_Percentage__c'));
            }
        }
        
    }
    
    public OrderItem calculateDiscountOrPercentage(OrderItem item,Discount_Matrix__c matrix){
        Decimal price=item.UnitPrice!=null?item.UnitPrice:0;
        Decimal q=item.Quantity!=null?item.Quantity:0;
        Decimal totalUnitPrice=price*q;
        Decimal amt=0;
        Decimal percentage=0;
        String level=matrix.Level__c;
        if(matrix.Discount_Percent__c!=null && matrix.Discount_Percent__c!=0){
            amt=(matrix.Discount_Percent__c/100)*price;
            percentage=matrix.Discount_Percent__c;
        }
        else if(matrix.Discount_Amount__c!=null && matrix.Discount_Amount__c >0 && totalUnitPrice!=null && totalUnitPrice > 0){
            amt=matrix.Discount_Amount__c;
            percentage=(amt*100)/price;
        }
        if(level!='1'){
            /* 02-Aug-2022--to handle net*/
            if (matrix.Gross_Net__c == '2')
            {
                isNetDiscount = true;
            }
            /*End of 02-Aug-2022*/          
            item.put('Applied_Discount_Matrix_Level_'+level+'_Amount__c',amt);
            item.put('Applied_Discount_Matrix_L'+level+'_Percentage__c',percentage);
            
        }
        else{
            item.Discount_Amount__c=amt;
            item.Line_Discount__c=percentage;
        }
        return item;
    }
    
    public List<OrderItem> getOrderItemRecords(Set<Id> orderItemIds){
        return [Select Id,UnitPrice,Quantity,Order.Area__c,Order.Sales_Office__c,Order.Internal_Sales_Representative__r.Zone__c,
                Order.External_Sales_Representative__r.Zone__c,Order.Sold_to_Business_Partner__r.Account_Code__c,
                Order.Type,Order.Delivery_Terms__c,Product2.Manufacturer__c,Order.Order_Currency__c,Order.Sales_Price_List__c,Order.Branch__r.Channel__c,
                Order.Payment_Terms__c,Product2.Product_Class__c,Product2.Item_Group__c,Product2.Item_Type__c,Product2.Product_Line__c,Product2Id,
                Order.Business_Unit__c,Order.Sales_Type__c,Order.Sold_to_Business_Partner__c,Price_Origin__c,Product2.Price_Group__c,Order.Owner.ProfileId,
                //added few fields here by Praful - 11-08-2020
                Applied_Discount_Matrix_Level_2_Code__c,Applied_Discount_Matrix_Level_3_Code__c,Applied_Discount_Matrix_Level_4_Code__c,
                Applied_Discount_Matrix_Level_5_Code__c,Applied_Discount_Matrix_Level_6_Code__c,Applied_Discount_Matrix_Level_7_Code__c,
                Applied_Discount_Matrix_Level_8_Code__c,Applied_Discount_Matrix_Level_9_Code__c,Applied_Discount_Matrix_Level_10_Code__c,
                Applied_Discount_Matrix_Level_11_Code__c,
                //added field on 02-Aug-2022
                Applied_Discount_Matrix_Level_2_Code__r.Gross_Net__c,Applied_Discount_Matrix_Level_3_Code__r.Gross_Net__c,Applied_Discount_Matrix_Level_4_Code__r.Gross_Net__c,
                Applied_Discount_Matrix_Level_5_Code__r.Gross_Net__c,Applied_Discount_Matrix_Level_6_Code__r.Gross_Net__c,Applied_Discount_Matrix_Level_7_Code__r.Gross_Net__c,
                Applied_Discount_Matrix_Level_8_Code__r.Gross_Net__c,Applied_Discount_Matrix_Level_9_Code__r.Gross_Net__c,Applied_Discount_Matrix_Level_10_Code__r.Gross_Net__c,
                Applied_Discount_Matrix_Level_11_Code__r.Gross_Net__c                
                From OrderItem
                Where Id In :orderItemIds And Order.Sales_Type__c= :GlobalConstants.SALES_TYPE_PRIMARY
               ];
    }
    
    public List<Discount_Matrix__c> getDiscountMatrixRecords(List<OrderItem> orderItems){
        Set<String> orderLineAreas=new Set<String>();
        Set<Id> salesOffices=new Set<Id>();
        Set<String> zones=new Set<String>();
        Set<String> accountCodes=new Set<String>();
        Set<String> orderTypes=new Set<String>();
        Set<String> deliveryTerms=new Set<String>();
        Set<String> manufactures=new Set<String>();
        Set<String> orderCurrencies=new Set<String>();
        Set<Id> salesPriceLists=new Set<Id>();
        Set<String> channels=new Set<String>();
        Set<String> productClasses=new Set<String>();
        Set<String> itemGroups=new Set<String>();
        Set<String> itemTypes=new Set<String>();
        Set<String> productLines=new Set<String>();
        Set<String> product2Ids=new Set<String>();
        Set<String> paymentTerms=new Set<String>();
        Set<String> businessUnits=new Set<String>();
        Set<String> priceGroups=new Set<String>();
        
        product2Ids.add('ALL');
        for(OrderItem item:orderItems){
            if(item.Order.Area__c!=null) 
                orderLineAreas.add(item.Order.Area__c);
            if(item.Order.Sales_Office__c!=null)
                salesOffices.add(item.Order.Sales_Office__c);
            if(item.Order.Internal_Sales_Representative__c!=null && item.Order.Internal_Sales_Representative__r.Zone__c!=null)
                zones.add(item.Order.Internal_Sales_Representative__r.Zone__c);
            else if(item.Order.External_Sales_Representative__c!=null && item.Order.External_Sales_Representative__r.Zone__c!=null)
                zones.add(item.Order.External_Sales_Representative__r.Zone__c);
            if(item.Order.Sold_to_Business_Partner__c!=null)
                accountCodes.add(item.Order.Sold_to_Business_Partner__c);
            if(item.Order.Type!=null)
                orderTypes.add(item.Order.Type);
            if(item.Order.Delivery_Terms__c!=null)
                deliveryTerms.add(item.Order.Delivery_Terms__c);
            if(item.Product2.Manufacturer__c!=null)
                manufactures.add(item.Product2.Manufacturer__c);
            if(item.Order.Order_Currency__c!=null)
                orderCurrencies.add(item.Order.Order_Currency__c);
            if(item.Order.Sales_Price_List__c!=null)
                salesPriceLists.add(item.Order.Sales_Price_List__c);
            if(item.Order.Branch__r.Channel__c!=null)
                channels.add(item.Order.Branch__r.Channel__c);
            if(item.Order.Payment_Terms__c!=null)
                paymentTerms.add(item.Order.Payment_Terms__c);
            if(item.Product2.Product_Class__c!=null)
                productClasses.add(item.Product2.Product_Class__c);
            if(item.Product2.Item_Group__c!=null)
                itemGroups.add(item.Product2.Item_Group__c);
            if(item.Product2.Price_Group__c!=null)
                priceGroups.add(item.Product2.Price_Group__c);
            if(item.Product2.Item_Type__c!=null)
                itemTypes.add(item.Product2.Item_Type__c);
            if(item.Product2.Product_Line__c!=null)
                productLines.add(item.Product2.Product_Line__c);
            if(item.Product2Id!=null)
                product2Ids.add(String.valueOf(item.Product2Id));
            if(item.Order.Business_unit__c!=null)
                businessUnits.add(item.Order.Business_unit__c); 
        }
        List<Discount_Matrix__c> discountsMatrices=new List<Discount_Matrix__c>();
        discountsMatrices=[Select Id,Discount_Percent__c,Discount_Amount__c,Exclusive__c,Level__c,Area__c,Sales_Office__c,
                           Zone__c,BP_Code__c,Order_Type__c,Delivery_Terms__c,Manufacturer__c,
                           Order_Currency__c,Price_List__c,Channel__c,Product_Class__c,
                           Item_Group__c,Item_Type__c,Product_Line__c,Item_Code__c,
                           Payment_Terms__c,Business_Unit__c,Price_Group__c,Matrix_Source__c,
                           Gross_Net__c 
                           From Discount_Matrix__c
                           Where (Area__c=null Or Area__c In :orderLineAreas) And 
                           (Sales_Office__c=null Or Sales_Office__c In :salesOffices ) And
                           (Zone__c=null Or Zone__c In :zones) And 
                           (BP_Code__c=null Or BP_Code__c In :accountCodes) And 
                           (Order_Type__c=null Or Order_Type__c In :orderTypes) And 
                           (Delivery_Terms__c=null Or Delivery_Terms__c In :deliveryTerms) And 
                           (Manufacturer__c=null Or Manufacturer__c In :manufactures) And 
                           (Order_Currency__c=null Or Order_Currency__c In :orderCurrencies) And 
                           (Price_List__c=null Or Price_List__c In :salesPriceLists) And 
                           (Channel__c=null Or Channel__c In :channels) And 
                           (Product_Class__c=null Or Product_Class__c In :productClasses) And 
                           (Item_Group__c=null Or Item_Group__c In :itemGroups) And 
                           (Item_Type__c=null Or Item_Type__c In :itemTypes) And 
                           (Product_Line__c=null Or Product_Line__c In :productLines) And 
                           (Item_Code_Text__c In :product2Ids) And 
                           (Payment_Terms__c=null Or Payment_Terms__c In :paymentTerms) And
                           (Business_Unit__c=null Or Business_Unit__c In :businessUnits) And
                           (Price_Group__c=null Or Price_Group__c In :priceGroups) And
                           Stage__c='Active'  And Start_Date__c<=TODAY And
                           (End_Date__c=null OR End_Date__c>=TODAY)];    
        
        return discountsMatrices;
    }
    
    /*------------------------------------------------------------------------
Author:        Manasi Londhe
Company:       Salesforce
Description:   Returns a Map of order Item and matrices matched
----------------------------------------------------------------------------*/
    public Map<Id,List<Discount_Matrix__c>> getItemsVsMatricesMatched(List<OrderItem> orderItems,List<Discount_Matrix__c> discountsMatrices){
        Map<Id,List<Discount_Matrix__c>> itemIdVsMatricesFound=new Map<Id,List<Discount_Matrix__c>>();
        List<Profile> integrationAdminProfile=[Select  Id From Profile Where Name=:System.Label.Integration_User_Profile_Name];
        integrationAdminProfileId=integrationAdminProfile.Size()==1?integrationAdminProfile[0].Id:null;
        for(OrderItem item:orderItems){
            for(Discount_Matrix__c matrix:discountsMatrices){
                if( (matrix.Area__c==null || (matrix.Area__c==item.Order.Area__c)) &&
                   (matrix.Sales_Office__c==null || (matrix.Sales_Office__c==item.Order.Sales_Office__c)) && 
                   (matrix.Zone__c==null || (matrix.Zone__c==item.Order.Internal_Sales_Representative__r.Zone__c||matrix.Zone__c==item.Order.External_Sales_Representative__r.Zone__c )) &&
                   (matrix.BP_Code__c==null || (matrix.BP_Code__c==item.Order.Sold_to_Business_Partner__c)) &&
                   (matrix.Order_Type__c==null || (matrix.Order_Type__c==item.Order.Type)) &&
                   (matrix.Delivery_Terms__c==null || (matrix.Delivery_Terms__c==item.Order.Delivery_Terms__c)) &&
                   (matrix.Manufacturer__c==null || (matrix.Manufacturer__c==item.Product2.Manufacturer__c)) &&
                   (matrix.Order_Currency__c==null || (matrix.Order_Currency__c==item.Order.Order_Currency__c)) &&
                   (matrix.Price_List__c==null || (matrix.Price_List__c==item.Order.Sales_Price_List__c)) &&
                   (matrix.Channel__c==null || (matrix.Channel__c==item.Order.Branch__r.Channel__c)) &&
                   (matrix.Product_Class__c==null || (matrix.Product_Class__c==item.Product2.Product_Class__c)) &&
                   (matrix.Item_Group__c==null || (matrix.Item_Group__c==item.Product2.Item_Group__c)) &&
                   (matrix.Price_Group__c==null || (matrix.Price_Group__c==item.Product2.Price_Group__c)) &&
                   (matrix.Item_Type__c==null || (matrix.Item_Type__c==item.Product2.Item_Type__c)) &&
                   (matrix.Product_Line__c==null || (matrix.Product_Line__c==item.Product2.Product_Line__c)) &&
                   (matrix.Item_Code__c==null || (matrix.Item_Code__c==item.Product2Id)) &&
                   (matrix.Payment_Terms__c==null || (matrix.Payment_Terms__c==item.Order.Payment_Terms__c)) &&
                   (matrix.Business_Unit__C==null || (matrix.Business_Unit__C==item.Order.Business_Unit__C)) &&
                   integrationAdminProfileId!=null && item.Order.Owner.ProfileId!=integrationAdminProfileId){
                       if(!itemIdVsMatricesFound.containsKey(item.Id))   
                           itemIdVsMatricesFound.put(item.Id,new List<Discount_Matrix__c>{matrix});
                       else
                           itemIdVsMatricesFound.get(item.Id).add(matrix); 
                   }
            }
        }
        return itemIdVsMatricesFound;
    }
    
    /*------------------------------------------------------------------------
Author:        Manasi Londhe
Company:       Salesforce
Description:   Update order line with correct discount matrix code ,amount,percentage.  
----------------------------------------------------------------------------*/
    public void stampDiscountMatrixCode(List<OrderItem> orderItems,Map<Id,List<Discount_Matrix__c>> itemIdVsMatricesFound){
        for(OrderItem item:orderItems){
            if(itemIdVsMatricesFound.containsKey(item.Id)){
                if(itemIdVsMatricesFound.get(item.Id).size()==1){
                    updateOrderItem(item,itemIdVsMatricesFound.get(item.Id)[0]); 
                }
                else if(itemIdVsMatricesFound.get(item.Id).size()>1){
                    Boolean exclusiveFound=false;
                    for(Discount_Matrix__c matrix:itemIdVsMatricesFound.get(item.Id)){
                        if(matrix.Exclusive__c){
                            updateOrderItem(item,matrix);
                            exclusiveFound=true;
                            break;
                        }
                    }
                    if(!exclusiveFound){
                        for(Discount_Matrix__c matrix:itemIdVsMatricesFound.get(item.Id)){
                            updateOrderItem(item,matrix);
                        }
                    }
                }
            }
        }
        
        //Commenting this block as mentioned by praful in a triage call on 13/08/2020 - Uncommented by Praful 14-08
        //Added here by Praful - 11-08-2020
        //setting default discount matrix
        //check if discount amtrix applied for each product for each level
        
        List<Discount_Matrix__c> dm=new List<Discount_Matrix__c>();
        
        if(!test.isRunningTest())
            dm=[Select Id From Discount_Matrix__c Where Id=:System.Label.Default_Discount_Matrix];
        else
            dm=[Select Id From Discount_Matrix__c Where name='No Discount'];
        
        Id defaultDiscountMatrixId;
        
        //Throw exeption with valid error message, if discount matrix is not found
        if( dm.Size()==0){
            InvalidParameterValueException e = new InvalidParameterValueException('','');
            e.setMessage('Couldn\'t find Default Discount Matrix, please check custom label - Default_Discount_Matrix');
            throw e;
        }else{
            defaultDiscountMatrixId = dm[0].Id;
        }
        
        if(defaultDiscountMatrixId!=null){
            for(OrderItem objOrderItem : orderItems){
                OrderItem orderPro = (idVsItem.containsKey(objOrderItem.Id) ? idVsItem.get(objOrderItem.Id) : objOrderItem );
                for( Integer level=2; level<12; level++ ){
                    if( orderPro.get('Applied_Discount_Matrix_Level_'+level+'_Code__c') == null 
                       && integrationAdminProfileId!=null && 
                       //Business Unit field added by Anupam on 4/9/2021 to bypass NoDiscount for interio
                       orderPro.Order.Owner.ProfileId!=integrationAdminProfileId && orderPro.Order.Business_Unit__c !=GlobalConstants.INTERIO_BUSINESS_UNIT){
                           orderPro.put('Applied_Discount_Matrix_Level_'+level+'_Code__c',defaultDiscountMatrixId);
                           orderPro.put('Applied_Discount_Matrix_Level_'+level+'_Amount__c', 0);
                           orderPro.put('Applied_Discount_Matrix_L'+level+'_Percentage__c', 0);
                           idVsItem.put( objOrderItem.Id, orderPro );
                       }
                }
            }
        }
    }
    
    /*------------------------------------------------------------------------
Author:        Manasi Londhe
Company:       Salesforce
Description:   Rerun the discount matrix logic if order is updated 
----------------------------------------------------------------------------*/
    public void updateDiscountCodeOnOrderUpdate(Map<Id,Order> newItems,Map<Id,Order> oldItems){  
        Set<Id> orderIds=new Set<Id>();
        Set<Id> orderItemIds=new Set<Id>();
        for(Order o:newItems.Values()){
            if(o.Area__c!=oldItems.get(o.Id).Area__c || o.Sales_Office__c!=oldItems.get(o.Id).Sales_Office__c || o.Type!=oldItems.get(o.Id).Type 
               || o.Delivery_Terms__c!=oldItems.get(o.Id).Delivery_Terms__c  || o.Order_Currency__c!=oldItems.get(o.Id).Order_Currency__c  
               || o.Sales_Price_List__c!=oldItems.get(o.Id).Sales_Price_List__c ||
               o.Payment_Terms__c!=oldItems.get(o.Id).Payment_Terms__c || o.Branch__c!=oldItems.get(o.Id).Branch__c ){
                   orderIds.add(o.Id);
               }
            
        }
        if(orderIds.size()>0){
            Map<Id,OrderItem> IdVsOrderItems=new Map<Id,OrderItem>([Select Id From OrderItem Where OrderId In :orderIds]);
            for(OrderItem item:IdVsOrderItems.values()){
                for(Integer i=2;i<12;i++){
                    item.put('Applied_Discount_Matrix_L'+i+'_Percentage__c',null);
                    item.put('Applied_Discount_Matrix_Level_'+i+'_Code__c',null);
                    item.put('Applied_Discount_Matrix_Level_'+i+'_Amount__c',null);
                }
            }
            OrderItemTriggerHandler.TriggerDisabled=true;
            //resetting on the level values in orderLineItem
            Update IdVsOrderItems.Values();
            OrderItemTriggerHandler.TriggerDisabled=false;
            processDiscountMatrix(IdVsOrderItems);
        }
    }
    
    /*------------------------------------------------------------------------
Author:        Manasi Londhe
Company:       Salesforce
Description:   Method to reverse calculate level 2 to 11 discount amount and percentage field if either one of them is entered.
----------------------------------------------------------------------------*/
    public void reverseCalculateLevel2To11DiscountFields(List<OrderItem> newOrderItems,Map<Id,OrderItem> oldItems){
        List<OrderItem> applicableOrderItems=new List<OrderItem>();
        for(OrderItem item:newOrderItems){
            for(Integer i=2;i<=11;i++){
                if((item.get('Applied_Discount_Matrix_Level_'+i+'_Amount__c')!=oldItems.get(item.Id).get('Applied_Discount_Matrix_Level_'+i+'_Amount__c'))
                   || item.get('Applied_Discount_Matrix_L'+i+'_Percentage__c')!=oldItems.get(item.Id).get('Applied_Discount_Matrix_L'+i+'_Percentage__c')){
                       applicableOrderItems.add(item);
                       break;
                   }
            }
        }
        for(OrderItem item:applicableOrderItems){
            for(Integer i=2;i<=11;i++){
                if(((Double)item.get('Applied_Discount_Matrix_L'+i+'_Percentage__c'))!=null 
                   && ((Double)item.get('Applied_Discount_Matrix_L'+i+'_Percentage__c'))>0
                   && item.UnitPrice!=null
                   && (((Double)item.get('Applied_Discount_Matrix_Level_'+i+'_Amount__c'))==0 || ((Double)item.get('Applied_Discount_Matrix_Level_'+i+'_Amount__c'))==null)){
                       Double amount=((Double)item.get('Applied_Discount_Matrix_L'+i+'_Percentage__c')/100)*item.UnitPrice;
                       //Aug 05 2022: Added if condition
                       if(GlobalConstants.INTEGRATION_USER_SF_ID == UserInfo.getUserId() && (String)oldItems.get(item.Id).get('CreatedById') != GlobalConstants.INTEGRATION_USER_SF_ID)
                       {
                           item.put('Applied_Discount_Matrix_Level_'+i+'_Amount__c',oldItems.get(item.Id).get('Applied_Discount_Matrix_Level_'+i+'_Amount__c')) ;
                           
                       }
                       else
                       {
                           //End of Aug 05 2022: Added if condition
                           
                           item.put('Applied_Discount_Matrix_Level_'+i+'_Amount__c',amount);
                       }
                   }
                else if(((Double)item.get('Applied_Discount_Matrix_Level_'+i+'_Amount__c'))!=null 
                        && ((Double)item.get('Applied_Discount_Matrix_Level_'+i+'_Amount__c'))>0
                        && item.UnitPrice!=null && item.UnitPrice>0
                        && (((Double)item.get('Applied_Discount_Matrix_L'+i+'_Percentage__c'))==0 || ((Double)item.get('Applied_Discount_Matrix_L'+i+'_Percentage__c'))==null)){
                            Double amt=(Double)item.get('Applied_Discount_Matrix_Level_'+i+'_Amount__c');
                            Double percentage=(amt*100)/item.unitPrice;
                            //Aug 05 2022: Added if condition
                            if(GlobalConstants.INTEGRATION_USER_SF_ID == UserInfo.getUserId() && (String)oldItems.get(item.Id).get('CreatedById') != GlobalConstants.INTEGRATION_USER_SF_ID)
                            {
                                item.put('Applied_Discount_Matrix_L'+i+'_Percentage__c',oldItems.get(item.Id).get('Applied_Discount_Matrix_L'+i+'_Percentage__c')) ;
                                
                            }
                            else
                            {
                                //End of Aug 05 2022: Added if condition                   
                                item.put('Applied_Discount_Matrix_L'+i+'_Percentage__c',percentage);
                            }
                        }
            }
        }
    }
    
    /*------------------------------------------------------------------------
Author:        Manasi Londhe
Company:       Salesforce
Description:   Method to validate matrix Id Stored in Default_Discount_Matrix custom label
----------------------------------------------------------------------------*/
    /*public Static void validateDefaultDiscountMatrix(OrderItem orderLine){
List<Discount_Matrix__c> discountMatrices=new List<Discount_Matrix__c>(); 
discountMatrices=[Select Id From Discount_Matrix__c Where Id=:System.Label.Default_Discount_Matrix];
if(!Test.isRunningTest() && discountMatrices.Size()!=1)
orderLine.adderror('No Discount Matrix Found With Id '+System.Label.Default_Discount_Matrix+' Please Configure DEFAULT DISCOUNT MATRIX Custom label Correctly');
}*/
}