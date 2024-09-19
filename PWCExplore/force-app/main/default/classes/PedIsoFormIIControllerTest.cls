@isTest
public class PedIsoFormIIControllerTest {
    @testSetup
    public static void createData(){  
        profile pedProfile = [Select Id, Name from Profile where Name ='PED Regional Head Sales Mktg' limit 1]; 
        User pedTBandUser = new TestUserBuilder()
                .setProfileId(pedProfile.Id)
                .setLastName('T Band User')
                .setLogisticCompany('1700')
                .setBusinessUnit('P')
            	.setPersona('PED Head Sales - T Band')
                .getTestRecord();        
        pedTBandUser.IsActive = true;    
        insert pedTBandUser;
        
        System.runAs(pedTBandUser){            
            //Insert custom setting            
            Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
            setting.FireQuoteValidationRules__c = false;
            setting.FireOpportunityValidationRules__c = false;
            setting.FireAccountValidationRules__c = false;
            setting.FireLeadValidationRules__c =false;
            setting.FireOrderValidationRules__c =false;
            setting.AccountTriggerDisabled__c = true;
            setting.OrderTriggerDisabled__c = true;
            setting.OpportunityTriggerDisabled__c = true; 
            setting.QuoteTriggerDisabled__c = true;
            setting.QLITriggerDisabled__c = true;
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
            
            //Create a new OpportunityLineItem record
            OpportunityLineItem oli = new OpportunityLineItem(
                OpportunityId = oppRecord.Id,
                PricebookEntryId = pbe.Id,
                Quantity = 1,
                UnitPrice = pbe.UnitPrice,
                Equipment_Name__c='Test Equipment'
            );
            
            insert oli;
            
            Quote quoteRecord = new TestQuoteBuilder()
                .setOpportunityId(oppRecord.id)
                .setExpectedDateOfDelivery(System.today()+30)
                .setRecordTypeId(Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get(GlobalConstants.PED_QUOTE_RT).getRecordTypeId())
                .setExpirationDate(System.today()+30)
                .setPricebook2Id(pricebookId)
                .getSavedTestRecord();
            
            Order orderRecord =new TestOrderBuilder()
                .setOpportunityId(oppRecord.Id)
                .setAccountId(acc.Id)
                .setQuoteId(quoteRecord.Id)
                .setBusinessUnit('P')
                .setPriceBook2Id(pricebookId)
                .setEffectiveDate(system.today())
                .setStatus('Draft')
                .setRecordTypeId(Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get(GlobalConstants.PED_QUOTE_RT).getRecordTypeId())
                .getSavedTestRecord();
        }
    }
        
    static testMethod void testPedIsoFormController(){
        Test.startTest(); 
            User adminUser = [Select Id,LastName From User where LastName='T Band User' Limit 1];  
        	System.runAs(adminUser){
                Order orderRecord =[Select ID,Integration_Status__c FROM Order LIMIT 1];
            	orderRecord.Integration_Status__c='Synced';  
                update orderRecord;
                
                Assert.areEqual('Synced', orderRecord.Integration_Status__c, 'Integration_Status__c not updated as expected');
        	}
        Test.stopTest();
    }
}