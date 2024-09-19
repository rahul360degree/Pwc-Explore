/*------------------------------------------------------------------------------------
 * Author        :        Joshna
 * Company       :        Salesforce
 * Description   :        Test Builder for Opportunities
 * Inputs        :        
 * Test Class    :    
 * History
 * --------
 * 18-06-2020      Joshna Palla     Initial Release
 * ----------------------------------------------------------------------------------*/
@isTest
public with sharing class TestOpportunityBuilder {
    Opportunity opportunityInstance;

    public TestOpportunityBuilder() {
        opportunityInstance = new Opportunity();
        // Set defaults for required fields here
        opportunityInstance.Name = 'Opportunity for test class';
        opportunityInstance.StageName = 'Qualification';
        opportunityInstance.CloseDate = Date.today().addDays(30);
    }

    public TestOpportunityBuilder setName(String name) {
        opportunityInstance.Name = name;
        return this;
    }
    
    public TestOpportunityBuilder setAccountId(ID accountID) {
        opportunityInstance.AccountId = accountID;
        return this;
    }


    public TestOpportunityBuilder setStageName(String stageName) {
        opportunityInstance.StageName = stageName;
        return this;
    }

    public TestOpportunityBuilder setCloseDate(Date closeDate) {
        opportunityInstance.CloseDate = closeDate;
        return this;
    }

    public TestOpportunityBuilder setRecordTypeId(Id recordTypeId) {
        opportunityInstance.RecordTypeId = recordTypeId;
        return this;
    }

    public TestOpportunityBuilder setMHEDivision(String mheDivision) {
        opportunityInstance.MHE_Division__c = mheDivision;
        return this;
    }

    public TestOpportunityBuilder setBusinessUnit(String bUnit) {
        opportunityInstance.Business_Unit__c = bUnit;
        return this;
    }
    
    //Added by Sushant and Dipti on 12th Jan 2023
    public TestOpportunityBuilder setOEFStatus(String oefStatus) {
        opportunityInstance.OEF_Status__c = oefStatus;
        return this;
	}
    
     //Added by Sushant and Dipti on 12th Jan 2023
    public TestOpportunityBuilder setPONumber(String poNum) {
        opportunityInstance.PO_Number__c = poNum;
        return this;
    }
    
    //Added dipti 
    public TestOpportunityBuilder setPriceBookEntryId(Id priceBookEntryId) {
        opportunityInstance.Pricebook2Id = priceBookEntryId;
        return this;
    }
    
    public Opportunity getTestRecord() {
        return opportunityInstance;
    }

    public Opportunity getSavedTestRecord() {
        // Add errors for all required fields here
        if (String.isBlank(opportunityInstance.Name)) {
            throw new TestDataException('Opportunity Name is Empty');
        }
        if (String.isBlank(opportunityInstance.StageName)) {
            throw new TestDataException('Stage is blank');
        }
        if (opportunityInstance.CloseDate == null) {
            throw new TestDataException('Close Date is blank');
        }
        insert opportunityInstance;
        return opportunityInstance;
    }
    
    // Added new methods by rohit jadhav on 15th Sep 2023
    public TestOpportunityBuilder setConvertedLeadId(String convertedLeadId) {
        opportunityInstance.Converted_Lead__c = convertedLeadId;
        return this;
    }
    
    public TestOpportunityBuilder setSalesBranchName(String SalesBranchName) {
        opportunityInstance.Sales_Branch_Name__c = salesBranchName;
        return this;
    }
    
    public TestOpportunityBuilder setGeographicalLocation(String geographicalLocation) {
        opportunityInstance.Geographical_Location__c = geographicalLocation;
        return this;
    }
    
    public TestOpportunityBuilder setExportControlEndUseCertificate(String exportControlEndUseCertificate){
        opportunityInstance.Export_Control_End_Use_Certificate__c = exportControlEndUseCertificate;
        return this;
    } 
    
    public TestOpportunityBuilder setEndUser(String endUser) {
        opportunityInstance.End_User__c = endUser;
        return this;
    }       
    
    public TestOpportunityBuilder setNameOfNewEndUser(String nameOfNewEndUser) {
        opportunityInstance.Name_of_New_End_User__c = nameOfNewEndUser;
        return this;
    }
    
    public TestOpportunityBuilder setEquipmentName(String equipmentName) {
        opportunityInstance.Equipment_Name__c = equipmentName;
        return this;
    }
    
    public TestOpportunityBuilder setEquipmentType(String equipmentType) {
        opportunityInstance.EQUIPMENT_TYPE__c = equipmentType;
        return this;
    }
    
    public TestOpportunityBuilder setProjectValue(Decimal projectValue) {
        opportunityInstance.Project_Value__c = projectValue;
        return this;
    }
    
    public TestOpportunityBuilder setOpportunityValue(Decimal opportunityValue) {
        opportunityInstance.Opportunity_Value__c = opportunityValue;
        return this;
    }
}