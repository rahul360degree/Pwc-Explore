@isTest
public class SaveProductFieldDetailTest {
    @TestSetup static void createData(){
         Profile userProfile = [Select Id from Profile where Name = 'System Administrator' LIMIT 1];
        // Create User record.
        User userToRun = new User(EmailEncodingKey = 'UTF-8', firstName = 'Test', lastname = 'ConstructionMaterialUser', Alias = 'tuser',
                            languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = userProfile.id,
                            timezonesidkey = 'Asia/Kolkata', email = 'testN.user@godrej.com', username = 'test.user@godrej.com', Business_Unit__c = GlobalConstants.Construction_BUSINESS_UNIT);

       
        userToRun.Sub_Division__c = 'B2B';
        insert userToRun;
        
        
        System.runAs(userToRun) {
            Lead leadRecord = new TestLeadBuilder()
                .setRecordTypeId(Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Construction_Material').getRecordTypeId())
                .getSavedTestRecord();
            
            Opportunity oppRecord = new TestOpportunityBuilder()
                .setRecordTypeId(Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Construction_Materials').getRecordTypeId())
                .getSavedTestRecord();
            
            Quote quoteRecord = new TestQuoteBuilder()
                .setRecordTypeId(Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get('Construction_Materials').getRecordTypeId())
                .setOpportunityId(oppRecord.Id).getSavedTestRecord();
            
        }
     }
    @isTest private static void testSaveDetails() {
        // Create a Lead record with relevant fields
        //Test.startTest();
        Lead leadRecord = [select id from Lead];
            
        	leadRecord.LastName = 'ConUser';
            leadRecord.Estimated_Project_AAC_Qty_in_CBM__c = 10;
            leadRecord.Estimated_Project_Duroplast_Qty_Bag__c = 5;
        	leadRecord.Estimated_Project_EasyFix_Qty_Bag__c = 20;
            leadRecord.Est_Project_Solid_Concrete_Block_Nos__c = 27;
            leadRecord.Estimated_Project_Pavers_in_Sqm__c = 90;
            leadRecord.Estimated_Project_Curb_Stone_in_Nos__c = 36;
			leadRecord.Estimated_Project_Tilefix_Qty_Bag__c = 79; //added by poonam (SCF - 102)
       
        update leadRecord;
        
        String result = SaveProductFieldDetail.saveRecordDetails(leadRecord);
        System.assertEquals('SUCCESS', result);
        System.assertEquals(10, leadRecord.Estimated_Project_AAC_Qty_in_CBM__c);
        System.assertEquals(5, leadRecord.Estimated_Project_Duroplast_Qty_Bag__c);
        System.assertEquals(20, leadRecord.Estimated_Project_EasyFix_Qty_Bag__c);
        System.assertEquals(27, leadRecord.Est_Project_Solid_Concrete_Block_Nos__c);
        System.assertEquals(90, leadRecord.Estimated_Project_Pavers_in_Sqm__c);
        System.assertEquals(36, leadRecord.Estimated_Project_Curb_Stone_in_Nos__c);
        System.assertEquals(79, leadRecord.Estimated_Project_Tilefix_Qty_Bag__c); //added by poonam (SCF - 102)
        
        List<Boolean> defaultValues = SaveProductFieldDetail.getDefaultRecordValue(leadRecord);
        System.assertEquals(7, defaultValues.size());
        System.assertEquals(true, defaultValues[0]); 
        System.assertEquals(true, defaultValues[1]); 
        System.assertEquals(true, defaultValues[2]); 
        System.assertEquals(true, defaultValues[3]);
        System.assertEquals(true, defaultValues[4]); 
        System.assertEquals(true, defaultValues[5]);
        System.assertEquals(true, defaultValues[6]); 	//added by poonam (SCF - 102)
    }
        
        @isTest
    static void testSaveOpportunityDetails() {
        // Create an Opportunity record with relevant fields
        //Test.startTest();
        Opportunity oppRecord = [select id from Opportunity];
        
            oppRecord.Estimated_Project_AAC_Qty_in_CBM__c = 15;
            oppRecord.Estimated_Project_Duroplast_Qty_Bag__c = 8;
        	oppRecord.Estimated_Project_EasyFix_Qty_Bag__c = 22;
            oppRecord.Est_Project_Solid_Concrete_Block_Nos__c = 23;
            oppRecord.Estimated_Project_Pavers_in_Sqm__c = 10;
            oppRecord.Estimated_Project_Curb_Stone_in_Nos__c = 30;
        	oppRecord.Estimated_Project_Tilefix_Qty_Bag__c = 90;
            oppRecord.Name = 'testingopp';
            oppRecord.StageName = 'Qualification';
            oppRecord.CloseDate = System.today()+1;
           
        
        update oppRecord;
        
        String resultopp = SaveProductFieldDetail.saveRecordDetails(oppRecord);
        System.assertEquals('SUCCESS', resultopp);
        System.assertEquals(15, oppRecord.Estimated_Project_AAC_Qty_in_CBM__c);
        System.assertEquals(8, oppRecord.Estimated_Project_Duroplast_Qty_Bag__c);
        System.assertEquals(22, oppRecord.Estimated_Project_EasyFix_Qty_Bag__c);
        System.assertEquals(23, oppRecord.Est_Project_Solid_Concrete_Block_Nos__c);
        System.assertEquals(10, oppRecord.Estimated_Project_Pavers_in_Sqm__c);
        System.assertEquals(30, oppRecord.Estimated_Project_Curb_Stone_in_Nos__c);
        System.assertEquals(90, oppRecord.Estimated_Project_Tilefix_Qty_Bag__c);	//added by poonam (SCF - 102)
        
        List<Boolean> defaultValues = SaveProductFieldDetail.getDefaultRecordValue(oppRecord);
        System.assertEquals(7, defaultValues.size());
        System.assertEquals(true, defaultValues[0]); 
        System.assertEquals(true, defaultValues[1]); 
        System.assertEquals(true, defaultValues[2]); 
        System.assertEquals(true, defaultValues[3]); 
        System.assertEquals(true, defaultValues[4]);
        System.assertEquals(true, defaultValues[5]); 	
        System.assertEquals(true, defaultValues[6]);		//added by poonam (SCF - 102)
    }
        
       @isTest
    static void testSaveQuoteDetails() {
        
        Quote quoteRecord = [select id from Quote];
        
            quoteRecord.Estimated_Project_AAC_Qty_in_CBM__c = 20;
            quoteRecord.Estimated_Project_Duroplast_Qty_Bag__c = 12;
        	quoteRecord.Estimated_Project_EasyFix_Qty_Bag__c = 37;
            quoteRecord.Est_Project_Solid_Concrete_Block_Nos__c = 18;
            quoteRecord.Estimated_Project_Pavers_in_Sqm__c = 28;
            quoteRecord.Estimated_Project_Curb_Stone_in_Nos__c = 29;
        	quoteRecord.Estimated_Project_Tilefix_Qty_Bag__c = 89;		//added by poonam (SCF - 102)
         
        update quoteRecord;
        
        String resultq = SaveProductFieldDetail.saveRecordDetails(quoteRecord);
        System.assertEquals('SUCCESS', resultq);
        System.assertEquals(20, quoteRecord.Estimated_Project_AAC_Qty_in_CBM__c);
        System.assertEquals(12, quoteRecord.Estimated_Project_Duroplast_Qty_Bag__c);
        System.assertEquals(37, quoteRecord.Estimated_Project_EasyFix_Qty_Bag__c);
        System.assertEquals(18, quoteRecord.Est_Project_Solid_Concrete_Block_Nos__c);
        System.assertEquals(28, quoteRecord.Estimated_Project_Pavers_in_Sqm__c);
        System.assertEquals(29, quoteRecord.Estimated_Project_Curb_Stone_in_Nos__c);
        System.assertEquals(89, quoteRecord.Estimated_Project_Tilefix_Qty_Bag__c);		//added by poonam (SCF - 102)
        
        List<Boolean> defaultValues = SaveProductFieldDetail.getDefaultRecordValue(quoteRecord);
        System.assertEquals(7, defaultValues.size());
        System.assertEquals(true, defaultValues[0]); 
        System.assertEquals(true, defaultValues[1]); 
        System.assertEquals(true, defaultValues[2]); 
        System.assertEquals(true, defaultValues[3]); 
        System.assertEquals(true, defaultValues[4]); 
        System.assertEquals(true, defaultValues[5]); 
        System.assertEquals(true, defaultValues[6]); //added by poonam (SCF - 102)
    	}
    
}