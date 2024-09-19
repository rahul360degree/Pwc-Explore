/**
* @description       : 
* @author            : vrajpoot@godrej.com
* @group             : 
* @last modified on  : 02-07-2023
* @last modified by  : vrajpoot@godrej.com
**/
@isTest
public class PurchaseOrderController_Test {
    @testSetup
    public static void getData(){
        Profile appliancesProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator-Appliances'];
        User appliancesUser = new TestUserBuilder().setProfileId(appliancesProfile.Id)
            .setBusinessUnit('H').setSalaryCode('25345').getSavedTestRecord();
        System.debug(appliancesUser.Id);
        //System.runAs(appliancesUser){
        
        Discount_Matrix__c dm = new Discount_Matrix__c( 
            Name='No Discount', 
            Discount_Percent__c=0, 
            Discount_Amount__c=1,
            Gross_Net__c='1', 
            Level__c='3', 
            Stage__c='Active', 
            Start_Date__c=system.today(),
            Discount_Code__c='HDH'
        );
        insert dm;
        Product2 prod = new TestProductBuilder().setItemCode('52141501SD02232').getSavedTestRecord();
        prod.Product_Storage_Clasification__c = 'Category A';
        prod.Is_generic_Product__c = true;
        update prod;
        
        PriceBookEntry entry = new TestPriceBookEntryBuilder().setPricebook2Id(Test.getStandardPricebookId()).setProduct2Id(prod.Id).getSavedTestRecord();
        
        Account accountRecord = new TestAccountBuilder()
            .setRecordTypeId(Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Dealer').getRecordTypeId())
            .setBusinessUnit('K').getSavedTestRecord();
        List<Order> orders = new List<Order>();
        /*
Runtime_Execution__c cst = new Runtime_Execution__c();
cst.OrderTriggerDisabled__c = false;
insert cst;
*/
        Address__c addr = createPrimaryAddress();
        addr.Building__c = 'Solitaire';
        insert addr;  
        Address_by_BP__c abp = new Address_by_BP__c();
        abp.Account__c = accountRecord.Id;
        abp.Sold_To__c = true;
        abp.Ship_To__c = true; 
        abp.Address_Code__c = addr.Id;
        abp.RecordTypeId = (RecordTypeUtils.getInstance()).getRecordTypeId('Address_by_BP__c', 'B2B_Additional_Address');
        AddressByBPTriggerHandler.TriggerDisabled = true;
        insert abp;                 
        
        
        Order so = new TestOrderBuilder().setAccountId(accountRecord.Id)
            .setRecordTypeId(Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('MHE_Order_Secondary').getRecordTypeId())
            .setBusinessUnit('K').setPriceBook2Id(Test.getStandardPricebookId())
            .setShipToAddress(abp.Id).setSoldToAddress(abp.Id)
            .getTestRecord(); //Changed Business unit from H to K by Shreela on 11th October 2022 fro resolving test class error
        so.intent__c = 'true';
        so.Sales_Type__c = 'Secondary';
        so.Area__c = 'SV1';
        so.sub_division__c = 'B2B';
        so.MHE_Division__c = 'Spare Parts';
        so.Sold_to_Business_Partner__c = accountRecord.Id;
        orders.add(so);
        Order po = new TestOrderBuilder().setAccountId(accountRecord.Id)
            .setRecordTypeId(Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('MHE_Order_Primary').getRecordTypeId())
            .setBusinessUnit('K').setPriceBook2Id(Test.getStandardPricebookId()).getTestRecord();   //Changed Business unit from H to K by Shreela on 11th October 2022 fro resolving test class error
        po.intent__c = 'true';
        po.Sales_Type__c = 'Primary';
        
        po.Area__c = 'SV1';
        po.MHE_Division__c = 'Spare Parts';
        po.sub_division__c = 'B2B';
        orders.add(po);
        insert orders;
        
        
        
        List<OrderItem> ois = new List<OrderItem>();
        OrderItem oitem = new OrderItem(Orderid = so.Id, PricebookEntryId = entry.id, Quantity = 1,UnitPrice = 1000);
        ois.add(oitem);
        /*
OrderItem oitem2 = new OrderItem(Orderid = po.Id, PricebookEntryId = entry.id, Quantity = 1,UnitPrice = 5000,Discount_Amount__c = 10);
ois.add(oitem2);
*/
        insert ois;
        Purchase_Order__c purchesOrder = new Purchase_Order__c();
        purchesOrder.Order__c = so.Id;
        purchesOrder.Item_Code__c = '552266'; 
        purchesOrder.Address_Code__c = 'MH';
        purchesOrder.Quantity__c = '20';
        purchesOrder.Purchase_Price__c = '20000';
        purchesOrder.Business_Partner_Code__c = '23654125';
        purchesOrder.Integration_Status__c='Synced';
        purchesOrder.OwnerId= userInfo.getUserId();
        purchesOrder.Order_Product__c = ois[0].Id;
        insert purchesOrder; 
        
        
        
        /*
Address__c addr = createPrimaryAddress();
addr.Building__c = 'Solitaire';
insert addr;  

Account acc = new TestAccountBuilder()
.setRecordTypeId(Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Dealer').getRecordTypeId())
.setPrimaryAddress(addr.id)
.setBusinessUnit('H')
.getSavedTestRecord();      

Address_by_BP__c abp = new Address_by_BP__c();
abp.Account__c = acc.Id;
abp.Sold_To__c = true;
abp.Ship_To__c = true; 
abp.Address_Code__c = addr.Id;
abp.RecordTypeId = (RecordTypeUtils.getInstance()).getRecordTypeId('Address_by_BP__c', 'B2B_Additional_Address');
AddressByBPTriggerHandler.TriggerDisabled = true;
insert abp;                 

Order order = new TestOrderBuilder().setAccountId(acc.Id)
.setRecordTypeId(Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('Appliance_Primary').getRecordTypeId())
.setBusinessUnit('H')
.setShipToAddress(abp.Id)
.setStatus('Draft')
.setEffectiveDate(date.today())
.setPriceBook2Id(Test.getStandardPricebookId())
.setOrderReferenceNumberExt('')
.getTestRecord();
order.Sales_Type__c = GlobalConstants.SALES_TYPE_PRIMARY;        
order.Is_Create_Demo_Installation_Request__c = true;
order.Sales_Price_List__c = Test.getStandardPricebookId();
order.Area__c ='EA2';                        
order.order_currency__c = 'INR';
order.Sold_to_Business_Partner__c =acc.Id;               
Insert order; 

Product2 prod = new TestProductBuilder().setItemCode('H').setItemCode('52141501SD02232')
.setProductCode(System.Label.Construction_SO_from_SF_to_LN ).getSavedTestRecord();
PriceBookEntry entry = new TestPriceBookEntryBuilder().setPricebook2Id(Test.getStandardPricebookId()).setProduct2Id(prod.Id).setUnitPrice(1000).getSavedTestRecord();



Discount_Matrix__c dm = new Discount_Matrix__c( 
Name='No Discount', 
Discount_Percent__c=0, 
Discount_Amount__c=1,
Gross_Net__c='1', 
Level__c='3', 
Stage__c='Active', 
Start_Date__c=system.today(),
Discount_Code__c='HDH'
);
OrderItem oitem = new OrderItem(OrderId = order.Id, PricebookEntryId = entry.id, Quantity = 1,UnitPrice = 1000);
insert oitem;
System.debug('Test::::');
System.debug([Select Id,Product2.Item__c from OrderItem where id=:oitem.Id]);
System.debug([Select Id,Product2.Item__c from OrderItem where id=:oitem.Id].Product2.Item__c);


Purchase_Order__c purchesOrder = new Purchase_Order__c();
purchesOrder.Order__c = order.Id;
purchesOrder.Item_Code__c = '552266'; 
purchesOrder.Address_Code__c = 'MH';
purchesOrder.Quantity__c = '20';
purchesOrder.Purchase_Price__c = '20000';
purchesOrder.Business_Partner_Code__c = '23654125';
purchesOrder.Integration_Status__c='Synced';
purchesOrder.OwnerId= userInfo.getUserId();
purchesOrder.Order_Product__c = oitem.Id;
insert purchesOrder; 


Tax_Number__c taxPAN = new Tax_Number__c();
taxPAN.Business_Partner__c = acc.Id;
taxPAN.Country__c = 'IND';
taxPAN.Tax_Number__c = 'AASCS6585A';
taxPAN.Category__c = 'PAN';
taxPAN.Un_registered__c = 'No';
taxPAN.Tax_Number_Ext__c = 'WDX001015___PAN_AASCS6585A';
insert taxPAN;

Tax_Number__c taxGST = new Tax_Number__c();
taxGST.Business_Partner__c = acc.Id;
taxGST.Country__c = 'IND';
taxGST.State_Province_Name__c = 'IND_MH'; 
taxGST.Tax_Number__c = '23AASCS6585A23D';
taxGST.Category__c = 'GSTIN';
taxGST.Un_registered__c = 'No';
taxGST.Tax_Number_Ext__c = 'WDX001015___PAN_AASCS6585A';
taxGST.Effective_Date__c = date.today(); 
insert taxGST;   

ContentVersion contentVersion = new ContentVersion();
contentVersion.Title = 'demo';
contentVersion.PathOnClient = 'demo.pdf';
contentVersion.versionData = Blob.valueOf('Test Content');
contentVersion.IsMajorVersion = true;
insert contentVersion;

Id conDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:contentVersion.Id].ContentDocumentId;

ContentDocumentLink contentDocumentLinks = new ContentDocumentLink();
contentDocumentLinks.ContentDocumentId = conDocId;
contentDocumentLinks.LinkedEntityId = acc.id;
contentDocumentLinks.ShareType = 'V';
contentDocumentLinks.Visibility = 'AllUsers';
insert contentDocumentLinks;*/
        // }
    }
    
    private static Address__c createPrimaryAddress(){
        ZipCode__c zipcd = new ZipCode__c(City_Name__c ='citytst', StateName__c = 'sttetst', name='zpcdtst');
        insert zipcd;
        Address__c addr = new Address__c(Street__c='strttst',ZipCode__c = zipcd.id,Name__c='Account for test class');
        return addr;
    }
    
    @isTest
    public static void Method(){        
        User user = [SELECT Id FROM User WHERE Salary_Code__c = '25345'];
        System.runAs(user){
            Purchase_Order__c purchesOrder = [select Id,Order__r.AccountId from Purchase_Order__c limit 1];        
            Test.startTest();
            ApexPages.StandardController standardController = new ApexPages.StandardController(purchesOrder);
            PurchaseOrderController poController = new PurchaseOrderController(standardController);
    		
            List<Id> lstId = new List<Id>();
            lstId.add([Select Id from Purchase_Order__c limit 1].Id);   
            List<ContentVersion> createPOPDF = PurchaseOrderController.createPOPDF(lstId);
            System.assertEquals(1, createPOPDF.size());
            Test.stopTest(); 
        }
    }
    
    
}