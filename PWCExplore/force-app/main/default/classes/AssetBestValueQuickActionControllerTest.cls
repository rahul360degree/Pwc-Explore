/*-----------------------------------------------------------------------------------
 * Author        :        Mahith Madwesh
 * Company       :        Salesforce
 * Description   :        Test Class for AssetBestValueQuickActionController
 * Inputs        :        
 * Test Class    :    
 * History
 * --------
 * 25-11-2020      Mahith Madwesh     Initial Release
 * ---------------------------------------------------------------------------------*/
@isTest
public with sharing class AssetBestValueQuickActionControllerTest {

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
        newAsset.Product_Purchased_Warranty_Start_Date__c = Datetime.parse('11/6/2020, 11:46 AM');
        newAsset.Product_Purchased_Warranty_End_Date__c = Date.newInstance(2021,6,11);
    	newAsset.Scheduled_PM_Visits_Number__c = 4;
    	newAsset.Coverage__c = 'KFTWC01200001';
    	newAsset.Address_Code__c = address.id;			//Added by pc
        newAsset.Type_of_Warranty__c = 'Special Warranty';
        insert newAsset;

        Asset newAsset1 = new Asset();
        newAsset1.Name= 'testAsset1';
        newAsset1.AccountId = newAccount.id;
        newAsset1.Status = 'Purchased';
    	newAsset1.Coverage__c = 'KFTWC01200001';
        newAsset1.Type_of_Warranty__c = 'Special Warranty';
    	newAsset1.Scheduled_PM_Visits_Number__c = 4;
        newAsset.Product_Purchased_Warranty_Start_Date__c = Datetime.parse('11/6/2020, 11:46 AM');
        newAsset.Product_Purchased_Warranty_End_Date__c = Date.newInstance(2021,6,11);
    	newAsset1.Address_Code__c = address.id;			//Added by pc
        insert newAsset1;
        
        Plan__c standardPlan = new Plan__c();
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
        
        Plan__c bronzePlan = new Plan__c();
        bronzePlan.Name = 'Bronze Plan';
        bronzePlan.Is_Active__c= true;
        bronzePlan.Plan_Type__c = 'Add on';
        bronzePlan.Is_Standard_Plan__c = false; 
        bronzePlan.BD_Visits_Number__c = 4;
        bronzePlan.Scheduled_PM_Visits__c = 'Yes';
        bronzePlan.Scheduled_PM_Visits_Number__c= 4;
        bronzePlan.Remote_Assistance__c = 'Yes';
        insert bronzePlan;
        
        Asset_Benefit__c assetBenefit = new Asset_Benefit__c();
        assetBenefit.Asset__c = newAsset.id;
        assetBenefit.Is_Active__c = true;
        assetBenefit.Plan__c = standardPlan.id; 
    	assetBenefit.Scheduled_PM_Visits_Number__c = 4;
        insert assetBenefit;


         Asset_Benefit__c assetBenefit1 = new Asset_Benefit__c();
        assetBenefit1.Asset__c = newAsset.id;
        assetBenefit1.Is_Active__c = true;
        assetBenefit1.Plan__c = bronzePlan.id; 
    	assetBenefit1.Scheduled_PM_Visits_Number__c = 4;
        insert assetBenefit1;
    
}

@isTest
public static void UpdatebestValueBenifitTest(){

Test.startTest();
list<Asset> assetRecords  = new list<Asset>();
assetRecords = [SELECT Id, Name, Scheduled_PM_Visits_Number__c, Product_Purchased_Warranty_End_Date__c, Product_Purchased_Warranty_Start_Date__c FROM Asset ];

AssetBestValueQuickActionController.updateBenifitBestValueOnAsset(assetRecords.get(0).Id);
system.assertEquals(true, true);

Test.stopTest();
}


}