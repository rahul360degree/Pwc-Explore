public with sharing class SObjectMapperConfigurator {
    public String metadataName;
    public Map<String,String> objetNameVsWhereClause;
    public String targetObjectName;
    public Map<String,Object> defaultValues;
    public String sourceObjectName;
    public String sourceObjectUniqueField;
    public String quoteRecordTypeDeveloperName;
    public String transactionType;
    
    public SObjectMapperConfigurator(){}
}