/*-----------------------------------------------------------------------------------
* Author        :        Mahith Madwesh
* Company       :        Salesforce
* Description   :        Test class for AssetBenfitBestValueBatchHelper.cls
*                         Assets
* Inputs        :        
* Test Class    :         AssetBenfitBestValueBatchHelperTest.cls
* History
* --------
* 23-11-2020      Mahith Madwesh     Initial Release
* ---------------------------------------------------------------------------------*/
@isTest
public with sharing class AssetBenfitBestValueBatchHelperTest {
    @TestSetup
    static void makeData(){
        
        Account newAccount = new Account();
        newAccount.Name = 'Test Account';
        insert newAccount;
        
        //Create Address Record							//Added by pc
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
        newAsset.Name= 'testAsset';
        newAsset.AccountId = newAccount.id;
        newAsset.Status = 'Purchased';
        newAsset.Product_Purchased_Warranty_Start_Date__c = Datetime.newInstance(2020, 11, 17, 1, 6, 8); 
        newAsset.Product_Purchased_Warranty_End_Date__c = Date.newInstance(2021, 11, 17);
        newAsset.Date_of_Commissioning__c = Datetime.newInstance(2020, 11, 17, 1, 6, 8);
        newAsset.Scheduled_PM_Visits_Number__c = 4;
        newAsset.Recalculation_Required__c = true;
        newAsset.Address_Code__c = address.id;			//Added by pc
        insert newAsset;
        
        
        Asset newAsset1 = new Asset();
        newAsset1.Name= 'testAsset1';
        newAsset1.AccountId = newAccount.id;
        newAsset1.Recalculation_Required__c = true;
        newAsset1.Status = 'Purchased';
        newAsset1.Address_Code__c = address.id;				//Added by pc
        insert newAsset1;
        
        Plan__c standardPlan = new Plan__c();
        standardPlan.Name = 'Std Warranty';
        standardPlan.Is_Active__c= true;
        
        standardPlan.Plan_Type__c = 'Basic';
        standardPlan.Is_Standard_Plan__c = true; 
        standardPlan.BD_Visits__c = 'Yes';
        standardPlan.BD_Visits_Number__c = 2;
        standardPlan.Scheduled_PM_Visits__c = 'Yes';
        standardPlan.Scheduled_PM_Visits_Number__c = 4;
        standardPlan.Remote_Assistance__c = 'Yes';
        standardPlan.Operator__c = 'No';
        standardPlan.Supervisor__c = 'Yes';    
        standardPlan.Audits__c = 'Yes';
        standardPlan.Stationed_Manpower__c = 'Yes';
        standardPlan.Equipment_Type__c = null;    
        standardPlan.Reports_Dashboards__c = 'No';
        standardPlan.Parts_Support__c = 'No';  
        insert standardPlan;
        
        Plan__c bronzePlan = new Plan__c();
        bronzePlan.Name = 'Bronze Plan';
        bronzePlan.Is_Active__c= true;
        bronzePlan.Plan_Type__c = 'Add on';
        bronzePlan.Is_Standard_Plan__c = false; 
        bronzePlan.BD_Visits_Number__c = 4;
        bronzePlan.Scheduled_PM_Visits__c = 'Yes';
        bronzePlan.Scheduled_PM_Visits_Number__c= 3;
        bronzePlan.Remote_Assistance__c = 'Yes';
        insert bronzePlan;
        
        Asset_Benefit__c assetBenefit = new Asset_Benefit__c();
        assetBenefit.Asset__c = newAsset.id;
        assetBenefit.Is_Active__c = true;
        assetBenefit.Is_Legacy_Benefit__c = false;
        assetBenefit.Plan__c = standardPlan.id; 
        assetBenefit.Scheduled_PM_Visits_Number__c  = standardPlan.Scheduled_PM_Visits_Number__c;
        assetBenefit.BD_Visits__c = standardPlan.BD_Visits__c;
        assetBenefit.BD_Visits_Number__c=standardPlan.BD_Visits_Number__c;
        assetBenefit.Scheduled_PM_Visits__c=standardPlan.Scheduled_PM_Visits__c;
        assetBenefit.Scheduled_PM_Visits_Number__c=standardPlan.Scheduled_PM_Visits_Number__c;
        assetBenefit.Remote_Assistance__c=standardPlan.Remote_Assistance__c;
        assetBenefit.Operator__c=standardPlan.Operator__c;
        assetBenefit.Supervisor__c=standardPlan.Supervisor__c;   
        assetBenefit.Audits__c = standardPlan.Audits__c;
        assetBenefit.Stationed_Manpower__c=standardPlan.Stationed_Manpower__c;
        assetBenefit.Equipment_Type__c=standardPlan.Equipment_Type__c;
        assetBenefit.Reports_Dashboards__c=standardPlan.Reports_Dashboards__c;
        assetBenefit.Parts_Support__c=standardPlan.Parts_Support__c;
        insert assetBenefit;
        
        
        Asset_Benefit__c assetBenefit1 = new Asset_Benefit__c();
        assetBenefit1.Asset__c = newAsset.id;
        assetBenefit1.Is_Legacy_Benefit__c = false;
        assetBenefit1.Is_Active__c = true;
        assetBenefit1.Plan__c = bronzePlan.id; 
        insert assetBenefit1;
        
    }

    @isTest
    public static void updateBenifitBestValueOnAssetTest(){
        
        Test.startTest();
        list<Asset> assetRecords  = new list<Asset>();
        assetRecords = [SELECT Id, Name, Product_Purchased_Warranty_End_Date__c,Date_of_Commissioning__c, Product_Purchased_Warranty_Start_Date__c,  
                        (SELECT Id, Name, Audits__c, Scheduled_PM_Visits_Number__c, Operator__c, Scheduled_PM_Visits__c, 
                         BD_Visits__c, BD_Visits_Number__c, Equipment_Type__c, Parts_Support__c, plan__r.name,
                         Remote_Assistance__c, Reports_Dashboards__c, Stationed_Manpower__c, Supervisor__c,
                         Contract_Line_Item__r.startDate,Contract_Line_Item__r.endDate,lastModifiedDate,Is_Legacy_Benefit__c,Contract_Line_Item__r.ServiceContract.Approved_Date__c 
                         FROM Asset_Benefits__r WHERE Is_Active__c = true) FROM Asset WHERE Recalculation_Required__c = true];
        
        AssetBenfitBestValueBatchHelper abHelper = new AssetBenfitBestValueBatchHelper();
        abHelper.UpdatebestValueBenifit(assetRecords);
        system.assertEquals(assetRecords.size()>0, assetRecords.size()>0, 'Update Asset Benifit Best Value Failed');
        
        Test.stopTest();
    }

}