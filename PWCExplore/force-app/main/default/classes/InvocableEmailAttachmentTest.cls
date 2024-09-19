/*------------------------------------------------------------------------
Company    :   GITL
Description:   Test class for InvocableEmailAttachments    
History    :   20-05-2020    
----------------------------------------------------------------------------*/
@isTest
public class InvocableEmailAttachmentTest {
    @isTest 
    static void sendEmailSendTo() { 
        /*
//Create List of Account Data
List<account> accList = new List<account>();         
Account acc = new Account();
acc.Name = 'Knights watch';
acc.Business_Unit__c='G';
acc.type='I';

acc.Sub_Division__c='B2B';
insert acc;
accList.add(acc);

//Create List of Opportunity Data
List<Opportunity> oppList = new List <Opportunity>();
Opportunity o = new opportunity();
o.Name = 'Iron bank';
o.StageName = 'Needs Analysis';
o.AccountId = acc.Id;

o.Amount = 2000;        
o.CloseDate = system.Date.today();
insert o;        
oppList.add(o);

*/
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(thisUser){
            
            Discount_Matrix__c defaultDiscountMatrix=new Discount_Matrix__c(Name='No Discount',Discount_Code__c='HDH',
                                                                            Start_Date__c=System.Today(),End_Date__c=System.Today(),
                                                                            Gross_Net__c='1', Level__c='2', Stage__c='Active');
            Insert defaultDiscountMatrix;
            
            PriceBook2 standardPriceBook = new PriceBook2(Id = Test.getStandardPricebookId(), LN_PriceList_Code__c = 'ST', PriceList_Code__c = 'ST');
            update standardPriceBook;
            
            PriceBook2 contractPriceBook = new PriceBook2(Name = System.Label.MHE_SF_Local_Contract_PB, IsActive = true, LN_PriceList_Code__c = 'CON', PriceList_Code__c = 'CON');
            insert contractPriceBook;
            
            List<Product2> allProducts = new List<Product2> {
                new TestProductBuilder().setName('GX 300').setDescription('GX 300 Forklift').setItemCode('GX1').setComponentType('Base Product').getTestRecord(),
                    new TestProductBuilder().setName('GX 300 Attachment').setItemCode('GX2').setDescription('GX 300 Forklift Attachment').setComponentType('Attachments').getTestRecord()
                    };
                        insert allProducts;
            
            List<PriceBookEntry> allPBEs = new List<PriceBookEntry> {
                new TestPriceBookEntryBuilder().setProduct2Id(allProducts[0].Id).setPricebook2Id(contractPriceBook.Id).setUnitPrice(50000).getTestRecord(),
                    new TestPriceBookEntryBuilder().setProduct2Id(allProducts[1].Id).setPricebook2Id(contractPriceBook.Id).setUnitPrice(3000).getTestRecord()
                    };
                        insert allPBEs;
            
            ZipCode__c zipcd = new ZipCode__c(City_Name__c ='citytst', StateName__c = 'sttetst', name='zpcdtst');
            insert zipcd;
            Address__c addr = new Address__c(Street__c='strttst',ZipCode__c = zipcd.id,Name__c='Account for test class');
            insert addr;
            
            Account accountRecord = new TestAccountBuilder()
                .setRecordTypeId(Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business_Account').getRecordTypeId())
                .getSavedTestRecord();
            accountRecord.Primary_Address__c = addr.id;
            update accountRecord;
            
            Branch__c branch = new Branch__c();
            branch.Business_Partner__c = accountRecord.Id;
            branch.Business_Partner_Status__c = 'Open';
            branch.Branch_Name__c = '3010';
            insert branch;
            
            //create custom setting
            Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
            setting.FirePlannedDeliveryDateValidation__c = true;
            insert setting;
            
            Profile profileId = [SELECT Id FROM Profile WHERE Name = 'Appliances HO D2D User' LIMIT 1];
            
            UserRole ur = new UserRole(Name = 'Appliances HO (Head Office)-D2D');
            insert ur;
            
            User userWithRole = new User(UserRoleId = ur.Id, ProfileId = profileId.Id, Account__c = accountRecord.id, 
                                         Alias = 'hasrole', Email='userwithrole@godrej.com',
                                         EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',LocaleSidKey='en_US',
                                         TimeZoneSidKey='America/Los_Angeles',Username = 'test12345_gnbtest@godrej.com',CommunityNickname = 'test12345',
                                         Logistic_Company__c='5010',Business_Unit__c='H',Sub_Division__c='B2C',Interio_Sub_Division__c='',Persona__c='Appliances- HO (Head Office)-D2D',
                                         Salary_Code__c='377990',Business_Partner_Code__c='HHC000021'); 
            insert UserWithRole;
            
            Profile iaProfile = [SELECT Id FROM Profile WHERE Name = 'Appliances HO D2D User' LIMIT 1];
            
            UserRole iaUserRole = new UserRole(Name = 'CEO');
            insert iaUserRole;
            
            User iaUserWithRole = new User(UserRoleId = iaUserRole.Id, ProfileId = iaProfile.Id, 
                                           Alias = 'ia', Email='iaUser@godrej.com',
                                           EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',LocaleSidKey='en_US',
                                           TimeZoneSidKey='America/Los_Angeles',Username = 'iaUser@godrej.com',CommunityNickname = 'test123456'); 
            insert iaUserWithRole;    
            
        }
        
        User cocoUser = [Select id, Account__c from User WHERE username = 'test12345_gnbtest@godrej.com'];
        System.runAs(cocoUser){
            
            //Create Account
            Account newAccount = new Account( FirstName = 'Test', LastName ='Person Account', PersonEmail = 'test@invalid.com', Account_Code__c='HBC112233', Integration_status__c='Synced',
                                             RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Customer').getRecordTypeId());
            insert newAccount;
            
            Account newAccount2 = new Account( FirstName = 'Test12', LastName ='Person Account22', PersonEmail = 'test4433@invalid.com',
                                              Interio_Sub_Division__c = 'VFD',Business_Unit__c = 'H',Sub_Division__c = 'B2C',
                                              RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Customer').getRecordTypeId(),
                                              Account_Code__c='HBC123456', Integration_status__c='Synced');
            insert newAccount2;
            
            
            Opportunity newOpp = new Opportunity(
                Name = 'Test Opp',               
                AccountId = newAccount.Id, 
                Sales_Branch_Name__c = '3010',               
                LeadSource = 'Advertisement',           
                Business_Unit__c = 'W',                 
                Sub_Division__c = 'B2C',                      
                Interio_Sub_Division__c = 'VFD',              
                Organization_Name__c = '18-30 Lakhs',         
                Birthdate__c = Date.valueOf('1992-01-23'),    
                Amount = 8866.85,                             
                Anniversary__c = Date.valueOf('2019-11-07'),  
                CloseDate = Date.today().addDays(28),       
                StageName = 'Meeting Scheduled',              
                ForecastCategoryName = 'Pipeline',            
                Probability = 35,                             
                Occupation__c = 'Business',                    
                Internal_Sales_Rep__c = UserInfo.getUserId(),    
                Area_Code__c = 'EA1',               
                Room_Planner_Demo_Done__c = 'No',             
                Product_Configuration_Demo_Given__c = 'Yes',  
                Exchange_Order__c = 'No',                     
                RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Interio_B2C_Appliances').getRecordTypeId());
            
            insert newOpp;
            
            Blob bodyBlob=Blob.valueOf('Dummy Body'); 
            ContentVersion contentVersion = new ContentVersion(Title='SOA.pdf',  PathOnClient ='SampleTitle.pdf', VersionData = bodyBlob, origin = 'H');
            insert contentVersion;  
            //code to cover ContentDocumentLinkTrigger and it's helper        
            ContentDocumentLink contentlink = new ContentDocumentLink();
            contentlink.LinkedEntityId = newOpp.Id ;
            contentlink.contentdocumentid = [Select contentdocumentid from contentVersion where Id=:contentVersion.Id].contentdocumentid;
            contentlink.ShareType = 'V';
            insert contentlink;
            
            Quote newQuote = new Quote(
                Name = 'Test Quote',                 
                Opportunity_Owner__c = UserInfo.getUserId(),         
                Status = 'Draft',                             
                OpportunityId = newOpp.Id,                
                Approval_Status__c = 'Approval Not Required',     
                ExpirationDate = Date.today().addDays(20),      
                Area_Code__c = 'EA1',                   
                Transaction_Type__c = 'Primary',                  
                Quote_Type__c = 'Customer Facing',
                Sold_To_Business_Partner__c = cocoUser.Account__c,  
                Ship_To_Account__c = cocoUser.Account__c);
            insert newQuote;
            
            //Create List of Attachments Data
            attachment att = new attachment();
            att.Name = 'Test attachment';
            att.Body = bodyBlob;        
            att.ParentId = newOpp.Id;        
            insert att;
            
            //Input Variable 
            string myEmail = 'anytestEmailID@gmail.com';        
            string emailBody = 'this is the email body';        
            string emailSubject = 'this is subject';        
            List<invocableEmailAttachment.flowInput> inputList = new List<invocableEmailAttachment.flowInput>();        
            List<attachment> finalAttachmentList = [select id, name from Attachment where parentId =:newopp.Id];
            
            invocableEmailAttachment.flowInput input;        
            input = new invocableEmailAttachment.flowInput();        
            input.eMail = myEmail;
            input.ccMail = myEmail;        
            input.currentRecordId = newopp.Id;        
            input.eSubject = emailSubject;        
            input.ebody = emailBody;            
            input.sendAttachment=true;
            input.trackEmail = true;
            input.useOneCRMOrgWideEmailID = true;
            inputList.add(input);                 
            invocableEmailAttachment.currentRecordID(inputList);        
            integer invocation = limits.getEmailInvocations();                        
            system.assertEquals(1, invocation);        
            system.assertEquals(1, finalAttachmentList.size());                 
        } 
    }
}