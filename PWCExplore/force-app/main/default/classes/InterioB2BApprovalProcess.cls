/**
* @description       : 
* @author            : vrajpoot@godrej.com
* @group             : 
* @last modified on  : 18-10-2023
* @last modified by  : snehalw@godrej.com
**/
public with sharing class InterioB2BApprovalProcess {
    private static String quoteId;
/*------------------------------------------------------------------------
Author            : Varun Rajpoot
Description       : Method to get QuoteList 
Test Class        : InterioB2BApprovalProcessTest
----------------------------------------------------------------------------*/    
    @AuraEnabled
    public static List<Quote> quoteList(){
        try {        
            Set<Id> getpendingQuoteIds = getpendingQuoteIds();
            User user = getUserDetail();
            if(getpendingQuoteIds.isEmpty()){
                String errorMessage = System.Label.QLI_Not_Found;
                AuraHandledException error = new AuraHandledException(errorMessage);
                error.setMessage(errorMessage);
                throw error; 
            }
            
            List <Quote> quoteList = [Select Id, Name, QuoteNumber,
                                      AccountId, Account.Name,
                                      OpportunityId, Opportunity.Name, Opportunity_Type__c,Opportunity.OwnerId, Opportunity.Owner.Name,
                                      toLabel(Sales_Branch_Name__c), Zone__c, CreatedDate,
                                      Interio_Sub_Division__c, Approval_Status__c,
                                      SalesPrice__c, System_Basic__c, Quantity__c,
                                      Requested_COP_Factor__c,End_Customer_Segment__c,Pending_Since_Date__c,Transaction_Type__c,
                                      Transaction_Type_c__c,CreatedBy.Name,CreatedById,
                                      (Select Id,Current_Approver__c, List_of_Approvers__c from QuoteLineItems where Current_Approver__c !='' and List_of_Approvers__c !='')
                                      from Quote 
                                      where ID IN: getpendingQuoteIds];
            if(user.Persona__c == GlobalConstants.PERSONA_VP){
                List<Quote> filteredQuote = new List<Quote>();
                for(Quote quote: quoteList){
                    Boolean isApprovedByAll = true;
                    for(QuoteLineItem qli:quote.QuoteLineItems){
                        if(qli.Current_Approver__c != user.Id){
                            isApprovedByAll = false;
                            break;
                        }
                    }
                    if(isApprovedByAll){
                        filteredQuote.add(quote);
                    }
                }
                quoteList =  filteredQuote;
            }
            return quoteList;
            
            
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }
    /*------------------------------------------------------------------------
Author            : Varun Rajpoot
Description       : Method to get pending QuoteLineitems 
Test Class        : InterioB2BApprovalProcessTest
----------------------------------------------------------------------------*/  
    //record type id Quote 0122x000000QDhoAAG
    @AuraEnabled
    public static List<QuoteLineItem> getPendingQuoteLines(String quoteId,String additionalFields){
        try{
            Set<Id> queueIds = getQueList();
            User user = getUserDetail();
            Id userId =  user.Id;
            String whereClause = ' Where ';
            // if(!String.isEmpty(quoteId)){
            //     whereClause +=' AND QuoteId =:quoteId';
            // }
            if(String.isEmpty(quoteId)){
                if(user.Persona__c == GlobalConstants.PERSONA_SalesPerson || user.Persona__c == GlobalConstants.PERSONA_CST){
                    whereClause += ' Approval_Status__c =\''+GlobalConstants.STATUS_Resubmitted+'\' ';    
                }else{
                    whereClause += ' Approval_Status__c =\''+GlobalConstants.Submitted_for_Approval+'\' ';
                }
                if(user.Persona__c != GlobalConstants.PERSONA_CST){
                    whereClause += ' AND (Current_Approver__c=:userId';
                    whereClause += !queueIds.isEmpty() ?  ' or Current_Approver__c IN : queueIds) ':')';
                }
            }else{
                whereClause +=' QuoteId =:quoteId ';
            }
            
            String queryString  =' Select Id,QuoteId';
            queryString += String.isEmpty(additionalFields)?' ':','+additionalFields;
            queryString +=' from QuoteLineItem';
            queryString +=whereClause+' limit 20000';
            return Database.query(queryString);
        }catch(Exception ex){
            throw new AuraHandledException(ex.getMessage());
        }
    }
    /*------------------------------------------------------------------------
Author            : Varun Rajpoot
Description       : Method to get Queue List 
Test Class        : InterioB2BApprovalProcessTest
----------------------------------------------------------------------------*/  
    private static Set<Id> getQueList(){
        Set<Id> queueIds = new Set<Id> ();
        for(GroupMember gMember:[Select Id,GroupId from GroupMember where UserOrGroupId=:userInfo.getUserId() AND Group.Type = 'Queue']){
            queueIds.add(gMember.GroupId);
        }
        return queueIds;
    }
    
    private static Set<Id> getpendingQuoteIds(){
        List<QuoteLineItem> quoteLines= getPendingQuoteLines('','');
        Set<Id> quoteIds = new Set<Id>();
        if( !(quoteLines.isEmpty() )){
            for(QuoteLineItem qli:quoteLines){
                quoteIds.add(qli.quoteId);
            }
            return quoteIds;
        }else{
            //through exception
            String errorMessage = System.Label.QLI_Not_Found;
            AuraHandledException error = new AuraHandledException(errorMessage);
            error.setMessage(errorMessage);
            throw error; 
        }
    }
    /*------------------------------------------------------------------------
Author            : Varun Rajpoot
Description       : Method for Submit for approval
Test Class        : InterioB2BApprovalProcessTest
----------------------------------------------------------------------------*/  
    @AuraEnabled
    public static String submitForApproval(List<QuoteLineItem> qliRecords,String approvalStatus){
        Savepoint sp = Database.setSavepoint();
        try {
            GlobalConstants.SKIP_QUOTE_LOCK = true;            
            QliTriggerHandler.TriggerDisabled = true;
            if(approvalStatus == GlobalConstants.APPROVED_STATUS){
                helperApprovalNextStep(qliRecords);             
            }
            Boolean isChanged = getPriorCustomerDiscount(qliRecords[0].QuoteId, qliRecords);//Added by snehal w
            update qliRecords;
            system.debug('Qlirectest2'+ qliRecords);
            
            if(approvalStatus == GlobalConstants.APPROVED_STATUS || approvalStatus ==GlobalConstants.STATUS_Resubmitted || approvalStatus==GlobalConstants.Rejected || approvalStatus==GlobalConstants.DRAFT){
                updateQuote(qliRecords[0].Quote,approvalStatus);  
                if(approvalStatus!=GlobalConstants.DRAFT)
                {
                    system.debug('Qlirectest'+ qliRecords[0].Quote);
                    sendEmailNotificationToApproverAndSubmitter(qliRecords[0].QuoteId, isChanged);  
                }
                
            }else if(approvalStatus == GlobalConstants.Submitted_for_Approval){
                system.debug('qliRecordstest' + qliRecords[0].Quote);
                updateQuote(qliRecords[0].Quote,approvalStatus);//added to save the quote
                executeSubmitForApprovalAction(''+qliRecords[0].QuoteId,null,true); //added by snehal w 12/10/23
            }
            
            return 'success';
        } 
        
        catch (Exception e) {
            System.debug(e.getStackTraceString());
            Database.RollBack(sp);
            throw new AuraHandledException(e.getMessage());
        }
    }
  
    /**
* check is any quote  remaining for approval ?
*  If no=> Change status to approve
* else send to next approval
* 
*/
     /*------------------------------------------------------------------------
Author            : Varun Rajpoot
Description       : Method to check nect approver
Test Class        : InterioB2BApprovalProcessTest
----------------------------------------------------------------------------*/
    private static void helperApprovalNextStep(List<QuoteLineItem> quoteItemRecords){ 
        Map<String,String> userOrQueueNameMap=new Map<String,String>();
        Set<String>  userIdSet=new Set<String>();
        Set<String>  queueIdSet=new Set<String>();
        for(QuoteLineItem qli : quoteItemRecords){
            
            if(!String.IsBlank(qli.List_of_Approvers__c)){
                List<String> lstAllApprovers = (qli.List_of_Approvers__c).split(',');
                Integer requiredApprovalSize = lstAllApprovers.size();
                Integer nextApprovalIndex = lstAllApprovers.indexOf(qli.Current_Approver__c) + 1;
                if(nextApprovalIndex < requiredApprovalSize){
                    qli.Current_Approver__c = lstAllApprovers[nextApprovalIndex];
                    if(qli.Current_Approver__c.startsWith(GlobalConstants.USER_PREFIX)) {// Added by Snehal W
                        userIdSet.add(qli.Current_Approver__c);
                    }else{
                        queueIdSet.add(qli.Current_Approver__c);
                    }
                }else if(nextApprovalIndex == requiredApprovalSize){
                    qli.Current_Approver__c ='';
                    qli.Approval_Status__c = GlobalConstants.APPROVED_STATUS;
                    qli.Pending_With_Owner__c = '';//Added by pankaj
                }
            }
        }  
        //Added by Snehal W 24/07/2023
        if(!userIdSet.isEmpty() || !queueIdSet.isEmpty()){
            userOrQueueNameMap=getUserOrQueueName(userIdSet,queueIdSet); 
            for(QuoteLineItem qli : quoteItemRecords){
                if(userOrQueueNameMap.containsKey(qli.Current_Approver__c)){
                    qli.Pending_With_Owner__c=userOrQueueNameMap.get(qli.Current_Approver__c);
                }
            }
        }
    }
     /*------------------------------------------------------------------------
Author            : Varun Rajpoot
Description       : Method to update Quote
Test Class        : InterioB2BApprovalProcessTest
----------------------------------------------------------------------------*/
    private static void updateQuote(Quote quoteLWC,String approvalStatus){
        try{
            Quote quoteToUpdate = [Select Id,Pending_Since_Date__c,(Select Id from QuoteLineItems where Approval_Status__c !=:GlobalConstants.APPROVED_STATUS) from Quote where Id =:quoteLWC.Id ];
            String status = '';
            if(approvalStatus == GlobalConstants.APPROVED_STATUS){
                if((quoteToUpdate.QuoteLineItems).isEmpty()){
                    status = GlobalConstants.APPROVED_STATUS;
                }
            }else if(approvalStatus == GlobalConstants.STATUS_Resubmitted || approvalStatus == GlobalConstants.Rejected || approvalStatus == GlobalConstants.Submitted_for_Approval ){
                status = approvalStatus;
            }
            quoteToUpdate.Pending_Since_Date__c = System.now();
            quoteToUpdate.Total_List_Price__c = quoteLWC.Total_List_Price__c;
            quoteToUpdate.Req_Cust_Disc__c = quoteLWC.Req_Cust_Disc__c;
            quoteToUpdate.Total_Sales_Price__c = quoteLWC.Total_Sales_Price__c;
            quoteToUpdate.App_Cust_Disc__c = quoteLWC.App_Cust_Disc__c;
            quoteToUpdate.Total_Approved_Customer_Discount_Price__c = quoteLWC.Total_Approved_Customer_Discount_Price__c;
            quoteToUpdate.Req_WD_Retention_SAC_Amnt_Req_Disc_Bsc__c = quoteLWC.Req_WD_Retention_SAC_Amnt_Req_Disc_Bsc__c;
            quoteToUpdate.Req_WD_Retention_SAC_Amnt_Req_Cons_Bsc__c = quoteLWC.Req_WD_Retention_SAC_Amnt_Req_Cons_Bsc__c;
            quoteToUpdate.Appr_WD_Ret_SAC_Amt_appr_Disc_Bsc__c = quoteLWC.Appr_WD_Ret_SAC_Amt_appr_Disc_Bsc__c;
            quoteToUpdate.Appr_WD_Ret_SAC_Amt_on_cons_Bsc__c = quoteLWC.Appr_WD_Ret_SAC_Amt_on_cons_Bsc__c;
            quoteToUpdate.Req_WD_CONT_Amt_on_Req_Disc_bsc__c = quoteLWC.Req_WD_CONT_Amt_on_Req_Disc_bsc__c;
            quoteToUpdate.Req_WD_CONT_amt_on_cons_bsc__c = quoteLWC.Req_WD_CONT_amt_on_cons_bsc__c;
            quoteToUpdate.Appr_WD_CONT_Amt_On_Appr_Disc_Bsc__c = quoteLWC.Appr_WD_CONT_Amt_On_Appr_Disc_Bsc__c;
            quoteToUpdate.Appr_WD_CONT_Amt_On_Cons_Bsc__c = quoteLWC.Appr_WD_CONT_Amt_On_Cons_Bsc__c;
            quoteToUpdate.Req_Net_Rlizd_Basic_Rate_Cons__c = quoteLWC.Req_Net_Rlizd_Basic_Rate_Cons__c;
            quoteToUpdate.Appr_Net_Rlizd_Basic_Rate_Cons__c = quoteLWC.Appr_Net_Rlizd_Basic_Rate_Cons__c;
            quoteToUpdate.COP__c = quoteLWC.COP__c;
            quoteToUpdate.Requested_COP_Factor__c = quoteLWC.Requested_COP_Factor__c;
            quoteToUpdate.Approved_COP_Factor__c = quoteLWC.Approved_COP_Factor__c;
            quoteToUpdate.Req_WD_Ret_Disc_Basic__c = quoteLWC.Req_WD_Ret_Disc_Basic__c;
            quoteToUpdate.Req_WD_Ret_Cons_Basic__c = quoteLWC.Req_WD_Ret_Cons_Basic__c;
            quoteToUpdate.Appr_WD_Ret_Disc_Basic__c = quoteLWC.Appr_WD_Ret_Disc_Basic__c;
            quoteToUpdate.Appr_WD_Ret_Cons_Basic__c = quoteLWC.Appr_WD_Ret_Cons_Basic__c;
            quoteToUpdate.Req_WD_CONT__c = quoteLWC.Req_WD_CONT__c;
            quoteToUpdate.Req_WD_CONT_Cons_Basic__c = quoteLWC.Req_WD_CONT_Cons_Basic__c;
            quoteToUpdate.Appr_WD_CONT_Disc_Basic__c = quoteLWC.Appr_WD_CONT_Disc_Basic__c;
            quoteToUpdate.Appr_WD_CONT_Cons_Basic__c = quoteLWC.Appr_WD_CONT_Cons_Basic__c;
            quoteToUpdate.Req_Net_Rlizd_Disc_Cons_Basic__c = quoteLWC.Req_Net_Rlizd_Disc_Cons_Basic__c;
            quoteToUpdate.Appr_Net_Relzd_Bsc_Disc_On_Cons_Bsc__c = quoteLWC.Appr_Net_Relzd_Bsc_Disc_On_Cons_Bsc__c;
            quoteToUpdate.LOBSummaryTotal__c = quoteLWC.LOBSummaryTotal__c;            
            
            if(!String.isEmpty(status)){
                quoteToUpdate.Approval_Status__c = status;                
            }
            update quoteToUpdate;
        }
        catch(Exception ex){
            throw new AuraHandledException(ex.getMessage());
        }
        
    }
     /*------------------------------------------------------------------------
Author            : Varun Rajpoot
Description       : Future Method to execute submit for approval action
Test Class        : InterioB2BApprovalProcessTest
----------------------------------------------------------------------------*/
    @future
    public static void executeSubmitForApprovalAction(String quoteId,List<String> qliIds,Boolean isChanged){
        UpdateQliListOfApprovers.handleQuoteSubmit(quoteId,new List<String>());   
        // added by rohit to send email notification to Opportunity Owner ,Submitter and Current Approver. 
        sendEmailNotificationToApproverAndSubmitter(quoteId, isChanged);
    }
     /*------------------------------------------------------------------------
Author            : Varun Rajpoot
Description       : Method to create approval comments
Test Class        : InterioB2BApprovalProcessTest
----------------------------------------------------------------------------*/
    @AuraEnabled
    public static string createApprovalComments(List<Quote_Approval_History__c> approvalComments){
        try {
            insert approvalComments;
            return 'SUCCESS';
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
     /*------------------------------------------------------------------------
Author            : Varun Rajpoot
Description       : Method to get approval comments
Test Class        : InterioB2BApprovalProcessTest
----------------------------------------------------------------------------*/
    private static List<Quote_Approval_History__c> getApprovalComment(Id quoteId,boolean fetchArchived){
        try {
            List<Quote_Approval_History__c> approvalHistory = [
                Select Id, Approval_Comments__c, CreatedBy.Name, CreatedDate,Status__c,Quote__r.Opportunity_Owner__r.Name,Quote__r.Transaction_Type__c from Quote_Approval_History__c 
                where Quote__c =:quoteId and Archived__c =:fetchArchived
                Order by createdDate desc
            ];
            
            return approvalHistory.isEmpty()? new List<Quote_Approval_History__c>() : approvalHistory;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
     /*------------------------------------------------------------------------
Author            : Varun Rajpoot
Description       : Method to get user details
Test Class        : InterioB2BApprovalProcessTest
----------------------------------------------------------------------------*/
    private static User getUserDetail(){
        return [Select Id,Persona__c,Email from User where Id = :UserInfo.getUserId() limit 1];
    }
    /*------------------------------------------------------------------------
Author            : Varun Rajpoot
Description       : Wrapper class
----------------------------------------------------------------------------*/
    public class WrapperClass{
        @AuraEnabled public List<Quote_Approval_History__c> approvalComment;        
        @AuraEnabled public User user;
        @AuraEnabled public List<Id> queueIdList = new List<Id>();
    }
    
    @AuraEnabled
    public static WrapperClass wrapInfo(Id quoteId){
        try {
            Set<Id>  queueIdSet = getQueList();
            WrapperClass wrap = new WrapperClass();
            wrap.approvalComment = getApprovalComment(quoteId,false);
            wrap.user = getUserDetail();
            if(!queueIdSet.isEmpty()){
                wrap.queueIdList.addAll(queueIdSet);
            }
            return wrap;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
      /*------------------------------------------------------------------------
Author            : Pankaj Meshram
Description       : Method to get user name or queue name 
Test Class        : InterioB2BApprovalProcessTest
----------------------------------------------------------------------------*/
    private static Map<String,String> getUserOrQueueName( Set<String>  userIdSet,Set<String>  queueIdSet){
        Map<String,String> userOrQueueNameMap=new Map<String,String>();//Added by Snehal W
        if(!userIdSet.isEmpty()){
            for(User getUserName : [Select Id,Name,Persona__c from User where Id IN:userIdSet]){
                userOrQueueNameMap.put(getUserName.Id,getUserName.Name);             
            }
        }
        if(!queueIdSet.isEmpty()){
            for(Group getGrpName : [select Id,Name from Group where  Type = 'Queue' AND Id IN:queueIdSet]){
                userOrQueueNameMap.put(getGrpName.Id,getGrpName.Name);
            }
        }
        return userOrQueueNameMap;
    }
    
    /*------------------------------------------------------------------------
Author            : jadhavr@godrej.com
Description       : Method to send email notification when quote is submitted for approval or Approval Status changed.
Inputs            : quoteId. 
Test Class        : InterioB2BApprovalProcessTest
last modified on  : 01-04-2022
last modified by  : jadhavr@godrej.com
----------------------------------------------------------------------------*/
    private static void sendEmailNotificationToApproverAndSubmitter(String quoteId, Boolean isChanged)
    { 
        List<String> toAddresses =new List<String>();
        List<String> ccAddresses =new List<String>();
        List<User> userRecordList =new List<User>();
        Set<String> currentApproverIdSet=new Set<String>(); 
        String templateName;
        String templateName1;
        Boolean sendNotificationEmail=true;
        system.debug('ischangedValue:' + isChanged);
        List<QuoteLineItem> qliList=[Select Id,QuoteId,Quote.Name,Current_Approver__c,Quote.Approval_Status__c,Quote.Opportunity.OwnerId,
                                     Quote.Opportunity.Owner.Email,Quote.Opportunity.Owner.Name,Quote.Opportunity.Owner.Salary_Code__c,Quote.Transaction_Type__c,toLabel(Product_Line_c__c),
                                     Pending_With_Owner__c,List_of_Approvers__c from QuoteLineItem Where QuoteId =:quoteId];
        if(!qliList.isEmpty()){
            Set<String> productLineSet= new Set<String>(); // To Display Send All Line Items in Email Template Table.
            Set<String> currentApproverNameSet= new Set<String>(); // To Display Current Approver Names in Email Template Table.
            Set<String> approvedByHoNameSet= new Set<String>();
            Boolean isPendingWithAnyHO=false;           
            String vicePresidentName;
            
            User currentUserRecord=getUserDetail();
            
            for(QuoteLineItem qli:qliList){
                productLineSet.add(qli.Product_Line_c__c);               
                if(qli.Current_Approver__c!='' && qli.Current_Approver__c!=null)
                {
                    currentApproverNameSet.add(qli.Pending_With_Owner__c); 
                    if(currentUserRecord.Persona__c==GlobalConstants.Interio_HO_PERSONA){
                        if(!qli.Current_Approver__c.startsWith(GlobalConstants.USER_PREFIX)){
                            isPendingWithAnyHO=true;                    
                        }else{
                            vicePresidentName=qli.Pending_With_Owner__c;
                        } 
                    }                    
                } 
                
            }    
            ccAddresses=Label.Interio_B2B_Approval_Email_Notification_CCAddress.split(',');
            
            Set<String> previouslyApprovedEmails = getPreviouslyApprovedApproversEmails(quoteId);
            // If Condition for PART-A and Else is for PART-B
            if(qliList[0].Quote.Approval_Status__c==GlobalConstants.Submitted_for_Approval){                
                if(currentUserRecord.Persona__c==GlobalConstants.Interio_HO_PERSONA && isPendingWithAnyHO==true){
                    currentApproverNameSet.remove(vicePresidentName);
                    approvedByHoNameSet=getApprovedByHoNames(qliList);
                    toAddresses.add(qliList[0].Quote.Opportunity.Owner.Email);
                }
                else{
                    if(currentUserRecord.Persona__c==GlobalConstants.Interio_HO_PERSONA || currentUserRecord.Persona__c==GlobalConstants.Interio_VP_PERSONA){
                        approvedByHoNameSet.add('Approved By All HO'); 
                    }                        
                    currentApproverIdSet=getCurrentApproverUserIds(qliList);
                    if(!currentApproverIdSet.isEmpty()){
                        userRecordList=[Select Id,Email from User where Id IN :currentApproverIdSet];    
                        if(!userRecordList.isEmpty()){  
                            for(User userRecord:userRecordList){
                                toAddresses.add(userRecord.Email);
                            }
                        }
                    }
                    ccAddresses.add(qliList[0].Quote.Opportunity.Owner.Email);  
                    // Add previously approved approvers' email addresses to the CCAddresses list
                    ccAddresses.addAll(previouslyApprovedEmails);
                } 
                templateName=GlobalConstants.Interio_B2B_Submitted_For_Approval_Template; 
                if(isChanged){
                    templateName1=GlobalConstants.Interio_B2B_DOCUMENT_TRANSACTION_MODIFIED;
                }
            }else{
                toAddresses.add(qliList[0].Quote.Opportunity.Owner.Email);
                ccAddresses.addAll(previouslyApprovedEmails);
                templateName=GlobalConstants.Interio_B2B_Approval_Status_Change_Template;
                if(isChanged){
                    templateName1=GlobalConstants.Interio_B2B_DOCUMENT_TRANSACTION_MODIFIED;
                }
                if(qliList[0].Quote.Approval_Status__c ==GlobalConstants.STATUS_Resubmitted){
                    sendChatterNotification(qliList[0]);                     
                }
            }
            
            OrgWideEmailAddress owea =  [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress WHERE DisplayName=:GlobalConstants.One_CRM];
            
            List<EmailTemplate> templateList=[Select id,Name from EmailTemplate where Name =:templateName OR Name =:templateName1];         
            for(EmailTemplate template: templateList){
                if(template.Name == templateName || (template.Name == templateName1 && isChanged == true && (currentUserRecord.Persona__c != GlobalConstants.PERSONA_SalesPerson && currentUserRecord.Persona__c != GlobalConstants.PERSONA_CST) )){
                    sendEmailNotification(template.id,qliList[0],toAddresses,ccAddresses,productLineSet.toString() ,currentApproverNameSet.toString(),approvedByHoNameSet.toString(), owea); 
                }
            }
        }
    }
     /*------------------------------------------------------------------------
Author            : jadhavr@godrej.com
Description       : Method to send email notification 
Test Class        : InterioB2BApprovalProcessTest
----------------------------------------------------------------------------*/
    private static void sendEmailNotification(Id templateId,QuoteLineItem qliRecord,List<String> toAddresses,List<String> ccAddresses,String productLines,String currentApproverNames,String approvedByHoNames, OrgWideEmailAddress owea)
    {
        List<Messaging.SingleEmailMessage> mailList = new List<Messaging.SingleEmailMessage>(); 
        Messaging.SingleEmailMessage message = Messaging.renderStoredEmailTemplate(templateId, null, qliRecord.QuoteId);
        String htmlBody=message.gethtmlBody();
        productLines=productLines.replaceAll('[{}]','');  
        currentApproverNames=currentApproverNames.replaceAll('[{}]','');   
        approvedByHoNames=approvedByHoNames.replaceAll('[{}]','');  
        htmlBody=htmlBody.replace('LINE_OF_BUSINESS', productLines);       
        htmlBody=htmlBody.replace('CURRENT_APPROVER', currentApproverNames);
        htmlBody=htmlBody.replace('APPROVED_BY_HO', approvedByHoNames);
        htmlBody=(qliRecord.Quote.Opportunity.Owner.Salary_Code__c!=null) ? htmlBody.replace('SALARY_CODE', qliRecord.Quote.Opportunity.Owner.Salary_Code__c) : htmlBody.replace('SALARY_CODE', '');
        
        message.setSubject(message.getSubject());
        message.sethtmlBody(htmlBody);
        message.setOrgWideEmailAddressId(owea.id);
        message.setToAddresses(toAddresses);
        message.setCcAddresses(ccAddresses);
        mailList.add(message);    
        if(!mailList.isEmpty()) {                       
            Messaging.sendEmail(mailList);
        }
    }
       /*------------------------------------------------------------------------
Author            : Pankaj Meshram
Description       : Method to getCurrentApproverUserIds 
Test Class        : InterioB2BApprovalProcessTest
----------------------------------------------------------------------------*/      
    private static Set<String> getCurrentApproverUserIds(List<QuoteLineItem> qliList)
    {
        Set<String> currentApproverIdSet=new Set<String>();
        Set<String> queueIdSet=new Set<String>();
        for(QuoteLineItem qliRecord:qliList){
            if(qliRecord.Current_Approver__c!='' && qliRecord.Current_Approver__c!=null)
            {
                if(qliRecord.Current_Approver__c.startsWith(GlobalConstants.USER_PREFIX)) {
                    currentApproverIdSet.add(qliRecord.Current_Approver__c);
                }
                else{
                    queueIdSet.add(qliRecord.Current_Approver__c);
                }
            }
        }
        if(!queueIdSet.isEmpty()){
            List<GroupMember> grpMemberList=[Select Id,GroupId,UserOrGroupId from GroupMember where GroupId IN:queueIdSet];
            if(!grpMemberList.isEmpty()){
                for(GroupMember grpMember: grpMemberList){
                    String userId=grpMember.UserOrGroupId;
                    if(userId.startsWith(GlobalConstants.USER_PREFIX)){
                        currentApproverIdSet.add(grpMember.UserOrGroupId);
                    }                    
                }
            }
        }
        return currentApproverIdSet;
    }
    /*------------------------------------------------------------------------
Author            : jadhavr@godrej.com
Description       : Method to get Approved by HO Names 
Test Class        : InterioB2BApprovalProcessTest
----------------------------------------------------------------------------*/
    private static Set<String> getApprovedByHoNames(List<QuoteLineItem> qliList)
    {
        Set<String> queueIdSet=new Set<String>();
        Set<String> approvedByHoNameSet=new Set<String>();
        for(QuoteLineItem qliRecord:qliList)
        { 
            If(qliRecord.Current_Approver__c!='' && qliRecord.Current_Approver__c!=null && qliRecord.Current_Approver__c.startsWith(GlobalConstants.USER_PREFIX) ){
                List<String> lstAllApprovers = (qliRecord.List_of_Approvers__c).split(',');
                Integer previousApprovalIndex = lstAllApprovers.indexOf(qliRecord.Current_Approver__c) - 1;
                if(!lstAllApprovers[previousApprovalIndex].startsWith(GlobalConstants.USER_PREFIX)){
                    queueIdSet.add(lstAllApprovers[previousApprovalIndex]);// Added by Snehal W
                }
            }
        }
        if(!queueIdSet.isEmpty()){//Added by Snehal W 
            for (Group getGrpName : [SELECT Id, Name FROM Group WHERE Type = 'Queue' AND Id IN :queueIdSet]) {
                approvedByHoNameSet.add(getGrpName.Name);
            }
        }
        return approvedByHoNameSet;
    }
     /*------------------------------------------------------------------------
Author            : snehalw@godrej.com
Description       : Method to get previously approvedApproversEmails
Test Class        : InterioB2BApprovalProcessTest
last modified on  : 11-10-2023
last modified by  : snehalw@godrej.com
----------------------------------------------------------------------------*/
    public static Set<String> getPreviouslyApprovedApproversEmails(String quoteId) {
        Set<String> previouslyApprovedEmails = new Set<String>();
        
        List<Quote_Approval_History__c> approvalHistory = [SELECT Id, Name, Status__c, CreatedBy.Email
                                                           FROM Quote_Approval_History__c WHERE Quote__c = :quoteId
                                                           AND Status__c = :GlobalConstants.APPROVED_STATUS];
        
        for (Quote_Approval_History__c history : approvalHistory) {
            if (history.CreatedBy != null && history.CreatedBy.Email != null) {
                previouslyApprovedEmails.add(history.CreatedBy.Email);
            }
        }
        return previouslyApprovedEmails;
    }
    /*------------------------------------------------------------------------
Author            : jadhavr@godrej.com
Description       : Method to send chatter notification 
Test Class        : InterioB2BApprovalProcessTest
----------------------------------------------------------------------------*/
    private static void sendChatterNotification(QuoteLineItem qliRecord)
    {
        FeedItem post = new FeedItem();
        post.ParentId = qliRecord.Quote.Opportunity.OwnerId;
        String chatterBody;
        chatterBody= userInfo.getName() +' has resubmmited the quote. \n';
        chatterBody+='Quote Name : '+ qliRecord.Quote.Name +'\n'+'Opportunity Owner Name : ' + qliRecord.Quote.Opportunity.Owner.Name+'\n\n';
        chatterBody+=URL.getOrgDomainUrl().toExternalForm()+'/lightning/r/Quote/'+qliRecord.QuoteId+'/view';  
        post.Body =chatterBody;
        insert post; 
    }
        /*------------------------------------------------------------------------
Author            : snehalw@godrej.com
Description       : Method to get prior customer discount
Test Class        : InterioB2BApprovalProcessTest
last modified on  : 16-10-2023
last modified by  : snehalw@godrej.com
----------------------------------------------------------------------------*/
    public static Boolean getPriorCustomerDiscount(String quoteId, List<QuoteLineItem> newQLIRecords) {
        Map<Id, QuoteLineItem> existingQLIRecordsMap = new Map<Id, QuoteLineItem>();
        List<QuoteLineItem> existingQLIRecords = [SELECT Id, Approved_Customer_Discount__c, Approved_WD_Retention_On_ReqDiscbasic__c, Approved_WD_CONT__c
                                                  FROM QuoteLineItem WHERE QuoteId = :quoteId];
        for (QuoteLineItem qli : existingQLIRecords) {
            existingQLIRecordsMap.put(qli.Id, qli);
        }
        
        // Iterate through the new QLI records
        for (QuoteLineItem newQLI : newQLIRecords) {
            QuoteLineItem existingQLI = existingQLIRecordsMap.get(newQLI.Id);
            if (existingQLI != null) {
                // Compare the fields to check for changes
                if (newQLI.Approved_Customer_Discount__c != existingQLI.Approved_Customer_Discount__c
                    || newQLI.Approved_WD_Retention_On_ReqDiscbasic__c != existingQLI.Approved_WD_Retention_On_ReqDiscbasic__c
                    || newQLI.Approved_WD_CONT__c != existingQLI.Approved_WD_CONT__c) {
                        return true;
                    }
            }
        }
        return false; // Return false if none of the fields have changed
    }
}