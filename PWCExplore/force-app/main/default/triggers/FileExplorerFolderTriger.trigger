/*------------------------------------------------------------------------
Author:        Vikrant Mahantare

Description:   Trigger to hadle database events on 'qsyd_FE__FileExplorerFolder__c' records
Inputs:        NA
----------------------------------------------------------------------------*/
trigger FileExplorerFolderTriger on qsyd_FE__FileExplorerFolder__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
            TriggerDispatcher.Run(new FileExplorerTriggerHandler());
}