/**
 * @description       : 
 * @author            : vrajpoot@godrej.com
 * @group             : 
 * @last modified on  : 04-13-2022
 * @last modified by  : vrajpoot@godrej.com
**/
public with sharing class ProductConfig_QuoteJson {
    public class ProductDetails {
        public String productCode;// not required // send blank code
        public String unspscCode;// item code
        public String qty;
        public String mrp;
        public String basic;
        public String discPerc;
        public String remarks;
    }

    public String customerCode;
    public String billingAddress;
    public String deliveryAddress;
    public String customerOrderNumber;
    public String vertical;
    public String branchWarehouse;
    public String customerExpDelDate;
    public String aidNumber;
    public String commentsHO;
    public String commentsMFG;
    public String user;
    public String channel;
    public String sfQuotationID;
    public String sfQuotationPos;
    public String remarks;
    public String deliveryType;
    public List<ProductDetails> productDetails;
    
    public static ProductConfig_QuoteJson parse(String json) {
        return (ProductConfig_QuoteJson) System.JSON.deserialize(json, ProductConfig_QuoteJson.class);
    }

}