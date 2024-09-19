/* ==============================================
* @class name: GenericBulkDeleteBatch
* @author: GITL (PSM)
* @purpose: To delete all the records of the object in label , older than days specified in the CMD
* @created date (mm/dd/yyyy) :  07/06/2023
================================================*/
global with sharing class GenericBulkDeleteBatch implements Database.Batchable<Sobject>{
    Private Integer intPurgeWindow; //Class Level Variable 
    Private List<Delete_Window_Configuration__mdt> lstBatchSetting;
    
 	/*=================================================      
    *@description : Default constructor for Batch class
    *@param 	  : NA
    *@return 	  : Void
    ===================================================*/
    global GenericBulkDeleteBatch(){
        lstBatchSetting = new List<Delete_Window_Configuration__mdt>();//Variable Initialization
        //fetching the defined Purge Window size, stored in cmd.
        lstBatchSetting = [SELECT BulkPurgeWindow__c FROM Delete_Window_Configuration__mdt limit 1 ];
        if(!lstBatchSetting.isEmpty()){
            intPurgeWindow = Integer.valueOf(lstBatchSetting[0].BulkPurgeWindow__c);
        }
    }
    
    /* ========================================================
    * @method name : start()
    * @author : GITL(PSM)
    * @purpose: To prepare the list of old records and pass it to execute() for deletion
    * @param : objBatchContext - Database.BatchableContext
    * @return: Database.QueryLocator
    * @created date (mm/dd/yyyy) : 07/06/2023
    ============================================================*/
    global Database.QueryLocator start(Database.BatchableContext objBatchContext) {              
        String strQuery;//Variable Declaration
        if(Test.isRunningTest())
            strQuery = Label.Generic_Delete_Fetch_Test;
        else
        	strQuery = Label.Generic_Delete_Fetch + intPurgeWindow;//getting records older than specified days using the LAST_N_DAYS SOQL Clause
        return Database.getQueryLocator(strQuery);//this will be the scope for execute method
    }
    
    /* ========================================================
    * @method name : execute()
    * @author : GITL (PSM)
    * @purpose: To perform hard deletion on the records
    * @param : lstOldLogs - List of records to be deleted
    * @return: void
    * @created date (mm/dd/yyyy) : 07/06/2023
    ============================================================*/
    global void execute(Database.BatchableContext objBatchContext, List<sobject> lstOldLogDetails) {
        //Delete Records
        try{
            Database.Delete (lstOldLogDetails,false);
            DataBase.emptyRecyclebin(lstOldLogDetails);
        }catch(Exception e){
            system.debug('Exception'+e.getMessage());
        }
    } 
    
    global void finish(Database.BatchableContext objBatchContext) {        
    }
}