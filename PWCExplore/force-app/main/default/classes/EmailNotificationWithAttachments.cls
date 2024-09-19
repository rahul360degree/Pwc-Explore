/*------------------------------------------------------------------------
Author:        Shreela Nair
Company:       Godrej Infotech
Description:   Class to send Email Notification of different Object Records along with Attachments.
Added for Jira number - SMEPB 19
Inputs:        
Test Class:    

History
29-03-2022      Shreela Nair     Initial Release
29-03-2022      Shreela Nair     Method to fetch Attachment of SObject Record for Email Notification
31-03-2022      Shreela Nair     Method to send Email Notification along with Attachment of MHE Synced Outright Sales 
Order record to MHE Outright Sales User.
----------------------------------------------------------------------------*/
public class EmailNotificationWithAttachments {
    
    
    /*------------------------------------------------------------------------
Author:        Shreela Nair
Company:       Godrej Infotech
Description:   Method to fetch Attachment of SObject Record for Email Notification
Inputs:        
Test Class:    

----------------------------------------------------------------------------*/
    public static List<ContentVersion> getAttachmentUsingRecordIds(Set<Id> newItemId){
        
        Set<String> contentDocumentSet = new Set<String>();
        
        //Get ContentDocumentId from ContentDocumentLink Object
        for(ContentDocumentLink doc : [SELECT ContentDocumentId,ContentDocument.title,Id,LinkedEntityId,ShareType 
                                       FROM ContentDocumentLink 
                                       WHERE LinkedEntityId IN :newItemId]){
                                           contentDocumentSet.add(doc.ContentDocumentId);
                                       }  
        
        //For each content version file get the file name, extension, version
        List<ContentVersion> ContentVersionFile = [SELECT VersionData, title, FileType, FileExtension 
                                                   FROM ContentVersion
                                                   WHERE ContentDocumentId IN :contentDocumentSet 
                                                   AND IsLatest = true];
        
        if(!ContentVersionFile.isEmpty()){
            return  ContentVersionFile;
        }
        else{
            return null;
        }
    }
    
    /*------------------------------------------------------------------------
Author:        Shreela Nair
Company:       Godrej Infotech
Description:   Method to send Email Notification along with Attachment of MHE Synced Outright Sales 
Order record to MHE Outright Sales User.
Inputs:        
Test Class:    

----------------------------------------------------------------------------*/    
    /*public static void OrderNotificationToMheOutrightUser(Map<Id,Order> oldOrderItems,Id newOrderId){

//Email Template to set as body of each and every Email 
EmailTemplate emailTemplate =[SELECT Id,Subject,Description,DeveloperName,HtmlValue,Body 
FROM EmailTemplate
WHERE DeveloperName ='Send_Order_Details_1648632203286']; 
String emailBody = '';

List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();  

//To set OneGodrej as Sender
List<OrgWideEmailAddress> lstOrgWideEmailId = [SELECT id,DisplayName,Address FROM OrgWideEmailAddress WHERE Address='onecrm@godrej.com'];                    

//Set Email address in To of Email
List<GroupMember> grpMembersinTo = [SELECT GroupId,Id,UserOrGroupId FROM GroupMember where Group.DeveloperName = 'MHE_Outright_Sales_To_User'];
List<String> toEmailAddress = getEmailAddress(grpMembersinTo);

//Set Email address in Cc of Email
List<GroupMember> grpMembersinCc = [SELECT GroupId,Id,UserOrGroupId FROM GroupMember where Group.DeveloperName = 'MHE_Outright_Sales_Cc_User'];
List<String> ccEmailAddress = getEmailAddress(grpMembersinCc); 

//Query the related lookup of Order for assignment of placeholders in email template
Map<Id,Order> ordMap = new Map<Id,Order>([SELECT Order.Sold_to_Business_Partner__r.Name,
Order.Sold_to_Business_Partner__r.Account_Code__c, Order.WarehouseCode__r.Name 
FROM ORDER
WHERE Id =:newOrderId]);

//Query the related Order Product
Map<Id,OrderItem> ordItem = new Map<Id,OrderItem>([SELECT Id,Product2.Name,Quantity,OrderId 
FROM OrderItem 
WHERE OrderId =: newOrderId]);

emailBody = emailTemplate.HtmlValue;

Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
List<Messaging.EmailFileAttachment> attach= new list<Messaging.EmailFileAttachment>();     

Set<Id> orderId = new Set<Id>();
orderId.add(newOrderId);           

//For each content version file get the file name, extension, version and add into the attachment list called 'attach'
List<ContentVersion> contentVersionData = getAttachmentUsingRecordIds(orderId);
try{

for(ContentVersion contentVersionFile : contentVersionData){ 
Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
efa.setFileName(contentVersionFile.title.Trim()+'.'+contentVersionFile.FileExtension.Trim());
efa.setBody(contentVersionFile.VersionData);
attach.add(efa);

} 


}
catch(Exception e){
System.debug('Exception');
} 

message.setFileAttachments(attach);

//Replace all placeholder in email template with values
if(ordMap.get(newOrderId).Sold_to_Business_Partner__r.Name<>null){
emailBody = emailBody.replace('{​​!BPNameList​​}',  ordMap.get(newOrderId).Sold_to_Business_Partner__r.Name);
} 
else{
emailBody = emailBody.replace('{​​!BPNameList​​}',  '');

}

if(ordMap.get(newOrderId).Sold_to_Business_Partner__r.Account_Code__c<>null){
emailBody = emailBody.replace('{​​!BPCodeList​​}',  ordMap.get(newOrderId).Sold_to_Business_Partner__r.Account_Code__c);
} 
else{
emailBody = emailBody.replace('{​​!BPCodeList​​}', '');

}

if(ordMap.get(newOrderId).WarehouseCode__r.Name<>null){
emailBody = emailBody.replace('{​​!WareHouseCodeList​​}',ordMap.get(newOrderId).WarehouseCode__r.Name); 
} 
else{
emailBody = emailBody.replace('{​​!WareHouseCodeList​​}', '');

}


if(oldOrderItems.get(newOrderId).Order_Amount__c<>null){
emailBody = emailBody.replace('{​​!ValueOrderAmountList​​}',oldOrderItems.get(newOrderId).Order_Amount__c.format());
}

else{
emailBody = emailBody.replace('{​​!ValueOrderAmountList​​}','');
}

//To display Name and quantiy of related Order Product
for(OrderItem orderItem : OrdItem.values()){
if(orderItem.OrderId == newOrderId)
emailBody+= '<html><body>Products :  '+orderItem.Product2.Name+'<br>Quantity :  '+orderItem.Quantity+'<br><br></body></html>';
}

String fullRecordURL;
fullRecordURL = URL.getSalesforceBaseUrl().toExternalForm() + '/lightning/r/Order/'+newOrderId+'/view';

emailBody+= '<html><body>Click '+fullRecordURL+' to view the record.<br><br>Thanks & Regards,<br>Godrej MHE</body></html>';
message.setHTMLBody(emailBody);
message.setOrgWideEmailAddressId(lstOrgWideEmailId[0].id);  
message.setToAddresses(toEmailAddress);
message.setUseSignature(false);
message.setSubject('Your order has been synced');
message.setWhatId(newOrderId);
message.setTreatBodiesAsTemplate(true);  //To treat template data as email body
message.setCcAddresses(ccEmailAddress);
emailsToSend.add(message);

Messaging.SendEmailResult [] result =  Messaging.sendEmail(emailsToSend);


} */
    
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
    //Email address in CC of Email
    public static List<String> ccEmailAddress{
        get{
            return ccEmailAddress;
        }
        set{
            ccEmailAddress = value;
        }
    }
    //Email Template
    public static EmailTemplate emailTemplate{
        get{
            return emailTemplate;
        }set{
            emailTemplate = value;
        }
    }
    //Map of Order and Order Line Item
    public static Map<Id,Order> orderMap{
        get{
            return orderMap;
        }
        set{
            orderMap = value;
        }
    }
    
    //Key=> OrderId and Value List of content files
    public static Map<Id,List<ContentVersion>>orderVSFileMap{
        get{
            return orderVSFileMap;
        }
        set{
            orderVSFileMap = value;
        }
    }
    //Old Order Map
    public static Map<Id,Order> oldOrderMap{
        get{
            return oldOrderMap;
        }
        set{
            oldOrderMap = value;
        }
    }
    //Key=> Quote Id, Value=> QuoteLineItem record
    public static Map<Id,QuoteLineItem> quoteLineItemMap {
        get{
            return quoteLineItemMap;
        }
        set{
            quoteLineItemMap = value;
        }
    }
    //call this method to send the email
    public static void OrderNotificationToMheOutrightUser(Set<Id> orderIdSet,Map<Id,Order> oldOrders){
        try{
            EmailNotificationWithAttachments.orgWideEmailAddress = [SELECT id,DisplayName,Address FROM OrgWideEmailAddress WHERE Address='onecrm@godrej.com'][0];
            EmailNotificationWithAttachments.toEmailAddress = getEmailAddress([SELECT GroupId,Id,UserOrGroupId FROM GroupMember where Group.DeveloperName = 'MHE_Outright_Sales_To_User']);
            EmailNotificationWithAttachments.ccEmailAddress = getEmailAddress([SELECT GroupId,Id,UserOrGroupId FROM GroupMember where Group.DeveloperName = 'MHE_Outright_Sales_Cc_User']);
            EmailNotificationWithAttachments.emailTemplate = [SELECT Id,Subject,Description,DeveloperName,HtmlValue,Body FROM EmailTemplate WHERE DeveloperName ='Send_Order_Details_1648632203286'];
            EmailNotificationWithAttachments.orderMap = new Map<Id,Order>([SELECT Id, QuoteId, Order.Sold_to_Business_Partner__r.Name, Order.Sold_to_Business_Partner__r.Account_Code__c,
                                                                                Order.WarehouseCode__r.Name,
                                                                        (SELECT Id,Product2.Name,Quantity,OrderId, QuoteLineItemId FROM OrderItems)
                                                                        FROM ORDER WHERE Id IN: orderIdSet
                                                                        ]);
            EmailNotificationWithAttachments.orderVSFileMap = getfiles();
            EmailNotificationWithAttachments.oldOrderMap = oldOrders;
            EmailNotificationWithAttachments.quoteLineItemMap = getQuoteLineItemMap();
            List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
            for(Id orderId:orderIdSet){
                emailList.add(emailMessage(EmailNotificationWithAttachments.orderMap.get(orderId),EmailNotificationWithAttachments.orderVSFileMap.get(orderId)));
            }
            Messaging.SendEmailResult [] result =  Messaging.sendEmail(emailList);
        }catch(Exception ex){
            throw ex;
        }
    }
    //Key=>Quote Id, Value=>Quote Record
    private static Map<Id,QuoteLineItem> getQuoteLineItemMap(){
        List<Order> orderList = orderMap.values();
        Set<Id> quoteIds = new Set<Id>();
        for(Order order:orderList){
            quoteIds.add(order.QuoteId);
        }
        if( quoteIds.isEmpty()){
            return new Map<Id,QuoteLineItem>();
        }else{
            return new Map<Id,QuoteLineItem>([Select Id,Description from QuoteLineItem where QuoteId IN:quoteIds]);
        }
        
    }
    //prepare email message
    private static Messaging.SingleEmailMessage emailMessage(Order order, List<ContentVersion> contentVersionData){		
        String emailBody = handlePlaceholder(order);
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        List<Messaging.EmailFileAttachment> attach= new list<Messaging.EmailFileAttachment>();     
        if(contentVersionData<> null && !contentVersionData.isEmpty()){
            for(ContentVersion contentVersionFile : contentVersionData){ 
                Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
                efa.setFileName(contentVersionFile.title.Trim()+'.'+contentVersionFile.FileExtension.Trim());
                efa.setBody(contentVersionFile.VersionData);
                attach.add(efa);
            } 
        }
        message.setFileAttachments(attach);
        message.setHTMLBody(emailBody);
        message.setOrgWideEmailAddressId(EmailNotificationWithAttachments.orgWideEmailAddress.Id);  
        message.setToAddresses(EmailNotificationWithAttachments.toEmailAddress);
        message.setUseSignature(false);
        message.setSubject('Your order has been synced');
        message.setWhatId(order.Id);
        message.setTreatBodiesAsTemplate(true);  //To treat template data as email body
        message.setCcAddresses(EmailNotificationWithAttachments.ccEmailAddress);
        return message;
    }
    
    //key=>Order Id, Value=>Files
    private static Map<Id,List<ContentVersion>> getfiles(){
        Map<Id,Id> cdLinkIdVSOrderId = new Map<Id,Id>();
        for(ContentDocumentLink doc : [SELECT ContentDocumentId,ContentDocument.title,Id,LinkedEntityId,ShareType 
                                       FROM ContentDocumentLink 
                                       WHERE LinkedEntityId IN :EmailNotificationWithAttachments.orderMap.keySet()]){
                                           cdLinkIdVSOrderId.put(doc.ContentDocumentId,doc.LinkedEntityId);
                                       }
        Map<Id,List<ContentVersion>> orderVSFile = new Map<Id,List<ContentVersion>> ();
        for(ContentVersion cvFile : [SELECT VersionData, title, FileType, FileExtension, ContentDocumentId 
                                     FROM ContentVersion 
                                     WHERE ContentDocumentId IN :cdLinkIdVSOrderId.keySet() AND IsLatest = true])
        {
            if(!orderVSFile.containskey(cdLinkIdVSOrderId.get(cvFile.ContentDocumentId))){
                orderVSFile.put(cdLinkIdVSOrderId.get(cvFile.ContentDocumentId), new List<ContentVersion>());
            }
            orderVSFile.get(cdLinkIdVSOrderId.get(cvFile.ContentDocumentId)).add(cvFile);
        }
        return orderVSFile;
    }
    
    //Get email Addresses
    private static List<String> getEmailAddress(List<GroupMember> grpMembers){
        Set<Id> usrId = new Set<Id>();
        for(GroupMember grpid : grpMembers){
            usrId.add(grpid.UserOrGroupId);
        }
        
        List<User> userDetails = [Select Id,Email from User where Id In : usrId];
        List<String> emailAddress = new List<String>();
        for(User usr : userDetails){
            emailAddress.add(usr.Email);
        }
        
        return emailAddress;
    }
    //replace placeholders
    private static String handlePlaceholder(Order order){
        String emailBody = EmailNotificationWithAttachments.emailTemplate.HtmlValue;
        
        if(order.Sold_to_Business_Partner__r.Name<>null){
            emailBody = emailBody.replace('{​​!BPNameList​​}',  order.Sold_to_Business_Partner__r.Name);
        } 
        else{
            emailBody = emailBody.replace('{​​!BPNameList​​}',  '');
            
        }
        
        if(order.Sold_to_Business_Partner__r.Account_Code__c<>null){
            emailBody = emailBody.replace('{​​!BPCodeList​​}',  order.Sold_to_Business_Partner__r.Account_Code__c);
        } 
        else{
            emailBody = emailBody.replace('{​​!BPCodeList​​}', '');
            
        }
        
        if(order.WarehouseCode__r.Name<>null){
            emailBody = emailBody.replace('{​​!WareHouseCodeList​​}',order.WarehouseCode__r.Name); 
        } 
        else{
            emailBody = emailBody.replace('{​​!WareHouseCodeList​​}', '');
        }
        
        // get previous value
        if(EmailNotificationWithAttachments.oldOrderMap.get(order.Id).Order_Amount__c<>null){
            emailBody = emailBody.replace('{​​!ValueOrderAmountList​​}',EmailNotificationWithAttachments.oldOrderMap.get(order.Id).Order_Amount__c.format());
        }	
        else{
            emailBody = emailBody.replace('{​​!ValueOrderAmountList​​}','');
        }

        //get QuoteLineItem description
        if(!((order.OrderItems).isEmpty())){
            for(OrderItem orderItem : order.OrderItems){
                System.debug(orderItem);
                String orderValue = 'Products : '+orderItem.Product2.Name+'<br>Quantity :  '+orderItem.Quantity;
                if( !String.isEmpty(orderItem.QuoteLineItemId) && quoteLineItemMap.containsKey(orderItem.QuoteLineItemId) && !(String.isEmpty(quoteLineItemMap.get(orderItem.QuoteLineItemId).Description)) ){
                    orderValue +='<br/>Description : '+quoteLineItemMap.get(orderItem.QuoteLineItemId).Description;
                }
                emailBody+= '<html><body>Products :  '+ orderValue +'<br><br></body></html>';
            }
        }


        String fullRecordURL = URL.getSalesforceBaseUrl().toExternalForm() + '/lightning/r/Order/'+order.Id+'/view';
        emailBody+= '<html><body>Click '+fullRecordURL+' to view the record.<br><br>Thanks & Regards,<br>Godrej MHE</body></html>';
        return emailBody;
    }		
}