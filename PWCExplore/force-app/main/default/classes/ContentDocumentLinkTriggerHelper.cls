/**
 * @Description       : 
 * @Author            : Varun Rajpoot
 * @last modified on  : 02-02-2024
 * @last modified by  : Varun Rajpoot 
 * Modifications Log
 * Ver   Date         Author          Modification
 * 1.0   02-02-2024   Varun Rajpoot   Initial Version
**/
public class ContentDocumentLinkTriggerHelper{
    
    //Added by Shreela on 24th May 2023 for Jira No :SPEP 3,4,7 and 8
    // Org wide Email Address   
    public static OrgWideEmailAddress orgWideEmailAddress{
        get{
            return orgWideEmailAddress;
        }
        set{
            orgWideEmailAddress = value;
        }
    }  
    
    //Email address in To of Email
    public static List<String> toEmailAddress{
        get{
            return toEmailAddress;
        }
        set{
            toEmailAddress = value;
        }
    } 
    
    //Map of Content Document Id to Lead Id
    public static Map<Id,Id> conDocIdvsLeadId{
        get{
            return conDocIdvsLeadId;
        }
        set{
            conDocIdvsLeadId = value;
        }
    } 
    
    //Map of Content Document Id to Opportunity Id
    public static Map<Id,Id> conDocIdvsOppId{
        get{
            return conDocIdvsOppId;
        }
        set{
            conDocIdvsOppId = value;
        }
    } 
    
    //Get PES Lead Records
    public static List<Lead> getpesLeadRecords(Set<Id> parentId){
        
        List<Lead> pesLead = [SELECT Id,Business_Unit__c,Title,Lead_Number__c
                              FROM Lead
                              WHERE Id IN: parentId
                              AND RecordType.DeveloperName =: GlobalConstants.PES_Lead_RecordType];                       
        
        if(!pesLead.isEmpty()){
            return  pesLead;
        }
        else{
            return null;
        }
    }
    
    //Get PES Opportunity Records
    public static List<Opportunity> getpesOppRecords(Set<Id> parentId){
        
        List<Opportunity> pesOpp = [SELECT Id,Business_Unit__c,Name,Opportunity_No__c
                                    FROM Opportunity
                                    WHERE Id IN: parentId
                                    AND RecordType.DeveloperName =: GlobalConstants.PES_Opp_RecordType];                       
        
        if(!pesOpp.isEmpty()){
            return  pesOpp;
        }
        else{
            return null;
        }
    }
    
    //Get Content Version Records
    public static List<ContentVersion> getContentVersion(Set<Id> contentDocumentId){
        
        List<ContentVersion> cvList;
        cvList = [SELECT ContentDocumentId,VersionData,Title,FileExtension,PathOnClient,FileType 
                  FROM ContentVersion 
                  WHERE contentDocumentId IN : contentDocumentId AND IsLatest=true];
        
        if(cvList.size()>0){
            return  cvList;
        }
        else{
            return null;
        }
    }
    
    //Check whether ContentVersion is of  Note's type or not
    public static Integer checkNote(Set<Id> recordId,List<ContentVersion> cvList){
        Integer count = 0;
        
        for(ContentVersion cv : cvList){
            if(cv.FileType == GlobalConstants.FileType_Notes_Value &&
               ((ContentDocumentLinkTriggerHelper.conDocIdvsLeadId!=null &&  ContentDocumentLinkTriggerHelper.conDocIdvsLeadId.size()>0 && ContentDocumentLinkTriggerHelper.conDocIdvsLeadId.containsKey(cv.ContentDocumentId) && recordId.contains(ContentDocumentLinkTriggerHelper.conDocIdvsLeadId.get(cv.ContentDocumentId)))
                || (ContentDocumentLinkTriggerHelper.conDocIdvsOppId!=null && ContentDocumentLinkTriggerHelper.conDocIdvsOppId.size()>0 && ContentDocumentLinkTriggerHelper.conDocIdvsOppId.containsKey(cv.ContentDocumentId) && recordId.contains(ContentDocumentLinkTriggerHelper.conDocIdvsOppId.get(cv.ContentDocumentId)))))  {                  
                    count = count + 1;
                }
            
        }
        
        if(count>=1){
            return count;
        }
        else
            return null;
        
    }
    
    //Get File Attachments 
    public static List<Messaging.EmailFileAttachment> getFileAttachment(Set<Id> recordId,List<ContentVersion> cvList){
        List<Messaging.EmailFileAttachment> fileAttachments = new List<Messaging.EmailFileAttachment>();
        for(ContentVersion cv : cvList){
            if(cv.FileType != GlobalConstants.FileType_Notes_Value &&
               ((ContentDocumentLinkTriggerHelper.conDocIdvsLeadId!=null &&  ContentDocumentLinkTriggerHelper.conDocIdvsLeadId.size()>0 && ContentDocumentLinkTriggerHelper.conDocIdvsLeadId.containsKey(cv.ContentDocumentId) && recordId.contains(ContentDocumentLinkTriggerHelper.conDocIdvsLeadId.get(cv.ContentDocumentId)))
                || (ContentDocumentLinkTriggerHelper.conDocIdvsOppId!=null && ContentDocumentLinkTriggerHelper.conDocIdvsOppId.size()>0 && ContentDocumentLinkTriggerHelper.conDocIdvsOppId.containsKey(cv.ContentDocumentId) && recordId.contains(ContentDocumentLinkTriggerHelper.conDocIdvsOppId.get(cv.ContentDocumentId)))))  {
                    Messaging.Emailfileattachment efa = new Messaging.Emailfileattachment(); 
                    efa.setFileName(cv.Title+'.'+cv.FileExtension);
                    efa.setBody(cv.VersionData);
                    fileAttachments.add(efa);
                }
            
        }
        
        if(fileAttachments.size()>0){
            return fileAttachments;
        }
        else{
            return null;
        }
        
    }
    
  
  //Ended by Shreela on 24th May 2023 for Jira No :SPEP 3,4,7 and 8

    public void statementOfAccountVisibility(List<ContentDocumentLink> newItems){
        String keyPrefix = Statement_of_Account__c.SObjectType.getDescribe().getKeyPrefix();
        for(ContentDocumentLink l:newItems){
            //Only for Statement of Account
            if((''+l.LinkedEntityId).startsWith(keyPrefix)){
                l.Visibility='AllUsers'; 
            }
            
        }
    }
    
    /*------------------------------------------------------------------------
    Author:        Shreela Nair
    Company:       Godrej Infotech
    Description:   To send email notification when User uploads any file attachment or inserts notes in PES Lead or Opportunity Record
    Inputs:        Map of ContentDocumentLink with Ids
    Test Class:    ContentDocumentTriggerHandlerTest

    History
    16-03-2023     Shreela Nair    Initial Release
    24-05-2023     Shreela Nair    Updated 
    ----------------------------------------------------------------------------*/
    public void sendEmailonInsertionofAttachmentandNotes(Map<Id,ContentDocumentLink> newItems){
        
        //Get Object Id    
        Set<Id> leadId = new Set<Id>(); 
        Set<Id> oppId = new Set<Id>(); 
        
        //Get Content Document of Lead and Opportunity    
        Set<Id> contentDocumentLeadId = new Set<Id>(); 
        Set<Id> contentDocumentOppId = new Set<Id>(); 
        
        //Get Content Document Id vs Object Id Map    
        Map<Id,Id> conDocIdvsLeadIdMap = new Map<Id,Id>(); 
        Map<Id,Id> conDocIdvsOppIdMap = new Map<Id,Id>();  
        
        //Get Content Version of both objects
        List<ContentVersion> cvLeadList; 
        List<ContentVersion> cvOppList;
        
        //Fetch list of both objects
        List<Lead> leadList = new List<Lead>();
        List<Opportunity> oppList = new List<Opportunity>();
        
        //To attach file attachments of respective Lead/Opp records
        List<Messaging.Emailfileattachment> fileLeadAttachments = new List<Messaging.Emailfileattachment>();
        List<Messaging.Emailfileattachment> fileOppAttachments = new List<Messaging.Emailfileattachment>();
        
        //To check no of Note's type file
        Integer sNoteLeadCheck;
        Integer sNoteOppCheck;
        
        //To send email
        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();
        
        try{
            ContentDocumentLinkTriggerHelper.orgWideEmailAddress = [SELECT id,DisplayName,Address FROM OrgWideEmailAddress WHERE Address='onecrm@godrej.com'][0];
            ContentDocumentLinkTriggerHelper.toEmailAddress =  System.Label.PES_Common_Email_Address.split(',');
            String sObjName;
            
            for(ContentDocumentLink cd : newItems.values()){
                
                sObjName = cd.LinkedEntityId.getSObjectType().getDescribe().getName(); //To check object name
                
                if(sObjName == GlobalConstants.Lead_SObject){  //To check whether inserted CDL record belongs to Lead or not
                    leadId.add(cd.LinkedEntityId);
                    contentDocumentLeadId.add(cd.ContentDocumentId);
                    conDocIdvsLeadIdMap.put(cd.ContentDocumentId,cd.LinkedEntityId);
                    ContentDocumentLinkTriggerHelper.conDocIdvsLeadId = conDocIdvsLeadIdMap;
                }
                if(sObjName == GlobalConstants.Opp_SObject){   //To check whether inserted CDL record belongs to Opportunity or not
                    oppId.add(cd.LinkedEntityId);
                    contentDocumentOppId.add(cd.ContentDocumentId);
                    conDocIdvsOppIdMap.put(cd.ContentDocumentId,cd.LinkedEntityId);
                    ContentDocumentLinkTriggerHelper.conDocIdvsOppId = conDocIdvsOppIdMap;
                }
                
            }
            

            if(!leadId.isEmpty()){
                leadList = ContentDocumentLinkTriggerHelper.getpesLeadRecords(leadId); //Fetch PES Lead Records
            }
            
            if(!oppId.isEmpty()){
                oppList = ContentDocumentLinkTriggerHelper.getpesOppRecords(oppId); //Fetch PES Opportunity Records
                
            }
            
            if(!contentDocumentLeadId.isEmpty() && !leadList.isEmpty()){ //Added list condition by Shreela on 11th Jan 2024 for SLEIP-10
                cvLeadList = getContentVersion(contentDocumentLeadId);  //Fetch Content Version of lead
            }
            if(!contentDocumentOppId.isEmpty() && !oppList.isEmpty()){ //Added list condition by Shreela on 11th Jan 2024 for SLEIP-10
                cvOppList = getContentVersion(contentDocumentOppId); //Fetch Content Version of Opportunity
            }
            
            if(leadList.size()>0 && cvLeadList.size()>0){
                for(Lead ld : leadList){
                    String fullRecordURL = URL.getSalesforceBaseUrl().toExternalForm()+'/lightning/r/Lead/'+ld.Id+'/view';
                    Set<Id> recordId = new Set<Id>();
                    recordId.add(ld.Id); //Fetch lead record Id
                    fileLeadAttachments = getFileAttachment(recordId,cvLeadList); //Fetch file attachment for Lead record
                    sNoteLeadCheck = checkNote(recordId,cvLeadList); //Check no of notes inserted for lead record
                    
                    
                    if(fileLeadAttachments!=null && fileLeadAttachments.size()>0){ //To send email notification if file uploaded in Lead GPE Record
                        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                        message.setOrgWideEmailAddressId(ContentDocumentLinkTriggerHelper.orgWideEmailAddress.Id);  
                        message.setToAddresses(ContentDocumentLinkTriggerHelper.toEmailAddress);
                        message.setSubject('New file added  for lead : '+ld.Title);
                        message.setFileAttachments(fileLeadAttachments);
                        String body = '<html><body>Dear GPE  Team,<br><br>New file added for below mentioned Lead<br><br>Lead Title - '+ld.Title+'<br>Lead Number - '+ld.Lead_Number__c+'<br>Lead URL - <a href="'+fullRecordURL+'">Click here.</a><br><br>Thanks!<br><br>Note: This is a system generated email, do not reply to this.</body></html>';
                        message.setHtmlBody(body); //Set HTML Body
                        emailsToSend.add(message);
                        
                    }
                    if(sNoteLeadCheck>=1){ //Send email notification if note inserted for GPE Lead Record
                        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                        message.setOrgWideEmailAddressId(ContentDocumentLinkTriggerHelper.orgWideEmailAddress.Id);  
                        message.setToAddresses(ContentDocumentLinkTriggerHelper.toEmailAddress);
                        message.setSubject('Note has been added for Lead : '+ld.Title);
                        String body = '<html><body>Dear GPE Team,<br><br>This is to notify that a note has been added for '+ld.Title+' Lead<br><br>Please check the below record link of Lead :<br>'+fullRecordURL+'<br><br>Thanks!<br><br>Note: This is a system generated email, do not reply to this.</body></html>';
                        message.setHtmlBody(body);   
                        emailsToSend.add(message);
                    } 
                    
                }
                
            }
            
            if(oppList.size()>0 && cvOppList.size()>0){
                for(Opportunity opp : oppList){
                    String fullRecordURL = URL.getSalesforceBaseUrl().toExternalForm()+'/lightning/r/Opportunity/'+opp.Id+'/view';
                    Set<Id> recordId = new Set<Id>();
                    recordId.add(opp.Id); //Fetch opportunity record Id
                    fileOppAttachments = getFileAttachment(recordId,cvOppList); //Fetch file attachment for Opportunity record
                    sNoteOppCheck = checkNote(recordId,cvOppList); //Check no of notes inserted for opportunity record
                    
                    if(fileOppAttachments!=null && fileOppAttachments.size()>0){ //To send email notification if file uploaded in Opportunity GPE Record
                        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                        message.setOrgWideEmailAddressId(ContentDocumentLinkTriggerHelper.orgWideEmailAddress.Id);  
                        message.setToAddresses(ContentDocumentLinkTriggerHelper.toEmailAddress);
                        message.setSubject('New file added  for Opportunity : '+opp.Opportunity_No__c+' '+opp.Name); 
                        message.setFileAttachments(fileOppAttachments);
                        String body = '<html><body>Dear GPE Team,<br><br>New file added  for below mentioned Opportunity<br><br>Opportunity Number - '+opp.Opportunity_No__c+'<br>Opportunity Name - '+opp.Name+'<br>Opportunity URL - <a href="'+fullRecordURL+'">Click here.</a><br><br>Thanks!<br><br>Note: This is a system generated email, do not reply to this. </body></html>'; 
                        message.setHtmlBody(body); 
                        emailsToSend.add(message);
                        
                    }
                    if(sNoteOppCheck>=1){ //Send email notification if note inserted for GPE Opportunity Record
                        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                        message.setOrgWideEmailAddressId(ContentDocumentLinkTriggerHelper.orgWideEmailAddress.Id);  
                        message.setToAddresses(ContentDocumentLinkTriggerHelper.toEmailAddress);
                        message.setSubject('Note has been added for Opportunity : '+opp.Opportunity_No__c+' '+opp.Name);
                        String body = '<html><body>Dear GPE Team,<br><br>This is to notify that a note has been added for '+opp.Opportunity_No__c+' Opportunity<br><br>Please check the below record link of Opportunity :<br>'+fullRecordURL+'<br><br>Thanks!<br><br>Note: This is a system generated email, do not reply to this.</body></html>';
                        message.setHtmlBody(body);  
                        emailsToSend.add(message);
                    }
                    
                }

                
            }

            if(emailsToSend.size()>0){
                Messaging.SendEmailResult [] result =  Messaging.sendEmail(emailsToSend);
            }
            
        }
        
        catch(Exception ex){
            System.debug(ex.getStackTraceString());
        }
        
    }
     /*------------------------------------------------------------------------
Author:        Varun Rajpoot & Shreela Nair
Company:       Godrej Infotech
Description:   SAEPB-103 - Branch Accountant should be able to attach revised statement files to Statement of account records
Inputs:        List of ContentDocumentLink
Test Class:    

History
03-08-2023     Shreela Nair    Initial Release
04-08-2023     Varun Rajpoot   Updated code

----------------------------------------------------------------------------*/
public void setShareType(List<ContentDocumentLink> newItems){
    List<ContentDocumentLink> updateC = new List<ContentDocumentLink>();
    try{
        //for(ContentDocumentLink cdl : [Select Id,LinkedEntityId,ShareType from ContentDocumentLink where ID IN: newItems]){               
        for(ContentDocumentLink cdl : newItems){               
            Id recordId = cdl.LinkedEntityId;
            String sObjName = recordId.getSObjectType().getDescribe().getName();
            if(sObjName == GlobalConstants.SOA_Object)
            {
                updateC.add(new ContentDocumentLink(Id = cdl.Id,ShareType = 'C'));    
            }
            
            
        }
        update updateC;
    }catch(Exception ex){
        System.debug(ex);
    }
}
    
/*------------------------------------------------------------------------
    Author:        Shreela Nair
    Company:       Godrej Infotech
    Description:   SMEPB-113 - MHE-SMF-149-US-2- Visibility of Billed sales and outstanding object to partner user
    Inputs:        List of ContentDocumentLink
    Test Class:    

    History
    14-09-2023     Shreela Nair    Initial Release

----------------------------------------------------------------------------*/
    public void setVisibilityOfBSOFilesForExternalUsers(List<ContentDocumentLink> newItems){
        
        //Fetch BSO File Id and  Record Id
        Set<Id> bsoFilesId = new Set<Id>();
        Set<Id> bsoId = new Set<Id>();
        
        //To set ShareType of Content Document and fetch BSO records of MHE Division
        List<ContentDocumentLink> updateVisibilityandShareTypeForMHEBSO = new List<ContentDocumentLink>();
        Map<Id,Billed_Sales_Outstandings__c> bsoMap = new Map<Id,Billed_Sales_Outstandings__c>();
        
        for(ContentDocumentLink cd : newItems){            
            if(cd.LinkedEntityId.getSObjectType().getDescribe().getName()== GlobalConstants.BSO_Object){
                bsoFilesId.add(cd.Id);
                bsoId.add(cd.LinkedEntityId);
            }
                
        }
        
        
        if(!bsoId.isEmpty()){
            bsoMap= new Map<Id,Billed_Sales_Outstandings__c>([SELECT Id, Business_Unit__c 
                                                              FROM Billed_Sales_Outstandings__c
                                                              WHERE Id IN: bsoId AND Business_Unit__c =: GlobalConstants.BUSINESS_UNIT_MHE_DIVISION]);
            
        }
        try{
            if(bsoMap!=null && bsoMap.size()>0){
                for(ContentDocumentLink cdl : [Select Id,LinkedEntityId,ShareType 
                                               FROM ContentDocumentLink 
                                               WHERE Id IN:bsoFilesId]){           
                                                   
                                                   if(bsoMap.containsKey(cdl.LinkedEntityId))
                                                   {
                                                       updateVisibilityandShareTypeForMHEBSO.add(new ContentDocumentLink(Id = cdl.Id,ShareType = 'V',Visibility='AllUsers'));    
                                                   }
                                               }
                update updateVisibilityandShareTypeForMHEBSO;
            }
        }
        catch(Exception ex){
            System.debug('ex : '+ex);
        }
    } 
        
}