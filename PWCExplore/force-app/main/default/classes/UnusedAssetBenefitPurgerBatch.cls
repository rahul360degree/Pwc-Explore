/*-----------------------------------------------------------------------------------
* Author        :     Kishor Kumar
* Company       :     Salesforce
* Description   :     Batch job to purge unused Plan Benefit records
 * Inputs        :        
 * Test Class    :    UnusedAssetBenefitPurgerBatchTest
 * History
 * --------
 * 24-11-2020      Kishor Kumar     Initial Release
 * ---------------------------------------------------------------------------------*/
global class UnusedAssetBenefitPurgerBatch implements Database.Batchable<sobject> {
	
    global Database.QueryLocator start(Database.BatchableContext bc) {
        list<String> closedStages = GlobalConstants.OPPORTUNITY_CLOSE_STAGES;
        String queryString = 'SELECT Id FROM Asset_Benefit__c WHERE Asset__c = null AND Quote_Line_Item__r.Quote.Opportunity.StageName IN: closedStages' ; 
        
    	return Database.getQueryLocator(queryString);
    }
    
    global void execute(Database.BatchableContext bc, List<Asset_Benefit__c> scope) {
        try{
            if((scope.size() > 0)&&(Schema.sObjectType.Asset_Benefit__c.isDeletable())){			//GCP22
                delete scope;
            }
        } catch(Exception e){
            Logger.logError('UnusedAssetBenefitPurgerBatch', 'execute', '', e);
        }
        
    }

  	global Void finish(Database.BatchableContext bc) {
       
    }
   
}