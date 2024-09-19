public class CreateWarrantyClaimRequestForAsset {
    public static final Id WARRANTY_TYPE_RECORDTYPE_ID = Schema.SObjectType.Claim_Requests__c.getRecordTypeInfosByDeveloperName().get('Warranty').getRecordTypeId();
    public static Set<Id> duplicateEWPContractsAssetIds=new Set<Id>();
    public static void createWarrantyClaims(Map<Id,Asset> idVsAsset) {
        List<Claim_Requests__c> claimRequests = new List<Claim_Requests__c>();
        List<Claim_Requests__c> claimRequestsToInsert=new List<Claim_Requests__c>();
        String csgHead = getMHECSGHead();
        for(Id assetId : idVsAsset.keySet()){
            Claim_Requests__c cr = new Claim_Requests__c();
            cr.RecordTypeId = WARRANTY_TYPE_RECORDTYPE_ID;
            cr.Asset__c = assetId;
            cr.Is_System_Generated__c = true;
            if(string.isNotBlank(csgHead)){
                cr.OwnerId = csgHead;
            }
            claimRequests.add(cr);
        }
        ClaimRequestTriggerDefaultHelper.checkDuplicateEWPContractForWarrantyClaim(claimRequests,idVsAsset);
        for(Claim_Requests__c cr:claimRequests){
            if(!duplicateEWPContractsAssetIds.contains(cr.Asset__c)){
                claimRequestsToInsert.add(cr);
            }
        }
        if(claimRequestsToInsert != null && claimRequestsToInsert.size() > 0){
            insert claimRequestsToInsert;
        }
    }
    
    static String getMHECSGHead(){
        return [Select Id, Value__c, DeveloperName From Application_Settings__mdt Where DeveloperName = 'MHE_CSG_Head' limit 1].Value__c;
    }
}