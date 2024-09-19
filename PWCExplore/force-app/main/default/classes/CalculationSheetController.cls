/*------------------------------------------------------------------------
Author:        Jayasurya Gunasekharan
Company:       Stetig
Description:   Class for generation of Calculation Sheet over Head of Terms
Inputs:        NA
Test Class:    
----------------------------------------------------------------------------*/

public class CalculationSheetController {
    public Boolean isRunError {get;set;}
    public string preparedFor {get;set;}
    public string preparedBy{get;set;} 
    public NumberToWord formatClass {get;set;}
    public string amountCompensation{get;set;}
    public string amountSecurityDep{get;set;}
    public string amountRate{get;set;}
    public string wordCompensation{get;set;}
    public string wordSecurityDep{get;set;}
    public string wordRate{get;set;}
    public List<BillingWrapper> billingWrapperList {get; set;}
    public string hotId;
    public Junction_Unit__c rentalUnit {get;set;}
    public List<HEAD_OF_TERMS__c> headOfTermsList {get;set;}
    public List<Junction_Unit__c> rentalUnitList {get;set;}
    public List<Term_Item__c> termList {get;set;}
    public List<Billing_Schedule__c> billingSchList {get;set;}
    public Map<id, Term_Item__c> termMap {get;set;}
    
    //fetch billing schedule details for Calculation Sheet
    public void getDetails() {
        isRunError = false;
        headOfTermsList = new List<HEAD_OF_TERMS__c>();
        rentalUnitList = new List<Junction_Unit__c>();
        termList = new List<Term_Item__c>();
        billingSchList = new List<Billing_Schedule__c>();
        termMap = new Map<id, Term_Item__c>();
        billingWrapperList = new List<BillingWrapper>();
        hotId = ApexPages.currentPage().getParameters().get('hotId');
        formatClass = new NumberToWord();
        amountCompensation = '';
        amountSecurityDep='';
        amountRate='';
        wordCompensation = '';
        wordSecurityDep = '';
        wordRate = '';
        
        //fetching head of terms list for details 
        headOfTermsList = [Select Id, Name, Licensor__c, Proposed_Licensee__c, Net_usable_area_Area_Sq_ft__c, Building__c,
                           Building__r.Building_View__c, Building__r.Project__c, Building__r.City__c, Building__r.Location__c,
                           Building__r.Display_Name__c, Opportunity__r.Auto_Number__c, Bill_Leasing_Term__c, Leasing_Term__c,
                           Billing_Mismatch__c
                           from HEAD_OF_TERMS__c
                           where id =: hotId];
        
        //fetching rental unit/junction unit for details
        rentalUnitList = [Select Id, Name, HEAD_OF_TERMS__c, Floor__c, Floor__r.Block__c, Floor__r.Floor_Number__c
                          from Junction_Unit__c
                          where HEAD_OF_TERMS__c =: hotId];
        
        //fetching term clauses for columns to be displayed using wrapper
        termList = [Select Id, Name, HEAD_OF_TERMS__c, Header__c, Merged_Term_Value__c, Value__c, Merge_Field_1__c, Deviation__c,
                    Reason_for_deviation__c, Negotiation_Details__c, Negotiation_Log__c
                    from Term_Item__c
                    where HEAD_OF_TERMS__c =: hotId order by sequence__c];
        
        //fetching billing schedule list for displaying the details related to amount
        billingSchList = [Select Id, Name, HEAD_OF_TERMS__c, Charges_Type__c, Net_usable_area_Area_Sq_ft__c, Start_Date__c, 
                          End_Date__c, From_Month__c, To_Month__c, Number_of_Months__c, Rate__c, Amount__c, Security_Deposit__c, Charges_Type__r.Name
                          from Billing_Schedule__c
                          where HEAD_OF_TERMS__c =: hotId and Charges_Type__r.Charge_Type__c =: ElbConstantsClass.CHARGE_TYPES_LICENSE_FEE
                          order by Name];
        
        if(headOfTermsList[0].Leasing_Term__c != headOfTermsList[0].Bill_Leasing_Term__c || billingSchList.isEmpty() && headOfTermsList[0].Billing_Mismatch__c == true){
            isRunError = true;
            Apexpages.addMessage(new Apexpages.Message(ApexPages.severity.ERROR, 'Please enter the details for Billing Schedule or check the details entered in the Billing Schedule, there is a mis-match of the license term.'));
        } 
        else{
            Integer i1 = 1;
            for(Billing_Schedule__c bill: billingSchList){
                List<Billing_Schedule__c> biList = new List<Billing_Schedule__c>();
                biList.add(bill);
                amountCompensation = formatClass.INFormat(bill.Amount__c);
                amountSecurityDep = formatClass.INFormat(bill.Security_Deposit__c);
                amountRate = formatClass.INFormat(bill.Rate__c);
                wordCompensation = formatClass.getNumberToWordConvertion(bill.Amount__c);
                wordSecurityDep = formatClass.getNumberToWordConvertion(bill.Security_Deposit__c);
                wordRate = formatClass.getNumberToWordConvertion(bill.Rate__c);
                if(bill.Start_Date__c == NULL || bill.End_Date__c == NULL){
                    billingWrapperList.add(new BillingWrapper(i1, biList, false, amountCompensation, amountSecurityDep, amountRate, wordCompensation, wordSecurityDep, wordRate));
                }
                else{
                    billingWrapperList.add(new BillingWrapper(i1, biList, true, amountCompensation, amountSecurityDep, amountRate, wordCompensation, wordSecurityDep, wordRate));
                }
                i1 += 1;
            }
        }
    }
    
    public class BillingWrapper{
        public Integer billingSequence {get;set;}
        public Boolean printDate {get;set;}
        public List<Billing_Schedule__c> billingItemObject {get;set;}
        public String moneyFormatCompensation {get;set;}
        public String moneyFormatSecurityDep {get;set;}
        public String moneyFormatRate {get;set;}
        
        public String wordFormatCompensation {get;set;}
        public String wordFormatSecurityDep {get;set;}
        public String wordFormatRate {get;set;}
        
        public BillingWrapper(Integer billingSequence, List<Billing_Schedule__c> billingItemObject, Boolean printDate, String moneyFormatCompensation, String moneyFormatSecurityDep, String moneyFormatRate, String wordFormatCompensation, String wordFormatSecurityDep, String wordFormatRate){
            this.billingSequence = billingSequence;
            this.billingItemObject = billingItemObject;
            this.printDate = printDate;
            this.moneyFormatCompensation = moneyFormatCompensation;
            this.moneyFormatSecurityDep = moneyFormatSecurityDep;
            this.moneyFormatRate = moneyFormatRate;
            this.wordFormatCompensation = wordFormatCompensation;
            this.wordFormatSecurityDep = wordFormatSecurityDep;
            this.wordFormatRate = wordFormatRate;
        }
    }
}