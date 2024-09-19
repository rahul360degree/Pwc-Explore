/**
 * @description       : 
 * @author            : vrajpoot@godrej.com
 * @group             : 
 * @last modified on  : 03-07-2023
 * @last modified by  : vrajpoot@godrej.com
**/
@isTest
public class StatementofAccountTest {   
    @testsetup
    public static void testData() {
        //User creation L1, L2 and DSA User
        Profile appliancesUser = [Select Id from Profile where Name = 'Appliances Sales User' LIMIT 1];
        Profile adminProfile = [Select Id from Profile where Name =: GlobalConstants.SYSTEM_ADMIN_PROFILE_NAME LIMIT 1];        
        List<User> userToInsert = new List<User>();
        
        User L2User = new User(EmailEncodingKey = 'UTF-8', firstName = 'Test', lastname = 'User', Alias = 'tuser',
                               languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = adminProfile.id,
                               timezonesidkey = 'Asia/Kolkata', email = 'test.user@godrej.com', 
                               username = 'l2@user@godrej.com', Business_Unit__c = 'H',Logistic_Company__c = '2000',
                               Area_Code__c = 'WN1',salary_code__c='123L2');
        userToInsert.add(L2User);
        
        User userManager = new User(EmailEncodingKey = 'UTF-8', firstName = 'Test', lastname = 'User', Alias = 'tuser',
                                    languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = adminProfile.id,
                                    timezonesidkey = 'Asia/Kolkata', email = 'test.userManager@godrej.com', username = 'test.userManager@godrej.com', Business_Unit__c = 'H',
                                    IsActive = true,Allow_Business_Account_Creation__c = false,Logistic_Company__c = '2000',
                                    Area_Code__c = 'WN1'
                                   );
        userToInsert.add(userManager);
        
        User user = new User(EmailEncodingKey = 'UTF-8', firstName = 'Test', lastname = 'User', Alias = 'tuser',
                             languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = appliancesUser.id,
                             timezonesidkey = 'Asia/Kolkata', email = 'test.user@godrej.com', 
                             username = 'testPartner.user@godrej.com', 
                             Business_Unit__c = 'H',Logistic_Company__c = '2000',Area_Code__c = 'WN1',salary_code__c='123',
                             ManagerId = userManager.Id
                            );     
        userToInsert.add(user);
        insert userToInsert;
        //Update Manager of the records
        userManager.ManagerId = [Select Id from User where UserName=:'l2@user@godrej.com'][0].Id;
        user.ManagerId = [Select Id from User where UserName=:'test.userManager@godrej.com'][0].Id;
        update userToInsert;
        System.debug([Select Id,managerId,Manager.ManagerId from User]);
        //Account Creation
        Account accountRecord2 = new Account(LastName='Test Account1', PersonMobilePhone='7902112112',Business_Unit__c = 'H',
                                             Account_Code__c = 'HDX_0001',PersonEmail='invalid1@test.com',DSA_Automation_Level__c = 'Full',
                                             DSA_Contact_User__c = user.Id,
                                             ownerId=user.Id
                                            );
        insert accountRecord2;
        
        createTestSOARecord();
    }
    
    
    private static void createTestSOARecord(){
        string strCalendarMonth = (System.now().addMonths(-1) ).Format('MMMM');
        Date dtToday = Date.Today().addMonths(-1);
        integer intCalendarYear = dtToday.Year();
        integer intCalendarMonth = dtToday.Month();
        integer intPeriodYear = intCalendarMonth >= 4 ? (intCalendarYear+1) : intCalendarYear;
        integer intPeriodMonth = intCalendarMonth >=4 ? (intCalendarMonth - 3) : (9 + intCalendarMonth);
            
            Account acn = Database.query('SELECT Id, Name, OwnerId,Owner.ManagerId,Owner.Manager.ManagerId, DSA_Contact_User__c, Account_Code__c,Primary_Address__r.ZipCode__r.CityCode__c '
                                         +'FROM Account where Account_Code__c like \'HDX%\' and DSA_Automation_Level__c IN(\'Email\',\'Full\')');
        Statement_Of_Account__c soa = new Statement_Of_Account__c();
        soa.Account__c = acn.Id;                    
        soa.Name = 'DSA for ' + acn.Name + ' for ' + strCalendarMonth + ' ' + intCalendarYear ;
        //soa.OwnerId = acn.DSA_Contact_User__c;
        soa.OwnerId = acn.OwnerId;
        soa.Calendar_Month__c = strCalendarMonth;
        soa.Calendar_Year__c = intCalendarYear;
        soa.Period_Month__c = intPeriodMonth;
        soa.Period_Year__c = intPeriodYear;
        soa.DSA_External_Key__c = acn.Account_Code__c + '_' + intPeriodYear + '_' + (intPeriodMonth<10 ? '0' + String.valueOf(intPeriodMonth) : String.valueOf(intPeriodMonth));
        soa.Business_Unit__c = (acn.Account_Code__c).substring(0,1);
        soa.Area_Sales_Manager__c = acn.OwnerId;
        if(acn.Owner.ManagerId <> null)
            soa.ASM_Manager__c = acn.Owner.ManagerId;//ASM L+1        
        if(acn.Owner.ManagerId <> null && acn.Owner.Manager.ManagerId <>null)
            soa.ASM_s_L_2__c = acn.Owner.Manager.ManagerId; //ASM L+2
        insert soa;
    }



    private static void createAttachementRecord(Id soaId){
        Blob bodyBlob=Blob.valueOf('Dummy Body'); 
        ContentVersion contentVersion = new ContentVersion(
            Title='SOA.pdf', 
            PathOnClient ='SampleTitle.pdf',
            VersionData = bodyBlob, 
            origin = 'H'
        );
        insert contentVersion;  
        //code to cover ContentDocumentLinkTrigger and it's helper        
        ContentDocumentLink contentlink = new ContentDocumentLink();
        contentlink.LinkedEntityId = soaId ;
        contentlink.contentdocumentid = [Select contentdocumentid from contentVersion where Id=:contentVersion.Id].contentdocumentid;
        contentlink.ShareType = 'V';
        insert contentlink;
    }

    //This method covers batch and its helper
    @isTest private static void SOAGeneratorBatchTest(){
        User user = [Select Id,managerId,Manager.ManagerId from User where username='testPartner.user@godrej.com'];
        System.runAs(user){
            test.startTest();
            // SOAGeneratorBatch sh1 = new SOAGeneratorBatch();            
            // String sch = '0 0 23 * * ?'; 
            // System.Schedule('Generate SOA', sch, sh1);
            // //DSA_Attachment.getAttchments();
            test.stopTest();            
        }
        
    }
    //Insert the attachments to cover trigger
    @isTest private static void contentDocumentLinkTriggerTest(){
        Statement_Of_Account__c soaRec = [Select Id from Statement_Of_Account__c limit 1];
        
        createAttachementRecord(soaRec.Id);
        //SOAEmailBatchTest
        soaRec.Status__c = 'Statements Attached';
        update soaRec;
        
        test.startTest();
        // SOAEmailBatch sh1 = new SOAEmailBatch();//Execute Scenario for Full level            
        // String sch = '0 0 23 * * ?'; 
        // System.Schedule('Email SOA', sch, sh1);
        // System.assertEquals(1,[Select Id from Statement_Of_Account__c].size());
        test.stopTest();
    }
    
        //Insert the attachments to cover trigger
        @isTest private static void SOAEmailBatchEmailLevelTest(){
            
            Statement_Of_Account__c soaRec = [Select Id,Account__c from Statement_Of_Account__c limit 1];            
            
            createAttachementRecord(soaRec.Id);
            //SOAEmailBatchTest
            soaRec.Status__c = 'Statements Attached';
            update soaRec;
            
            Account acn = new Account(Id = soaRec.Account__c,DSA_Automation_Level__c='Email');
            update acn;

            test.startTest();
            // SOAEmailBatch sh1 = new SOAEmailBatch();//Execute Scenario for Full level            
            // String sch = '0 0 23 * * ?'; 
            // System.Schedule('Email SOA', sch, sh1);
            System.assertEquals(1,[Select Id from Statement_Of_Account__c].size());
            test.stopTest();
        }

//Insert the attachments to cover trigger
@isTest private static void SOAEmailBatchMismatchLevelTest(){
            
    Statement_Of_Account__c soaRec = [Select Id,Account__c from Statement_Of_Account__c limit 1];            
    
    createAttachementRecord(soaRec.Id);
    //SOAEmailBatchTest
    soaRec.Status__c = 'Statements Attached';
    soaRec.Mismatch__c = true;
    update soaRec;


    test.startTest();
    // SOAEmailBatch sh1 = new SOAEmailBatch();//Execute Scenario for Full level            
    // String sch = '0 0 23 * * ?'; 
    // System.Schedule('Email SOA', sch, sh1);
    System.assertEquals(1,[Select Id from Statement_Of_Account__c].size());
    test.stopTest();
}

    //To cover DSA_Attachment Class
    @isTest private static void DSA_Attachment_Test(){
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments( 'Submitting request for approval' );
        req1.setObjectId([Select Id from Statement_Of_Account__c limit 1].Id );
        req1.setNextApproverIds(new Id[] {UserInfo.getUserId()});
        Approval.ProcessResult result = Approval.process( req1 );
        
        String objectName = 'Statement_Of_Account__c';
        String query='SELECT Id '
            +' from ProcessInstanceWorkitem'
            +' where '
            +'ProcessInstance.TargetObject.Type  =: objectName ' 
            + '  limit 100';
        List<ProcessInstanceWorkitem> processItems= Database.query(query);
        if(!processItems.isEmpty()){
            DSA_Attachment.getAttchments(processItems[0].Id);//+ve scenario
            //-ve scenario
            try{
                DSA_Attachment.getAttchments(null);
            }catch(Exception ex){
                System.debug('-ve testing'+ex.getStackTraceString());
            }
        }        
    }    
}