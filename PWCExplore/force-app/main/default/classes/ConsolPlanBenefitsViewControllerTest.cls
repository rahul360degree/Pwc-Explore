/*------------------------------------------------------------------------
Author:        Kishor KUmar
Company:       Salesforce
Description:   Test class for ConsolidatedPlanBenefitsViewController
Inputs:            

----------------------------------------------------------------------------*/
@isTest
public class ConsolPlanBenefitsViewControllerTest {
	@testsetup
    private static void testData() {
        //Create Account record
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
        
        //Create Asset record
        Asset newAsset = new Asset();
        newAsset.Name= 'Test Asset';
        newAsset.AccountId = newAccount.id;
        newAsset.Status = 'Purchased';
        newAsset.BD_Visits_Number__c = 5;
        newAsset.Scheduled_PM_Visits_Number__c = 6;
        newAsset.Coverage__c = 'KFTWC01200001';
        newAsset.Type_of_Warranty__c = 'Special Warranty';
        newAsset.Address_Code__c = address.id;			//Added by pc
        insert newAsset;
        
        //Create Case record
        Case caseRecord = new Case();
        caseRecord.AccountId = newAccount.Id;
        caseRecord.AssetId = newAsset.Id;
        caseRecord.Origin = 'Automated';
        caseRecord.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(GlobalConstants.CASE_RECORDTYPE_MHE_SERIVCE_REQUEST).getRecordTypeId();
        
        insert caseRecord;
        
        //Create Asset Benefit record
        Asset_Benefit__c newAssetBenefit = new Asset_Benefit__c();
        newAssetBenefit.Name= 'Plan A';
        newAssetBenefit.Asset__c = newAsset.id;
        newAssetBenefit.Is_Active__c = true; 
        newAssetBenefit.BD_Visits_Number__c = 4;
        newAssetBenefit.Scheduled_PM_Visits_Number__c = 4;
        
        insert newAssetBenefit;
    }
    
    
    @isTest private static void testGetContractBenefitDetails(){
        test.startTest();        
        Case caseRec = [SELECT Id FROM Case LIMIT 1];
		
        String wrappedString = ConsolidatedPlanBenefitsViewController.getContractBenefitDetails(caseRec.Id);
        System.assert(String.isNotBlank(wrappedString));
        test.stopTest();          
          
    }
    
    @isTest private static void testGetAccountBenefitDetails(){
        test.startTest();        
        Case caseRec = [SELECT Id FROM Case LIMIT 1];
		
        String wrappedString = ConsolidatedPlanBenefitsViewController.getAccountBenefitDetails(caseRec.Id);
        System.assert(String.isNotBlank(wrappedString));
        test.stopTest();          
          
    }

    @isTest private static void testGetOverridenBenefitDetails(){
        test.startTest();        
        Case caseRec = [SELECT Id FROM Case LIMIT 1];
		
        String wrappedString = ConsolidatedPlanBenefitsViewController.getOverridenBenefitDetails(caseRec.Id);
        System.assert(String.isNotBlank(wrappedString));
        test.stopTest();          
          
    }
    
    @isTest private static void testRecalculateBenefitDetails(){
        test.startTest();        
        Case caseRec = [SELECT Id FROM Case LIMIT 1];
		
        Boolean isSuccess = ConsolidatedPlanBenefitsViewController.recalculateBenefitDetails(caseRec.Id);
        System.assert(isSuccess != null);
        test.stopTest();          
          
    }
}