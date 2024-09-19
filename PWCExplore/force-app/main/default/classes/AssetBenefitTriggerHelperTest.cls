@isTest
public class AssetBenefitTriggerHelperTest {
    @testSetup
    static void createData(){
        
        Profile userProfile = [Select Id from Profile where Name =: GlobalConstants.SYSTEM_ADMIN_PROFILE_NAME LIMIT 1];
        // Create User record.
        User userToRun = new User(EmailEncodingKey = 'UTF-8', firstName = 'Test', lastname = 'User', Alias = 'tuser',
                            languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = userProfile.id, 
                            timezonesidkey = 'Asia/Kolkata', email = 'test.userAcc@godrej.com', username = 'test.userAcc@godrej.com', Business_Unit__c = 'W');

        userToRun.IsActive = true;
        userToRun.Allow_Business_Account_Creation__c = true;
        userToRun.Logistic_Company__c = '2000';
        userToRun.Area_Code__c = 'WN1';
        insert userToRun;
        
        Account newAccount = new Account();
        newAccount.Name = 'Test Account';
        insert newAccount;
        
        //Create Address Record						//Added by pc
            Address__c address = new Address__c();
            address.Address_Type__c = 'B2B';
            address.Address_Format__c = 'ADR';
            address.Name__c = 'Nuvoco Plant Pune';
            address.Telephone__c = '8765432111';
            address.Email__c = 'punetest1234@nuvoco.com';
            address.Building__c = 'Avenues';
            address.Street2__c = '1st Street';
            insert address;
        
        Asset newAsset = new Asset();
        newAsset.Name= 'test Asset';
        newAsset.AccountId = newAccount.id;
        newAsset.Status = 'Purchased';
        newAsset.Coverage__c = 'KFTWC01200001';
        newAsset.Type_of_Warranty__c = 'Special Warranty';
        newAsset.Address_Code__c = address.id;
        insert newAsset;
        
        /*Plan__c standardPlan = new Plan__c();
        standardPlan.Name = 'Standard Warrenty Plan';
        standardPlan.Is_Active__c= true;
        standardPlan.Plan_Type__c = 'Basic';
        standardPlan.Is_Standard_Plan__c = true; 
        standardPlan.BD_Visits__c = 'Yes';
        standardPlan.BD_Visits_Number__c = 2;
        standardPlan.Scheduled_PM_Visits__c = 'Yes';
        standardPlan.Scheduled_PM_Visits_Number__c = 3;
        standardPlan.Remote_Assistance__c = 'Yes';
        standardPlan.Operator__c = 'No';
        standardPlan.Supervisor__c = 'Yes';      
        insert standardPlan;
        */
        
        Plan__c bronzePlan = new Plan__c();
        bronzePlan.Name = 'Bronze Plan';
        bronzePlan.Is_Active__c= true;
        bronzePlan.Plan_Type__c = '	Add on';
        bronzePlan.Is_Standard_Plan__c = false; 
        bronzePlan.BD_Visits_Number__c = 4;
        bronzePlan.Scheduled_PM_Visits__c = 'Yes';
        bronzePlan.Scheduled_PM_Visits_Number__c= 4;
        bronzePlan.Remote_Assistance__c = 'Yes';
        insert bronzePlan;
        
        
    }
    
    @isTest private static void assetRecalculationFieldUpdateOnInsertTest() {
        User contextuser = [Select Id FROM User WHERE username = 'test.userAcc@godrej.com' LIMIT 1];
        System.runAs(contextuser) {
            Test.startTest();
            Asset assetRec = [SELECT Id FROM Asset LIMIT 1];
            Plan__c plan = [SELECT Id FROM Plan__c LIMIT 1];
                
            Asset_Benefit__c assetBenefit = new Asset_Benefit__c();
            assetBenefit.Asset__c = assetRec.Id;
            assetBenefit.Is_Active__c = true;
            assetBenefit.Plan__c = plan.Id;
            assetBenefit.Supervisor__c = 'Yes';
            insert assetBenefit;
            
            Asset updatedAssetRec = [SELECT Id, Recalculation_Required__c FROM Asset WHERE Id =: assetRec.Id];
            system.assertEquals(updatedAssetRec.Recalculation_Required__c, true);
            Test.stopTest();
        }
    }
    
    @isTest private static void assetRecalculationFieldUpdateOnUpdateTest() {
        User contextuser = [Select Id FROM User WHERE username = 'test.userAcc@godrej.com' LIMIT 1];
        System.runAs(contextuser) {
            Test.startTest();
            Asset assetRec = [SELECT Id FROM Asset LIMIT 1];
            Plan__c plan = [SELECT Id FROM Plan__c LIMIT 1];
                
            Asset_Benefit__c assetBenefit = new Asset_Benefit__c();
            assetBenefit.Asset__c = assetRec.Id;
            assetBenefit.Is_Active__c = true;
            assetBenefit.Plan__c = plan.Id;
            assetBenefit.Supervisor__c = 'Yes';
            insert assetBenefit;
            
            //update asset Benefit record
            Asset_Benefit__c assetBenefitTOUpdate = new Asset_Benefit__c(Id = assetBenefit.Id, Supervisor__c = 'No');
            update assetBenefitTOUpdate;
            
            Asset updatedAssetRec = [SELECT Id, Recalculation_Required__c FROM Asset WHERE Id =: assetRec.Id];
            system.assertEquals(updatedAssetRec.Recalculation_Required__c, true);
            Test.stopTest();
        }
    }

}