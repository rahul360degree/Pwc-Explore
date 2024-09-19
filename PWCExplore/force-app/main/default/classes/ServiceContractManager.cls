/*------------------------------------------------------------------------
Author:        Kartik Shetty
Company:       Salesforce
Description:   Class to generate service contract from quote
Inputs:        NA
Test Class:   

History
25-05-2020      Kartik Shetty     Initial Release
17-07-2020      Joshna Palla      Updated Discount fields
----------------------------------------------------------------------------*/
public with sharing class ServiceContractManager {
    public class ServiceContractManagerException extends Exception {}

    private final String COMMODITY_CODE = System.Label.Commodity_Code;
    private List<Quote> quoteRec;

    @AuraEnabled
    public static String validateQuote(String quoteId){
        List<Quote> quoteRecords = [Select Id, ExpirationDate, Status, AccountId, Opportunity.Internal_Sales_Rep__c, Primary_Quote__c, 
                                    RecordType.DeveloperName, Opportunity.Sales_Branch_Name__c, Sold_to_Business_Partner__c
            FROM Quote WHERE Id = : quoteId
        ];
        List<QuoteLineItem> quoteLineItems = [Select Id FROM QuoteLineItem WHERE QuoteId =: quoteId ];
        if(quoteRecords[0].RecordType.DeveloperName!=GlobalConstants.QUOTE_MHE_CONTRACTS_RECORDTYPE_APINAME
           && quoteRecords[0].RecordType.DeveloperName!=GlobalConstants.QUOTE_MHE_RENTALS_RECORDTYPE_APINAME)
            return System.Label.Cannot_Generate_Service_Contract;

        // if accountId is missing from quote then ask user to verify the quote
        if(quoteRecords[0] != null && quoteRecords[0].Primary_Quote__c != null) {
            return 'This is not the Primary Quote.';
        }
        else if(quoteRecords[0] != null && quoteRecords[0].AccountId == null){
            return System.Label.ACCOUNT_NAME_MISING;
        }else if(quoteRecords[0] != null && quoteRecords[0].ExpirationDate != null && quoteRecords[0].ExpirationDate < Date.today()){//if quote expirationdate is of past then ask user to create another quote
            return System.Label.QUOTE_EXPIRED;
        }else if(quoteRecords[0].Status != GlobalConstants.QUOTE_STATUS_FINALIZED){//Check for quote status as finalized to generate order
            return System.Label.QUOTE_NOT_FINALIZED;
        }else if(quoteLineItems == null || quoteLineItems.size() == 0 ){//ask user to add if no products added 
            return System.Label.NO_PRODUCT_ADDED;
        }
        return null;
    }

    @AuraEnabled
    public static ServiceContract createServiceContract(String quoteId){
        ServiceContractManager classInstance = new ServiceContractManager();
        ServiceContract serviceContractObj;
        try {
            serviceContractObj = classInstance.createServiceContractDS(quoteId);
            insert serviceContractObj;
            classInstance.createServiceContractLineItems(serviceContractObj.Id, serviceContractObj.PriceBook2Id);
        } catch(Exception ex) {
            Logger.logError('ServiceContractManager', 'createServiceContract', String.valueOf(quoteId), ex);
            throw new ServiceContractManagerException((ex.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION') ? ex.getMessage().substringAfter('FIELD_CUSTOM_VALIDATION_EXCEPTION,') : ex.getMessage() ));

        }
        return serviceContractObj;
    }

    /*
        @description: Function to create datastructure related to ServiceContract.
        @param: String quoteId
        @return: ServiceContract record
    */
    private ServiceContract createServiceContractDS(String quoteId) {
        ServiceContract serviceContractObj = new ServiceContract();
        //Fetch quote details to construct quoteKey
        quoteRec = [Select Id, QuoteNumber, RecordType.DeveloperName, AccountId, OpportunityId, Opportunity.OwnerId,
            ExpirationDate, Status, PriceBook2Id,
            Sold_to_Address__c, Quote_Discount__c, Transaction_Type__c, Payment_Terms__c,
            Total_Customer_Discount_Percentage__c, Opportunity.Internal_Sales_Rep__c, 
                    Invoice_To__c ,Invoice_To_Address__c, Name,
            //added by Praful - 22-Feb-2021
            Duration_Unit__c, Duration__c, Contract_Start_Date__C, Contract_End_Date__C,
            Opportunity.CreatedById,Opportunity.CreatedBy.ContactId,Opportunity.CreatedBy.Service_Manager__c,
            Opportunity.Business_Unit__c,Opportunity.MHE_Division__c //Added by Namrata for SMEPB-142 on 31/01/2024
            FROM Quote WHERE Id =: quoteId
        ];

        //Store order RecordTypeId based on order record type dev name
        Id recordTypeId;
        String orderRecordType;
        recordTypeId = Schema.SObjectType.ServiceContract.getRecordTypeInfosByDeveloperName().get(GlobalConstants.SERVICECONTRACT_RECORDTYPE_NAME).getRecordTypeId();
        serviceContractObj = mapQuoteFieldsToServiceContract(quoteRec[0]);
        serviceContractObj.RecordTypeId = recordTypeId;
        return serviceContractObj; 
    }

    /*
        @description: Function to map quote related fields to ServiceContract object.
        @param: quoteObj => quote record
        @return: ServiceContract record
    */
    private ServiceContract mapQuoteFieldsToServiceContract(Quote quoteObj) {
        Id userId = UserInfo.getUserId();
        User userRecord = [Select Id, Service_Office__c FROM User WHERE Id = :userId];
        
        Id serviceOfficeRecordTypeId = Schema.SObjectType.Sales_Office__c.getRecordTypeInfosByDeveloperName().get(GlobalConstants.SERVICE_OFFICE_RECORDTYPE_NAME).getRecordTypeId();
        List<Sales_Office__c> salesOfficeRecord = [Select Id, State__c, Logistic_Company__c FROM Sales_Office__c 
            WHERE Service_Department__c = :userRecord.Service_Office__c AND RecordTypeID = :serviceOfficeRecordTypeId LIMIT 1
        ];

        ServiceContract serviceContractObj = new ServiceContract();
        serviceContractObj.Name = String.valueOf(quoteObj.Name);
        serviceContractObj.Associated_Quote__c = quoteObj.Id;
        serviceContractObj.Associated_Opportunity__c = quoteObj.OpportunityId;
        serviceContractObj.AccountId = quoteObj.AccountId;
        serviceContractObj.PriceBook2Id = quoteObj.PriceBook2Id;
        serviceContractObj.Sold_To_BP__c = quoteObj.AccountId;
        serviceContractObj.Invoice_To_BP__c = quoteObj.Invoice_To__c ;
        serviceContractObj.Pay_by_BP__c = quoteObj.AccountId;
        serviceContractObj.Sold_To_BP_Address__c = salesOfficeRecord.size() > 0 ? getSoldToPrimaryAddress_FromAccount(quoteObj, salesOfficeRecord[0]) : quoteObj.Sold_to_Address__c;
        serviceContractObj.Invoice_To_BP_Address__c = quoteObj.Invoice_To_Address__c;
        //Added by Namrata for SMEPB-142 on 31/01/2024
 	    if(quoteObj.Opportunity.MHE_Division__c == GlobalConstants.MHE_DIVISION_CONTRACTS && quoteObj.Opportunity.CreatedBy.ContactId != null){
           	serviceContractObj.Sales_Rep_Code__c = quoteObj.Opportunity.CreatedBy.Service_Manager__c;
        }else{ //Ended by Namrata for SMEPB-142 on 31/01/2024
            serviceContractObj.Sales_Rep_Code__c = quoteObj.Opportunity.OwnerId;
        }
        serviceContractObj.Service_Department__c = salesOfficeRecord.size() > 0 ? salesOfficeRecord[0].Id : null;
        serviceContractObj.Registration_Number__c = salesOfficeRecord.size() > 0 ? getRegistrationNumberRecordId(salesOfficeRecord[0]) :getSequenceZero();
        
        //Added by Praful - 22-Feb-2021
        serviceContractObj.Duration_Unit__c = serviceContractObj.Contract_Renewal_Period_Unit__c = quoteObj.Duration_Unit__c;
        serviceContractObj.Duration__c = serviceContractObj.Contract_Renewal_Period__c = (quoteObj.Duration__c!= null ? String.valueOf(quoteObj.Duration__c):null);
        serviceContractObj.StartDate = quoteObj.Contract_Start_Date__c;
        serviceContractObj.EndDate = quoteObj.Contract_End_Date__c;
        
        
        //Added for MHE Rentals
        serviceContractObj.MHE_Division__c = quoteObj.Opportunity.MHE_Division__c;
        serviceContractObj.Payment_term__c = quoteObj.Payment_Terms__c ;
        return serviceContractObj;
    }

    /*
        @description: Function to get Sold To Address that is marked as primary and it's sold to checkbox is checked 
                    for the associated account.
        @param: quoteObj => Quote record queried for creating the service contract.
        @param: salesOfficeRecord => Sales office record queried
        @return: Id of Address By BP record.
    */
    private Id getSoldToPrimaryAddress_FromAccount(Quote quoteObj, Sales_Office__c salesOfficeRecord) {
        List<Branch__c> branchRecords = [Select Id, Name FROM Branch__c Where 
            Branch_Name__c = :salesOfficeRecord.Logistic_Company__c AND Business_Partner__c = :quoteObj.AccountId
            ORDER BY LastModifiedDate DESC LIMIT 1
        ];
        if(branchRecords.size() > 0) {
            List<Address_by_BP__c> addressByBPRecords = [SELECT Id FROM Address_by_BP__c WHERE 
                Sold_To__c = true AND isPrimary__c = true AND Branch__c = :branchRecords[0].Id ORDER BY LastModifiedDate DESC LIMIT 1
            ];
            if(addressByBPRecords.size() > 0) {
                return addressByBPRecords[0].Id;
            }
        }
        return quoteObj.Sold_to_Address__c;
    }

    public Id getRegistrationNumberRecordId(Sales_Office__c salesOfficeRecord) {
        Date today = Date.today();
        
        List<Registration_Number__c> registrationNumberRecord = [Select Id FROM Registration_Number__c 
            WHERE State__c = :salesOfficeRecord.State__c AND Commodity_Code__c = :COMMODITY_CODE AND Effective_Date__c > :today
        ];
        
        if(registrationNumberRecord.size() > 0) {
            return registrationNumberRecord[0].Id;
        }
        return getSequenceZero();
    }
    
    public Id getSequenceZero() {
        Date today = Date.today();
        List<Registration_Number__c> registrationNumberRecord = [SELECT Id FROM Registration_Number__c 
            WHERE Sequence_Number__c = '0' AND Expiry_Date__c > :today LIMIT 1
        ];
        if(registrationNumberRecord.size() > 0) {
            return registrationNumberRecord[0].Id;
        }
        return null;
    }

    /*
        @description: Function to create ContractLineItems.
        @param: serviceContractId => ServiceContract record id, 
            pricebookId => pricebook id from associated opportunity,
            quoteLineItemJSON => quoteLineItems in JSON string
        @return: 
    */
    /*private void createServiceContractLineItems(Id serviceContractId, Id pricebookId) {
        List<ContractLineItem> contractLineItems = createContractLineItemDS(serviceContractId, pricebookId);
        if(contractLineItems.size() > 0) {
            insert contractLineItems;
        }
    }*/

    /*
        @description: Function to create ContractLineItem related datastructure.
        @param: serviceContractId => ServiceContract record id,
            pricebookId => pricebook id from associated opportunity
        
    */
    private void createServiceContractLineItems(Id serviceContractId, Id pricebookId) {
        list<Asset_Benefit__C> assetBenefitsToUpdate = new list<Asset_Benefit__C>();
        map<Id, Id> qliVsCliId = new  map<Id, Id>();

        //Added following 2 mappings by Anupam Mishra on 21-10-2020 - OTRS NUMBER = 30275319, 30275318
        Map<Id, QuoteLineItem> quoteLineItemMap = new Map<Id, QuoteLineItem>([SELECT Id, UnitPrice, Quantity, Product2Id, PricebookEntryId, 
                Approved_Customer_Discount__c, Approved_SAC_ORC__c, Approved_WD_Retention__c, Asset__c, Asset_Serial_Number__c, 
                Contract_Start_Date__c,Contract_End_Date__c, Description,Date_of_Dispatch__C, Quote.Quote_Discount__c,
                // Added by Praful - 22-Feb-2021
                Duration__c, Duration_Unit__c,
                    (SELECT Id, Name, Contract_Line_Item__c FROM Asset_Benefits__r)  
                FROM QuoteLineItem WHERE QuoteId = :quoteRec[0].Id
        ]);
        List<ContractLineItem> contractLineItems = createContractLineItemMappingVsQLI(pricebookId, quoteLineItemMap, serviceContractId);
        
        //Insert Contract Line Items
        if(contractLineItems.size() > 0) {
            Database.SaveResult[] srList = Database.insert(contractLineItems, true);

            //iterate through each returned result to track the created CLI for each QLI record
            if(srList.size() > 0){
                for(Integer i=0; i< srList.size(); i++){
                    qliVsCliId.put((quoteLineItemMap.values())[i].Id, srList[i].getId());
                }
            }
            
        }
        //iterate through all the QLIs & relate all the asset Benefit records to corresponding CLI
        for(QuoteLineItem qli : quoteLineItemMap.values()){
            if(qliVsCliId.containsKey(qli.Id) && qli.Asset_Benefits__r.size() > 0){
                for(Asset_Benefit__c assetBenefit : qli.Asset_Benefits__r){
                    assetBenefit.Contract_Line_Item__c = qliVsCliId.get(qli.Id);
                  //  assetBenefit.Is_Active__c = TRUE;
                    assetBenefit.Asset__c = qli.Asset__c;
                    assetBenefitsToUpdate.add(assetBenefit);
                }
            }
        }

        //Update all the asset Benefit records to corresponding CLI
        if(assetBenefitsToUpdate.size() > 0){
            update assetBenefitsToUpdate;
        }
        
        
    }

    /*
        @description: Function to map quote related fields to ServiceContract object.
        @param: pricebookId => pricebookd from associated opportunity,
            quoteLineItemMap => quotelineItem records in Map format,
            quoteLineItemIdVSOrderQuantity => quoteLineItem id with order quantity as value
        @return: List of contractLineItem records
    */
    private List<ContractLineItem> createContractLineItemMappingVsQLI(Id pricebookId, Map<Id, QuoteLineItem> quoteLineItemMap, Id serviceContractId) {
        List<ContractLineItem> contractLineItems = new List<ContractLineItem>();
        for(QuoteLineItem qli : quoteLineItemMap.values()) {
            ContractLineItem cli = new ContractLineItem();
            cli.PricebookEntryId = qli.PricebookEntryId;
            cli.Effective_Date__c = GlobalConstants.ORDER_DEFAULT_STARTDATE;
            cli.Cost_Amount__c = (qli.UnitPrice * qli.Quantity);
            cli.Quantity = qli.Quantity;
            //added by Manasi as line items were not getting inserted without parent id.
            cli.ServiceContractId=serviceContractId;
            cli.UnitPrice = qli.UnitPrice;
            cli.AssetId = qli.Asset__c;
            cli.StartDate=qli.Contract_Start_Date__c;
            cli.EndDate=qli.Contract_End_Date__c;
            
            //Added by Praful - 22-Feb-2021
            cli.Duration__c=qli.Duration__c;
            cli.Duration_Unit__c=qli.Duration_Unit__c;
            
            cli.Serial_Number__c = qli.Asset_Serial_Number__c;
            cli.Discount = ((qli.Quote.Quote_discount__c <> 0 && qli.Quote.Quote_discount__c <>NULL) ? qli.Quote.Quote_discount__c : qli.Approved_Customer_Discount__c);
            cli.Sales_Amount__c = calculateActualPrice(qli, qli.Quantity, (cli.Discount<>NULL ? cli.Discount : 0 ));
            
            //Added following 2 mappings by Anupam Mishra on 21-10-2020 - OTRS NUMBER = 30275319, 30275318
            cli.Date_of_Dispatch__c = qli.Date_of_Dispatch__c;
            cli.Description = qli.Description;
            
            contractLineItems.add(cli);
        }
        return contractLineItems;
    }

    private Decimal calculateActualPrice(QuoteLineItem qli, Decimal quantity, Decimal discount) {
        return (qli.UnitPrice * quantity) - (qli.UnitPrice * quantity * discount/100);
    }
}