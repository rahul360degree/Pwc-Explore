/**
* @description       : To send email to Hot Owner,Opportunity Owner and email addres mentioned in custom metadata
* @author            : shreela@godrej.com,vrajpoot@godrej.com
* @group             : 
* @last modified on  : 16-02-2023
* @last modified by  : priyamu@godrej.com
**/
public class HoTExpiryNotificationHelper {
    public void sendNotificationEmail(List<HEAD_OF_TERMS__c> scope){
        try{
            //Fetching lightning email template
            EmailTemplate emailTemplate =[SELECT Id,Subject,Description,DeveloperName,HtmlValue,Body 
                                        FROM EmailTemplate
                                        WHERE DeveloperName ='HoT_expiry_Notification'
                                        ]; 
            List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();
            //To set OneGodrej as Sender
            List<OrgWideEmailAddress> lstOrgWideEmailId = [SELECT id,DisplayName,Address 
                                                        FROM OrgWideEmailAddress 
                                                        WHERE Address='onecrm@godrej.com'];
            
            //if(!lstOrgWideEmailId.isEmpty() && emailTemplate <> null){
            if(!lstOrgWideEmailId.isEmpty()){
                HoT_Notification_Setting__mdt config = [SELECT Id,Email_Address__c,Number_of_Month__c 
                                                        FROM HoT_Notification_Setting__mdt 
                                                        WHERE DeveloperName='Default'];
                
                List<String>ccEmailAddress = new List<String>();
                //To send email notification to email address set in below mentioned field
                if(config<>null && String.isNotEmpty(config.Email_Address__c)){
                    ccEmailAddress = config.Email_Address__c.split(';');
                }
                String assetcode='';//moved the declaration outside the loop
                List<String> addnCCEmailAddress = new List<String>();//moved the declaration outside the loop
                 
                for(HEAD_OF_TERMS__c hot : scope){
                    String emailBody = emailTemplate.HtmlValue; 
                    
                    addnCCEmailAddress.addall(ccEmailAddress);//Adding the cc list from meta data
                    addnCCEmailAddress.add(hot.Opportunity__r.Owner.Email);//Adding opportunity owner
                    
                    //Get all Asset Code and replace in email body
                    for(Junction_Unit__c unit: hot.Rental_Units__r){
                        assetcode += unit.Floor__r.Asset_Code__c+',';                        
                    }
                    if(String.isNotEmpty(assetcode)){
                        assetcode = assetcode.removeEnd(',');                         
                    }
                    
                    //To replace variable mentioned in email template{​​!AssetCodeList}​​
                    emailBody = emailBody.replace('{​​!AssetCodeList}​​', assetcode);
                    Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                    String subject = ''+hot.Name+' '+'agreement due for Renewal';
                    
                    List<string> setToAddresses=new List<string>();
                    setToAddresses.add(hot.owner.email);
                    message.setOrgWideEmailAddressId(lstOrgWideEmailId[0].id);   
                    message.setToAddresses(setToAddresses);
                    message.setUseSignature(false);
                    message.setSubject(subject);
                    message.setHTMLBody(emailBody);
                    message.setWhatId(hot.Id);
                    message.setTreatBodiesAsTemplate(true);
                    message.setCcAddresses(addnCCEmailAddress);
                    emailsToSend.add(message);
                    assetcode = '';//tidy before next iteration
                    addnCCEmailAddress.clear();//tidy before next iteration
                }
                Messaging.SendEmailResult [] result =  Messaging.sendEmail(emailsToSend);
            }
        
        }catch(Exception ex){
            System.debug(ex.getStackTraceString());
        }
    }
    
}