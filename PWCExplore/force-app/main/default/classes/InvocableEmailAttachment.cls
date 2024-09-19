/*------------------------------------------------------------------------
Author :       Santosh Jahagirdar
Company:       GITL
Description:   class which sends Email Attachment when invoke from Flow    
Test Class:    InvocableEmailAttachmentTest
----------------------------------------------------------------------------*/
global class InvocableEmailAttachment {
    
    //class to get multiple inputs from flow
    global class flowInput {                  
        @InvocableVariable(required=true)
        global String eMail;        
        @InvocableVariable
        global String ccMail;        
        @InvocableVariable(required=true)
        global String eSubject;        
        @InvocableVariable
        global String ebody;         
        @InvocableVariable
        global id currentRecordId;        
        @InvocableVariable
        global boolean sendAttachment;  
        @InvocableVariable
        global boolean trackEmail;
        @InvocableVariable
        global boolean useOneCRMOrgWideEmailID;
    }
    //invocable method
    @InvocableMethod(label='Email with Attachments' description='Used to send email alert along with attachments on the record.') 
    global static void currentRecordID(flowInput[] currentInput){                           
        ID rId;        
        for(flowInput singleID :currentInput ){
            //fetching record id
            rId = singleID.currentRecordId;                                                             
            //Get the obbject of the record id
            sobject sO = rId.getSobjectType().newsobject(rId);                            
        }                
        Set<String> contentDocumentSet = new Set<String>();          
        //Get all content document link where linkedEntityid=: rID. 
        for(ContentDocumentLink doc : [SELECT ContentDocumentId,ContentDocument.title,Id,LinkedEntityId,ShareType FROM ContentDocumentLink WHERE LinkedEntityId =:rID ] )  {
            contentDocumentSet.add(doc.ContentDocumentId);
        }        
        //Get all related contentVersion file
        List<ContentVersion> contentVersionFile = new List<ContentVersion>([SELECT VersionData, title, FileType, FileExtension FROM ContentVersion WHERE ContentDocumentId IN :contentDocumentSet AND IsLatest = true]);                                     
        //New email message method
        Messaging.SingleEmailMessage mail= new Messaging.SingleEmailMessage();            
        //defining list of email attachments
        List<Messaging.EmailFileAttachment> attach= new list<Messaging.EmailFileAttachment>();                
        //For each content version file get the file name, extension, version and add into the attachment list called 'attach'
        for(ContentVersion file : contentVersionFile){
            Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
            efa.setFileName(file.title.Trim()+'.'+file.FileExtension.Trim());
            efa.setBody(file.VersionData);
            attach.add(efa);
        }                        
        //List of TO email id's 
        List<String> sendTo = new List<String>();                     
        for(String emailId : currentInput[0].eMail.split(',')){
            if(emailId !=Null){
                sendTo.add(emailId.trim());
            }                    
        }                                    
        mail.setToAddresses(sendTo);        
        
        //List of CC email id's:
        
        if(currentInput[0].ccMail!=Null  && currentInput[0].ccMail.trim() != ''){           
            List<String> ccSendTo = new List<String>();           
            for(String ccEmailId : currentInput[0].ccMail.split(',')){
                if(ccEmailId!=Null){
                    ccSendTo.add(ccEmailId.trim());
                }                        
            }
            mail.setCcAddresses(ccSendTo);                    
        }            
        //Email Body
        mail.setHTMLBody(currentInput[0].eBody);        
        //Email subject
        mail.setSubject(currentInput[0].eSubject);        

        if(currentInput[0].trackEmail != Null && currentInput[0].trackEmail && String.isNotBlank(rId)){
            mail.setWhatId(rId);
            mail.setSaveAsActivity(true);
            
        }
        //Attachment
        if(currentInput[0].sendAttachment ==True){
            mail.setFileAttachments(attach);            
        }
        //set owd Email
        if(currentInput[0].useOneCRMOrgWideEmailID !=null && currentInput[0].useOneCRMOrgWideEmailID ){
            List<OrgWideEmailAddress> lstOrgWideEmailId = [SELECT id,displayName FROM OrgWideEmailAddress WHERE Address='onecrm@godrej.com'];
            if(!lstOrgWideEmailId.isEmpty()){
                Id orgWideEmailAddressID = lstOrgWideEmailId[0].id;
                mail.setOrgWideEmailAddressId(orgWideEmailAddressID);
            }
        }
        //Send Email
        Messaging.sendEmail(new Messaging.SingleEmailMessage[]{mail});
    }
    
}