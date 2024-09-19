/**
 * @Description       : 
 * @Author            : Varun Rajpoot
 * @last modified on  : 01-23-2024
 * @last modified by  : Varun Rajpoot 
 * Modifications Log
 * Ver   Date         Author          Modification
 * 1.0   01-23-2024   Varun Rajpoot   Initial Version
**/
@isTest
public class CaseTriggerHandlerTest {
    
    @TestSetup static void setupUser() {
        Runtime_Execution__c runTimeExecution = new Runtime_Execution__c();
        
        Profile userProfile = [Select Id from Profile where Name =: GlobalConstants.SYSTEM_ADMIN_PROFILE_NAME LIMIT 1];
        UserRole role = [SELECT Id, Name, DeveloperName FROM UserRole WHERE DeveloperName = 'CEO' LIMIT 1];
        // Create User record.
        User userToRun = new User(EmailEncodingKey = 'UTF-8', firstName = 'Test', lastname = 'User', Alias = 'tuser',
                            languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = userProfile.id, UserRoleId = role.Id,
                            timezonesidkey = 'Asia/Kolkata', email = 'test.userAcc@godrej.com', username = 'test.userAcc@godrej.com', Business_Unit__c = 'W');

        userToRun.IsActive = true;
        userToRun.Allow_Business_Account_Creation__c = true;
        userToRun.Logistic_Company__c = '2000';
        userToRun.Area_Code__c = 'NH1';
        insert userToRun;
        
        //Create 2nd user
        User user2 = userToRun.clone(false);
        user2.Persona__c = GlobalConstants.MHE_GODREJ_BRANCH_CHAMPION;
        user2.username = 'test.userAcc2@godrej.com';
        insert user2;
        
        UserRole mheCSGRole = [SELECT Id, Name, DeveloperName FROM UserRole WHERE DeveloperName = 'MHE_Service_CSG_HO' LIMIT 1];
        
        User user3 = userToRun.clone(false);
        user3.UserRoleId = mheCSGRole.id;
        user3.Username = 'ad.userAcc@godrej.com';
        insert user3;       
        
        System.runAs(userToRun){
            //Create Custom Setting Record for RunTime Execution
             runTimeExecution = new Runtime_Execution__c(Name = 'CaseAssignmentTest', FireCaseValidationRules__c = true);
            insert runTimeExecution;
            
            Account newAccount = new Account();
            newAccount.Name = 'Test Business Account';
            newAccount.Business_Unit__c ='K';
            newAccount.Sub_Division__c = 'B2B';
            newAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business_Account').getRecordTypeId();
            insert newAccount;
        }
        
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(thisUser){
            
            Account accountRecord = new Account();
            accountRecord.Name = 'Test Business Account2';
            accountRecord.Business_Unit__c ='K';
            accountRecord.Sub_Division__c = 'B2B';
            accountRecord.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Dealer').getRecordTypeId();
            accountRecord.Type = 'D';
            accountRecord.Account_Series__c = System.Label.Parent_Account_Series;
            accountRecord.Business_Partner_Type__c = 'COC';
            insert accountRecord;
            
            
            
            Profile profileId = [SELECT Id FROM Profile WHERE Name = 'Interio B2C VFD COCO Team User' LIMIT 1];

            UserRole ur = new UserRole(Name = 'Interio VFD COCO Store MUM Chief 2');
            insert ur;

            User userWithRole = new User(UserRoleId = ur.Id, ProfileId = profileId.Id, Account__c = accountRecord.id, 
                                        Alias = 'hasrole', Email='userwithrole@godrej.com',
                                        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',LocaleSidKey='en_US',
                                        TimeZoneSidKey='America/Los_Angeles',Username = 'test12345_gnbtest@godrej.com',CommunityNickname = 'test12345',
                                        Logistic_Company__c='5010',Business_Unit__c='W',Sub_Division__c='B2C',Interio_Sub_Division__c='VFD',Persona__c='InterioVFD- COCO Store Team',Salary_Code__c='377990',Business_Partner_Code__c='WWC000021'); 
            insert UserWithRole;
        }
          UserRole iaUserRole = new UserRole(Name = 'CEO');
          insert iaUserRole;
          Profile iaProfile = [SELECT Id FROM Profile WHERE Name = 'Integration Administrator' LIMIT 1];
          User ssg_user = new User(UserRoleId = iaUserRole.Id, ProfileId = iaProfile.Id, 
                                               Alias = 'ssg', Email='ssgUser@godrej.com',Salary_Code__c='377337',Business_Unit__c='G',
                                               EmailEncodingKey='UTF-8', LastName='Testing_ssg', LanguageLocaleKey='en_US',LocaleSidKey='en_US',
                                               TimeZoneSidKey='America/Los_Angeles',Username = 'ssgUser@godrej.com',CommunityNickname = 'test1234567');
                
        insert ssg_user;
        User chandigarh_user = new User(UserRoleId = iaUserRole.Id, ProfileId = iaProfile.Id, 
                                 Alias = 'ssg', Email='chtest@godrej.com',Business_Unit__c='G',
                                 EmailEncodingKey='UTF-8', LastName='chtest', LanguageLocaleKey='en_US',LocaleSidKey='en_US',
                                 TimeZoneSidKey='America/Los_Angeles',Username = 'chtest@godrej.com',CommunityNickname = 'chtest');
        User user = [Select Id,isActive from User where Salary_Code__c = '383182'];
        if(user <> null && !user.isActive){
            chandigarh_user.isActive = true;
            chandigarh_user.id = user.Id;
            update chandigarh_user;
        }else{
        	chandigarh_user.Salary_Code__c = '383182';    
            insert chandigarh_user;
        }
        /*
        
        insert new List<User>{ssg_user,chandigarh_user}; */
         
        
        
    }

    @isTest private static void caseShareTest(){
        Test.startTest();
        User iaUser = [Select id, Account__c from User WHERE username = 'test12345_gnbtest@godrej.com'];
        
        System.runAs(iaUser){
            Case newCase = new Case(
                Status = 'New', Priority = 'Medium', Case_Category__c = 'Customer Complaint',
                Type = 'Product Quality Issue', Mobile__c = '9000009000', Email__c = 'test@invalid.com',
                Origin = 'Web',Alternate_Contact_s_Name__c = 'Test',Installation_Scope__c= 'Dealer'
            );

            insert newCase;
        }
        List<Case> caseRec = [Select Id,AccountId FROM Case LIMIT 1];
        System.assertEquals(iaUser.Account__c, String.valueOf(caseRec[0].AccountId));
        Test.stopTest();
    }

    @isTest private static void accountMissingErrorTest(){
        Test.startTest();
        User iaUser = [Select id, Account__c from User WHERE username = 'test12345_gnbtest@godrej.com'];
        iaUser.Account__c = null;
        update iaUser;

        System.runAs(iaUser){
            Case newCase = new Case(
                Status = 'New', Priority = 'Medium', Case_Category__c = 'Customer Complaint',
                Type = 'Product Quality Issue', Mobile__c = '9000009000', Email__c = 'test@invalid.com',
                Origin = 'Web'
            );
            try{
                insert newCase;
            }Catch(Exception ex){
                System.assertEquals(true,ex.getMessage().contains(System.Label.ACCOUNT_MUST_BE_SELECTED));
            }
        }
        
        Test.stopTest();
    }

    @isTest private static void caseUpdateTest(){
        Test.startTest();
        User iaUser = [Select id, Account__c from User WHERE username = 'test12345_gnbtest@godrej.com'];
        
        System.runAs(iaUser){
            Case newCase = new Case(
                Status = 'New', Priority = 'Medium', Case_Category__c = 'Customer Complaint',
                Type = 'Product Quality Issue', Mobile__c = '9000009000', Email__c = 'test@invalid.com',Alternate_Contact_s_Name__c = 'Test',
                Origin = 'Web',OwnerId = UserInfo.getUserId());

            insert newCase;
            newCase.OwnerId = iaUser.Id;
            update newCase;
        }
        List<Case> caseRec = [Select Id,AccountId,OwnerId FROM Case LIMIT 1];
        System.assertEquals(iaUser.Id,caseRec[0].OwnerId);
        Test.stopTest();
    }
    
    
    @isTest private static void webOriginCaseAssignmentTest() {
        Test.startTest();
        User contextuser = [Select Id FROM User WHERE username = 'test.userAcc@godrej.com' LIMIT 1];
        System.runAs(contextuser) {
            
            //Fetch Queue Id for Email/Web channels
            Id mheQueueId = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperNAME =: GlobalConstants.MHE_EMAIL_WEB_QUEUE].Id;
        
            list<Account> accounts = [SELECT Id FROM Account WHERE Name = 'Test Business Account' LIMIT 1];
            
            Case caseRecord = new Case();
            caseRecord.AccountId = accounts[0].Id;
            caseRecord.Origin = 'Web';
            caseRecord.Status = 'New';
            caseRecord.Priority = 'Medium';
            caseRecord.Case_Category__c = 'Customer Complaint';
            caseRecord.SuppliedEmail = 'test@invalid.com';
            caseRecord.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('MHE_Service_Request').getRecordTypeId();
            
            insert caseRecord;
            
            List<Case> caseRec = [Select Id, OwnerId FROM Case WHERE Id=: caseRecord.Id LIMIT 1];
            System.assertEquals(mheQueueId, caseRec[0].OwnerId);
            Test.stopTest();
        }
    }
    
    @isTest private static void offloadedContractCaseAssignmentTest() {
        Test.startTest();
        User contextuser = [Select Id FROM User WHERE username = 'test.userAcc@godrej.com' LIMIT 1];
        System.runAs(contextuser) {
            
            Id p = [SELECT id FROM profile WHERE name='Partner Community User'].id;
            
            Account ac = new Account(name ='Grazitti') ;
            ac.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Dealer').getRecordTypeId();
            insert ac; 
       
            Contact con = new Contact(LastName ='testCon',AccountId = ac.Id, MobilePhone = '9876543211', Phone= '9876543210', Role__c = GlobalConstants.CONTACT_ROLE_SUPERVISOR);
            insert con;  
                  
            User user = new User(alias = 'test123', email='test123@noemail.com',
                emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
                localesidkey='en_US', profileid = p, country='United States',IsActive =true,
                ContactId = con.Id, Logistic_Company__c = '5010', Area_Code__c = 'NH1',
                timezonesidkey='America/Los_Angeles', username='teste1234094r@noemail.com');
       
            insert user;
            
            list<Account> accounts = [SELECT Id FROM Account WHERE Name = 'Test Business Account2' LIMIT 1];
            
            //Create Zip Code record
            ZipCode__c zipCode = new ZipCode__c();
            zipCode.Name = '410002';
            zipCode.CityCode__c = 'PUNE';
            zipCode.City_Name__c = 'PUNE';
            zipCode.StateCode__c = 'MH';
            zipCode.StateName__c = 'Maharashtra';
            zipCode.CountryCode__c = 'IN';   
            zipCode.CountryName__c = 'INDIA';   
            zipCode.ZipCodeExternalId__c = 'IN_410002';
            
            insert zipCode;

            //Create Address Record							
            Address__c address = new Address__c();
            address.Address_Type__c = 'B2B';
            address.Address_Format__c = 'ADR';
            address.Name__c = 'Nuvoco Plant Pune';
            address.Telephone__c = '8765432111';
            address.Email__c = 'punetest1234@nuvoco.com';
            address.ZipCode__c = zipCode.Id;
            address.Building__c = 'Avenues';
            address.Street2__c = '1st Street';
            insert address;
			
            //Insert Asset record
            Asset newAsset = new Asset();
            newAsset.Name= 'Asset 1';
            newAsset.AccountId = accounts[0].id;
            newAsset.Status = 'Unregistered';
            newAsset.Primary_Dealer__c = ac.Id;
            newAsset.Branch__c = '5010';
            newAsset.Area_Code__c = 'NH1';
            newAsset.Type_of_Warranty__c = 'Std Warranty';
            newAsset.Address_Code__c = address.Id;
            newAsset.Product_Purchased_Warranty_Start_Date__c = System.now();
            newAsset.Product_Purchased_Warranty_End_Date__c = Date.today().addDays(5);
            newAsset.Product_Family__c = 'Equipment';
            newAsset.Product_Category__c = 'Warehousing';
            newAsset.Product_Sub_Category__c = 'Stacker';
            newAsset.Equipment_Category__c = 'WE';
            AssetTriggerHandler.TriggerDisabled = true;
            insert newAsset;
            AssetTriggerHandler.TriggerDisabled = false;

            newAsset.Status = 'Active';
            newAsset.Date_of_Commissioning__c = System.today().addDays(-9);
            AssetTriggerHandler.TriggerDisabled = true;
            update newAsset;
            AssetTriggerHandler.TriggerDisabled = false;
            
            //Create Case Record
            Case caseRecord = new Case();
            caseRecord.AccountId = accounts[0].Id;
            caseRecord.AssetId = newAsset.Id;
            caseRecord.Origin = 'Manual';
            caseRecord.Status = 'New';
            caseRecord.Priority = 'Medium';
            caseRecord.Case_Category__c = 'Customer Complaint';
            caseRecord.Email__c = 'abc@invalid.com';
            caseRecord.Mobile__c = '9890908989';
            caseRecord.Alternate_Contact_s_Name__c = 'Alternate Contact';
            caseRecord.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('MHE_Service_Request').getRecordTypeId();
            caseRecord.Asset_Location__c = 'Pune';
            //Test.startTest();
            insert caseRecord;
            
            List<Case> caseRec = [Select Id, OwnerId FROM Case WHERE Id=: caseRecord.Id LIMIT 1];
            System.assertEquals(user.Id, caseRec[0].OwnerId);
        }
            Test.stopTest();
        
    }
    
    @isTest private static void internalTechnicianCaseAssignmentTest() {
        User contextuser = [Select Id FROM User WHERE username = 'test.userAcc@godrej.com' LIMIT 1];
        System.runAs(contextuser) {
            Test.startTest();
            
            list<Account> accounts = [SELECT Id FROM Account WHERE Name = 'Test Business Account' LIMIT 1];
            
            //Create Zip Code record
            ZipCode__c zipCode = new ZipCode__c();
            zipCode.Name = '410002';
            zipCode.CityCode__c = 'PUNE';
            zipCode.City_Name__c = 'PUNE';
            zipCode.StateCode__c = 'MH';
            zipCode.StateName__c = 'Maharashtra';
            zipCode.CountryCode__c = 'IN';   
            zipCode.CountryName__c = 'INDIA';   
            zipCode.ZipCodeExternalId__c = 'IN_410002';
            
            insert zipCode;
            
            //Create Address Record
            Address__c address = new Address__c();
            address.Address_Type__c = 'B2B';
            address.Address_Format__c = 'ADR';
            address.Name__c = 'Nuvoco Plant Pune';
            address.Telephone__c = '8765432111';
            address.Email__c = 'punetest1234@nuvoco.com';
            address.ZipCode__c = zipCode.Id;
            address.Building__c = 'Avenues';
            address.Street2__c = '1st Street';
            insert address;
			
            //Insert Asset record
            Asset newAsset = new Asset();
            newAsset.Name= 'Asset 1';
            newAsset.AccountId = accounts[0].id;
            newAsset.RecordTypeId = Schema.SObjectType.Asset.getRecordTypeInfosByDeveloperName().get('MHE_Asset').getRecordTypeId();
            newAsset.Status = 'Unregistered';
            newAsset.Product_Family__c = 'Equipment';
            newAsset.Product_Category__c = 'Counterbalanced Diesel';
            newAsset.Product_Sub_Category__c = 'Light Diesel';
            newAsset.Equipment_Category__c = 'CB-D';
            newAsset.Type_of_Warranty__c = 'Std Warranty';
            newAsset.Address_Code__c = address.Id;
            newAsset.Area_Code__c = 'NH1';
            newAsset.Product_Purchased_Warranty_Start_Date__c = System.now();
            newAsset.Product_Purchased_Warranty_End_Date__c = Date.today().addDays(5);
            AssetTriggerHandler.TriggerDisabled = true;
            insert newAsset;
            AssetTriggerHandler.TriggerDisabled = false;
            
            newAsset.Status = 'Active';
            newAsset.Date_of_Commissioning__c = System.today().addDays(-9);
            AssetTriggerHandler.TriggerDisabled = true;
            update newAsset;
            AssetTriggerHandler.TriggerDisabled = false;
            
            //Create Case record
            Case caseRecord = new Case();
            caseRecord.AccountId = accounts[0].Id;
            caseRecord.AssetId = newAsset.Id;
            caseRecord.Origin = 'Manual';
            caseRecord.Status = 'New';
            caseRecord.Priority = 'Medium';
            caseRecord.Case_Category__c = 'Customer Complaint';
            caseRecord.Email__c = 'abc@invalid.com';
            caseRecord.Mobile__c = '9890908989';
            caseRecord.Asset_Location__c = 'Pune';
            caseRecord.Alternate_Contact_s_Name__c = 'Test';
            caseRecord.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('MHE_Service_Request').getRecordTypeId();
            
            insert caseRecord;
            
            List<Case> caseRec = [Select Id, OwnerId FROM Case WHERE Id=: caseRecord.Id LIMIT 1];
            System.assert(caseRec[0].OwnerId != null);
            Test.stopTest();
        }
    }
    
    @isTest private static void zipCodeBasedCaseAssignmentTest() {
        User contextuser = [Select Id FROM User WHERE username = 'test.userAcc@godrej.com' LIMIT 1];
        System.runAs(contextuser) {
            //Zip code Rule
            Group caseGrp = new Group(Name='Test Case Group Q1', type='Queue');
            insert caseGrp;
            
            QueuesObject caseQ = new QueueSObject(QueueID = caseGrp.id, SobjectType = 'Case');
            insert caseQ;
            
            //Fetch case Group details
            list<Group> caseGroups = [SELECT Id, Name, DeveloperName, Type FROM Group Where Type = 'Queue' AND Name LIKE 'Test Case Group Q%'];
            
            //Create Zip Code record
            ZipCode__c zipCode = new ZipCode__c();
            zipCode.Name = '410002';
            zipCode.CityCode__c = 'PUNE';
            zipCode.City_Name__c = 'PUNE';
            zipCode.StateCode__c = 'MH';
            zipCode.StateName__c = 'Maharashtra';
            zipCode.CountryCode__c = 'IN';   
            zipCode.CountryName__c = 'INDIA';   
            zipCode.ZipCodeExternalId__c = 'IN_410002';
            
            insert zipCode;
            
            //Insert Zip code rule record
            Zip_Code_Rule__c rule = new Zip_Code_Rule__c();
            rule.name = 'K-B2B-410002';
            rule.Queue_1__c = caseGroups[0].DeveloperName;
            rule.Effective_Till__c = Date.today().addDays(100);
            rule.Run_Round_Robin_on_Queue1__c = false;
            rule.Queues_And_LastAssignedId__c = '{}';
            rule.Object_Name__c = 'Case';
            
            insert rule;
            
            //Fetch Queue Id for Email/Web channels
            Id mheQueueId = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperNAME =: GlobalConstants.MHE_EMAIL_WEB_QUEUE].Id;
        
            list<Account> accounts = [SELECT Id FROM Account WHERE Name = 'Test Business Account' LIMIT 1];
            
            //Create Address Record
            Address__c address = new Address__c();
            address.Address_Type__c = 'B2B';
            address.Address_Format__c = 'ADR';
            address.Name__c = 'Nuvoco Plant Pune';
            address.Telephone__c = '8765432111';
            address.Email__c = 'punetest1234@nuvoco.com';
            address.ZipCode__c = zipCode.Id;
            address.Building__c = 'Avenues';
            address.Street2__c = '1st Street';
            insert address;
     
            //Insert Asset record
            Asset newAsset = new Asset();
            newAsset.Name= 'Asset 1';
            newAsset.AccountId = accounts[0].id;
            newAsset.RecordTypeId = Schema.SObjectType.Asset.getRecordTypeInfosByDeveloperName().get('MHE_Asset').getRecordTypeId();
            newAsset.Status = 'Unregistered';
            newAsset.Product_Family__c = 'Equipment';
            newAsset.Product_Category__c = 'Counterbalanced Diesel';
            newAsset.Product_Sub_Category__c = 'Light Diesel';
            newAsset.Equipment_Category__c = 'CB-D';
            newAsset.Address_Code__c = address.Id;
            newAsset.Type_of_Warranty__c = 'Std Warranty';
            newAsset.Product_Purchased_Warranty_Start_Date__c = System.now();
            newAsset.Product_Purchased_Warranty_End_Date__c = Date.today().addDays(5);
            insert newAsset;
            
            newAsset.Status = 'Active';
            newAsset.Date_of_Commissioning__c = System.today().addDays(-9);
            update newAsset;
            
            //Create Case record
            Case caseRecord = new Case();
            caseRecord.AccountId = accounts[0].Id;
            caseRecord.AssetId = newAsset.Id;
            caseRecord.Origin = 'Manual';
            caseRecord.Status = 'New';
            caseRecord.Priority = 'Medium';
            caseRecord.Case_Category__c = 'Customer Complaint';
            caseRecord.Email__c = 'abc@invalid.com';
            caseRecord.Mobile__c = '9890908989';
            caseRecord.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('MHE_Service_Request').getRecordTypeId();
            caseRecord.Asset_Location__c = 'Pune';
            caseRecord.Alternate_Contact_s_Name__c = 'Test';
            
            Test.startTest();
            insert caseRecord;
            
            List<Case> caseRec = [Select Id, OwnerId FROM Case WHERE Id=: caseRecord.Id LIMIT 1];
            System.assertEquals(caseGroups[0].Id, caseRec[0].OwnerId);
            Test.stopTest();
        }
    }
    
    @isTest private static void addBranchChampionToCaseTeamTest() {
        User contextuser = [Select Id FROM User WHERE username = 'test.userAcc@godrej.com' LIMIT 1];
        System.runAs(contextuser) {
            Test.startTest();
            User userRec = [SELECT Id FROM User WHERE Persona__c =: GlobalConstants.MHE_GODREJ_BRANCH_CHAMPION LIMIT 1];
            
            list<Account> accounts = [SELECT Id FROM Account WHERE Name = 'Test Business Account' LIMIT 1];
            
            //Create Zip Code record
            ZipCode__c zipCode = new ZipCode__c();
            zipCode.Name = '410002';
            zipCode.CityCode__c = 'PUNE';
            zipCode.City_Name__c = 'PUNE';
            zipCode.StateCode__c = 'MH';
            zipCode.StateName__c = 'Maharashtra';
            zipCode.CountryCode__c = 'IN';   
            zipCode.CountryName__c = 'INDIA';   
            zipCode.ZipCodeExternalId__c = 'IN_410002';
            
            insert zipCode;

            //Create Address Record
            Address__c address = new Address__c();
            address.Address_Type__c = 'B2B';
            address.Address_Format__c = 'ADR';
            address.Name__c = 'Nuvoco Plant Pune';
            address.Telephone__c = '8765432111';
            address.Email__c = 'punetest1234@nuvoco.com';
            address.ZipCode__c = zipCode.Id;
            address.Building__c = 'Avenues';
            address.Street2__c = '1st Street';
            insert address;
			
            //Insert Asset record
            Asset newAsset = new Asset();
            newAsset.Name= 'Asset 1';
            newAsset.AccountId = accounts[0].id;
            newAsset.RecordTypeId = Schema.SObjectType.Asset.getRecordTypeInfosByDeveloperName().get('MHE_Asset').getRecordTypeId();
            newAsset.Status = 'Unregistered';
            newAsset.Product_Family__c = 'Equipment';
            newAsset.Product_Category__c = 'Counterbalanced Diesel';
            newAsset.Product_Sub_Category__c = 'Light Diesel';
            newAsset.Equipment_Category__c = 'CB-D';
            newAsset.Type_of_Warranty__c = 'Std Warranty';
            newAsset.Address_Code__c = address.Id;
            newAsset.Product_Purchased_Warranty_Start_Date__c = System.now();
            newAsset.Product_Purchased_Warranty_End_Date__c = Date.today().addDays(5);
            AssetTriggerHandler.TriggerDisabled = true;
            insert newAsset;
            AssetTriggerHandler.TriggerDisabled = false;
            
            newAsset.Status = 'Active';
            newAsset.Date_of_Commissioning__c = System.today().addDays(-9);
            AssetTriggerHandler.TriggerDisabled = true;
            update newAsset;
            AssetTriggerHandler.TriggerDisabled = false;
            
            //Create case record
            Case caseRecord = new Case();
            caseRecord.AccountId = accounts[0].Id;
            caseRecord.Assetid = newAsset.Id;
            caseRecord.OwnerId = contextuser.Id;
            caseRecord.Origin = 'Manual';
            caseRecord.Status = 'New';
            caseRecord.Priority = 'Medium';
            caseRecord.Case_Category__c = 'Customer Complaint';
            caseRecord.Email__c = 'abc@invalid.com';
            caseRecord.Mobile__c = '9890908989';
            caseRecord.Asset_Location__c = 'Pune';
            caseRecord.Alternate_Contact_s_Name__c = 'Test';
            caseRecord.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('MHE_Service_Request').getRecordTypeId();            
            insert caseRecord;
            
            //Change Owner of case
            caseRecord.OwnerId = userRec.Id;
            update caseRecord;
            
            List<CaseTeamMember> caseTeamMembers = [Select Id FROM CaseTeamMember WHERE ParentId=: caseRecord.Id  AND MemberId =: userRec.Id LIMIT 1];
            System.assertEquals(true, caseTeamMembers.size() > 0);				//Commented by pc
            
            Test.stopTest();
        }
    }
    
    @isTest private static void updateAssetEnrollmentStatusTest() {
        
        User contextuser = [Select Id FROM User WHERE username = 'ad.userAcc@godrej.com' LIMIT 1];
        
        System.runAs(contextuser) {
			//Create Address Record
			Address__c address = new Address__c();
            address.Address_Type__c = 'B2B';
            address.Address_Format__c = 'ADR';
            address.Name__c = 'Nuvoco Plant Pune';
            address.Telephone__c = '8765432111';
            address.Email__c = 'punetest1234@nuvoco.com';
            //address.ZipCode__c = zipCode.Id;
            address.Building__c = 'Avenues';
            address.Street2__c = '1st Street';
            insert address;
            Test.startTest();
            Account accRec = [SELECT Id FROM Account WHERE Name = 'Test Business Account' LIMIT 1];
  
            Asset newAsset = new Asset();
            newAsset.Name= 'Asset 1';
            newAsset.AccountId = accRec.id;
            newAsset.RecordTypeId = Schema.SObjectType.Asset.getRecordTypeInfosByDeveloperName().get('MHE_Asset').getRecordTypeId();
            newAsset.Status = 'Unregistered';
            newAsset.Product_Family__c = 'Equipment';
            newAsset.Product_Category__c = 'Counterbalanced Diesel';
            newAsset.Product_Sub_Category__c = 'Light Diesel';
            newAsset.Equipment_Category__c = 'CB-D';
            newAsset.Type_of_Warranty__c = 'Std Warranty';
            newAsset.Address_Code__c = address.Id;
            newAsset.Product_Purchased_Warranty_Start_Date__c = System.now();
            newAsset.Product_Purchased_Warranty_End_Date__c = Date.today().addDays(5);
            AssetTriggerHandler.TriggerDisabled = true;
            insert newAsset;
            AssetTriggerHandler.TriggerDisabled = false;
            
            Case caseRecord = new Case();
            caseRecord.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('MHE_Service_Request').getRecordTypeId();
            caseRecord.AccountId = accRec.id;
            caseRecord.Assetid = newAsset.Id;
            caseRecord.Origin = 'Manual';
            caseRecord.Status = 'New';
            caseRecord.Priority = 'Medium';
            caseRecord.Case_Category__c = 'Customer Complaint';
            caseRecord.Email__c = 'abc@invalid.com';
            caseRecord.Mobile__c = '9890908989';
            caseRecord.Alternate_Contact_s_Name__c = 'Test';
            caseRecord.Asset_Location__c = 'Pune';
            caseRecord.Type = 'Asset Enrollment';  
            caseRecord.Approval_Status__c = 'Approved';
            caseRecord.Call_Pending_Reason__c = 'Spares Not Available';
            
            insert caseRecord;
            
            
            caseRecord.Call_Pending_Reason__c = '';
            caseRecord.Status = 'Closed';
            update caseRecord;
            
            
            Asset assetRecord = [SELECT Id, Enrollment_Status__c FROM Asset WHERE Name = 'Asset 1' LIMIT 1];
            
            System.assertEquals('Approved', assetRecord.Enrollment_Status__c);
            Test.stopTest();
        }
    }
    
    @isTest private static void validateCaseStatusTest() {
        	//Create Address Record							//Added by pc
            Address__c address = new Address__c();
            address.Address_Type__c = 'B2B';
            address.Address_Format__c = 'ADR';
            address.Name__c = 'Nuvoco Plant Pune';
            address.Telephone__c = '8765432111';
            address.Email__c = 'punetest1234@nuvoco.com';
            address.Building__c = 'Avenues';
            address.Street2__c = '1st Street';
       		 address.Street__c = '2nd street';
            insert address;
            Account accRec = [SELECT Id FROM Account WHERE Name = 'Test Business Account' LIMIT 1];
            
            Asset newAsset = new Asset();
            newAsset.Name= 'Asset 1';
            newAsset.AccountId = accRec.id;
            newAsset.RecordTypeId = Schema.SObjectType.Asset.getRecordTypeInfosByDeveloperName().get('MHE_Asset').getRecordTypeId();
            newAsset.Status = 'Unregistered';
            newAsset.Product_Family__c = 'Equipment';
            newAsset.Product_Category__c = 'Counterbalanced Diesel';
            newAsset.Product_Sub_Category__c = 'Light Diesel';
            newAsset.Equipment_Category__c = 'CB-D';
            newAsset.Type_of_Warranty__c = 'Std Warranty';
            newAsset.Address_Code__c = address.Id;		//Added by pc
            newAsset.Product_Purchased_Warranty_Start_Date__c = System.now();
            newAsset.Product_Purchased_Warranty_End_Date__c = Date.today().addDays(5);
            AssetTriggerHandler.TriggerDisabled = true;
            insert newAsset;
            AssetTriggerHandler.TriggerDisabled = false;
            
            Case caseRecord = new Case();
            caseRecord.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('MHE_Service_Request').getRecordTypeId();
            caseRecord.AccountId = accRec.id;
            caseRecord.Assetid = newAsset.Id;
            caseRecord.Origin = 'Manual';
            caseRecord.Status = 'Registerd';
            caseRecord.Priority = 'Medium';
            caseRecord.Case_Category__c = 'Customer Complaint';
            caseRecord.Email__c = 'abc@invalid.com';
            caseRecord.Mobile__c = '9890908989';
            caseRecord.Alternate_Contact_s_Name__c = 'Test';
            caseRecord.Asset_Location__c = 'Pune';
            caseRecord.Type = 'Asset Enrollment';  
            caseRecord.Approval_Status__c = 'Approved';
            caseRecord.Call_Pending_Reason__c = 'Vendor dependency';  
        
            insert caseRecord;
            
            caseRecord.Call_Pending_Reason__c = '';
            caseRecord.Status = 'New';
            Test.startTest();    
            try{
                CaseFieldPopulator caseField = new CaseFieldPopulator();
                caseField.getDependentPicklistValuesMethod('Delhi');
                caseField.getDependentPicklistValuesMethod('Chandigarh');
                caseField.getDependentPicklistValuesMethod('Kolkata');
                caseField.getDependentPicklistValuesMethod('Mumbai');
                caseField.getDependentPicklistValuesMethod('Pune');
                caseField.getDependentPicklistValuesMethod('Ahmedabad');
                caseField.getDependentPicklistValuesMethod('Chennai');
                caseField.getDependentPicklistValuesMethod('Bangalore');
                caseField.getDependentPicklistValuesMethod('Hyderabad');
                caseField.getDependentPicklistValuesMethod('MENA');
                caseField.getDependentPicklistValuesMethod('Noida');
                
                update caseRecord;
                
                }catch(Exception ex){
                    System.assert(ex.getMessage().contains('Please select valid status as backtracking is not allowed'));
                }
            Test.stopTest();
    }
    //Added by pankaj for for Design_clearance milestone should not get created code in casefieldpopulator which is create milestone method  
       @isTest private static void validateCaseInstallationScopeIsDealerTest() {
            Test.startTest();
         
           User ssg_user = [SELECT Id,username FROM User WHERE username = 'ssgUser@godrej.com' LIMIT 1];
                System.runAs(ssg_user){
                    Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
                    setting.AccountTriggerDisabled__c = true;
                    setting.OrderTriggerDisabled__c = true;
                    setting.CaseTriggerDisabled__c = false;
                    insert setting;
                    //Creating Account for SSG
                    Account newAccount_ssg = new Account( Name = 'Test Account', Business_Unit__c = 'G', Type = 'I',
                                                RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business_Account').getRecordTypeId());
                    insert newAccount_ssg;
                    Account accountRecord_ssgsid = new TestAccountBuilder()
                        .setRecordTypeId(Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business_Account').getRecordTypeId())
                        .getSavedTestRecord();
                    accountRecord_ssgsid.Business_Unit__c = 'G';
                    update accountRecord_ssgsid;
                    //Creating order for SSG
                    Order newOrder_ssg = new Order( Logistics_Company_Branch__c = '1300',                  
                                                Line_of_Business__c = 'ENGG',                               
                                                Business_Unit__c = 'G', Sub_Division__c = 'B2B',                                                
                                                Internal_Sales_Representative__c = ssg_user.id,Design_clearance_required__c='No',
                                                AccountId = accountRecord_ssgsid.Id,EffectiveDate = System.today(),Status = 'Draft',
                                                RecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('SSG_Primary').getRecordTypeId());
                    insert newOrder_ssg;  
                
            Case caseRecord = new Case();
            caseRecord.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('SSG_Service_Request').getRecordTypeId();
            caseRecord.AccountId = accountRecord_ssgsid.Id;
            caseRecord.No_material_Supply__c = 'Yes';
            caseRecord.Origin = 'Manual';
             caseRecord.Execution_Branch__c ='Chandigarh';
            caseRecord.Status = 'Registerd';
            caseRecord.Priority = 'Medium';
            caseRecord.Case_Category__c = 'Customer Complaint';
            caseRecord.Email__c = 'abc@invalid.com';
            caseRecord.Mobile__c = '9890908989';
            caseRecord.Alternate_Contact_s_Name__c = 'Test';
            caseRecord.Asset_Location__c = 'Pune';
            caseRecord.Type = 'Asset Enrollment';  
            caseRecord.Approval_Status__c = 'Approved';
            caseRecord.Call_Pending_Reason__c = 'Vendor dependency';  
          caseRecord.installation_scope__c = 'Dealer';
             caseRecord.Order__c = newOrder_ssg.id;
            insert caseRecord;
            
            Test.stopTest();
            system.assertEquals('Dealer',caseRecord.installation_scope__c);//gcp22
                }
       }
    //Added by pankaj for for Design_clearance milestone should not get created code in casefieldpopulator which is create milestone method  
       @isTest private static void validateCaseInstallationScopeIsGodrejTest() {
            Test.startTest();
         
           User ssg_user = [SELECT Id,username FROM User WHERE username = 'ssgUser@godrej.com' LIMIT 1];
                System.runAs(ssg_user){
                    Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
                    setting.AccountTriggerDisabled__c = true;
                    setting.OrderTriggerDisabled__c = true;
                    setting.CaseTriggerDisabled__c = false;
                    insert setting;
                    //Creating Account for SSG
                    Account newAccount_ssg = new Account( Name = 'Test Account', Business_Unit__c = 'G', Type = 'I',
                                                RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business_Account').getRecordTypeId());
                    insert newAccount_ssg;
                    Account accountRecord_ssgsid = new TestAccountBuilder()
                        .setRecordTypeId(Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business_Account').getRecordTypeId())
                        .getSavedTestRecord();
                    accountRecord_ssgsid.Business_Unit__c = 'G';
                    update accountRecord_ssgsid;
                    //Creating order for SSG
                    Order newOrder_ssg = new Order( Logistics_Company_Branch__c = '1300',                  
                                                Line_of_Business__c = 'ENGG',                               
                                                Business_Unit__c = 'G', Sub_Division__c = 'B2B',                                                
                                                Internal_Sales_Representative__c = ssg_user.id,Design_clearance_required__c='No',
                                                AccountId = accountRecord_ssgsid.Id,EffectiveDate = System.today(),Status = 'Draft',
                                                RecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('SSG_Primary').getRecordTypeId());
                    insert newOrder_ssg;  
                
            Case caseRecord = new Case();
            caseRecord.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('SSG_Service_Request').getRecordTypeId();
            caseRecord.AccountId = accountRecord_ssgsid.Id;
            caseRecord.No_material_Supply__c = 'No';
            caseRecord.Origin = 'Manual';
             caseRecord.Execution_Branch__c='Chandigarh';
            caseRecord.Status = 'Registerd';
            caseRecord.Priority = 'Medium';
            caseRecord.Case_Category__c = 'Customer Complaint';
            caseRecord.Email__c = 'abc@invalid.com';
            caseRecord.Mobile__c = '9890908989';
            caseRecord.Alternate_Contact_s_Name__c = 'Test';
            caseRecord.Asset_Location__c = 'Pune';
            caseRecord.Type = 'Asset Enrollment';  
            caseRecord.Approval_Status__c = 'Approved';
            caseRecord.Call_Pending_Reason__c = 'Vendor dependency';  
          caseRecord.installation_scope__c = 'Godrej';
             caseRecord.Order__c = newOrder_ssg.id;
            insert caseRecord;
            
            Test.stopTest();
            system.assertEquals('Godrej',caseRecord.installation_scope__c);//gcp22
                    
                }
       }

   //Added by Shreela on 14th May 2023 for SMEPB -95 to cover LOC in validateCaseChange method of cfp class
    @isTest private static void testvalidateCaseChange(){
        Test.startTest();
        
        User mhe_user = [SELECT Id,username FROM User WHERE username = 'test.userAcc2@godrej.com' LIMIT 1];
        System.runAs(mhe_user){
        Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
        setting.AccountTriggerDisabled__c=true;
        setting.ContactTriggerDisabled__c=true;
        setting.UserTriggerDisabled__c=true;
        setting.AssetTriggerDisabled__c=true;
        insert setting;
		
        //Create Address Record						//Added by pc
            Address__c address = new Address__c();
            address.Address_Type__c = 'B2B';
            address.Address_Format__c = 'ADR';
            address.Name__c = 'Nuvoco Plant Pune';
            address.Telephone__c = '8765432111';
            address.Email__c = 'punetest1234@nuvoco.com';
            address.Building__c = 'Avenues';
            address.Street2__c = '1st Street';
            insert address;
            
        Account newAccount1 = new Account();
        newAccount1.Name = 'Test Business Account';
        newAccount1.Business_Unit__c ='K';
        newAccount1.Sub_Division__c = 'B2B';
        newAccount1.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business_Account').getRecordTypeId();
        insert newAccount1;
        
        Contact contactRecord1 = new Contact(LastName = 'TestCon43',
                                            AccountId = newAccount1.Id,
                                            Phone = '9874562135');
        insert contactRecord1;
    
        Asset newAsset1 = new Asset();     
        newAsset1.Name= 'Asset 1';
        newAsset1.AccountId = newAccount1.id;
        newAsset1.RecordTypeId = Schema.SObjectType.Asset.getRecordTypeInfosByDeveloperName().get('MHE_Asset').getRecordTypeId();
        newAsset1.Status = 'Unregistered';
        newAsset1.Product_Family__c = 'Equipment';
        newAsset1.Product_Category__c = 'Counterbalanced Diesel';
        newAsset1.Product_Sub_Category__c = 'Light Diesel';
        newAsset1.Equipment_Category__c = 'CB-D';
        newAsset1.Type_of_Warranty__c = 'Std Warranty'; 
        newAsset1.Product_Purchased_Warranty_Start_Date__c = System.now();
        newAsset1.Product_Purchased_Warranty_End_Date__c = Date.today().addDays(5);
        newAsset1.ContactId = contactRecord1.Id;
		newAsset1.Address_Code__c = address.id;
        insert newAsset1;	
        
        Case newCase1 = new Case();
        newCase1.AccountId = newAccount1.Id;
        newCase1.Status = GlobalConstants.CASE_STATUS_ASSIGNED;
        newCase1.AssetId = newAsset1.Id;
        insert newCase1;
        
        Map<Id,Case> oldCaseMap = new Map<Id,Case>();
        oldCaseMap.put(newCase1.Id,newCase1);
        
        newCase1.Asset_Location__c = 'Vikroli';
        try{
            update newCase1;
        }
        catch(Exception e){
            Boolean expectedExceptionThrown =  e.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION') ? true : false;
            System.AssertEquals(expectedExceptionThrown, true);
        }
        
        Map<Id,Case> newCaseMap = new Map<Id,Case>();
        newCaseMap.put(newCase1.Id,newCase1);
        
        CaseFieldPopulator cfp = new CaseFieldPopulator();
        cfp.validateCaseChange(newCaseMap,oldCaseMap);
        
        Test.stopTest();
        }
        
    }
}