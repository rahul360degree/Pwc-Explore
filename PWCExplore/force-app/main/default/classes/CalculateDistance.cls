/*------------------------------------------------------------------------
 * Author:        Manasi Londhe
 * Company:       Salesforce
 * Description:   Helper class to calculate Distance between two geo locations
 * Inputs:        NA
 * Test Class:    CalculateDistanceTest
 * ---------------------------------------------------------------------------
 * History
 * 13-10-2020      Manasi Londhe     Initial Release
 * ----------------------------------------------------------------------------*/

public with sharing class CalculateDistance {

    /*------------------------------------------------------------------------
        * Author:        Manasi Londhe
        * Company:       Salesforce
        * Description:   invocable method to calculate Distance between two geo locations
        * Inputs:        LocationInfoWrapper
        * Test Class:    
        * ---------------------------------------------------------------------------
        * History
        * 13-10-2020      Manasi Londhe     Initial Release
    * ----------------------------------------------------------------------------*/
    @InvocableMethod
    public static List<Double> getDistanceBetweenTwoGeoCodes(List<LocationInfoWrapper> LocationInformation){
        Double lat1;
        Double long1;
        Double lat2;
        Double long2;
        for(LocationInfoWrapper info:LocationInformation){
            lat1=info.currentlatitude;
            long1=info.currentlongitude;
            lat2=info.registeredlatitude;
            long2=info.registeredlongitude;
        }
        Double dist;
        if(lat1!=null && long1!=null && lat2!=null && long2!=null)
            dist=Location.getDistance(Location.newInstance(lat1,long1),Location.newInstance(lat2,long2),'km');
        return new List<Double>{dist};
    }
        
    public class LocationInfoWrapper{
        @invocablevariable
        public Double currentlatitude;
        @invocablevariable
        public Double currentlongitude;
        @invocablevariable
        public Double registeredlatitude;
        @invocablevariable
        public Double registeredlongitude;
    }

    /*------------------------------------------------------------------------
        * Author:        Manasi Londhe
        * Company:       Salesforce
        * Description:   AuraEnabled method to calculate Distance between two geo locations
        * Inputs:        Start of Day and End of Day Geolocaitons.
        * Test Class:    
        * ---------------------------------------------------------------------------
        * History
        * 11-11-2020      Manasi Londhe     Initial Release
    * ----------------------------------------------------------------------------*/
    @AuraEnabled(cacheable=true)
    public static Double getDistance(Double startOfDayLatitude,Double startOfDayLongitude,Double endOfDayLatitude,Double endOfDayLongitude){
        Double distance;
        if(startOfDayLatitude!=null && startOfDayLongitude!=null && endOfDayLatitude!=null && endOfDayLongitude!=null){
            distance=Location.getDistance(Location.newInstance(startOfDayLatitude,startOfDayLongitude),Location.newInstance(endOfDayLatitude,endOfDayLongitude),'km');
        }
        return distance;
    }

}