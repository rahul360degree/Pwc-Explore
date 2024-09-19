@isTest
public class PedOrderRiskMatrixTest {
    @testSetup
    public static void createData(){  
        profile pedProfile = [Select Id, Name from Profile where Name ='PED Regional Head Sales Mktg' limit 1]; 
        User pedTBandUser = new User(EmailEncodingKey = 'UTF-8', firstName = 'tests', lastname = 'T Band User', Alias = 'tuser',
                                    languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = pedProfile.id,
                                    timezonesidkey = 'Asia/Kolkata', email = 'ped.TBandUser@godrej.com', username = 'ped.TBandUser@godrej.com', 
                                    Business_Unit__c = 'P',Persona__c = 'PED Head Sales - T Band',
                                    Logistic_Company__c = '1700');        
        insert pedTBandUser;
        
        System.runAs(pedTBandUser){            
            //Insert custom setting
            Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
            setting.FireQuoteValidationRules__c = false;
            setting.FireQLIValidationRules__c = false;
            setting.FireOpportunityValidationRules__c = false;
            setting.FireAccountValidationRules__c = false;
            setting.FireLeadValidationRules__c =false;
            insert setting;
            
            Account acc = new TestAccountBuilder()
                .setRecordTypeId(Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business_Account').getRecordTypeId())
                .setBusinessUnit('P')
                .getSavedTestRecord();
            
            Lead leadRecord=new TestLeadBuilder()
                .setBusinessUnit('P')            	
                .setProjectName('Test Project')
                .setPedRegion('DOMESTIC')
                .setPedSector('REFINERY')
                .setEndUser('NEW END USER')
                .setNameOfNewEndUser('Test User')
                .setEquipmentName('Test REACTOR')
                .setEquipmentType('REACTOR')
                .setProjectValue(2000)
                .setProjectValue(1000)
                .setRecordTypeId(Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('PED_Lead').getRecordTypeId())
                .getSavedTestRecord();
            
            Opportunity oppRecord = new TestOpportunityBuilder()
                .setAccountId(acc.Id)
                .setConvertedLeadId(leadRecord.Id)
                .setBusinessUnit('P')
                .setSalesBranchName('1700')
                .setEquipmentName('Test REACTOR')
                .setEquipmentType('REACTOR')
                .setStageName('In Process')
                .setCloseDate(system.today() + 1)
                .setProjectValue(2000)
                .setOpportunityValue(100)
                .setGeographicalLocation('Conducive')
                .setExportControlEndUseCertificate('YES')
                .setRecordTypeId(Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get(GlobalConstants.PED_BQ_OPPORTUNITY_RT).getRecordTypeId())
                .getSavedTestRecord();       
            
            Product2 product = new TestProductBuilder()
                .setItemCode('00001')
                .setProductCode('00001')
                .setIsActive(true)              
            	.setIsGeneric(true) 
                .getSavedTestRecord();  
            
            
            Id pricebookId = Test.getStandardPricebookId();
            PricebookEntry pbe = new TestPriceBookEntryBuilder()
                .setPricebook2Id(pricebookId)
                .setProduct2Id(product.Id)
                .getSavedTestRecord();
                        
            Quote quoteRecord = new TestQuoteBuilder()
                .setOpportunityId(oppRecord.id)
                .setExpectedDateOfDelivery(System.today()+30)
                .setRecordTypeId(Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get(GlobalConstants.PED_QUOTE_RT).getRecordTypeId())
                .setExpirationDate(System.today()+30)
                .setPricebook2Id(pricebookId)
                .setTechnicalOfferDesignCodes('TEMA')
                .setTechnicalOfferExclusions('Site work')
                .getSavedTestRecord();
        }
    }
        
    static testMethod void testPedQuotePdfController(){
        Test.startTest();
            Quote QuoteRec =[Select ID,Conversion_Rate__c,Currency__c FROM Quote LIMIT 1];
            User adminUser = [Select Id,LastName From User where LastName='T Band User' Limit 1];  
            List<QuoteLineItem> qliList=new List<QuoteLineItem>();
            System.runAs(adminUser){
                Order_Risk_Matrix__c ormRecord=PedOrderRiskMatrix.getOrderRiskMatrix(QuoteRec.Id); 
                Assert.areNotEqual(null, ormRecord, 'Order Risk Matrix record is null');
               	User usr=PedOrderRiskMatrix.getLoggedInUserDetails();
                PedOrderRiskMatrix.updateOrderRiskMatrixRecord(ormRecord,true);
                
                Order_Risk_Matrix__c ormRecord1=PedOrderRiskMatrix.getOrderRiskMatrix(QuoteRec.Id);
                Assert.areNotEqual(null, ormRecord1, 'Updated Order Risk Matrix record is null');
            }
        Test.stopTest();
    }
}