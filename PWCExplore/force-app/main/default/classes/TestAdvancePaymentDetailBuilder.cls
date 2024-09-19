@isTest
public with sharing class TestAdvancePaymentDetailBuilder {
    Advance_Payment_Details__c advancePaymentInstance;
    
    public TestAdvancePaymentDetailBuilder() {
        advancePaymentInstance = new Advance_Payment_Details__c();
    }
    
    public Advance_Payment_Details__c setEMIScheme(String emiScheme) {
        advancePaymentInstance.EMI_Scheme__c = emiScheme;
        return advancePaymentInstance;
    }
    
    public Advance_Payment_Details__c setPaymentMode(String paymentMode) {
        advancePaymentInstance.Payment_Mode__c = paymentMode;
        return advancePaymentInstance;
    }
    
    public Advance_Payment_Details__c setEMIVendor(String vendor) {
        advancePaymentInstance.EMI_Vendor__c = vendor;
        return advancePaymentInstance;
    }
    
    public Advance_Payment_Details__c setBankName(String bankName) {
        advancePaymentInstance.Bank_Provider_Name__c = bankName;
        return advancePaymentInstance;
    }
    
    public Advance_Payment_Details__c setReferenceNumber(String refNo) {
        advancePaymentInstance.Reference_Number__c = refNo;
        return advancePaymentInstance;
    }
    
    public Advance_Payment_Details__c setOrder(Id orderId) {
        advancePaymentInstance.Order__c = orderId;
        return advancePaymentInstance;
    }
    
    public Advance_Payment_Details__c setTransactionType(String transType) {
        advancePaymentInstance.Transaction_Type__c = transType;
        return advancePaymentInstance;
    }    

    public Advance_Payment_Details__c setModeOfAdvancePayment(String modeOfAdvPay) {
        advancePaymentInstance.Mode_of_Advance_Payment__c = modeOfAdvPay;
        return advancePaymentInstance;
    }       

    public Advance_Payment_Details__c setTransactionEntryDate(Date transEntryDate) {
        advancePaymentInstance.Transaction_Entry_Date__c = transEntryDate;
        return advancePaymentInstance;
    }
    
    //added by jalaj 13-07-2021
    
    public Advance_Payment_Details__c setTypeOfTransaction(String typeOfTrans) {
        advancePaymentInstance.Type_of_Transaction__c = typeOfTrans;
        return advancePaymentInstance;
    }
    
/*    public Advance_Payment_Details__c setLogisticCompany(String company) {
        advancePaymentInstance.Logistics_Company_Branch__c	 = company;
        return advancePaymentInstance;
    } */
}