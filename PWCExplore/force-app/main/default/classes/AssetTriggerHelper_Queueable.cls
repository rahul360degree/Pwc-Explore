public class AssetTriggerHelper_Queueable implements Queueable{
    List<AssetWrapper> assetList;
    
        public AssetTriggerHelper_Queueable(List<AssetWrapper> assetList){
        this.assetList = assetList;
    } 
    public void execute(QueueableContext context) {
        createInstallationCase(assetList);
    }
    
    
    /*------------------------------------------------------------------------
	Author:        Varun Rajpoot
	Company:       Salesforce
    Description:   Method to create Installation type Case record 
    Inputs:        NA
    Test Class:    AssetTriggerHelperTest
    History
    11-10-2021     Varun Rajpoot    Initial Release
    ----------------------------------------------------------------------------*/
    public List<Case> createInstallationCase(List<AssetWrapper> assetList){
        List<Case> caseList = new List<Case>();
        for(AssetWrapper assetRecord:assetList){
            Case installationCase = new Case();
            installationCase.AccountId = assetRecord.objAsset.AccountId;
            installationCase.Origin = GlobalConstants.CASE_ORIGIN_AUTOMATED;
            installationCase.Status = GlobalConstants.CASE_STATUS_REGISTERED;
            installationCase.Type = GlobalConstants.CASE_TYPE_COMMISSIONING; 
            installationCase.Call_Category__c = GlobalConstants.CASE_CALL_CATEGORY_COURTESY;
            installationCase.Subject = System.label.Installation_Service_Request_Description;
            installationCase.Description = System.label.Installation_Service_Request_Description;
            installationCase.Asset_Serial_Number__c = assetRecord.objAsset.Equipment_Serial_No__c;
            installationCase.AssetId = assetRecord.objAsset.Id;   
            installationCase.ContactId = assetRecord.objAsset.ContactId; 
            installationCase.recordtypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('MHE_Service_Request').getRecordTypeId();
            installationCase.Applicable_For_Pincode_Based_Assignment__c = true;
            installationCase.Is_System_Created__c = TRUE;                                       
            installationCase.Branch__c = assetRecord.objAsset.Branch__c;
            caseList.add(installationCase);
        }
        
        
        try{
            if(caseList.size() > 0)
                insert caseList;
        } catch(Exception ex){
            Logger.logError('AssetTriggerHelper_Queueable', 'createInstallationServiceRequest', '', ex, 'P1');
        }
        return caseList;
    }
}