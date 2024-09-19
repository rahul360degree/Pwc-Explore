@isTest
public class InsBgBatchTest {
    @testSetup
    public static void createData(){ 
        profile pedProfile = [Select Id, Name from Profile where Name ='PED Regional Head Sales Mktg' limit 1];
        UserRole pedRole = [Select Id, Name from UserRole where DeveloperName ='PED_Head_Marketing_Business_Development_OGC_Power_MKT_II' limit 1]; 
        
        User pedTBandUser = new TestUserBuilder()
                .setProfileId(pedProfile.Id)
                .setLastName('T Band User')
                .setLogisticCompany('1700')
                .setBusinessUnit('P')
            	.setPersona('PED Head Sales - T Band')
                .getTestRecord();        
        pedTBandUser.IsActive = true;    
        pedTBandUser.UserRoleId =pedRole.Id;
        insert pedTBandUser;
        
        System.runAs(pedTBandUser){             
            List<Insurance_Bank_Guarantee__c> insuranceBgList=new List<Insurance_Bank_Guarantee__c>();
            
            Insurance_Bank_Guarantee__c insBgRec1=new Insurance_Bank_Guarantee__c();
            insBgRec1.Contractual_Validity_Date__c=system.today().addDays(30);
            insBgRec1.Expiry_Date__c=system.today().addDays(30);
            insBgRec1.RecordTypeId = Schema.SObjectType.Insurance_Bank_Guarantee__c.getRecordTypeInfosByDeveloperName().get(GlobalConstants.PED_IB_BG_RT).getRecordTypeId();
            insuranceBgList.add(insBgRec1);
            
            
            Insurance_Bank_Guarantee__c insBgRec2=new Insurance_Bank_Guarantee__c();
            insBgRec2.Contractual_Validity_Date__c=system.today().addDays(30);
            insBgRec2.Expiry_Date__c=system.today().addDays(37);
            insBgRec2.RecordTypeId = Schema.SObjectType.Insurance_Bank_Guarantee__c.getRecordTypeInfosByDeveloperName().get(GlobalConstants.PED_IB_INSURANCE_RT).getRecordTypeId();
            insuranceBgList.add(insBgRec2);

            Insurance_Bank_Guarantee__c insBgRec3=new Insurance_Bank_Guarantee__c();
            insBgRec3.Contractual_Validity_Date__c=system.today().addDays(30);
            insBgRec3.Expiry_Date__c=system.today().addDays(-1);
            insBgRec3.RecordTypeId = Schema.SObjectType.Insurance_Bank_Guarantee__c.getRecordTypeInfosByDeveloperName().get(GlobalConstants.PED_IB_BG_RT).getRecordTypeId();
            insuranceBgList.add(insBgRec3);
            
            Insurance_Bank_Guarantee__c insBgRec4=new Insurance_Bank_Guarantee__c();
            insBgRec4.Contractual_Validity_Date__c=system.today().addDays(30);
            insBgRec4.Expiry_Date__c=system.today().addDays(-10);
            insBgRec4.RecordTypeId = Schema.SObjectType.Insurance_Bank_Guarantee__c.getRecordTypeInfosByDeveloperName().get(GlobalConstants.PED_IB_INSURANCE_RT).getRecordTypeId();
            insuranceBgList.add(insBgRec4);
            
            insert insuranceBgList;
        }
    }
    
    static testMethod void testEmailToFinanceForBGRequestPedBatch(){  
        User pedUser = [Select Id,LastName From User where LastName='T Band User' Limit 1];
        System.runAs(pedUser){         
            EmailToFinanceForBGRequestPedBatch batchInstance = new EmailToFinanceForBGRequestPedBatch(); 
            database.executeBatch(batchInstance,5);
            
            Integer expectedEmailsSent = 2;
        	Integer actualEmailsSent = [SELECT COUNT() FROM EmailMessage];
        	Assert.areEqual(expectedEmailsSent, actualEmailsSent, 'Emails not sent as expected');
        }
    }
    
    static testMethod void testInsBgExpiryReminderEmailPedBatch(){  
        User pedUser = [Select Id,LastName From User where LastName='T Band User' Limit 1];
        System.runAs(pedUser){                
            InsBgExpiryReminderEmailPedBatch batchInstance = new InsBgExpiryReminderEmailPedBatch(); 
            database.executeBatch(batchInstance,5); 
            
            Integer expectedEmailsSent = 2;
        	Integer actualEmailsSent = [SELECT COUNT() FROM EmailMessage];
        	Assert.areEqual(expectedEmailsSent, actualEmailsSent, 'Emails not sent as expected');
        }
    }
}