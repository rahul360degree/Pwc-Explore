/*------------------------------------------------------------------------
Author:        Shreela Nair
Company:       Godrej Infotech
Description:   Utility class to perform DSA integration and other operations for OLAP approach
Inputs:        NA
Test Class:    OLAPDSAExtensionTest
History
----------------------------------------------------------------------------*/
public class OLAPDSAExtension { 
    public HttpResponse getAccountDetails(String accountdetails) {
        try {
            System.debug('Account Details inside OLAPDSAExtension: ' + accountdetails);
            DSAVisibilityRequestor requestorObject = new DSAVisibilityRequestor();
            HttpResponse response = requestorObject.generateRequest(accountdetails);

            if(response.getStatusCode() != 200) {
                throw new DSACheckerException(response.getBody());
            } else {
                return response;
            }
        } catch(DSACheckerException exceptionObj) {
            ResponseError responseError = (ResponseError) JSON.deserialize(exceptionObj.getMessage(), ResponseError.class);
            System.debug('Response Error msg: ' + responseError.error.message);
            System.debug('Error has occurred :: OLAPDSAExtension-getAccountDetails');
            System.debug(exceptionObj.getMessage());
            throw new DSACheckerException(responseError.error.source + responseError.error.message);
        }
    }

    /*------------------------------------------------------------------------
    Author:        Siddhesh Mayekar
    Company:       Godrej Infotech 
    Description:   Method to get account code of External User/Dealer after clicking Log in as user in Contacts by External User/Dealer.
    Inputs:        String uid
    Output Type:   String
    Test Class:    

    History
    ----------------------------------------------------------------------------*/    
    @AuraEnabled
    public static List<sobject> IsDealer(String uid){
        System.debug('Account Id in apex is'+uid);
        string UserID = '\'' + String.escapeSingleQuotes(uid) + '\'';  
        string query = 'select contact.account.account_code__c from user where id = '+ UserID +' AND contact.account.account_code__c != null';
        return Database.query('select contact.account.account_code__c from user where id = '+ UserID +' AND contact.account.account_code__c != null');
    }
    /*------------------------------------------------------------------------
    Author:        Siddhesh Mayekar
    Company:       Godrej Infotech 
    Description:   Method to retrive/display account code of External User/Dealer
    Inputs:        String accId, String accName
    Output Type:   String
    Test Class:    

    History
    ----------------------------------------------------------------------------*/       
    //  For retrieving Account Code
    @AuraEnabled(cacheable=true)  
    public static List<sobject> findAccountCode(String accId, String accName ) {  
       string accountsID = '\'' + String.escapeSingleQuotes(accId) + '\'';  
      string query = 'SELECT Account_Code__c FROM Account WHERE Id = '+accountsID+'';  
      return Database.query('SELECT Account_Code__c FROM Account WHERE Id = '+accountsID+''); 
    } 

    public class ResponseError {
        public Error error;
    }

    public class Error {
        public String message;
        public String source;
    }
}