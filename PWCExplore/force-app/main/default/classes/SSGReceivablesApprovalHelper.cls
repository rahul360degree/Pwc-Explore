/*------------------------------------------------------------------------
 * Author:        Shailja Mishra
 * Company:       Salesforce
 * Description:   Helper class to handle SSG Receivable Approvals
 * Inputs:        NA
 * Test Class:    SSGReceivableApprovalHelperTest
 * ---------------------------------------------------------------------------
 * History
 * 03-11-2020      Shailja Mishra     Initial Release
 * ----------------------------------------------------------------------------*/
public with sharing class SSGReceivablesApprovalHelper {
     /*------------------------------------------------------------------------
      Author:        Shailja Mishra
      Company:       Salesforce
      Description:   Responsible for populating Approval Level fields based on Persona
      Inputs:        NA
      Test Class:    SSGReceivableApprovalHelperTest
    ---------------------------------------------------------------------------
      History
      3-11-2020      Shailja Mishra     Initial Release
    ----------------------------------------------------------------------------*/
    @InvocableMethod
    public static void setFieldValues(List<WriteOffReceivableWrapper> inputs){
        List<Billed_Sales_Outstandings__c> receivables = new List<Billed_Sales_Outstandings__c>();
        Set<Id> userIds = new Set<Id>();
        Map<Id, User> idVsUser = new Map<Id, User>();
        for(WriteOffReceivableWrapper wrapper : inputs){
            userIds.add(wrapper.receivableRecord.OwnerId);
        }
        idVsUser = getUsers(userIds);
        if(!idVsUser.isEmpty()){
            for(WriteOffReceivableWrapper wrapper : inputs){
                Id userId = wrapper.receivableRecord.OwnerId;
                Billed_Sales_Outstandings__c rc = new Billed_Sales_Outstandings__c();
                if(idVsUser.containsKey(userId)){
                    rc.Id = wrapper.receivableRecord.Id;
                    //Set ManagerId (Level 1)
                    Id managerId = idVsUser.get(userId).ManagerId;
                    // if Manager.Persona is 'Teritory Sales Manager' then set Level 1 as ManagerId
                    if(managerId != null){
                      /* && String.isNotBlank(idVsUser.get(userId).Manager.Persona__c)
                       && idVsUser.get(userId).Manager.Persona__c.contains(GlobalConstants.SSG_TERRITORY_SALES_MANAGER)){ */
                        rc.Approver_1__c = managerId;
                        // set Manager.ManagerId (Level 2)
                        managerId = idVsUser.get(UserId).Manager.ManagerId;
                    }
                    // if Manager.Manager.Persona is 'Regional Sales Manager' then set Level 2 as Manager.ManagerId
                    if(managerId != null){ 
                       /*&& String.isNotBlank(idVsUser.get(userId).Manager.Manager.Persona__c)
                       && idVsUser.get(userId).Manager.Manager.Persona__c.contains(GlobalConstants.SSG_REGIONAL_SALES_MANAGER)){*/
                        rc.Approver_2__c = managerId;
                        //set Manager.Manager.ManagerId (Level 3)
                        managerId = idVsUser.get(UserId).Manager.Manager.ManagerId;
                    }
                    // if Manager.Manager.Manager.Persona is 'National Sales Manager' then set Level 3 as Manager.Manager.ManagerId
                    if(managerId != null){
                      /* && String.isNotBlank(idVsUser.get(userId).Manager.Manager.Manager.Persona__c)
                       && idVsUser.get(userId).Manager.Manager.Manager.Persona__c.contains(GlobalConstants.SSG_NATIONAL_SALES_MANAGER)){ */
                        rc.Approver_3__c = managerId;
                        //set Manager.Manager.Manager.ManagerId (Level 4)
                        managerId = idVsUser.get(UserId).Manager.Manager.Manager.ManagerId;
                    }
                    // if Manager.Manager.Manager.Manager.Persona is 'Sales & Marketing Head' then set Level 4 as Manager.Manager.Manager.ManagerId
                    if(managerId != null){ 
                      /* && String.isNotBlank(idVsUser.get(userId).Manager.Manager.Manager.Manager.Persona__c)
                       && idVsUser.get(userId).Manager.Manager.Manager.Manager.Persona__c.contains(GlobalConstants.SSG_SALES_AND_MARKETING_HEAD)){ */
                        rc.Approver_4__c = managerId;
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
     * @Description - Method is responsible for returning user records for the given set of Ids
     */
    static Map<Id, User> getUsers(Set<Id> ids){
        return  new Map<Id, User>([Select Id, ManagerId, Manager.ManagerId, Manager.Manager.ManagerId, Manager.Manager.Manager.ManagerId,
                                          Manager.Manager.Manager.Manager.ManagerId, Persona__c, Manager.Persona__c, Manager.Manager.Persona__c, Manager.Manager.Manager.Persona__c,
                                          Manager.Manager.Manager.Manager.Persona__c
                                   From User Where Id IN: ids]);
    }
    
    public class WriteOffReceivableWrapper{
        @InvocableVariable public Billed_Sales_Outstandings__c receivableRecord;
    }
}