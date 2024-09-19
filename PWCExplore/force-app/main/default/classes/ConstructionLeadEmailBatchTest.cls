/**
 * @description       : 
 * @author            : jadhavr@godrej.com
 * @group             : 
 * @last modified on  : 10-05-2023
 * @last modified by  : jadhavr@godrej.com
**/
@IsTest
public class ConstructionLeadEmailBatchTest{
    @testSetup
    public static void createData(){   
        Profile userProfile = [Select Id from Profile where Name = 'Construction Sales Engineer' LIMIT 1];        
        // Create User record.

        User userRec = new TestUserBuilder()
            .setProfileId(userProfile.Id)
            .setLastName('Construction User')
            .setSalaryCode('12354')
            .getTestRecord();  
        userRec.IsActive = true;  
        insert userRec;
        
        System.runAs(userRec){ 
            List<Lead> leadRecordList=new List<Lead>();
            Lead LeadRecord1 = new TestLeadBuilder()
                .setBusinessUnit(GlobalConstants.Construction_BUSINESS_UNIT)
                .setRecordTypeId(Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Interio_MHE_SSG_B2B').getRecordTypeId())
                .setEmail('testUser1@godrej.com')
                .getTestRecord();
            LeadRecord1.Status=GlobalConstants.NEW_CONSTANT;
            LeadRecord1.Internal_Sales_Rep__c=userRec.Id;
            LeadRecord1.Construction_Time__c=0;
            LeadRecord1.LOB_N__c='WPS';
            LeadRecord1.Cluster__c='MUM';
      //    LeadRecord.Next_Reminder_Date__c=system.today();
            leadRecordList.add(LeadRecord1);
            
            Lead LeadRecord2 = new TestLeadBuilder()
                .setBusinessUnit(GlobalConstants.Construction_BUSINESS_UNIT)
                .setRecordTypeId(Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Interio_MHE_SSG_B2B').getRecordTypeId())
                .setEmail('testUser2@godrej.com')
                .getTestRecord();
            LeadRecord2.Status=GlobalConstants.NEW_CONSTANT;
            LeadRecord2.Internal_Sales_Rep__c=userRec.Id;
            LeadRecord2.Construction_Time__c=0;
            LeadRecord2.LOB_N__c='RMC';
            LeadRecord2.Cluster__c='MMR';
      //    LeadRecord.Next_Reminder_Date__c=system.today();
            leadRecordList.add(LeadRecord2);
            
            Lead LeadRecord3 = new TestLeadBuilder()
                .setBusinessUnit(GlobalConstants.Construction_BUSINESS_UNIT)
                .setRecordTypeId(Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Interio_MHE_SSG_B2B').getRecordTypeId())
                .setEmail('testUser3@godrej.com')
                .getTestRecord();
            LeadRecord3.Status=GlobalConstants.NEW_CONSTANT;
            LeadRecord3.Internal_Sales_Rep__c=userRec.Id;
            LeadRecord3.Construction_Time__c=0;
            LeadRecord3.LOB_N__c='RMC';
            LeadRecord3.Cluster__c='Pune East';
      //    LeadRecord.Next_Reminder_Date__c=system.today();
            leadRecordList.add(LeadRecord3);
            
            Lead LeadRecord4 = new TestLeadBuilder()
                .setBusinessUnit(GlobalConstants.Construction_BUSINESS_UNIT)
                .setRecordTypeId(Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Interio_MHE_SSG_B2B').getRecordTypeId())
                .setEmail('testUser4@godrej.com')
                .getTestRecord();
            LeadRecord4.Status=GlobalConstants.NEW_CONSTANT;
            LeadRecord4.Internal_Sales_Rep__c=userRec.Id;
            LeadRecord4.Construction_Time__c=0;
            LeadRecord4.LOB_N__c='RMC';
            LeadRecord4.Cluster__c='Pune West';
      //    LeadRecord.Next_Reminder_Date__c=system.today();
            leadRecordList.add(LeadRecord4);
            
            Lead LeadRecord5 = new TestLeadBuilder()
                .setBusinessUnit(GlobalConstants.Construction_BUSINESS_UNIT)
                .setRecordTypeId(Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Interio_MHE_SSG_B2B').getRecordTypeId())
                .setEmail('testUser5@godrej.com')
                .getTestRecord();
            LeadRecord5.Status=GlobalConstants.NEW_CONSTANT;
            LeadRecord5.Internal_Sales_Rep__c=userRec.Id;
            LeadRecord5.Construction_Time__c=0;
            //LeadRecord5.Cluster__c='WPS';
      //    LeadRecord.Next_Reminder_Date__c=system.today();
            leadRecordList.add(LeadRecord5);
            
            Lead LeadRecord6 = new TestLeadBuilder()
                .setBusinessUnit(GlobalConstants.Construction_BUSINESS_UNIT)
                .setRecordTypeId(Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Interio_MHE_SSG_B2B').getRecordTypeId())
                .setEmail('testUser6@godrej.com')
                .getTestRecord();
            LeadRecord6.Status=GlobalConstants.NEW_CONSTANT;
            LeadRecord6.Internal_Sales_Rep__c=userRec.Id;
            LeadRecord6.Construction_Time__c=10;
           // LeadRecord6.Cluster__c='WPS';
            LeadRecord6.Auto_Closing_Date__c=system.today();
            leadRecordList.add(LeadRecord6);
        
            insert leadRecordList;
        }
    }
    
    static testmethod void test_ConstructionLeadEmailBatch(){
        User constructionUser = [Select Id,LastName From User where LastName='Construction User' and IsActive = true Limit 1];
        System.runAs(constructionUser){          
            system.assertEquals('Construction User',constructionUser.LastName);            
            Test.startTest();       
            	ConstructionLeadEmailBatch schedular = new ConstructionLeadEmailBatch();
            	String sch = '0 0 23 * * ?'; 
            	system.schedule('ConstructionLeadEmail', sch, schedular);
            Test.stopTest();
        }
    }
}