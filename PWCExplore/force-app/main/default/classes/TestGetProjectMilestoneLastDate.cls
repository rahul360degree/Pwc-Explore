@isTest
    private class TestGetProjectMilestoneLastDate {
        static Id bookingRTId = Schema.SObjectType.Project_milestone__c.getRecordTypeInfosByDeveloperName().get(System.label.Project_Milestone_Booking_2_Record_Type).getRecordTypeId();
        static Id designRTId = Schema.SObjectType.Project_milestone__c.getRecordTypeInfosByDeveloperName().get(System.label.Project_Milestone_Design_Clearance_Record_Type).getRecordTypeId();
        static Id ssgRTID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('SSG_Service_Request').getRecordTypeId();
        static Id supplyRTId= Schema.SObjectType.Project_milestone__c.getRecordTypeInfosByDeveloperName().get('Supply_and_Material_Pull_Plan').getRecordTypeId();    
        
        @TestSetup 
            static void createData(){
            Test.startTest(); 
            /*Id bookingRTId = Schema.SObjectType.Project_milestone__c.getRecordTypeInfosByDeveloperName().get(System.label.Project_Milestone_Booking_2_Record_Type).getRecordTypeId();
            Id designRTId = Schema.SObjectType.Project_milestone__c.getRecordTypeInfosByDeveloperName().get(System.label.Project_Milestone_Design_Clearance_Record_Type).getRecordTypeId();
            Id ssgRTID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('SSG_Service_Request').getRecordTypeId();
            Id supplyRTId= Schema.SObjectType.Project_milestone__c.getRecordTypeInfosByDeveloperName().get('Supply_and_Material_Pull_Plan').getRecordTypeId();     */      
            UserRole iaUserRole = new UserRole(Name = 'CEO');
            insert iaUserRole;
            Profile iaProfile = [SELECT Id FROM Profile WHERE Name = 'Integration Administrator' LIMIT 1];
            Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
            User ssg_user = new User(UserRoleId = iaUserRole.Id, ProfileId = iaProfile.Id, 
                                Alias = 'ssg', Email='ssgUser@godrej.com',Salary_Code__c='377337',Business_Unit__c='G',
                                EmailEncodingKey='UTF-8', LastName='Testing_ssg', LanguageLocaleKey='en_US',LocaleSidKey='en_US',
                                TimeZoneSidKey='America/Los_Angeles',Username = 'ssgUser@godrej.com',CommunityNickname = 'test1234567');
            insert ssg_user; 
                
            System.runAs(ssg_user){
                Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
                setting.AccountTriggerDisabled__c = true;
                setting.OrderTriggerDisabled__c = true;
                setting.ClaimRequestTriggerDisabled__c = true;
                setting.QuoteTriggerDisabled__c = true;
            insert setting;
                
            Account acc= new Account();
            acc.Name = 'TestAccount';
            acc.Interio_Sub_Division__c= 'B2B-KAM';
            acc.Business_Unit__c = 'G';
            acc.Type = 'F';
            acc.Account_Series__c = System.Label.Parent_Account_Series;
            insert acc;
                
            Contact contct = new Contact();
            contct.lastName = 'ssgContact';
            contct.Business_Unit__c = 'G';
            contct.MobilePhone = '9809878909';
            contct.Email = 'ssgContactPartner@gmail.com';
            insert contct;
                
            //Added by pankaj on 24 jan 2022 for test failure
            Account partnerAccount = new TestAccountBuilder().setRecordTypeId(Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Dealer')
                .getRecordTypeId()).setBusinessUnit('G').getSavedTestRecord();
           
            Opportunity newSsgOpp = new Opportunity(
                        Name = 'Test ssg Opp',               
                        AccountId = partnerAccount.id, 
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
                       // Internal_Sales_Rep__c = UserInfo.getUserId(),    
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
                        Quote_Type__c = 'Customer Facing',Scope_of_Installation__c = 'Godrej');
                        
                    insert newSsgQuote;
                 //Create Order record
                Order newOrder_ssg = new Order( Logistics_Company_Branch__c = '1300',                  
                                                    Line_of_Business__c = 'ENGG',                              
                                                    Business_Unit__c = 'G', Sub_Division__c = 'B2B',QuoteId=newSsgQuote.id,   
                                                    Planned_Delivery_Date__c=system.today(),Planned_Receipt_Date__c=system.today(),
                                                    AccountId = partnerAccount.id,EffectiveDate = System.today(),Status = 'Draft',Installation_Scope__c=newSsgQuote.Scope_of_Installation__c,
                                               		Internal_Sales_Representative__c = ssg_user.id,sold_to_contact__c=contct.Id,
                                                    RecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('SSG_Primary').getRecordTypeId());
                insert newOrder_ssg;  
    
    
            Case TestPMGeneration = new Case();
            TestPMGeneration.Subject = 'Test SSG Service Request';
            TestPMGeneration.Description = 'Test SSG Service Request';
            TestPMGeneration.AccountId = acc.Id;
            TestPMGeneration.RecordTypeId = ssgRTID;
            TestPMGeneration.Project_Number__c = 'PRN012398';
            TestPMGeneration.No_material_Supply__c='Yes';
            TestPMGeneration.Order__c = newOrder_ssg.id; 
            insert TestPMGeneration;
            }
           Test.stopTest();     
       }
        @isTest 
        private static void getLastDateTest(){
            /*Id bookingRTId = Schema.SObjectType.Project_milestone__c.getRecordTypeInfosByDeveloperName().get(System.label.Project_Milestone_Booking_2_Record_Type).getRecordTypeId();
            Id designRTId = Schema.SObjectType.Project_milestone__c.getRecordTypeInfosByDeveloperName().get(System.label.Project_Milestone_Design_Clearance_Record_Type).getRecordTypeId();
            Id supplyRTId= Schema.SObjectType.Project_milestone__c.getRecordTypeInfosByDeveloperName().get('Supply_and_Material_Pull_Plan').getRecordTypeId();  */         
            case caseObj= [select id from case where Subject = 'Test SSG Service Request'];
            Project_milestone__c pm = [SELECT Id,Foc_Number__c, Start_Date__c, End_Date__c,FOC_Last_synced__c,FOC_End_Date_status__c
                                       from Project_milestone__c WHERE RecordTypeId =: bookingRTId AND Service_Request__r.Subject = 'Test SSG Service Request' LIMIT 1 ];
            System.debug('pm :'+pm.Id);
            //Project_milestone__c spm = [SELECT Id, Start_Date__c, End_Date__c from Project_milestone__c WHERE RecordTypeId =: supplyRTId AND Service_Request__r.Subject = 'Test SSG Service Request' LIMIT 1 ];
            Project_milestone__c spm = new Project_milestone__c();
            spm.RecordTypeId = supplyRTId;
            spm.Service_Request__c = caseObj.id;
            insert spm; 
            pm.FOC_Number__c='GDA000001,HDA000005';
             id pmid=pm.id;
             update pm;
                Test.startTest();
                    Test.setMock(HttpCalloutMock.class, new MockFocResponseGenerator()); 
                    GetProjectMilestoneLastDate.GetLastDate(pmid);
                    Project_milestone__c checkBookingpm=[select FOC_End_Date_status__c from Project_milestone__c where id=:pmid ];
                    system.assertEquals('Success',checkBookingpm.FOC_End_Date_status__c);
              Test.stopTest();
            
        }
        
    }