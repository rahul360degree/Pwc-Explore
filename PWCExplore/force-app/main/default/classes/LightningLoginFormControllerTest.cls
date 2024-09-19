@IsTest(SeeAllData = true)
public with sharing class LightningLoginFormControllerTest {

 @IsTest
 static void testLoginWithInvalidCredentials() {
  test.startTest();     
  System.assertNotEquals('Argument 1 cannot be null', LightningLoginFormController.login('testUser', 'fakepwd', null));
  Test.stopTest();
 }
   
 @IsTest
 static void LightningLoginFormControllerInstantiation() {
  LightningLoginFormController controller = new LightningLoginFormController();
  System.assertNotEquals(controller, null);
 }

 @IsTest
 static void testIsUsernamePasswordEnabled() {
  System.assertEquals(true, LightningLoginFormController.getIsUsernamePasswordEnabled());
 }

 @IsTest
 static void testIsSelfRegistrationEnabled() {
  System.assertEquals(false, LightningLoginFormController.getIsSelfRegistrationEnabled());
 }

 @IsTest
 static void testGetSelfRegistrationURL() {
  System.assertEquals(null, LightningLoginFormController.getSelfRegistrationUrl());
 }

 @IsTest
 static void testAuthConfig() {
  Auth.AuthConfiguration authConfig = LightningLoginFormController.getAuthConfig();
  System.assertNotEquals(null, authConfig);
 }
 
  static testMethod void isTest(){        
        test.startTest();
        LightningLoginFormController.setExperienceId('');
        test.stopTest();        
    } 
    static testMethod void isTest1(){
        
        test.startTest();
        LightningLoginFormController.setExperienceId(NULL);
        test.stopTest();
        
    }   
}