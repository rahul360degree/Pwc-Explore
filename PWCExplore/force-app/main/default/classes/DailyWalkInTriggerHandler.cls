/**
 * @Description       : SIEPB-119: Added Validation to stop duplicate Records
 * @Author            : Varun Rajpoot
 * @last modified on  : 12-08-2023
 * @last modified by  : Varun Rajpoot
 * Modifications Log
 * Ver   Date         Author          Modification
 * 1.0   12-08-2023   Varun Rajpoot   Initial Version
**/
public with sharing class DailyWalkInTriggerHandler extends VTriggerHandler{
    public override void BeforeInsert(list<SObject> newItems){
        DailyWalkInTriggerHelper helper = new DailyWalkInTriggerHelper();
        helper.duplicateCheck((list<Daily_Walk_Ins__c>) newItems);
    }
}