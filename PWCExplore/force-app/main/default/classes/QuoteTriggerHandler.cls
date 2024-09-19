/*------------------------------------------------------------------------
Author:        Kishor Kumar
Company:       Salesforce
Description:   Handler class for Quote Trigger
Inputs:        NA
Test Class:    
History 
06-04-2020      Kishor Kumar     Initial Release
----------------------------------------------------------------------------*/
public with sharing class QuoteTriggerHandler extends VTriggerHandler{
    
    // Allows unit tests (or other code) to disable this trigger for the transaction
    public static Boolean TriggerDisabled = false;
 
    /*
        Checks to see if the trigger has been disabled either by custom setting or by running code
    */
    public override Boolean IsDisabled(){
        Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
        if (setting.QuoteTriggerDisabled__c)
            return true;
        else 
            return TriggerDisabled;
    } 
    
    /*------------------------------------------------------------------------
    Author:        Kishor Kumar
    Company:       Salesforce
    Description:   Method to handle before Insert event context of Quote Trigger
    Inputs:        list of inserted records
    Test Class:   

    History
    08-04-2020      Kishor Kumar     Initial Release
    ----------------------------------------------------------------------------*/
    public override void BeforeInsert(list<SObject> newItems){
        QuoteLineRuleEngine.evaluteRule(newItems, null, 'Quote',GlobalConstants.Context_Variable_Insert);  //Added GlobalConstants.Context_Variable_Insert by Shreela on 16th January 2023 for SAEPB 44
        QuoteRecordProcessor  qProcessor = new QuoteRecordProcessor();
        qProcessor.populateQuoteWarehouses_BasedOnOpportunity((List<Quote>) newItems);
        qProcessor.prepopulateQuoteField((list<Quote>) newItems);
        SoldToPricebookUtility.setSoldtoShiptoAtQuote((list<Quote>)newItems,null);
        qProcessor.populateCustomerGSTN((list<Quote>)newItems,null); 
        
        qProcessor.validateAndAutoapproveForSSG_SFS((list<Quote>)newItems,null);
        qProcessor.validateAndAutoapproveForSSG_Regular_Key((list<Quote>)newItems,null);
        
        qProcessor.populateQuoteWarehouse((List<Quote>) newItems);
        qProcessor.validateCommissionWhenInserted((List<Quote>)newItems);
        
        //Added here by Praful - 22-Feb-2021
        qProcessor.populateEndDate((List<Quote>) newItems);
        qProcessor.populateQuoteVersion((List<Quote>) newItems); // Added for Locks Quotes to have versions
        
        //Added by Rohit Jadhav for PED - 12 July 2023
        qProcessor.validateOpportunityGeographicalLocationAndHighCustomerCreditAssessment((List<Quote>) newItems);
    }
    
    /*------------------------------------------------------------------------
    Author:        Kishor Kumar
    Company:       Salesforce
    Description:   Method to handle After Insert event context of Quote Trigger
    Inputs:        map of created records
    Test Class:   

    History
    06-04-2020      Kishor Kumar     Initial Release
    ----------------------------------------------------------------------------*/
    public override void AfterInsert(Map<Id, SObject> newItems) {
        PricingApprovalRequestRecordCreator recordCreator = new PricingApprovalRequestRecordCreator();
        QuoteRecordProcessor  qProcessor = new QuoteRecordProcessor();
        recordCreator.createPricingApprovalRequestRecord((list<Quote>) newItems.values());
        
        qProcessor.updatePARForAutoapprovedQuotes((map<Id, Quote>) newItems);
        qProcessor.updateOpportunityStage(newItems.values()); //Added for loop  by Shreela on 9th August 2022 for SAEPB - 44 Appliance B2B
        
    }
    
    /*------------------------------------------------------------------------
    Author:        Kishor Kumar
    Company:       Salesforce
    Description:   Method to handle Before Update event context of 'Quote' Trigger
    Inputs:        map of created records
    Test Class:   

    History
    08-04-2020      Kishor Kumar     Initial Release
    ----------------------------------------------------------------------------*/
    public override void BeforeUpdate(map<Id, sObject> newItems, map<Id, sObject> oldItems){
        QuoteRecordProcessor  qProcessor = new QuoteRecordProcessor();
        
 
        //To Avoid loop 
        if(GlobalConstants.EXECUTE_METHOD){        
            qProcessor.updateQuoteApprovalStatus((map<Id, Quote>) newItems, (map<Id, Quote>) oldItems);             
            QuoteLineRuleEngine.evaluteRule((list<Quote>)newItems.values(), (map<Id, Quote>)oldItems, 'Quote',GlobalConstants.Context_Variable_Update);  //Added GlobalConstants.Context_Variable_Update by Shreela on 16th January 2023 for SAEPB 44
            SoldToPricebookUtility.setSoldtoShiptoAtQuote((list<Quote>)newItems.values(), (map<Id, Quote>)oldItems);
            qProcessor.populateCustomerGSTN((list<Quote>)newItems.values(),(map<Id, Quote>)oldItems);
            
            qProcessor.validateAndAutoapproveForSSG_SFS((list<Quote>)newItems.values(),(map<Id, Quote>)oldItems);
            qProcessor.validateAndAutoapproveForSSG_Regular_Key((list<Quote>)newItems.values(),(map<Id, Quote>)oldItems);
            
            qProcessor.populateQuoteWarehouses_BasedOnOpportunity((List<Quote>) newItems.values());
            qProcessor.populateQuoteWarehouse((List<Quote>) newItems.values());
            qProcessor.validateQuoteWarehouses((Map<Id, Quote>) newItems, (List<Quote>) oldItems.values());
            qProcessor.validateCommissionWhenUpdated((map<Id, Quote>) newItems, (map<Id, Quote>) oldItems);
            
            //Addded by Praful - 22-Feb-2021
            qProcessor.populateEndDate((Map<Id, Quote>) newItems, (Map<Id, Quote>) oldItems);
                        
        } 

         qProcessor.updateLastApprovedDate((Map<Id, Quote>) newItems,(Map<Id, Quote>) oldItems); //Added by Shreela on 14th November 2022 for SAEPB-44   
         qProcessor.updatePaymentTermsofQuote((List<Quote>) newItems.values(),(Map<Id, Quote>) oldItems);  //Added by Shreela on 14th December 2022 for SAEPB-44
         qProcessor.validateOfferDateForPED((List<Quote>) newItems.values(), (map<Id, Quote>) oldItems);  //Added by rohit on 20th November 2023 for PED.   
    }
    
    /*------------------------------------------------------------------------
    Author:        Kishor Kumar
    Company:       Salesforce
    Description:   Method to handle After Update event context of Quote Trigger
    Inputs:        map of created records
    Test Class:   

    History
    08-04-2020      Kishor Kumar     Initial Release   
    ----------------------------------------------------------------------------*/
    public override void AfterUpdate(map<Id, sObject> newItems, map<Id, sObject> oldItems){
        
        //Update approval status on associated QLIs
        QuoteRecordProcessor  qProcessor = new QuoteRecordProcessor();
         
         //ADDED BY PRAFUL - ADDED RECURSION HANDLE
        if(GlobalConstants.ALLOW_TRIGGER_TO_EXECUTE)
            qProcessor.updateQLIsApprovalStatus((map<Id, Quote>)newItems , (map<Id, Quote>)oldItems);
        
        qProcessor.updatePARForAutoapprovedQuotes((map<Id, Quote>) newItems);
        qProcessor.updateQLIWarehouses((Map<Id, Quote>) newItems, (List<Quote>) oldItems.values());
        
        qProcessor.updateOpportunityStage(newItems.values()); //Added for loop  by Shreela on 9th August 2022 for SAEPB - 44 Appliance B2B
        qProcessor.updatePaymentTermsofQLI((List<Quote>) newItems.values(),(Map<Id, Quote>) oldItems); //Added by Shreela on 21st November 2022 for SAEPB-44  
        qProcessor.sendEmailNotificationOnLocksB2BQuoteApproval((list<Quote>)newItems.values(), (map<Id, Quote>) oldItems);
        qProcessor.updateQLIForLocksB2B(newItems, oldItems);
        qProcessor.sendEmailNotificationToPEDUsers((list<Quote>)newItems.values(), (map<Id, Quote>) oldItems); // Added by Rohit Jadhav on 17th oct 2023 
    }
    
}