/*------------------------------------------------------------------------
 * Author:        Manasi Londhe
 * Company:       Salesforce
 * Description:   Test class for 'CalculateDistance' Apex class
 * Inputs:        NA
 * ---------------------------------------------------------------------------
 * History
 * 13-10-2020      Manasi Londhe     Initial Release
 * ----------------------------------------------------------------------------*/
@istest
public with sharing class CalculateDistanceTest {
    
    @istest private static void distanceShouldBe14() { 
        List<CalculateDistance.LocationInfoWrapper> locationInformationList=getLocationWrapper(18.6011,18.5285,73.7641,73.8744);
        Test.startTest();
        List<Double> distance=CalculateDistance.getDistanceBetweenTwoGeoCodes(locationInformationList);
        Double distance2=(CalculateDistance.getDistance((Double)18.6011,(Double)73.7641,(Double)18.5285,(Double)73.8744)).round();
        Test.StopTest();
        decimal result=distance[0].round();
        System.assertEquals(14,result);
        System.assertEquals(14,distance2);
    }

    @istest private static void distanceShouldBeNull() {
        List<CalculateDistance.LocationInfoWrapper> locationInformationList=getLocationWrapper(null,null,73.7641,73.8744);
        Test.startTest();
        List<Double> distance=CalculateDistance.getDistanceBetweenTwoGeoCodes(locationInformationList);
        Double distance2=CalculateDistance.getDistance(null,null,null,null);
        Test.StopTest();
        System.assertEquals(null,distance[0]);
        System.assertEquals(null,distance2);
    }

    private static List<CalculateDistance.LocationInfoWrapper> getLocationWrapper(Decimal lat1,Decimal lat2,Decimal long1,Decimal long2){
        List<CalculateDistance.LocationInfoWrapper> locationInfos=new List<CalculateDistance.LocationInfoWrapper>(); 
        CalculateDistance.LocationInfoWrapper locationInfo=new CalculateDistance.LocationInfoWrapper();
        locationInfo.currentlatitude=lat1;
        locationInfo.registeredlatitude=lat2;
        locationInfo.currentlongitude=long1;
        locationInfo.registeredlongitude=long2;
        locationInfos.add(locationInfo);
        return locationInfos;
    }
}