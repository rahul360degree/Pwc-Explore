/*------------------------------------------------------------------------
Author:        Shreela Nair
Company:       Godrej Infotech
Description:   To send CSV File of all notes of related lead records to Logged-in user by clicking Send Notes in CSV action for jira no SPBSCI-18
               Called from Screen flow by name 'Send Notes in CSV'
Inputs:        List of Ids of Lead Records
Test Class:    SendCSVNotesInEmailTest

History
03-03-2023     Shreela Nair    Initial Release
----------------------------------------------------------------------------*/
public with sharing class SendCSVNotesInEmail {
    @InvocableMethod
    public static void sendNotes(List<Id> leadId) {
        
        String csvHeaders = '"'+'Title'+'","'+'Text Preview'+'","'+'CreatedDate'+'"\n';        //CSV File Header
        String[] emailToAddress = new String[]{UserInfo.getUserEmail()};       //To fetch email address of logged in User
            Set<Id> conDocId = new Set<Id>();            //To fetch ContentDocumentId of ContentDocumentLink
        Set<Id> cId = new Set<Id>();                 //To fetch Id of ContentDocument
        String csvRowVal='';                         //To set the rows of CSV File
        String csvFile = '';                         //To set the rows and headers of CSV File
        List<OrgWideEmailAddress> lstOrgWideEmailId;
        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();
        Map<Id,Id> contentDocumentIdVsLeadIdMap = new Map<Id,Id>(); //Map of ContentDocumentId and LeadId
                
        //To fetch title of lead records
        List<Lead> leadLst = [SELECT Id,Title 
                              FROM Lead 
                              WHERE Id IN: leadId AND Business_Unit__c=: GlobalConstants.PES_BUSINESS_UNIT WITH SECURITY_ENFORCED LIMIT 1]; 
        
        if(!leadLst.isEmpty()){
            //To set OneGodrej as Sender
            lstOrgWideEmailId = [SELECT id,DisplayName,Address 
                                 FROM OrgWideEmailAddress 
                                 WHERE Address='onecrm@godrej.com'];
          
            for(ContentDocumentLink  cdl : [SELECT Id,ContentDocumentId,LinkedEntityId 
                       FROM ContentDocumentLink 
                       WHERE LinkedEntityId IN:LeadId WITH SECURITY_ENFORCED]){
                contentDocumentIdVsLeadIdMap.put(cdl.ContentDocumentId,cdl.LinkedEntityId);
                conDocId.add(cdl.ContentDocumentId);
            }

             //To fetch files of only SNOTE type (Notes) of lead record 
            for(ContentDocument c :[SELECT Id,FileType 
                  FROM ContentDocument 
                  WHERE FileType='SNOTE' AND Id IN: conDocId WITH SECURITY_ENFORCED]){
                cId.add(c.Id);
            }
 
        }
        
            for(ContentVersion c :[SELECT ContentBodyId,ContentDocumentId,Id,TextPreview,Title,CreatedDate 
                  FROM ContentVersion 
                  WHERE ContentdocumentId IN: cId AND IsLatest=true WITH SECURITY_ENFORCED]){
                if(!contentDocumentIdVsLeadIdMap.isEmpty() && contentDocumentIdVsLeadIdMap.containsKey(c.ContentDocumentId) && contentDocumentIdVsLeadIdMap.get(c.ContentDocumentId)==leadLst[0].Id){
                        csvRowVal = csvRowVal+'"'+c.Title+'","'+c.TextPreview+'","'+c.CreatedDate+'"\n';
                }
            } 
            csvFile = csvHeaders + csvRowVal +'\n';
            
            //Send email
            Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
            Messaging.EmailFileAttachment attach1 = new Messaging.EmailFileAttachment();
            blob csvFileBody;
            if(Test.isRunningTest()) { 
                csvFileBody = blob.valueOf('Sending Notes of lead record in CSV File');
            } else {
                csvFileBody = Blob.valueOf(csvFile);
            } 
            attach1.setBody(csvFileBody);
            String fileName = 'CSV File of '+leadLst[0].Title+'.csv';
            attach1.setFileName(fileName);
            message.setFileAttachments(new Messaging.EmailFileAttachment[]{attach1});
            message.setOrgWideEmailAddressId(lstOrgWideEmailId[0].id); 
            message.setToAddresses(emailToAddress);
            String subject = leadLst[0].Title+' '+System.Today().format();
            message.setSubject(subject); 
            String emailBody = '<html><body>Dear GPE Team,<br><br>PFA of all notes of the '+leadLst[0].Title+'</body></html>';
            message.setHtmlBody( emailBody);
            emailsToSend.add(message);
            csvRowVal = ''; //Resetting the value for next lead record

            Messaging.SendEmailResult [] result =  Messaging.sendEmail(emailsToSend);
    }
    
    
}