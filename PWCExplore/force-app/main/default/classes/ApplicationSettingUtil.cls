/*------------------------------------------------------------------------
Author:        Nupoor Sharma
Company:       Salesforce
Description:   Helper for getting values from Application_Settings__mdt
Inputs:        
Test Class:    MHERentalRenewalBatchTest

History
24-06-2020      Nupoor Sharma     Initial Release
----------------------------------------------------------------------------*/
public class ApplicationSettingUtil {
    
    // a static, final variable that initializes an instance of the class
    // as it's final, it will only be initialized once
    private static final ApplicationSettingUtil instance = new ApplicationSettingUtil();
    
    //the map of application settings
    public Map<String,String> developerNameWithValueMap {get;private set;}
    
    // The constructor is private and initializes the developerNameWithValueMap
    private ApplicationSettingUtil()
    {
        System.Debug('Initializing Application Setting Map');
        developerNameWithValueMap = new Map<String, String>();
     //	List<Application_Settings__mdt> appSettingList = new List<Application_Settings__mdt>([Select Id, DeveloperName, Value__c From Application_Settings__mdt LIMIT 499999]);
            List<Application_Settings__mdt> appSettingList = Application_Settings__mdt.getAll().values();
           for(Application_Settings__mdt setting : appSettingList)
           {
               //developerName as the Key with the corresponding value
               developerNameWithValueMap.put(setting.DeveloperName.toUpperCase(), setting.Value__c);
           }

    }
    
    /* getInstance : 
     * The instance of the class is instantiated as 
     * a final, static variable, 
     * which means that only one instance ever exists. 
     * This method is typically used if the cost of creating 
     * the instance is small.
     */
    public static ApplicationSettingUtil getInstance(){
        // eager load of the class
        return instance;
    }


}