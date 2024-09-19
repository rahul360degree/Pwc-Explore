public with sharing class SplitStringForFlow {
    @InvocableMethod(label='Split a comma separated string')
    public static List<List<String>> getStringList(List<String> inputString){
        List<List<String>> all = new List<List<String>>();
        all.add(inputString[0].split(';'));
        return all;
    }
}