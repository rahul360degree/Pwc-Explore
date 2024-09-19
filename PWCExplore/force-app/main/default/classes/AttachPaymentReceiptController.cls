public class AttachPaymentReceiptController {

    public class ReceiptException extends Exception {}
   
    @AuraEnabled   
    public static String createAttachmentRecord(String recordId) {        
              
        Advance_Payment_Details__c advancePaymentRecord = [SELECT Id,Business_Unit__c, Name, Order__c 
                                                           FROM Advance_Payment_Details__c WHERE ID = :recordId limit 1];
        PageReference pdf;
        
        if(advancePaymentRecord.Business_Unit__c=='W'){
            //added by siddhesh for checking script user
            string LoghInId = UserInfo.getUserId() ;
            System.debug('Current Login Id is :'+LoghInId);
            
            User loginUserRecord = [SELECT Email,FirstName,Interio_Sub_Division__c,LastName 
                                    FROM User WHERE Id = : LoghInId];
            System.Debug('USer all Details =' + loginUserRecord.Interio_Sub_Division__c);

            if( loginUserRecord.Interio_Sub_Division__c == 'Scripts'){
                pdf=Page.PaymentReceipt_InterioScript;
            }else
            {  pdf=Page.PaymentReceipt; }
            
            //ended by siddhesh for checking script user
        // pdf=Page.PaymentReceipt;
       }
       else 
        if(advancePaymentRecord.Business_Unit__c=='H'){
             System.debug('appliances :'+advancePaymentRecord.Business_Unit__c);
        pdf=Page.PaymentReceiptForAppliance;
        }
        if(pdf !=null){   
        pdf.getParameters().put('orderId', advancePaymentRecord.Order__c);
        pdf.getParameters().put('paymentId', recordId);
        }
        Blob body;
        
        try {
            if(Test.isRunningTest()) {
                body = blob.valueOf('PDF Content');
            } else {
                body = pdf.getContent();
            }
        } catch (ReceiptException ex) {
            body = Blob.valueOf('PDF Content');
        }
        
        String fileName = 'Payment_Receipt-' + advancePaymentRecord.Name + '.pdf';
        List<ContentDocumentLink> existingContent = [SELECT Id 
                                                     FROM ContentDocumentLink WHERE ContentDocument.Title = :fileName and LinkedEntityId = :recordId];
        
        //added by Shreela for assigning File Name Record Id and DownloadURL
        String fetchFileName;
        fetchFileName =  fileName;        
        String record;
        record = recordId;
        String downloadUrl;
        //ended by Shreela for assigning File Name and Record Id
        
        try {
          //  if(existingContent.size() > 0 )
                      if(existingContent.size() > 0 && advancePaymentRecord.Business_Unit__c !='W')
                throw new ReceiptException('Cannot generate receipt more than once.');
            
            ContentVersion contentVersion = new ContentVersion(ContentLocation = 'S', PathOnClient = fileName, Origin = 'H',
                                                               Title = fileName, VersionData = body);
            System.debug('upto this line 2  :'+contentVersion.id);
            insert contentVersion;
            
            //added by Pankaj and Shreela
            ContentDistribution cd = new ContentDistribution();
            cd.Name = fetchFileName;
            cd.ContentVersionId = contentVersion.Id;
            cd.PreferencesAllowViewInBrowser= true;
            cd.PreferencesLinkLatestVersion=true;
            cd.PreferencesNotifyOnVisit=false;
            cd.PreferencesPasswordRequired=false;
            cd.PreferencesAllowOriginalDownload= true;
            insert cd;

            ContentDistribution dowldUrl = [SELECT PdfDownloadUrl 
                                            FROM ContentDistribution WHERE Name= :fetchFileName];
            downloadUrl = String.valueOf(dowldUrl.PdfDownloadUrl);
            //System.debug('downloadUrl'+downloadUrl);
            //ended by Pankaj and Shreela
            
            Id contentDocumentId = [SELECT ContentDocumentId 
                                    FROM ContentVersion WHERE Id = :contentVersion.Id].ContentDocumentId;
            
            //added by Shreela for assigning Content Id
            Id fetchContentId;
            fetchContentId = contentDocumentId;
            //System.debug('fetchContentId  :'+fetchContentId);
            //ended by Shreela for assigning Content Id
            
            ContentDocumentLink contentDocLink = new ContentDocumentLink(ContentDocumentId = contentDocumentId, LinkedEntityId = recordId,
                                                                         ShareType = 'I', Visibility = 'AllUsers');
            System.debug('upto this line  :'+contentDocLink.id);
            insert contentDocLink;
             System.debug('upto this line 2  :'+contentDocLink.id);
            //return 'Successfully created attachment. Will be redirected to record page.';
            
            //added by Shreela for sending Email and SMS for Appliances Business Unit
            if(advancePaymentRecord.Business_Unit__c=='H'){
            System.debug('test business unit: '+advancePaymentRecord.Business_Unit__c); 
            System.debug('fetchFileName,record,fetchContentId: '+fetchFileName+','+record+','+fetchContentId);      
			AttachPaymentReceiptController.mailAttachmentToUser(fetchFileName,record,fetchContentId);
            AttachPaymentReceiptController.sendSMSNotification(record,downloadUrl);
            }
            //ended by Shreela for sending Email and SMS for Appliances Business Unit
            
			return 'Successfully created attachment. Will be redirected to record page.';
        } catch(ReceiptException ex) {
            return ex.getMessage();
        }
       	   	   
    }
	
            //added by Shreela 
            //To call function of Sending Email with Generated Advance Payment PDF Attachment  
	        public static void mailAttachmentToUser(String fetchFileName,String record,Id fetchContentId) {
            List<OrgWideEmailAddress> lstOrgWideEmailId = [SELECT id,displayName 
                                                           FROM OrgWideEmailAddress WHERE Address='onecrm@godrej.com'];  //To set OneGodrej as Sender
            Id orgWideEmailAddressID;
            String orgWideEmailAddressDisplayName;
            if(lstOrgWideEmailId.size() != 0)
            {
               orgWideEmailAddressID = lstOrgWideEmailId[0].id;
               orgWideEmailAddressDisplayName = lstOrgWideEmailId[0].displayName;
            }
    
                List<Messaging.Email> emailList=new List<Messaging.Email>();
                Advance_Payment_Details__c advancePaymentRecord = [SELECT Id,Business_Unit__c, Name, Order__c 
                                                                   FROM Advance_Payment_Details__c WHERE ID = :record limit 1];
                Id orderId = advancePaymentRecord.Order__c;
                Account accountRecord = [SELECT OwnerId,Name,PersonEmail 
                                         FROM Account a WHERE a.Id in ( SELECT AccountId FROM Order b WHERE b.Id=:orderId)];
        
                if(accountRecord.PersonEmail!=null){
                    //initiallize messaging method
                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                    mail.setOrgWideEmailAddressId(orgWideEmailAddressID);
                    mail.setUseSignature(false);
                    List<string> setToAddresses=new List<string>();
                    setToAddresses.add(accountRecord.PersonEmail); 
                    mail.setToAddresses(setToAddresses);   //Set To Email Address
                    //mail.setCcAddresses(new String[] {'shreela@godrej.com','meshramp@godrej.com'});
                    //mail.setTargetObjectId(accountRecord.PersonEmail); //Commented for testing
                    mail.setSubject('Advance Receipt Email');    //Set Subject
                    
                    //Message with line break tag
                    String body = '<html><body>Dear  <span style="color:red;font-weight:bold">'+accountRecord.Name+'</span>,<br><br>Thank you for giving us opportunity to serve you .<br><br>Please check attached Order conformation and Advance amount receipt .<br><br>Our representative will soon get in touch with you to assist.<br><br>Regards,<br>Godrej & Boyce<br>Customer Experience group</body></html>';
                    
                    mail.setHtmlBody(body);  //Set HTML Body
                    mail.setSaveAsActivity(false);
                    
                    List<Messaging.Emailfileattachment> fileAttachments = new List<Messaging.Emailfileattachment>();
                    PageReference pdfFile;
                    pdfFile=Page.PaymentReceiptForAppliance;
                    pdfFile.getParameters().put('orderId', advancePaymentRecord.Order__c);
                    pdfFile.getParameters().put('paymentId', record);
                    Blob b;
                    if(!test.isRunningTest()){
                        b = pdfFile.getContent();   
                    }
                    else{
                        b = Blob.valueOf('Dummy Body'); 
                    }
                       
                
                    for (ContentDocument contentDocFile : [SELECT Id,Title,FileType,FileExtension 
                                                           FROM ContentDocument WHERE Title = :fetchFileName])
                    {
                        // Add to attachment file list
                        Messaging.Emailfileattachment efa = new Messaging.Emailfileattachment();
                        efa.setFileName(contentDocFile.Title);
                        efa.setBody(b);
                        fileAttachments.add(efa);
                    }
                    
                    mail.setFileAttachments(fileAttachments); 
                    emailList.add(mail);	
                    Messaging.sendEmail(emailList);
                }    

	}
    
    //To send SMS Notification
    public static void sendSMSNotification(String record,String downloadUrl){

        Advance_Payment_Details__c advancePaymentRecord = [SELECT Id,Business_Unit__c, Name, Order__c 
                                                           FROM Advance_Payment_Details__c WHERE ID = :record limit 1];
        Id orderId = advancePaymentRecord.Order__c;
        //System.debug('Test 1');
        String orderNo;
        List<Order> orderNumber = [SELECT OrderNumber 
                                   FROM Order WHERE Id=:orderId];
        for(Order ord :orderNumber){
            orderNo = ord.OrderNumber;
        }
        
        //System.debug('orderNo'+orderNo);
        Account accountDetail = [SELECT OwnerId,Name,PersonMobilePhone 
                                 FROM Account a WHERE a.Id in (SELECT AccountId FROM Order b WHERE b.Id=:orderId)];
        
        //call bitlyservice class for fetching tiny url
        String url = downloadUrl;
        //System.debug('url '+url);
        String mobNo;
        if(accountDetail.PersonMobilePhone!=null){
             mobNo = String.valueOf(accountDetail.PersonMobilePhone);
         } 
        AttachPaymentReceiptController.calloutSMS(url,mobNo,orderNo);        
         
    }  
    
         //To generate Tiny URL from  TinyUrlService class
        @future(callout = true)
        public static void calloutSMS(String url,String mobNo, String orderNo){
            String orderNumber= orderNo;
            String mobile = mobNo;
            String urlCheck = url;
            //System.debug('urlCheck'+urlCheck);
            String tinyurl;

            TinyUrlService bsb = new TinyUrlService();
            tinyurl = bsb.create(url);
            System.debug(tinyurl);
            AttachPaymentReceiptController.generateSMS(tinyurl,mobile,orderNumber);
            
        }
    
       //To generate SMS body and URL through PaymentReceiptResponseClass class
       public static void generateSMS(String tinyurl,String mobile,String orderNumber){
            String orderNo = orderNumber;
            String mobileno = mobile;
            String checkmobTenDigitNo;
            String mobNo;
            if (mobileno != null ) {
                checkmobTenDigitNo = mobileno.substring(0,10);
                Boolean validateMobileNumber = checkmobTenDigitNo.isNumeric();
                if(validateMobileNumber==true){
                    mobNo = checkmobTenDigitNo;
                    //System.debug('mobNo inside generateSMS1'+mobNo);
                }
            }
            String smsBody = 'Dear Customer,Your order '+orderNo+' is received and in process. Download receipt: '+tinyurl;
            //String smsBody = generateSMSBody(orderNo,tinyurl);
            //System.debug('Check smsBody'+smsBody);
            //System.debug('mobNo inside generateSMS2'+mobNo);
            HttpResponse response;
            PaymentReceiptResponseClass pr = new PaymentReceiptResponseClass();
           if(mobNo!=null){
                response= pr.generateSMSRequest(mobNo,smsBody);
           }

            System.debug('response inside generateSMS'+response);
            //AttachPaymentReceiptController.sendSMSNotification(record,downloadUrl);
       }          
    
    //ended by Shreela 	
}