@isTest
public class DiscountMatrixTriggerHandlerTest {
    
    static testMethod void createTestDataTrg() {
        
        Test.startTest();
        
        Discount_Matrix__c dm = new Discount_Matrix__c( 
            Name='No Discount', 
            Discount_Percent__c=0, 
            Discount_Amount__c=1,
            Gross_Net__c='2', 
            Level__c='3', 
            Stage__c='Active', 
            Start_Date__c=system.today(),
            Discount_Code__c='HDH'
        );
        insert dm;
        
        //get standart price book
        Pricebook2 standardPricebook = new Pricebook2(Id = Test.getStandardPricebookId(),IsActive = true,PriceList_Code__c='123',LN_PriceList_Code__c='456');
        Update standardPricebook;
        
        //insert product
        Product2 product = new Product2(Name = 'test product', Family = 'Mobile',Item__c='mob123',Is_Generic_Product__c=true);
        Insert product;
        
        List<Discount_Matrix__c> matrixList=new List<Discount_Matrix__c>();
        Discount_Matrix__c matrix=new Discount_Matrix__c();
        matrix.Name='Test Appliance Matrix';
        matrix.Discount_Code__c='HA9';
        matrix.Discount_Percent__c=8;
        matrix.Level__c='2';
        matrix.Start_Date__c=(date.today()).addDays(-5);
        matrix.End_Date__c=(date.today()).addDays(5);
        matrix.Stage__c='Active';
        matrix.Business_Unit__c='H';
        matrix.Matrix_Source__c='Salesforce';
        matrix.Type__c='Discount';
        matrix.Gross_Net__c='2';
        matrix.code__c = 'W56';
        matrix.Area__c ='EA2';
        matrix.price_list__c = Test.getStandardPricebookId();
        matrix.order_Currency__C = 'INR';
        matrixList.add(matrix);
        
        Discount_Matrix__c matrix1=new Discount_Matrix__c();
        matrix1.Name='Test Appliance Matrix';
        matrix1.Discount_Code__c='HA9';
        matrix1.Discount_amount__c=8000;
        matrix1.Level__c='3';
        matrix1.Start_Date__c=(date.today()).addDays(-5);
        matrix1.End_Date__c=(date.today()).addDays(5);
        matrix1.Stage__c='Active';
        matrix1.Business_Unit__c='H';
        matrix1.Matrix_Source__c='Infor';
        matrix1.Type__c='Discount';
        matrix1.Gross_Net__c='2';
        matrix1.code__c = 'W56';
        matrix1.Area__c ='EA1';
        matrix1.price_list__c = Test.getStandardPricebookId();
        matrix1.order_Currency__C = 'INR';
        matrixList.add(matrix1);
        
        Insert matrixList;
        matrixList=new List<Discount_Matrix__c>(); 
        
        Discount_Matrix__c matrix2=new Discount_Matrix__c();
        matrix2.Name='Test Appliance Matrix';
        matrix2.Discount_Amount__c=2000;
        matrix2.Level__c='2';
        matrix2.Discount_Code__c='HA9';
        matrix2.Start_Date__c=(date.today()).addDays(-5);
        matrix2.End_Date__c=(date.today()).addDays(5);
        matrix2.Stage__c='Active';
        matrix2.Business_Unit__c='H';
        matrix2.Matrix_Source__c='Infor';
        matrix2.Type__c='Discount';
        matrix2.Gross_Net__c='2';
        matrix2.code__c = 'W56';
        matrix2.Area__c ='EA2';
        matrix2.price_list__c = Test.getStandardPricebookId();
        matrix2.order_Currency__C = 'INR';
        matrixList.add(matrix2);
        
        matrix1=new Discount_Matrix__c();
        matrix1.Name='Test Appliance Matrix';
        matrix1.Discount_Code__c='HA9';
        matrix1.Discount_amount__c=8000;
        matrix1.Level__c='3';
        matrix1.Start_Date__c=(date.today()).addDays(-5);
        matrix1.End_Date__c=(date.today()).addDays(5);
        matrix1.Stage__c='Active';
        matrix1.Business_Unit__c='H';
        matrix1.Matrix_Source__c='Infor';
        matrix1.Type__c='Discount';
        matrix1.Gross_Net__c='2';
        matrix1.code__c = 'W56';
        matrix1.Area__c ='EA1';
        matrix1.price_list__c = Test.getStandardPricebookId();
        matrix1.order_Currency__C = 'INR';
        matrixList.add(matrix1);
        
        Insert matrixList;
        Test.stopTest();
    }
}