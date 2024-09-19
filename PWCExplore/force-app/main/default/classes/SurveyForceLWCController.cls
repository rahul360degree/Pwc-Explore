public class SurveyForceLWCController 
{
	@AuraEnabled(cacheable=true)
    public static List<Survey_Question__c> getSurveyQuestions(Id surveyId)
        {
            return [SELECT Id, Question__c, Description__c, Choices__c FROM Survey_Question__c WHERE Survey__c =:surveyId];
        }
   
}