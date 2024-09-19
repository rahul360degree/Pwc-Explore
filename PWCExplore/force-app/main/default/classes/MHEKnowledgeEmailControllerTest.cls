@isTest
public class MHEKnowledgeEmailControllerTest {
	static testMethod void sendEmailNotifcationToMHEUsers(){
       Profile profile = [SELECT Id FROM Profile WHERE Name =:GlobalConstants.SYSTEM_ADMIN_PROFILE_NAME];
        User runningAdminUser =new TestUserBuilder()
            .setProfileId(profile.Id)
            .setLastName('Admin User')
            .getTestRecord();        
        runningAdminUser.IsActive = true;
        insert runningAdminUser;
        
        System.runAs(runningAdminUser)
        { 
            System.assertEquals('Admin User', runningAdminUser.LastName);
            List<String> knowledgeIdList=new List<String>();
            // Created Knowledge Record.
            Knowledge__kav knowledgeRecord=new Knowledge__kav();
            knowledgeRecord.Title='MHE KT';
            knowledgeRecord.Summary='Latest Version';
            knowledgeRecord.IsVisibleInPrm=true;
            knowledgeRecord.UrlName='TestURL';            
            insert knowledgeRecord;
            
            knowledgeIdList.add(knowledgeRecord.Id);
            
            Test.startTest();
                MHEKnowledgeEmailController.callFutureMethod(knowledgeIdList);
            Test.stopTest();
        }
    }
}