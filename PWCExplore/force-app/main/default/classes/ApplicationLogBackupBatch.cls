/*------------------------------------------------------------------------
Author:        Maherzad Chothia/Shreela Nair
Company:       Godrej Infotech
Description:   For hard deleting Application records generated more than 14 days
Inputs:        
Test Class:    
History 
07-02-2024     Maherzad Chothia     Initial Release
----------------------------------------------------------------------------*/
global class ApplicationLogBackupBatch implements Database.Batchable<Sobject>, Database.Stateful, Schedulable {
    private String csvData; // Declaring csvData as class level variable
    public integer count_of_data= 0 ;// variable for the count

    global Database.QueryLocator start(Database.BatchableContext objBatchContext) {
        
        // Adjusting the start date based on weekly schedule
        Date startDate = Date.today().addDays(-15); // Back up logs from the last 14 days
        DateTime formattedStartDate =DateTime.newInstanceGMT(startDate, Time.newInstance(0, 0, 0, 0));
        formattedStartDate = formattedStartDate.addHours(5);
        formattedStartDate = formattedStartDate.addMinutes(30);      
        

        String strQuery;
         system.debug('##### data_fetched: '+strQuery); 
        if (Test.isRunningTest()) {
            strQuery = 'SELECT Id, Name FROM Application_Log__c WHERE CreatedDate >= :formattedStartDate';
        } else {
            Integer n=0;
            String pesNAStr = System.Label.PES_Name_Not_Available;
            if(String.valueOf(System.Label.Application_Log_Last_N_days) != 'NA')
            {
                n = Integer.valueOf(System.Label.Application_Log_Last_N_days);
                system.debug('##### n value: '+n);
            }
            
            strQuery = 'SELECT Category__c, CreatedById, CreatedDate, Id, IsDeleted, LastModifiedById, LastModifiedDate, LastReferencedDate, LastViewedDate, Message__c,Name, Object_Type__c, OwnerId, Priority__c, Record_ID__c, Record_URL__c, Source_Apex_Class__c, Source_Function__c, Source__c, SystemModstamp, Target__c, Type__c, User__c FROM Application_Log__c';
            
            system.debug('#### Value of N: '+String.valueOf(n));
            system.debug('#### value of pesNAStr: '+pesNAStr);
            if ( String.valueOf(n) != pesNAStr) {
                system.debug('#### If statement: '+strQuery);
                strQuery += ' WHERE CreatedDate < LAST_N_DAYS:'+n+'  ORDER BY CreatedDate DESC ';//removed limit of 10000
            }
            else {
                system.debug('##### Else statement: '+strQuery);
                strQuery+= '  CreatedDate < :formattedStartDate ORDER BY CreatedDate DESC ';  //removed limit of 10000
            }
            
        }
        return Database.getQueryLocator(strQuery);
    }

    global void execute(Database.BatchableContext objBatchContext, List<Application_Log__c> applLog) {
        try {
            
            // Check if the batch is running in a test context
            Boolean isTest = Test.isRunningTest();

            // Initialize a class level CSV data string if it's null
            if (csvData == null) {
                csvData = 'Id,Name,Category__c,CreatedBy,CreatedDate,IsDeleted,LastModifiedBy,LastModifiedDate,LastReferencedDate,LastViewedDate,Message__c,Object_Type__c,OwnerId,Priority__c,Record_ID__c,Record_URL__c,Source_Apex_Class__c,Source_Function__c,Source__c,SystemModstamp,Target__c,Type__c,User__c,\n';                	

            }

            // Create CSV data and append it to the existing CSV data
            for (SObject record : applLog) {
                String message = record.get('Message__c') != null ? (String)record.get('Message__c') : '';
                // Replace newline characters with space
                message = message.replace('\n', ';');
                // Replace commas within the message field value
                message = message.replace(',', ';'); // Replace with a placeholder character  
				///Need to uncomment below
                csvData += record.get('Id') + ',' + record.get('Name') + ',' + record.get('Category__c')+ ','+ record.get('CreatedById')+ ',' + record.get('CreatedDate')+ ',' + record.get('IsDeleted')+ ',' + record.get('LastModifiedById') + ',' + record.get('LastModifiedDate')+ ',' + record.get('LastReferencedDate')+ ',' + record.get('LastViewedDate')+ ',' +message+ ',' + record.get('Object_Type__c')+ ',' + record.get('OwnerId')+ ',' + record.get('Priority__c')+ ',' + record.get('Record_ID__c')+ ',' + record.get('Record_URL__c')+ ',' + record.get('Source_Apex_Class__c')+ ',' + record.get('Source_Function__c')+ ',' + record.get('Source__c')+ ',' + record.get('SystemModstamp')+ ',' + record.get('Target__c')+ ',' + record.get('Type__c')+ ',' + record.get('User__c')+ '\n';
            }

            // After successful backup, delete the records
            Database.Delete(applLog, false); ///Need to uncomment
            Database.emptyRecyclebin(applLog);
            //count_of_data += applLog.size();

        } catch (Exception e) {
            System.debug('Exception' + e.getMessage());
        }
    }

    global void finish(Database.BatchableContext objBatchContext) {
        // Send email with CSV data as attachment
        sendEmail();  ///Need to uncomment
        //system.debug('##### count_of_data: '+count_of_data) 
 
    }

    private void sendEmail() {
        try {
            // Save the CSV data to a Blob
            Blob csvBlob = Blob.valueOf(csvData);

            // Create an email message with the CSV file as an attachment
            Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
            attachment.setFileName('BackupFile_Application_Log.csv');
            attachment.setBody(csvBlob); 

            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setSubject('Backup File of Application Log');
            email.setPlainTextBody('Please find the attached backup file.');

            List<string> setToAddresses=new List<string>();
            setToAddresses.addall(System.Label.Application_Log_To_Label.split(',')); 
            email.setToAddresses(setToAddresses);
            
            List<string> setCCAddresses=new List<string>();
            setCCAddresses.addall(System.Label.Application_Log_CC_Label.split(','));  
            email.setCcAddresses(setCCAddresses);  
            
            email.setFileAttachments(new Messaging.EmailFileAttachment[]{attachment});

            // Send the email
            Messaging.sendEmail(new Messaging.SingleEmailMessage[]{email});
        } catch (Exception e) {
            System.debug('Exception' + e.getMessage());
        }
    }

    // Implementing the scheduleJob method from the Schedulable interface
    global void execute(SchedulableContext ctx) {
        try {
            ApplicationLogBackupBatch bct = new ApplicationLogBackupBatch();
            database.executebatch(bct,100);
            }
        catch (Exception ex) {
            System.debug('Error: '+ex.getStackTraceString());
            Logger.logError('ApplicationLogBackupBatch', 'execute', '', ex);
            }
        

    }
}