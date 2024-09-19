/**
* @description       : 
* @author            : vrajpoot@godrej.com
* @group             : 
* @last modified on  : 03-07-2023
* @last modified by  : vrajpoot@godrej.com
**/
global with sharing class SOAEmailBatch implements Database.Batchable<sObject>,Schedulable{
    private static List<Approval.ProcessSubmitRequest> reqList = new List<Approval.ProcessSubmitRequest>();
    //prepare the query
    //
    Set<Id> soaIds = new Set<Id>();
    global SOAEmailBatch(Set<Id> ids){
        soaIds = ids;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {        
        String status = GlobalConstants.statements_Attached;
        Set<String> automationLevels = new Set<String>{'Email','Full'};
            String query = 'Select Id,Name,Branch_Accountant__r.Id,Account__c,Account__r.Account_Code__c,Account__r.Name,'
            +'Status__c,Branch_Accountant__r.Email,Area_Sales_Manager__r.Email,Account__r.DSA_Contact_User__r.Email,Account__r.DSA_Contact_User__r.Id,'
            +'Account__r.Owner.Email,Mismatch__c,Branch_Accountant__c,OwnerId,Awaiting_TP_Approval__c,DSA_Automation_Level__c,Account__r.DSA_Automation_Level__c,'
            +'Account__r.DSA_Contact_User__c,Account_Name__c,Calendar_Month__c,Statement_Year__c '+
            +',Account__r.DSA_Contact_User__r.FirstName, Account__r.DSA_Contact_User__r.LastName,Area_Sales_Manager__r.FirstName,Area_Sales_Manager__r.LastName'
            +',Branch_Accountant__r.FirstName,Branch_Accountant__r.LastName,Period_Year__c,Period_Month__c,Area_Sales_Manager__r.Id'
            +' FROM Statement_of_Account__c '
            +' WHERE Status__c=:status AND Account__r.DSA_Automation_Level__c IN: automationLevels ';
        	
        if(!soaIds.isEmpty()){
            query +=' AND ID IN:soaIds';
        }
        
        //query +=' WITH SECURITY_ENFORCED Order by DSA_Automation_Level__c ';
        return Database.getQueryLocator(query);
    }
    
    //execute the records
    public static void execute(Database.BatchableContext BC, List<Statement_of_Account__c> soaRecordsList) { 
        //        try{
        Map<Id,List<ContentVersion>> soaWithCVFileMap = soaWithCVFileMap(soaRecordsList);
        List<Messaging.SingleEmailMessage> emailList = getMail(soaRecordsList ,soaWithCVFileMap);
        System.debug(emailList);
        if(!emailList.isEmpty()){
            try{
                Messaging.SendEmailResult [] result =  Messaging.sendEmail(emailList);
            }catch(Exception ex){
                System.debug('Error: '+ex.getStackTraceString());
            }
        }
        System.debug(soaRecordsList);
        Database.SaveResult[] saveProdcuts = Database.update(soaRecordsList, false);
        System.debug(saveProdcuts);
        for (Database.SaveResult sr : saveProdcuts) {
            if (!sr.isSuccess()) {
                for(Database.Error err : sr.getErrors()) {
                    System.debug('Error Code: '+err.getStatusCode() + ': ' + err.getMessage()+ ' Error Field: '+err.getFields());
                }
            }
        }

        if(!reqList.isEmpty()){
            try{
                List<Approval.ProcessResult> approvalresult = Approval.process(reqList);
            }catch(Exception ex){
                System.debug('Error: '+ex.getStackTraceString());
            }
        }

        
    }
    //finish method
    global void finish(Database.BatchableContext BC) {
        // execute any post-processing operations like sending email
    }   
    
    //Scehdule the email
    public void execute(SchedulableContext ctx) {
        //SOAEmailBatch soa = new SOAEmailBatch(); 
       // Database.executeBatch(soa,25);
    }

    //prepare Map of files with key SOA Id
    private static Map<Id,List<ContentVersion>> soaWithCVFileMap(List<Statement_of_Account__c> soaRecordsList){
        Set<Id> soaIds = new Set<Id>();
        for(Statement_of_Account__c soa : soaRecordsList){
            soaIds.add(soa.Id);
        }
        Set<Id> contentDocumentIdSet = new Set<Id>();         
        
        //Get all content document link where linkedEntityid=: rID. 
        Map<Id,ContentDocumentLink> cdLink = new Map<Id,ContentDocumentLink>([SELECT ContentDocumentId,ContentDocument.title,Id,LinkedEntityId,ShareType
                                                                              FROM ContentDocumentLink WHERE LinkedEntityId IN:soaIds ]) ;
        Map<Id,Id>cdIdVscdLinkId = new Map<Id,Id>();
        for(ContentDocumentLink doc : cdLink.values()){
            contentDocumentIdSet.add(doc.ContentDocumentId);
            cdIdVscdLinkId.put(doc.ContentDocumentId,doc.Id);
        }    
        
        //Get all related contentVersion file         
        Map<Id,List<ContentVersion>> contentVersionWithSOAID = new Map<Id,List<ContentVersion>> ();
        for(ContentVersion cvFile: [SELECT VersionData, title, FileType, FileExtension,ContentDocumentId
                                    FROM ContentVersion 
                                    WHERE ContentDocumentId IN : contentDocumentIdSet AND IsLatest = true])
        {
            Id soaId= cdLink.get(cdIdVscdLinkId.get(cvFile.ContentDocumentId)).LinkedEntityId;
            if(!contentVersionWithSOAID.containsKey(soaId)){
                contentVersionWithSOAID.put(soaId,new List<ContentVersion>());
            }
            contentVersionWithSOAID.get(soaId).add(cvFile);
            
        }
        return contentVersionWithSOAID;
    }   
    
    //Prepare the Email to Send and submit
    private static List<Messaging.SingleEmailMessage> getMail(List<Statement_of_Account__c> soaRecordsList,Map<Id,List<ContentVersion>> soaWithCVFileMap ){
        EmailTemplate misMatchTemplate = getMismatchEmailTemplate();
        EmailTemplate dsaEmailTemplate = getDSAEmailTemplate();
        Id orgEmailId = orgWideEmailAddress();
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        for(Statement_of_Account__c soa : soaRecordsList){
            if(soaWithCVFileMap.containsKey(soa.Id)){
                Messaging.SingleEmailMessage mail= new Messaging.SingleEmailMessage();            
                //defining list of email attachments
                List<Messaging.EmailFileAttachment> attach= new list<Messaging.EmailFileAttachment>();                
                //For each content version file get the file name, extension, version and add into the attachment list called 'attach'
                for(ContentVersion file : soaWithCVFileMap.get(soa.Id)){
                    Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
                    efa.setFileName(file.title.Trim()+'.'+file.FileExtension.Trim());
                    efa.setBody(file.VersionData);
                    attach.add(efa);
                } 
                boolean isMismatched = soa.Mismatch__c ? true: false;
                
                string toEmail = '', ccEmail = '', emailSubject = '', emailBody = '';
                EmailTemplate emailTemplate;
                if(isMismatched){
                    toEmail = soa?.Branch_Accountant__r?.Email;
                    // toEmail = soa?.Branch_Accountant__r?.Id;
                    ccEmail = soa?.Account__r?.Owner?.Email;
                    emailSubject = 'Monthly DSA Statement Mismatch for ' +soa.Account_Name__c + ' for '+ soa.Calendar_Month__c+ ' '+soa.Statement_Year__c+' - '+soa.Account__r.Name +' - BP Code '+SOA.Account__r.Account_Code__c;
                    emailBody = replaceMismatchedEmailBody(misMatchTemplate.HtmlValue,SOA);
                    emailTemplate = misMatchTemplate;
                    soa.Awaiting_TP_Approval__c = false;
                }else if(soa.Account__c<>null && soa.Account__r.DSA_Automation_Level__c<>null && soa.Account__r.DSA_Automation_Level__c == 'Email'){
                    toEmail = soa?.Account__r?.DSA_Contact_User__r?.Email.trim();
                    // toEmail = soa?.Account__r?.DSA_Contact_User__r?.Id;
                    ccEmail = soa?.Area_Sales_Manager__r?.Email;
                    emailSubject = 'Monthly Statement of Account with Godrej Appliances ' +soa.Calendar_Month__c +' '+soa.Statement_Year__c+' - '+soa.Account__r.Name+ ' - BP Code ' + soa.Account__r.Account_Code__c;
                    emailBody = replaceTradePartnerEmailBody(dsaEmailTemplate.HtmlValue,SOA);
                    emailTemplate = dsaEmailTemplate;
                    soa.Awaiting_TP_Approval__c = false;
                }else if(soa.Account__c<>null && soa.Account__r.DSA_Automation_Level__c<>null && soa.Account__r.DSA_Automation_Level__c == 'Full'){
                    soa.OwnerId = soa.Account__r.DSA_Contact_User__c;
                    soa.Awaiting_TP_Approval__c = true;
                    Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
                    req1.setObjectId(soa.Id);
                    req1.setSubmitterId(soa.Area_Sales_Manager__r.Id); 
                    req1.setProcessDefinitionNameOrId('Appliances_DSA_Workflow_Trade_Partner');
                    req1.setSkipEntryCriteria(false);
                    reqList.add(req1);
                }
                else{
                    continue;
                }
                
                
                
                if(!String.isEmpty(toEmail)  || !String.isEmpty(ccEmail)){ 
                    mail.setToAddresses(new List<String>{toEmail});        
                    if(String.isNotBlank(ccEmail)){
                        mail.setCcAddresses(new List<String>{ccEmail});//List of CC email id's:
                    }
                    mail.setSubject(emailSubject);//Email subject
                    mail.setHTMLBody(emailBody);//Email Body
                    mail.setWhatId(soa.Id);
                    mail.setSaveAsActivity(true);
                    //Attachment
                    if(!attach.isEmpty()){
                        mail.setFileAttachments(attach);            
                    }
                    mail.setOrgWideEmailAddressId(orgEmailId);
                    emailList.add(mail);
                }
                soa.Status__c = 'Sent';
            }
            
        }
        return emailList;
    }
    
    //Email template for Mismatch Accounts
    private static EmailTemplate getMismatchEmailTemplate(){
        return [Select id, Subject, Body,HtmlValue From EmailTemplate  Where DeveloperName = 'SOA_Mismatch_Email']; 
    }
    
    //Email template for Trade partners
    private static EmailTemplate getDSAEmailTemplate(){
        return [Select id, Subject,Body,HtmlValue From EmailTemplate  Where DeveloperName= 'SOA_Trade_Partner_Email'];
    }
    
    //Get the Org default email address
    private static Id orgWideEmailAddress(){
        return [SELECT id,displayName FROM OrgWideEmailAddress WHERE Address='onecrm@godrej.com' limit 1]?.Id;
    }
    
    //replace the email placeholders
    private static String replaceTradePartnerEmailBody(String emailBody, Statement_of_Account__c soa){
        emailBody = emailBody.replace('{DSA_CONTACT_USER}', soa.Account__r.DSA_Contact_User__r.FirstName +' '+soa.Account__r.DSA_Contact_User__r.LastName)
            .replace('{ACCOUNT_NAME}', soa.Account__r.Name)
            .replace('{ACCOUNT_CODE}',soa.Account__r.Account_Code__c)
            .replace('{CALENDAR_MONTH}',soa.Calendar_Month__c)
            .replace('{STATEMENT_YEAR}',soa.Statement_Year__c)
            .replace('{DATE_DUE_BY}', ''+( (Date.today().adddays(3)).format() ) )
            .replace('{ASM_Name}',soa.Area_Sales_Manager__r.FirstName+' '+soa.Area_Sales_Manager__r.LastName)
            .replace('{ACCOUNT_NAME}',soa.Account__r.Name);
        return emailBody;
    }
    
    //replace the email placeholders
    private static String replaceMismatchedEmailBody(String emailBody, Statement_of_Account__c soa){
        String url = URL.getSalesforceBaseUrl().toExternalForm()+'/'+soa.Id;
        url = '<a href ="'+url+'">url</a>';
        emailBody = emailBody.replace('{BRANCH_ACCOUNTANT}', SOA.Branch_Accountant__r.FirstName+' '+SOA.Branch_Accountant__r.LastName)
            .replace('{ACCOUNT_CODE}',soa.Account__r.Account_Code__c)
            .replace('{ACCOUNT_NAME}',soa.Account__r.Name)
            .replace('{PERIOD_MONTH}',''+soa.Period_Month__c)
            .replace('{PERIOD_YEAR}',''+SOA.Period_Year__c )
            .replace('{URL}',url);
        return emailBody;
    }
    

}