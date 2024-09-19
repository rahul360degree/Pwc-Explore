/*------------------------------------------------------------------------
Author:        Mahith Madwesh
Company:       Salesforce
Description:   Trigger to Platform Event records for Asset_Sharing__e
Inputs:        NA
Test Class:   

History
17-12-2020      Mahith Madwesh     Initial Release
----------------------------------------------------------------------------*/
trigger AssetSharingPlatformEventTrigger on Asset_Sharing__e (after insert) {

    Integer counter = 0;
    Integer BatchSize = Integer.valueOf(partial_transaction_control__c.getValues('Asset Sharing').Batch_Size__c);
    if(trigger.new.size()>BatchSize){
      list<Asset_Sharing__e>  assetSharingList = new list<Asset_Sharing__e>();
         for (Asset_Sharing__e ev : Trigger.New) {
      // Increase batch counter.
      counter++;
      // Only process the first 200 event messages
     
      if (counter > BatchSize) {
        // Resume after the last successfully processed event message
        // after the trigger stops running. 
        // Exit for loop.
        break;
      }else{
        if(Math.mod(Integer.valueOf(String.valueof(ev.replayId).right(1)),2) == 0){
            assetSharingList.add(ev);
        }
      }

      // Process event message.
      // ....

      // Set Replay ID after which to resume event processing 
      // in new trigger execution.
      EventBus.TriggerContext.currentContext().setResumeCheckpoint(ev.ReplayId);
       
    }
        AssetSharingProcessor.calculateSharing(assetSharingList);
    }else{
        AssetSharingProcessor.calculateSharing(trigger.new);
    }
   
    
}