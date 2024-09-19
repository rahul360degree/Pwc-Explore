public with sharing class ContactFieldPopulator {
    public void checkMandatoryDocuments(Map<Id, Contact> conRecords){
        String metaDataLabel = '';
        Set<Id> recordIdForNOC = new Set<Id>();
        Set<Id> conDocIdSetForNOC = new Set<Id>();
        Set<Id> conDocIdSet = new Set<Id>();
        Set<Id> conRecordId = new Set<Id>();
        Map<Id,String>conRecIdvsBu = new Map<Id,String>();
        Map<String,List<String>> bUnitvsReqdoc = new Map<String,List<String>>();
        Map<String,List<String>> conRecIdvsReqdoc = new Map<String,List<String>>();
        List<ProcessInstance> approvalProcesses = new List<ProcessInstance>();
        Map<ID, String> mandatoryDocumentsNameNotUploaded = new Map<ID, String>();
        for(Contact c : conRecords.values()){
            if(c.Status__c == 'Submitted for approval' || c.Status__c == 'Submitted for Deactivation'){
                conRecordId.add(c.Id);
                conRecIdvsBu.put(c.Id,c.Business_Unit__c);
            }
            else if(c.Status__c == 'NOC Cleared'){
                recordIdForNOC.add(c.Id);
                
            }
        }
        for(ProcessInstance pi : [SELECT Id,Status,TargetObjectId, ProcessDefinition.DeveloperName
                                                FROM ProcessInstance
                                                WHERE TargetObjectId = :conRecordId
                                                AND Status = 'Started'
                                                ]) {
               String bu = conRecIdvsBu.get(pi.TargetObjectId);
            if(pi.ProcessDefinition.DeveloperName == 'Onboarding_Approval_Process_Technician') {
                metaDataLabel =  '('+bu+')-'+ '%tech%Onboarding%';
                List<UploadFilesCheckList__mdt> metadataquery = [SELECT RequiredDocuments__c,Related_Object__c,DocumentName__c,Business_Unit__c FROM UploadFilesCheckList__mdt WHERE Label LIKE :metaDataLabel LIMIT 1];
                if(metadataquery.size()>0 ){
                    UploadFilesCheckList__mdt metadataRecord = metadataquery[0];
                    String requiredDocuments = metadataRecord.RequiredDocuments__c;
           		 List<String> requiredDocumentsList = requiredDocuments.split(',');
                conRecIdvsReqdoc.put(pi.TargetObjectId,requiredDocumentsList);
                
                }
                
                
               // metaDataLabel = 'TECH onboarding Documents_Appliances';
                approvalProcesses.add(pi);
            } else if(pi.ProcessDefinition.DeveloperName == 'Technician_Termination_Approval'){
               // metaDataLabel = 'TECH Termination Documents_Appliances';
                 metaDataLabel =  '('+bu+')-'+ '%tech%termi%';
                List<UploadFilesCheckList__mdt> metadataquery = [SELECT RequiredDocuments__c,Related_Object__c,DocumentName__c,Business_Unit__c FROM UploadFilesCheckList__mdt WHERE Label LIKE :metaDataLabel LIMIT 1];
                if(metadataquery.size()>0 ){
                    UploadFilesCheckList__mdt metadataRecord = metadataquery[0];
                    String requiredDocuments = metadataRecord.RequiredDocuments__c;
           		 List<String> requiredDocumentsList = requiredDocuments.split(',');
                conRecIdvsReqdoc.put(pi.TargetObjectId,requiredDocumentsList);
                
                }
                approvalProcesses.add(pi);
            }
        }
        
        //------FOR NOC
        /*
        if(!recordIdForNOC.isEmpty()){
            String requiredDocuments='NOC';
            List<String> requiredDocumentsList=requiredDocuments.split(',');
            //requiredDocumentsList.add('NOC');
            Map<Id, Id> conDocMap = new Map<Id, Id>();
            for(ContentDocumentLink conDocLink : [SELECT Id, ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId = :recordIdForNOC]) {
                conDocIdSetForNOC.add(conDocLink.ContentDocumentId);
                conDocMap.put(conDocLink.ContentDocumentId, conDocLink.LinkedEntityId);
            }
           
            Map<Id, List<String>> conFileMap = new Map<Id, List<String>>();     
            for(ContentVersion conVersions : [SELECT Id, Title, ContentDocumentId, FileType, Document_Name__c FROM ContentVersion WHERE ContentDocumentId IN :conDocIdSetForNOC]){
                String documentName = conVersions.Document_Name__c.trim().tolowerCase();
              
                List<String> fileName = conFileMap.get(conDocMap.get(conVersions.ContentDocumentId));
                if(fileName == null) {
                    fileName = new List<String>{documentName};
                }
                fileName.add(documentName);
                conFileMap.put(conDocMap.get(conVersions.ContentDocumentId), fileName);
            }
            Map<Contact, Boolean> conToAddError = new Map<Contact, Boolean>();
            
            for(Id i : recordIdForNOC){
                Boolean isContainsAllDocuments = true;
                if(conFileMap.containsKey(i)) {
                    List<String> documentsUploaded = conFileMap.get(i);
                    for(String s : requiredDocumentsList){
                        if(!documentsUploaded.contains(s.trim().toLowerCase())){
                            String docName = mandatoryDocumentsNameNotUploaded.get(i);
                            if(docName == null){
                                docName = s;
                            } else {
                                docName += ', ' + s;
                            }
                            mandatoryDocumentsNameNotUploaded.put(i, docName);
                            isContainsAllDocuments = false;
                        }
                    }
                } else {
                    isContainsAllDocuments = false;
                }
                if(!isContainsAllDocuments){
                    conToAddError.put(conRecords.get(i), isContainsAllDocuments);
                    
                }  
            }
            
             if(!conToAddError.isEmpty()){
                 
                for(Contact c : conToAddError.keySet()){
                    Boolean isContainsAllDocuments = conToAddError.get(c);
                    String errorMessage = '';
                    if(mandatoryDocumentsNameNotUploaded.get(c.Id) != null && !isContainsAllDocuments){
                        errorMessage = 'Please upload required documents. These include ' + mandatoryDocumentsNameNotUploaded.get(c.Id) + '.';
                    }
                    else {
                        errorMessage = 'Please upload all the required documents.';
                    }
                   
                    c.addError(errorMessage);
                }
            }
            
        }
*/
//-----NOC ENDS
        if(!approvalProcesses.isEmpty()){   
            
            Map<Id, Id> conDocMap = new Map<Id, Id>();
            for(ContentDocumentLink conDocLink : [SELECT Id, ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId = :conRecordId]) {
                conDocIdSet.add(conDocLink.ContentDocumentId);
                conDocMap.put(conDocLink.ContentDocumentId, conDocLink.LinkedEntityId);
              
            }
            // List<String> documentsUploaded = new List<String>();   
            Map<Id, List<String>> conFileMap = new Map<Id, List<String>>();  
            for(ContentVersion conVersions : [SELECT Id, Title, ContentDocumentId, FileType, Document_Name__c FROM ContentVersion WHERE ContentDocumentId IN :conDocIdSet]){
                String documentName = conVersions.Document_Name__c.trim().tolowerCase();
                // documentsUploaded.add(documentName);
                List<String> fileName = conFileMap.get(conDocMap.get(conVersions.ContentDocumentId));
                if(fileName == null) {
                    fileName = new List<String>{documentName};
                }
                fileName.add(documentName);
                conFileMap.put(conDocMap.get(conVersions.ContentDocumentId), fileName);
            }
            Map<Contact, Boolean> conToAddError = new Map<Contact, Boolean>();

            for(Id i : conRecordId){
                Boolean isContainsAllDocuments = true;
                
                if(conFileMap.containsKey(i)) {
                    List<String> documentsUploaded = conFileMap.get(i);
                        
                    
                    List<String> requiredDocList= conRecIdvsReqdoc.get(i);
                    for(String s : requiredDocList){
                        if(!documentsUploaded.contains(s.trim().toLowerCase())){
                            String docName = mandatoryDocumentsNameNotUploaded.get(i);
                            if(docName == null){
                                docName = s;
                            } else {
                                docName += ', ' + s;
                            }
                            mandatoryDocumentsNameNotUploaded.put(i, docName);
                            isContainsAllDocuments = false;
                        }
                    }
                } else {
                    isContainsAllDocuments = false;
                }
                if(!isContainsAllDocuments){
                    conToAddError.put(conRecords.get(i), isContainsAllDocuments);
                }  
            }
            if(!conToAddError.isEmpty()){
                for(Contact c : conToAddError.keySet()){
                    Boolean isContainsAllDocuments = conToAddError.get(c);
                    String errorMessage = '';
                    if(mandatoryDocumentsNameNotUploaded.get(c.Id) != null && !isContainsAllDocuments){
                        errorMessage = 'Please upload required documents. These include ' + mandatoryDocumentsNameNotUploaded.get(c.Id) + '.';
                    } else {
                        errorMessage = 'Please upload all the required documents.';
                    }
                    c.addError(errorMessage);
                }
            }
        }    
    }
    
    
}