@isTest
public with sharing class TestUserBuilder {
        
    User userInstance;
    public TestUserBuilder() {
        userInstance = new User();
        // Set defaults for required fields here
        String randomKey = String.valueOf(Math.random() * 2).substring(0, 5);
        userInstance.LastName = 'Test User' + randomKey;
        userInstance.Email = 'testUser' + randomKey + '@godrej.com';
        userInstance.UserName = 'testUser' + randomKey + '@godrej.com';
        userInstance.Alias = 'al' + randomKey;
        userInstance.EmailEncodingKey = 'UTF-8';
        userInstance.TimeZoneSidKey = 'Asia/Kolkata';
        userInstance.LocaleSidKey = 'en_IN';
        userInstance.LanguageLocaleKey = 'en_US';
    }
    
    public User getPartnerUser(){
        User UserwithRole;
        
        List<String> PortalType = new List<String> {'PowerPartner','CSPLiteUser','PowerCustomerSuccess','CustomerSuccess'};
            
        if(userWithRole == null) {  
            if(UserInfo.getUserRoleId() == null) {
                UserRole r = new UserRole(name = 'TEST ROLE');
                Database.insert(r);
                userWithRole = new User(Alias = 'hasrole', Email='userwithrole@godrej.com', userroleid = r.id,
                                    EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                                    LocaleSidKey='en_US', ProfileId = UserInfo.getProfileId(),
                                    TimeZoneSidKey='America/Los_Angeles',Username = 'test12345_gnbtest@godrej.com',CommunityNickname = 'test12345');
            } else {
                userWithRole = new User(Id = UserInfo.getUserId(), UserRoleId = UserInfo.getUserRoleId());
            }
            System.assert(userWithRole.userRoleId != null,
                          'This test requires the target org to have at least one UserRole created. Please create a user role in this organization and try again.');
        }
        
        Account a;
        Contact c;
        Contact b;
        
       
        System.runAs(userWithRole) {
            a = new Account(name = 'TEST ACCOUNT');
            Database.insert(a);
            b = new Contact(AccountId = a.id, lastname = 'lastname1');
            Database.insert(b);
            c = new Contact(AccountId = a.id, lastname = 'lastname',ReportstoId=b.id);
            Database.insert(c);
        }
        /* Get any profile for the given type.*/
        Profile p = [select id
                     from profile
                     where usertype = :portalType[0]
                     limit 1];  
        String testemail = 'tstuser234_gnbTest@gnbTest.com';
        User pu = new User(profileId = p.id, username = testemail, email = testemail,
                           emailencodingkey = 'UTF-8', localesidkey = 'en_US',
                           languagelocalekey = 'en_US', timezonesidkey = 'America/Los_Angeles',
                           alias='cspu', lastname='lastname', contactId = c.id);
        
        Database.insert(pu);
        return pu;
    }

    public TestUserBuilder setProfileId(Id profileId) {
        userInstance.ProfileId = profileId;
        return this;
    }

    public TestUserBuilder setContactId(Id contactId) {
        userInstance.ContactId = contactId;
        return this;
    }

    public TestUserBuilder setUserName(String userName) {
        userInstance.UserName = userName;
        return this;
    }

    public TestUserBuilder setAlias(String alias) {
        userInstance.Alias = alias;
        return this;
    }

    public TestUserBuilder setEmail(String Email) {
        userInstance.Email = Email;
        return this;
    }

    public TestUserBuilder setEmailEncodingKey(String emailEncodingKey) {
        userInstance.EmailEncodingKey = emailEncodingKey;
        return this;
    }

    public TestUserBuilder setLastName(String lastName) {
        userInstance.LastName = lastName;
        return this;
    }

    public TestUserBuilder setCommunityNickname(String communityNickname) {
        userInstance.CommunityNickname = communityNickname;
        return this;
    }

    public TestUserBuilder setTimeZoneSidKey(String timeZoneSidKey) {
        userInstance.TimeZoneSidKey = timeZoneSidKey;
        return this;
    }

    public TestUserBuilder setLocaleSidKey(String localeSidKey) {
        userInstance.LocaleSidKey = localeSidKey;
        return this;
    }

    public TestUserBuilder setLanguageLocaleKey(String languageLocaleKey) {
        userInstance.LanguageLocaleKey = languageLocaleKey;
        return this;
    }

    public TestUserBuilder setUserRoleId(Id userRoleId) {
        userInstance.UserRoleId = userRoleId;
        return this;
    }

    public TestUserBuilder setBusinessUnit(String businessUnit) {
        userInstance.Business_Unit__c = businessUnit;
        return this;
    }

    public TestUserBuilder setPersona(String persona) {
        userInstance.Persona__c = persona;
        return this;
    }
    
    public TestUserBuilder setSalaryCode(String salaryCode) {
        userInstance.Salary_Code__c = salaryCode;
        return this;
    }

    public TestUserBuilder setAllowBusinessAccountCreation(Boolean allowCreation) {
        userInstance.Allow_Business_Account_Creation__c = allowCreation;
        return this;
    }

    public TestUserBuilder setLogisticCompany(String company) {
        userInstance.Logistic_Company__c = company;
        return this;
    }

    public User getTestRecord() {
        return userInstance;
    }

    public User getSavedTestRecord() {
        // Add errors for all required fields here
        if (String.isBlank(userInstance.ProfileId)) {
            throw new TestDataException('Profile not set');
        }
        insert userInstance;
        return userInstance;
    }
}