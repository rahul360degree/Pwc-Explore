trigger CheckPoorCSATFeedbackForSSD on SurveyQuestionResponse__c (after insert) 
{
    // this is the guetsUserId for the customer filling in the form on the GNB CSAT Survey Experience Cloud site - hardcoded
    Id guestUserId = '005C4000002iswPIAQ';
   
    List<SurveyQuestionResponse__c> sqrList = new List<SurveyQuestionResponse__c>();
    for (SurveyQuestionResponse__c sqr : Trigger.new)
    {
        sqrList.add(sqr);
    }
    
    System.debug('sqrList ' + sqrList);
   
    Id surveyTakerId = sqrList[0].SurveyTaker__c;
    SurveyTaker__c surveyTaker = [SELECT Id, User__c, Case__c FROM SurveyTaker__c WHERE Id = :surveyTakerId];
    Case SSD_Case = [SELECT Id, RecordTypeId, Poor_Response_CSAT__c FROM Case WHERE Id =:surveyTaker.Case__c];
    
    System.debug('surveyTaker ' + surveyTaker);
    
    // check if a guest user has responded and it's an SSD service request
    // 
    // SSD Service Request record typeid = 012C4000000ZsqL
    if (surveyTaker.User__c == guestUserId && SSD_Case.RecordTypeId == '012C4000000ZsqL')
    {
        //List<SurveyQuestionResponse__c> sqrList = [SELECT Id, Response__c, SurveyTaker__c FROM SurveyQuestionResponse__c WHERE SurveyTaker__c = :surveyTakerId];
        //System.debug('sqrList' + sqrList);
        
        Integer totalScore = 0;
            
        for (SurveyQuestionResponse__c sqr : sqrList)
        {
            try
            {
                // if the response can be converted into an integer, add it to the total score
				Integer responseInt = Integer.valueOf(sqr.Response__c);
                totalScore += responseInt;
            }
            catch (Exception e)
            {
                // otherwise continue
                continue;
            }
            
            
        }
        
        Decimal aggregateScore = (totalScore / sqrList.size());
        
        System.debug('Aggregate Score ' + aggregateScore); 
        // poor feedback
        if (aggregateScore <= 8.0)
        {
            
            
            // update the poor response to true
    		SSD_Case.Poor_Response_CSAT__c = true;
            
            update SSD_Case;
        }
    }
	
}