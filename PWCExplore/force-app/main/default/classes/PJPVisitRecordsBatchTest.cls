@isTest
public class PJPVisitRecordsBatchTest {
    @isTest static void testData(){
    
    }
    
    static testMethod void testmethods(){
                User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs (thisUser) {
        
        UserRole userrole = [Select Id from UserRole where Name like 'Appliances Area%' Limit 1];
        Profile userProfile2 = [Select Id from Profile where Name = 'Appliances Area Service Manager User - Service' LIMIT 1];
        //Address__c primaryadd = [Select Id from Address__c Limit 1];
           List<User> userdata = [select Id from User where UserRole.Name like 'Appliances Area%' limit 1];
        
        integer k=0;
        integer i =1;
        List<String> acctype = new List<String>{'3','E','D'};
        List<String> acccategory = new List<String>{'A','B','C'};
        List<Account> testaccount = new List<Account>();
        for(User us : userdata){
            for(k=0;k<10;k++){
            for(String type : acctype){
                for(String cat : acccategory){
                    testaccount.add(new Account(
                        Name= 'test account'+ '-'+i,
                        Business_Unit__c = 'H',
                        OwnerId=us.Id,
                        Category__c=cat,
                        Type=type,
                        AADHAR_Number__c = 1234567890,
                        GST_Number__c='234567d',
                        PAN__c='123456',
                        GSTN__c='2467d7',
                        Tenure__c='1 year',
                        ASP_Owner__c=us.Id,
                        Primary_Address__c='a05C4000002SBIjIAO'
            		));
                    i=i+1;
                }
            } 
            }
        }
       
        
        AccountTriggerHandler.TriggerDisabled = true;
        insert testaccount;

            
            /*insert testaccount;
            system.debug('testinsert'+testaccount);
            system.debug('testaccountbu'+testaccount.Business_Unit__c);
            system.debug('testtype'+testaccount.Type);
            system.debug('testaccountowner'+testaccount.OwnerId);*/

    }
        Test.startTest();
        PJPVisitRecordsBatch batch = new PJPVisitRecordsBatch();
		Database.executeBatch(batch,300);
        Test.stopTest();
    }
    
}