/*------------------------------------------------------------------------
Author:        HansRaj Yadav
Company:       PWC
Description:   Controller class for Caller page redirection cmp
Inputs:        CaseId
Test Class:    

Modification Log :

* Developer             Date               Description
---------------------------------------------------------------------------
* HansRaj Yadav         12-04-2024        Initial Release
* 
----------------------------------------------------------------------------*/

public with sharing class SearchCallerController {
    
    @AuraEnabled
    public static ResultWrap searchCallerNumber( String callerNumber , String leadId, String agentId){
        System.debug('caller');
        ResultWrap result = new ResultWrap();

        User usr = [SELECT Id, Lead_Id__c FROM User WHERE Id =: agentId];
        usr.Lead_Id__c = leadId;     
        update usr;

        //Bussiness Account B2B
        List<Contact> b2bContactLst = [ SELECT Id, LastName, AccountId FROM Contact WHERE (Phone=:callerNumber OR MobilePhone =:callerNumber) AND IsPersonAccount = false];
        

        //PersonAccounts B2C
        List<Account>  b2cCustomerLst = [  SELECT Id, PersonMobilePhone, Mobile_Number__c, Mobile_Number_of_ASP_Supervisor__c, 
                                            Primary_Contact_Mobile__c, Whatsapp_Mobile_Number__c, IsPersonAccount
                                        FROM Account 
                                        WHERE  PersonMobilePhone =:callerNumber 
                                    ];

        //Can be alternate number
        List<ContactPointPhone> b2cContactPoint = [ SELECT Id, ParentId FROM ContactPointPhone WHERE TelephoneNumber =:callerNumber ];

        System.debug('b2bContactLst - ' + b2bContactLst + ' b2cCustomerLst --  ' + b2cCustomerLst + 'b2cContactPoint - ' + b2cContactPoint);

        if( b2bContactLst.size() > 0 && (b2cCustomerLst.size() > 0 || b2cContactPoint.size() > 0) ){
            
            //Global Search
            result.isUnique = false;
            result.isMultiple = true;
            return result;
        
        } else if( b2bContactLst.size() > 0){
            
            if( b2bContactLst.size() == 1 ){
                result.acctId = b2bContactLst[0].AccountId;
                result.isUnique = true;

            }else{
                //Multiple contact exits
                //redirect to global search
                result.isUnique = false;
                result.isMultiple = true;
                return result;
                
            }

        } else if( b2cCustomerLst.size() > 0 && b2cCustomerLst.size() ==1 ){
            result.acctId = b2cCustomerLst[0].Id;
            result.isUnique = true;
            result.isMultiple = false;
            return result;

        } else if( b2cContactPoint.size() > 0 && b2cContactPoint.size() == 1 ){
            result.acctId = b2cContactPoint[0].ParentId;
            result.isUnique = true;
            result.isMultiple = false;
            return result;
        
        } else{
            result.isMultiple = true;
            result.isUnique = false;
            return result;
        }

        


        Genesys_CTI__e newsEvent = new Genesys_CTI__e(
            Message__c='Hi msg is here'
        //    Urgent__c=true,
        //    News_Content__c='Lake Road is closed due to mudslides.'
        );
        // Call method to publish events
        Database.SaveResult sr = EventBus.publish(newsEvent);
        // Inspect publishing result
        if (sr.isSuccess()) {
            System.debug('Successfully published event.');
        } else {
            for(Database.Error err : sr.getErrors()) {
                System.debug('Error returned: ' +
                            err.getStatusCode() +
                            ' - ' +
                            err.getMessage());
            }
        }




    
        return result;
    }


    public Class ResultWrap {
        @AuraEnabled
        public Boolean isUnique;
        @AuraEnabled
        public String acctId;
        @AuraEnabled
        public Boolean isMultiple;
        
    }
}