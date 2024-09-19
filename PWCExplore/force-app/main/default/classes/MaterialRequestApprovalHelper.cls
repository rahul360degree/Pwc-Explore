public with sharing class MaterialRequestApprovalHelper {
    public static final Id MHE_PRIMARY_RECORDTYPE_ID = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get(GlobalConstants.MHE_PRIMARY).getRecordTypeId();
    /*------------------------------------------------------------------------
     Author:        Shailja Mishra 
     Company:       Salesforce
     Description:   Method is responsible for populating approvers for Material Request Approval Process
     Inputs:        list of newOrders
    ---------------------------------------------------------------------------
     History
     29-11-2020      Shailja Mishra     Initial Release
    -----------------------------------------------------------------------*/
    public List<Order> populateApprovers(List<Order> newOrders) {
        List<Id> ownerIds = new List<Id>();
        Set<String> areaCodes = new Set<String>();
        List<Order> orders = new List<Order>();
        Map<Id, User> idVsUser = new Map<Id, User>();
        Map<String, String> mheDivisionVsLOBHead = new Map<String, String>();
        Map<String, String> mheDivisionVsCheckerId = new Map<String, String>();
        Map<String, String> areaCodeVBranchHeadSalaryCodes = new Map<String, String>();
        Map<String, String> areaCodeVBranchChampionSalaryCodes = new Map<String, String>();
        Map<String, String> areaCodeVRegionalManagerSalaryCodes = new Map<String, String>();
        for(Order od : newOrders){
            if(od.recordTypeId == MHE_PRIMARY_RECORDTYPE_ID && od.Service_Form__c != null){
                areaCodes.add(od.Area__c);
                ownerIds.add(od.OwnerId);
            }
        }
        if(areaCodes.size() > 0){
            List<Area_Code_Branch_Champion__mdt> areaMappings = [Select Id, Area_Code__c, Branch_Champion_salary_code__c, Branch_head_Salary_code__c, Regional_Manager_Salary_Code__c From Area_Code_Branch_Champion__mdt Where Area_Code__c IN: areaCodes];
            
            Set<String> salaryCodes = new Set<String>();
            for(Area_Code_Branch_Champion__mdt mdt : areaMappings){
                areaCodeVBranchHeadSalaryCodes.put(mdt.Area_Code__c, mdt.Branch_head_Salary_code__c);
                areaCodeVBranchChampionSalaryCodes.put(mdt.Area_Code__c, mdt.Branch_Champion_salary_code__c);
                areaCodeVRegionalManagerSalaryCodes.put(mdt.Area_Code__c, mdt.Regional_Manager_Salary_Code__c);
                salaryCodes.add(mdt.Branch_head_Salary_code__c);
                salaryCodes.add(mdt.Branch_Champion_salary_code__c);
                salaryCodes.add(mdt.Regional_Manager_Salary_Code__c);
            }
            
            
            Map<String, User> salaryCodeVsUser = new Map<String, User>();
            List<User> userFromSalaryCode = [Select Id, Area_Code__c, Salary_Code__c From User Where Salary_Code__c IN: salaryCodes];
            for(User ur : userFromSalaryCode){
                salaryCodeVsUser.put(ur.Salary_Code__c, ur);
            }
            
            //idVsUser = getUsers(ownerIds);
            mheDivisionVsLOBHead = getMHEDivisionVsLOBHead(GlobalConstants.MHE_Division_Vs_MetadataLOB);
            Set<Id> userIds = new Set<Id>((List<Id>)mheDivisionVsLOBHead.values());
            List<Id> userIdList = new List<Id>((Set<Id>)userIds);
            idVsUser = getUsers(userIdList);
            for(Order od : newOrders){
                if(areaCodeVBranchChampionSalaryCodes.containsKey(od.Area__c) && salaryCodeVsUser.containsKey(areaCodeVBranchChampionSalaryCodes.get(od.Area__c))){
                    //branch champion
                    od.Level_1_Approver__c = salaryCodeVsUser.get(areaCodeVBranchChampionSalaryCodes.get(od.Area__c)).Id;
                }
                if(areaCodeVBranchHeadSalaryCodes.containsKey(od.Area__c) && salaryCodeVsUser.containsKey(areaCodeVBranchHeadSalaryCodes.get(od.Area__c))){
                    //branch head
                    od.Level_2_Approver__c = salaryCodeVsUser.get(areaCodeVBranchHeadSalaryCodes.get(od.Area__c)).Id;
                }
                if(areaCodeVRegionalManagerSalaryCodes.containsKey(od.Area__c) && salaryCodeVsUser.containsKey(areaCodeVRegionalManagerSalaryCodes.get(od.Area__c))){
                    //regional manager
                    od.Level_3_Approver__c = salaryCodeVsUser.get(areaCodeVRegionalManagerSalaryCodes.get(od.Area__c)).Id;
                }
                
                Id lobHead = mheDivisionVsLOBHead.get(od.MHE_Division__c); 
                if(!idVsUser.isEmpty()){
                    //LOB head
                    od.Level_4_Approver__c = idVsUser.containsKey(lobHead) ? idVsUser.get(lobHead).ManagerId : null;
                }
                
                orders.add(od);
            }
        }
        return orders;
    }
    
   /*------------------------------------------------------------------------
    Author:        Shailja Mishra 
    Company:       Salesforce
    Description:   Method is reponsible for returning map of MHEDivision Vs LOB Head UserID
    Inputs:        list of userIds
    ---------------------------------------------------------------------------
    History
    29-11-2020      Shailja Mishra     Initial Release
    -----------------------------------------------------------------------*/
    public Map<Id, User> getUsers(List<Id> userIds){
        return new Map<Id, User>([Select Id, ManagerId, Manager.ManagerId From User Where Id IN: userIds]);
    }
    
   /*------------------------------------------------------------------------
    Author:        Shailja Mishra 
    Company:       Salesforce
    Description:   Method is reponsible for returning map of MHEDivision Vs LOB Head UserID
    Inputs:        map<String, String> mheDivisionVsLOB
    ---------------------------------------------------------------------------
    History
    29-11-2020      Shailja Mishra     Initial Release
    -----------------------------------------------------------------------*/
    public Map<String, String> getMHEDivisionVsLOBHead(Map<String, String> mheDivisionVsLOB){
        Set<String> metadataDevNames = new Set<String>((List<String>)mheDivisionVsLOB.values());
        List<Application_Settings__mdt> settings = [Select Id, DeveloperName, Value__c, Description__c 
                                                    From Application_Settings__mdt 
                                                    Where DeveloperName IN: metadataDevNames];
        Map<String, String> mheDivisionVsLOBHead = new Map<String, String>();
        for(String mheDivision : mheDivisionVsLOB.keySet()){
            mheDivisionVsLOBHead.put(mheDivision, '');
        }
        
        for(String mheDivision : mheDivisionVsLOB.keySet()){
            for(Application_Settings__mdt setting : settings){
                if( setting.DeveloperName.containsIgnoreCase(mheDivisionVsLOB.get(mheDivision)) ){
                    mheDivisionVsLOBHead.put(mheDivision, setting.Value__c);
                    break;
                }
            }
        }
        return mheDivisionVsLOBHead;
    }
}