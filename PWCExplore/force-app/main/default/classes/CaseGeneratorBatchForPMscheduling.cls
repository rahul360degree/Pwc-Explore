/*------------------------------------------------------------------------
Author:        Suwarna Rao
Company:       Salesforce
Description:   Batch class to create Case record for PM Visits.
Inputs:        
Test Class:   CaseGeneratorBatchForPMschedulingTest
----------------------------------------------------------------------------*/

public class CaseGeneratorBatchForPMscheduling implements Database.Batchable<sObject> {
    String query; 
    Map<String, String> caseCreationStatusMap = new Map<String, String>();
    
    public CaseGeneratorBatchForPMscheduling() {
        CaseGeneratorBatchForAssetHelper ca = new CaseGeneratorBatchForAssetHelper();
        query = ca.generateQuery();      
        caseCreationStatusMap = ca.getCaseCreationStatusValues();
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC) {
        //Get the Asset records which are having the PM visit scheduled in next 7 days and case is not already created. 
        return Database.getQueryLocator(query);       
    }
    
    //Create case record for each CLI
    public void execute(Database.BatchableContext BC, List<Asset> Assets) { 
        
        List<Case> casesToCreate = new List<Case>();   
        List<Asset> assetsToUpdate = new List<Asset>();   
        Id mheRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('MHE_Service_Request').getRecordTypeId();
        
        for(Asset a: Assets){
            //Logic to Generate Case recrd for each CLI record
            Case c= new case(Subject='PM Visit Scheduled',
                             Status = GlobalConstants.CASE_STATUS_REGISTERED,
                             AssetId = a.Id,
                             AccountId = a.AccountId,
                             ContactId = a.ContactId,
                             Origin = GlobalConstants.CASE_ORIGIN_AUTOMATED,
                             Type = 'PM',
                             Call_Category__c = 'Service Audit',
                             Is_Equipment_In_Operational_Condition__c = 'Yes',
                             Asset_Serial_Number__c = a.Equipment_Serial_No__c,
                             OwnerId = a.OwnerId,
                             RecordTypeId = mheRecordTypeId,
                             Description = 'Scheduled Preventive Maintenance',
                             Is_System_Created__c = TRUE
                            );
            casesToCreate.add(c);
            
        }      
        //Create Case record & update Asset status for the created case
        try{
            database.SaveResult[] results = database.insert(casesToCreate,false);            
            Integer loopCounter = 0;
            set<Id> insertedCaseIds = new set<Id>();
            set<Id> failedAssetsIds = new set<Id>();
            
            for(database.SaveResult result : results){
                if (result.isSuccess()) 
                    insertedCaseIds.add(result.getId());
                Else{
                    failedAssetsIds.add(casesToCreate[loopCounter].AssetId);
                }
                loopCounter++;
            }
            String body = '<html> <body>';
            if(insertedCaseIds.size() > 0){               
                body +='<p>Please note PM calls for the following assets were successfully created through the automated batch</p>';
                body +='<table  border="1" style="border-collapse: collapse background-color:#008000"> <tr> <th>SR:</th> <th>Asset</th></tr>';
                Integer i =1;
                for(Case sr : [SELECT Id, AssetId, Asset.Case_creation_status__c,Asset.Name FROM Case WHERE Id IN : insertedCaseIds]){
                    //logic to update case creation status on Asset
                    if(String.isBlank(sr.Asset.Case_creation_status__c)){
                        assetsToUpdate.add(new Asset(Id = sr.AssetId, Case_creation_status__c = 'Case_1_created'));
                    } else if(String.isNotBlank(sr.Asset.Case_creation_status__c) 
                              && caseCreationStatusMap.containsKey(sr.Asset.Case_creation_status__c)){
                                  assetsToUpdate.add(new Asset(Id = sr.AssetId, Case_creation_status__c = caseCreationStatusMap.get(sr.Asset.Case_creation_status__c)));
                              }
                    body+='<tr>';
                    body+='<td>'+i +'</td>';
                    body+='<td>'+sr.Asset.Name +'</td>';
                    body+='</tr>';
                    i++;
                }
                
                body +='</table>';
                body +='<br/>';
            }
            if(failedAssetsIds.size() > 0){
                body +='<p>Please note the PM calls for the following assets were not created through the automated batch process.</p>';
                body +='<table  border="1" style="border-collapse: collapse background-color:#ff0000"> <tr> <th>SR:</th> <th>Asset</th></tr>';
                Integer i=1;
                for(Asset a : [SELECT Id, Name, Case_creation_status__c FROM Asset WHERE Id IN : failedAssetsIds]){
                    //logic to update case creation status on Asset
                    if(String.isBlank(a.Case_creation_status__c)){
                        assetsToUpdate.add(new Asset(Id = a.Id, Case_creation_status__c = 'Case_1_created'));
                    } else if(String.isNotBlank(a.Case_creation_status__c)&& caseCreationStatusMap.containsKey(a.Case_creation_status__c)){
                        assetsToUpdate.add(new Asset(Id = a.Id, Case_creation_status__c = caseCreationStatusMap.get(a.Case_creation_status__c)));
                    }
                    body+='<tr>';
                    body+='<td>'+i +'</td>';
                    body+='<td>'+a.Name +'</td>';
                    body+='</tr>';
                    i++;
                }
                
                body +='</table>';               
                body +=' <br/>Kindly take manual action on the above, as appropriate.';
                
            }
            body +=' <br/><br/><br/>Thanks!';
            body +='</body> </html>';
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setOrgWideEmailAddressId([SELECT id,displayName FROM OrgWideEmailAddress WHERE Address='onecrm@godrej.com'].Id);
            mail.setUseSignature(false);
            List<string> setToAddresses=new List<string>();
            setToAddresses.addall(System.Label.PM_Failure_Recipient.split(';')); 
            mail.setToAddresses(setToAddresses); 
            mail.setSubject('Daily PM Call auto-generation status');
            mail.setHtmlBody(body);
            mail.setSaveAsActivity(false);
            List<Messaging.Email> emailList=new List<Messaging.Email>();
            emailList.add(mail);  
            Messaging.sendEmail(emailList);
            
            update assetsToUpdate;
        } catch(Exception ex){
            Logger.logError('CaseGeneratorBatchForAsset', 'Execute', '', ex);
        }                         
    }   
    
    public Void finish(Database.BatchableContext bc) {
        //Logic for post processing of batch records
    }    
}