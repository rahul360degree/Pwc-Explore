/*------------------------------------------------------------------------
Author:        Vikrant Mahantare
Description:   Trigger to handle database events on 'qsyd_FE__FileExplorerFile__c' records

----------------------------------------------------------------------------*/

public with sharing class FileExplorerEmailTrigger {
    Public void Emailtriggersemail(map<Id, sObject> newItems){
        Set<Id> userId = new Set<Id>();
        String[] sendingTo = new List<String>();
        id uid;
        List<qsyd_FE__FileExplorerFile__c> fil = new list<qsyd_FE__FileExplorerFile__c>();
        // Added the criteria to check the user's division/BU and subdivision , to have the emails sent iff it is an interio B2B user 
        List<User> Lstuser = [select id,UserRole.parentroleid from user where id = :UserInfo.getUserId() and Business_unit__c =:GlobalConstants.INTERIO_BUSINESS_UNIT and sub_division__c  =: GlobalConstants.B2B_INTERIO_SUBDIVISION];    

        if (!Lstuser.isEmpty()){
            for(User FilKamUser:Lstuser){
                List<User> LstParUser = [select UserroleId,email,name from User where UserRoleId =:FilKamUser.UserRole.parentroleid ];
                for(User ParUser:LstParUser){
                    sendingTo.add(ParUser.email);
                }
            }

            for(qsyd_FE__FileExplorerFile__c obj1:(List<qsyd_FE__FileExplorerFile__c>)newItems.values()){
                uid = obj1.id;
            }
            qsyd_FE__FileExplorerFile__c filerel = [Select id,qsyd_FE__LinkedEntityId__c,LastModifiedDate,lastmodifiedbyid,qsyd_FE__Label__c,qsyd_FE__Folder__r.qsyd_FE__Label__c,lastmodifiedby.Name,lastmodifiedby.email,CreatedById from qsyd_FE__FileExplorerFile__c where id=:uId ];
            Account fileacc = [Select id,Name from Account where Id = :filerel.qsyd_FE__LinkedEntityId__c];
            List<Messaging.SingleEmailMessage> lstMails = new List<Messaging.SingleEmailMessage>();
            for(qsyd_FE__FileExplorerFile__c obj:(List<qsyd_FE__FileExplorerFile__c>)newItems.values()){
                userId.add(obj.CreatedById);
                Messaging.SingleEmailMessage semail = new Messaging.SingleEmailMessage();
                semail.setToAddresses(sendingTo);               
                String[] sendingTocAdd = new String[]{filerel.lastmodifiedby.email}; 
                semail.setCcAddresses(sendingTocAdd); 
                semail.setSubject(GlobalConstants.EMAIL_SUB + filerel.lastmodifiedby.Name+GlobalConstants.Full_stop);
                String strTimeInAMorPM = filerel.LastModifiedDate.format(GlobalConstants.Email_Interio_date_format);
                Integer intIndex = strTimeInAMorPM.indexOf(GlobalConstants.Commas);
                strTimeInAMorPM = strTimeInAMorPM.substring(0,intIndex+6)+ GlobalConstants.ATstr+ strTimeInAMorPM.substring(intIndex+6,strTimeInAMorPM.length() );
                String filelabel = filerel.qsyd_FE__Label__c;
                String Open_bracket = GlobalConstants.Bracket_open;
                String close_bracket  = GlobalConstants.Bracket_close;
                String messageBody = system.label.Email_Body_For_File_explorer_class +
                    filerel.lastmodifiedby.Name+ Open_bracket +filerel.lastmodifiedby.email+close_bracket+ 
                    system.label.Email_Body_For_class_FileExplorerEmailTrigger_1 +
                    Open_bracket+ filelabel+close_bracket+ GlobalConstants.onn +
                    strTimeInAMorPM+ GlobalConstants.onn + GlobalConstants.kamAccount+Open_bracket+
                    fileacc.Name+close_bracket+ GlobalConstants.Full_stop + system.label.Email_Body_For_class_FileExplorerEmailTrigger_3;        
                semail.setHtmlBody(messageBody);    
                lstMails.add(semail);                
            } 
            Messaging.sendEmail(lstMails);             
        }
    }
}