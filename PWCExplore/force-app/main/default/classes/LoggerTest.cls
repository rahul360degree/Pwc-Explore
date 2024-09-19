@isTest
public class LoggerTest {

    @isTest
    private static void testLogError(){
        test.startTest();
        try{
            Integer i = 1/0;
        }catch(Exception ex){
        	Logger.logError('teset', 'teste', '', ex);
            System.assert(ex.getMessage() != null);
        }
        test.stopTest();
    }
    
    @isTest
    private static void testLogError1(){
        test.startTest();
        try{
        	Integer i = 1/0;
        }catch(Exception ex){
        	Logger.logError('tests', 'test', 'test1', '', ex);   
            System.assert(ex.getMessage() != null);
        }
        test.stopTest();
    }
    
    @isTest
    private static void testLogError2(){
        test.startTest();
        try{
        	Integer i = 1/0;
        }catch(Exception ex){
        	Logger.logError('tests', 'test1', '', ex, 'P1');   
            System.assert(ex.getMessage() != null);
        }
        test.stopTest();
    }
    
    @isTest
    private static void testLogError3(){
        test.startTest();
        try{
        	Integer i = 1/0;
        }catch(Exception ex){
        	Logger.logError('tests', 'testLogError3', ex.getMessage());   
            System.assert(ex.getMessage() != null);
        }
        test.stopTest();
    }
    
    @isTest
    private static void testlogDebugInfo(){
        test.startTest();
        	list<Quote> i = new List<Quote>();
        	Logger.logDebugInfo('LoggerTest', 'testlogDebugInfo', null,i);   
        test.stopTest();
    }
}