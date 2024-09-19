/*------------------------------------------------------------------------
	@Author:        Saurabh Mehta
	@File Name:     updatenegotiationLog.apxt
	@Company:       Stetig
	@Description:   NA
	@Inputs:        NA
	@Last Modified: 26/11/2021
	@Test Class:    
----------------------------------------------------------------------------*/
trigger updatenegotiationLog on Term_Item__c(before insert, before update, after insert, after update) {
    if(Trigger.isAfter) {
    
    }
    // Call to handler for specific scenarios
    if(Trigger.isBefore){ 
	
	   if(Trigger.isUpdate) {
	
		TermCaluseHandller.updatenegotiationLog(Trigger.new);
		
		}
	}
}