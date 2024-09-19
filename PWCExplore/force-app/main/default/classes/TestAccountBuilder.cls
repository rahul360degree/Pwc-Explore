/*------------------------------------------------------------------------------------
 * Author        :        Joshna
 * Company       :        Salesforce
 * Description   :        Test Builder for Accounts
 * Inputs        :        
 * Test Class    :    
 * History
 * --------
 * 18-06-2020      Joshna Palla     Initial Release
 * ----------------------------------------------------------------------------------*/
@isTest
public with sharing class TestAccountBuilder {
    Account accountInstance;
    
    public TestAccountBuilder() {
        Address_Code_reserved_char__c orgInst = Address_Code_reserved_char__c.getOrgDefaults();
        if (orgInst == null || orgInst.Id == null) {
            orgInst = new Address_Code_reserved_char__c(SetupOwnerId=UserInfo.getOrganizationId(),
                B2B_character__c = 'A', B2C_character__c = 'A', B2B_Account_Series_Char__c = 'X');
            insert orgInst;
        }
        accountInstance = new Account(Type = 'D');
        // Set defaults for required fields here
        accountInstance.Name = 'Account for test class';
        //Added by Praful Gadge to resolve validation error - 21-10-2020
        accountInstance.PAN__c = 'AABBC11'+ String.valueOf(Math.random()).right(1) + String.valueOf(Math.random()).right(1) + 'Z';
    }
    
    public TestAccountBuilder(Boolean IsPersonAccount) {
        accountInstance = new Account();
        // Set defaults for required fields here
        if(!IsPersonAccount)
        accountInstance.Name = 'Account for test class';
    }


    public TestAccountBuilder setName(String name) {
        accountInstance.Name = name;
        return this;
    }
    
    public TestAccountBuilder setBusinessUnit(String bUnit) {
        accountInstance.Business_Unit__c = bUnit;
        return this;
    }
    
    public TestAccountBuilder setPrimaryAddress(Id primaryAddressId){
        accountInstance.Primary_Address__c = primaryAddressId;
        return this;
    }
    
    public TestAccountBuilder setRecordTypeId(Id recordTypeId) {
        accountInstance.RecordTypeId = recordTypeId;
        return this;
    }
    
    public TestAccountBuilder setPanNumber(String pan) {
        accountInstance.PAN__c = pan;
        return this;
    }
    

    public Account getTestRecord() {
        return accountInstance;
    }

    public Account getSavedTestRecord() {
        // Add errors for all required fields here
        if (String.isBlank(accountInstance.Name)) {
            throw new TestDataException('Account Name is Empty');
        }
        insert accountInstance;
        return accountInstance;
    }
    
  public TestAccountBuilder setIntegrationStatus(String integrationStatus) {
      accountInstance.Integration_Status__c = integrationStatus;
      return this;
  }
    
}