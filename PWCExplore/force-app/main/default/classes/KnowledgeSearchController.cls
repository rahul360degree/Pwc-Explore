public with sharing class KnowledgeSearchController {
    public knowledgeSearchController() {
    }
    
    @AuraEnabled(cacheable=true)
    public static List<String> KnowledgeRecordTypes(){
        List<String> knowledgeRecordTypesValues = new List<String>();
        
        // Query all Knowledge__kav active record types
        for (RecordType rt : [SELECT Name FROM RecordType WHERE IsActive = true AND SobjectType = 'Knowledge__kav']) {
            knowledgeRecordTypesValues.add(rt.Name);
        }
        System.debug('knowledgeRecordTypesValues:' + knowledgeRecordTypesValues);
        return knowledgeRecordTypesValues;
    }    
    
    
    @AuraEnabled(cacheable=true)
    public static List<Knowledge__kav> KnowledgeArticles(String input, String cat) {
        List<Knowledge__kav> knowledgeArticlesList = new List<Knowledge__kav>();
        
        // Searching in Knowledge Subject
        if (input != '' && input != null) {
            String knowledgeQuery = '';
            if (cat != null && cat != '' && cat != 'All') {
                knowledgeQuery = 'SELECT Id, Title, Summary FROM Knowledge__kav WHERE Title LIKE \'%' + input + '%\' AND RecordType.Name = ' + '\'' + cat + '\' LIMIT 10';
            }
            else {
                knowledgeQuery = 'SELECT Id, Title, Summary FROM Knowledge__kav WHERE Title LIKE \'%' + input + '%\' LIMIT 10';
            }
            knowledgeArticlesList = Database.query(knowledgeQuery);
        }
        return knowledgeArticlesList;
    }
    
    @AuraEnabled
    public static void sendKnowledgeArticle(List<String> knowledgeRecordIdList,String recordId){
        List<String> fileUrlList = new List<String>();
        String emailAddress;
        System.debug('HOO-->'+ knowledgeRecordIdList);
        List<ContentDistribution> listofCd = new List<ContentDistribution>();
        List<ContentDocumentLink> documentLinksToUpdate = new List<ContentDocumentLink>();
        Set<Id> setofCDL = new Set<Id>();
        if(!knowledgeRecordIdList.isEmpty()){
            List<WorkOrderLineItem> woliList = [SELECT WorkOrder.Account.PersonEmail FROM WorkOrderLineItem WHERE Id=:recordId];
            emailAddress = woliList[0].WorkOrder.Account.PersonEmail;
            System.debug('HOO-->');
            
            List<ContentDocumentLink> documentLinks = [SELECT ContentDocument.Title,ContentDocument.LatestPublishedVersionId,contentdocumentId
                                                       FROM ContentDocumentLink
                                                       WHERE LinkedEntityId IN :knowledgeRecordIdList];
            System.debug('HOO-->');
            
            for(ContentDocumentLink cdl : documentLinks){
                cdl.Visibility = 'AllUsers';
                System.debug('HOO-->');
                
                documentLinksToUpdate.add(cdl);
                setofCDL.add(cdl.contentdocument.id);
            }
            System.debug('HOO-->');
            
            if (!documentLinksToUpdate.isEmpty()) {
                //update documentLinksToUpdate;
            }
            List<ContentVersion> cv = [select id,ContentDocument.Title from contentversion where contentdocumentid = :setofCDL];
            for(ContentVersion link : cv){
                ContentDistribution cdRecord = new ContentDistribution();
                cdRecord.Name = link.ContentDocument.Title;
                cdRecord.ContentVersionId = link.Id;
                cdRecord.PreferencesAllowViewInBrowser = true;
                listofCd.add(cdRecord);
            }
            System.debug('HOO-->');
            
            insert listofCd;
            System.debug('ListofCD_' +listofCd);
            
            for(ContentDistribution cdData: listofCd){
                fileUrlList.add(cdData.Id);
            }
            List<ContentDistribution> contentDist = [SELECT DistributionPublicUrl FROM ContentDistribution WHERE ID =:fileUrlList];
            System.debug('CDDD->' +contentDist);
            List<String> CdLink = new List<String>();
            for(ContentDistribution cd :contentDist){
                CdLink.add(cd.DistributionPublicUrl);
            }
            sendEmailtotheCustomer(CdLink,emailAddress);
            
        }
    }
    
    public static void sendEmailtotheCustomer( List<String> fileUrlList,String emailAddress){
        OrgWideEmailAddress orgWideEmailObj = [SELECT Id, Address FROM OrgWideEmailAddress WHERE Address = 'onecrm@godrej.com'];
        // String imageUrl = '{!URLFOR($Resource.Godrej_Icon, 'Godrej_Icon')}';
        String emailBody = '<html><body>';
        emailBody += '<p>Hello Sir/Madam,</p>';
        emailBody += '<p>Please refer to the attached Knowledge Article.</p>';
        //emailBody += '<img src="' + imageUrl + '" alt="icon" style="width: 100px; height: auto;">'; // Adjust width and height as needed
        for (String fileUrl : fileUrlList) {
            emailBody += '<li><a href="' + fileUrl + '">' + fileUrl + '</a></li>';
        }
        emailBody += '</ul></body></html>';
        emailBody += '<p>Thanks and Regards,</p>';
        
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new String[]{emailAddress});
        email.setSubject('Knowledge Article');
        email.setHtmlBody(emailBody); // Set the HTML body
        email.setOrgWideEmailAddressId(orgWideEmailObj.Id);
        
        Messaging.sendEmail(new Messaging.SingleEmailMessage[]{email});   
        
    }
}