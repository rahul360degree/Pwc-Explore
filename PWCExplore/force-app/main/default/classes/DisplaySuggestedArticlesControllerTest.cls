@isTest
public class DisplaySuggestedArticlesControllerTest {
    @TestSetup 
    static void createData() {
        Profile userProfile = [Select Id from Profile where Name = 'System Administrator' LIMIT 1];
        // Create User record.
        User userToRun = new User(EmailEncodingKey = 'UTF-8', firstName = 'Test', lastname = 'User', Alias = 'tuser',
            languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = userProfile.id,
            timezonesidkey = 'Asia/Kolkata', email = 'test.user@godrej.com', username = 'test.user@godrej.com', Business_Unit__c = GlobalConstants.MHE_DIVISION_CODE
        );

        insert userToRun;

        System.runAs(userToRun) {
            // Create account record
            Account accountRecord = new TestAccountBuilder()
                .setRecordTypeId(Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business_Account').getRecordTypeId())
                .getSavedTestRecord();
            accountRecord.Business_Unit__c = GlobalConstants.BUSINESS_UNIT_MHE_DIVISION;
            update accountRecord;

            // Create Case Record
            Case caseRecord = new TestCaseBuilder()
                .setAccountId(accountRecord.Id)
                .setAlternateMobile('9999999990')
                .setAlternateEmail('test.user@email.com')
                .setRecordTypeId((RecordTypeUtils.getInstance()).getRecordTypeId('Case', 'MHE_Service_Request'))
                .getSavedTestRecord();
            
            // Create Knowledge article
            Knowledge__kav newArticle = new Knowledge__kav(Title='DisplaySuggestedArticlesControllerTest', 
                Summary='DisplaySuggestedArticlesControllerTest', UrlName='DisplaySuggestedArticlesControllerTest', Answer__c = 'List of answers', Expiry_Date__c = Date.today() + 7
            );
            insert newArticle;
        }
    }

    @isTest
    private static void getArticlesTest() {
        User userToRun = [Select Id FROM User WHERE Username = 'test.user@godrej.com' LIMIT 1];
        System.runAs(userToRun){
            List<Case> caseRecords = [Select Id FROM Case LIMIT 1];
            List<KnowledgeArticle> knowledgeArticles = DisplaySuggestedArticlesController.getArticles(caseRecords[0].Id);
        }
    }

    @isTest
    private static void createCaseArticleTest() {
        User userToRun = [Select Id FROM User WHERE Username = 'test.user@godrej.com' LIMIT 1];
        System.runAs(userToRun){
            List<Case> caseRecords = [Select Id FROM Case LIMIT 1];
            List<Knowledge__kav> articles = [Select Id FROM Knowledge__kav LIMIT 1];
            List<Id> knowledgeArticleVersionIds = new List<Id>{articles[0].Id};
            Boolean isArticleCreated = DisplaySuggestedArticlesController.createCaseArticle(knowledgeArticleVersionIds, caseRecords[0].Id);
        }
    }

    @isTest
    private static void getArticlesBySearchTest() {
        User userToRun = [Select Id FROM User WHERE Username = 'test.user@godrej.com' LIMIT 1];
        System.runAs(userToRun){
            List<KnowledgeArticle> knowledgeArticles = DisplaySuggestedArticlesController.getArticlesBySearch('DisplaySuggestedArticlesControllerTest');
        }
    }
}