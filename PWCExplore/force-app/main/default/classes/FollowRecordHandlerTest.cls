@isTest
public class FollowRecordHandlerTest {
    
    @TestSetup static void setupUser() {
        Runtime_Execution__c runTimeExecution = new Runtime_Execution__c();
        
        Profile userProfile = [Select Id from Profile where Name =: GlobalConstants.SYSTEM_ADMIN_PROFILE_NAME LIMIT 1];
        UserRole role = [SELECT Id, Name, DeveloperName FROM UserRole WHERE DeveloperName = 'CEO' LIMIT 1];
        // Create User record.
        User userToRun = new User(EmailEncodingKey = 'UTF-8', firstName = 'Test', lastname = 'User', Alias = 'tuser',
                            languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = userProfile.id, UserRoleId = role.Id,
                            timezonesidkey = 'Asia/Kolkata', email = 'test.userAcc@godrej.com',Salary_Code__c =  'QW1', username = 'test.userAcc@godrej.com', Business_Unit__c = 'W'); //added Salary Code by Shreela for Test Class issue resolve on 27th October 2021

        userToRun.IsActive = true;
        userToRun.Allow_Business_Account_Creation__c = true;
        userToRun.Logistic_Company__c = '5010';
        userToRun.Area_Code__c = 'WN1';
        insert userToRun; 
        
        
        System.runAs(userToRun){
            //Create Custom Setting Record for RunTime Execution
             runTimeExecution = new Runtime_Execution__c(Name = 'CaseAssignmentTest', FireCaseValidationRules__c = true,AccountTriggerDisabled__c=true);
            insert runTimeExecution;
            
            Account newAccount = new Account();
            newAccount.Name = 'Test Business Account';
            newAccount.Type = 'Institution';
            newAccount.Business_Unit__c ='G';
            newAccount.Sub_Division__c = 'B2B';
            newAccount.Account_Series__c = 'GIX';
            //newAccount.Account_Series__c = System.Label.Parent_Account_Series;
            newAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business_Account').getRecordTypeId();
            system.debug('newAccount:'+newAccount);
            insert newAccount;
            
            Warehouse__c warehouseRecord1 = new Warehouse__c();
            warehouseRecord1.Channel__c = 'VAS';
            warehouseRecord1.Channel_Type__c = 'Institution';
            warehouseRecord1.Hub__c = 'North Hub';
            warehouseRecord1.Logistic_Company__c = '5010';
            warehouseRecord1.Stock_Category__c = 'Finished Goods -Branches';
            warehouseRecord1.Warehouse__c = 'ZXF001';
            warehouseRecord1.Zone__c = 'North Hub';
            insert warehouseRecord1;
        }
        
    }
    
    @isTest private static void followRecordTest() {
        User contextuser = [Select Id FROM User WHERE username = 'test.userAcc@godrej.com' LIMIT 1];
        System.runAs(contextuser) {
             Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
                    setting.AccountTriggerDisabled__c = true;
                    setting.OrderTriggerDisabled__c = true;
                    setting.ClaimRequestTriggerDisabled__c = true;
                    setting.QuoteTriggerDisabled__c = true;
                    insert setting;
            Test.startTest();
            map<Id, Project_milestone__c> projectMilestones = new map<Id, Project_milestone__c>();
            list<EntitySubscription> ExistingSubs = new list<EntitySubscription>();
            set<Id> recordIds = new set<Id>();
            list<Account> accounts = [SELECT Id,name , Business_Unit__c FROM Account WHERE Name = 'Test Business Account' and Business_Unit__c = 'G' LIMIT 1];
            //list<Account> accounts = [SELECT Id FROM Account WHERE Name = 'Test Business Account' and Business_Unit__c = 'G' LIMIT 1];
            system.debug('list of accounts'+accounts);
			/*Account newAccount_ssg = new Account( Name = 'Test Account', Business_Unit__c = 'G', Type = 'I',Account_Series__c = 'GIX',Sub_Division__c = 'B2B',
                                 RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business_Account').getRecordTypeId());
        insert newAccount_ssg;*/
            Id warehouseid = [Select Id, Warehouse__c FROM Warehouse__c WHERE Warehouse__c = 'ZXF001' LIMIT 1][0].Id;
            Opportunity newSsgOpp = new Opportunity(
                    Name = 'Test ssg Opp',               
                    AccountId = accounts[0].Id, 
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
                	WarehouseCode__c = warehouseid,
                   // Internal_Sales_Rep__c = UserInfo.getUserId(),    
                    Area_Code__c = 'EA1',               
                    Room_Planner_Demo_Done__c = 'No',             
                    Product_Configuration_Demo_Given__c = 'Yes',  
                    Exchange_Order__c = 'No',                     
                    RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('SSG').getRecordTypeId());
    
                insert newSsgOpp;       
            Quote newSsgQuote = new Quote(
                    Name = 'Test Quote',                 
                   // Opportunity_Owner__c = UserInfo.getUserId(),         
                    Status = 'Draft',                             
                    OpportunityId = newSsgOpp.Id,                
                    Approval_Status__c = 'Approval Not Required',     
                    ExpirationDate = Date.today().addDays(20),      
                    Area_Code__c = 'EA1',
                 	WarehouseCode__c = null,
                    Quote_Type__c = 'Customer Facing',Scope_of_Installation__c = 'Dealer');
                   
                insert newSsgQuote;
             //Create Order record
            Order newOrder_ssg = new Order( Logistics_Company_Branch__c = '1300',                  
                                                Line_of_Business__c = 'ENGG',                              
                                                Business_Unit__c = 'G', Sub_Division__c = 'B2B',   
                                                Planned_Delivery_Date__c=system.today(),Planned_Receipt_Date__c=system.today(),
                                                AccountId = accounts[0].Id,EffectiveDate = System.today(),Status = 'Draft',Installation_Scope__c=newSsgQuote.Scope_of_Installation__c,
                                                QuoteId=newSsgQuote.id,
                                                RecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('SSG_Primary').getRecordTypeId());
            insert newOrder_ssg;  
            //Create Case record
            Case caseRecord = new Case();
            caseRecord.AccountId = accounts[0].Id;
            caseRecord.Origin = 'Manual';
            caseRecord.Status = 'New';
            caseRecord.Priority = 'Medium';
            caseRecord.Email__c = 'caseRec1@sr.com';
            caseRecord.Mobile__c = '9087654391';
            caseRecord.Execution_Branch__c = 'Delhi'; //added by Shreela for Test Class issue resolve on 27th October 2021
            caseRecord.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('SSG_Service_Request').getRecordTypeId();
            caseRecord.Order__c = newOrder_ssg.Id;
            caseRecord.No_material_Supply__c = 'Yes';
            insert caseRecord;
            recordIds.add(caseRecord.Id);
            
            //Fetch the created Milestone records
            projectMilestones = new map<Id, Project_milestone__c>([SELECT Id FROM Project_milestone__c 
                                                                   							WHERE Service_Request__c =: caseRecord.Id]);
            recordIds.addAll(projectMilestones.keyset());
            
            FollowRecordHandler.followRecord(caseRecord.Id);
            
            ExistingSubs = [SELECT Id, parentId FROM EntitySubscription 
                                                WHERE parentId IN : recordIds 
                                              	AND subscriberid =: userInfo.getUserId()];
            system.assertEquals(recordIds.size(), ExistingSubs.size());
            Test.stopTest();
        }
    }
    
    @isTest private static void unfollowRecordTest() {
        User contextuser = [Select Id FROM User WHERE username = 'test.userAcc@godrej.com' LIMIT 1];
        System.runAs(contextuser) {
             Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
                    setting.AccountTriggerDisabled__c = true;
                    setting.OrderTriggerDisabled__c = true;
                    setting.ClaimRequestTriggerDisabled__c = true;
                    setting.QuoteTriggerDisabled__c = true;
                    insert setting;
            Test.startTest();
            map<Id, Project_milestone__c> projectMilestones = new map<Id, Project_milestone__c>();
            list<EntitySubscription> ExistingSubs = new list<EntitySubscription>();
            set<Id> recordIds = new set<Id>();
            
            list<Account> accounts = [SELECT Id FROM Account WHERE Name = 'Test Business Account' LIMIT 1];
            Order newOrder_ssg = new Order( Logistics_Company_Branch__c = '1300',                  
                                 Line_of_Business__c = 'ENGG',                              
                                 Business_Unit__c = 'G', Sub_Division__c = 'B2B',   
                                 Planned_Delivery_Date__c=system.today(),Planned_Receipt_Date__c=system.today(),
                                 AccountId = accounts[0].Id,EffectiveDate = System.today(),Status = 'Draft',
                                 RecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('SSG_Primary').getRecordTypeId());
            insert newOrder_ssg; 
            //Create Case record
            Case caseRecord = new Case();
            caseRecord.AccountId = accounts[0].Id;
            caseRecord.Origin = 'Manual';
            caseRecord.Status = 'New';
            caseRecord.Priority = 'Medium';
            caseRecord.Email__c = 'caseRec@sr.com';
            caseRecord.Mobile__c = '9087654321';
            caseRecord.Execution_Branch__c = 'Delhi'; //added by Shreela for Test Class issue resolve on 27th October 2021
            caseRecord.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('SSG_Service_Request').getRecordTypeId();
            caseRecord.Order__c = newOrder_ssg.Id;
            caseRecord.No_material_Supply__c='Yes';
            insert caseRecord;
            recordIds.add(caseRecord.Id);
            
            //Fetch the created Milestone records
            projectMilestones = new map<Id, Project_milestone__c>([SELECT Id FROM Project_milestone__c 
                                                                   							WHERE Service_Request__c =: caseRecord.Id]);
            recordIds.addAll(projectMilestones.keyset());
            
            FollowRecordHandler.unfollowRecord(caseRecord.Id);
            
            ExistingSubs = [SELECT Id, parentId FROM EntitySubscription 
                                                WHERE parentId IN : recordIds 
                                              	AND subscriberid =: userInfo.getUserId()];
            system.assertEquals(0, ExistingSubs.size());
            Test.stopTest();
        }
    }
}