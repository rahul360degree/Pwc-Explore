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
private class OrderFieldPopulatorTest {
    @TestSetup static void createData(){            
        //Test.startTest();
        UserRole iaUserRole = new UserRole(Name = 'CEO');
        insert iaUserRole;
        /*//Added Appliance Role by Shreela on 4th April 2023
        UserRole applUserRole = new UserRole(Name = 'Appliances_ASM_Raipur');
        insert applUserRole; */
        
        Profile iaProfile = [SELECT Id FROM Profile WHERE Name = 'Integration Administrator' LIMIT 1];
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        /*Profile applSalesUserProfile = [SELECT Id FROM Profile WHERE Name = 'Appliances Sales User' LIMIT 1]; //Added Appliance Profile by Shreela on 4th April 2023 */
        
        User objUser = new User(UserRoleId = iaUserRole.Id, ProfileId = adminProfile.Id, 
                                Alias = 'hasrole', Email='userwithrole@godrej.com',
                                EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',LocaleSidKey='en_US',
                                TimeZoneSidKey='America/Los_Angeles',Username = 'sample@godrej.com',CommunityNickname = 'sample',
                                Logistic_Company__c='5010',Business_Unit__c='W',Sub_Division__c='B2C',Interio_Sub_Division__c='VFD',
                                Persona__c='InterioVFD- COCO Store Team',Salary_Code__c='377992',Business_Partner_Code__c='WWC000021'); 
        
        insert objUser; 
         Test.startTest();
        System.runAs(objUser){
            Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
            setting.OrderTriggerDisabled__c = true;
            insert setting; 
            
        } 
        //Commented by Shreela on 28th March 2023
        
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(thisUser){
            //Added by Shreela on 28th March 2023
            //Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
            //setting.FirePlannedDeliveryDateValidation__c = true;
            //setting.OpportunityTriggerDisabled__c = true;
            //setting.QuoteTriggerDisabled__c = true;
            //insert setting;
            
            Discount_Matrix__c defaultDiscountMatrix=new Discount_Matrix__c(Name='No Discount',Discount_Code__c='HDH',
                                                                            Start_Date__c=System.Today(),End_Date__c=System.Today(),Discount_Amount__c = 1100, //Added Discount_Amount__c by Shreela on 28th March 2023
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
            
            Address__c addr = createPrimaryAddress();
            insert addr;
            
            Account accountRecord = new TestAccountBuilder()
                .setRecordTypeId(Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business_Account').getRecordTypeId())
                .getSavedTestRecord();
            accountRecord.Primary_Address__c = addr.id;
            accountRecord.Integration_Status_Pay_By__c='Synced';//Added by pankaj on 4th april 2023
            update accountRecord;
            
            Branch__c branch = new Branch__c();
            branch.Business_Partner__c = accountRecord.Id;
            branch.Business_Partner_Status__c = 'Open';
            branch.Branch_Name__c = '3010';
            branch.Integration_Status_Ship_To__c = 'Synced';//Added by pankaj on 4th april 2023
            branch.Integration_Status_Sold_To__c = 'Synced';//Added by pankaj on 4th april 2023 
            insert branch;
            
            //create custom setting
            /*Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
            setting.FirePlannedDeliveryDateValidation__c = true;
            insert setting; */  //Commented by Shreela on 28th March 2023
            
            Profile profileId = [SELECT Id FROM Profile WHERE Name = 'Interio B2C VFD COCO Team User' LIMIT 1];
            
            UserRole ur = new UserRole(Name = 'Interio VFD COCO Store MUM Chief 2');
            insert ur;
            
            User userWithRole = new User(UserRoleId = ur.Id, ProfileId = profileId.Id, Account__c = accountRecord.id, 
                                         Alias = 'hasrole', Email='userwithrole@godrej.com',
                                         EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',LocaleSidKey='en_US',
                                         TimeZoneSidKey='America/Los_Angeles',Username = 'test12345_gnbtest@godrej.com',CommunityNickname = 'test12345',
                                         Logistic_Company__c='5010',Business_Unit__c='W',Sub_Division__c='B2C',Persona__c='InterioVFD- COCO Store Team',Salary_Code__c='377990',Business_Partner_Code__c='WWC000021'); 
            insert UserWithRole;
            
            User iaUserWithRole = new User(UserRoleId = iaUserRole.Id, ProfileId = iaProfile.Id, 
                                           Alias = 'ia', Email='iaUser@godrej.com',
                                           EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',LocaleSidKey='en_US',
                                           TimeZoneSidKey='America/Los_Angeles',Username = 'iaUser@godrej.com',CommunityNickname = 'test123456'); 
            insert iaUserWithRole;      
            
        }
       
        User cocoUser = [Select id, Account__c from User WHERE username = 'test12345_gnbtest@godrej.com'];
        
        System.runAs(cocoUser){            
            Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
            setting.AccountTriggerDisabled__c = true;
            //setting.OrderTriggerDisabled__c = true; //Commented by Shreela on 28th March 2023
            setting.BranchTriggerDisabled__c = true; //Added by Shreela on 28th March 2023
            setting.OpportunityTriggerDisabled__c = true;  //Added by Shreela on 28th March 2023
            setting.QuoteTriggerDisabled__c = true; //Added by Shreela on 28th March 2023
            insert setting;
            //Create Address
            Address__c addr = createPrimaryAddress();
            addr.Building__c = 'Solitaire';
            insert addr;                  
            //Create Account
            Account newAccount = new Account( FirstName = 'Test', LastName ='Person Account', PersonEmail = 'test@invalid.com', 
                                             RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Customer').getRecordTypeId());
            insert newAccount;
            Branch__c salesBranch = new Branch__c(Branch_Name__c = '5010', Business_Partner__c  = newAccount.Id, Sold_To_Address__c = addr.Id );
            insert salesBranch;            
            Address_by_BP__c branchAddress = new Address_by_BP__c(Account__c  = newAccount.Id, Address_Code__c  = addr.Id, isPrimary__c = TRUE, 
                                                                  Branch__c = salesBranch.Id, Ship_To__c = TRUE, Sold_To__c  = TRUE);
            insert branchAddress;           
            
            
            Opportunity newOpp = new Opportunity(
                Name = 'Test Opp',               
                AccountId = newAccount.Id, 
                Sales_Branch_Name__c = '3010',               
                LeadSource = 'Advertisement',           
                Business_Unit__c = 'W',                 
                Sub_Division__c = 'B2C',                      
                // Interio_Sub_Division__c = 'VFD',              
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
                Ship_To_Account__c = cocoUser.Account__c,
                Sold_to_Address__c = branchAddress.id);
            insert newQuote;
            
            //Create Order 
            Order newOrder = new Order( Logistics_Company_Branch__c = '3010',                  
                                       Line_of_Business__c = 'E&P',                               
                                       Business_Unit__c = 'W', Sub_Division__c = 'B2C',                                                
                                       Internal_Sales_Representative__c = UserInfo.getUserId(),
                                       AccountId = newAccount.Id,Sold_To_Business_Partner__c = cocoUser.Account__c,EffectiveDate = System.today(),Status = 'Draft',  
                                       Ship_To_Account__c = cocoUser.Account__c, QuoteId = newQuote.Id,OpportunityId = newOpp.Id,Owner_Manager_Email__c='abc@gmail.com',
                                       RecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('Interio_B2C_VFD_Primary').getRecordTypeId());
            insert newOrder;
            //Profile adminProfile1 = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
            
        }
        User mhe_user = new User(UserRoleId = iaUserRole.Id, ProfileId = adminProfile.Id, 
                                 Alias = 'mhe', Email='mheUser@godrej.com',Salary_Code__c='6121997',Business_Unit__c='K',
                                 EmailEncodingKey='UTF-8', LastName='Testing_mhe', LanguageLocaleKey='en_US',LocaleSidKey='en_US',
                                 TimeZoneSidKey='America/Los_Angeles',Username = 'mheUser@godrej.com',CommunityNickname = 'test12345678');
        insert mhe_user;
        System.runAs(mhe_user){
            Runtime_Execution__c setting1 = Runtime_Execution__c.getInstance();
            setting1.AccountTriggerDisabled__c = true;
            setting1.OrderTriggerDisabled__c = true;
            //setting1.ClaimRequestTriggerDisabled__c = true; //Commented by Shreela on 28th March 2023
            setting1.QuoteTriggerDisabled__c = true;
            setting1.OpportunityTriggerDisabled__c = true; //Added by Shreela on 28th March 2023	
            insert setting1;               
            
            Account newAccount_MHE = new Account( Name = 'Test Account MHE', Business_Unit__c = 'K',Type='D',Dealer_Type__c = 'Non Stock & Sell',
                                                 RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Dealer').getRecordTypeId());
            insert newAccount_MHE;                      
            
            Address_by_BP__c abp = new Address_by_BP__c();
            abp.Account__c = newAccount_MHE.Id;
            abp.Sold_To__c = true;
            abp.Ship_To__c = true; //Added this and above line by Shreela on 10th October 2022 
            abp.RecordTypeId = (RecordTypeUtils.getInstance()).getRecordTypeId('Address_by_BP__c', 'B2B_Additional_Address');
            AddressByBPTriggerHandler.TriggerDisabled = true;
            insert abp;     
            
            //newAccount_MHE.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Dealer').getRecordTypeId();
            //Update newAccount_MHE;
            
            Opportunity newMheOpp = new Opportunity(
                Name = 'Test MHE Opp',               
                AccountId = newAccount_MHE.Id, 
                Sales_Branch_Name__c = '3010',               
                LeadSource = 'Advertisement',           
                Business_Unit__c = 'K',                       
                Organization_Name__c = '18-30 Lakhs',         
                Birthdate__c = Date.valueOf('1992-01-23'),    
                Amount = 8866.85,                             
                Anniversary__c = Date.valueOf('2019-11-07'),  
                CloseDate = Date.today().addDays(28),       
                StageName = 'Qualification',              
                ForecastCategoryName = 'Pipeline',            
                Probability = 35,                             
                Occupation__c = 'Business',                    
                Internal_Sales_Rep__c = UserInfo.getUserId(),    
                Area_Code__c = 'EA1',               
                Room_Planner_Demo_Done__c = 'No',             
                Product_Configuration_Demo_Given__c = 'Yes',  
                Exchange_Order__c = 'No',                     
                RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('MHE').getRecordTypeId());
            
            insert newMheOpp;
            
            Quote newMheQuote = new Quote(
                Name = 'Test Quote',                 
                Opportunity_Owner__c = UserInfo.getUserId(),         
                Status = 'Draft',                             
                OpportunityId = newMheOpp.Id,                
                Approval_Status__c = 'Approval Not Required',     
                ExpirationDate = Date.today().addDays(20),      
                Area_Code__c = 'EA1',                   
                Transaction_Type__c = 'Primary',                  
                Quote_Type__c = 'Non-Customer Facing',
                Associated_Dealer__c = newAccount_MHE.Id,
                Sold_To_Business_Partner__c = mhe_user.Account__c,SCC_Activities__c = 'Enquiry Generation;Demo Conducted;Ensuring technical clearance;',  
                Ship_To_Account__c = newAccount_MHE.id,Ship_To_Address__c = abp.id,
                Sold_To_Address__c = abp.id, //Added by Shreela on 10th oct 2022
                RecordTypeId = Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get('MHE_Equipments').getRecordTypeId());
            
            insert newMheQuote;
            
            Sales_Office__c salesoffice=new Sales_Office__c();
            salesoffice.Name='test Sales Office';
            salesoffice.LN_Sales_Office_Code__c='SO1';
            insert salesoffice;
            
            Order newMHESecondaryOrder = new Order( Logistics_Company_Branch__c = '3010',Line_of_Business__c = 'E-RETA',Business_Unit__c = 'K',                                            
                                                   Internal_Sales_Representative__c = UserInfo.getUserId(),QuoteId = newMheQuote.Id,Sub_Division__c = 'B2B',
                                                   AccountId = newAccount_MHE.Id,EffectiveDate = System.today(),Status = 'Draft',MHE_Division__c='Outright Sales',
                                                   Sales_Office__c=salesoffice.id,Area__c='WN1',Type='SOT',Sales_order_series__c='KOS',  
                                                   Owner_Manager_Email__c='abc@gmail.com',
                                                   RecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('MHE_Order_Secondary').getRecordTypeId());
            insert newMHESecondaryOrder;                
            Order newMHEPrimaryOrder = new Order( Logistics_Company_Branch__c = '3010',OrderReferenceNumber='HOA020202',Integration_Status__c='Draft',   //Changed from Synced to Draft by Shreela on 10th Oct 2022               
                                                 Line_of_Business__c = 'E-RETA', Related_Secondary_Order__c =  newMHESecondaryOrder.Id,                            
                                                 Business_Unit__c = 'K',Internal_Sales_Representative__c = UserInfo.getUserId(),QuoteId = newMheQuote.Id,
                                                 AccountId = newAccount_MHE.Id,EffectiveDate = System.today(),Status = 'Draft',MHE_Division__c='Outright Sales',
                                                 Sales_Office__c=salesoffice.id,Area__c='WN1',Type='SOT',Sales_order_series__c='KOS',  
                                                 Owner_Manager_Email__c='abc@gmail.com',
                                                 Sold_to_Business_Partner__c = newAccount_MHE.Id, //Added by shreela on 10th october 2022 for resolving 101 error and rectifying custom validation (Sold_To_Ship_To_Address_Validate)
                                                 Ship_To_Account__c = newAccount_MHE.Id, //Added by shreela on 10th october 2022 for resolving 101 error and rectifying custom validation (Sold_To_Ship_To_Address_Validate)
                                                 RecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('MHE_Order_Primary').getRecordTypeId());
            insert newMHEPrimaryOrder;
            
            //Added by Shreela on 6th April 2022 
            //Get standart price book
            Pricebook2 standardPricebook = new Pricebook2(Id = Test.getStandardPricebookId(),IsActive = true,PriceList_Code__c='123',LN_PriceList_Code__c='456');
            Update standardPricebook;
            
            //insert product
            Product2 product = new Product2(Name = 'test product', Family = 'Mobile',Item__c='mob123',Is_Generic_Product__c=true);
            Insert product;
            //ended by Shreela on 6th April 2022
            
            String mheOrderPrimary  = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('MHE_Order_Primary').getRecordTypeId();  
            Order order=new Order();
            order.RecordTypeId=mheOrderPrimary;
            order.quoteId = newMheQuote.id;
            order.Sales_Type__c=GlobalConstants.SALES_TYPE_PRIMARY;
            order.Business_Unit__c='K';
            order.AccountId=newAccount_MHE.Id;
            order.Status='Draft';
            order.Is_Create_Demo_Installation_Request__c = true;
            order.Sales_Price_List__c=Test.getStandardPricebookId();
            order.Area__c ='EA2';
            order.EffectiveDate = date.today();
            order.Pricebook2Id = Test.getStandardPricebookId();
            order.order_currency__c = 'INR';
            order.Sold_to_Business_Partner__c =newAccount_MHE.Id;   
            order.Order_Reference_Number_Ext__c = '';
            Insert order; 
            
            //added by Shreela on 6th April 2022 
            Product2 product2 = [select id from product2 where item__c = 'mob123' limit 1];
            
            Id mhePrimaryRecordTypeId=Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('MHE_Order_Primary').getRecordTypeId();  
            
            //insert order
            Order order3=new Order();
            order3.RecordTypeId=mhePrimaryRecordTypeId;
            order3.Sales_Type__c=GlobalConstants.SALES_TYPE_PRIMARY;
            order3.Business_Unit__c='K';
            order3.AccountId=newAccount_MHE.Id;
            order3.Status='Draft';
            order3.Sales_Price_List__c=Test.getStandardPricebookId();
            order3.Area__c ='EA2';
            order3.EffectiveDate = date.today();
            order3.Pricebook2Id = Test.getStandardPricebookId();
            order3.order_currency__c = 'INR';
            order3.MHE_Division__c = 'Outright Sales';
            order3.Order_Amount__c = 24000;
            Insert order3;
            
            
            //insert orderLineItem
            OrderItemTriggerHandler.TriggerDisabled=true;
            List<OrderItem> itemList = new List<OrderItem>();
            OrderItem lineItem=new OrderItem();
            lineItem.Product2Id=product2.Id;
            lineItem.Quantity=1;
            lineItem.orderId=order3.Id;
            lineItem.Product2Id=product2.Id;
            lineItem.PricebookEntryId=[Select Id From PriceBookEntry Limit 1].Id;
            lineItem.UnitPrice=30;
            lineItem.Price_origin__c= 'extern';
            itemList.add(lineItem);
            Insert itemList;
            
            lineItem.UnitPrice=40;
            //update lineItem;
            //ended by Shreela on 6th April 2022                     
            
        }
        //Creating user for SSG
         User ssg_userMgr = new User(UserRoleId = iaUserRole.Id, ProfileId = iaProfile.Id, 
                                 Alias = 'ssg', Email='ssgUserManager@godrej.com',Salary_Code__c='377338',Business_Unit__c='G',
                                 EmailEncodingKey='UTF-8', LastName='Testing_ssg', LanguageLocaleKey='en_US',LocaleSidKey='en_US',
                                 TimeZoneSidKey='America/Los_Angeles',Username = 'ssgUserMgr@godrej.com',CommunityNickname = 'test1234568');
        insert ssg_userMgr;
        User ssg_user = new User(UserRoleId = iaUserRole.Id, ProfileId = iaProfile.Id, 
                                 Alias = 'ssg', Email='ssgUser@godrej.com',Salary_Code__c='377337',Business_Unit__c='G',
                                 EmailEncodingKey='UTF-8', LastName='Testing_ssg', LanguageLocaleKey='en_US',LocaleSidKey='en_US',
                                 TimeZoneSidKey='America/Los_Angeles',Username = 'ssgUser@godrej.com',CommunityNickname = 'test1234567',managerId=ssg_userMgr.id);
        insert ssg_user;

        System.runAs(ssg_user){
            Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
            setting.AccountTriggerDisabled__c = true;
            setting.OrderTriggerDisabled__c = true;
            //setting.ClaimRequestTriggerDisabled__c = true; //Commented by Shreela on 28th March 2023
            setting.QuoteTriggerDisabled__c = true;
            setting.OpportunityTriggerDisabled__c = true; //Added by Shreela on 10th Oct 2022 for resolving 101 error in OpportunityFieldPopulator class
            insert setting;
            //Creating Account for SSG
            Account newAccount_ssg = new Account( Name = 'Test Account', Business_Unit__c = 'G', Type = 'I',
                                                 RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business_Account').getRecordTypeId());
            insert newAccount_ssg;
            
            contact ssgContact = new Contact();
            ssgContact.LastName = 'test contact';
            ssgContact.MobilePhone = '9801230202';
            ssgContact.Business_Unit__c='G';
            insert ssgContact;
            
            Account accountRecord_ssgsid = new TestAccountBuilder()
                .setRecordTypeId(Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business_Account').getRecordTypeId())
                .getSavedTestRecord();
            accountRecord_ssgsid.Business_Unit__c = 'G';
            update accountRecord_ssgsid;
            
            Opportunity newSsgOpp = new Opportunity(
                Name = 'Test ssg Opp',               
                AccountId = newAccount_ssg.Id, 
                contactId = ssgContact.id,
        //        Converted_Lead__c = '00Q1m000002SWebEAG',
                Sales_Branch_Name__c = '3010',               
                LeadSource = 'Advertisement',           
                Business_Unit__c = 'G',                       
                Organization_Name__c = '18-30 Lakhs',         
                Birthdate__c = Date.valueOf('1992-01-23'),    
                Amount = 8866.85,                             
                Anniversary__c = Date.valueOf('2019-11-07'),  
                CloseDate = Date.today().addDays(28),       
                StageName = 'Qualification',              
                ForecastCategoryName = 'Pipeline',            
                Probability = 35,                             
                Occupation__c = 'Business',                    
                Internal_Sales_Rep__c = UserInfo.getUserId(),    
                Area_Code__c = 'EA1',               
                Room_Planner_Demo_Done__c = 'No',             
                Product_Configuration_Demo_Given__c = 'Yes',  
                Exchange_Order__c = 'No',                     
                RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('SSG').getRecordTypeId());
            
            insert newSsgOpp;
            
            Quote newSsgQuote = new Quote(
                Name = 'Test Quote',                 
                Opportunity_Owner__c = UserInfo.getUserId(),         
                Status = 'Draft',                             
                OpportunityId = newSsgOpp.Id,                
                Approval_Status__c = 'Approval Not Required',     
                ExpirationDate = Date.today().addDays(20),      
                Area_Code__c = 'EA1',                   
                Transaction_Type__c = 'Primary',                  
                Quote_Type__c = 'Customer Facing',
                Sold_To_Business_Partner__c = ssg_user.Account__c,  
                Ship_To_Account__c = ssg_user.Account__c,Scope_of_Installation__c = 'Dealer');
            
            insert newSsgQuote;
            
            //Creating order for SSG
            Order newOrder_ssg = new Order( Logistics_Company_Branch__c = '1300',                  
                                           Line_of_Business__c = 'ENGG',QuoteId=newSsgQuote.id,                               
                                           Business_Unit__c = 'G', Sub_Division__c = 'B2B',                                                
                                    //       Internal_Sales_Representative__c = ssg_user.id, //Commented by Rohit Jadhav on 28 March 202
                                           AccountId = accountRecord_ssgsid.Id,EffectiveDate = System.today(),Status = 'Draft',
                                           RecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('SSG_Primary').getRecordTypeId());
            insert newOrder_ssg;  
            User objMHEUser = new User(UserRoleId = iaUserRole.Id, ProfileId = adminProfile.Id, 
                                       Alias = 'hasrole', Email='objMHEuser@godrej.com',
                                       EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',LocaleSidKey='en_US',
                                       TimeZoneSidKey='America/Los_Angeles',Username = 'objMHEuser@godrej.com',CommunityNickname = 'agent',
                                       Logistic_Company__c='5010',Business_Unit__c='K'); 
            
            insert objMHEUser;
            
        }
        
        /*//Added user and other details specifically for Appliance by Shreela on 4th April 2023
        User applUser = new User(UserRoleId = applUserRole.Id, ProfileId = applSalesUserProfile.Id, 
                                 Alias = 'appl', Email='applSalesUser@godrej.com',Salary_Code__c='377248',Business_Unit__c='H',
                                 EmailEncodingKey='UTF-8', LastName='Testing_Appl_Sales_User', LanguageLocaleKey='en_US',LocaleSidKey='en_US',
                                 TimeZoneSidKey='America/Los_Angeles',Username = 'applSalesUser@godrej.com',CommunityNickname = 'testAppl123');
        System.runAs(applUser){
            
            Runtime_Execution__c setting1 = Runtime_Execution__c.getInstance();
            setting1.AccountTriggerDisabled__c = true;
            setting1.TaxNumberTriggerDisabled__c = true; 
            setting1.QuoteTriggerDisabled__c = true;
            setting1.OpportunityTriggerDisabled__c = true; 	
            setting1.OrderTriggerDisabled__c = true;
            insert setting1;               
            
            Account newAccountAppl = new Account( Name = 'Test Account Appl', Business_Unit__c = 'H',Type='D',Dealer_Type__c = 'Non Stock & Sell',
                                                 RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Dealer').getRecordTypeId());
            insert newAccountAppl;  
            
            Opportunity newApplOpp = new Opportunity(
                Name = 'Test Appl Opp',               
                AccountId = newAccountAppl.Id, 
                Sales_Branch_Name__c = '3010',               
                LeadSource = 'Advertisement',           
                Business_Unit__c = 'H',                       
                Organization_Name__c = '18-30 Lakhs',         
                Birthdate__c = Date.valueOf('1992-01-23'),    
                Amount = 8866.85,                             
                Anniversary__c = Date.valueOf('2019-11-07'),  
                CloseDate = Date.today().addDays(28),       
                StageName = 'Qualification',              
                ForecastCategoryName = 'Pipeline',            
                Probability = 35,                             
                Occupation__c = 'Business',                    
                Internal_Sales_Rep__c = UserInfo.getUserId(),    
                Area_Code__c = 'EA1',               
                Room_Planner_Demo_Done__c = 'No',             
                Product_Configuration_Demo_Given__c = 'Yes',  
                Exchange_Order__c = 'No',                     
                RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Appliances').getRecordTypeId());
            
            insert newApplOpp;
            
            Quote newApplQuote = new Quote(
                Name = 'Test Quote',                 
                Opportunity_Owner__c = UserInfo.getUserId(),         
                Status = 'Draft',                             
                OpportunityId = newApplOpp.Id,                
                Approval_Status__c = 'Approval Not Required',     
                ExpirationDate = Date.today().addDays(20),      
                Area_Code__c = 'EA1',                   
                Transaction_Type__c = 'Primary',                  
                Quote_Type__c = 'Non-Customer Facing',
                Associated_Dealer__c = newAccountAppl.Id,
                Sold_To_Business_Partner__c = mhe_user.Account__c,SCC_Activities__c = 'Enquiry Generation;Demo Conducted;Ensuring technical clearance;',  
                Ship_To_Account__c = newAccountAppl.id,
                RecordTypeId = Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get('Appliances').getRecordTypeId());
            
            insert newApplQuote;

            
            Order newApplPrimaryOrder = new Order( Logistics_Company_Branch__c = '5000',Line_of_Business__c = 'D2D',Business_Unit__c = 'H',                                            
                                                   //Internal_Sales_Representative__c = UserInfo.getUserId(),
                                                   QuoteId = newApplQuote.Id,Sub_Division__c = 'B2C',
                                                   AccountId = newAccountAppl.Id,EffectiveDate = System.today(),Status = 'Draft',
                                                   Area__c='HZ1',Type='NOR',Sales_order_series__c='HOP',  
                                                   Owner_Manager_Email__c='abc@gmail.com',
                                                   RecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('Appliance_Primary').getRecordTypeId());
            insert newApplPrimaryOrder;
            
        }  */
        Test.stopTest(); 
    }
    
    @isTest private static void setRecordTypeForInforOrdersTest(){
        Test.startTest();
        User iaUser = [Select id, Account__c from User WHERE username = 'iaUser@godrej.com'];
        System.runAs(iaUser){
            //Create Account
            Account newAccount = new Account( FirstName = 'Test', LastName ='Person Account', PersonEmail = 'testt@invalid.com',
                                             Interio_Sub_Division__c = 'VFD',Business_Unit__c = 'W',Sub_Division__c = 'B2C',
                                             RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Customer').getRecordTypeId());
            insert newAccount;
            
            //Create Order 
            Order newOrder = new Order( Logistics_Company_Branch__c = '3010',                  
                                       Line_of_Business__c = 'E&P',                               
                                       Business_Unit__c = 'W', Sub_Division__c = 'B2C',                                                
                                       Planned_Delivery_Date__c = Datetime.now().addDays(10),
                                       AccountId = newAccount.Id,OwnerId = iaUser.Id
                                      );
            insert newOrder;
            OrderFieldPopulator opf = new OrderFieldPopulator();
            opf.setRecordTypeForInforOrders(new List<Order>{newOrder});
            
        }        
        Test.stopTest();
    }
    
    
    
    @isTest private static void populateDefaultsTest(){
        Test.startTest();
        User usr = [Select id, Account__c from User WHERE username = 'test12345_gnbtest@godrej.com'];
        System.runAs(usr){
                        Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
            setting.AccountTriggerDisabled__c = true;
            setting.OrderTriggerDisabled__c = true;
            //setting.ClaimRequestTriggerDisabled__c = true; //Commented by Shreela on 28th March 2023
            setting.QuoteTriggerDisabled__c = true;
            setting.OpportunityTriggerDisabled__c = true;
            //insert setting;
            String query = QueryBuilder.build(GlobalConstants.ORDER_SOBJECT_API_NAME,'',false);
            List<Order> orderRecords = Database.query(query);   
            
            OrderFieldPopulator opf = new OrderFieldPopulator();
            opf.populateDefaults(orderRecords);
        }
        Test.stopTest();
    }
    
    @isTest private static void validatePlannedDeliveryDateTest(){
        Test.startTest();
        User usr = [Select id, Account__c from User WHERE username = 'mheUser@godrej.com']; //Modified by Shreela on 29th June 2022
        System.runAs(usr){
            String query = QueryBuilder.build(GlobalConstants.ORDER_SOBJECT_API_NAME,'',false);
            List<Order> orderRecords = Database.query(query);
            //added by Shreela on 29th June 2022
            Map<Id,Order> orderRecords2 = new Map<Id,Order>();
            for(Order ord : orderRecords){
                orderRecords2.put(ord.Id,ord);
            }
            
            orderRecords[0].Planned_delivery_Date__c = Datetime.now().addDays(-10);
            //added by Shreela on 29th June 2022
            orderRecords[0].MHE_Division__c = GlobalConstants.MHE_SUB_DIVISION_EQUIPMENT;
            orderRecords[0].Approval_Status__c = GlobalConstants.APPROVED_STATUS ; 
            orderRecords[0].Integration_Status__c = GlobalConstants.INTEGRATION_STATUS_SYNCED;
            
            try{
                update orderRecords;
            }
            catch(Exception e){
                String message = e.getMessage();           
            }       
            //ended by shreela on 2
            OrderFieldPopulator opf = new OrderFieldPopulator();
            opf.validatePlannedDeliveryDate(orderRecords2,orderRecords); //Modified by Shreela on 28th June 2022
        }
        Test.stopTest();
    }
    
    @isTest private static void populateApproversForInternalUsersTest(){
        Test.startTest();
        User usr = [Select id, Account__c from User WHERE username = 'test12345_gnbtest@godrej.com'];
        System.runAs(usr){
            String query = QueryBuilder.build(GlobalConstants.ORDER_SOBJECT_API_NAME,'',false);
            List<Order> orderRecords = Database.query(query);
            OrderFieldPopulator opf = new OrderFieldPopulator();
            opf.populateApproversForInternalUsers(orderRecords);
        }
        Test.stopTest();
    }
    
    private static Address__c createPrimaryAddress(){
        ZipCode__c zipcd = new ZipCode__c(City_Name__c ='citytst', StateName__c = 'sttetst', name='zpcdtst');
        insert zipcd;
        Address__c addr = new Address__c(Street__c='strttst',ZipCode__c = zipcd.id,Name__c='Account for test class',Building__c='Daisy Apartment'); //Added Building__c by Shreela on 28th March 2023
        return addr;
    }
    
    //Calling createOrderItems with Copy_LineItems__c checked should create order with line items
    @isTest private static void createOrderItemsWithCopyCheckedShouldCreateOrderWithLineItems(){
    /*Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
setting.OrderTriggerDisabled__c = true;
insert setting;*/
        List<Order> orderRecords = new List<Order>();
        User objUser = [Select id from User WHERE username = 'sample@godrej.com'];
        
        System.runAs(objUser){
            List<PriceBookEntry> pbeList = new List<PriceBookentry>([Select Id, UnitPrice, PriceBook2Id from PriceBookEntry where Pricebook2.Name = :System.Label.MHE_SF_Local_Contract_PB]);
            
            String query = QueryBuilder.build(GlobalConstants.ORDER_SOBJECT_API_NAME,'',false);
            system.debug('query SID : '+query);
            orderRecords = Database.query(query);
            //List<Order> orderRecords = [SELECT Id,QuoteId,AccountId,OpportunityId,Related_Secondary_Order__c,Copy_LineItems__c,Intent__c,PriceBook2Id FROM Order LIMIT 1];
            if(orderRecords.size()>0 && pbeList.size()>0) {
                String quoteId = orderRecords[0].QuoteId;
                //Create Order 
                Order newOrder2 = new Order( Logistics_Company_Branch__c = '3010',                  
                                            Line_of_Business__c = 'E&P',   PriceBook2Id = pbeList[0].Pricebook2Id,                           
                                            Business_Unit__c = 'W', Sub_Division__c = 'B2C',EffectiveDate = System.today(),Status = 'Draft',
                                            AccountId = orderRecords[0].AccountId, QuoteId = quoteId,OpportunityId = orderRecords[0].OpportunityId,
                                            RecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('Interio_B2C_VFD_Primary').getRecordTypeId());
                insert newOrder2;
                List<OrderItem> allOLI = new List<OrderItem> {
                    new OrderItem(OrderId = newOrder2.Id, Quantity  = 1, PriceBookEntryId = pbeList[0].Id, UnitPrice =  pbeList[0].UnitPrice ),
                        new OrderItem(OrderId = newOrder2.Id, Quantity  = 1, PriceBookEntryId = pbeList[1].Id, UnitPrice =  pbeList[1].UnitPrice )
                        };
                            insert allOLI;
                
                //Added by Pankaj on 23-12-2021 for productDescriptionPopulator class coverage
                List<Id> lstOdr = new List<Id>();
                lstOdr.add(newOrder2.Id);
                productDescriptionPopulator.updateProductDescr(lstOdr);
                
                //end by pankaj
                Test.startTest();
                update new Quote(Id = quoteId, PriceBook2Id = pbeList[0].PriceBook2Id);
                List<QuoteLineItem> allQLI = new List<QuoteLineItem> {
                    new TestQuoteLineItemBuilder().setQuoteId(quoteId).setPriceBookEntryId(pbeList[0].Id).setUnitPrice(pbeList[0].unitPrice).getTestRecord(),
                        new TestQuoteLineItemBuilder().setQuoteId(quoteId).setPriceBookEntryId(pbeList[1].Id).setUnitPrice(pbeList[1].unitPrice).getTestRecord()
                        };
                            insert allQLI;
                
                orderRecords[0].Related_Secondary_Order__c = newOrder2.Id;
                orderRecords[0].Copy_LineItems__c = TRUE;
                orderRecords[0].Intent__c = 'true';
                orderRecords[0].PriceBook2Id = pbeList[0].PriceBook2Id;
                update orderRecords;
                
            }
        }
        User usr = [Select id, Account__c from User WHERE username = 'test12345_gnbtest@godrej.com'];
        System.runAs(usr){
            OrderFieldPopulator opf = new OrderFieldPopulator();
            opf.createOrderItems(new Map<Id, Order>{orderRecords[0].Id => orderRecords[0]});
            
        }
        List<OrderItem> orderItemList = new List<OrderItem>([Select Id from OrderItem where OrderId = :orderRecords[0].Id]);
        System.assertEquals(orderItemList.size()>0, TRUE, 'OrderItems should be copied from Secondary Order');
        Test.stopTest();
    }
    
    @isTest
    public static void generateClaimRequestOnExternalIdUpdate() {
        Test.startTest();
        //Order order = [SELECT Id,QuoteId FROM Order LIMIT 1];
        Account mheAccount  = [select id from Account where Name = 'Test Account MHE'];
        /*mheAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Dealer').getRecordTypeId();
Update mheAccount;
Account newAccount = new Account(Type='D',Dealer_Type__c = 'Non Stock & Sell',RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Dealer').getRecordTypeId(),Name='TEST');
insert newAccount;*/
        Order mheOrder = [select id,QuoteId,Sales_Type__c from Order where Business_unit__c='K' and Sales_Type__c=:GlobalConstants.SALES_TYPE_PRIMARY Limit 1];
        Quote q = new Quote(Id = mheOrder.QuoteId,Quantity__c = 2,SCC_Activities__c = 'Enquiry Generation;Demo Conducted;Ensuring technical clearance;',Transaction_Type__c='Primary',Associated_Dealer__c = mheAccount.Id,Commission__c = 1,RecordTypeId = Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get('MHE_Equipments').getRecordTypeId(),Quote_Type__c='Non-Customer Facing');
        update q; 
        
        // Order mheOrder = [select id,Sales_Type__c from Order where Business_unit__c='K' and Sales_Type__c=:GlobalConstants.SALES_TYPE_PRIMARY Limit 1];
        //mheOrder.RecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('MHE_Order_Primary').getRecordTypeId();
        mheOrder.Order_Reference_Number_Ext__c = '5';
        system.debug('Sales_Type__c--->'+mheOrder.id+'===>'+mheOrder.Sales_Type__c);
        update mheOrder;
        
        List<Claim_Requests__c> claims  = [SELECT Id FROM Claim_Requests__c WHERE Godrej_Sales_Order__c =: mheOrder.Id];
        system.debug('Sales_Type__c--->'+claims.size());
        System.assertEquals(1, claims.size());
        Test.stopTest();
    }
    
    /*------------------------------------------------------------------------
Author     :  Siddhesh Mayekar
Date       :  29/11/2021
Description:  Test Method to Show validation error if User other than Order's owner/its L+1 is trying to submit order for approval(SSG-Primary).
Inputs     :  Map<Id, Order> mapNewOrderRecords, Map<Id, Order> mapOldOrderRecords)
----------------------------------------------------------------------------*/
    @isTest
    public static void verifyingSubmitterForOrderApprovalSSG() {
        Order order = [SELECT Id FROM Order WHERE Business_Unit__c = 'G' AND Approval_Status__c = null LIMIT 1];
        order.Approval_Status__c = 'Submitted for Approval';
        Test.startTest();
        try{
            update order;
        }
        catch(Exception e){
            String message = e.getMessage();
            System.assertEquals(message.contains('You don\'t have access to submit order for approval.'),True);           
        }       
        Test.stopTest();  
    }
    @isTest
    public static void PopulateShipTOMHE() {
        Order MHEOrder = [SELECT Id,Business_unit__c,QuoteId,Related_Secondary_Order__c,Ship_To_Address__c,Ship_To_Account__c,Sold_to_Business_Partner__c,Sold_to_Address__c,AccountId FROM Order WHERE Business_Unit__c =: GlobalConstants.MHE_BUSINESS_UNIT and Related_Secondary_Order__c != Null and MHE_Division__c =: GlobalConstants.MHE_SUB_DIVISION_EQUIPMENT AND OrderReferenceNumber='HOA020202' Limit 1]; //Added AccountId,Sold_to_Business_Partner__c,Sold_to_Address__c and OrderReference Number by Shreela on 10th October 2022 for resolving custom validation error and 101 error
        Quote MHEQuote = [SELECT Id,Ship_To_Address__c,Ship_To_Account__c,Sold_to_Business_Partner__c,Sold_to_Address__c From Quote where Ship_To_Address__c != Null and Ship_To_Account__c!= Null and Record_Type_Developer_Name__c ='MHE_Equipments' Limit 1];
        //System.debug('MHEQuote='+MHEQuote.size());
        MHEOrder.Ship_To_Account__c = MHEQuote.Ship_To_Account__c;
        //MHEOrder.Ship_To_Address__c = MHEQuote.Ship_To_Address__c;
        /*System.debug('MHEOrder.AccountId :'+MHEOrder.AccountId);
System.debug('MHEOrder.Ship_To_Address__r.Account__c :'+MHEOrder.Ship_To_Address__r.Account__c);
System.debug('MHEOrder.Ship_To_Address__r.Ship_To__c :'+MHEOrder.Ship_To_Address__r.Ship_To__c);
System.debug('MHEOrder.Ship_To_Account__c'+MHEOrder.Ship_To_Account__c); */
        //MHEOrder.Sold_to_Business_Partner__c = MHEQuote.Sold_to_Business_Partner__c;
        //MHEOrder.Sold_to_Address__c = MHEQuote.Sold_to_Address__c; //Added Sold_to_Business_Partner__c,Sold_to_Address__c by Shreela on 10th October 2022 for resolving custom validation error and 101 error
        update MHEOrder;
    }
    /*------------------------------------------------------------------------
Author     :  Shreela Nair
Date       :  06/04/2022
Description:  Test  Method to send Email Notification along with Attachment of MHE Synced Outright Sales
Inputs     :  
----------------------------------------------------------------------------*/       
    
    @isTest
    public static void OrderNotificationToMheOutrightUserTest() {
        Order MHEOrder = [SELECT Id,Business_unit__c,Integration_Status__c,MHE_Division__c,Order_Amount__c,QuoteId,Related_Secondary_Order__c,Ship_To_Address__c,Ship_To_Account__c FROM Order WHERE Business_Unit__c =: GlobalConstants.MHE_BUSINESS_UNIT  and MHE_Division__c =:GlobalConstants.MHE_SUB_DIVISION_EQUIPMENT  Limit 1];
        
        Blob bodyBlob=Blob.valueOf('Dummy Body');          
        ContentVersion contentVersion = new ContentVersion(
            Title='Payment', 
            PathOnClient ='SampleTitle.pdf',
            VersionData = bodyBlob, 
            origin = 'H'
        );
        
        insert contentVersion;
        
        contentVersion = [SELECT Id, Title, ContentDocumentId 
                          FROM ContentVersion WHERE Id = :contentVersion.Id LIMIT 1];
        ContentDocumentLink contentlink = new ContentDocumentLink();
        contentlink.LinkedEntityId =MHEOrder.id;
        contentlink.contentdocumentid = contentVersion.contentdocumentid;
        contentlink.ShareType = 'V';
        insert contentlink;
        
        MHEOrder.Integration_Status__c = 'Synced';
        update MHEOrder;
    }
    
    @isTest 
    public static void restrictUpdatesOnApprovedMHEOrders(){
        Test.startTest();
        User objMHEuser = [Select id, Account__c from User WHERE username = 'objMHEuser@godrej.com'];
        List<Order> newOrder = [Select id, Integration_Status__c, Business_Unit__c , MHE_Division__c,mr_type__c,
                                Approval_Status__c from Order WHERE OrderReferenceNumber = 'HOA020202'];
        System.runAs(objMHEuser){
            OrderFieldPopulator ofp = new OrderFieldPopulator();
            ofp.restrictUpdatesOnApprovedMHEOrders(new Map<Id, Order>(newOrder),new Map<Id, Order>(newOrder));
            
        }        
        Test.stopTest();
    }
    
    
    
    /*------------------------------------------------------------------------
Author     :  Srinivasa Angaluri
Date       :  03/08/2022
Description:  Test  Method for updateStockFileRemainingQuantity to update the stock file remaining quantity.
Inputs     :  
----------------------------------------------------------------------------   
@isTest
public static void updateStockFileRemainingQuantityTest1() {
List<Order> orderRecords = new List<Order>();
User objUser = [Select id from User WHERE username = 'sample@godrej.com'];

System.runAs(objUser){
String query = QueryBuilder.build(GlobalConstants.ORDER_SOBJECT_API_NAME,'',false);
system.debug('query SID : '+query);
orderRecords = Database.query(query);

PriceBook2 standardPriceBook = new PriceBook2(Id = Test.getStandardPricebookId(), LN_PriceList_Code__c = 'ST1', PriceList_Code__c = 'ST1');
update standardPriceBook;

PriceBook2 contractPriceBook = new PriceBook2(Name='COM', IsActive = true, LN_PriceList_Code__c = 'COM', PriceList_Code__c = 'COM');
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
Order newOrder = new Order( Logistics_Company_Branch__c = '3010', Stock_File_Reference_Number__c = 'STK-001',                 
Line_of_Business__c = 'E&P',                            
Business_Unit__c = 'W', Sub_Division__c = 'B2C',EffectiveDate = System.today(),Status = 'Draft',
AccountId = orderRecords[0].AccountId, 
RecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('Direct_Billing_Order_Appliances').getRecordTypeId());
insert newOrder;
List<OrderItem> allOLI = new List<OrderItem> {
new OrderItem(OrderId = newOrder.Id, Quantity  = 1, PriceBookEntryId = standardPriceBook.Id ),
new OrderItem(OrderId = newOrder.Id, Quantity  = 1, PriceBookEntryId = standardPriceBook.Id )
};
insert allOLI;
Stock_File__c stockFileRec = new Stock_File__c(Quantity__c = '2',ListPrice__c= 20.22,Name = 'Test File',
Item_Code__c='1234567891',Remaining_Quantity_Available__c=3);
List<Stock_File__c> stkfile = [Select Id, Quantity__c, Stockfile_Number__c, ListPrice__c, Name, Item_Code__c,Remaining_Quantity_Available__c from Stock_File__c  where Stockfile_Number__c =:newOrder.Stock_File_Reference_Number__c]; 

}
}   */
    
    /*------------------------------------------------------------------------
Author     :  Alpana
Date       :  06/10/2022
Description:  Test  Method for orderRecordLockedValidation to skip validation for Integration user and MHE Outright sales users.
Inputs     :  Map<Id, Order> mapNewOrderRecords, Map<Id, Order> mapOldOrderRecords)
Jira/OTRS  :  #SMEPB-46[SMF-83]
-----------------------------------------------------------------------------*/ 
    @isTest private static void verifyOrderRecordLockedValidationTest(){         
        User objMHEuser = [Select id, Account__c from User WHERE username = 'objMHEuser@godrej.com'];
        List<Order> newOrderRecord = [Select id, Integration_Status__c, Business_Unit__c , MHE_Division__c,mr_type__c,
                                      Approval_Status__c from Order WHERE OrderReferenceNumber = 'KOA000101'];
        /*List<OrderItem> orderItemList = new List<OrderItem> {
new OrderItem(OrderId = newOrderRecord[0].Id, Quantity  = 1, Order_Line_Status__c='Print Sales Order Acknowledgements/RMAs' ),
new OrderItem(OrderId = newOrderRecord[0].Id, Quantity  = 1, Order_Line_Status__c='Print Sales Order Acknowledgements/RMAs' )
};


insert orderItemList;*/
        System.runAs(objMHEuser){
            OrderFieldPopulator ofp = new OrderFieldPopulator();
            Test.startTest();
            ofp.orderRecordLockedValidation(new Map<Id, Order>(newOrderRecord ),new Map<Id, Order>(newOrderRecord)); 
            Test.stopTest();
        }        
    }
    /*------------------------------------------------------------------------
Author     :  Pankaj Meshram
Date       :  07/12/2022
Description:  Test  Method for Mhe equipment validation which is thorwn while updating warehouse,salesoffice,orderType and delivery term
 
----------------------------------------------------------------------------  */
	@isTest 
	private static void mheOrderValidationRuleTestMethod1(){         
        User objMHEuser = [Select id, Account__c from User WHERE username = 'objMHEuser@godrej.com'];
        Order newOrderRecord = [Select id,Logistics_Company_Branch__c,Delivery_Terms__c,type from Order WHERE OrderReferenceNumber = 'HOA020202'];
     	
     	System.runAs(objMHEuser){
         	newOrderRecord.Logistics_Company_Branch__c = '2000'; 
            newOrderRecord.Type = 'NOF';
            newOrderRecord.Delivery_Terms__c = 'EW3';
            try{
            	update newOrderRecord;
            }
            catch(Exception e)
            {
                String message = e.getMessage();
                system.assert(message.contains('Please select correct Order Type/ delivery terms.'), 'message=' + message);
                
            }
     	}     
 }
    
    @isTest 
    private static void mheOrderValidationRuleTestMethod2(){         
        User objMHEuser = [Select id, Account__c from User WHERE username = 'objMHEuser@godrej.com'];
        Order newOrderRecord = [Select id,Logistics_Company_Branch__c,Delivery_Terms__c,type from Order WHERE OrderReferenceNumber = 'HOA020202'];
     	
     	System.runAs(objMHEuser){
         	newOrderRecord.Logistics_Company_Branch__c = '2000'; 
            newOrderRecord.Type = 'NOR';
            newOrderRecord.Delivery_Terms__c = 'EW3';
            try{
            	update newOrderRecord;
            }
            catch(Exception e)
            {
                String message = e.getMessage();
                system.assert(message.contains('Please select correct Order Type/ delivery terms.'), 'message=' + message);
                
            }
     	}
     
 }
     @isTest 
    private static void mheOrderValidationRuleTestMethod3(){         
        User objMHEuser = [Select id, Account__c from User WHERE username = 'objMHEuser@godrej.com'];
        Order newOrderRecord = [Select id,Logistics_Company_Branch__c,Delivery_Terms__c,type from Order WHERE OrderReferenceNumber = 'HOA020202'];
     	
     	System.runAs(objMHEuser){            
            List<Warehouse__c> warehouseRecords = createWarehouseRecords();
            insert warehouseRecords;
            
         	newOrderRecord.WarehouseCode__c = warehouseRecords[0].id;
            newOrderRecord.Logistics_Company_Branch__c = '2000'; 
            Sales_Office__c salesOffice = insertSalesOffice();
            newOrderRecord.Sales_Office__c = salesOffice.id;
            newOrderRecord.Type = 'NOF';
            newOrderRecord.Delivery_Terms__c = 'EW1';            
            try{
            	update newOrderRecord;
            }
            catch(Exception e)
            {
                String message = e.getMessage();
                system.assert(message.contains('Please select Warehouse (KAF11S)/ Sales office (MHE Mum PL 16 - Sales Off).'), 'message=' + message);
                
            }
     	}
     
 }
    @isTest 
    private static void mheOrderValidationRuleTestMethod4(){         
        User objMHEuser = [Select id, Account__c from User WHERE username = 'objMHEuser@godrej.com'];
        Order newOrderRecord = [Select id,Logistics_Company_Branch__c,Delivery_Terms__c,type from Order WHERE OrderReferenceNumber = 'HOA020202'];
     	
     	System.runAs(objMHEuser){            
            List<Warehouse__c> warehouseRecords = createWarehouseRecords();
            insert warehouseRecords;
            
         	newOrderRecord.WarehouseCode__c = warehouseRecords[0].id;
            newOrderRecord.Logistics_Company_Branch__c = '2010'; 
            Sales_Office__c salesOffice = insertSalesOffice();
            newOrderRecord.Sales_Office__c = salesOffice.id;
            newOrderRecord.Type = 'NOR';
            newOrderRecord.Delivery_Terms__c = 'EW5';            
            try{
            	update newOrderRecord;
            }
            catch(Exception e)
            {
                String message = e.getMessage();
                system.assert(message.contains('Please select Warehouse (KBF11S)/ Sales office (MHE Sai-Dhara PL - Sales Off).'), 'message=' + message);
                
            }
     	}
     
 }
 private static List<Warehouse__c> createWarehouseRecords() {
        List<Warehouse__c> warehouseRecordList = new List<Warehouse__c>();

        Warehouse__c warehouseRecord1 = new Warehouse__c();
        warehouseRecord1.Channel__c = 'VAS';
        warehouseRecord1.Channel_Type__c = 'Institution';
        warehouseRecord1.Hub__c = 'North Hub';
        warehouseRecord1.Logistic_Company__c = '2000';
        warehouseRecord1.Stock_Category__c = 'Finished Goods -Branches';
        warehouseRecord1.Warehouse__c = 'KBF11s';
        warehouseRecord1.Zone__c = 'North Hub';
        warehouseRecordList.add(warehouseRecord1);

        Warehouse__c warehouseRecord2 = new Warehouse__c();
        warehouseRecord2.Channel__c = 'DST';
        warehouseRecord2.Channel_Type__c = 'Institution';
        warehouseRecord2.Hub__c = 'South Hub';
        warehouseRecord2.Logistic_Company__c = '2010';
        warehouseRecord2.Stock_Category__c = 'Finished Goods Manufactured Plant';
        warehouseRecord2.Warehouse__c = 'KAF11S';
        warehouseRecord2.Zone__c = 'South Hub';
        warehouseRecordList.add(warehouseRecord2);

        return warehouseRecordList;
    }    
    public static Sales_Office__c insertSalesOffice(){
        Sales_Office__c salesoffice=new Sales_Office__c();
        salesoffice.Name='test Sales Office';
        salesoffice.LN_Sales_Office_Code__c='AB1';
        salesoffice.Sales_Office_Code__c='AB1';
        insert salesoffice;
        return salesoffice;
    }
    //end by pankaj
    
    //Added calcualteOrderAmountTest method by Shreela on 4th April 2023
    private static void calcualteOrderAmountTest () {
        User applUser = [Select id, Account__c FROM User WHERE username = 'applSalesUser@godrej.com'];
        Order applOrder = [select Id,QuoteId,Business_unit__c FROM Order WHERE Business_unit__c='H' Limit 1];
        Map<Id,Order> oldOrderMap = new Map<Id,Order>();
        oldOrderMap.put(applOrder.Id,applOrder);
     	
     	System.runAs(applUser){
            
            //Get standart price book
            Pricebook2 standardPricebook = new Pricebook2(Id = Test.getStandardPricebookId(),IsActive = true,PriceList_Code__c='123',LN_PriceList_Code__c='456');
            Update standardPricebook;
            
            //insert product
            Product2 product = new Product2(Name = 'test product', Family = 'Mobile',Item__c='mob123',Is_Generic_Product__c=true);
            Insert product;
            
            //insert orderLineItem
            OrderItem lineItem=new OrderItem();
            lineItem.Product2Id=product.Id;
            lineItem.Quantity=1;
            lineItem.OrderId=applOrder.Id;
            lineItem.PricebookEntryId=[Select Id From PriceBookEntry Limit 1].Id;
            lineItem.UnitPrice=30;
            lineItem.Price_origin__c= 'extern';
            insert lineItem;
            
            List<Order> newOrders = new List<Order>();
            newOrders.add(applOrder);
             
            OrderFieldPopulator ofp = new OrderFieldPopulator();
            ofp.calculateOrderAmount(newOrders, oldOrderMap);
            
            System.assertEquals(lineItem.OrderId,newOrders[0].Id);
            
        }
   
    }   
}