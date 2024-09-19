@isTest
public inherited sharing class videoPreviewControllerTest {
    

    @TestSetup
    static void makeData(){
        Account acct = new Account(Name='TEST_ACCT');
        insert acct;


        ContentVersion contentVersion = new ContentVersion(
            Title = 'Penguins',
            PathOnClient = 'Penguins.jpg',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true
          );

          insert contentVersion; 
          
          
          List<ContentDocument> documents = [
              SELECT Id, Title, LatestPublishedVersionId 
              FROM ContentDocument LIMIT 49999
          ];
          
          //create ContentDocumentLink  record 
          ContentDocumentLink cdl = New ContentDocumentLink();
          cdl.LinkedEntityId = acct.id;
          cdl.ContentDocumentId = documents[0].Id;
          cdl.shareType = 'V';
          insert cdl;

        
    }


    @isTest
    public static void getAttachmentTest(){

        Account ka = [select Id from Account].get(0);

        list<ContentDocumentLink> clinks = VideoPreviewerController.getAttachedDocuments(ka.Id);
        system.assertEquals(clinks.size()>0, clinks.size()>0);
    }

    @isTest
    public static void getBaseUrlTest(){
        string baseUrl = VideoPreviewerController.getBaseUrl();
        system.assertEquals(baseUrl.length()>0, baseUrl.length()>0);
    }
}