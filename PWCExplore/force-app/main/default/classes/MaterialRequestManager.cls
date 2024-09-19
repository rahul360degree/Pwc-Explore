/*------------------------------------------------------------------------
Author:        Shailja Mishra
Company:       Salesforce
Description:   Class to manage 'Generate Material Request' on Case
Inputs:        NA 
Test Class:   
---------------------------------------------------------------------------
History
21-12-2020      Shailja Mishra     Initial Release
----------------------------------------------------------------------------*/
public without sharing class MaterialRequestManager {
    public static final Id MHE_ORDER_PRIMARY_RECORDTYPEID = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get(GlobalConstants.MHE_PRIMARY).getRecordTypeId();
   //Added by sumith sharma on 8 -march-2021 - Record Type MHE secondary
    public static final Id MHE_ORDER_SECONDARY_RECORDTYPEID = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get(GlobalConstants.MHE_SECONDARY).getRecordTypeId();
    public static final string CONFIGURED_ASSET_9_BLANKS = '         ';
    public static final string CONFIGURED_ASSET_23_BLANKS = '                       ';
    /*------------------------------------------------------------------------
     Author:        Shailja Mishra 
     Company:       Salesforce
     Description:   Method is reponsible for returning wrapper
     Inputs:        serviceFormId
    --------------------------------------------------------------------------
     History
     29-12-2020      Shailja Mishra     Initial Release
    -----------------------------------------------------------------------*/
    @AuraEnabled
    public static InitReturnWrapper init(String serviceFormId){
    system.debug('@@testacc');
        Service_Form__c serviceform = getServiceFormData(serviceFormId);
        //Added by sumit - 22 - april -2021 - to get service form id
        Id assetId = serviceform.Case__r.AssetId;
        InitReturnWrapper wrapper = new InitReturnWrapper();
        wrapper.mheRecordTypeId = MHE_ORDER_PRIMARY_RECORDTYPEID;
        wrapper.mheRecordTypeIdSecondary = MHE_ORDER_SECONDARY_RECORDTYPEID;
        wrapper.serviceForm = serviceform;
        wrapper.cli = getCLI(assetId);
        wrapper.mrType = getMRType(serviceform);//serviceform.Case__r.Asset.Product_Purchased_Warranty_End_Date__c, serviceform.Case__r.Asset.Product_Purchased_Warranty_Start_Date__c, serviceform.Case__r.AssetId);
        wrapper.salesOrderSeriesOptions = getSalesOrderSeriesOptions('CreateMaterialRequestSalesOrderSeriesOpt');
        wrapper.rentalOptions =   getSalesOrderSeriesOptions('CreateMaterialRequestRentalsOrderOptions');
        wrapper.contractOptions = getSalesOrderSeriesOptions('CreateMaterialRequestContractOrderOption');
        wrapper.warrantyOptions = getSalesOrderSeriesOptions('CreateMaterialRequestWarrantyOrderOption');
        wrapper.goodwillOptions = getSalesOrderSeriesOptions('CreateMaterialRequestGoodwillOrderOption');
         //Added by sumith sharma on  4-march- 2021 - Dealer consumption order
        wrapper.categoryOptions = getSalesOrderSeriesOptions('CreateMaterialRequestCategoryOrderOption');
        wrapper.lineOfBusinessOptions =  getSalesOrderSeriesOptions('CreateMaterialRequestLineOfBusinessOrder');
        wrapper.salesTypeOptions =  getSalesOrderSeriesOptions('CreateMaterialRequestSalesTypeOrderoptn');
        wrapper.businessUnitOptions =  getSalesOrderSeriesOptions('CreateMaterialRequestBusinessUnOrderoptn');
        wrapper.enquiryCategoryOptions =  getSalesOrderSeriesOptions('CreateMaterialRequestEnquiryCaOrderOptn');
        wrapper.subDivisionOptions =  getSalesOrderSeriesOptions('CreateMaterialRequestSubDivOrderOptn');
        wrapper.defaultLogisticCompany =  getdefaultLogisticCompany();
        wrapper.srAccountId = getServiceFormId(serviceFormId);

        system.debug('@@@AccountID1'+wrapper.srAccountId);


        if(getSalesOffice().size() > 0){ 
            wrapper.salesServiceOfficeId = getSalesOffice()[0].Id;
        }
       /* if(getAccountName().size() > 0){ 
            wrapper.srAccountId = getAccountName()[0].Service_Form__r.Case__r.AccountId;
            system.debug('@@@AccountID2'+wrapper.srAccountId);
        } */
        return wrapper;
    }
    
   
    public class InitReturnWrapper {
        @auraEnabled public Id mheRecordTypeId{get; set;}
        @auraEnabled public Id mheRecordTypeIdSecondary{get; set;}
        @auraEnabled public String mrType{get; set;}
        @auraEnabled public Id caseId{get; set;}
        @auraEnabled public Service_Form__c serviceForm{get; set;}
        @auraEnabled public ContractLineItem cli{get; set;}
        @auraEnabled public List<String> salesOrderSeriesOptions{get; set;}
        @auraEnabled public List<String> rentalOptions{get; set;}
        @auraEnabled public List<String> contractOptions{get; set;}
        @auraEnabled public List<String> warrantyOptions{get; set;}
        @auraEnabled public List<String> goodwillOptions{get; set;}
        @auraEnabled public Id salesServiceOfficeId{get; set;}
        @auraEnabled public Id srAccountId{get; set;}
        @auraEnabled public List<String> categoryOptions{get; set;}
        @auraEnabled public List<String> lineOfBusinessOptions{get; set;}
        @auraEnabled public List<String> salesTypeOptions{get; set;}
        @auraEnabled public List<String> businessUnitOptions{get; set;}
        @auraEnabled public List<String> enquiryCategoryOptions{get; set;}
        @auraEnabled public List<String> subDivisionOptions{get; set;}
        @auraEnabled public User defaultLogisticCompany{get; set;}



        public InitReturnWrapper(){
        }
    }
    
    /*------------------------------------------------------------------------
     Author:        Shailja Mishra 
     Company:       Salesforce
     Description:   Method is reponsible for returning Contractlineitem record
                    based on ServiceForm.Case.AssetId
     Inputs:        assetId
    ---------------------------------------------------------------------------
     History
     21-01-2021      Shailja Mishra     Initial Release
    -----------------------------------------------------------------------*/
     public static ContractLineItem getCLI(string assetId){
     system.debug('@@testacc');
        List<ContractLineItem> cli = [Select Id, AssetId, ServiceContract.MHE_Division__c, ServiceContract.StartDate, ServiceContract.EndDate, ServiceContract.Sales_Rep_Code__c, ServiceContract.Status 
                                      From ContractLineItem Where AssetId = :assetId And ServiceContract.Status=:GlobalConstants.ACTIVE Order By ServiceContract.StartDate Desc, ServiceContract.EndDate Desc Limit 1]; //01-08-2023 Added One filter(ServiceContract status is active)
        if(cli.size() > 0){
            return cli[0];
        }else{
            return new ContractLineItem();
        }
    }
    
    
    /*
     * Description: Method is to get SalesOffice 
     */
    public static List<Sales_Office__c> getSalesOffice(){
        return new List<Sales_Office__c>([Select Id, LN_Sales_Office_Code__c From Sales_Office__c Where LN_Sales_Office_Code__c = :GlobalConstants.SALESOFFICE_CODE_MRTYPE_SALES Limit 1]);
    }
    /* 
     * Description: Method to get Account name -- added by sumith - 22-april-2021
     */
     /* public static List<SR_Products__c> getAccountName(){
      Id serviceFormId = getServiceFormId(Id serviceForm);
        return new List<SR_Products__c>([select Service_Form__r.Case__r.AccountId ,Service_Form__c from SR_Products__c Where Service_Form__c =: serviceFormId limit 1]);    
      } */
    /*
    Added by sumit on 22- April- 2021 to get Service form ID
    */
    public static ID getServiceFormId(Id serviceFormId){ 
    system.debug('@@testacc'); 
    list<id> idlist = new list<id>();
        list<Service_Form__c> AccountID = [select Case__r.AccountId  from Service_Form__c Where id=:serviceFormId limit 1];
        for(Service_Form__c SF : AccountID){
            idlist.add(SF.Case__r.AccountId);
        }
        system.debug('@@@idlist  '+ idlist);
        Id SFAccountID = idlist.get(0);
        system.debug('@@@SFAccountID '+SFAccountID);
        return SFAccountID;
    }
    /*------------------------------------------------------------------------
     Author:        Shailja Mishra 
     Company:       Salesforce
     Description:   Method is reponsible for returning Contractlineitem record
                    based on ServiceForm.Case.AssetId
     Inputs:        assetId
    ---------------------------------------------------------------------------
     History
     21-01-2021      Shailja Mishra     Initial Release
    -----------------------------------------------------------------------*/
    @AuraEnabled
     public static Address_by_BP__c getAddressByBP(String accountId, String branchName){
     system.debug('@@testacc');
        List<Address_by_BP__c> abp = [Select Id, Account__c, Branch__c, isPrimary__c, Branch_Name__c
                                      From Address_by_BP__c Where Account__c = :accountId And Branch_Name__c = :branchName Order By isPrimary__c Desc Limit 1];
        if(abp.size() > 0){
            return abp[0];
        }else{
            return new Address_by_BP__c();
        }
    }
    /*------------------------------------------------------------------------
     Author:        Shailja Mishra 
     Company:       Salesforce
     Description:   Method is reponsible for inserting OrderRecord and returing OrderRecord.Id
     Inputs:        serviceFormId, OrderRecord
    ---------------------------------------------------------------------------
     History
     29-12-2020      Shailja Mishra     Initial Release
    -----------------------------------------------------------------------*/
    @AuraEnabled
    public static Id insertRecord(Id serviceFormId, Order orderRec, String supplyTo, boolean isDealerConsumption){
    system.debug('@@testacc');
        Service_Form__c serviceForm = getServiceFormData(serviceFormId);
        //Populate remaining defaults on Order
       // if(isDealerConsumption== true){
        orderRec = populateOrderFields(orderRec,serviceform,isDealerConsumption);
        //}
        system.debug('@@@orderRec1'+ orderRec);
        
        //Added if Condition (line 183 and 187) by Sumith sharma 28 - Apr -2021
        if(isDealerConsumption != true){
        //Populate approvers for Material Request Approval Process
        MaterialRequestApprovalHelper mrHelper = new MaterialRequestApprovalHelper();
        orderRec = mrHelper.populateApprovers(new List<Order> {orderRec})[0];
        system.debug('@@@orderRec2'+ orderRec);

        }
        //populate WareHouseCode
        orderRec = populateWarehouseCode(orderRec); 
        
        /* Set PriceBook for Dealer Consumption
        Added On 29-05-2021 for MHE Dealer Consumption
        Added By Alpana S*/
        if(isDealerConsumption == true){
        orderRec = setPriceBookForDealerConsumption(orderRec);          
       }          
        
        //populate Sold To, Ship To Addresses
        if(isDealerConsumption != true){
        orderRec = populateSoldToShipToAddress(serviceForm, orderRec, supplyTo);
        }
        
       // list<SR_Products__c> srList=[select id,Service_Form__c,Product_Type__c from SR_Products__c where Service_Form__c=:serviceFormId and Product_Type__c ='Exclusion' limit 1];
          
            insert orderRec; 
       
        if(orderRec.Level_1_Approver__c != null){
            shareOrderWithApprover(orderRec.Id, orderRec.Level_1_Approver__c);
        }
       /* //Added by sumith sharma on 10 -march-2021
        order order = [select id,Pricebook2Id from order where id=:orderRec.Id];
        insertOrderProducts(order,serviceFormId,isDealerConsumption); */
        return orderRec.Id;
    }
    
    /*
     * Description: Insert OrderProducts for respective Order and ServiceForm
     */
    @AuraEnabled
    public static Id insertOrderProducts(Id serviceFormId,Id orderId,boolean isDealerConsumption){
    system.debug('@@testacc');
        Order order = [Select Id, Pricebook2Id From Order Where Id = :orderId];
       // if(isDealerConsumption==true){
        insertOrderProducts(order,serviceFormId,isDealerConsumption);
        //}
        return orderId;
    }
    
    /*
     * Description: Update Order field on ServiceForm record
     */
    @AuraEnabled
    public static Id updateServiceForm(Service_Form__c serviceForm, Id orderId){
        try{
            if(serviceForm.Order__c == null){
                serviceForm.Order__c = orderId;
                update serviceForm;
            }
        }catch(Exception ex){
            AuraHandledException aex = new AuraHandledException('Error in updating ServiceForm');
            aex.setMessage(ex.getMessage());
        }
        return serviceForm.Id;
    }
    
    /*
     * Description: Populate warehouse Code
     */
    public static Order populateWarehouseCode(Order orderRecord){
        Map<String, String> branchVsWarehouse = new Map<String, String>();
        if(orderRecord.MR_Type__c == GlobalConstants.MRTYPE_Sales){
            List<Warehouse__c> warehouses = [Select Id, Warehouse__c From Warehouse__c Where Warehouse__c = :GlobalConstants.WAREHOUSE_CODE_MRTYPE_SALES Limit 1];
            if(warehouses.size() == 1){
                orderRecord.WarehouseCode__c = warehouses[0].Id;
            }
        }else if(orderRecord.Logistics_Company_Branch__c != null){
            for(Warehouse_defaults__mdt mdt : [Select Id, Location_Id__c, Warehouse_code__c From Warehouse_defaults__mdt Where Location_Id__c =: orderRecord.Logistics_Company_Branch__c]){
                branchVsWarehouse.put(mdt.Location_Id__c, mdt.Warehouse_code__c); 
            }
            Map<String, Warehouse__c> warehouseCodeVsWarehouse = new Map<String, Warehouse__c>();
            if(!branchVsWarehouse.isEmpty()){
                for(Warehouse__c wh : [Select Id, Warehouse__c From Warehouse__c Where Warehouse__c IN: branchVsWarehouse.values()]){
                    warehouseCodeVsWarehouse.put(wh.Warehouse__c, wh);
                }
            }
            if(!warehouseCodeVsWarehouse.isEmpty()){
                if(branchVsWarehouse.containsKey(orderRecord.Logistics_Company_Branch__c)
                   && warehouseCodeVsWarehouse.containsKey(branchVsWarehouse.get(orderRecord.Logistics_Company_Branch__c))){
                    orderRecord.WarehouseCode__c = warehouseCodeVsWarehouse.get(branchVsWarehouse.get(orderRecord.Logistics_Company_Branch__c)).Id;
                }
            }
        }
        return orderRecord;
    } 
    
     /*------------------------------------------------------------------------
     Description:   Method is reponsible to set Pricebook for dealer consumption orders
     Input:        OrderRecord
     Added on:     29.05.2021
     Added By:     Alpana S   
    -----------------------------------------------------------------------*/
    public static Order setPriceBookForDealerConsumption(Order orderRecord){
    if (orderRecord != null){    
        orderRecord.Pricebook2Id =System.label.OrderRecordPricebook2Id; 
     }
    return orderRecord;
    }
    
    
    
    
    /*
     * Description: Method is responsible for populating and validating Sold To/Ship To Address
     */
   // @Testvisible Public static List<Address_By_BP__c> addressByBP = new List<Address_By_BP__c>();
    public static Order populateSoldToShipToAddress(Service_Form__c serviceForm, Order orderRecord, String supplyTo){
        Id shipToAccountPrimaryAddress = [Select Id, Primary_Address__c From Account Where Id = :orderRecord.Ship_To_Account__c limit 1]?.Primary_Address__c;
      List<Address_By_BP__c>  addressByBP = [Select Id, Address_Code__c, Account__c From Address_By_BP__c 
                                              Where Branch__r.Branch_Name__c = :orderRecord.Logistics_Company_Branch__c
                                                    And
                                                    ((Account__c = :serviceForm.Case__r.AccountId And
                                                      Address_Code__c = :serviceForm.Case__r.Asset.Address_Code__c 
                                                    )
                                                    OR
                                                    (Account__c = :orderRecord.Ship_To_Account__c And 
                                                     Address_Code__c = :shipToAccountPrimaryAddress))
                                               order by isPrimary__c desc];
        if(addressByBP.size() > 0){
            for(Address_By_BP__c abp : addressByBP){
                if(serviceForm.Case__r.AccountId == abp.Account__c && abp.Address_Code__c == serviceForm.Case__r.Asset.Address_Code__c){
                    // SoldToAddress for supplyto equal to customer/dealer
                    orderRecord.Sold_To_Address__c = abp.Id;
                    //ShipTo Address for supplyTo equal to Customer
                    if(String.isNotBlank(supplyTo) && supplyTo.equalsIgnoreCase('Customer')){
                        orderRecord.Ship_To_Address__c = abp.Id;
                    }
                }else if(orderRecord.Ship_To_Account__c == abp.Account__c && abp.Address_Code__c == shipToAccountPrimaryAddress){
                    //ShipTo Address for supplyTo equal to Dealer
                        orderRecord.Ship_To_Address__c = abp.Id;
                    
                }
            }
        }
        
        if(orderRecord.Sold_To_Address__c == null || orderRecord.Ship_To_Address__c == null){
            throw new AuraHandledException(System.Label.MR_SoldTo_ShipToAddress_Validation_Message);
        }
        return orderRecord;
    }
    
    /*------------------------------------------------------------------------
     Author:        Shailja Mishra 
     Company:       Salesforce
     Description:   Method is reponsible for populating Oder Fields (Material Request fields)
     Inputs:        orderRecord, serviceform Record
    ---------------------------------------------------------------------------
     History
     29-12-2020      Shailja Mishra     Initial Release
     27-01-2021      Shailja Mishra     W-702,Regardless of Case MHE division, setting the division to "Parts"
     11-02-2021      Shailja Mishra     W-797,Regardless of SupplyTo, populate SoldToBP as Case's Account(serviceForm.Case__r.AccountId)
    -----------------------------------------------------------------------*/
    public static Order populateOrderFields(Order orderRecord, service_Form__c serviceform, Boolean isDealerConsumption){
        System.debug('@@@isDealerConsumption '+ isDealerConsumption);
        orderRecord.Ship_To_Account__c = orderRecord.AccountId;
        orderRecord.Sold_to_Business_Partner__c = serviceForm.Case__r.AccountId;
        orderRecord.Business_Unit__c = GlobalConstants.BUSINESS_UNIT_MHE_DIVISION;
        orderRecord.Service_Form__c = serviceform.Id;   
       // orderRecord.RecordTypeId = MHE_ORDER_PRIMARY_RECORDTYPEID;
        orderRecord.RecordTypeId = getRecordTyID(isDealerConsumption);
        system.debug('@@RecordTypeId1  '+orderRecord.RecordTypeId);
       // orderRecord.Record_Types__c = GlobalConstants.ORDER_MHE_ORDER_PRIMARY_RECORD_TYPES;//'MHE Order - Primary';
       orderRecord.Record_Types__c = getRecordTypes(isDealerConsumption);
       system.debug('@@Record_Types__c  '+orderRecord.Record_Types__c);
       orderRecord.Case__c = serviceform.Case__c;
        orderRecord.MHE_Division__c =  GlobalConstants.MHE_SUB_DIVISION_PARTS;
        orderRecord.Configured_Asset__c = 'S_'+ CONFIGURED_ASSET_9_BLANKS + serviceform.Case__r.Asset.UNSPC_Code__c + CONFIGURED_ASSET_23_BLANKS +'_' + serviceform.Case__r.Asset.Equipment_Serial_No__c;
        orderRecord.Intent__c = 'true';
        if(isDealerConsumption == true) {
        user getDealerUser =getDealer();
            if(getDealerUser <> null && getDealerUser.ContactId <> null && getDealerUser.Contact.AccountId<>null ){
            orderRecord.Associated_Dealer__C = getDealerUser.Contact.AccountID; 
            }
         }
        return orderRecord;
    }
    //Added by sumith sharma- 28 -April -2021  
    Public static ID getRecordTyID(Boolean isDealerConsumption){
        system.debug('@@isDealerConsumptionvalue '+isDealerConsumption);
        if(isDealerConsumption == true){
            system.debug('@@@Whendealerconsumptiontrue');      
            return MHE_ORDER_SECONDARY_RECORDTYPEID; 
        }else{
            system.debug('@@@Whendealerconsumptionfalse');      

            return MHE_ORDER_PRIMARY_RECORDTYPEID;
        }
    
    } 
    //Added by sumith sharma- 28 -April -2021 
    Public static string getRecordTypes(Boolean isDealerConsumption){
        system.debug('@@isDealerConsumptionvalue2 '+isDealerConsumption);
        if(isDealerConsumption == true){
            system.debug('@@@Whendealerconsumptiontrue1');      
            return GlobalConstants.ORDER_MHE_ORDER_SECONDARY_RECORD_TYPES;
        }else{
            system.debug('@@@Whendealerconsumptionfalse2');      
        return GlobalConstants.ORDER_MHE_ORDER_PRIMARY_RECORD_TYPES;
        } 
    } 
    /*------------------------------------------------------------------------
     Author:        Shailja Mishra 
     Company:       Salesforce
     Description:   Method is reponsible for returning ServiceForm record
     Inputs:        serviceFormId
    ---------------------------------------------------------------------------
     History
     29-12-2020      Shailja Mishra     Initial Release
    -----------------------------------------------------------------------*/
    public static service_Form__c getServiceFormData(Id serviceForm){
        return [Select Id, Order__c, Case__r.AssetId, Case__r.Address_by_BP__c, Case__r.Asset.Area_Code__c, Case__r.Asset.Contract_Number__c, Case__r.ServiceContract.Sales_Rep_Code__c,
                Case__r.Asset.Product_Purchased_Warranty_End_Date__c, Case__r.Asset.Product_Purchased_Warranty_Start_Date__c, Case__r.AccountId, Case__r.Account.Business_Unit__c, 
                Job_Card_Number__c, Case__r.ServiceContract.Pricebook2Id, Case__c, Case__r.Branch__c, Case__r.Asset.Primary_Dealer__c, Case__r.Asset.Branch__c, Case__r.Asset.Execution_Branch__c,
                Case__r.MHE_Division__c, Case__r.ServiceContract.Service_Department__c, Case__r.ServiceContract.Service_Department__r.Sales_Order_Series__c,
                Case__r.Asset.Status, Case__r.Asset.MHE_Division__c, Case__r.Asset.UNSPC_Code__c, Case__r.Asset.Equipment_Serial_No__c, Case__r.Asset.Address_Code__c
                From service_Form__c
                Where Id = :serviceForm];
    }

    /*------------------------------------------------------------------------
     Author:        Shailja Mishra 

     Company:       Salesforce
     Description:   Method is reponsible for returning MR Type based on StartDate, EndDate and Asset
     Inputs:        DateTime endDate, DateTime startDate, Id asset
    ---------------------------------------------------------------------------
     History
     29-12-2020      Shailja Mishra     Initial Release
     29-04-2021      Alpana Sahay       Modified method for Migrated Contract
     03-12-2021      Alpana Sahay       Modified to generate Service Order for Platinum Contract(OTRS 30463192) 
    -----------------------------------------------------------------------*/
      public static String getMRType(Service_form__c serviceform){
        Id quoteId;
        Id assetId;
        DateTime startDate = serviceform.Case__r.Asset.Product_Purchased_Warranty_Start_Date__c;
        Date endDate = serviceform.Case__r.Asset.Product_Purchased_Warranty_End_Date__c;
             
        
        if(startDate != null && endDate != null 
           && System.today() >= startDate.date() && System.today() <= endDate 
           && serviceform.Case__r.Asset.Status.equalsIgnoreCase(GlobalConstants.ASSET_ACTIVE_STATUS)){
            return GlobalConstants.MRTYPE_Service;
        }else {
            List<ContractLineItem> cli = [Select StartDate,EndDate, ServiceContract.Contract_Type__c, AssetId, 
                                               ServiceContract.Associated_Quote__c, 
                                          ServiceContract.StartDate, ServiceContract.EndDate, ServiceContract.Status
                                          From ContractLineItem 
                                          Where AssetId =: serviceform.Case__r.AssetId 
                                          And ServiceContract.StartDate != null And ServiceContract.EndDate != null
                                          And (ServiceContract.Contract_Type__c =:GlobalConstants.CMP_CONTRACT_TYPE 
                                          OR ServiceContract.Contract_Type__c = :GlobalConstants.CMD_CONTRACT_TYPE                                          
                                          OR ServiceContract.Contract_Type__c = :GlobalConstants.CMT_CONTRACT_TYPE)
                                          AND (ServiceContract.Status__c = 'Free' OR ServiceContract.Status__c = 'Open')
                                          Order By StartDate Desc,EndDate Desc Limit 1];           
                
                
                if(cli.size() > 0){
                    return GlobalConstants.MRTYPE_Service;
                }else{
                    return GlobalConstants.MRTYPE_Sales; 
                }
            } 
    }
    
    /*------------------------------------------------------------------------
     Author:        Shailja Mishra 
     Company:       Salesforce
     Description:   Method is reponsible for sharing Order record with BranchChampion(Level 1 Approver)
     Inputs:        Id orderRecordId, Id userId
    ---------------------------------------------------------------------------
     History
     12-02-2021      Shailja Mishra     Initial Release
    -----------------------------------------------------------------------*/
    public static void shareOrderWithApprover(Id recordId, Id userId){
        OrderShare orderShr  = new OrderShare();
        
        // Set the ID of record being shared.
        orderShr.OrderId = recordId;
        
        // Set the ID of user being granted access.
        orderShr.UserOrGroupId = userId;
        
        // Set the access level.
        orderShr.OrderAccessLevel = 'Edit';
        
        // Insert the sharing record and capture the save result. 
        // The false parameter allows for partial processing if multiple records passed into the operatio

        try{
                     Database.SaveResult sr = Database.insert(orderShr,false);
        }catch(Exception ex){
            Logger.logError('Material Request', 'MaterialRequestManager', ex.getMessage());
        } 
    }

    /*------------------------------------------------------------------------
     Author:        Shailja Mishra 
     Company:       Salesforce
     Description:   Method is reponsible for inserting OrderProducts
     Inputs:        Order order, Id serviceFormId
    ---------------------------------------------------------------------------
     History
     29-11-2020      Shailja Mishra     Initial Release
    -----------------------------------------------------------------------*/
    public static void insertOrderProducts(Order order, Id serviceFormId,boolean isDealerConsumption){
      /* if(isDealerConsumption == true){
         order.Pricebook2Id ='01s2h000000DQSAAA4'; 
       } */
        system.debug('@@@OrderProducts');
        List<OrderItem> orderProductsToInsert = new List<OrderItem>();
        Set<Id> productIds = new Set<Id>();
        system.debug('@@@productIds '+productIds);
        Map<Id, PricebookEntry> productIdVsPBE = new Map<Id, PricebookEntry>();
        //Added by sumith sharma on 10 -march-2021
        
      //  string strProductType = (isDealerConsumption ? GlobalConstants.PRODUCT_TYPE_DC : GlobalConstants.PRODUCT_TYPE_INCLUSION);
        
        string strProductType = GlobalConstants.PRODUCT_TYPE_INCLUSION;
        
        List<SR_Products__c> srProducts = [Select id,Product__c,Service_Form__r.Order__r.Pricebook2Id,Quantify__c, Service_Form__c 
                                           From SR_Products__c 
                                           Where Service_Form__c =: serviceFormId 
                                                And Product__c != null 
                                            //  And Product_Type__c = :GlobalConstants.PRODUCT_TYPE_INCLUSION 
                                                And Product_Type__c = :strProductType 
                                                And isConverted__c = false
                                                AND Ignore_record__c = false];
        system.debug('@@@OrderProducts2 '+srProducts);
        for(SR_Products__c srp : srProducts){
                productIds.add(srp.Product__c);  
        }
        
        for(PricebookEntry pbe : [Select Id, Product2Id,Pricebook2Id, UnitPrice From PricebookEntry Where Pricebook2Id =: order.Pricebook2Id AND Product2Id IN: productIds]){
           system.debug('@@1234');
           system.debug(pbe);

            productIdVsPBE.put(pbe.Product2Id, pbe);
        }
        
        if(!productIdVsPBE.isEmpty()){
            for(SR_Products__c srp : srProducts){
                if(productIdVsPBE.containsKey(srp.Product__c)){
                    OrderItem item = new OrderItem(OrderId = order.Id,
                                                   Product2Id = srp.Product__c,
                                                   Quantity = srp.Quantify__c != null ? srp.Quantify__c : 1,
                                                   PriceBookEntryId = productIdVsPBE.get(srp.Product__c).Id,
                                                   ListPrice = productIdVsPBE.get(srp.Product__c).UnitPrice,
                                                   UnitPrice = productIdVsPBE.get(srp.Product__c).UnitPrice,
                                                   Line_Discount__c = 100);
                    orderProductsToInsert.add(item);
                    system.debug('@@@orderproductsize '+orderProductsToInsert);
                }
            }
        }
       // if(orderProductsToInsert.Size() > 0){
            system.debug('@@@orderproductsize '+orderProductsToInsert );

            Insert orderProductsToInsert;
      //  }
    }
    
    /*------------------------------------------------------------------------
     Author:        Shailja Mishra 
     Company:       Salesforce
     Description:   Method is reponsible for validating Order Products
                    (Before Update)
     Inputs:        List<OrderItem> newLineItems
    ---------------------------------------------------------------------------
     History
     31-12-2020      Shailja Mishra     Initial Release
    -----------------------------------------------------------------------*/
     public void validateOrderProducts(Map<Id, OrderItem> newItems, Map<Id,OrderItem> oldItems){
        List<OrderItem> orderItems = new List<OrderItem>();
        for(OrderItem oi : newItems.values()){
            if((oi.Quantity != oldItems.get(oi.Id).Quantity)
               || (oi.Product2Id != oldItems.get(oi.Id).Product2Id)){
                orderItems.add(oi);
            }
        }
        if(orderItems.size() > 0)
            validateOrderProducts(orderItems);
    }
    
    /*------------------------------------------------------------------------
     Author:        Shailja Mishra 
     Company:       Salesforce
     Description:   Method is reponsible for validating Order Products
                    (Before Insert)
     Inputs:        List<OrderItem> newLineItems
    ---------------------------------------------------------------------------
     History
     31-12-2020      Shailja Mishra     Initial Release
    -----------------------------------------------------------------------*/
    public void validateOrderProducts(List<OrderItem> newLineItems){
        List<Id> orderIds = new List<Id>();
        Set<Id> productIds = new Set<Id>();
        for(OrderItem oi : newLineItems){
            orderIds.add(oi.OrderId);
            productIds.add(oi.Product2Id);
        }
        
        List<Id> serviceFormIds = new List<Id>();
        Map<Id, Id> orderIdVsServiceFormId = new Map<Id, Id>();
        for(Order od: [Select Id, Service_Form__c from Order Where Id IN: orderIds And Service_Form__c != null]){
            serviceFormIds.add(od.Service_Form__c);
            orderIdVsServiceFormId.put(od.Id, od.Service_Form__c);
        }
        
        
        Map<Id, Map<Id, SR_Products__c>> srFormIdVsSRProductsMap = new Map<Id, Map<Id,SR_Products__c>>();
        for(SR_Products__c srp : [Select Id, Service_Form__c, Product__c, Quantify__c From SR_Products__c Where Service_Form__c IN: serviceFormIds And Product__c IN: productIds]){
            if(srFormIdVsSRProductsMap.containsKey(srp.Service_Form__c)){
                srFormIdVsSRProductsMap.get(srp.Service_Form__c).put(srp.Product__c, srp);
            }else{
                srFormIdVsSRProductsMap.put(srp.Service_Form__c, new Map<Id, SR_Products__c>{srp.Product__c => srp});
            }
        }
        
        Boolean isProductPresent = false;
        if(!orderIdVsServiceFormId.isEmpty()){
            for(OrderItem oi : newLineItems){
                if(orderIdVsServiceFormId.containsKey(oi.OrderId)){
                    Id serviceFormId = orderIdVsServiceFormId.get(oi.OrderId);
                    if(srFormIdVsSRProductsMap.containsKey(serviceFormId)){
                        Map<Id, SR_Products__c> idVsSRProduct = srFormIdVsSRProductsMap.get(serviceFormId);
                        if(idVsSRProduct.containsKey(oi.Product2Id)){
                            isProductPresent = true;
                        }
                        if(idVsSRProduct.containsKey(oi.Product2Id)){
                            Double srQty = idVsSRProduct.get(oi.Product2Id).Quantify__c;
                            if(oi.Quantity > srQty){
                                oi.addError(System.Label.Validate_OrderItem_Quantity_From_SR_Products +' ' + srQty);
                            }
                        }
                    }
                    
                    if(isProductPresent == false){
                        oi.addError(System.Label.Validate_OrderItem_Product_From_SR_Products);
                    }
                }
            }
        }      
    }
    
    /*------------------------------------------------------------------------
     Author:        Shailja Mishra 
     Company:       Salesforce
     Description:   Method is reponsible for updating SR Products to IsConverted
                    (After Insert)
     Inputs:        Map<Id, OrderItem> newLineItems
    ---------------------------------------------------------------------------
     History
     22-01-2021      Shailja Mishra     Initial Release
    -----------------------------------------------------------------------*/
    public void updateSRProducts(Map<Id, OrderItem> newItems ){
        List<Id> orderIds = new List<Id>();
        List<Id> productIds = new List<Id>();
        for(OrderItem oi : newItems.values()){
            orderIds.add(oi.OrderId);
            productIds.add(oi.Product2Id);
        }
        
        List<Id> serviceFormIds = new List<Id>();
        Map<Id, Id> orderIdVsServiceFormId = new Map<Id, Id>();
        
        //Added on 25-Jun-2021
        Map<Id, String> orderIdVsRecordType = new Map<Id, String>();
        
        for(Order od: [Select Id, Service_Form__c, Record_Types__c from Order Where Id IN: orderIds And Service_Form__c != null]){
            serviceFormIds.add(od.Service_Form__c);
            orderIdVsServiceFormId.put(od.Id, od.Service_Form__c);
            //Added on 25-Jun-2021
            orderIdVsRecordType.put(od.Id, od.Record_Types__c);
        }
        
        Map<Id, Map<Id, SR_Products__c>> srFormIdVsSRProductsMap = new Map<Id, Map<Id,SR_Products__c>>();
        for(SR_Products__c srp : [Select Id, Service_Form__c, Product__c, Quantify__c From SR_Products__c Where Service_Form__c IN: serviceFormIds And Product__c IN: productIds And (Product_Type__c =:GlobalConstants.PRODUCT_TYPE_INCLUSION OR Product_Type__c =:GlobalConstants.PRODUCT_TYPE_DC)]){
            if(srFormIdVsSRProductsMap.containsKey(srp.Service_Form__c)){
                srFormIdVsSRProductsMap.get(srp.Service_Form__c).put(srp.Product__c, srp);
            }else{
                srFormIdVsSRProductsMap.put(srp.Service_Form__c, new Map<Id, SR_Products__c>{srp.Product__c => srp});
            }
        }
        
        List<SR_Products__c> srProductsToUpdate = new List<SR_Products__c>();  
        if(!orderIdVsServiceFormId.isEmpty()){
            for(OrderItem oi : newItems.values()){
                if(orderIdVsServiceFormId.containsKey(oi.OrderId)){
                    Id serviceFormId = orderIdVsServiceFormId.get(oi.OrderId);
                    if(srFormIdVsSRProductsMap.containsKey(serviceFormId)){
                        Map<Id, SR_Products__c> idVsSRProduct = srFormIdVsSRProductsMap.get(serviceFormId);
                        if(idVsSRProduct.containsKey(oi.Product2Id)){
                            SR_Products__c sr = idVsSRProduct.get(oi.Product2Id);
                            if(Schema.sObjectType.SR_Products__c.fields.isConverted__c.isUpdateable()){ 
                               sr.isConverted__c = true;
                              }
                            //Added on 25-Jun-2021
                            if (orderIdVsRecordType.get(oi.OrderId) == GlobalConstants.ORDER_MHE_ORDER_SECONDARY_RECORD_TYPES)
                            {
                                sr.Product_Type__c = GlobalConstants.PRODUCT_TYPE_DC;
                            }
                            srProductsToUpdate.add(sr);
                        }
                    }
                }
            }
        }
        
        if(srProductsToUpdate != null && srProductsToUpdate.size() > 0){
            update srProductsToUpdate;
        }   
    }
    
    @Testvisible
    private static List<String> getSalesOrderSeriesOptions(string settingName) {
        List<Application_Settings__mdt> appSettings = [SELECT Id,Values__c FROM Application_Settings__mdt WHERE DeveloperName = :settingName];
        if(appSettings.size() > 0) {
            return appSettings[0].Values__c.split(',');
        } else { 
            AuraHandledException ex = new AuraHandledException(settingName+ 'not found');
            ex.setMessage(settingName+ 'not found');
            throw ex;
        }
    }   
    //Added by sumith sharma on 10 -march-2021
    public static user getdefaultLogisticCompany(){
        user usr = [SELECT Logistic_Company__c,Sales_Order_Series__c,Business_Line__c,
        Business_Unit__c,Sub_Division__c From User WHERE username=:UserInfo.getUsername()];
    return usr; 
    }
     /*------------------------------------------------------------------------
     Author:        Alpana Sahay
     Company:       GITL
     Description:   Method is reponsible for returning Dealer associated with Dealer Consumption Order            
    ---------------------------------------------------------------------------
     History
     13-09-2021      Alpana Sahay     Initial Release
    -----------------------------------------------------------------------*/
    public static user getDealer (){
        user usr; 
        usr = [SELECT Contact.AccountID,contactid From User WHERE username=:UserInfo.getUsername()];
        return usr;        
        
    }
}