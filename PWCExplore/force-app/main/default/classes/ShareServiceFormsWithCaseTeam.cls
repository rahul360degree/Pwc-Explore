/*------------------------------------------------------------------------
Author:        Nupoor Sharma
Company:       Salesforce
Description:   Shares the Service Forms associated to a Case with the Case Team Members and the Case Owner
			   Also, revokes access from Service Forms by deleting any outdated share records.
Inputs:        
Test Class:    

History
10-12-2020      Nupoor Sharma     Initial Release
----------------------------------------------------------------------------*/
public without sharing class ShareServiceFormsWithCaseTeam {
    
    /*
     * Method : shareForCase
     * Description : Accepts a list of Case records
     * 				 Shares the associated Service Form Records with the Case Owner and Case Team Members
     * 				 Revokes the access of any members who no longer need access to Service Forms
     */
    public static void shareForCase(List<Case> caseList)
    {
        //Step 1 : Get All Case Team members
        list<CaseTeamMember> caseTeamMembers = new List<CaseTeamMember>([SELECT Id, ParentId, MemberId, TeamRole.AccessLevel, TeamTemplateId
                                                                          FROM CaseTeamMember WHERE ParentId IN : caseList]);
        
        //Map with key as caseID and value as list of case team members on that case
        Map<ID, List<CaseTeamMember>> caseID_CTM_Map = new Map<ID, List<CaseTeamMember>>();
        for(CaseTeamMember ctm : caseTeamMembers)
        {
            List<CaseTeamMember> ctmList = new List<CaseTeamMember>();
            if(caseID_CTM_Map.containsKey(ctm.ParentId)){
               ctmList = caseID_CTM_Map.get(ctm.ParentId);
            }
            ctmList.add(ctm);
            caseID_CTM_Map.put(ctm.ParentId, ctmList);
        }
        
        
        //Step 2 : Fetch all Service Forms for the case
        List<Service_Form__c> serviceFormRecords = new List<Service_Form__c>([SELECT Id, OwnerId, Case__c, Case__r.OwnerId 
                                                                              FROM Service_Form__c WHERE Case__c IN :caseList]);
        
        if(!serviceFormRecords.isEmpty())
        {
            //List of share records to be inserted
            List<Service_Form__Share> serviceFormShareList = new List<Service_Form__Share>();
            
            for(Service_Form__c formObj : serviceFormRecords)
            {
                //Step 3 : Add share record for Case Owner
                if(String.valueOf(formObj.Case__r.OwnerId.getsobjecttype()) == 'User'){
                serviceFormShareList.add(ShareServiceFormsWithCaseTeam.createShareRecord(formObj.ID, formObj.Case__r.OwnerId, 'Edit' ));
                }
                
                List<CaseTeamMember> case_ctmList = caseID_CTM_Map.get(formObj.Case__c);
                if(case_ctmList<>NULL && !case_ctmList.isEmpty())
                {
                    //Step 4 : Add share for each case team member
                    for(CaseTeamMember ctm : case_ctmList){
                        if(String.isBlank(ctm.TeamTemplateId)){
                        serviceFormShareList.add(ShareServiceFormsWithCaseTeam.createShareRecord(formObj.ID, ctm.MemberId, ctm.TeamRole.AccessLevel ));
                        }
                    }
                }
            }
            
            //Capture Timestamp
            DateTime shareModTimeStamp = System.now();
            
            //Step 5 : Insert the share records and capture save result
            Database.SaveResult[] shareInsertResult = Database.insert(serviceFormShareList,false);
            
            //Step 6 : Flush outdated share records on Service Forms
            ShareServiceFormsWithCaseTeam.removeOutdatedShareRecords(serviceFormRecords, shareModTimeStamp);

        }
    }
    
    /*
     * Method : createShareRecord
     * Description : Creates a share record for Service Form with rowCause - Case Team
     */
    public static Service_Form__Share createShareRecord(ID parentID, ID userOrGroupID, String accessLevel)
    {
       Service_Form__Share newShare = new Service_Form__Share();
       newShare.ParentId = parentID;
       newShare.UserOrGroupId = userOrGroupID;
       newShare.AccessLevel = accessLevel;
       newShare.RowCause = Schema.Service_Form__Share.RowCause.Case_Team__c;
       return newShare;
    }
    
    /*
     * Method : removeOutdatedShareRecords
     * Description : Deletes the share records for Service Form which are no longer required
     */
    public static void removeOutdatedShareRecords(List<Service_Form__c> serviceForms, DateTime lastMod)
    {
       List<Service_Form__Share> outdatedShareRecords = new List<Service_Form__Share>([SELECT Id, ParentId, UserOrGroupId, AccessLevel, RowCause, LastModifiedDate 
                                                                                       FROM Service_Form__Share 
                                                                                       WHERE ParentId IN: serviceForms
                                                                                       AND LastModifiedDate < :lastMod
                                                                                       AND RowCause = 'Case_Team__c']);
        delete outdatedShareRecords;

    }
    
    @AuraEnabled
    public static String shareCaseForms(String recordId) {
        String returnVal = 'NA';
        ShareServiceFormsWithCaseTeam.shareForCase(new List<Case>{new Case(Id = recordId)});
        returnVal = recordId;
        return returnVal;
    }

    

}