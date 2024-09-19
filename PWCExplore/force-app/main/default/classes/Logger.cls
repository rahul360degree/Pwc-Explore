public without sharing class Logger {
  	/*
	 * Description: Method to log an error 
	 * Param: Apex Class Name, Apex Method Name, Reference Record Id if any and Exception object
	*/
    public static void logError(String sourceClassName, String sourceMethodName, String referenceId, Exception ex) {
    	Application_Log__c logRecord = new Application_Log__c(Type__c = GlobalConstants.LOG_TYPE.ERROR.name(),
                                                              Source_Apex_Class__c = sourceClassName,
                                                              Source_Function__c = sourceMethodName,
                                                              Message__c = 'ERROR: ' + ex.getMessage() + '\nSTACK TRACE: ' + ex.getStackTraceString(),
                                                              Record_ID__c = referenceId,
                                                              User__c = UserInfo.getUserId());
        if(!Test.isRunningTest()) insert logRecord;
    }
    
    /*
	 * Description: Method to log an error 
	 * Param: Module Name, Apex Class Name, Apex Method Name, Reference Record Id if any and Exception object
	*/
    public static void logError(String category, String sourceClassName, String sourceMethodName, String referenceId, Exception ex) {
    	Application_Log__c logRecord = new Application_Log__c(Type__c = GlobalConstants.LOG_TYPE.ERROR.name(),
                                                              Source_Apex_Class__c = sourceClassName,
                                                              Source_Function__c = sourceMethodName,
                                                              Message__c = 'ERROR: ' + ex.getMessage() + '\nSTACK TRACE: ' + ex.getStackTraceString(),
                                                              Record_ID__c = referenceId,
                                                              User__c = UserInfo.getUserId(),
                                                              Category__c = category);
        if(!Test.isRunningTest()) insert logRecord;
    }

    /*
	 * Description: Method to log batch status
	 * Param: Module Name, Apex Class Name, Message
	*/
    public static void logError(String category, String sourceClassName, String message) {
    	Application_Log__c logRecord = new Application_Log__c(Type__c = GlobalConstants.LOG_TYPE.INFO.name(),
                                                              Source_Apex_Class__c = sourceClassName,
                                                              Message__c = message,
                                                              User__c = UserInfo.getUserId(),
                                                              Category__c = category);
        if(!Test.isRunningTest()) insert logRecord;
    }

    /*
	 * Description: Method to log an error 
	 * Param: Apex Class Name, Apex Method Name, Reference Record Id if any, Exception object and priority
	*/
    public static void logError(String sourceClassName, String sourceMethodName, String referenceId, Exception ex, String priority) {
    	Application_Log__c logRecord = new Application_Log__c(Type__c = GlobalConstants.LOG_TYPE.ERROR.name(),
                                                              Source_Apex_Class__c = sourceClassName,
                                                              Source_Function__c = sourceMethodName,
                                                              Message__c = 'ERROR: ' + ex.getMessage() + '\nSTACK TRACE: ' + ex.getStackTraceString(),
                                                              Record_ID__c = referenceId,
                                                              Priority__c = priority,
                                                              User__c = UserInfo.getUserId());
        if(!Test.isRunningTest()) insert logRecord;
    }
    
    /*
	 * Description: Method to log debug statements
	 * Param: Module Name, Apex Class Name, Message
	*/
    public static void logDebugInfo(String sourceClassName, String sourceMethodName, sobject obj,List<Sobject> lstObj) {
    	Application_Log__c logRecord = new Application_Log__c(Type__c = GlobalConstants.LOG_TYPE.INFO.name(),
                                                              Source_Apex_Class__c = sourceClassName,
                                                              Source_Function__c = sourceMethodName,
                                                              Message__c = 'Debug object:'+obj+'Debug List:'+lstObj,
                                                              User__c = UserInfo.getUserId());
        if(!Test.isRunningTest()) insert logRecord;
    }
}