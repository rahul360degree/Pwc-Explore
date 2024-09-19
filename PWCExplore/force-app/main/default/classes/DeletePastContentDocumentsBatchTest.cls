/*------------------------------------------------------------------------
Author:        Shailja
Company:       Salesforce
Description:   Test Class for DeletePastContentDocumentsBatch
Inputs:        NA
Test Class:   
---------------------------------------------------------------------------
History
04-02-2021      Shailja     Initial Release
----------------------------------------------------------------------------*/
@isTest
public class DeletePastContentDocumentsBatchTest {
	 @TestSetup
    static void testData(){ 
        Profile userProfile = [Select Id from Profile where Name = 'System Administrator-Appliances' LIMIT 1];
        User userToRun = new User(EmailEncodingKey = 'UTF-8', firstName = 'Test', lastname = 'User', Alias = 'tuser',
                                  languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = userProfile.id,
                                  timezonesidkey = 'Asia/Kolkata', email = 'test.user@godrej.com', 
                                  username = 'test.user@godrej.com');
        insert userToRun;
        
        System.runAs(userToRun){
              TestAttendanceBuilder tab = new TestAttendanceBuilder();
        Attendance__c attendanceRec = tab.setType('Missing Attendance');
        attendanceRec.end_of_day__c = attendanceRec.start_of_day__c.addHours(2);
        attendanceRec.Auto_Submit_For_Approval__c = false;
        insert attendanceRec;
		System.debug('attendanceRec owner'+attendanceRec.Owner.Name);
            System.debug('end_of_day__c '+attendanceRec.end_of_day__c);
            System.debug('start_of_day__c '+attendanceRec.start_of_day__c);
        //System.debug('Owner manager'+attendanceRec.Owner.ManagerId);
        ContentVersion contentDoc = new ContentVersion(); 
        contentDoc.Title = 'Attendance file'; 
        contentDoc.PathOnClient = '/' + contentDoc.Title + '.jpg'; 
        Blob bodyBlob = Blob.valueOf('Content Version'); 
        contentDoc.VersionData = bodyBlob;
        contentDoc.origin = 'H';
        insert contentDoc;
        
        ContentDocumentLink contentDoclink = new ContentDocumentLink();
        contentDoclink.LinkedEntityId = attendanceRec.id;
        contentDoclink.contentdocumentid = [select contentdocumentid from contentversion where id =: contentDoc.id].contentdocumentid;
        contentDoclink.ShareType = 'I';
        contentDoclink.Visibility = 'AllUsers'; 
        insert contentDoclink;
    
        }
        /*TestAttendanceBuilder tab = new TestAttendanceBuilder();
        Attendance__c attendanceRec = tab.setType('Missing Attendance');
        attendanceRec.end_of_day__c = attendanceRec.start_of_day__c.addHours(2);
        attendanceRec.Auto_Submit_For_Approval__c = false;
        insert attendanceRec;
		System.debug('attendanceRec owner'+attendanceRec.Owner.Name);
        //System.debug('Owner manager'+attendanceRec.Owner.ManagerId);
        ContentVersion contentDoc = new ContentVersion(); 
        contentDoc.Title = 'Attendance file'; 
        contentDoc.PathOnClient = '/' + contentDoc.Title + '.jpg'; 
        Blob bodyBlob = Blob.valueOf('Content Version'); 
        contentDoc.VersionData = bodyBlob;
        contentDoc.origin = 'H';
        insert contentDoc;
        
        ContentDocumentLink contentDoclink = new ContentDocumentLink();
        contentDoclink.LinkedEntityId = attendanceRec.id;
        contentDoclink.contentdocumentid = [select contentdocumentid from contentversion where id =: contentDoc.id].contentdocumentid;
        contentDoclink.ShareType = 'I';
        contentDoclink.Visibility = 'AllUsers'; 
        insert contentDoclink;*/
    }
    
    
    @isTest private static void testBatch(){
        List<Attendance__c> attendances = [Select Id,type__c From Attendance__c];
        integer s=attendances.size();
        System.assert(attendances.size() == 1);
        List<ContentDocumentLink> contentDocLinks = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId =: attendances[0].Id];
        integer s1=contentDocLinks.size();
        List<ContentDocument> lstContentDocument = [SELECT Id FROM ContentDocument where id =:contentDocLinks[0].ContentDocumentId];
        integer s3=lstContentDocument.size();
        Test.startTest();
        DeletePastContentDocumentsBatch b = new DeletePastContentDocumentsBatch();
        database.executebatch(b, 100);
        Test.stopTest();
        integer s4=lstContentDocument.size();
    }
	    
}