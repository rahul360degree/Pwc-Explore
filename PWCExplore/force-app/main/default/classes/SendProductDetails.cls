public  class SendProductDetails {
    @AuraEnabled
    public static String SendProductDetailsMethod(Id recordId){

        Id getrecordId = recordId; 
        String getObj = getrecordId.getSobjectType().getDescribe().getName();
        //System.debug('getObj:'+getObj);
        List<Product2> getProduct;
        List<ContentDocumentLink> cdLink;
        List<ContentDistribution> contentDistributionList= new List<contentDistribution>();
        List<ContentDistribution> contentDistributionCount;
        List<ContentDistribution> contentDistributionInsert;
        List<OpportunityLineItem> opLineItemList;
        List<QuoteLineItem> quoteLineItemList;
        List<OrderItem> orderItemList;
        
        Account accountRecord;
        
        if(getObj=='Opportunity'){
            String getLineItem = 'OpportunityLineItem';
            opLineItemList = [SELECT Id,Product2Id from OpportunityLineItem Where OpportunityId =:recordId];
            accountRecord = [SELECT OwnerId,Name,PersonEmail,PersonMobilePhone from Account a where a.Id in ( Select AccountId from Opportunity b where b.Id=:recordId)];
            System.debug('opLineItemList :'+opLineItemList);
        }
        
        if(getObj=='Quote'){
            String getLineItem = 'QuoteLineItem';
            quoteLineItemList = [SELECT Id,Product2Id from QuoteLineItem Where QuoteId =:recordId];
            accountRecord = [SELECT OwnerId,Name,PersonEmail,PersonMobilePhone from Account a where a.Id in ( Select AccountId from Quote b where b.Id=:recordId)];
            System.debug('quoteLineItemList :'+quoteLineItemList);
        }
        
        if(getObj=='Order'){
            String getLineItem = 'OrderItem';
            orderItemList = [SELECT Id,Product2Id from OrderItem Where OrderId =:recordId];
            accountRecord = [SELECT OwnerId,Name,PersonEmail,PersonMobilePhone from Account a where a.Id in ( Select AccountId from Order b where b.Id=:recordId)];
            System.debug('orderItemList :'+orderItemList);
        }
        
        List<ContentVersion> contentVersion= new List<ContentVersion>{}; 
        List<ContentVersion> ContentVersionIds = new List<ContentVersion>{};
        Set<Id> productIds = new Set<Id>();
        //System.debug('orderItemList outside if :'+orderItemList);
        if(opLineItemList!=null||quoteLineItemList!=null||orderItemList!=null){
            if(opLineItemList!=null){                
                for(OpportunityLineItem opLineItem : opLineItemList){
                    productIds.add(opLineItem.Product2Id);
                }
            } 
            
            if(quoteLineItemList!=null){                
                for(QuoteLineItem quoteLineItem : quoteLineItemList){
                    productIds.add(quoteLineItem.Product2Id);
                }
            }
            
            if(orderItemList!=null){                
                for(OrderItem orderLineItem : orderItemList){
                    productIds.add(orderLineItem.Product2Id);
                }
            }
            
                cdLink = [SELECT Id,ContentDocumentId from ContentDocumentLink Where LinkedEntityId IN:productIds]; 
                //System.debug(cdLink);
                Set<Id> ContentDocumentIds = new Set<Id>();
                if(!cdLink.isEmpty()){
                    for(ContentDocumentLink clink: cdLink){
                        ContentDocumentIds.add(clink.ContentDocumentId);
                    }
                    //System.debug(ContentDocumentIds);
                    

                    contentVersion.addAll([
                        SELECT Id, Title, FileType, VersionData, isLatest, ContentDocumentId
                        FROM ContentVersion
                        WHERE isLatest = true  AND FileType='PDF' AND ContentDocumentId IN :ContentDocumentIds
                    ]);
                    
                    //System.debug('contentVersion'+contentVersion);
                    
                    ContentVersionIds = new List<ContentVersion>();
                    ContentVersionIds = [SELECT Id
                        FROM ContentVersion
                        WHERE isLatest = true AND ContentDocumentId IN :ContentDocumentIds
                    ]; 
                    
                    contentDistributionCount = new List<contentDistribution>();
                     contentDistributionCount = [SELECT PdfDownloadUrl 
                        FROM ContentDistribution 
                        WHERE ContentVersionId IN :ContentVersionIds
                    ];    
                    if(contentDistributionCount.isEmpty()){
                      contentDistributionInsert = new List<contentDistribution>();
                      
                        
                      for(ContentVersion cv :contentVersion){
                         ContentDistribution cd = new ContentDistribution();  
                         System.debug('Check contenVersion :'+cv);                         
                         cd.Name = cv.Title;
                         cd.ContentVersionId = cv.Id;
                         cd.PreferencesAllowViewInBrowser= true;
                         cd.PreferencesLinkLatestVersion=true;
                         cd.PreferencesNotifyOnVisit=false;
                         cd.PreferencesPasswordRequired=false;
                         cd.PreferencesAllowOriginalDownload= true;                         
                         //System.debug('cd :'+cd);                         
                         contentDistributionInsert.add(cd); 
                         //System.debug('contentDistribution size :'+contentDistributionList.size());
                      }
                          if(contentDistributionInsert.size() > 0 ) {
                              try {
                                  insert contentDistributionInsert;
                              }
                              catch(Exception ex) {
                              }
                          }
                        
                    }    

                     contentDistributionList = [SELECT PdfDownloadUrl 
                        FROM ContentDistribution 
                        WHERE ContentVersionId IN :ContentVersionIds
                    ];  
                                            
                    //System.debug('contentDistributionList :'+contentDistributionList);
                }
            }
        
         
        List<OrgWideEmailAddress> lstOrgWideEmailId = [Select id,displayName from OrgWideEmailAddress where id='0D22h000000CcFzCAK']; //To set OneGodrej as Sender
        Id orgWideEmailAddressID;
        String orgWideEmailAddressDisplayName;
        if(lstOrgWideEmailId.size() != 0)
        {
            orgWideEmailAddressID = lstOrgWideEmailId[0].id;
            orgWideEmailAddressDisplayName = lstOrgWideEmailId[0].displayName;
        }

        List<Messaging.Email> emailList=new List<Messaging.Email>();
        if(accountRecord.PersonEmail!=null){
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setOrgWideEmailAddressId(orgWideEmailAddressID);
            mail.setUseSignature(false);
            List<string> setToAddresses=new List<string>();
            setToAddresses.add(accountRecord.PersonEmail); 
            mail.setToAddresses(setToAddresses);   //Set To Email Address        
            //mail.setToAddresses(new String[] {'shreela@godrej.com','meshramp@godrej.com'});
            mail.setSubject('Product Attachment Email');    //Set Subject 
            
            //Message with line break tag
            String body = '<html><body>Dear Customer,<br><br>Please check the attached details of the product based on your interest.<br><br>We look forward to serve you better.<br><br>Regards,<br>Godrej & Boyce<br>Customer Experience group</body></html>';
            mail.setHtmlBody(body);  //Set HTML Body
            mail.setSaveAsActivity(false);
            
            List<Messaging.Emailfileattachment> fileAttachments = new List<Messaging.Emailfileattachment>();
            if(!contentVersion.isEmpty()){
                for (ContentVersion document: contentVersion) {
                    Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
                    
                    attachment.setBody(document.VersionData);
                    attachment.setFileName(document.Title+ '.pdf');
                    attachment.setContentType('application/pdf');                
                    fileAttachments.add(attachment);
                    
                }
                mail.setFileAttachments(fileAttachments); 
            }
            
            emailList.add(mail);    
            Messaging.sendEmail(emailList);
        }
        String mobNo;
        String contentDistributionString;
        if(accountRecord.PersonMobilePhone!=null){
             mobNo = String.valueOf(accountRecord.PersonMobilePhone);
             //System.debug('contentDistribution size :'+contentDistributionList.size());
            if(!contentDistributionList.isEmpty()){
                for(ContentDistribution cdString :contentDistributionList){
                    contentDistributionString =  String.valueOf(cdString.PdfDownloadUrl);
                    SendProductDetails.SendProductDetailsInSMS(contentDistributionString,mobNo);
                }
            }    
            
         } 
        if(!contentVersion.isEmpty()){
            return 'Successfully sent attachment';
        }
        else{
            return 'File Not found';
        }
    }
 
    @future(callout = true)
    public static void SendProductDetailsInSMS(String contentDistributionString,String mobNo){
         String mobileNo = mobNo;
         String downloadUrl = contentDistributionString;
         String tinyurl;
         TinyUrlService bsb = new TinyUrlService();
         tinyurl = bsb.create(downloadUrl);
         //System.debug(tinyurl);
         SendProductDetails.generateSMS(tinyurl,mobileNo);        
      }    
    
    public static void generateSMS(String tinyurl,String mobileNo){
            String mobilePhone = mobileNo;
            String checkmobTenDigitNo;
            String mobNo;
            if (mobilePhone != null ) {
                checkmobTenDigitNo = mobilePhone.substring(0,10);
                Boolean abc = checkmobTenDigitNo.isNumeric();
                if(abc==true){
                    mobNo = checkmobTenDigitNo;
                    //System.debug('mobNo inside generateSMS1'+mobNo);
                }
            }
            String smsBody = 'Dear Customer, Sharing with you product detail. download file '+tinyurl;
            //System.debug('Check smsBody'+smsBody);
            //System.debug('mobNo inside generateSMS2'+mobNo);
            HttpResponse response;
            PaymentReceiptResponseClass pr = new PaymentReceiptResponseClass();
           if(mobNo!=null){
                response= pr.generateSMSRequest(mobNo,smsBody);
           }

            System.debug('response inside generateSMS'+response);
       } 
}