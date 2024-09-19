/*------------------------------------------------------------------------------------
 * Author        :        Kartik Shetty
 * Company       :        Salesforce
 * Description   :        Controller for handling SR Products
 * Test Class    :          
 * History
 * --------
 * 05-01-2021      Kartik Shetty     Initial Release
 * ----------------------------------------------------------------------------------*/
public without sharing class SRProductManager {

    public static final String EXCLUSTION_PRODUCT_TYPE = 'Exclusion';
    public static final String INCLUSION_PRODUCT_TYPE = 'Inclusion';
    public static final String VALID_USER_PERSONA = System.Label.SR_Product_Valid_Persona;
    public static final String OPP_CLOSE_DATE = System.Label.SR_Product_Opp_Close_Date;
    public static final String SERVICE_FORM_SUBMITTED_STATUS = 'Submitted';

    /*------------------------------------------------------------------------
     Author:        Kartik Shetty
     Company:       Salesforce
     Description:   Method to check whether the user performing the operation is a valid user
     Inputs:        
     Returns:       String - VALID_USER / IN_VALID_USER
    *----------------------------------------------------------------------------*/
    @AuraEnabled
    public static String checkUserAccess(){
        try {
            User userRecord = [Select Id, Persona__c FROM User WHERE Id = :UserInfo.getUserId()];
            if(!String.isBlank(userRecord.Persona__c) && VALID_USER_PERSONA.containsIgnoreCase(userRecord.Persona__c)) {
                return 'VALID_USER';
            }
            return 'IN_VALID_USER';
        } catch (Exception e) {
            throw new CustomException(e.getMessage());
        }
    }

    /*------------------------------------------------------------------------
     Author:        Kartik Shetty
     Company:       Salesforce
     Description:   Method to check if Job Card is submitted.
     Inputs:        Service_Form__c - Service_Form__c
     Returns:       Boolean
    *----------------------------------------------------------------------------*/
    private static Boolean isJobCardSubmitted(Service_Form__c serviceFormRecordInCtxt) {
        if(serviceFormRecordInCtxt.Status__c == SERVICE_FORM_SUBMITTED_STATUS){
            return true;
        }
        return false;
    }
    
    /*------------------------------------------------------------------------
     Author:        Kartik Shetty
     Company:       Salesforce
     Description:   Method to get SR product records in proper format
     Inputs:        Id - service form record id 
     Returns:       List<productWrapper.product> - Products part of service form
    *----------------------------------------------------------------------------*/
    @AuraEnabled
    public static List<ProductWrapper.product> getSRProductList(Id recordId) {
        List<ProductWrapper.product> wrapperClassList = new List<ProductWrapper.product>();
        try {
            List<SR_Products__c> serviceProductList = [Select Id, Is_Available_In_Inclusion_List__c, Product__c, 
                Product__r.Name, Product__r.ProductCode, Product__r.Item__c, Product_Type__c, Quantify__c
                FROM SR_Products__c
                WHERE Service_Form__c = :recordId AND Ignore_record__c = false AND isConverted__c = false
            ];
            if(!serviceProductList.isEmpty()) {
                for(SR_Products__c serviceProduct : serviceProductList) {
                    ProductWrapper.product productWrapper = new ProductWrapper.product();
                    productWrapper.id = serviceProduct.Id;
                    productWrapper.quantity = Integer.valueOf(serviceProduct.Quantify__c);
                    productWrapper.product2Id = serviceProduct.Product__c;
                    productWrapper.productName = serviceProduct.Product__r.Name;
                    productWrapper.productCode = serviceProduct.Product__r.ProductCode;
                    productWrapper.itemCode = serviceProduct.Product__r.Item__c;
                    productWrapper.isDefaultInclusion = false;
                    productWrapper.isInclusion = false;

                    // If product type is of inclusion then mark it as default inclusion.
                    // Branch Champion wont be able to change inclusion status for products that are already of type inclusion.
                    if(serviceProduct.Is_Available_In_Inclusion_List__c) {
                        productWrapper.isDefaultInclusion = true;
                        productWrapper.isInclusion = true;
                    }
                    wrapperClassList.add(productWrapper);
                }
            }
            return wrapperClassList;

        } catch (Exception e) {
            throw new CustomException(e.getMessage());
        }
    }

    /*------------------------------------------------------------------------
     Author:        Kartik Shetty
     Company:       Salesforce
     Description:   Method to mark an SR product as ignored
     Inputs:        Id - service form record id, 
     Returns:       String - Success / Error message
    *----------------------------------------------------------------------------*/
    @AuraEnabled
    public static String markRecordAsIgnored(Id recordId, String productId) {
        try {
            List<SR_Products__c> serviceProductList = [Select Id, Ignore_record__c
                FROM SR_Products__c
                WHERE Service_Form__c = :recordId AND 
                Product__c = :Id.valueOf(productId) AND
                Ignore_record__c = false LIMIT 1
            ];
            if(!serviceProductList.isEmpty()) {
                for(SR_Products__c serviceProduct : serviceProductList) {
                    serviceProduct.Ignore_record__c = true;
                }
                update serviceProductList;
            }
            return 'Success';
        } catch (Exception e) {
            throw new CustomException(e.getMessage());
        }
    }

    /*------------------------------------------------------------------------
     Author:        Kartik Shetty
     Company:       Salesforce
     Description:   Method to SR save records
     Inputs:        List<ProductWrapper.product> - Product wrapper, Id - service form record id 
     Returns:       String - Success or failure message
    *----------------------------------------------------------------------------*/
    @AuraEnabled
    public static String saveRecords(List<ProductWrapper.product> pWrapperProdList, Id recordId) {
        try {
            Map<Id, SR_Products__c> srProductMap = new Map<Id, SR_Products__c>([Select Id, Product__c, Product_Type__c, Is_Available_In_Inclusion_List__c
                FROM SR_Products__c WHERE Service_Form__c = :recordId
            ]);
            for(ProductWrapper.product productWrapper : pWrapperProdList) {
                if(srProductMap.containsKey(productWrapper.id)) {
                    SR_Products__c srProduct = srProductMap.get(productWrapper.id);
                    srProduct.Product_Type__c = EXCLUSTION_PRODUCT_TYPE;
                    srProduct.Is_Available_In_Inclusion_List__c = false;

                    // If Branch/Dealer Champion has marked this as inclusion then update accordingly.
                    if(productWrapper.isInclusion) {
                        srProduct.Product_Type__c = INCLUSION_PRODUCT_TYPE;
                        srProduct.Is_Available_In_Inclusion_List__c = true;
                    }
                }
            }

            update srProductMap.values();
            return 'Success';
        } catch (Exception e) {
            throw new CustomException(e.getMessage());
        }
    }

    /*------------------------------------------------------------------------
     Author:        Kartik Shetty
     Company:       Salesforce
     Description:   Method to create opportunity and opportunity line items for exclusion products.
     Inputs:        List<ProductWrapper.product> - Product wrapper, Id - service form record id 
     Returns:       String - Success or failure message
    *----------------------------------------------------------------------------*/
    @AuraEnabled
    public static String createOpportunity_And_OppProduct_Record(List<ProductWrapper.product> pWrapperProdList, Id recordId) {
        String pricebookName = System.Label.Product_Search_Pricebook;
        ResultWrapper rw;
        try {
            Service_Form__c serviceFormRecordInCtxt = [SELECT Id, Name, Opportunity__c, Order__c, Case__c, Status__c, Case__r.CaseNumber, 
                                                              Case__r.AccountId, Case__r.Account.Sales_SPOC__c, Case__r.Asset.Area_Code__c  
                FROM Service_Form__c WHERE Id = :recordId
            ];
            if(!isJobCardSubmitted(serviceFormRecordInCtxt)) {
                throw new CustomException(System.Label.Job_card_must_be_submitted_for_oppty_creation);
            }
            String result = saveRecords(pWrapperProdList, recordId);

            if(String.isNotBlank(serviceFormRecordInCtxt.Opportunity__c)) {
                throw new CustomException(System.Label.Service_opportunity_already_exists);
            }
            Map<Id, ProductWrapper.product> exclusionProductMap = new Map<Id, ProductWrapper.product>();
            for(ProductWrapper.product productWrapper : pWrapperProdList) {
                if(!productWrapper.isInclusion) {
                    exclusionProductMap.put(productWrapper.product2Id, productWrapper);
                }
            }

            // Return an error message if exclusionProductMap is empty.
            if(exclusionProductMap.isEmpty()) {
                throw new CustomException(System.Label.No_exclusion_products_available);
            }

            Opportunity oppRecord = new Opportunity();
            oppRecord.Name = 'Service Opportunity ' + serviceFormRecordInCtxt.Case__r.CaseNumber + '_' + serviceFormRecordInCtxt.Name;
            oppRecord.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('MHE').getRecordTypeId();
            oppRecord.AccountId = serviceFormRecordInCtxt.Case__r.AccountId;
            oppRecord.CloseDate = (Date.today()).addDays(Integer.valueOf(OPP_CLOSE_DATE));
            oppRecord.StageName = 'Purchase Order';
            oppRecord.Business_Unit__c = GlobalConstants.MHE_DIVISION_CODE;
            oppRecord.MHE_Division__c = 'Spare Parts';
            //Added the below line to Populate Service Form lookup on the created opportunity
            oppRecord.Service_Form__c = serviceFormRecordInCtxt.Id;
            rw = getOpportunityOwnerId(serviceFormRecordInCtxt);
            if(rw != null && String.isNotBlank(rw.userId)) {
                oppRecord.OwnerId = rw.userId;
            }else{
                throw new CustomException(rw.errorMessage);
            }

            insert oppRecord;
            createOpportunityLineItems(oppRecord, exclusionProductMap);

            // Update service form with the opportunity id that is just created.
            serviceFormRecordInCtxt.Opportunity__c = oppRecord.Id;
            update serviceFormRecordInCtxt;
            
            //Update the SRP if all the items are converted
            List<SR_Products__c> srpLstToUpdate = new List<SR_Products__c>();
            for(SR_Products__c srpItr : [SELECT Id 
                                           FROM SR_Products__c 
                                          WHERE Service_Form__c =: serviceFormRecordInCtxt.id AND Product_Type__c =: EXCLUSTION_PRODUCT_TYPE]){
                srpItr.isConverted__c = true;
                srpLstToUpdate.add(srpItr);
            }
            update srpLstToUpdate;

            return String.valueOf(oppRecord.Id);
        } catch (Exception e) {
            System.debug(e.getMessage());
            throw new CustomException(e.getMessage());
        }
    }

    /*------------------------------------------------------------------------
     Author:        Kartik Shetty
     Company:       Salesforce
     Description:   Method to determine who will be the owner of the opportunity record
     Inputs:        Service_Form__c - Service Form record
     Returns:       Id - user id
    *----------------------------------------------------------------------------*/
    private static ResultWrapper getOpportunityOwnerId(Service_Form__c serviceFormRecordInCtxt) {
        
        User userRecord = [Select Id, ContactId, Account.Sales_SPOC__c FROM User WHERE Id = :UserInfo.getUserId()];
        String areaCode = serviceFormRecordInCtxt.Case__r.Asset.Area_Code__c;
        ResultWrapper rw = new ResultWrapper();
        
        //Opportunity owner assignment for external user
        if(!String.isBlank(userRecord.ContactId) && !String.isBlank(userRecord.Account.Sales_SPOC__c)) {
            rw.userId = userRecord.Account.Sales_SPOC__c;
        }
        
        // Opportunity owner assignment for internal user
        else if(String.isNotBlank(areaCode)){
            //Get the branch champion mapping from the metdata
            List<Area_Code_Branch_Champion__mdt> mdtRecords = [SELECT Branch_Champion_salary_code__c, 
                                                                      Sales_SPOC__c 
                                                                 FROM Area_Code_Branch_Champion__mdt
                                                                WHERE Area_Code__c =: areaCode AND BU_Division__c = 'MHE' LIMIT 1];
            If(!mdtRecords.isEmpty() && String.isNotBlank(mdtRecords[0].Sales_SPOC__c)){
                List<User> userLst = [SELECT Id 
                                        FROM User 
                                       WHERE Salary_Code__c =: mdtRecords[0].Sales_SPOC__c AND IsActive = true];
                if(!userLst.isEmpty()){
                    rw.userId = userLst[0].Id;                                  
                }
                else{
                    rw.errorMessage = System.Label.No_active_branch_champion_found_for_area_code + areaCode;
                }   
            }else{
                rw.errorMessage = System.Label.No_record_found_for_branch_champion;
            }
                
        }else{
            rw.errorMessage = System.Label.Area_code_missing_on_asset;
        }
    
        return rw;
    }

    /*------------------------------------------------------------------------
     Author:        Kartik Shetty
     Company:       Salesforce
     Description:   Method to create opportunity line items for exclusion products.
     Inputs:        Opportunity - opportunityRecord, List<ProductWrapper.product> - Product wrapper
     Returns:       
    *----------------------------------------------------------------------------*/
    private static void createOpportunityLineItems(Opportunity oppRecord, Map<Id, ProductWrapper.product> exclusionProductMap) {
        List<Opportunity> opportunityRecords = [Select Id, Pricebook2Id FROM Opportunity WHERE Id = :oppRecord.Id];
        List<OpportunityLineItem> oppProducts = new List<OpportunityLineItem>();

        if(opportunityRecords.isEmpty()) {
            throw new CustomException(System.Label.Pricebook_not_found);
        }

        List<PricebookEntry> pricebookEntryRecords = [Select Id, Product2Id, UnitPrice FROM PricebookEntry 
            WHERE Product2Id IN :exclusionProductMap.keySet() AND Pricebook2Id = :opportunityRecords[0].Pricebook2Id
        ];

        for(PricebookEntry pricebookEntryRecord : pricebookEntryRecords) {
            OpportunityLineItem oppProduct = new OpportunityLineItem();
            oppProduct.PricebookEntryId = pricebookEntryRecord.Id;
            oppProduct.Quantity = exclusionProductMap.get(pricebookEntryRecord.Product2Id).quantity;
            oppProduct.UnitPrice = pricebookEntryRecord.UnitPrice;
            oppProduct.OpportunityId = oppRecord.Id;
            oppProducts.add(oppProduct);
        }

        insert oppProducts;
    }
    
    public class ResultWrapper{
        Id userId;
        String errorMessage;
    }
}