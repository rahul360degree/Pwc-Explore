/*
 * Base class for all the trigger handlers.
 * Every trigger handler class must extend this class and 
 * implement the required methods only. 
*/

public virtual class VTriggerHandler {
    public virtual void BeforeInsert(List<SObject> newItems){system.debug('Virtual');}
 
    public virtual void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){}
 
    public virtual void BeforeDelete(Map<Id, SObject> oldItems){}
 
    public virtual void AfterInsert(Map<Id, SObject> newItems){}
 
    public virtual void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){}
 
    public virtual void AfterDelete(Map<Id, SObject> oldItems){}
 
    public virtual void AfterUndelete(Map<Id, SObject> oldItems){}
 
    public virtual Boolean IsDisabled(){ return false;}
}