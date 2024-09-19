public class MHEKnowledgeEmailController {  
    /*   MassEmailMessage Limitations
1. In Single SendEmail we can add only 5000 setTargetObjectIds.
2. In one tranction we can add only 10 SendEmail.
*/
    
    // Method is called from Screen Flow - "Send Email Notification of knowledge Article To MHE Users"
    @InvocableMethod
    public static void callFutureMethod(List<String> knowledgeId)
    {
        sendEmailNotificationToMHEUsers(knowledgeId[0]);
    }
    
    @future
    public static void sendEmailNotificationToMHEUsers(String knowledgeId) {
        Knowledge__kav knowledgeRecord=[SELECT Id,PublishStatus,Summary,IsVisibleInApp,IsVisibleInPrm,Title,UrlName FROM Knowledge__kav where Id=:knowledgeId]; 
        if(knowledgeRecord.IsVisibleInApp){
            sendEmailNotificationToMHEUsers(knowledgeRecord,'Send to Internal');
        }
        if(knowledgeRecord.IsVisibleInPrm){
            sendEmailNotificationToMHEUsers(knowledgeRecord,'Send to External');
        }
        
    }
    public static void sendEmailNotificationToMHEUsers(Knowledge__kav knowledgeRecord,String receiverType) {
        //Knowledge__kav knowledgeRecord=[SELECT Id,PublishStatus,Summary,IsVisibleInApp,IsVisibleInPrm,Title FROM Knowledge__kav where Id=:knowledgeId]; 
        List<String> userIDList = new List<String>();        
        Integer sendEmailCounter=1;          
        Map<Integer,List<Id>> userIdMap=new Map<Integer,List<Id>>();
        userIDList.addAll(fetchUserIds(knowledgeRecord,receiverType)); // Fetched User Ids and added in list. 
        if(!userIDList.isEmpty()){
            if(userIDList.size()>5000 || Test.isRunningTest()){
                Integer userIdCount=1;
                List<Id> idList=new List<Id>();
                for(String userId:userIDList){
                    idList.add(userId); 
                    if(userIdCount==5000){
                        userIdMap.put(sendEmailCounter,idList);
                        idList=new List<Id>();
                        sendEmailCounter++;
                        userIdCount=1;
                    }
                    else{
                        userIdCount++;
                    }                    
                }
                if(!idList.isEmpty()){
                    userIdMap.put(sendEmailCounter,idList);
                }
            }
            else{
                userIdMap.put(sendEmailCounter,userIDList);
            }
            
            // Query Email Template and update knowledge record link in email template. Select id,body,HtmlValue,Subject from EmailTemplate where DeveloperName =:GlobalConstants.MHE_Knowledge_Template limit 1 
            EmailTemplate template;//
            
            if(receiverType == 'Send to Internal'){
                template=[Select id,body,HtmlValue,Subject from EmailTemplate where DeveloperName =:GlobalConstants.MHE_Internal_User_Knowledge_Published limit 1];  
                template.HtmlValue=template.HtmlValue.replace(template.HtmlValue.substringBetween('<a href="','</a>'), URL.getSalesforceBaseUrl().toExternalForm() +'/'+knowledgeRecord.Id+'">'+knowledgeRecord.Title);
            }
            else if(receiverType == 'Send to External'){
                template=[Select id,body,HtmlValue,Subject from EmailTemplate where DeveloperName =:GlobalConstants.MHE_External_User_Knowledge_Published limit 1];  
                //template.HtmlValue=template.HtmlValue.replace(template.HtmlValue.substringBetween('<a href="','</a>'), 'https://gnb--onecrmuat.sandbox.my.site.com/gbpartners/s/article' +'/'+knowledgeRecord.UrlName +'">'+knowledgeRecord.Title);
                template.HtmlValue=template.HtmlValue.replace(template.HtmlValue.substringBetween('<a href="','</a>'), 'https://gnb.my.site.com/gbpartners/s/article' +'/'+knowledgeRecord.UrlName +'">'+knowledgeRecord.Title);
            }
            
            template.Subject = template.Subject.substringBefore('\'')+ '\''+knowledgeRecord.Title+'\'';
            
            System.debug(template);
            update template;
            List<Messaging.MassEmailMessage> mailList = new List<Messaging.MassEmailMessage>();
            for(Integer key:userIdMap.keySet()){                
                Messaging.MassEmailMessage mail = new Messaging.MassEmailMessage();
                mail.setTargetObjectIds(userIdMap.get(key));
                mail.setTemplateId(template.Id);
                mail.setsaveAsActivity(false);
                mailList.add(mail);
            }
            
            Messaging.sendEmail(mailList);
        }
    }
    
    private static Set<String> fetchUserIds(Knowledge__kav knowledgeRecord,String receiverType){
        Set<String> userIdSet=new Set<String>();
        Set<String> profileNameSet=new Set<String>();
        if(receiverType == 'Send to External'){
            profileNameSet.addAll(System.Label.MHE_External_User_Profiles.split(','));
        }
        if(receiverType == 'Send to Internal'){
            profileNameSet.addAll(System.Label.MHE_Internal_User_Profiles.split(','));
        }
        for(String s:profileNameSet ){
            profileNameSet.add(s.trim());
        }
        if(!profileNameSet.isEmpty()){
            for(User userRecord:[Select Id from User where IsActive=true and Profile.Name IN :profileNameSet limit 50000 ]){
                userIdSet.add(userRecord.Id);
            }
        }
        return userIdSet;
    }
}