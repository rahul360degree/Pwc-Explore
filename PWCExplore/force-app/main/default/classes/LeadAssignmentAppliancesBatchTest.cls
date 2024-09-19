@IsTest
public class LeadAssignmentAppliancesBatchTest{
    @testSetup
    public static void createData(){   
        Profile userProfile = [Select Id from Profile where Name = 'System Administrator' LIMIT 1];
        
        // Create User records.
        List<User> userList=new List<User>();
        User userRec = new TestUserBuilder()
            .setProfileId(userProfile.Id)
            .setLogisticCompany('5020')
            .setBusinessUnit(GlobalConstants.APPLIANCE_BUSINESS_UNIT)
            .setLastName('Appliance User')
            .getTestRecord();        
        userRec.Persona__c = 'Appliances- Self Calling Executive';
        userRec.IsActive = true;                
        userList.add(userRec);
        
        User userRec1 = new TestUserBuilder()
            .setProfileId(userProfile.Id)
            .setLogisticCompany('5020')
            .setBusinessUnit(GlobalConstants.APPLIANCE_BUSINESS_UNIT)
            .setLastName('Appliance Self Calling Executive User')
            .getTestRecord();        
        userRec1.Business_Line__c = GlobalConstants.D2D_CHANNEL;							
        userRec1.Persona__c = 'Appliances- Self Calling Executive';
        userRec1.IsActive = true; 
        userList.add(userRec1);
        insert userList;
        
        
        Group  grp=[Select Id from Group where Type='Queue' and DeveloperName='Default_Queue' limit : 1];
        
        Group zipQueue=new Group();
        zipQueue.DeveloperName='H_D2D_PUNE_Test';
        zipQueue.Type='Queue';
        zipQueue.Name='H_D2D_PUNE_Test';
        insert zipQueue;
        
        List<GroupMember> groupMemberList=new List<GroupMember>();
        GroupMember grpMember=new GroupMember();
        grpMember.GroupId=grp.Id;
        grpMember.UserOrGroupId=userRec.Id;
        groupMemberList.add(grpMember);
        
        GroupMember zipQueueMember=new GroupMember();
        zipQueueMember.GroupId=zipQueue.Id;
        zipQueueMember.UserOrGroupId=userRec1.Id;
        groupMemberList.add(zipQueueMember);
        insert groupMemberList;
    }
    
    static testmethod void test_LeadAssignmentAppliancesBatch(){
        User applianceUser = [Select Id,LastName From User where LastName='Appliance Self Calling Executive User' Limit 1];
        Set<Id> userIdSet=new Set<Id>();
        userIdSet.add(applianceUser.Id);
        System.runAs(applianceUser){
            Group  grp=[Select Id from Group where Type='Queue' and DeveloperName='Default_Queue' limit : 1];
            ZipCode__c zipCode = new ZipCode__c();
            zipCode.Name = '392140';
            zipCode.CityCode__c = 'PUNE';
            zipCode.City_Name__c = 'PUNE';
            zipCode.StateCode__c = 'MH';
            zipCode.StateName__c = 'Maharashtra';
            zipCode.CountryCode__c = 'IN';   
            zipCode.CountryName__c = 'INDIA';   
            zipCode.ZipCodeExternalId__c = 'IN_410002';   
            insert zipCode;    
            
            Zip_Code_Rule__c zipRule = new Zip_Code_Rule__c();
            zipRule.name = 'H-B2C-392140-D2D';
            zipRule.Queue_1__c = 'H_D2D_PUNE_Test';
            zipRule.Effective_Till__c = (Date.today()).addDays(100);
            zipRule.Object_Name__c = 'Lead';
            zipRule.Channel__c=GlobalConstants.D2D_CHANNEL;
            zipRule.Run_Round_Robin_on_Queue1__c = true;
            zipRule.Queues_And_LastAssignedId__c = UserInfo.getUserId();
            insert zipRule;
            
            Lead LeadRecord = new TestLeadBuilder()
                .setBusinessUnit(GlobalConstants.APPLIANCE_BUSINESS_UNIT)
                .setRecordTypeId(Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Appliances_B2C_Lead').getRecordTypeId())
                .setChannel(GlobalConstants.D2D_CHANNEL) 
                .setOwnerId(grp.Id)
                .getTestRecord();
            LeadRecord.Status='New';
            LeadRecord.sub_division__C = GlobalConstants.B2C_SUBDIVISION;
            LeadRecord.ZipCode__c=zipCode.Id;
            LeadRecord.Zip_Code_Rule__c=zipRule.Id;
			insert LeadRecord;
            
            Test.startTest();
        /*    LeadAssignmentAppliancesBatch schedular = new LeadAssignmentAppliancesBatch();
            String sch = '0 0 23 * * ?'; 
            system.schedule('LeadAssignment', sch, schedular);*/
            
            LeadAssignmentAppliancesBatch batchInstance = new LeadAssignmentAppliancesBatch(userIdSet,true,null); 
            database.executebatch(batchInstance,1);
      
            Test.stopTest();
        }
    }
}