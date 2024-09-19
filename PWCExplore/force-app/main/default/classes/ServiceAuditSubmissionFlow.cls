public class ServiceAuditSubmissionFlow 
{
	@InvocableMethod(label='Check if Service Audit Report Line Items are all filled')
    public static List<Service_Audit_Report_Line_Item__c> checkIfSARLIFilled(List<Observation_Area__c> OARecords)
    {
        Boolean isASPAudit;
        
        // essentially getting only one OA to work with
        List <Id> OAIds = new List<Id>();
            for (Observation_Area__c OARecord : OARecords)
            {
                OAIds.add(OARecord.Id); 
                if (OaRecord.Service_Audit_Report__r.Audit_Type__c == 'ASP Audit')
                {
					isASPAudit = true;
                }
                else if (OaRecord.Service_Audit_Report__r.Audit_Type__c != 'ASP Audit')
                {
                    isASPAudit = false;
                }
            }  
 
        List<Service_Audit_Report_Line_Item__c> unfilledSARLIRecords = new List<Service_Audit_Report_Line_Item__c>();
        List<Service_Audit_Report_Line_Item__c> SARLIRecords = new List<Service_Audit_Report_Line_Item__c>();
        
        // getting all SARLI from that one OA
        if (isASPAudit)
        {
            SARLIRecords = [SELECT Id, Achieved_Score__c, Recommendation__c, Observation_Details__c, Exclude_Observation__c, Observation_Area__c FROM Service_Audit_Report_Line_Item__c WHERE Observation_Area__c IN :OAIds ];
        }
        else if (!isASPAudit)
        {
            SARLIRecords = [SELECT Id, Recommendation__c, Observation_Details__c, Observation_Area__c FROM Service_Audit_Report_Line_Item__c WHERE Observation_Area__c IN :OAIds ];
        }
        
        
        // going through all SARLI in 1 OA and if there's even one field that's blank or null, then returns the unfilledSARLIRecords
        for (Service_Audit_Report_Line_Item__c SARLIRecord : SARLIRecords)
        {
            if (isASPAudit)
            {
				if(SARLIRecord.Exclude_Observation__c == true)
            	{
                	continue;
            	}
                else if(SARLIRecord.Achieved_Score__c == null || String.isBlank(SARLIRecord.Recommendation__c) || String.isBlank(SARLIRecord.Observation_Details__c))
                {
                    System.debug('is the string blank?' + String.isBlank(SARLIRecord.Recommendation__c));
                    unfilledSARLIRecords.add(SARLIRecord);
                    return unfilledSARLIRecords;
                }
            }
            else if(!isASPAudit)
            {
                if(String.isBlank(SARLIRecord.Recommendation__c) || String.isBlank(SARLIRecord.Observation_Details__c))
                {
                    unfilledSARLIRecords.add(SARLIRecord);
                    return unfilledSARLIRecords;
                }
            }
        }
        return null;
    }  
}