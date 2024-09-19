@isTest
public with sharing class SplitStringForFlowTest {
    @isTest
    public static void testStringSplit() {
        Test.startTest();
        SplitStringForFlow.getStringList(new List<String>{'A;B'});
        Test.stopTest();
    }
}