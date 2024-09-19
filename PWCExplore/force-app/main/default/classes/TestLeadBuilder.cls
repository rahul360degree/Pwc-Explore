/*------------------------------------------------------------------------------------
 * Author        :        Joshna
 * Company       :        Salesforce
 * Description   :        Test Builder for Leads
 * History
 * --------
 * 27-07-2020      Joshna Palla     Initial Release
 * ----------------------------------------------------------------------------------*/
@isTest
public with sharing class TestLeadBuilder {
    Lead leadInstance;

    public TestLeadBuilder() {
        leadInstance = new Lead();
        String randomKey = String.valueOf(Math.random() * 2).substring(0, 5);
        leadInstance.LastName = 'LastName' + randomKey;
    }

    public TestLeadBuilder setRecordTypeId(Id recordTypeId) {
        leadInstance.RecordTypeId = recordTypeId;
        return this;
    }

    public TestLeadBuilder setLastName(String lastName) {
        leadInstance.LastName = lastName;
        return this;
    }

    public TestLeadBuilder setEmail(String email) {
        leadInstance.Email = email;
        return this;
    }

    public TestLeadBuilder setBusinessUnit(String businessUnit) {
        leadInstance.Business_Unit__c = businessUnit;
        return this;
    }
    
    public TestLeadBuilder setChannel(String channel) {
        leadInstance.Channel__c = channel;
        return this;
    }

    public TestLeadBuilder setKeyAccount(Boolean isKeyAccount) {
        leadInstance.Key_Account__c = isKeyAccount;
        return this;
    }

    public TestLeadBuilder setOwnerId(Id ownerId) {
        leadInstance.OwnerId = ownerId;
        return this;
    }
    
    //Added by Shreela on 1st Sept 2023 for SPEP - 14
    public TestLeadBuilder setLeadIncharge(Id leadIncharge) { //Modified this method by Shreela on 5th September 2023
        leadInstance.Lead_Incharge_GPE__c = leadIncharge;
        return this;
    }
    
    public TestLeadBuilder setPESSector(String pesSector) {
        leadInstance.PES_Sector__c = pesSector;
        return this;
    }
    
    public TestLeadBuilder setTitle(String title) {
        leadInstance.Title = title;
        return this;
    }
    
    public TestLeadBuilder setDescription(String description) {
        leadInstance.Description = description;
        return this;
    }
    
    public TestLeadBuilder setCompany(String company) {
        leadInstance.Company = company;
        return this;
    }
    public TestLeadBuilder setCustomerType(String customerType){			//Added by pc
        leadInstance.Customer_Type__c = customerType;
    	return this;
    }
    
    public TestLeadBuilder setStatus(String status) {
        leadInstance.Status = status;
        return this;
    }
    //Ended by Shreela on 1st Sept 2023 for SPEP - 14

    public Lead getTestRecord() {
        return leadInstance;
    }

    public Lead getSavedTestRecord() {
        // Add errors for all required fields here
        if (String.isBlank(leadInstance.LastName)) {
            throw new TestDataException('Last Name is blank');
        }
        insert leadInstance;
        return leadInstance;
    }
    
     // Added new methods by rohit jadhav on 15th Sep 2023
    public TestLeadBuilder setProjectName(String projectName) {
        leadInstance.Project_Name__c = projectName;
        return this;
    }
    
    public TestLeadBuilder setPedRegion(String pedRegion) {
        leadInstance.PED_Region__c = pedRegion;
        return this;
    }
    
    public TestLeadBuilder setPedSector(String pedSector) {
        leadInstance.PED_Sector__c = pedSector;
        return this;
    }
    
    public TestLeadBuilder setEndUser(String endUser) {
        leadInstance.End_User__c = endUser;
        return this;
    }   
    
    
    public TestLeadBuilder setNameOfNewEndUser(String nameOfNewEndUser) {
        leadInstance.Name_of_New_End_User__c = nameOfNewEndUser;
        return this;
    }
    
    public TestLeadBuilder setEquipmentName(String equipmentName) {
        leadInstance.Equipment_Name__c = equipmentName;
        return this;
    }
    
    public TestLeadBuilder setEquipmentType(String equipmentType) {
        leadInstance.EQUIPMENT_TYPE__c = equipmentType;
        return this;
    }
    
    public TestLeadBuilder setProjectValue(Decimal projectValue) {
        leadInstance.Project_Value__c = projectValue;
        return this;
    }
    
    public TestLeadBuilder setOpportunityValue(Decimal opportunityValue) {
        leadInstance.Opportunity_Value__c = opportunityValue;
        return this;
    }   
}