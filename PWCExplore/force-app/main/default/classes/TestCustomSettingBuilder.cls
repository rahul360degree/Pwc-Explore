@isTest
public class TestCustomSettingBuilder {
    /*------------------------------------------------------------------------
    Description:   This method is for generating Runtime Execution custom setting records.
    Inputs:        noOfRecords i.e. no of records to be generated  (List<String>)
                   isFire__ (boolean), List<String> , isDisable(boolean)
    ----------------------------------------------------------------------------*/
	public static Runtime_Execution__c generateRuntimeExecutionRecords(List<String> isFireFields, Boolean isFire, List<String> isDisableFields, Boolean isDisable) {
        Runtime_Execution__c runTimeExecution = new Runtime_Execution__c();
        if(isFireFields != null && isFireFields.size() > 0 && isFire != null) {
            for(String name : isFireFields) {
                runTimeExecution.put(name, isFire);
            }
        } 
        if(isDisableFields != null && isDisableFields.size() > 0 && isDisable != null) {
            for(String name : isDisableFields) {
                runTimeExecution.put(name, isDisable);
            }
        } 
        
        return runTimeExecution;
    }   
}