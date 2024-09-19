public without sharing class QueryBuilder {
    
    //Object Name not provided Error
    private static string OBJECT_NAME_MISSING = 'Object name not provided';
    //Fields missing
    private static String OBJECT_FIELDS_MISSING = 'Fields to query are missing';
    //Fields to skip
    private static set<String> FIELDS_TO_SKIP = new set<String> {'LastReferencedDate', 'LastViewedDate','LastPasswordChangeDate'};

    /*
	* Description: Method to build query based on SObject Name, Where Clause
	* Param: Sobject Name, Where Clause and flag to skip Long Text Fields.
	* Sample Call: QueryBuilder.build('Account', 'Id = \'001XXXXXXXX\'', false);
	*/
    public static String build(String sObjectName, String whereClause, boolean skipLongTextFields) {
        if(String.isBlank(sObjectName)) throw new QueryBuilderException(OBJECT_NAME_MISSING);
        set<String> fields = getSObjectFields(sObjectName, skipLongTextFields);
        whereClause = (!String.isBlank(whereClause) ? whereClause : '').remove('WHERE').trim();
        return 'SELECT ' + String.join(new List<String>(fields), ',') + ' FROM ' + sObjectName + (!String.isBlank(whereClause) ? (' WHERE ' + whereClause) : '');
    }

    /*
	* Description: Method to build query based on SObject Name, field set and Where Clause
	* Param: Sobject Name, Set of fields to query and Where Clause
	* Sample Call: QueryBuilder.build('Account', new set<String> {'Name', 'ParentId'}, 'Id = \'001XXXXXXXX\'');
	*/
    public static String build(String sObjectName, set<String> fieldsToQuery, String whereClause) {
        if(String.isBlank(sObjectName)) throw new QueryBuilderException(OBJECT_NAME_MISSING);
        if(fieldsToQuery == null) throw new QueryBuilderException(OBJECT_FIELDS_MISSING);
        if(fieldsToQuery.isEmpty()) fieldsToQuery.add('Id');
        whereClause = (!String.isBlank(whereClause) ? whereClause : '').removeStart('WHERE').trim();
        return 'SELECT ' + String.join(new List<String>(fieldsToQuery), ',') + ' FROM ' + sObjectName + (!String.isBlank(whereClause) ? (' WHERE ' + whereClause) : '');
    }

    /*
	* Description: Method to get the fields from sObject
	* Param: Sobject Name, flag to indicate whether to skip longTextFields or not
	* Sample Call: QueryBuilder.getSObjectFields('Account', false);
	*/
    public static Set<String> getSObjectFields(String sObjectName, boolean skipLongTextFields) {
        if(String.isBlank(sObjectName)) throw new QueryBuilderException(OBJECT_NAME_MISSING);
        set<String> fields = new set<String>();
        SObjectType objType = Schema.getGlobalDescribe().get(sObjectName);
        Map<String, Schema.SObjectField> mfields = objType.getDescribe().fields.getMap();
        for(Schema.SObjectField f : mfields.values()) {
            //Skip the Long Text Area Fields.
            if(skipLongTextFields && f.getDescribe().getType() == DisplayType.TextArea) continue; 
            if(FIELDS_TO_SKIP.contains(f.getDescribe().getName())) continue;
            if(!f.getDescribe().isAccessible() && !sObjectName.contains('__mdt')) continue;
            fields.add(f.getDescribe().getName());
        }        
        return fields;
    }   

    /*Custom Exception Class to throw the query builder related exceptions*/
    public class QueryBuilderException extends Exception {}
}