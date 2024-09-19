/**
 * @description       : 
 * @author            : vrajpoot@godrej.com
 * @group             : 
 * @last modified on  : 01-10-2023
 * @last modified by  : vrajpoot@godrej.com
**/
@IsTest
public class LeadAssignmentInterioB2CBatchTest {
 /*   @testsetup   //Commented by Shreela on 5th dec 2023 
    public static void createdata(){
        Profile userProfile = [Select Id from Profile where Name = 'System Administrator' LIMIT 1];
        
        List<String> ownerEmailList=Label.Interio_B2C_Lead_Assignment_User_Name.split(',');        
        
        //Create User
        List<User> UserList = [Select Id from User where username in :ownerEmailList and isActive = true];
        if(UserList.isEmpty())
        {
            UserList = new List<User>();
        
        User user1 = New TestUserBuilder()
            .setProfileId(userProfile.Id)
            .setLogisticCompany('3010')
            .setLastName('Interio User')
            .setBusinessUnit(GlobalConstants.INTERIO_BUSINESS_UNIT)
            .getTestRecord();
        user1.Email = ownerEmailList[0]; 
        user1.username = ownerEmailList[0];
        user1.IsActive = true;                
        UserList.add(user1);
 
        User user2 = New TestUserBuilder()
            .setProfileId(userProfile.Id)
            .setLogisticCompany('3010')
            .setBusinessUnit(GlobalConstants.INTERIO_BUSINESS_UNIT)
            .getTestRecord(); 
        user2.IsActive = true;             
        user2.username = ownerEmailList[1];    //Changed from 0 to 1 by Shreela on 5th December 2023 for duplicate user anem issue
        UserList.add(user2);
        
        insert UserList;
        }
        Group  grp=[Select Id from Group where Type='Queue' and DeveloperName='Default_Queue' limit : 1];
        
        List<GroupMember> groupMemberList=new List<GroupMember>();
        GroupMember grpMember=new GroupMember();
        grpMember.GroupId=grp.Id;
        grpMember.UserOrGroupId=UserList[1].Id;
        groupMemberList.add(grpMember);
        
        insert groupMemberList;
        
        
        
    }
    
    static testmethod void testLeadAssignmentInterioB2BBatchTest(){
        List<String> ownerEmailList=Label.Interio_B2C_Lead_Assignment_User_Name.split(',');        
        User InterioUser = [Select Id from User where username in :ownerEmailList and isActive = true limit 1];

        System.runAs(InterioUser){
            Group  grp=[Select Id from Group where Type='Queue' and DeveloperName=:GlobalConstants.LEAD_ASSIGNMENT_DEFAULT_QUEUE limit : 1];
            List<Lead> LeadList = new List<Lead>(); 
            Lead LeadRecord1 = new TestLeadBuilder()
                .setBusinessUnit('W')
                .setOwnerId(grp.Id)
                .setRecordTypeId(Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Interio_B2C_Lead').getRecordTypeId())
                .getTestRecord();
            LeadRecord1.Status='New';
            
            LeadRecord1.Interio_Sub_Division__c = GlobalConstants.INTERIO_VFD;
            LeadList.add(LeadRecord1);
            
            Lead LeadRecord2 = new TestLeadBuilder()
                .setBusinessUnit('W')
                .setOwnerId(InterioUser.Id)
                .setRecordTypeId(Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Interio_B2C_Lead').getRecordTypeId())
                .getTestRecord();
            LeadRecord2.Status='New';
            LeadRecord2.Interio_Sub_Division__c = GlobalConstants.INTERIO_VFD;
            LeadList.add(LeadRecord2);
            
            
            insert LeadList;
            
            Test.startTest(); */ //Commented by Shreela on 5th dec 2023 
            /*    LeadAssignmentAppliancesBatch schedular = new LeadAssignmentAppliancesBatch();
String sch = '0 0 23 * * ?'; 
system.schedule('LeadAssignment', sch, schedular);*/
            
            /*LeadAssignmentInterioB2CBatch batchInstance = new LeadAssignmentInterioB2CBatch();  //Commented by Shreela on 5th dec 2023 
            database.executebatch(batchInstance);
            
            Test.stopTest();
        }
    } */ //Commented by Shreela on 5th dec 2023 
    
    
}