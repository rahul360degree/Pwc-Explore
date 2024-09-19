global class LeadAssignmentAppliancesBatch implements Database.Batchable<sObject>,Database.Stateful, Schedulable{
    Set<Id> userIdSet;
    Set<Id> zipCodeRuleIdSet;
    Boolean recursionflag;
    
    public LeadAssignmentAppliancesBatch(){
        userIdSet=new Set<Id>();
        zipCodeRuleIdSet=new Set<Id>();
        recursionflag=false;
    }
    
    /*  Constructor is called from finish method to re-iterate the batch only once for the specified set of users
        which have less than 100 leads assigned in first iteration of batch execution.
        Passing 3 parameters to constructor.-->
        1. Set of userId's for which we have to re-iterate the batch.
        2. Boolean Flag to re-iterate batch only once.
        3. Set of ZipCodeRules which is not part of any lead record having Status='New'.
        */
    public LeadAssignmentAppliancesBatch(Set<Id> inputUserIdSet, Boolean inputRecursionFlag , Set<Id> inputZipCodeRuleIdSet){
        this.userIdSet = inputUserIdSet ;
        this.zipCodeRuleIdSet=inputZipCodeRuleIdSet;
        this.recursionflag = inputRecursionFlag;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        String businessUnit=GlobalConstants.APPLIANCE_BUSINESS_UNIT;
        String businessLine=GlobalConstants.D2D_CHANNEL;
        String persona='Appliances- Self Calling Executive';
        String query='SELECT Id, IsActive,Business_Unit__c,Business_Line__c,Persona__c FROM User ';
        if(recursionflag==false)
        {
            query += 'where IsActive=true and Business_Unit__c = :businessUnit and Business_Line__c=:businessLine and Persona__c=:persona'; 
        }
        else
        {
            query += 'where Id IN:userIdSet';   
        }
        return Database.getQueryLocator(query);
        
    }
    
    global void execute(Database.BatchableContext BC,list<User> userList ){ 
       Id userId = userList[0].Id;
        integer leadCount = 0;
        integer noOfLeadsToAssign = 300;
        integer leadLimit=1;
        system.debug('userId-->'+userId);
        
        // Query to fetch Lead Assignment Default Queue Id.
        Group defaultQueueGroup=[Select Id from Group where Type='Queue' and DeveloperName=:GlobalConstants.LEAD_ASSIGNMENT_DEFAULT_QUEUE limit : 1];
        
        String defaultQueue = defaultQueueGroup.Id;
        
        // Aggregate Query to Count Lead Records owned by user having status as New.
        List<AggregateResult> aggregateResult = [Select Count(Id) leadCount from Lead Where OwnerId =:userId AND Status =:GlobalConstants.NEW_CONSTANT ];
        
        if(!aggregateResult.isEmpty())
        {
            leadCount= (Integer)aggregateResult[0].get('leadCount');
        } 
        
        system.debug('leadCount-->'+leadCount);
        if(leadCount < noOfLeadsToAssign)
        {
             // Query to fetch List of Group Names for which user as group member.
            List<GroupMember> groupMember = [SELECT Id, Group.Name, Group.Type, UserOrGroupId, SystemModstamp
                                             FROM GroupMember 
                                             where UserOrGroupId =:userId];
            if(!groupMember.isEmpty())
            {
                Set<String> groupNameSet = new Set<String>();
                for(GroupMember grpMember:groupMember){
                    groupNameSet.add(grpMember.Group.Name);
                }
                
                List<Zip_Code_Rule__c> rulelist=new List<Zip_Code_Rule__c>();
                
                // Query to fetch List of Zip Code Rules which contains Queue Name as Group Name ( feched on line no 66.  ) and Run_Round_Robin_on_Queue is true.
                rulelist = [Select Id,name,Sequence__c,Queues_And_LastAssignedId__c FROM Zip_Code_Rule__c where 
                            ((Queue_7__c IN: groupNameSet AND Run_Round_Robin_on_Queue7__c = true) OR
                             (Queue_6__c IN: groupNameSet AND Run_Round_Robin_on_Queue6__c = true) OR
                             (Queue_5__c IN: groupNameSet AND Run_Round_Robin_on_Queue5__c = true) OR
                             (Queue_4__c IN: groupNameSet AND Run_Round_Robin_on_Queue4__c = true) OR
                             (Queue_3__c IN: groupNameSet AND Run_Round_Robin_on_Queue3__c = true) OR
                             (Queue_2__c IN: groupNameSet AND Run_Round_Robin_on_Queue2__c = true) OR
                             (Queue_1__c IN: groupNameSet AND Run_Round_Robin_on_Queue1__c = true)) and 
                            (NOT (Id IN : zipCodeRuleIdSet))]; 
                System.debug('rulelist.size()-->'+rulelist.size());
                
                if(!rulelist.isEmpty())
                {
                    leadLimit=Integer.valueOf(Math.Round((noOfLeadsToAssign - leadCount)/rulelist.size()));
                    if(leadLimit==0)
                    {
                        leadLimit=1;
                    }
                    List<Lead> leadListToUpdate = new List<Lead>();
                    for(Zip_Code_Rule__c zipRule:rulelist){
                        // Query to fetch List of Leads for each zip code rule having Status = New and Owner is Default Queue.
                        List<Lead> leads = [Select Id from Lead 
                                            Where OwnerId =:defaultQueue
                                            and Status =:GlobalConstants.NEW_CONSTANT
                                            AND Zip_Code_Rule__c =: zipRule.Id limit :leadLimit
                                           ];
                        if (Schema.sObjectType.lead.fields.ownerId.isUpdateable()){
                        if(!leads.isEmpty())
                        {   
                            for(lead leadRecord:leads){
                                leadRecord.ownerId = userId;
                                leadListToUpdate.add(leadRecord);
                                leadCount++;
                                if(leadCount>=noOfLeadsToAssign){ break;}
                            }
                        }
                            if(leadCount>=noOfLeadsToAssign){break;}
                        }
                        else
                        {
                            zipCodeRuleIdSet.add(zipRule.Id);
                        }
                    }
                    if(leadCount<100)
                    {
                        userIdSet.add(userId);
                    }
                    
                    if(!leadListToUpdate.isEmpty())
                    {
                        system.debug('leadListToUpdate.Size()-->'+leadListToUpdate.Size());
                        List<Database.SaveResult> updateResult = Database.update(leadListToUpdate, false);
                        
                        {
                            for (Database.SaveResult sr : updateResult) 
                            {
                                if (!sr.isSuccess()) {  
                                    string errorMessage = 'Lead Record Id -->'+sr.getId()+'\n';
                                    for(Database.Error err : sr.getErrors()){errorMessage += err.getMessage();}
                                    Logger.logError('AppliancesLeadAssignmentV2', 'AppliancesLeadAssignmentV2.execute()', errorMessage);
                                }
                            }                   
                        }
                    }
                    
                }
            }
        }
    }
    
    global void finish(Database.BatchableContext BC){
         if(!userIdSet.isEmpty() && recursionFlag==false)
        {
            LeadAssignmentAppliancesBatch batchInstance = new LeadAssignmentAppliancesBatch(userIdSet,true,zipCodeRuleIdSet); 
            database.executebatch(batchInstance,1);
        }
       else
        {
            Set<String> userIdSetToSendEmail=new Set<String>();
            
            List<User> userList=[SELECT Id, IsActive,Business_Unit__c,Business_Line__c,Persona__c FROM User where 
                                 IsActive=true and Business_Unit__c =:GlobalConstants.APPLIANCE_BUSINESS_UNIT and Business_Line__c=:GlobalConstants.D2D_CHANNEL and Persona__c='Appliances- Self Calling Executive'];
            
            for(User usr:userList)
            {
                userIdSetToSendEmail.add(usr.Id);
            }
            
            messaging.singleEmailMessage mail = new messaging.singleEmailMessage();
            mail.ToAddresses=Label.LeadAssignmentBatchToEmailAddress.split(',');
            mail.setSubject('Lead Assignment');
            String htmlBody;
            String newOwnerName='';
            String oldOwnerName='';
            
            Integer zipCodeTotal=0;
            Integer leadCountTotal=0;
            
            htmlBody = '<table border="1"><tr><th style="padding:5px;text-align: center;">Owner Name</th><th style="padding:5px;text-align: center;">Zip Code</th><th style="padding:5px;text-align: center;">Lead Count</th></tr>';
            for(AggregateResult ar : [Select Count(Id) leadCount,Owner.Name ownerName,ZipCode__r.Name zipCodeName from Lead Where 
                                      OwnerId IN :userIdSetToSendEmail AND Status = 'New' group by owner.name,ZipCode__r.Name order by Owner.Name])
            {
                newOwnerName=(String)ar.get('ownerName');
                if(newOwnerName!=oldOwnerName)
                {
                    if(oldOwnerName!='')
                    {
                        htmlBody += '<tr><td style="padding:5px;text-align: center;">Grand Total</td><td style="padding:5px;text-align: center;">' + zipCodeTotal + '</td><td style="padding:5px;text-align: center;">' + leadCountTotal + '</td><tr>';  
                        zipCodeTotal=0; leadCountTotal=0;
                    }
                    htmlBody += '<tr><td style="padding:5px;text-align: center;"style="padding:5px;" >' + newOwnerName;
                }
                else
                {
                    htmlBody += '<tr><td style="padding:5px;text-align: center;">' + ' ';
                }
                zipCodeTotal++;
                leadCountTotal=leadCountTotal+(Integer)ar.get('leadCount');
                oldOwnerName=newOwnerName;
                htmlBody += '</td><td style="padding:5px;text-align: center;">' + ar.get('zipCodeName') + '</td><td style="padding:5px;text-align: center;">' + ar.get('leadCount') + '</td><tr>'; 
            }
            htmlBody += '<tr><td style="padding:5px;text-align: center;">Grand Total</td><td style="padding:5px;text-align: center;">' + zipCodeTotal + '</td><td style="padding:5px;text-align: center;">' + leadCountTotal + '</td><tr></table>';
            
            mail.setHtmlBody(htmlBody);
            List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
            mails.add(mail);
            Messaging.sendEmail(mails);
        }
    }
    
     global void execute(SchedulableContext sc) {
        LeadAssignmentAppliancesBatch batch = new LeadAssignmentAppliancesBatch(); 
       if(!Test.isRunningTest()){
            database.executebatch(batch,1);
        }
       else
       {
           database.executebatch(batch);
       }
   }
}