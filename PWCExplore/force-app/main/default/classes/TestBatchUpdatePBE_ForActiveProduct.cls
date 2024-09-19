@isTest
public class TestBatchUpdatePBE_ForActiveProduct {
    static testmethod void testQuotationControllerIf(){
        List<Product2> allProducts = new List<Product2> {new TestProductBuilder().setName('GX 300').setDescription('GX 300 Forklift').setItemCode('GX1').setComponentType('Base Product').setIsActive(true).getTestRecord()};
                    insert allProducts;
        
        List<PriceBookEntry> allPBEs = new List<PriceBookEntry> {new TestPriceBookEntryBuilder().setProduct2Id(allProducts[0].Id).setPricebook2Id(Test.getStandardPricebookId()).setUnitPrice(50000).setIsActive(false).getTestRecord()};
            allPBEs[0].Expiriy_Date__c = Date.today().addMonths(2);
            insert allPBEs;
        test.startTest();
        BatchUpdatePBE_ForActiveProduct obj = new BatchUpdatePBE_ForActiveProduct();
        Database.executeBatch(obj);
        
        BatchUpdatePBE_ForActiveProduct sh1 = new BatchUpdatePBE_ForActiveProduct();
		String sch = '0 0 23 * * ?'; 
        system.schedule('Test Job', sch, sh1); 
        
        
        test.stopTest();
    }
}