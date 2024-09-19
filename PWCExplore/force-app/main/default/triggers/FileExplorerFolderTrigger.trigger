trigger FileExplorerFolderTrigger on qsyd_FE__FileExplorerFolder__c (after insert) {
   
    Set<Id> userId = new Set<Id>();
    String[] sendingTo = new List<String>();
    id uid;
    Integer count1 = 0;
    List<qsyd_FE__FileExplorerFolder__c> fil = new list<qsyd_FE__FileExplorerFolder__c>();
    List<User> user1 = [select id,UserRole.parentroleid from user where id = :UserInfo.getUserId()];    
    for(User un:user1){
        List<User> user2 = [select UserroleId,email,name from User where UserRoleId =:un.UserRole.parentroleid ];
        for(User une:user2){
            sendingTo.add(une.email);
        }
    }
    
    List<Messaging.SingleEmailMessage> lstMails = new List<Messaging.SingleEmailMessage>();
    for(qsyd_FE__FileExplorerFolder__c obj:trigger.new){
        count1= count1+1;
        if(count1 == 1){
        List<qsyd_FE__FileExplorerFolder__c> filing = [Select id,LastModifiedDate,lastmodifiedbyid,lastmodifiedby.Name,lastmodifiedby.email from qsyd_FE__FileExplorerFolder__c where id=:obj.Id ];
        fil = filing;
        }
        userId.add(obj.CreatedById);
        Messaging.SingleEmailMessage semail = new Messaging.SingleEmailMessage();
        semail.setToAddresses(sendingTo);
        for(qsyd_FE__FileExplorerFolder__c filee : fil){
           String[] sendingTocAdd = new String[]{filee.lastmodifiedby.email}; 
           semail.setCcAddresses(sendingTocAdd); 
           semail.setSubject('File Explorer- file upload alert :'+filee.lastmodifiedby.Name+'.');
           String strTimeInAMorPM = filee.LastModifiedDate.format('MMMMM dd, yyyy hh:mm:ss a');
           Integer intIndex = strTimeInAMorPM.indexOf(',');
           strTimeInAMorPM = strTimeInAMorPM.substring(0,intIndex+6)+ ' at '+ strTimeInAMorPM.substring(intIndex+6,strTimeInAMorPM.length() );
           String filelabel = obj.qsyd_FE__Label__c;
           if (filelabel != null){
             Integer intIndex1 = filelabel.indexOf('(');
             filelabel = filelabel.substring(0, intIndex1 - 1 )+' Branch '+filelabel.substring(intIndex1,filelabel.length()-1)+' Folder)';
          }
            String messageBody = '<html><body>Dear Team,<br><br> '+'Please be informed that '+filee.lastmodifiedby.Name+'('+filee.lastmodifiedby.email+') has uploaded file on '+filelabel+' on '+strTimeInAMorPM+ ' <br><br>Regards<br>Salesforce CRM.</body></html>';        
            semail.setHtmlBody(messageBody);    
            lstMails.add(semail);
                   
        }
    }
    
    Messaging.sendEmail(lstMails);
    
}