/**
 * @Description       : Called from appliancesEzetapPayment for EzeTap online advance payment
 * @Author            : Varun Rajpoot
 * @last modified on  : 12-21-2023
 * @last modified by  : Varun Rajpoot
 * Modifications Log
 * Ver   Date         Author          Modification
 * 1.0   11-21-2023   Varun Rajpoot   Initial Version
**/
public with sharing class AppliancesAdvancedPayment implements Queueable,Database.AllowsCallouts{
    
    /* Functionality to chaeck payment status in backend after some given time.*/
    String calloutType, refNumber, jsonPart;    
    AppliancesAdvancedPayment(String calloutType,String refNumber,String jsonPart){
        this.calloutType = calloutType;
        this.refNumber = refNumber;
        this.jsonPart = jsonPart;
    }
    
    //Queueable method to update the status
    public void execute(QueueableContext context) {
        try{
            String json = EzetapController.initiatePayment(calloutType,refNumber,jsonPart) ;
    
            EzeTapResponseParser parseResult = EzeTapResponseParser.parse(json);//parse the response
            
            Advance_Payment_Details__c adv = [Select Id from Advance_Payment_Details__c 
                                                Where Reference_Number__c =:refNumber
                                            ];
            adv.Payment_Error_Message__c = String.isNotEmpty(parseResult.errorMessage) ? parseResult.errorMessage : '';
            adv.Payment_Error_Code__c = String.isNotEmpty(parseResult.errorCode) ? parseResult.errorCode : '' ;
            adv.Payment_Message__c = String.isNotEmpty(parseResult.message) ? parseResult.message: '' ;
            
            if(String.isNotEmpty(parseResult.customerReceiptUrl)){
                adv.Payment_Receipt_Url__c = parseResult.customerReceiptUrl;
            }
            if(String.isNotEmpty(parseResult.txnId)){
                adv.Payment_Transaction_Id__c = parseResult.txnId;
            }
            if(String.isNotEmpty(parseResult.paymentMode)){
                adv.Mode_of_Advance_Payment__c = parseResult.paymentMode;
            }
            if(!parseResult.states.isEmpty()){
                adv.Payment_State__c = string.join(parseResult.states,',');
            }
            if(String.isNotEmpty(parseResult.customerName)){
                adv.Paying_Customer_Name__c = parseResult.customerName    ;
            }
            
            
            adv.Payment_Status__c = String.isEmpty(parseResult.status) && parseResult.errorMessage=='No transaction records found.'?'No Payment Found':parseResult.status;


            update adv;//Update the payment status
        }catch(Exception ex){
            System.debug(ex.getMessage());
        }
    }

    //method to call queable method
    @AuraEnabled
    public static string backendStatusCheckJob(String calloutType,String refNumber,String jsonPart,String expiryTime){
        try {
            Integer delayInMinutes = Integer.valueOf(expiryTime);
            ID jobID = System.enqueueJob(new AppliancesAdvancedPayment(calloutType,refNumber,jsonPart), delayInMinutes);
            return jobID;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    //Backend status check functioanlity end here
    

    //Get all the Advanced payments to calculate remaining payment
    @AuraEnabled(cacheable=true)
    public static double getAdvancedPayment(Id recordId){
        try {
            Double paymentAmount = [Select Id,Order_Amount__c from Order where Id =:recordId].Order_Amount__c;
            
            for(Advance_Payment_Details__c adv : [ Select Id, Amount__c
                                                            from Advance_Payment_Details__c 
                                                            where Order__c =:recordId
                                                             AND(Mode_of_Advance_Payment__c = 'Cash'
                                                                OR Balance_Payment_Mode__c = 'Cash'
                                                                OR Payment_Status__c ='AUTHORIZED')
                                                            ]
                ){
                    paymentAmount = (adv.Amount__c <= paymentAmount) ? (paymentAmount - adv.Amount__c) : 0;
                    
            }
            return paymentAmount;
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    // Update the Advance Payment
    @AuraEnabled
    public static boolean updateAdvancedPayment(Advance_Payment_Details__c record){        
        try{
            update record;
            return true;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    
    //For status check get the current record
    @AuraEnabled
    public static String getCurrentAdvancedPayment(Id recordId){
        try{
            return [Select Id, Reference_Number__c from Advance_Payment_Details__c where Id = :recordId].Reference_Number__c;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    //get default contact as Order=> Account=> Address by BP [Primary Checkbox] => Address => Telephone
    @AuraEnabled(cacheable = true)
    public static String  getPhoneNumber(Id orderId){
        Order order = [Select Id,AccountId from Order where Id=:orderId];
        Account acn = [Select Id,
                         (Select Id,
                         Address_Code__r.Telephone__c
                         from Addresses_by_BP__r where isPrimary__c = true limit 1)
                        from Account where Id=:order.AccountId
                    ];

        return acn?.Addresses_by_BP__r?. Address_Code__r?.Telephone__c;
    }


  
}