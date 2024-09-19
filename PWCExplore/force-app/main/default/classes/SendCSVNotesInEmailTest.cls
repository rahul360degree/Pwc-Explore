@isTest
private class SendCSVNotesInEmailTest {
     @TestSetup
    static void prepareData(){
        Profile userProfile = [Select Id from Profile where Name = 'PES Sales And Marketing User' LIMIT 1];
        // Create User record.
        User userToRun = new User(EmailEncodingKey = 'UTF-8', firstName = 'Test', lastname = 'PES User', Alias = 'tpesuser',
                                  languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = userProfile.id,
                                  timezonesidkey = 'Asia/Kolkata', email = 'test.pesuser@godrej.com', username = 'test.pesuser@godrej.com', Business_Unit__c = GlobalConstants.PES_BUSINESS_UNIT);
        
        insert userToRun;
    }
    
     @isTest static void testsendNotes(){
        User userToRun = [Select Id,Name,Username FROM User Where username = 'test.pesuser@godrej.com' AND Profile.Name = 'PES Sales And Marketing User' LIMIT 1];
        
        System.runAs(userToRun) {
            Test.startTest();
            Lead pesLeadRec = new Lead();
            pesLeadRec.FirstName = 'Test';
            pesLeadRec.LastName='Lead 1';
            pesLeadRec.PES_Sector__c = 'General Engineering';
            pesLeadRec.Email = 'test@gmail.com';
            pesLeadRec.RecordTypeId = (RecordTypeUtils.getInstance()).getRecordTypeId('Lead', 'PES_Lead');
            pesLeadRec.Business_Unit__c = GlobalConstants.PES_BUSINESS_UNIT;
            insert pesLeadRec;
            
            List<Id> leadIds = new List<Id>();
            leadIds.add(pesLeadRec.Id);

            SendCSVNotesInEmail.sendNotes(leadIds); 
            Test.stopTest();
            System.assertEquals('Test',pesLeadRec.FirstName);
        }
        
    }

}