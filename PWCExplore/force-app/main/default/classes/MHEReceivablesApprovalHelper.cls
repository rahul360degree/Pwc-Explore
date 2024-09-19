/*------------------------------------------------------------------------
 * Author:        Shailja Mishra
 * Company:       Salesforce
 * Description:   Helper class to handle MHE Receivable Approvals
 *                This class is called from flow
 * Inputs:        NA
 * Test Class:    MHEReceivableApprovalHelperTest
 * ---------------------------------------------------------------------------
 * History
 * 22-10-2020      Shailja Mishra     Initial Release
 * ----------------------------------------------------------------------------*/
public with sharing class MHEReceivablesApprovalHelper {
    //Write Off Receivables Approval Process LOB
    public static Map<String, String> lobVsUserId = new Map<String, String>();
    public static Map<String, String> checkerLobVsUserId = new Map<String, String>();
    
    /*------------------------------------------------------------------------
      Author:        Shailja Mishra
      Company:       Salesforce
      Description:   Responsible for populating Approval Level fields based on Persona
      Inputs:        NA
      Test Class:    MHEReceivableApprovalHelperTest
    ---------------------------------------------------------------------------
      History
      22-10-2020      Shailja Mishra     Initial Release
    ----------------------------------------------------------------------------*/
    @InvocableMethod
    public static void setFieldValues(List<WriteOffReceivableWrapper> inputs){
        List<Billed_Sales_Outstandings__c> receivables = new List<Billed_Sales_Outstandings__c>();
        Set<Id> userIds = new Set<Id>();
        Map<Id, User> idVsUser = new Map<Id, User>();
        Map<Id, String> bcCodes = new Map<Id, String>();
        Set<Id> receivableIds = new Set<Id>();
        for(WriteOffReceivableWrapper wrapper : inputs){
            userIds.add(wrapper.receivableRecord.OwnerId);
            receivableIds.add(wrapper.receivableRecord.Id);
        }
        
        for (Receivable__c each : [SELECT Id, BC_Code__c, Invoice__c FROM Receivable__c WHERE Invoice__c IN :receivableIds]) {
           bcCodes.put(each.Invoice__c, each.BC_Code__c);
        }
        
        //get Metadata records based on LOB
        List<Application_Settings__mdt> settings = getSettings();
        //Get LOB Name Vs LOB Head's UserId
        lobVsUserId = getLobVsUserIds(settings);
        Map<Id, User> lobHeadIdVsUser = new Map<Id, User>();
        Set<Id> lobHeadUserIds = new Set<Id>((List<Id>)lobVsUserId.values());
        //Get LOB Head Vs user record to fetch LOB head's manager
        lobHeadIdVsUser = getUsers(lobHeadUserIds);
        //Get LOB Name Vs Chekcer's UserId
        checkerLobVsUserId = getCheckerLobVsUserId(settings);
        idVsUser = getUsers(userIds);
        if(!idVsUser.isEmpty()){
            for(WriteOffReceivableWrapper wrapper : inputs){
                Id userId = wrapper.receivableRecord.OwnerId;
                Billed_Sales_Outstandings__c rc = new Billed_Sales_Outstandings__c();
                if(idVsUser.containsKey(userId)){
                    rc.Id = wrapper.receivableRecord.Id;
                    // populate Direct Manager
                    rc.Approver_1__c = idVsUser.get(userId).ManagerId;
                    Id managerManagerId = idVsUser.get(userId).Manager.ManagerId;
                    // if Manager.Manager contains Region then populate Level2 Manager as Manager.ManagerId else populate as Manager.Manager.ManagerId 
                    rc.Approver_2__c = (managerManagerId != null && idVsUser.get(userId).Manager.Manager.Persona__c != null && idVsUser.get(userId).Manager.Manager.Persona__c.contains('Region')) ? managerManagerId : idVsUser.get(userId).Manager.Manager.ManagerId;
                    
                    String bcCode = bcCodes.get(rc.Id);
                    
                    if (String.isNotBlank(bcCode) && GlobalConstants.BC_CODE_VS_LOB.containsKey(bcCode)) {
                        if(checkerLobVsUserId.containsKey(GlobalConstants.BC_CODE_VS_LOB.get(bcCode))){
                           rc.Approver_3__c = checkerLobVsUserId.get(GlobalConstants.BC_CODE_VS_LOB.get(bcCode));
                        }
                        if(lobVsUserId.containsKey(GlobalConstants.BC_CODE_VS_LOB.get(bcCode))){  
                            rc.Approver_4__c = lobVsUserId.get(GlobalConstants.BC_CODE_VS_LOB.get(bcCode));
                        }
                    }
                    
                    if(!lobHeadIdVsUser.isEmpty() && rc.Approver_4__c != null){
                        //Functional head (Lob head's manager)
                        rc.Approver_5__c = lobHeadIdVsUser.containsKey(rc.Approver_4__c) ? lobHeadIdVsUser.get(rc.Approver_4__c).ManagerId : null;
                    }
                    receivables.add(rc);
                }
            }
        }
        
        if(receivables.size() > 0){
            update receivables;
        }
    }
    
    /*
     * @Description - Method is responsible for returning LOB Name Vs LOB Head's UserId 
     */
    static Map<String, String> getLobVsUserIds(List<Application_Settings__mdt> settings){
        lobVsUserId = new Map<String, String>();
        for(String lob : GlobalConstants.BC_CODE_VS_LOB.values()){
            lobVsUserId.put(lob, '');
        }
        
        for(String lob : GlobalConstants.BC_CODE_VS_LOB.values()){
            for(Application_Settings__mdt mdt : settings){
                if(mdt.DeveloperName.contains(lob) && mdt.DeveloperName.contains('LOB')){
                    lobVsUserId.put(lob, mdt.Value__c);
                }
            }
        }
        return lobVsUserId;
    }
    
    /*
     * @Description - Method is responsible for returning LOB Name Vs Checker's UserId 
     */
    static Map<String, String> getCheckerLobVsUserId(List<Application_Settings__mdt> settings){
        checkerLobVsUserId = new Map<String, String>();
        for(String lob : GlobalConstants.BC_CODE_VS_LOB.values()){
            checkerLobVsUserId.put(lob, '');
        }
        
        for(String lob : GlobalConstants.BC_CODE_VS_LOB.values()){
            for(Application_Settings__mdt mdt : settings){
                if(mdt.DeveloperName.contains(lob) && mdt.DeveloperName.contains('Checker')){
                   checkerLobVsUserId.put(lob, mdt.Value__c);
                }
            }
        }
        return checkerLobVsUserId;
    }
    
    /*
     * @Description - Method is responsible for returning metadata records with LOB Head's and Checker's Ids 
     */
    static List<Application_Settings__mdt> getSettings(){
        return new List<Application_Settings__mdt>([Select Id, DeveloperName, Value__c, Description__c 
                                                    From Application_Settings__mdt 
                                                    Where DeveloperName Like '%WriteOff_Receivable%']);
    }
    
    /*
     * @Description - Method is responsible for returning user records for the given set of Ids
     */
    static Map<Id, User> getUsers(Set<Id> ids){
        Map<Id, User> r = new Map<Id, User>([Select Id, ManagerId, Manager.ManagerId, Manager.Manager.ManagerId, Manager.Manager.Manager.ManagerId,
                                                    Manager.Manager.Manager.Manager.ManagerId, Persona__c, Manager.Persona__c, Manager.Manager.Persona__c, 
                                                    Manager.Manager.Manager.Persona__c, Manager.Manager.Manager.Manager.Persona__c
                                                               From User Where Id IN: ids]);
        return r;
    }
    
    
    public class WriteOffReceivableWrapper{
        @InvocableVariable public Billed_Sales_Outstandings__c receivableRecord;
    }
    
}