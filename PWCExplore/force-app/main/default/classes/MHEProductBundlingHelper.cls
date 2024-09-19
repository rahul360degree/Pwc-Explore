/*------------------------------------------------------------------------
Author:        Kartik Shetty
Company:       Salesforce
Description:   Class that contains product bundling logic for opportunity products where opportunity record is of type MHE equipment.
Inputs:        NA
Test Class:    
History
03-06-2020      Kartik Shetty     Initial Release
16-06-2020      Kartik Shetty     Added variant type check.
----------------------------------------------------------------------------*/

public with sharing class MHEProductBundlingHelper {
    // Variable used through out the class
    private Map<Id, Product2> associatedProducts;
    private Map<Integer, List<Id>> sequenceNoVSProductIDList = new Map<Integer, List<Id>>();
    private Map<Integer, Id> sequenceNoVSBaseProductID = new Map<Integer, Id>();
    private Map<Integer, OpportunityLineItem> sequenceNoVSBaseOppProduct = new Map<Integer, OpportunityLineItem>();
    private final String BASE_PRODUCT = GlobalConstants.BASE_PRODUCT_COMPONENT_TYPE;
    private final String VARIANT_PRODUCT = GlobalConstants.VARIANT_PRODUCT_COMPONENT_TYPE;
    private Map<Id,Opportunity> IdVsOpportunity=new Map<Id,Opportunity>();
    private String context;
    private final String UPDATE_CONTEXT = 'UPDATE';
    private final String INSERT_CONTEXT = 'INSERT';
    private final String VARIANT_LINE_ITEM_RESTRICTION_TYPES = 'MAST, TYRE, BATTERY';
    private final String VARIANT_QUANTITY_RESTRICTION_TYPES = 'MAST, BATTERY';
    private Map<String, OpportunityLineItem> oppProductRecordsInContext = new Map<String, OpportunityLineItem>();

    public void mainFunction(List<OpportunityLineItem> newRecords, String context) {
        List<OpportunityLineItem> records = preprocessingLogicFor_MHE_Equipments(newRecords, context);
        if(records.size() > 0) {
            processingLogicFor_MHE_Equipments(records);
        }
    }

    // Pre Processor Function
    private List<OpportunityLineItem> preprocessingLogicFor_MHE_Equipments(List<OpportunityLineItem> newRecords, String context) {
        this.context = context;
        identifyTheRecordsInContext(newRecords);
        getAssociatedOpportunityOfTypeMHE(newRecords);
        List<OpportunityLineItem> MHEoppProductRecords = new List<OpportunityLineItem>();

        // Get opportunity products whose opportunity is of type Equipments.
        List<OpportunityLineItem> tempDataHolder = identifyMHE_Equipment_OppProductRecords(newRecords);

        // For BEFORE_INSERT get all the existing products
        List<OpportunityLineItem> getExisitingOppProducts = getExistingOpportunityProducts(tempDataHolder);
        
        if(getExisitingOppProducts.size() > 0) {
            MHEoppProductRecords.addAll(getExisitingOppProducts);
        }
        if(tempDataHolder.size() > 0) {
            MHEoppProductRecords.addAll(tempDataHolder);
        }

        return MHEoppProductRecords;
    }

    // Used to identify the records that are available in trigger context. Will be used during throwing record specific errors.
    private void identifyTheRecordsInContext(List<OpportunityLineItem> newRecords) {
        for(OpportunityLineItem oli : newRecords) {
            oppProductRecordsInContext.put('' + Integer.valueOf(oli.Sequence_Number__c) + oli.Product2Id, oli);
        }
    }

    private void getAssociatedOpportunityOfTypeMHE(List<OpportunityLineItem> newRecords){
        Set<Id> OpportunityIds=new Set<Id>();
        for(OpportunityLineItem oppProduct : newRecords) {
            OpportunityIds.add(oppProduct.OpportunityId);
        }
        IdVsOpportunity=new Map<Id,Opportunity>([Select Business_Unit__c, MHE_Division__c, 
            (Select Id, Product2Id, Quantity, Sequence_Number__c, OpportunityId FROM OpportunityLineItems) 
            FROM Opportunity WHERE Id in :OpportunityIds AND Business_Unit__c = :GlobalConstants.BUSINESS_UNIT_MHE_DIVISION
        ]);
    }

    // Identify only MHE equipment records using opportunity MHE division and seperate them for further processing.
    private List<OpportunityLineItem> identifyMHE_Equipment_OppProductRecords(List<OpportunityLineItem> newRecords) {
        List<OpportunityLineItem> MHE_oppRecords = new List<OpportunityLineItem>();
        for(OpportunityLineItem oppProduct : newRecords) {
            if(IdVsOpportunity.containsKey(oppProduct.OpportunityId)) {
                Opportunity opp = IdVsOpportunity.get(oppProduct.OpportunityId);

                if (String.isBlank(opp.MHE_Division__c)) {
                    associateErrorWithRecord(oppProduct, System.Label.Add_MHE_Division_Error);
                }
                else if(isMHEEquipment_Opportunity(opp)) {
                    MHE_oppRecords.add(oppProduct);
                }
            }
        }
        return MHE_oppRecords;
    }

    private List<OpportunityLineItem> getExistingOpportunityProducts(List<OpportunityLineItem> newRecords) {
        Map<Id, OpportunityLineItem> productIdVSOpportunityProduct = new Map<Id, OpportunityLineItem>();
        List<OpportunityLineItem> existingOppProductsToProcess = new List<OpportunityLineItem>();

        for(OpportunityLineItem oli : newRecords) {
            productIdVSOpportunityProduct.put(oli.Product2Id, oli);
        }
        for(Id oppId : IdVsOpportunity.keySet()) {
            Opportunity opp = IdVsOpportunity.get(oppId);
            for(OpportunityLineItem oli : opp.OpportunityLineItems) {
                if (String.isBlank(opp.MHE_Division__c)) {
                    associateErrorWithRecord(oli, System.Label.Add_MHE_Division_Error);
                    continue;
                }
                else if(isMHEEquipment_Opportunity(opp)) {
                    if( !productIdVSOpportunityProduct.containsKey(oli.Product2Id) ) {
                        existingOppProductsToProcess.add(oli);
                    } else {
                        OpportunityLineItem duplicateOLI = productIdVSOpportunityProduct.get(oli.Product2Id);
                        if(context == UPDATE_CONTEXT && duplicateOLI != null && duplicateOLI.Id != oli.Id) {
                            existingOppProductsToProcess.add(oli);
                        } else if(context == INSERT_CONTEXT && duplicateOLI != null) {
                            existingOppProductsToProcess.add(oli);
                        }
                    }
                }
            }
        }
        return existingOppProductsToProcess;
    }
    
    private Boolean isMHEEquipment_Opportunity(Opportunity oppRecord) {
        if(oppRecord.MHE_Division__c != null && 
           (GlobalConstants.MHE_DIVISION_EQUIPMENT_CONTAINS).containsIgnoreCase(oppRecord.MHE_Division__c)) {
               return true;
        }
        return false;
    }

    // Main function responsible for data processing and apply Product Bundling logic.
    private void processingLogicFor_MHE_Equipments(List<OpportunityLineItem> oppProductRecords) {
        // Get associated products for each opportunity product record.
        getAssociatedProducts(oppProductRecords);

        // Group the products by sequence no provided in their related opportunity product for further processing.
        groupProductsBySequenceNo(oppProductRecords);

        // Perform a set of validations on each of the opportunity product of type MHE Equipments.
        doValidationChecksForMHEEquipments(oppProductRecords);
    }

    private void getAssociatedProducts(List<OpportunityLineItem> newRecords) {
        List<Id> associatedProductIds = new List<Id>();
        for(OpportunityLineItem oppProduct : newRecords) {
            associatedProductIds.add(oppProduct.Product2Id);
        }

        associatedProducts = new Map<Id, Product2>([Select Id, ProductCode, Variant_Type__c, Is_Independent_product__c, Associated_Base_Product__c,
        Component_Type__c From Product2 Where Id IN :associatedProductIds]);
    }
    
    private void groupProductsBySequenceNo(List<OpportunityLineItem> newRecords) {
        List<Id> productIds;
        for(OpportunityLineItem oppProduct : newRecords) {
            productIds = new List<Id>();
            if(sequenceNoVSProductIDList.containsKey(Integer.valueOf(oppProduct.Sequence_Number__c))) {
                productIds = sequenceNoVSProductIDList.get(Integer.valueOf(oppProduct.Sequence_Number__c));
            }
            productIds.add(String.valueOf(oppProduct.Product2Id));
            sequenceNoVSProductIDList.put(Integer.valueOf(oppProduct.Sequence_Number__c), productIds);
        }
    }

    private void doValidationChecksForMHEEquipments(List<OpportunityLineItem> newRecords) {
        ensureEachOppProduct_HasSequenceNumber(newRecords);
        identifyBaseProduct_ForEachSequenceNo(newRecords);
        checkIf_NonIndependentProduct_HasBaseProduct(newRecords);
        checkIf_NonBaseProduct_IsAssociatedWith_ProperBaseProduct(newRecords);
        checkIf_EachBaseProduct_HasOneVariantOfSameVariantType(newRecords);
    }

    private void ensureEachOppProduct_HasSequenceNumber(List<OpportunityLineItem> newRecords) {
        for(OpportunityLineItem oppProduct : newRecords) {
            Product2 associatedProduct = new Product2();
            associatedProduct = associatedProducts.get(oppProduct.Product2Id);
            /*
                If the associated product does not have independent checkbox checked and
                the opportunity product's sequence number is empty then throw error.
            */
            if(associatedProduct != null && !associatedProduct.Is_Independent_product__c && oppProduct.Sequence_Number__c == null) {
                associateErrorWithRecord(oppProduct, System.Label.Sequence_Number_is_mandatory);
            }
        }
    }

    private void identifyBaseProduct_ForEachSequenceNo(List<OpportunityLineItem> newRecords) {
        for(OpportunityLineItem oppProduct : newRecords) {
            // Ensure that each grouped product set has only one base product and maintain it in a DS.
            Product2 tempProduct = new Product2();
            tempProduct = associatedProducts.get(oppProduct.Product2Id);
            if(oppProduct.Sequence_Number__c != null && tempProduct.Component_Type__c == BASE_PRODUCT) {
                if(tempProduct != null && sequenceNoVSBaseProductID.containsKey(Integer.valueOf(oppProduct.Sequence_Number__c))) {
                    associateErrorWithRecord(oppProduct, System.Label.One_sequence_number_one_base_product);
                }
                sequenceNoVSBaseProductID.put(Integer.valueOf(oppProduct.Sequence_Number__c), oppProduct.Product2Id);
                sequenceNoVSBaseOppProduct.put(Integer.valueOf(oppProduct.Sequence_Number__c), oppProduct);
            }
        }
    }

    private void checkIf_NonIndependentProduct_HasBaseProduct(List<OpportunityLineItem> newRecords) {
        for(OpportunityLineItem oppProduct : newRecords) {         
            Product2 associatedProduct = new Product2();
            associatedProduct = associatedProducts.get(oppProduct.Product2Id);
            if( associatedProduct != null && !associatedProduct.Is_Independent_product__c && 
            associatedProduct.Component_Type__c != BASE_PRODUCT && 
            !sequenceNoVSBaseProductID.containsKey(Integer.valueOf(oppProduct.Sequence_Number__c))) {
                associateErrorWithRecord(oppProduct, System.Label.Base_product_required);
            }
        }
    }

    private void checkIf_NonBaseProduct_IsAssociatedWith_ProperBaseProduct(List<OpportunityLineItem> newRecords) {
        for(OpportunityLineItem oppProduct : newRecords) {
            Product2 childProduct = new Product2();
            Product2 baseProduct = null;

            childProduct = associatedProducts.get(oppProduct.Product2Id);
            baseProduct = associatedProducts.get(sequenceNoVSBaseProductID.get(Integer.valueOf(oppProduct.Sequence_Number__c)));
            if(childProduct.Component_Type__c != BASE_PRODUCT && !childProduct.Is_Independent_product__c && baseProduct == null) {
                associateErrorWithRecord(oppProduct, System.Label.Base_product_required);
            } else if(childProduct.Component_Type__c != BASE_PRODUCT && baseProduct != null ) {
                if(childProduct.Id !=  baseProduct.Id &&
                    (childProduct.Associated_Base_Product__c == null || 
                    (baseProduct.ProductCode !=null && !(childProduct.Associated_Base_Product__c).containsIgnoreCase(baseProduct.ProductCode)))
                ) {
                    if(childProduct.Is_Independent_product__c) {
                        associateErrorWithRecord(oppProduct, System.Label.Incorrect_product_association_for_an_independent_product);
                    } else {
                        associateErrorWithRecord(oppProduct, System.Label.Incorrect_product_association);
                    }
                }
            }
        }
    }

    private void checkIf_EachBaseProduct_HasOneVariantOfSameVariantType(List<OpportunityLineItem> newRecords) {
        Set<String> baseProductSequenceNoAndVariantType = new Set<String>();
        for(OpportunityLineItem oppProduct : newRecords) {
            Product2 childProduct = null;
            Product2 baseProduct = null;

            childProduct = associatedProducts.get(oppProduct.Product2Id);
            if(oppProduct.Sequence_Number__c != null) {
                baseProduct = associatedProducts.get(sequenceNoVSBaseProductID.get(Integer.valueOf(oppProduct.Sequence_Number__c)));
            }
            // Only proceed if the product is a child product and that too of type variant.
            if(childProduct != null && baseProduct != null && childProduct.Component_Type__c == VARIANT_PRODUCT 
               && childProduct.Variant_Type__c != null) {

                /*
                    Throw multiple variant error if the variant types are of certain values 
                    and multiple of them is associated with same base product.
                */
                if(baseProductSequenceNoAndVariantType.contains('' + Integer.valueOf(oppProduct.Sequence_Number__c) + childProduct.Variant_Type__c)
                    && VARIANT_LINE_ITEM_RESTRICTION_TYPES.containsIgnoreCase(childProduct.Variant_Type__c)) {
                    associateErrorWithRecord(oppProduct, System.Label.Similar_variant_type_product_added);
                } else {
                    /*
                        Throw quantity error if the variant types are of certain values 
                        and their quantity is greater than that of base product.
                    */
                    baseProductSequenceNoAndVariantType.add('' + Integer.valueOf(oppProduct.Sequence_Number__c) + childProduct.Variant_Type__c);
                    OpportunityLineItem baseOppProduct = sequenceNoVSBaseOppProduct.get(Integer.valueOf(oppProduct.Sequence_Number__c));
                    if(VARIANT_QUANTITY_RESTRICTION_TYPES.containsIgnoreCase(childProduct.Variant_Type__c) && 
                        oppProduct.Quantity > baseOppProduct.Quantity) {
                        associateErrorWithRecord(oppProduct, System.Label.Variant_quantity_is_greater_than_base_product_quantity);
                    }
                }
            }
        }
    }

    // Generic function used to throw error
    private void associateErrorWithRecord(OpportunityLineItem oppProduct, String error_msg) {
        if(oppProductRecordsInContext.containsKey('' + Integer.valueOf(oppProduct.Sequence_Number__c) + oppProduct.Product2Id)) {
            oppProduct.addError(error_msg);
        } else {
            for(String key : oppProductRecordsInContext.keySet()) {
                OpportunityLineItem allOppProductsInContext = oppProductRecordsInContext.get(key);
                allOppProductsInContext.addError(System.Label.Change_in_sequence_number_affects_other_products);
            }
        }
    }
}