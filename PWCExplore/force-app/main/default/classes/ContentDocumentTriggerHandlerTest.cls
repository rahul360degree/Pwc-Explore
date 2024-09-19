@isTest
private class ContentDocumentTriggerHandlerTest {
    @TestSetup static void createData(){
        
        //Added by Profile and User Shreela on 16th March 2023
        Profile userProfile = [Select Id from Profile where Name = 'PES Sales And Marketing User' LIMIT 1];
        // Create User record.
        User userToRun = new User(EmailEncodingKey = 'UTF-8', firstName = 'Test', lastname = 'PES User', Alias = 'tpesuser',
                                  languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = userProfile.id,
                                  timezonesidkey = 'Asia/Kolkata', email = 'test.pesuser@godrej.com', username = 'test.pesuser@godrej.com', Business_Unit__c = GlobalConstants.PES_BUSINESS_UNIT);
        
        insert userToRun;

        
        //Create Account
        Account newAccount = new Account( FirstName = 'Test', LastName ='Person Account', PersonEmail = 'test@invalid.com', 
                                    RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Customer').getRecordTypeId());
        insert newAccount;
        
        //Create Business Account for SMEPB - 119 by Shreela on 18th Sept 2023
        Account newAccount2 = new Account( Name = 'Test Business Account', 
                                    RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business_Account').getRecordTypeId(),
                                    Business_Unit__c = GlobalConstants.BUSINESS_UNIT_MHE_DIVISION);
        insert newAccount2;
        
        //Create Order 
        Order newOrder = new Order( Logistics_Company_Branch__c = '3010',                  
                                    Line_of_Business__c = 'E&P',                               
                                    Business_Unit__c = 'W', Sub_Division__c = 'B2C',                                                
                                    Area__c = 'EA2',Planned_Delivery_Date__c = Datetime.now().addDays(10),  
                                    EffectiveDate = Date.today(),                             
                                    Status = GlobalConstants.ORDER_DEFAULT_STATUS,
                                    AccountId = newAccount.Id);
        insert newOrder;
        
        //Create BSO Record by Shreela on 18th Sept 2023 for SMEPB- 113
        Billed_Sales_Outstandings__c bsoRecord = new TestBilledSalesOutstandingsBuilder().setAccount(newAccount2.Id).setBusinessUnit(GlobalConstants.BUSINESS_UNIT_MHE_DIVISION).getSavedTestRecord();

        
       ContentVersion contentVersion = new ContentVersion( Title = 'Penguins', PathOnClient = 'Penguins.jpg',
                                                            VersionData = Blob.valueOf('Test Content'),
                                                            IsMajorVersion = true); 
       insert contentVersion;
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];

        //create ContentDocumentLink  record 
        ContentDocumentLink cdl = New ContentDocumentLink();
        cdl.LinkedEntityId = newOrder.Id;
        cdl.ContentDocumentId = documents[0].Id;
        cdl.shareType = 'V';
        insert cdl; 
        
        //create ContentDocumentLink  record for MHE BSO Record for SMEPM - 113 by Shreela
        ContentDocumentLink cdl2 = New ContentDocumentLink();
        cdl2.LinkedEntityId = bsoRecord.Id;
        cdl2.ContentDocumentId = documents[0].Id;
        cdl2.shareType = 'V';
        insert cdl2; 
        
        
    }
    
    @isTest private static void uploadAttachmentToOrder(){
        Test.startTest();
        
        
        
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
        
        ContentVersion contentVersion = new ContentVersion( Title = 'Penguins', PathOnClient = 'Penguins.jpg',
                                                            VersionData = Blob.valueOf('Test Content'),
                                                            IsMajorVersion = true, ContentDocumentId = documents[0].Id);
        insert contentVersion;        

        Order getOrder = [Select Id,Has_Attachment__c FROM Order];
        System.assertEquals(getOrder.Has_Attachment__c, TRUE);
        
        Test.stopTest();
    }

    @isTest private static void deleteAttachmentToOrder(){
        Test.startTest();
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
        delete documents;

        List<ContentVersion> cvs = [Select Id FROM ContentVersion];
        /*ContentVersion cvs = new ContentVersion( Title = 'Penguins', PathOnClient = 'Penguins.jpg',
                                                            VersionData = Blob.valueOf('Test Content'),
                                                            IsMajorVersion = true, ContentDocumentId = documents[0].Id); */
        System.assertEquals(0,cvs.size());
        Test.stopTest();
    }

    @isTest private static void deletingAttachmentLinkedToAttendanceShouldReturnError(){
        ContentDocument documentRec = [SELECT Id FROM ContentDocument];
        Attendance__c attendanceRec = new TestAttendanceBuilder().setTypeValue('Leave').setApprover(Userinfo.getUserId()).setStartOfDayTime(System.now()).setEndOfDayTime(System.now().addHours(1)).getSavedTestRecord();
        System.debug(attendanceRec);
        System.debug(attendanceRec);
        ContentDocumentLink documentLink = new ContentDocumentLink(LinkedEntityId = attendanceRec.Id, ContentDocumentId = documentRec.Id, ShareType = 'V');
        insert documentLink;
        String errorMessage = '';
        try {
            Test.startTest();
            delete documentRec;
            Test.stopTest();
        } catch (Exception ex) {
            errorMessage = ex.getMessage();
        }
        System.assertEquals(true, errorMessage.contains(Label.Attendance_Attachment_Delete_Error), 'Deleting image tagged to attendance did not return any errors');
    }
    
    @isTest private static void sendEmailonInsertionofAttachmentTest(){
        User userToRun = [Select Id,Name,Username FROM User Where username = 'test.pesuser@godrej.com' AND Profile.Name = 'PES Sales And Marketing User' LIMIT 1];
        
        System.runAs(userToRun) {
            
         //Create Lead - By Shreela Nair on 16th March 2023
        Lead pesLeadRec = new Lead();
        pesLeadRec.FirstName = 'Test';
        pesLeadRec.LastName='Lead 1';
        pesLeadRec.PES_Sector__c = 'General Engineering';
        pesLeadRec.Email = 'test@gmail.com';
        pesLeadRec.RecordTypeId = (RecordTypeUtils.getInstance()).getRecordTypeId('Lead', 'PES_Lead');
        pesLeadRec.Business_Unit__c = GlobalConstants.PES_BUSINESS_UNIT;
        pesLeadRec.List_of_Email_Ids__c = 'test123@gmail.com,test234@gmail.com';
        insert pesLeadRec;

         //Create Opportunity - By Shreela Nair on 17th May 2023 for SPEP-3
        Opportunity pesOppRec = new Opportunity();
        pesOppRec.Name = 'Test Opportunity 1';
        pesOppRec.Sector__c ='Defence';
        pesOppRec.Firm_BQ__c = 'BQ';
        pesOppRec.Opportunity_No__c = 'GPE/BQ/D/2324/4';
        pesOppRec.RecordTypeId = (RecordTypeUtils.getInstance()).getRecordTypeId('Opportunity', 'PES');
        pesOppRec.Business_Unit__c = GlobalConstants.PES_BUSINESS_UNIT;
        pesOppRec.StageName = 'In Process';
        pesOppRec.CloseDate = System.today();
        insert pesOppRec;    
            
         Test.startTest();
         ContentVersion contentVersion = new ContentVersion( Title = 'Penguins', PathOnClient = 'Penguins.jpg',
                                                            VersionData = Blob.valueOf('Test Content'),
                                                            IsMajorVersion = true); 
        insert contentVersion; 
            
        //Added by Shreela on 18th May 2023 for SPEP-7 & SPEP-8
         ContentVersion contentVersion2 = new ContentVersion( Title = 'Test Title', PathOnClient = 'Test Title.snote',
                                                            VersionData = Blob.valueOf('Test Content'),
                                                            IsMajorVersion = false); 
        insert contentVersion2;     

        List<ContentDocument> documentRec = [SELECT Id FROM ContentDocument];
        Map<Id, ContentDocumentLink> clthMap = new Map<Id,ContentDocumentLink>();
        ContentDocumentLink documentLink = new ContentDocumentLink(LinkedEntityId =pesLeadRec.Id, ContentDocumentId = documentRec[0].Id, ShareType = 'V');
        insert documentLink;
        
        //Added by Shreela on 17th May 2023 for SPEP-3
        ContentDocumentLink documentLink2 = new ContentDocumentLink(LinkedEntityId =pesOppRec.Id, ContentDocumentId = documentRec[0].Id, ShareType = 'V');
        insert documentLink2;
            
        //Added by Shreela on 18th May 2023  for SPEP-7 & SPEP-8  
        ContentDocumentLink documentLink3 = new ContentDocumentLink(LinkedEntityId =pesLeadRec.Id, ContentDocumentId = documentRec[1].Id, ShareType = 'V');
        insert documentLink3;
        
        //Added by Shreela on 18th May 2023 for SPEP-7 & SPEP-8
        ContentDocumentLink documentLink4 = new ContentDocumentLink(LinkedEntityId =pesOppRec.Id, ContentDocumentId = documentRec[1].Id, ShareType = 'V');
        insert documentLink4;
            
        clthMap.put(documentLink.Id,documentLink);
        clthMap.put(documentLink2.Id,documentLink2); //Added by Shreela on 17th May 2023 for SPEP-3
        clthMap.put(documentLink3.Id,documentLink3); //Added by Shreela on 18th May 2023 for SPEP-7 & SPEP-8
        clthMap.put(documentLink4.Id,documentLink4); //Added by Shreela on 18th May 2023 for SPEP-7 & SPEP-8
            
        ContentDocumentLinkTriggerHelper clth = new ContentDocumentLinkTriggerHelper();
        clth.sendEmailonInsertionofAttachmentandNotes(clthMap);
        
        Test.stopTest();
        System.assertEquals(documentLink, clthMap.get(documentLink.Id));
        }    
        
    }
    
    //Added by Shreela on 18th Sept 2023 for SMEPB-119
    @isTest private static void setVisibilityOfBSOFilesForExternalUsersTest(){
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
        
        List<ContentDocumentLink> cdlList = [SELECT Id,LinkedEntityId,ContentDocumentId,ShareType
                                            FROM ContentDocumentLink 
                                            WHERE ContentDocumentId =: documents[0].Id];
        
        ContentDocumentLinkTriggerHelper clth = new ContentDocumentLinkTriggerHelper();
        clth.setVisibilityOfBSOFilesForExternalUsers(cdlList);
    }
}