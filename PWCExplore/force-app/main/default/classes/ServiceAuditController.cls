public with sharing class ServiceAuditController
{
    // method to fetch current SAR audit type data
    @AuraEnabled(cacheable=true)
    public static String getSARAuditType(Id sarId)
    {
        Service_Audit_Report__c SARrecord = [SELECT Id, Audit_Type__c FROM Service_Audit_Report__c WHERE Id = :sarId];
        String SARAuditType = SARrecord.Audit_Type__c;
        System.debug('SARAuditType ' + SARAuditType);
        return SARAuditType;
    }
    
    // method to fetch current user profile
    @AuraEnabled(cacheable=true)
    public static String getUserProfile() 
    {
        Id userId = UserInfo.getUserId();
        String profileName = [SELECT Profile.Name FROM User WHERE Id =: userId].Profile.Name;
        return profileName;
    }
    
    // method to get excludeObservation
    @AuraEnabled(cacheable=true)
    public static Boolean getExcludeObservation(Id sarliId)
    {
        Service_Audit_Report_Line_Item__c SARLIRecord = [SELECT Id, Exclude_Observation__c FROM Service_Audit_Report_Line_Item__c WHERE Id = :sarliId];
        Boolean excludeObservation = SARLIRecord.Exclude_Observation__c;
        System.debug('is the form submitted ' + excludeObservation);
            
        return excludeObservation;
    }
    // method to fetch OA data
    @AuraEnabled(cacheable=true)
    public static List<Observation_Area__c> getOAData(Id sarId) 
    {
        return [SELECT Id, Percentage_Achieved__c, Name, Status__c FROM Observation_Area__c WHERE Service_Audit_Report__c = :sarId];
    }
    
    // method to fetch observation question choices in case of call audit form
    @AuraEnabled(cacheable=true)
    public static List<Service_Audit_Report_Line_Item__c> getOQChoices(Id sarId) 
    {
        List<Service_Audit_Report_Line_Item__c> SARLIId_OQ_Records = [SELECT Id, Response__c, Observation_Question_LU__r.Question_Text__c, Observation_Question_LU__r.Choices__c, Observation_Question_LU__r.Additional_Details_Required__c FROM Service_Audit_Report_Line_Item__c WHERE Service_Audit_Report__r.Id = :sarId];
        return SARLIId_OQ_Records;
    }
    
    
    /*@AuraEnabled
    public static void updateResponseRequiredOnServiceAudit(Id sarliId)
    {
        Service_Audit_Report_Line_Item__c SARLIRecord = [SELECT Id, Response_Required__c, Observation_Area__r.Service_Audit_Report__c FROM Service_Audit_Report_Line_Item__c WHERE Id = :sarliId];
        if(SARLIRecord.Response_Required__c == true)
        {
            Service_Audit_Report__c SARRecord = [SELECT Id, Response_Required__c FROM Service_Audit_Report__c WHERE Id =: SARLIRecord.Observation_Area__r.Service_Audit_Report__c];
            SARRecord.Response_Required__c = true;
            update SARRecord;
        }
    }*/
        
    @InvocableMethod(label='Update Response Required On Service Audit')
    public static void updateResponseRequiredOnServiceAudit(List<Id> sarId)
    {
        List<Service_Audit_Report_Line_Item__c> SARLIRecords = [SELECT Id, Response_Required__c, Status__c, Observation_Area__r.Service_Audit_Report__c FROM Service_Audit_Report_Line_Item__c WHERE Observation_Area__r.Service_Audit_Report__c IN :sarId AND Response_Required__c = true];
        Service_Audit_Report__c SARRecord = [SELECT Id, Response_Required__c FROM Service_Audit_Report__c WHERE Id IN :sarId];
        
        if(!SARLIRecords.isEmpty())
        {
            SARRecord.Response_Required__c = true;
            for (Service_Audit_Report_Line_Item__c SARLIRecord : SARLIRecords)
            {
                SARLIRecord.Status__c = 'Open with ASP';
            	update SARLIRecord;
            }
            
            
        }
        else
        {
            SARRecord.Response_Required__c = false;
        }
        update SARRecord;
        
    }

	  
    
    // method to check if form is submitted in case of call audit form
    @AuraEnabled(cacheable=true)
    public static Boolean getFormSubmitted(Id sarId)
    {
        Service_Audit_Report__c SARRecord = [SELECT Id, Submitted__c FROM Service_Audit_Report__c WHERE Id = :sarId];
        Boolean formSubmitted = SARRecord.Submitted__c;
        System.debug('is the form submitted ' + formSubmitted);
            
        return formSubmitted;
    }
    
    // method to get parent OAId from SARLIId
    @AuraEnabled(cacheable=true)
    public static Id getOAIdFromSARLIId (Id sarliId)
    {
        Service_Audit_Report_Line_Item__c SARLIRecord = [SELECT Id, Observation_Area__c FROM Service_Audit_Report_Line_Item__c WHERE Id = :sarliId];
       	Id OAId = SARLIRecord.Observation_Area__c;
        return OAId;
    }
    
    // method to update call audit form records and also change form -> submitted
    @AuraEnabled
    public static void updateCallAuditForm(List<Service_Audit_Report_Line_Item__c> updatedSARLIRecords, List<Service_Audit_Report__c> updateFormSubmitted)
    {
            System.debug('updated SARLI Records' + updatedSARLIRecords);
            update updatedSARLIRecords;
        
        	System.debug('update SAR submitted' + updateFormSubmitted);
            update updateFormSubmitted;
    }
    
    // method to fetch updated SARLI by each OA
    @AuraEnabled
    public static Map<Id, List<Service_Audit_Report_Line_Item__c>> getSARLINew(Id oaId)
    {
        Map<Id, List<Service_Audit_Report_Line_Item__c>> OAId2SARLIRecord = new Map<Id, List<Service_Audit_Report_Line_Item__c>>();
        List<Service_Audit_Report_Line_Item__c> SARLIRecords = [SELECT Id, Achieved_Score__c, Recommendation__c, Observation_Details__c, Exclude_Observation__c, Status__c, Response_Required__c, Observation_Area__c, Observation_Area_S_No__c, Observation_Question_S_No__c FROM Service_Audit_Report_Line_Item__c WHERE Observation_Area__c = :oaId ORDER BY Observation_Area_S_No__c ASC, Observation_Question_S_No__c ASC];
    	for (Service_Audit_Report_Line_Item__c SARLIRecord : SARLIRecords)
        {
            if (!OAId2SARLIRecord.containsKey(SARLIRecord.Observation_Area__c))
            {
                OAId2SARLIRecord.put(SARLIRecord.Observation_Area__c, new List<Service_Audit_Report_Line_Item__c>());
            }

            OAId2SARLIRecord.get(SARLIRecord.Observation_Area__c).add(SARLIRecord);
        }
        //System.debug('OAId2SARLIRecord after' + OAId2SARLIRecord);
        return OAId2SARLIRecord;
    }
    // method to fetch SARLI data by each OA
    @AuraEnabled
    public static Map<Id, List<Service_Audit_Report_Line_Item__c>> getSARLIRecordsByOAIds (List<Id> oaIds)
    {
        Map<Id, List<Service_Audit_Report_Line_Item__c>> OAId2SARLIRecord = new Map<Id, List<Service_Audit_Report_Line_Item__c>>();
        System.debug('OAId2SARLIRecord before' + OAId2SARLIRecord);
        List<Service_Audit_Report_Line_Item__c> SARLIRecords = [SELECT Id, Maximum_Score__c, Achieved_Score__c, Observation_Details__c, Recommendation__c, Exclude_Observation__c, Corrective_Actions__c, Preventive_Actions__c, Status__c, Observation_Area__c, Observation_Area_S_No__c, Observation_Question_S_No__c, Response_Required__c, Observation_Question_LU__r.Question_Text__c FROM Service_Audit_Report_Line_Item__c WHERE Observation_Area__c IN :oaIds ORDER BY Observation_Area_S_No__c ASC, Observation_Question_S_No__c ASC];
        //System.debug('SARLI Records' + SARLIRecords);
        for (Service_Audit_Report_Line_Item__c SARLIRecord : SARLIRecords)
        {
            if (!OAId2SARLIRecord.containsKey(SARLIRecord.Observation_Area__c))
            {
                OAId2SARLIRecord.put(SARLIRecord.Observation_Area__c, new List<Service_Audit_Report_Line_Item__c>());
            }

            OAId2SARLIRecord.get(SARLIRecord.Observation_Area__c).add(SARLIRecord);
        }
        //System.debug('OAId2SARLIRecord after' + OAId2SARLIRecord);
        return OAId2SARLIRecord;
    }
    
    // method to link all the contentDocuments with the OA Id by creating a contentDocumentLink record
    @AuraEnabled
    public static void linkUploadedDocumentsToOA(Id ObservationAreaId, List<Id> uploadedDocumentIds)
    {
    	List<ContentDocumentLink> contentDocumentLinks = new List<ContentDocumentLink>();
        
        for (Id uploadedDocumentId : uploadedDocumentIds)
        {
            ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
            contentDocumentLink.ContentDocumentId = uploadedDocumentId;
            contentDocumentLink.LinkedEntityId = ObservationAreaId;
            contentDocumentLink.ShareType = 'C';
            contentDocumentLink.Visibility = 'AllUsers';
            contentDocumentLinks.add(contentDocumentLink);
        }
        insert contentDocumentLinks;
    }
    
    // method to get all contentDocuments for a particular OA
    @AuraEnabled(cacheable=true)
    public static Map<Id, List<ContentDocument>> getDocumentRecordsByOAIds (List<Id> oaIds)
    {
       Map<Id, List<ContentDocument>> OAId2ContentDocument = new Map<Id, List<ContentDocument>>();
       List<ContentDocumentLink> contentDocumentLinks = [SELECT ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId IN :oaIds];
       
       Map<Id, ContentDocument> contentDocumentId2ContentMap = new Map<Id, ContentDocument>();
        
       for (ContentDocumentLink link : ContentDocumentLinks)
       {
           contentDocumentId2ContentMap.put(link.ContentDocumentId, null);
       }
        
        contentDocumentId2ContentMap.putAll([SELECT Id, Title, FileExtension, CreatedBy.Name FROM ContentDocument WHERE Id IN :contentDocumentId2ContentMap.keySet()]);
        
        for (ContentDocumentLink link : contentDocumentLinks)
        {
            if(!OAId2ContentDocument.containsKey(link.LinkedEntityId))
            {
                OAId2ContentDocument.put(link.LinkedEntityId, new List<ContentDocument>());
            }
            
            ContentDocument cd = contentDocumentId2ContentMap.get(link.ContentDocumentId);
            if (cd != null)
            {
                OAId2ContentDocument.get(link.LinkedEntityId).add(cd);
            }
        }
        
        return OAId2ContentDocument;
    }
    
    // method to update SARLI records --- can be clubbed with call audit method to update SARLI records?
    @AuraEnabled(cacheable=true)
    public static void updateSARLIRecords(List<Service_Audit_Report_Line_Item__c> updatedRecords) {
        try {
            update updatedRecords;
            
            //this function should run only when achieved score for any SARLI changes for limiting only to necessary transactions.
            //System.debug('test');
            //updateOAPercentageAchieved(updatedRecords);
            //
            
        }
         catch (Exception e) 
        {
            throw new AuraHandledException('Error updating records: ' + e.getMessage());
        }
        
    }
    
    // method to update SARLI and OA percentages when the record is submitted
    @AuraEnabled
    public static void updatePercentageAchieved(Id sarliId)
    {
          
        // updating percentage for line item.
        
        Service_Audit_Report_Line_Item__c updateSARLIRecord = [SELECT Id, Achieved_Score__c, Maximum_Score__c, Percentage_Achieved__c, Observation_Area__c, Exclude_Observation__c FROM Service_Audit_Report_Line_Item__c WHERE Id = :sarliId];
        System.debug(updateSARLIRecord);
        Decimal updatedPercentage = (updateSARLIRecord.Achieved_Score__c / updateSARLIRecord.Maximum_Score__c) * 100;
        updateSARLIRecord.Percentage_Achieved__c = updatedPercentage.setScale(2);
        update updateSARLIRecord;
        
        
        // updating percentage for OA.
       
        Id updateOAId = updateSARLIRecord.Observation_Area__c;
        //System.debug(updateOAId);
        Decimal runningPercentageSum = 0;
        List<Decimal> achievedScores = new List<Decimal>();
        
        
        Observation_Area__c updateOARecord = [SELECT Id, Total_Maximum_Score__c, Percentage_Achieved__c FROM Observation_Area__c WHERE Id =:updateOAId];
        List<Service_Audit_Report_Line_Item__c> otherSARLIRecords = [SELECT Id, Achieved_Score__c, Maximum_Score__c, Observation_Area__c, Exclude_Observation__c FROM Service_Audit_Report_Line_Item__c WHERE Id != :sarliId AND Observation_Area__c =:updateOAId];
        
        Decimal TotalMaximumScore = updateOARecord.Total_Maximum_Score__c;
        
        if(updateSARLIRecord.Exclude_Observation__c == false)
        {
            System.debug('excludeobservation false' + updateSARLIRecord.Exclude_Observation__c);
            achievedScores.add(updateSARLIRecord.Achieved_Score__c);
        }
        else if(updateSARLIRecord.Exclude_Observation__c == true)
        {
            System.debug('excludeobservation true' + updateSARLIRecord.Exclude_Observation__c);
            TotalMaximumScore = TotalMaximumScore - updateSARLIRecord.Maximum_Score__c;
        }
        
        for (Service_Audit_Report_Line_Item__c otherSARLIRecord : otherSARLIRecords)
        {
            if (otherSARLIRecord.Exclude_Observation__c == false)
            {
                achievedScores.add(otherSARLIRecord.Achieved_Score__c);
            }
            else if(otherSARLIRecord.Exclude_Observation__c == true)
            {
                TotalMaximumScore = TotalMaximumScore - otherSARLIRecord.Maximum_Score__c;
            }
            
        }
        for (Decimal achievedScore: achievedScores)
        {
            if (achievedScore == null)
            {
                runningPercentageSum += 0;
            }
            else
            {
                runningPercentageSum += achievedScore/TotalMaximumScore;
            }
            
            Decimal percentageAchieved = runningPercentageSum*100;
       		updateOARecord.Percentage_Achieved__c = percentageAchieved.setScale(2);
        
       		update updateOARecord;
        }
        
        
        
    }
    /*@AuraEnabled(cacheable=true)
    public static void updateOAPercentageAchieved(List<Service_Audit_Report_Line_Item__c> updatedRecords)
    {
        List<Id> updatedRecordIds = new List<Id>();
        List<Decimal> achievedScores = new List<Decimal>();       
        Decimal runningPercentageSum = 0;
        
        for (Service_Audit_Report_Line_Item__c updatedRecord: updatedRecords)
        {
            Id updateSARLIRecordId = updatedRecord.Id;
            
            updatedRecordIds.add(updateSARLIRecordId);
            achievedScores.add(updatedRecord.Achieved_Score__c);
            
			System.debug(updatedRecordIds);
            System.debug(achievedScores);
            
            Service_Audit_Report_Line_Item__c updateSARLIRecord = [SELECT Id, Name, Percentage_Achieved__c, Maximum_Score__c FROM Service_Audit_Report_Line_Item__c WHERE Id =:updateSARLIRecordId];
        	
            System.debug(updateSARLIRecord);
            
            Decimal SARLIpercentageAchieved = (updatedRecord.Achieved_Score__c / updateSARLIRecord.Maximum_Score__c) * 100;
            //updateSARLIRecord.Percentage_Achieved__c = SARLIpercentageAchieved.setScale(2);
            update updateSARLIRecord;
        }
        //System.debug('updatedRecordIds' + updatedRecordIds);
        //System.debug('achievedScores' + achievedScores);
        //System.debug('updatedRecords' + updatedRecords);
        
        
        // need to include logic to update percentages for each SARLI based on the updated Records. for loop to run through them
        // fetch the achieved score and divide it by maximum score for that SARLI id and update.
        // 
        // 
        
        
        Id first_SARLI_Id = updatedRecords[0].Id;
        
        Service_Audit_Report_Line_Item__c first_SARLI_record = [SELECT Id, Observation_Area__c FROM Service_Audit_Report_Line_Item__c WHERE Id =:First_SARLI_Id];
        Id updateOA_Id = first_SARLI_record.Observation_Area__c;
        
        Observation_Area__c OA_record = [SELECT Id, Total_Maximum_Score__c FROM Observation_Area__c WHERE Id =:updateOA_Id];
        Decimal totalMaximumScore = OA_record.Total_Maximum_Score__c;
        
        //System.debug('updateOA_Id' + updateOA_Id);
        
        List<Service_Audit_Report_Line_Item__c> otherRecords = [SELECT Id, Achieved_Score__c, Observation_Area__c FROM Service_Audit_Report_Line_Item__c WHERE Id NOT IN :updatedRecordIds AND Observation_Area__c = :updateOA_Id];
        
        //System.debug(otherRecords);
        for (Service_Audit_Report_Line_Item__c otherRecord: otherRecords)
        {
            achievedScores.add(otherRecord.Achieved_Score__c);
        } 
        
        for (Decimal achievedScore: achievedScores)
        {
            if (achievedScore == null)
            {
                runningPercentageSum += 0;
            }
            else
            {
                runningPercentageSum += achievedScore/totalMaximumScore;
            }
            
        }
        
        //System.debug(runningPercentageSum); 
        
        Observation_Area__c OArecordChange = [SELECT Id, Percentage_Achieved__c FROM Observation_Area__c WHERE Id = :updateOA_Id];
        
        Decimal percentageAchieved = runningPercentageSum*100;
       	OArecordChange.Percentage_Achieved__c = percentageAchieved.setScale(2);
        
        update OArecordChange;
    }*/
    
    
}