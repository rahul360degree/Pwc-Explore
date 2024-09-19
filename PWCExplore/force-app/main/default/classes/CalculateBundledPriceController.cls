/*------------------------------------------------------------------------------------
 * Author        :        Joshna
 * Company       :        Salesforce
 * Description   :        Controller for CalculateBundledPrice component
 * Inputs        :        
 * Test Class    :    
 * History
 * --------
 * 15-06-2020      Joshna Palla     Initial Release
 * ----------------------------------------------------------------------------------*/
public with sharing class CalculateBundledPriceController {
    /* Method to calculate prices for base product for every sequence and all products that don't have a sequence
     * Following logic is used to calculate the prices - 
     * 1. Identify base product of every sequence
     * 2. For each sequence, identify the total price of all other related products within the sequence barring the base product and add per equipment cost
     * 3. Identify all products without sequence
     * 4. Ideally, these products should be where Manpower type = Supervisor or Technician
     * 5. Identify the total cost of these and distribute by quantity across base products
     * 6. If any product doesn't have a sequence and is not of the manpower type listed in (4), copy sales price to rate of contract per month
     * 7. This field will be blank for all non-base products in a sequence and all supervisor/technicians regardless of sequence
     */
    @AuraEnabled
    public static void calculateBundledPrices(String recordId) {
        if (String.isBlank(recordId)) {
            throw getAuraException(System.Label.Import_Invalid_Quote);
        }
        Map<Id, QuoteLineItem> quoteUpdateMap = new Map<Id, QuoteLineItem> ();
        Map<Decimal, Map<String, List<QuoteLineItem>>> qliPerSequence = new Map<Decimal, Map<String, List<QuoteLineItem>>>();
        List<QuoteLineItem> independentProducts = new List<QuoteLineItem>();
        Map<Id, Decimal> perEquipmentCostByBaseProduct = new Map<Id, Decimal>();
        Decimal totalQuantityAcrossSequences = 0;
        Decimal totalIndependentProductPrice = 0;
        Decimal totalQuantity = 0;
        
        Boolean flagForIsNewEquipment = false;
        String typeOfQuoteEquipment = '';

        for (QuoteLineItem each : [SELECT Id, UnitPrice, Quantity, Description, Sequence_Number__c, Product2.Name, Product2.Description, Component_Type__c,
                                          Price_per_Equipment__c, Product2.Variant_Type__c, Quote.RecordType.DeveloperName,
                                          Is_New_Equipment__c, Quote.Type_of_Equipment__c
                                    FROM QuoteLineItem
                                    WHERE QuoteId = :recordId]) {
            if (String.isBlank(each.Component_Type__c)) {
                throw getAuraException(System.Label.Invalid_Product_Type + ' ' + each.Product2.Name);
            }
                                        
            //Type Of Equipment                            
            typeOfQuoteEquipment = each.Quote.Type_of_Equipment__c;                          
            if( each.Is_New_Equipment__c == TRUE)
                flagForIsNewEquipment = TRUE;

                                        
            if (String.isBlank(each.Description)) {
                each.Description = each.Product2.Description;
                quoteUpdateMap.put(each.Id, each);
            }
            if (each.Sequence_Number__c == null || (each.Quote.RecordType.DeveloperName == GlobalConstants.QUOTE_RECORDTYPE_DEV_NAME_MHE_EQUIPMENTS
                       && String.isNotBlank(each.Product2.Variant_Type__c)
                       && !GlobalConstants.EQUIPMENT_ROLL_UP_VARIANTS.contains(each.Product2.Variant_Type__c))) {
                if (GlobalConstants.MANPOWER_COMMON.contains(each.Component_Type__c)) {
                    independentProducts.add(each);
                } else {
                    each.Price_per_Equipment__c = each.UnitPrice;
                    quoteUpdateMap.put(each.Id, each);
                }
            } else {
                Map<String, List<QuoteLineItem>> sequenceMap;
                if (qliPerSequence.containsKey(each.Sequence_Number__c)) {
                    sequenceMap = qliPerSequence.get(each.Sequence_Number__c);
                } else {
                    sequenceMap = new Map<String, List<QuoteLineItem>>();
                }
                if (sequenceMap.containsKey(each.Component_Type__c)) {
                    sequenceMap.get(each.Component_Type__c).add(each);
                } else {
                    sequenceMap.put(each.Component_Type__c, new List<QuoteLineItem>{each});
                }
                qliPerSequence.put(each.Sequence_Number__c, sequenceMap);
                if (each.Price_per_Equipment__c != null) {
                    each.Price_per_Equipment__c = null;
                    quoteUpdateMap.put(each.Id, each);
                }
            }
            totalQuantity += each.Quantity;
        }
        
        //Type Of Equipment Validation
        if (String.IsNotBlank(typeOfQuoteEquipment) 
            && typeOfQuoteEquipment.equalsIgnoreCase(GlobalConstants.QUOTE_TYPE_OF_EQUIPMENT_NEW)
            && (flagForIsNewEquipment == FALSE)) {
            throw getAuraException(System.Label.MHERentalTypeOfEquipmentError);
        }


        if (totalQuantity != Integer.valueOf(totalQuantity)) {
            throw getAuraException(System.Label.Invalid_Quantity);
        }

        for (Decimal each : qliPerSequence.keySet()) {
            if (!qliPerSequence.get(each).containsKey(GlobalConstants.BASE_PRODUCT_COMPONENT_TYPE)) {
                throw getAuraException(System.Label.No_Base_Product + ' ' + each);
            }
            if (qliPerSequence.get(each).get(GlobalConstants.BASE_PRODUCT_COMPONENT_TYPE).size() > 1) {
                throw getAuraException(System.Label.Multiple_Base_Products + ' ' + each);
            }
            QuoteLineItem baseProduct = qliPerSequence.get(each).get(GlobalConstants.BASE_PRODUCT_COMPONENT_TYPE).get(0);
            Decimal totalPriceForSequence = 0;
            for (String componentType : qliPerSequence.get(each).keySet()) {
                if (componentType == GlobalConstants.BASE_PRODUCT_COMPONENT_TYPE) {
                    continue;
                }
                for (QuoteLineItem eachLineItem : qliPerSequence.get(each).get(componentType)) {
                    totalPriceForSequence += eachLineItem.Quantity * eachLineItem.UnitPrice;
                }
            }
            perEquipmentCostByBaseProduct.put(baseProduct.Id, baseProduct.UnitPrice + (totalPriceForSequence/baseProduct.Quantity));
            totalQuantityAcrossSequences += baseProduct.Quantity;
        }

        if (!independentProducts.isEmpty()) {
            for (QuoteLineItem each : independentProducts) {
                totalIndependentProductPrice += each.UnitPrice * each.Quantity;
            }
        }

        for (Id each : perEquipmentCostByBaseProduct.keySet()) {
            QuoteLineItem baseProduct = new QuoteLineItem(Id = each);
            if (quoteUpdateMap.containsKey(each)) {
                baseProduct = quoteUpdateMap.get(each);
            }
            baseProduct.Price_per_Equipment__c = (perEquipmentCostByBaseProduct.get(each) + totalIndependentProductPrice/totalQuantityAcrossSequences).setScale(0);
            quoteUpdateMap.put(each, baseProduct);
        }

        try {
            update quoteUpdateMap.values();
        } catch (DMLException ex) {
            throw getAuraException(ex.getMessage());
        }
    }

    private static AuraHandledException getAuraException(String message) {
        AuraHandledException newException = new AuraHandledException(message);
        newException.setMessage(message);
        return newException;
    }
}