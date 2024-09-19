@isTest
public class ssdNsiAttachmentControllerTest {
    
    static testMethod void testConstructor() {
        Opportunity oppRecord=new TestOpportunityBuilder()
            .setRecordTypeId(Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Security_Solutions_B2B').getRecordTypeId())
            .setBusinessUnit('U')
            .getTestRecord();
        oppRecord.Order_Type__c = GlobalConstants.DIRECT_BILLING_TO_CUSTOMER;
        oppRecord.Booking_Option__c = 'Special Price';
        oppRecord.Customer_Type_SSD__c = 'BFSI';
        oppRecord.End_Customer_Segment_SSD__c = 'BNKPSU';
        oppRecord.Area_Code__c = 'WN1';
        oppRecord.Sales_Zone__c = 'EST';
        oppRecord.Region__c = 'WB_NE';
        oppRecord.Opportunity_Type__c = 'Std';
        insert oppRecord;
        
        NSI__c testNsi = new NSI__c(Requirement_Description__c = 'Test Data',Opportunity__c = oppRecord.Id);
        insert testNsi;
        
        ApexPages.StandardController stdController = new ApexPages.StandardController(testNsi);
        
        ssdNsiAttachmentController controller = new ssdNsiAttachmentController(stdController);
        
        System.assertEquals(testNsi.Id, controller.NsiId);
        System.assertEquals(testNsi.Id, controller.nsiData.Id);
    }
    
    static testMethod void testGetNsi() {
        
        Opportunity oppRecord=new TestOpportunityBuilder()
            .setRecordTypeId(Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Security_Solutions_B2B').getRecordTypeId())
            .setBusinessUnit('U')
            .getTestRecord();
        oppRecord.Order_Type__c = GlobalConstants.DIRECT_BILLING_TO_CUSTOMER;
        oppRecord.Booking_Option__c = 'Special Price';
        oppRecord.Customer_Type_SSD__c = 'BFSI';
        oppRecord.End_Customer_Segment_SSD__c = 'BNKPSU';
        oppRecord.Area_Code__c = 'WN1';
        oppRecord.Sales_Zone__c = 'EST';
        oppRecord.Region__c = 'WB_NE';
        oppRecord.Opportunity_Type__c = 'Std';
        insert oppRecord;
        
        NSI__c testNsi = new NSI__c(Requirement_Description__c = 'Test Data',Opportunity__c = oppRecord.Id);
        insert testNsi;
        
        ApexPages.StandardController stdController = new ApexPages.StandardController(testNsi);
        ssdNsiAttachmentController controller = new ssdNsiAttachmentController(stdController);
        NSI__c retrievedNsi = controller.getNsi(testNsi.Id);
        
        System.assertEquals(testNsi.Id, retrievedNsi.Id);
    }
}