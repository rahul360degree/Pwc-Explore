/**
 * @File Name          : EmailQuotePDFCtrl.cls
 * @Description        : This class is used to Create quote PDF.
 * @Author             : Varun Rajpoot
 * @Group              : 
 * @Last Modified By   : Varun Rajpoot
 * @Last Modified On   : 02-02-2024
 * @Modification Log   : @Varun: Updated the URL --c.vf.force for Enhanced Domain
 *==============================================================================
 * Ver         Date                     Author                Modification
 *==============================================================================
 * 1.0    25/08/2019 11:17 AM          Anuj Kumar            Initial Version
 * 1.1    27/09/2019 11:17 AM          Prabhat Sharma        Added Public URL generation logic for MC
 * 1.2    22/06/2020 09:00 PM          Joshna Palla          Updates for G&B
 * 1.3    04/07/2020 04:00 PM          Joshna Palla          Added template filters
**/

public with sharing class EmailQuotePDFCtrl {    
    /*
        @Author: Varun Rajpoot
        @Created Date :           27/08/2019
        @Discription:             To generate quote template and insert template
        @Date Of Modification :   27/08/2019
    */
    @AuraEnabled
    public static void generateQuotePDF(String recordId, String templateId){
        Boolean isPortalUser;
        
        List<User> userData = [Select id, Name , Title, IsPortalEnabled from User where Id =:UserInfo.getUserId() Limit 1];
        if(userData != null && userData.size() > 0){
            isPortalUser = userData[0].IsPortalEnabled;
        }
        insertQuoteTemplate(recordId, templateId);
    }

    /*
        @Author: Varun Rajpoot
        @Created Date :           25/08/2019
        @Discription:             Generate quote PDF Method.
        @Date Of Modification :   25/08/2019
    */
    
    public static void insertQuoteTemplate(String recordId, String templateId) {
        String baseURL = baseURL();
        String additionalParams = '';
        for (Quote_Template_Mapping__mdt each : [SELECT Id, Parameter_Values__c FROM Quote_Template_Mapping__mdt WHERE Template_ID__c = :templateId]) {
            if (String.isNotBlank(each.Parameter_Values__c)) {
                additionalParams = each.Parameter_Values__c;
            }
        }
        if (baseUrl.contains('--c.vf.force')) {
            baseUrl = baseUrl.replace('--c.vf.force', '.my.salesforce');
        }else if (baseUrl.contains('--c.sandbox.vf.force')) {
            baseUrl = baseUrl.replace('--c.sandbox.vf.force', '.sandbox.my.salesforce');
        }
        
        
        PageReference pr = new PageReference(baseURL + '/quote/quoteTemplateDataViewer.apexp?id=' + recordId + '&summlid=' + templateId + additionalParams);
        QuoteDocument qd = new QuoteDocument();
        try{
            Blob b;
            
            if (!Test.isRunningTest()) {
                b = pr.getContentAsPDF();
            } else {
                b = Blob.valueOf('Test Data');
            }
            
            qd.Document = b;
            qd.QuoteId = recordId;
            System.debug(b);
            insert qd;
            System.debug(qd);
        } catch(Exception ex) {
            System.debug(ex.getStackTraceString());
        }
        createFile(recordId, qd.Id);
    }

    /*
        @Author: Varun Rajpoot
        @Created Date :           30/09/2019
        @Discription:             Generate public link for file.
        @Date Of Modification :   30/09/2019
    */
    @AuraEnabled
    public static void createFile(String recordId, Id quoteDocumentId){
        List<ContentDocumentLink> cdLink = new list<ContentDocumentLink>([SELECT ContentDocumentId,LinkedEntityId,LinkedEntity.name FROM ContentDocumentLink
                                                                         WHERE LinkedEntityId=:recordId ORDER BY SystemModstamp DESC]);
        if(!cdLink.isEmpty()){
            ContentDocument cd = [SELECT Id, Title, Description FROM ContentDocument where Id =: cdLink[0].ContentDocumentId];
            for (QuoteDocument each : [SELECT Id, Name FROM QuoteDocument WHERE Id = :quoteDocumentId]) {
                cd.title =  each.Name;
            }
            update cd;
        }
    }

    @AuraEnabled
    public static List<ValueWrapper> getQuoteTemplateIds(String recordId) {
        String orderType;
        String recordType = '%';
        Set<String> approvedStatuses = new Set<String>{GlobalConstants.APPROVAL_NOT_REQUIRED_STATUS, GlobalConstants.APPROVED_STATUS};
        
        if (String.isNotBlank(recordId)) {
            Quote quoteRecord = [SELECT Id, RecordType.DeveloperName, Approval_Status__c, Transaction_Type__c FROM Quote WHERE Id = :recordId];
            recordType += quoteRecord.RecordType.DeveloperName + '%';
            orderType = quoteRecord.Transaction_Type__c;
            if (!approvedStatuses.contains(quoteRecord.Approval_Status__c)) {
                return null;
            }
        }
        
        List<ValueWrapper> returnList = new List<ValueWrapper>();
        for (Quote_Template_Mapping__mdt each : [SELECT Id, Template_ID__c, Template_Label__c, Order_Type__c
                FROM Quote_Template_Mapping__mdt
                WHERE Record_Type__c LIKE :recordType
                ORDER BY Template_Label__c]) {
            if (String.isBlank(each.Order_Type__c) || orderType == each.Order_Type__c) {
                returnList.add(new ValueWrapper(each.Template_Label__c, each.Template_ID__c));
            }            
        }
        return returnList;
    }

    public Static String baseURL(){
        String baseURL = '';
        Boolean isPortalUser;
        
        List<User> currentUserData = new List<User>([Select id, Name , Title, IsPortalEnabled from User where Id =:UserInfo.getUserId() Limit 1]);
        if(currentUserData != null && currentUserData.size() > 0){
            isPortalUser = currentUserData[0].IsPortalEnabled;
        }
        
        if(isPortalUser){
            String currentCommunityId = Network.getNetworkId();
            if(currentCommunityId != null) {
                ConnectApi.Community comm = ConnectApi.Communities.getCommunity(currentCommunityId);
                String communityURL  = comm.siteUrl;
                if(communityURL.endsWith('login')){
                    communityURL = communityURL.replace('/login', '');
                }
                baseURL = communityURL;
            }
        } else{
            baseURL = Url.getSalesforceBaseUrl().toExternalForm();
        }
        return baseURL;        
    }

    public class ValueWrapper {
        @AuraEnabled public String label;
        @AuraEnabled public String value;
        @AuraEnabled public Boolean selected;
        
        public ValueWrapper(String label, String value) {
            this.label = label;
            this.value = value;
            this.selected = false;
        }
    }
}