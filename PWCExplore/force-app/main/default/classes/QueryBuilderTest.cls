@isTest
private class QueryBuilderTest {
    
    //Check for build method to skip textarea field in query
    @isTest private static void buildSkipTextAreaTest(){
        String query = QueryBuilder.build(GlobalConstants.ORDER_SOBJECT_API_NAME,'',true);
        System.assertEquals(false, query.contains('Description'));
    }

    //Check for build method to include textarea field in query
    @isTest private static void buildDoNotSkipTextAreaTest(){
        String query = QueryBuilder.build(GlobalConstants.ORDER_SOBJECT_API_NAME,'',false);
        System.assertEquals(true, query.contains('Description'));
    }

    //Check for build method to query only requested field
    @isTest private static void buildFieldsToQueryTest(){
        Set<String> fieldsToQuery = new Set<String>();
        fieldsToQuery.add('AccountId');
        String query = QueryBuilder.build(GlobalConstants.ORDER_SOBJECT_API_NAME,fieldsToQuery,'');
        System.assertEquals(true,query.contains('AccountId'));
    }
    
    //Check for build method to not query other than requested field
    @isTest private static void buildFieldsNoTToQueryTest(){
        Set<String> fieldsToQuery = new Set<String>();
        fieldsToQuery.add('AccountId');
        String query = QueryBuilder.build(GlobalConstants.ORDER_SOBJECT_API_NAME,fieldsToQuery,'');
        System.assertEquals(false,query.contains('Approval_Status__c'));
    }
}