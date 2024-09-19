/*------------------------------------------------------------------------------------
 * Author        :        Sumit
 * Company       :        Salesforce
 * Description   :        Product Wrapper
 * Test Class    :    	  	
 * History
 * --------
 * 13-07-2020      Sumit Swami     Initial Release
 * ----------------------------------------------------------------------------------*/
public with Sharing class ProductWrapper {
    public class product{
        @AuraEnabled public string id{get;set;}
        @AuraEnabled public Id product2Id{get;set;}
        @AuraEnabled public Id priceBookEntryId {get;set;}
        @AuraEnabled public String productName{get;set;}
        @AuraEnabled public String productCode{get;set;}
        @AuraEnabled public String itemCode{get;set;}
        @AuraEnabled public Decimal unitPrice{get;set;}
        @AuraEnabled public Integer quantity{get;set;}
        @AuraEnabled public Boolean isSelected{get;set;}
        @AuraEnabled public Boolean hasMore{get;set;}
        @AuraEnabled public Decimal netTotal{get;set;}
        @AuraEnabled public Decimal totalPrice{get;set;}
        @AuraEnabled public Decimal discount{get;set;}
        @AuraEnabled public Boolean isDefaultInclusion{get; set;}
        @AuraEnabled public Boolean isInclusion{get; set;}
    }
}