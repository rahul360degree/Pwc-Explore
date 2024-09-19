/**
 * @Description       : SIEPB-119: Added Validation to stop duplicate Records
 * @Author            : Varun Rajpoot
 * @last modified on  : 12-08-2023
 * @last modified by  : Varun Rajpoot
 * Modifications Log
 * Ver   Date         Author          Modification
 * 1.0   12-08-2023   Varun Rajpoot   Initial Version
**/
trigger DailyWalkInTrigger on Daily_Walk_Ins__c (before insert) {
    TriggerDispatcher.Run(new DailyWalkInTriggerHandler());
}