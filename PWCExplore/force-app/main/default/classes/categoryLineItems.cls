public class categoryLineItems {
    
 @InvocableMethod(label='getCount')
    Public Static list<list<String>> convertIntegerToString(List<Integer> count){
        Integer loopCount = count[0];
        System.debug('count-------------- ' + count);
        System.debug('loopCount-------------- ' + loopCount);
        list<String> returnValue = new list<String>();
        list<list<String>> returnValueAct = new list<list<String>>();
        for(Integer i=1; i<=loopCount; i++){
            returnValue.add(String.valueOf(i));
        }
        System.debug('returnValue-------------- ' + returnValue);
        returnValueAct.add(returnValue);
        System.debug('returnValueAct-------------- ' + returnValueAct);
        return returnValueAct;
    }

}