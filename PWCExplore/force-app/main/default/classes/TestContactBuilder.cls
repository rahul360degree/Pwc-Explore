/*------------------------------------------------------------------------------------
 * Author        :        Joshna
 * Company       :        Salesforce
 * Description   :        Test Builder for Contacts
 * History
 * --------
 * 27-07-2020      Joshna Palla     Initial Release
 * ----------------------------------------------------------------------------------*/
@isTest
public with sharing class TestContactBuilder {
    Contact contactInstance;

    public TestContactBuilder() {
        contactInstance = new Contact();
        // Set defaults for required fields here
        String randomKey = String.valueOf(Math.random() * 2).substring(0, 5);
        contactInstance.LastName = 'TestContact' + randomKey;
        contactInstance.FirstName = 'FirstName';
        contactInstance.Email = 'testContact' + randomKey + '@godrej.com';
    }

    public TestContactBuilder setAccountId(Id accountId) {
        contactInstance.AccountId = accountId;
        return this;
    }

    public TestContactBuilder setFirstName(String firstName) {
        contactInstance.FirstName = firstName;
        return this;
    }

    public TestContactBuilder setLastName(String lastName) {
        contactInstance.LastName = lastName;
        return this;
    }

    public TestContactBuilder setEmail(String email) {
        contactInstance.Email = email;
        return this;
    }

    public TestContactBuilder setReportsTo(Id reportsToId) {
        contactInstance.ReportsToId = reportsToId;
        return this;
    }

    public Contact getTestRecord() {
        return contactInstance;
    }

    public Contact getSavedTestRecord() {
        // Add errors for all required fields here
        if (String.isBlank(contactInstance.LastName)) {
            throw new TestDataException('Last Name is blank');
        }
        insert contactInstance;
        return contactInstance;
    }
}