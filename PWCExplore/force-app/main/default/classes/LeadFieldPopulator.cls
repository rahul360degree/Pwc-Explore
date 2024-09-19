/*------------------------------------------------------------------------
Author:        Manasi Londhe
Company:       Salesforce
Description:   Class to populate Lead fields
Inputs:        map of created records
Test Class:   

History
08-05-2020      Manasi Londhe     Initial Release
----------------------------------------------------------------------------*/


public without sharing class LeadFieldPopulator {
    static final String B2CADDRESSRECORDTYPENAME = 'B2C_Additional_Address';
    /*------------------------------------------------------------------------
Author:        Manasi Londhe
Company:       Salesforce
Description:   Method to populate zip code rule on Lead
Inputs:        list of created order records
Test Class:   

History
08-05-2020      Manasi Londhe     Initial Release
30-10-2020      Manasi Londhe     Added channel parameter for applicance
----------------------------------------------------------------------------*/
    public void populateZipCodeRule(List<Lead> leads,Map<Id,Lead> mapOldLead){
        List<Lead> finalleads=new List<Lead>();
        Map<String,Zip_Code_Rule__c> ruleNameVsRuleRecord=new Map<String,Zip_Code_Rule__c>();
        if(mapOldLead==null){
            for(Lead l:leads){
                if(l.Applicable_For_Pincode_Based_Assignment__c){
                    finalleads.add(l);
                }
            }
        }
        else{
            for(Lead l:leads){
                if(l.Applicable_For_Pincode_Based_Assignment__c && (l.Business_Unit__c!=mapOldLead.get(l.Id).Business_Unit__c || l.ZipCode__c!=mapOldLead.get(l.Id).ZipCode__c ||
                                                                    l.Sub_Division__c!=mapOldLead.get(l.Id).Sub_Division__c || l.Interio_Sub_Division__c!=mapOldLead.get(l.Id).Interio_Sub_Division__c ||
                                                                    l.Channel__c !=mapOldLead.get(l.Id).Channel__c
                                                                   )){
                                                                       finalleads.add(l);
                                                                   }
            }
        }
        if(finalleads.size()>0){
            Id defaultQueueId = [select Id From Group Where Type = 'Queue' AND DeveloperName = :GlobalConstants.LEAD_ASSIGNMENT_DEFAULT_QUEUE].Id;
            Set<Id> zipCodeIds=new Set<Id>();
            Set<String> businessUnitSubDivZipCode=new Set<String>(); 
            for(Lead l: finalleads){
                if(l.ZipCode__c!=null){
                    zipCodeIds.add(l.ZipCode__c);
                }
            }
            Map<Id,ZipCode__c> idVszipCodes=new Map<id,ZipCode__c>([Select Name From ZipCode__c Where Id in :zipCodeIds]);
            for(Lead l:finalleads){
                String subDivision=l.Business_Unit__c==GlobalConstants.INTERIO_BUSINESS_UNIT?l.Interio_Sub_Division__c:l.Sub_Division__c;
                if(l.Business_Unit__c!=null && subDivision!=null && l.ZipCode__c!=null){
                    String ruleName=l.Business_Unit__c+'-'+subDivision+'-'+idVszipCodes.get(l.ZipCode__c).Name;
                    businessUnitSubDivZipCode.add(ruleName);
                    String ruleName2;
                    if(l.Business_Unit__c==GlobalConstants.APPLIANCE_BUSINESS_UNIT && l.Channel__c!=null){
                        ruleName2=ruleName+'-'+'ALL';
                        ruleName=ruleName+'-'+l.Channel__c;
                    }
                    businessUnitSubDivZipCode.add(ruleName);
                    businessUnitSubDivZipCode.add(ruleName2);
                }
            }
            for(Zip_Code_Rule__c rule :[Select Id,Name,Queue_1__c,Effective_Till__c
                                        From Zip_Code_Rule__c 
                                        Where Name in :businessUnitSubDivZipCode 
                                        And(( Queue_1__c!=null  And Effective_Till__c>=TODAY) OR (Account__c !=null))
                                        And Object_Name__c = 'Lead']){
                                            ruleNameVsRuleRecord.put(rule.Name,rule);
                                        }
            for(Lead l:finalleads){
                String subDivision=l.Business_Unit__c==GlobalConstants.INTERIO_BUSINESS_UNIT?l.Interio_Sub_Division__c:l.Sub_Division__c;
                if(l.Business_Unit__c!=null && subDivision!=null && l.ZipCode__c!=null){
                    String uniqueKey=l.Business_Unit__c+'-'+subDivision+'-'+idVszipCodes.get(l.ZipCode__c).Name;
                    if(l.Business_Unit__c==GlobalConstants.APPLIANCE_BUSINESS_UNIT && l.Channel__c!=null){
                        uniqueKey=uniqueKey+'-'+l.Channel__c;
                    }
                    if(ruleNameVsRuleRecord.containsKey(uniqueKey)){
                        l.Zip_Code_Rule__c=ruleNameVsRuleRecord.get(uniqueKey).Id;
                    }
                    if(l.Business_Unit__c==GlobalConstants.APPLIANCE_BUSINESS_UNIT && l.Zip_Code_Rule__c==null){
                        String key=l.Business_Unit__c+'-'+l.Sub_Division__c+'-'+idVszipCodes.get(l.ZipCode__c).Name+'-ALL';
                        if(ruleNameVsRuleRecord.containsKey(key)){
                            l.Zip_Code_Rule__c=ruleNameVsRuleRecord.get(key).Id;
                        }
                    }
                }
                else 
                    l.Zip_Code_Rule__c=null;
            }
        }
    }
    
    
    public void populateEmailDomain(List<Lead> leads,Map<Id,Lead> mapOldLead){
        //String email;
        for(Lead lead : leads) {
            if(null != lead.Email) {
                String email = lead.Email;
                lead.Email_Domain__c =  email.substringAfter('@');
            }
        }
    }
    
    /*------------------------------------------------------------------------
Author:        Pawan
Company:       Salesforce
Description:   Method to populate defaults on Lead
Inputs:        list of created order records nd branchName
Test Class:   

History
02-06-2020      Pawan     Initial Release
13-02-2024      Alpana S  Modified for SMEPB-148
----------------------------------------------------------------------------*/
    public void populateDefaults(List<Lead> leads,User loggedInUser){
        for(Lead newLead : leads){
            //If Branch is not populated then populated with Logged in User Branch
            if(newLead.Branch__c == null){  
                newLead.Branch__c = loggedInUser.Logistic_Company__c;
            }
            //Populate Interio Subdivision with Logged in User Interio Subdivision, if not populated only for 'Interio' Business Unit
            if(newLead.Interio_Sub_Division__c == null && newLead.Business_Unit__c != null && newLead.Business_Unit__c == 'W'){
                newLead.Interio_Sub_Division__c = loggedInUser.Interio_Sub_Division__c;
            }
            //populate Area_Code__c with logged in User
            if(newLead.Area_Code__c == null){
                newLead.Area_Code__c = loggedInUser.Area_Code__c;
            }
            //populate Customer/Lead type to "Regular"
            //Modified to set Lead type as Regular when Lead source is Website or SEM for SMEPB-148
            if((String.isNotEmpty(newLead.Business_Unit__c) && newLead.Business_Unit__c == GlobalConstants.BUSINESS_UNIT_MHE_DIVISION) 
               && (newLead.Lead_Source__c == GlobalConstants.LEAD_SOURCE_INDIAMART || newLead.Lead_Source__c == GlobalConstants.LEAD_SOURCE_GODREJ_WEBSITE || newLead.Lead_Source__c == GlobalConstants.LEAD_SOURCE_SEM )){
                   newLead.Customer_Type__c = GlobalConstants.ATT_REGULAR;
               } 

            if((String.isNotEmpty(newLead.Business_Unit__c) && newLead.Business_Unit__c =='N')){
                if(Trigger.isBefore && Trigger.isInsert && newLead.Next_Reminder_Date__c == null && newLead.Construction_Time__c != null){
                    newLead.Next_Reminder_Date__c = Date.today().addDays((Integer)newLead.Construction_Time__c);   
                }
            }
        }
    }
    // Method to Populate Qualified/Unqualified date for Interio B2C for SIF-89(Added by Sreekanth Jujare on 05/12/2022)
    public void calculateQualifiedDate(List<Lead> newLeads,Map<Id, Lead> oldLeads){
        for(Lead ld : newLeads){
            if(ld.Business_Unit__c == GlobalConstants.INTERIO_BUSINESS_UNIT && ld.Sub_Division__c == GlobalConstants.B2C_SUBDIVISION && 
               ld.Status != oldLeads.get(ld.id).Status &&
               (ld.Status ==  GlobalConstants.QUALIFIED || ld.Status == GlobalConstants.UNQUALIFIED)){
                   ld.Qualified_unqualified_Date__c = System.now();
               }
        }
    } 
    
    
    
    /* Method to create B2C addresses. Fetches the account Ids that were converted
* via leads and creates address records from information available on lead only if the
* Lead was converted to a person account. The address record is later used to create an
* address relation
*/
    public void createB2CAddresses(Map<Id, Lead> newLeads) {
        try {
            Id b2cRecordTypeId = Schema.SObjectType.Address_by_BP__c.getRecordTypeInfosByDeveloperName()
                .get(B2CADDRESSRECORDTYPENAME).getRecordTypeId();
            List<Lead> convertedB2CLeads = new List<Lead>();
            Map<Id, Address__c> newAddressesMap = new Map<Id, Address__c>();
            List<Address_By_BP__c> newAddressByBPRecords = new List<Address_By_BP__c>();
            
            for (Lead each : newLeads.values()) {
                // skip iteration if it is not converted via lead or if its not a person account
                if (String.isBlank(each.Company) && String.isNotBlank(each.ConvertedAccountId)) {
                    convertedB2CLeads.add(each);
                }
            }
            for (Lead each : convertedB2CLeads) {
                // Create address using data from lead
                String LeadName = each.FirstName + ' ' + each.LastName;
                newAddressesMap.put(each.ConvertedAccountId, new Address__c(Street__c = each.Street__c,
                                                                            ZipCode__c = each.ZipCode__c,
                                                                            Telephone__c = each.MobilePhone,
                                                                            Building__c = each.Building__c,
                                                                            Floor__c = each.Floor__c,
                                                                            Email__c = each.Email,
                                                                            Street2__c = each.Street2__c,
                                                                            House_Number__c = each.House_Number__c,
                                                                            Address_Type__c  = GlobalConstants.ADDRESSTYPE_B2C,
                                                                            Name__c = (LeadName.length()>35 ? LeadName.substring(0, 34): LeadName),
                                                                            Name2__c = (LeadName.length()>35 ? ( LeadName.length()>64 ? LeadName.substring(34, 64) : LeadName.substring(34, LeadName.length())) : '')));
            }
            insert newAddressesMap.values();
            
            // Add that as primary address on the account and create Address relation records for it
            for (Id each : newAddressesMap.keySet()) {
                newAddressByBPRecords.add(new Address_by_BP__c(Account__c = each,
                                                               Address_Code__c = newAddressesMap.get(each).Id,
                                                               isPrimary__c = true,
                                                               Name__c =  newAddressesMap.get(each).Name__c,
                                                               Email__c =  newAddressesMap.get(each).Email__c,
                                                               Telephone__c  =  newAddressesMap.get(each).Telephone__c,
                                                               RecordTypeId = b2cRecordTypeId));
            }
            insert newAddressByBPRecords;
        } catch (Exception ex) {
            Logger.logError(LeadFieldPopulator.class.getName(), 'createB2CAddresses', null, ex);
        }
    }

/*
@author : Varun Rajpoot
@Date : 10.01.23  (dd/mm/yy)
@description : used to change the owner of lead to queue based on queue name
*/

    public void interioB2COnLeadQualification(Map<Id, Lead> newLeads,Map<Id,Lead> oldLeads){  
        try{
            User user = [Select Id, Profile.Name from User where Id =: userinfo.getUserId()];
            if(user.Profile.Name == GlobalConstants.interCallCenterProfile){
                Id queueId =  LeadFieldPopulator.getQueueId(GlobalConstants.LEAD_ASSIGNMENT_DEFAULT_QUEUE);
                for(Lead newLead : newLeads.values()){
                    if( (newLead.Status == GlobalConstants.QUALIFIED && oldLeads.get(newLead.id).Status!= GlobalConstants.QUALIFIED)
                    && newLead.Business_Unit__c== GlobalConstants.INTERIO_BUSINESS_UNIT
                    && (newLead.Interio_Sub_Division__c== GlobalConstants.INTERIO_KITCHEN || 
                        newLead.Interio_Sub_Division__c== GlobalConstants.INTERIO_VFD ) ){ 
                            newLead.OwnerId= queueId;
                        }
                }      
            }
        }catch (Exception ex) {
            Logger.logError(LeadFieldPopulator.class.getName(), 'changeOwnerAsQueue', null, ex);
            throw ex;
        }
    }
    
    public static Id getQueueId(String queueDeveloperName){
       return [SELECT Id FROM Group WHERE Type = 'Queue' and DeveloperName =: queueDeveloperName]?.Id;

    }

    /*------------------------------------------------------------------------
Author:        Shreela
Company:       Godrej Infotech
Description:   Method to send Email with Coupon Codes to Generated Interio Leads captured through online websites for SIEPB-70
Inputs:        list of created lead records
Test Class:   

History
15-02-2023      Shreela     Initial Release
----------------------------------------------------------------------------*/
        public void sendCouponCodeEmailToGeneratedLeads(Map<Id,Lead> leadRecords){
        try{
            If(!Runtime_Execution__c.getInstance().BulkUpdateOnLeadDisable__c){  //Added by Srini on 25th April 2023 to disable mass upload of leads
            Set<Id> leadIds = new Set<Id>();
            Integer couponCodeListSize; //To count real time coupon codes available 
            Integer ccVarForIndexing = 0; //Used for indexing purpose 
            List<Lead>  leadList  = new List<Lead>();  //For unique 1:1 mapping 
            Map<Id,Lead>  leadMapForUpdation  = new Map<Id,Lead>(); //For updating lead fields once email is sent
            Map<Id,Id> couponCodeLeadIdMap = new Map<Id,Id>(); //Contains Id of lead and Id of coupon code for mapping purpose
            DateTime todaysDate = dateTime.now();
            Map<Id,Coupon_Code__c> couponCodeMapUpdate = new Map<Id,Coupon_Code__c>(); //For updating coupon code fields once email is sent
            //Map<Id,Lead> ldExistingMap; //To check number of emails which has received emails with coupon code already
            //Commented above line by Shreela as email duplicacy is okay for Interio B2C Leads on 3rd Oct 2023 for hotfix
            Set<String> emailSet = new Set<String>(); //To fetch existing email ids which received coupon codes
            List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();
            
            //Fetching lightning email template
            EmailTemplate emailTemplate = new EmailTemplate();
            
            
            //To set OneGodrej as Sender
            List<OrgWideEmailAddress> lstOrgWideEmailId = [SELECT id,DisplayName,Address 
                                                           FROM OrgWideEmailAddress 
                                                           WHERE Address='onecrm@godrej.com'];
           
            for(Lead ld : leadRecords.values()){
                 if(ld.Business_Unit__c == GlobalConstants.INTERIO_BUSINESS_UNIT && ld.IsEmailSentOnceWithCouponCode__c == false && 
                   (ld.LeadSource == GlobalConstants.LEAD_SOURCE_FACEBOOK_INSTAGRAM || ld.LeadSource == GlobalConstants.LEAD_SOURCE_GODREJ_WEBSITE)&& ld.Email != null
                  ){
                      leadIds.add(ld.Id);
                  }
            }
            
            List<Lead> ldList  = [SELECT Id,Name,IsEmailSentOnceWithCouponCode__c,LeadSource,Business_Unit__c,Email
                                   FROM Lead
                                   WHERE Id IN :leadIds];  //Since need to update fields after sending email which cannot be done with trigger.new as it is read only
            
            /*ldExistingMap = new Map<Id,Lead>([SELECT Id,Name,Email
                                              FROM Lead
                                              WHERE Email!=Null AND Business_Unit__c =: GlobalConstants.INTERIO_BUSINESS_UNIT
                                              AND Coupon_Code__c!=Null AND IsEmailSentOnceWithCouponCode__c = true]);  //To check if there is any exisiting email address who has got coupon code in past.Need to top sending coupon code value to those leads with existing email address
            
            for(Lead ldExisting : ldExistingMap.values()){
                emailSet.add(ldExisting.Email); 
            } */ //Commented above line by Shreela as email duplicacy is okay for Interio B2C Leads on 3rd Oct 2023 for hotfix
            
            if(!leadIds.isEmpty()){
                emailTemplate =[SELECT Id,Subject,Description,DeveloperName,HtmlValue,Body 
                                FROM EmailTemplate
                                WHERE DeveloperName ='Lead_Coupon_Code_Email_1676374111969'
                               ]; 
            }
            
            if(!lstOrgWideEmailId.isEmpty() && !leadIds.isEmpty()){
                  List<Coupon_Code__c> couponCodeRecords = [SELECT Id,IsCheckCouponCodeSent__c,CouponCodeValue__c
                                                          FROM Coupon_Code__c
                                                          WHERE IsCheckCouponCodeSent__c=false //AND Start_Date__c <=: todaysDate AND End_Date__c>=: todaysDate //Commented by Shreela for hotfix on 3rd Oct 2023
                                                          Limit 5000]; //Added limit by Shreela on 3rd Oct 2023 - Hotfix

                
                List<String>ccEmailAddress = new List<String>();
                
                if(!couponCodeRecords.isEmpty()){
                    couponCodeListSize = couponCodeRecords.size();
                    for(Lead ld : leadRecords.values()){
                           if(leadIds.contains(ld.Id) && ld.Coupon_Code__c == Null){ //First cond checks whether it is for Interio Leads captured from 
                           //online platform and second cond is to check whether coupon code is already assigned to lead or not
                            /*if(!ldExistingMap.isEmpty() && emailSet.contains(ld.Email)){ //Not adding email is null or not check as it has been checked already
                              ld.Email.addError('Coupon code has already been disptached to this Email Id.Please provide another email address'); //If an email id of exisiitng lead has alreayd received coupon code,it should not allow to create another lead with the same email address if Coupon code in the system is available
                                	
                            }        
                            else if((!ldExistingMap.isEmpty()  && !emailSet.contains(ld.Email))|| ldExistingMap.isEmpty()){ //Not adding email is null or not check as it has been checked already*/
                               //Commented above line by Shreela as email duplicacy is okay for Interio B2C Leads on 3rd Oct 2023 for hotfix
                                  if(leadIds.contains(ld.Id) && couponCodeListSize>0 && (ld.Status == 'Unqualified' ||ld.Status == 'Qualified')){ //Adding couponCodeListSize for counting real time coupon code records.. added Unqualified condition by Srini on 24th April 2023
                                     String emailBody = emailTemplate.HtmlValue; 
                                    if(couponCodeRecords[ccVarForIndexing].Id != null){
                                          couponCodeLeadIdMap.put(ld.Id,couponCodeRecords[ccVarForIndexing].Id);
                                    }
                                    
                                    emailBody = emailBody.replace('{​​!couponCodeList}​​', couponCodeRecords[ccVarForIndexing].CouponCodeValue__c);
                                    Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                                    String subject = couponCodeRecords[ccVarForIndexing].CouponCodeValue__c+' Coupon Code for the Lead';
                                    
                                    List<string> setToAddresses=new List<string>();
                                    setToAddresses.add(ld.Email);
                                    message.setOrgWideEmailAddressId(lstOrgWideEmailId[0].id);   
                                    message.setToAddresses(setToAddresses);
                                    //message.setToAddresses(new String[]{'shreela@godrej.com','srica@godrej.com'});
                                    message.setUseSignature(false);
                                    message.setSubject(subject);
                                    message.setHTMLBody(emailBody);
                                    message.setTargetObjectId(ld.Id);
                                    emailsToSend.add(message); 
                                    
                                    leadList.add(ld);                           
                                    
                                    couponCodeListSize-=1; //Counter to check real time no of Coupon code available
                                    ccVarForIndexing+=1; //Counter to assign next available coupon code to newly created lead.Acts as index 
                                }
                            //} //Commented above line by Shreela as email duplicacy is okay for Interio B2C Leads on 3rd Oct 2023 for hotfix
                        }
                    }
                }
                
                Messaging.SendEmailResult [] result =  Messaging.sendEmail(emailsToSend);
                
                if(leadList.size() == couponCodeLeadIdMap.size()){  //for 1:1 unique lead and available coupon code mapping
                    for(Lead ld : ldList){
                        ld.IsEmailSentOnceWithCouponCode__c = true;
                        ld.Coupon_Code__c = couponCodeLeadIdMap.get(ld.Id);
                        for(Coupon_Code__c cc :couponCodeRecords){
                            if(cc.Id == ld.Coupon_Code__c){
                                cc.IsCheckCouponCodeSent__c = true;
                                couponCodeMapUpdate.put(cc.Id,cc); //Added by Shreela on 3rd Oct 2023 - Hotfix
                            }
                            //couponCodeMapUpdate.put(cc.Id,cc); //Commented by Shreela on 3rd Oct 2023 - Hotfix
                        }
                        leadMapForUpdation.put(ld.Id,ld);
                    }
                }
                for(Messaging.SendEmailResult rr: result){ //For email error handling part
                    for(Messaging.SendEmailError err : rr.getErrors()){
                        if(err.targetobjectid == leadMapForUpdation.get(err.targetobjectid).Id){
                            leadMapForUpdation.remove(err.targetobjectid);
                            Id ccId = couponCodeLeadIdMap.get(err.targetobjectid);
                            couponCodeMapUpdate.remove(ccId);
                        } 
                    }    
                }
                
                if(result.size()>0){ //Update boolean fields and Coupon code lookup in lead if email is sent successfully
                    update couponCodeMapUpdate.values();
                    update  leadMapForUpdation.values();
                }
                
            }
            
        }
        }
        catch(Exception ex){
            System.debug(ex.getStackTraceString());
        }
        
     }   
     /*------------------------------------------------------------------------
Author:        Shreela
Company:       Godrej Infotech
Description:   Method to validate email Id for Interio online captured leads for SIEPB 70
Inputs:        list of created lead records
Test Class:   

History
28-02-2023      Shreela     Initial Release
----------------------------------------------------------------------------*/   
   /* public static void validateEmail(List<Lead> leads) {
        for(Lead ld : leads){
            if(ld.Business_Unit__c == 'W' && (ld.LeadSource =='Facebook/ Instagram' || 
               ld.LeadSource =='Godrej Website') && ld.Email != null ){
                String emailRegex ='([a-zA-Z0-9_\\-\\.]+)@((\\[a-z]{1,3}\\.[a-z]{1,3}\\.[a-z]{1,3}\\.)|(([a-zA-Z0-9\\-]+\\.)+))([a-zA-Z]{2,4}|[0-9]{1,3})';
                Pattern MyPat = Pattern.compile(emailRegex);
                String emailAddress = String.valueOf(ld.Email);
                Matcher MyMatcher = MyPat.matcher(ld.Email);
                if(!MyMatcher.matches())
                   ld.addError('Please enter valid email adress');
            }
        }
    } */
    
            /*------------------------------------------------------------------------
Author:        Shreela Nair
Company:       Godrej Infotech
Description:   Class to populate Name
Inputs:        List of Leads
Test Class:   

History
17-04-2023      Shreela Nair   
----------------------------------------------------------------------------*/
    
    public void populateNameForPES(List<Lead> newLeads){
        for(Lead ld : newLeads){
            if(ld.Business_Unit__c == GlobalConstants.PES_BUSINESS_UNIT){
                if(ld.LastName==System.Label.PES_Name_Not_Available){
                    ld.LastName = ld.Title;
                }
                    else if(ld.LastName!=ld.Title && ld.LastName.containsNone(GlobalConstants.openingBracket) && ld.LastName.containsNone(GlobalConstants.closingBracket)){
                    ld.LastName = ld.LastName+' '+'('+ld.Title+')'; //Append Title against Last Name if Last name is not NA.
                }                    
           }
        }
        
    }
 
    /* 
    @Description: After create method to assign Interio B2C leads to owner as per new Owner. 
                 SIEPB-127: LDM PROCESSES REVAMP FOR COCO /FRANCHISEE/DELEAR /DISTRIBUTOR
    @Modifiled By : GITL Team
    @Date: 23/Jan/2024
    */

    public void interioB2COwnerAssignment(List<Lead> newLeads){
        Set<Id> leadIdSet = new Set<Id>();
        Id recordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get(GlobalConstants.LEAD_RECORDTYPE_Interio_B2C).getRecordTypeId();
        for(Lead lead:newLeads){
            if(lead.Business_Unit__c == GlobalConstants.INTERIO_BUSINESS_UNIT && lead.RecordTypeId ==recordTypeId && lead.Applicable_For_Pincode_Based_Assignment__c ){
                leadIdSet.add(lead.Id);
            }
        }

        if(!leadIdSet.isEmpty()){
            System.debug(leadIdSet);
            InterioB2CLeadAssignment.initLeadAssignment(leadIdSet);
        }
    }
    
    /* 
    @Description: Before update method to update Sync_With_SFMC__c field when lead owner is changed
				  from Default Queue To User for Interio B2C leads.
    @Modifiled By : jadhavr@godrej.com
    @Date: 25/Jan/2024
    */
    public void interioB2CUpdateSyncWithSFMCFieldOnOwnerChange(Map<Id, Lead> newLeads,Map<Id,Lead> oldLeads){  
    	Id queueId =  LeadFieldPopulator.getQueueId(GlobalConstants.LEAD_ASSIGNMENT_DEFAULT_QUEUE);
        List<Lead> leadRecordList=new List<Lead>();
        for(Lead newLead : newLeads.values()){
        	/*//Removed this condition. Once new LDM is in placed we will add this condition
            //  newLead.Status == GlobalConstants.NEW_CONSTANT &&
            &&
            oldLeads.get(newLead.id).OwnerId == queueId 
            */
            if(
               newLead.Business_Unit__c == GlobalConstants.INTERIO_BUSINESS_UNIT && newLead.Sub_Division__c == GlobalConstants.B2C_SUBDIVISION &&
               ( newLead.Interio_Sub_Division__c==GlobalConstants.INTERIO_VFD || newLead.Interio_Sub_Division__c==GlobalConstants.INTERIO_KITCHEN ) &&                
                String.valueOf(newLead.OwnerId).startsWith(GlobalConstants.USER_PREFIX)
                && newLead.SFMC__c == false
                ){ 
                newLead.SFMC__c=true;
            }
        }
    }   
    
    /* 
    @Description: Before insert method to update Store Location Fields field for Interio B2C leads.
    @Modifiled By : jadhavr@godrej.com
    @Date: 25/Jan/2024
    */
    public void interioB2CUpdateStoreLocationFields(List<Lead> newLeads,Map<Id,Lead> oldItems){ 
        List<Lead> leadRecordList=new List<Lead>();
        Set<Id> zipCodeRuleIdSet=new Set<Id>();        
        for(Lead newLead : newLeads){
            if(newLead.Business_Unit__c == GlobalConstants.INTERIO_BUSINESS_UNIT && newLead.Sub_Division__c == GlobalConstants.B2C_SUBDIVISION &&
               ( newLead.Interio_Sub_Division__c==GlobalConstants.INTERIO_VFD || newLead.Interio_Sub_Division__c==GlobalConstants.INTERIO_KITCHEN ) &&
                newLead.Zip_Code_Rule__c!=null && ( Trigger.isInsert || ( Trigger.IsUpdate && newLead.Zip_Code_Rule__c != oldItems.get(newLead.id).Zip_Code_Rule__c) )){                    
                    leadRecordList.add(newLead);
                    zipCodeRuleIdSet.add(newLead.Zip_Code_Rule__c);
                }
        }
        if(!zipCodeRuleIdSet.isEmpty()){
            Map<Id,Zip_Code_Rule__c> zipCodeRuleMap=new Map<Id,Zip_Code_Rule__c>([Select Id,Name,Account__c,Queue_1__c,Account__r.Primary_Address__r.Store_Address__c,Account__r.Primary_Address__r.Store_Location_URL__c,
                                          Account__r.Primary_Address__r.Telephone__c,Run_Round_Robin_on_Queue1__c from Zip_Code_Rule__c where Id IN :zipCodeRuleIdSet]);            
         
            if(!zipCodeRuleMap.isEmpty()){
                List<Lead> leadStoreWithManyLocation=new List<Lead>();
                Set<Id> accountIdSet=new Set<Id>(); 
                Set<String> queueDeveloperNameSet=new Set<String>();                
                for(Lead newLead : leadRecordList){
                    if(!zipCodeRuleMap.get(newLead.Zip_Code_Rule__c).Run_Round_Robin_on_Queue1__c){                        
                        newLead.Store_Address__c=zipCodeRuleMap.get(newLead.Zip_Code_Rule__c).Account__r.Primary_Address__r.Store_Address__c;
                        newLead.Store_Location_URL__c=zipCodeRuleMap.get(newLead.Zip_Code_Rule__c).Account__r.Primary_Address__r.Store_Location_URL__c;
                        newLead.Store_Contact_Number__c=zipCodeRuleMap.get(newLead.Zip_Code_Rule__c).Account__r.Primary_Address__r.Telephone__c;
                    }else if(zipCodeRuleMap.get(newLead.Zip_Code_Rule__c).Run_Round_Robin_on_Queue1__c){
                        if(zipCodeRuleMap.get(newLead.Zip_Code_Rule__c).Account__c!=null && String.isNotBlank(zipCodeRuleMap.get(newLead.Zip_Code_Rule__c).Queue_1__c)){
                            accountIdSet.add(zipCodeRuleMap.get(newLead.Zip_Code_Rule__c).Account__c);
                            queueDeveloperNameSet.add(zipCodeRuleMap.get(newLead.Zip_Code_Rule__c).Queue_1__c);
                            leadStoreWithManyLocation.add(newLead);
                        }                        
                    } 
                }             
                if(!accountIdSet.isEmpty() && !queueDeveloperNameSet.isEmpty()){
                    Map<String,Address__c> accountIdVsQueueDeveloperNameMap=new Map<String,Address__c>();
                    for(Address__c adr:[Select id,Account_Name__c,Queue_Name__c,Store_Address__c,Store_Location_URL__c,Telephone__c from Address__c where Account_Name__c IN :accountIdSet AND Queue_Name__c IN :queueDeveloperNameSet  ]){
                        accountIdVsQueueDeveloperNameMap.put(adr.Account_Name__c+'-'+adr.Queue_Name__c,adr);                        
                    }
                    system.debug(accountIdVsQueueDeveloperNameMap);
                    if(!accountIdVsQueueDeveloperNameMap.isEmpty()){
                       for(Lead leadRecord : leadStoreWithManyLocation){                     
                            if(accountIdVsQueueDeveloperNameMap.containsKey(zipCodeRuleMap.get(leadRecord.Zip_Code_Rule__c).Account__c+'-'+zipCodeRuleMap.get(leadRecord.Zip_Code_Rule__c).Queue_1__c)){
                                Address__c addressRecord=accountIdVsQueueDeveloperNameMap.get(zipCodeRuleMap.get(leadRecord.Zip_Code_Rule__c).Account__c+'-'+zipCodeRuleMap.get(leadRecord.Zip_Code_Rule__c).Queue_1__c);
                                leadRecord.Store_Address__c=addressRecord.Store_Address__c;
                                leadRecord.Store_Location_URL__c=addressRecord.Store_Location_URL__c;
                                leadRecord.Store_Contact_Number__c=addressRecord.Telephone__c;
                            }
                        } 
                    }                   
                }  
            }
        }  
    }
}