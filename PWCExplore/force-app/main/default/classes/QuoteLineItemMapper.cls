public with sharing class QuoteLineItemMapper {
    public String id {get; set;}
    public String name {get; set;}
    public Integer available_quantity {get; set;}
    public Integer order_quantity {get; set;}
    public String description {get; set;}
    public String item_code {get; set;}
    public String search_key_II {get; set;} //Added by Rohit Jadhav for Locks B2C ISTD
}