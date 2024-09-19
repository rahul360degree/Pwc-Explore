/*------------------------------------------------------------------------------------------
 * Author        :        Joshna
 * Company       :        Salesforce
 * Description   :        Test class for UploadCompressedFileHelper
 * History
 * --------
 * 02-02-2021      Joshna Palla     Initial Release
 * -----------------------------------------------------------------------------------------*/
@isTest
public with sharing class UploadCompressedFileHelperTest {
    @isTest private static void createContentDocumentsWithTwoStringsShouldCreateTwoContentDocuments() {
        List<Id> documentIds;
        Test.startTest();
        documentIds = UploadCompressedFileHelper.createContentDocuments(new List<String>{'Blob one', 'Blob 2'}, 'Test File', 'png');
        Test.stopTest();
        System.assertEquals(2, documentIds.size(), 'Helper method did not create files');
    }
}