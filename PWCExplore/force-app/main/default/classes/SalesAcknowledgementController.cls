public without sharing class SalesAcknowledgementController {
        
    
    public Id orderRecordId;
    public String businessPartnerCode{get;set;}
    public Order orderRec{get;set;}
    public String COCOStoreAddress{get;set;}
    public List<Advance_Payment_Details__c> advancePayments{get;set;}
    public List<OrderItem> orderProducts{get;set;}
    public String shipToAddress{get;set;}
    public Datetime soldTocustGSTDate{get;set;}
    public String soldTocustGSTNumber{get;set;}
    public Datetime shipTocustGSTDate{get;set;}
    public String shipTocustGSTNumber{get;set;}
    public String GSTNumber{get;set;}
    public Date GSTDate{get;set;}
    public Map<Id,Decimal> orderItemVsTotalUnitAmount{get;set;}
    public Map<Id,Decimal> orderItemVsTotalAmount{get;set;}
    public String soldToAddress{get;set;}
    public Integer totalQuantity{get;set;}
    public decimal totalDiscountAmount{get;set;}
    public decimal totalTax{get;set;}
    public decimal totalIGSTAmount{get;set;}
    public decimal totalSGSTAmount{get;set;}
    public decimal totalCGSTAmount{get;set;}
    public decimal finalTotalAmount{get;set;} 
    public decimal totalDiscAmountQty{get;set;}
    public decimal totalBasicPrice{get;set;}  
    public decimal totalDiscountedBasicPrice{get;set;}  //Added by Shreela on 10th Nov 2023 for SIEPB - 107
    public String paymentTerms{get;set;}
    public Tax_Number__c taxRecord{get;set;}
    public String internalSalesRepName{get;set;}
    /*Shankar Sahu 18-1-2022
    Added below variables for 
    SRF 75 requirement-Sales acknowledgement for dealers
    */
    public decimal finalTotalAmountForDealerAck{get;set;}
    public decimal taxAmount{get;set;}
    public decimal totalTaxAmount{get;set;}
    public decimal taxRate{get;set;}
    public decimal overallTaxRate{get;set;}
    public String salestype{get;set;}
    public Boolean interioSalesAckPageCheck { get; set; }  //Added by Shreela on 22nd Nov 2023 for SIEPB - 107 
                                       
    public SalesAcknowledgementController() {
        try{
            orderRecordId=Apexpages.currentpage().getparameters().get('orderId');
            getOrderRecord();
            getPaymentTerms();
            getAdvancePaymentRecord();
            getOrderProduct();
            getTaxRecord();
            if(orderRec.Internal_Sales_Representative__c!=null)
            getInternalSalesRepAcctAndName(orderRec.Internal_Sales_Representative__r.Account__c);
            getShipToAndSoldToAddress();
            
        }
        catch(exception ex){
            Logger.logError('SalesAcknowledgementController', '', '', ex);
        }
    }

    public void getOrderRecord(){
           orderRec=[Select Id,Name,Sales_Type__c,Internal_Sales_Representative__r.Account__c,Internal_Sales_Representative__c,Ship_To_Address__r.Address_Code__r.House_Number__c,RecordType.DeveloperName,                                     
                                 Sold_to_Business_Partner__r.Name,Ship_To_Address__r.Address_Code__r.City__c,Ship_To_Address__r.Address_Code__r.Country__c,Sold_to_Business_Partner__r.Account_code__c,
                                 Ship_To_Address__r.Address_Code__r.Building__c,Ship_To_Address__r.Address_Code__r.Floor__c,Ship_To_Address__r.Address_Code__r.Street__c,
                                 Logistics_Company_Branch__c,Ship_To_Address__r.Address_Code__r.State_Province__c,Ship_To_Address__r.Address_Code__r.ZipCode__r.Name,
                                 Sold_to_Business_Partner__r.PersonMobilePhone,Internal_Sales_Representative__r.Salary_Code__c,Planned_Delivery_Date__c,
                                 Internal_Sales_Representative__r.Name,Payment_Terms__c,Sold_to_Business_Partner__r.CIN__c,Sold_To_Business_Partner__r.PersonEmail,
                                 Ship_To_Address__r.Name__c,Sold_To_Address__r.Name__c, Sold_To_Address__r.Address_Code__r.City__c,Sold_To_Address__r.Address_Code__r.Country__c,Sold_To_Address__r.Address_Code__r.State_Province__c,
                                 Sold_To_Address__r.Address_Code__r.Building__c,Sold_To_Address__r.Address_Code__r.Floor__c,Sold_To_Address__r.Address_Code__r.Street__c,
                                 Sold_To_Address__r.Address_Code_Ext__c,OrderReferenceNumber,CreatedDate,Customer_Order__c,WarehouseCode__r.Warehouse__c,Scheme_Code__r.Name,
                                 Scheme_Code__r.Description__c,Delivery_Terms_C__c,Total_Advance_Amount__c,Total_Due_Amount__c,Sales_Classification__c,Internal_Sales_Representative__r.Email,
                                 Sold_To_Address__r.Address_Code__r.House_Number__c,Sold_To_Address__r.Address_Code__r.ZipCode__r.Name,Reference_A__c,Reference_B__c,Sold_To_Address__r.Address_Code__c, Ship_To_Address__r.Address_Code__r.StateName__c,
                                 Account.PersonMobilePhone,Ship_To_Address__r.Address_Code__c,OrderNumber,
                                 Sold_to_Business_Partner__r.GSTN__c,
                                 Sold_to_Business_Partner__r.Effective_Date_GSTN__c ,Header_Text__c,Footer_Text__c,Delivery_Terms__c
                                 From Order
                                 Where Id=:orderRecordId];
    }
    
    public void getPaymentTerms(){
          Schema.DescribeFieldResult fieldResult = Order.Payment_Terms__c.getDescribe();
          List<Schema.PicklistEntry> values = fieldResult.getPicklistValues();
          for(Schema.PicklistEntry picklistEntry:values){
               if(picklistEntry.getValue()==orderRec.Payment_Terms__c)
                 paymentTerms=picklistEntry.getLabel();  
          }
    }
    
    public void getTaxRecord(){
        /* code block added to set GSTNumber and GSTDate from COCO Store account details */
        if ((orderRec != null) && (orderRec.Sold_to_Business_Partner__r.GSTN__c != null)){
            GSTNumber = orderRec.Sold_to_Business_Partner__r.GSTN__c;
        }
        if ((orderRec != null) && (orderRec.Sold_to_Business_Partner__r.Effective_Date_GSTN__c != null)){
            GSTDate = orderRec.Sold_to_Business_Partner__r.Effective_Date_GSTN__c;
        }
        /* end of code block added to set GSTNumber and GSTDate from COCO Store account details */
        List<Tax_Number__c> taxRecs=new List<Tax_Number__c>();
        if(orderRec.Sold_To_Address__c!=null && orderRec.Sold_To_Address__r.Address_Code__c!=null && orderRec.Sold_to_Business_Partner__c!=null)
          taxRecs=[Select Effective_Date__c,Tax_Number__c,Address_Code__r.State_Province__c,Business_Partner__c,Category__c,
                                    Address_Code__c,State_Province__c,Sequence_Number__c
                                    From Tax_Number__c
                                    Where Business_Partner__c=:orderRec.Sold_to_Business_Partner__c
                                    And Category__c='GSTIN'
                                    And Tax_Number__c!=null
                                    And Effective_Date__c!=null
                                    Order By Sequence_Number__c Desc];
        for(Tax_Number__c taxRec:taxRecs){
            if(taxRec.Address_Code__c!=null 
               && taxRec.Address_Code__c==orderRec.Sold_To_Address__r.Address_Code__c
               && soldTocustGSTDate==null
               && soldTocustGSTNumber==null){
                   soldTocustGSTDate=(taxRec.Effective_Date__c).date();
                   soldTocustGSTNumber=taxRec.Tax_Number__c;
            }
            if(taxRec.Address_Code__c!=null 
               && taxRec.Address_Code__c==orderRec.Ship_To_Address__r.Address_Code__c
               && shipTocustGSTDate==null
               && shipTocustGSTNumber==null){
                   shipTocustGSTDate=(taxRec.Effective_Date__c).date();
                   shipTocustGSTNumber=taxRec.Tax_Number__c;
            }
            if(taxRec.Address_Code__c==null
               && taxRec.Sequence_Number__c!=null
               && GSTDate==null
               && GSTNumber==null){
                   GSTDate=(taxRec.Effective_Date__c).date();
                   GSTNumber=taxRec.Tax_Number__c;
            }
        }
    }

    public void getAdvancePaymentRecord(){
          advancePayments=[Select Id,Amount__c,
                           Bank_Provider_Name__c,
                           Branch__c,Cheque_Date__c,Credit_Debit_Card_Approval_Code__c,
                          Credit_Card_Last_four_digits__c,Down_Payment__c,EMI_Amount__c,EMI_Scheme__c,Payment_Date__c,
                          Payment_Mode__c,Processing_Fees__c,Reference_Number__c,Remarks__c,Total_Amount_For_EMI__c,Branch__r.Name 
                          From Advance_Payment_Details__c
                          Where Order__c=:orderRecordId];

    }

    public void getOrderProduct(){
        totalQuantity=0;
        totalIGSTAmount=0;
        totalSGSTAmount=0;
        totalCGSTAmount=0;
        finalTotalAmount=0;
        totalBasicPrice=0;
        totalDiscountAmount=0;
        finalTotalAmountForDealerAck=0;
        totalDiscAmountQty=0;        
        salestype ='';
        totalDiscountedBasicPrice =0; //Added by Shreela on 22nd Nov 2023 for SIEPB-107
        totalTaxAmount=0;
        interioSalesAckPageCheck = false; //Added by Shreela on 22nd Nov 2023 for SIEPB-107
        /*Shankar Sahu 18-1-2022
        Added Sales_type__c and Product2.Tax_Rate__c in the below query for 
        SRF 75 requirement-Sales acknowledgement for dealers
        */
        
        //Added by Shreela on 22nd Nov 2023 for SIEPB - 107
        String currentUrl = ApexPages.currentPage().getUrl();

        if (currentUrl.startsWith('/apex/interiosalesacknowledgement')) {
                interioSalesAckPageCheck = true;  
            }
            
            else{
                interioSalesAckPageCheck = false; 
            }
         //Ended by Shreela on 22nd Nov 2023 for SIEPB - 107       
            
         orderProducts=[Select OrderId,Order.Sales_type__c,Product2.Tax_Rate__c,Product2.Product_Category__c,Product2.Description,Product2.Colour__c,
                         Product2.Capacity__c,Old_Appliance_Colour__c,Old_Appliance_Model__c,Old_Appliance_Working__c,Product2.Item__c,
                         Old_Appliance_Capacity__c,Old_Appliance_Brand__c,Quantity,UnitPrice,Discount_Amount__c,CGST_Tax_Amount__c,
                         SGST_Tax_Amount__c,IGST_tax_Amount__c,Product2.Name,Total_Unit_Price__c,Age__c,Cabinet_Number__c,ListPrice,Total_Discount_Amount__c,
                         Business_unit__c,Line_Discount__c,Discounted_Basic_Total__c,Total_Discounted_Price_Per_Item__c, //Added Discount basic and price item discount by Sreekanth and Shreela for SFSSEB-15, SFSSEB-16 and SIEPB -107 respectively 
                         //Added by Shreela on 8th Nov 2023 for SIEPB - 107
                         Order.RecordType.DeveloperName,Total_tax_Amount__c,Order.Integration_Status__c,
                         Applied_Discount_Matrix_L2_Percentage__c,Applied_Discount_Matrix_L3_Percentage__c,
                         Applied_Discount_Matrix_L4_Percentage__c,Applied_Discount_Matrix_L5_Percentage__c,
                         Applied_Discount_Matrix_L6_Percentage__c,Applied_Discount_Matrix_L7_Percentage__c,
                         Applied_Discount_Matrix_L8_Percentage__c,Applied_Discount_Matrix_L9_Percentage__c,
                         Applied_Discount_Matrix_L10_Percentage__c,Applied_Discount_Matrix_L11_Percentage__c
                         //Ended by Shreela on 8th Nov 2023 for SIEPB - 107
                         From OrderItem
                         Where OrderId=:orderRecordId];
        orderItemVsTotalUnitAmount=new Map<Id,Decimal>();
        orderItemVsTotalAmount=new Map<Id,Decimal>();
        for(orderItem item:orderProducts){
           
            Integer quantitiy=item.Quantity!=null?(Integer)item.Quantity:0;
            Decimal taxRate =item.Product2.Tax_Rate__c;
            Decimal unitPrice=item.UnitPrice!=null?item.UnitPrice:0;
            Decimal totalUnitPrice=item.Business_unit__c == GlobalConstants.SSD_BUSINESS_UNIT?(item.ListPrice*item.Quantity):(item.Total_Unit_Price__c!=null?item.Total_Unit_Price__c:0); //SSD BU appended by Sreekanth Jujare
            //Decimal CGSTTaxAmt=item.CGST_Tax_Amount__c!=null?item.CGST_Tax_Amount__c:(item.Business_unit__c == GlobalConstants.SSD_BUSINESS_UNIT ? 0:(item.Total_Unit_Price__c-item.Total_Discount_Amount__c)*((item.Product2.Tax_Rate__c/100)/2)); //Formula modified by Sreekanth Jujare
            Decimal CGSTTaxAmt=item.CGST_Tax_Amount__c!=null?item.CGST_Tax_Amount__c:((item.Business_unit__c == GlobalConstants.SSD_BUSINESS_UNIT || (item.IGST_tax_Amount__c!=null && item.IGST_tax_Amount__c >0 && item.Order.Integration_Status__c == GlobalConstants.INTEGRATION_STATUS_SYNCED && interioSalesAckPageCheck && ((item.Order.RecordType.DeveloperName == GlobalConstants.INTERIO_B2C_VFD_PRIMARY) || (item.Order.RecordType.DeveloperName == GlobalConstants.INTERIO_B2C_KITCHEN) || (item.Order.RecordType.DeveloperName == GlobalConstants.INTERIO_B2C_SCRIPT)))) ? 0:(item.Total_Unit_Price__c-item.Total_Discount_Amount__c)*((item.Product2.Tax_Rate__c/100)/2)); //Formula modified by Sreekanth Jujare //Added by Shreela on 22nd Nov 2023 for SIEPB - 107
            Decimal IGSTTaxAmt=item.IGST_tax_Amount__c!=null?item.IGST_tax_Amount__c:0;
            //Decimal SGSTTaxAmt=item.SGST_Tax_Amount__c!=null?item.SGST_Tax_Amount__c:(item.Business_unit__c == GlobalConstants.SSD_BUSINESS_UNIT ? 0:(item.Total_Unit_Price__c-item.Total_Discount_Amount__c)*((item.Product2.Tax_Rate__c/100)/2));//Formula modified by Sreekanth Jujare
            Decimal SGSTTaxAmt=item.SGST_Tax_Amount__c!=null?item.SGST_Tax_Amount__c:((item.Business_unit__c == GlobalConstants.SSD_BUSINESS_UNIT  || (item.IGST_tax_Amount__c!=null && item.IGST_tax_Amount__c >0 && item.Order.Integration_Status__c == GlobalConstants.INTEGRATION_STATUS_SYNCED && interioSalesAckPageCheck && ((item.Order.RecordType.DeveloperName == GlobalConstants.INTERIO_B2C_VFD_PRIMARY) || (item.Order.RecordType.DeveloperName == GlobalConstants.INTERIO_B2C_KITCHEN) || (item.Order.RecordType.DeveloperName == GlobalConstants.INTERIO_B2C_SCRIPT))))? 0:(item.Total_Unit_Price__c-item.Total_Discount_Amount__c)*((item.Product2.Tax_Rate__c/100)/2));//Formula modified by Sreekanth Jujare //Added by Shreela on 22nd Nov 2023 for SIEPB - 107
            Decimal discountAmount=item.Total_Discount_Amount__c!=null?item.Total_Discount_Amount__c:0;           
            Decimal DiscAmountQty= item.Discount_Amount__c!=null?item.Discount_Amount__c*item.Quantity:0;//Changes done by Krishnareddy Gangula on 20/07/2023 for SIEPB-90
            Decimal totalUnitAmount=item.Business_unit__c == GlobalConstants.SSD_BUSINESS_UNIT?((item.ListPrice-item.Discount_Amount__c)+(CGSTTaxAmt/quantitiy)+(IGSTTaxAmt/quantitiy)+(SGSTTaxAmt/quantitiy)):(quantitiy>0?(unitPrice+(CGSTTaxAmt/quantitiy)+(IGSTTaxAmt/quantitiy)+(SGSTTaxAmt/quantitiy))-(discountAmount/quantitiy):0);//SSD BU appended by Sreekanth Jujare
            //Decimal totalAmount=item.Business_unit__c == GlobalConstants.SSD_BUSINESS_UNIT?totalUnitAmount*item.Quantity:(totalUnitPrice+CGSTTaxAmt+IGSTTaxAmt+SGSTTaxAmt)-discountAmount; //SSD BU appended by Sreekanth Jujare    //Commented by Shreela on 22nd Nov 2023       
            Decimal totalAmount=item.Business_unit__c == GlobalConstants.SSD_BUSINESS_UNIT?totalUnitAmount*item.Quantity:((((item.Order.RecordType.DeveloperName == GlobalConstants.INTERIO_B2C_VFD_PRIMARY) || (item.Order.RecordType.DeveloperName == GlobalConstants.INTERIO_B2C_KITCHEN) || (item.Order.RecordType.DeveloperName == GlobalConstants.INTERIO_B2C_SCRIPT))&& item.Order.Integration_Status__c == GlobalConstants.INTEGRATION_STATUS_SYNCED && interioSalesAckPageCheck)?(item.Total_Discounted_Price_Per_Item__c + item.Total_tax_Amount__c):((totalUnitPrice+CGSTTaxAmt+IGSTTaxAmt+SGSTTaxAmt)-discountAmount)); //SSD BU appended by Sreekanth Jujare //Modified by Shreela on 17th Nov 2023 for SIEPB - 107 // Modified By GUNA Ticket#30740849       
            Decimal totalDiscBasic=((item.Order.RecordType.DeveloperName == GlobalConstants.INTERIO_B2C_VFD_PRIMARY) || (item.Order.RecordType.DeveloperName == GlobalConstants.INTERIO_B2C_KITCHEN) || (item.Order.RecordType.DeveloperName == GlobalConstants.INTERIO_B2C_SCRIPT))?item.Total_Discounted_Price_Per_Item__c:0;//Added by Shreela on 10th Nov 2023 for SIEPB -107
            orderItemVsTotalUnitAmount.put(item.Id,totalUnitAmount);
            orderItemVsTotalAmount.put(item.Id,totalAmount);
            /*Shankar Sahu 18-1-2022
            Added below lines for 
            SRF 75 requirement-Sales acknowledgement for dealers
            */
            Decimal taxAmount=(totalUnitPrice-discountAmount)*(taxRate/100);
            Decimal totalAmountForDealer=(totalUnitPrice+taxAmount)-discountAmount;
            totalQuantity+=quantitiy; 
            totalIGSTAmount+=IGSTTaxAmt;
            totalSGSTAmount+=SGSTTaxAmt;
            totalCGSTAmount+=CGSTTaxAmt;
            finalTotalAmount+=totalAmount;
            totalDiscountAmount+=discountAmount;
            totalDiscAmountQty+=DiscAmountQty;
            totalBasicPrice+=totalUnitPrice;
            salestype= item.Order.Sales_type__c;
            totalDiscountedBasicPrice+=totalDiscBasic; //Added by Shreela on 10th Nov 2023 for SIEPB-107
            /*Shankar Sahu 18-1-2022
            Added below lines for 
            SRF 75 requirement-Sales acknowledgement for dealers
            */
            totalTaxAmount+=taxAmount;
            finalTotalAmountForDealerAck+=totalAmountForDealer;
            system.debug('Sales type>>'+salestype);
        }

    }

    public void getInternalSalesRepAcctAndName(Id accountId){
        List<Account> accts=[Select Account_code__c,Primary_Address__r.City__c,Primary_Address__r.State_Province__c,Primary_Address__r.House_Number__c,
                     Primary_Address__r.Building__c,Primary_Address__r.Floor__c,Primary_Address__r.Street__c,
                     Primary_Address__r.ZipCode__r.Name
                     From Account 
                     Where Id = :accountId];
        if(accts!=null && accts.size()>0){
            businessPartnerCode=accts[0].Account_code__c;
            String houseNo=accts[0].Primary_Address__r.House_Number__c!=null?accts[0].Primary_Address__r.House_Number__c+' ':'';
            String floor=accts[0].Primary_Address__r.Floor__c!=null?accts[0].Primary_Address__r.Floor__c+' ':'';
            String building=accts[0].Primary_Address__r.Building__c!=null?accts[0].Primary_Address__r.Building__c+' ':'';
            String street=accts[0].Primary_Address__r.Street__c!=null?accts[0].Primary_Address__r.Street__c+' ':'';
            String city=accts[0].Primary_Address__r.City__c!=null?accts[0].Primary_Address__r.City__c+' ':'';
            String state=accts[0].Primary_Address__r.State_Province__c!=null?accts[0].Primary_Address__r.State_Province__c+' ':'';
            String pincode='';
            if(accts[0].Primary_Address__r.ZipCode__c!=null)
                pincode=accts[0].Primary_Address__r.ZipCode__r.Name!=null?accts[0].Primary_Address__r.ZipCode__r.Name+' ':'';
            COCOStoreAddress=houseNo+floor+building+street+city+state+pincode;
        }
        List<String> FNLN=orderRec.Internal_Sales_Representative__r.Name!=null?(orderRec.Internal_Sales_Representative__r.Name).Split(' '):new List<String>();
        if(FNLN.size()==2){
            String lastNameInitial=FNLN[1].Split('')[0];
            internalSalesRepName=FNLN[0]+' '+lastNameInitial;
        }
        else if(FNLN.size()==1)
            internalSalesRepName=FNLN[0];
    }

    public void getShipToAndSoldToAddress(){
        if(orderRec.Ship_To_Address__c!=null && orderRec.Ship_To_Address__r.Address_Code__c!=null){
            String houseNo=orderRec.Ship_To_Address__r.Address_Code__r.House_Number__c!=null?orderRec.Ship_To_Address__r.Address_Code__r.House_Number__c+' ':'';
            String floor=orderRec.Ship_To_Address__r.Address_Code__r.Floor__c!=null?orderRec.Ship_To_Address__r.Address_Code__r.Floor__c+' ':'';
            String building=orderRec.Ship_To_Address__r.Address_Code__r.Building__c!=null?orderRec.Ship_To_Address__r.Address_Code__r.Building__c+' ':'';
            String street=orderRec.Ship_To_Address__r.Address_Code__r.Street__c!=null?orderRec.Ship_To_Address__r.Address_Code__r.Street__c+' ':'';
            String city=orderRec.Ship_To_Address__r.Address_Code__r.City__c!=null?orderRec.Ship_To_Address__r.Address_Code__r.City__c+' ':'';
            String state=orderRec.Ship_To_Address__r.Address_Code__r.State_Province__c!=null?orderRec.Ship_To_Address__r.Address_Code__r.State_Province__c+' ':'';
            String pincode='';
            if(orderRec.Ship_To_Address__r.Address_Code__r.ZipCode__c!=null)
                pincode=orderRec.Ship_To_Address__r.Address_Code__r.ZipCode__r.Name!=null?orderRec.Ship_To_Address__r.Address_Code__r.ZipCode__r.Name+' ':'';
            shipToAddress=houseNo+floor+building+street+city+state+pincode;
        }
        
        if(orderRec.Sold_To_Address__c!=null && orderRec.Sold_To_Address__r.Address_Code__c!=null){
            String houseNo1=orderRec.Sold_To_Address__r.Address_Code__r.House_Number__c!=null?orderRec.Sold_To_Address__r.Address_Code__r.House_Number__c+' ':'';
            String floor1=orderRec.Sold_To_Address__r.Address_Code__r.Floor__c!=null?orderRec.Sold_To_Address__r.Address_Code__r.Floor__c+' ':'';
            String building1=orderRec.Sold_To_Address__r.Address_Code__r.Building__c!=null?orderRec.Sold_To_Address__r.Address_Code__r.Building__c+' ':'';
            String street1=orderRec.Sold_To_Address__r.Address_Code__r.Street__c!=null?orderRec.Sold_To_Address__r.Address_Code__r.Street__c+' ':'';
            String city1=orderRec.Sold_To_Address__r.Address_Code__r.City__c!=null?orderRec.Sold_To_Address__r.Address_Code__r.City__c+' ':'';
            String state1=orderRec.Sold_To_Address__r.Address_Code__r.State_Province__c!=null?orderRec.Sold_To_Address__r.Address_Code__r.State_Province__c+' ':'';
            String pincode1='';
            if(orderRec.Sold_To_Address__r.Address_Code__r.ZipCode__c!=null)
              pincode1=orderRec.Sold_To_Address__r.Address_Code__r.ZipCode__r.Name!=null?orderRec.Sold_To_Address__r.Address_Code__r.ZipCode__r.Name+' ':'';
            soldToAddress=houseNo1+floor1+building1+street1+city1+state1+pincode1;
                    
        }
    }


    
}