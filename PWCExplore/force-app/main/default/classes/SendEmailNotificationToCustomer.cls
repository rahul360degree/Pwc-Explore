/*------------------------------------------------------------------------
Author:        Shreela Nair
Company:       GITL
Description:   Method to call Invocable method to send Email Notification along with Job Card File when Status is changed to Resolved
Inputs:        List<Id> recordId
Date :         18-01-2024
----------------------------------------------------------------------------*/ 
public class SendEmailNotificationToCustomer {
    @InvocableMethod(label='Send Email to Customers' description='Sends an email to Customers')
    public static void sendEmailNotifcationToCustomer(List<Id> recordId) {
        try{   
            Set<Id> cId = new Set<Id>();    //Set of Id from Content Document Object            
            Set<Id> conDocId = new Set<Id>();  //Set of Content Document Id from ContentDocumentLink Object
            Map<Id,Id> conIdCaseIdMap = new Map<Id,Id>(); //Map of Content Document Id and Case Id
            
            //Fetch necesaary details of Case Records
            List<Case> csList = [SELECT Id,Email__c,ContactEmail,SuppliedEmail,Account.Name,CaseNumber,Owner.FirstName,Owner.LastName
                                 FROM Case 
                                 WHERE Id IN: recordId];
            
            //Fetch Email Template
            EmailTemplate et = Utility.getEmailTemplate('MHE_Resolution_to_Customer');
            
            //To fetch related files of Case records whose status changed to 'Resolved'
            for(ContentDocumentLink  cdl : [SELECT Id,ContentDocumentId,LinkedEntityId 
                                            FROM ContentDocumentLink 
                                            WHERE LinkedEntityId IN: recordId]){
                                                conDocId.add(cdl.ContentDocumentId);
                                                conIdCaseIdMap.put(cdl.ContentDocumentId,cdl.LinkedEntityId);
                                            }
            
            //To fetch only Job Card files of Case records with the help of ContentDocumentId fetched from ContentDocumentLink
            for(ContentDocument c :[SELECT Id,FileType,Title 
                                    FROM ContentDocument 
                                    WHERE Id IN:conDocId AND (Title like 'Job Card%' OR Title like 'PM Checklist - Diesel%'
                                                              OR Title like 'PM Checklist - Electric%' OR Title like 'Commissioning Checklist%')]){
                                        cId.add(c.Id);
                                    }
            
            //To attach file for Email 
            List<ContentVersion> cvList = [SELECT ContentDocumentId,VersionData,Title,FileExtension,PathOnClient,FileType 
                                           FROM ContentVersion 
                                           WHERE contentDocumentId IN : cId AND IsLatest=true];
            
            //Setting from for Email
            OrgWideEmailAddress owea =  Utility.getOrgWideEmailAddress(GlobalConstants.One_CRM);
            
            //To send emails
            List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();        
            
            for(Case cse :csList){
                List<Messaging.EmailFileAttachment> fileAttachments = new List<Messaging.EmailFileAttachment>(); //To attach file
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                List<String> emailIdList = new List<String>(); //Fetching To for Email
                
                String emailBody = et.Body; //Fetching body of Email Template
                String emailSubject = et.Subject; //Fetching Subject of Email Template
                
                //Substituting Case Number of Email Template with it's value
                emailBody = emailBody.replace('{!Case.CaseNumber}',cse.CaseNumber);
                emailSubject = emailSubject.replace('{!Case.CaseNumber}',cse.CaseNumber);
                
                //Substituting Case's Account Name of Email Template with it's value
                if(cse.Account.Name<>null){
                    emailBody = emailBody.replace('{!Case.Account}',cse.Account.Name);
                }
                else{
                    emailBody = emailBody.replace('{!Case.Account}','');
                }
                
                //Substituting Case's Owner Name of Email Template with it's value
                if(cse.Owner.FirstName<>null){
                    emailBody = emailBody.replace('{!User.FirstName}',cse.Owner.FirstName);
                }
                else{
                    emailBody = emailBody.replace('{!User.FirstName}','');
                } 
                
                emailBody = emailBody.replace('{!User.LastName}',cse.Owner.LastName);

                
                //Appending Case's Alternate Email for sending email 
                if (cse.Email__c != null) {
                    emailIdList.add(cse.Email__c);
                }
                
                //Appending Case's Contact Email for sending email
                if (cse.ContactEmail != null) {
                    emailIdList.add(cse.ContactEmail);
                }
                
                //Appending Case's Email Address for sending email
                if (cse.SuppliedEmail != null) {
                    emailIdList.add(cse.SuppliedEmail);
                }
                
                email.setToAddresses(emailIdList);
                email.setOrgWideEmailAddressId(owea.id);
                email.setSaveAsActivity(false);
                email.setWhatId(cse.Id);
                email.setTemplateId(et.Id);
                email.setSubject(emailSubject);
                email.setPlainTextBody(emailBody);
                
                //Attaching file for email notification only if file exist
                for(ContentVersion cv : cvList){
                    if(conIdCaseIdMap.get(cv.ContentDocumentId) == cse.Id ){
                        Messaging.Emailfileattachment efa = new Messaging.Emailfileattachment(); 
                        efa.setFileName(cv.Title+'.'+cv.FileExtension);
                        efa.setBody(cv.VersionData);
                        fileAttachments.add(efa);
                    }
                }
               
                //Setting file attachment for Email Notification
                if(!fileAttachments.isEmpty()){
                    email.setFileAttachments(fileAttachments);
                }
                emailList.add(email);
                
                
            }
            if(!emailList.isEmpty()) { 
                Messaging.sendEmail(emailList);                        
            }
        }
        catch (Exception ex) {
            Logger.logError('SendEmailNotificationToCustomers', 'sendEmailNotificationToCustomers', '', ex);
        }        
    }
    
    
}