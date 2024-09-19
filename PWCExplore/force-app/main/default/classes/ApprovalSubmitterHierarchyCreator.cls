/*------------------------------------------------------------------------
Author:        Kishor Kumar
Company:       Salesforce
Description:   Class to create Approval Submitter hierarchy for vaiuos BUs
Inputs:        NA
Test Class:   

History
15-07-2020      Kishor Kumar     Initial Release
----------------------------------------------------------------------------*/
public with sharing class ApprovalSubmitterHierarchyCreator {
    
    
    /*------------------------------------------------------------------------
    Author:        Kishor Kumar
    Company:       Salesforce
    Description:   create Submitter Hierarchy for Interio Kitchen Approval
    Inputs:       Quote record, Pricing Approval Request record, User map, Custom metadata map 
    
    History
    15-07-2020      Kishor Kumar     Initial Release
    ----------------------------------------------------------------------------*/
    public static Pricing_approval_request__c createHierarchyForKitchen(Quote quoteRec, Pricing_approval_request__c par, map<Id, User> managerMap, 
                                                                                map<String, list<Approval_Submitter_Hierarchy_mapping__mdt>> approvalSubmitterHierarchyMap){
        map<Integer, String> hierarchyLevelVsPersona = new map<Integer, String>();
        map<String, Integer> personaVsHierarchyLevel = new map<String, Integer>();                                                                            
        map<String, Id> kitchenPersonaVsUserId = new map<String, Id>(); 
        map<Id, String> userIdVskitchenPersona = new map<Id, String>();
        map<Id, Id> userIdVsManagerId = new map<Id, Id>(); 
        Integer Interio_B2C_KITCHEN_max_approver_level = Integer.valueOf(System.Label.Interio_B2C_KITCHEN_max_approver_level);                                                                            
                                                                                    
       if (quoteRec.RecordType.DeveloperName == GlobalConstants.QUOTE_RECORDTYPE_INTERIO_KITCHEN 
                    && approvalSubmitterHierarchyMap.containsKey(GlobalConstants.QUOTE_RECORDTYPE_INTERIO_KITCHEN)){
            //Fetch all the metadata mappings           
            for(Approval_Submitter_Hierarchy_mapping__mdt subMapping : approvalSubmitterHierarchyMap.get(GlobalConstants.QUOTE_RECORDTYPE_INTERIO_KITCHEN)){
                hierarchyLevelVsPersona.put(Integer.valueOf(subMapping.Submitter_Level__c), subMapping.Quote_Submitter_Persona__c.toupperCase()); 
                personaVsHierarchyLevel.put(subMapping.Quote_Submitter_Persona__c.toupperCase(), Integer.valueOf(subMapping.Submitter_Level__c));            
            }
                        
            //create Persona Vs User map
            User KitchenUser = managerMap.get(quoteRec.CreatedById);
            if(String.isNotEmpty(KitchenUser.Persona__c)){        
                kitchenPersonaVsUserId.put(KitchenUser.Persona__c.toupperCase(), KitchenUser.Id);
                userIdVskitchenPersona.put(KitchenUser.Id, KitchenUser.Persona__c.toupperCase());
                userIdVsManagerId.put(KitchenUser.Id, KitchenUser.ManagerId);
            }
                        
            if(KitchenUser.ManagerId != null && String.isNotEmpty(KitchenUser.Manager.Persona__c)){      
                kitchenPersonaVsUserId.put(KitchenUser.Manager.Persona__c.toupperCase(), KitchenUser.ManagerId);
                userIdVskitchenPersona.put(KitchenUser.ManagerId, KitchenUser.Manager.Persona__c.toupperCase());
                userIdVsManagerId.put(KitchenUser.ManagerId, KitchenUser.Manager.ManagerId);
            }
                        
            if(KitchenUser.Manager.ManagerId != null && String.isNotEmpty(KitchenUser.Manager.Manager.Persona__c)){ 
                kitchenPersonaVsUserId.put(KitchenUser.Manager.Manager.Persona__c.toupperCase(), KitchenUser.Manager.ManagerId);
                userIdVskitchenPersona.put(KitchenUser.Manager.ManagerId, KitchenUser.Manager.Manager.Persona__c.toupperCase());
                //No Need to Populate userIdVsManagerId as we don't need manager for this user level
            }
            
            for(Approval_Submitter_Hierarchy_mapping__mdt subMapping : approvalSubmitterHierarchyMap.get(GlobalConstants.QUOTE_RECORDTYPE_INTERIO_KITCHEN)){
                Integer NextSubmitterLevel;
                
                if(KitchenUser.Persona__c.toupperCase() == subMapping.Quote_Submitter_Persona__c.toupperCase()){
                    par.Submitter_Hierarchy_Level__c = subMapping.Submitter_Level__c;
                    
                    //Check for max hierarchy level
                    if(par.Submitter_Hierarchy_Level__c < Interio_B2C_KITCHEN_max_approver_level){
                        NextSubmitterLevel = setNextSubmitter(KitchenUser.Id, userIdVsManagerId, Interio_B2C_KITCHEN_max_approver_level,
                                                                    userIdVskitchenPersona, personaVsHierarchyLevel);
                    } else {//else set max level 
                        NextSubmitterLevel = Interio_B2C_KITCHEN_max_approver_level + 1;
                    }
                    
                    //TSI Persona
                    if(NextSubmitterLevel == 2 && hierarchyLevelVsPersona.containsKey(NextSubmitterLevel) && kitchenPersonaVsUserId.containsKey(hierarchyLevelVsPersona.get(NextSubmitterLevel).toupperCase())){
                        par.Interio_KITCHEN_TSI__c = kitchenPersonaVsUserId.get(hierarchyLevelVsPersona.get(NextSubmitterLevel).toupperCase());
                        
                        NextSubmitterLevel = setNextSubmitter(par.Interio_KITCHEN_TSI__c, userIdVsManagerId, Interio_B2C_KITCHEN_max_approver_level,
                                                                    userIdVskitchenPersona, personaVsHierarchyLevel);
                    }
                    
                    //Zonal Head persona
                    if(NextSubmitterLevel == 3 && hierarchyLevelVsPersona.containsKey(NextSubmitterLevel) && kitchenPersonaVsUserId.containsKey(hierarchyLevelVsPersona.get(NextSubmitterLevel).toupperCase())){
                        par.Interio_KITCHEN_Zonal_Head__c = kitchenPersonaVsUserId.get(hierarchyLevelVsPersona.get(NextSubmitterLevel).toupperCase());
                    }
                }
            }        
        }
        return par;
    }
    
    public Static Integer setNextSubmitter(Id currentSubmitterId, map<Id, Id> userIdVsManagerId, Integer maxLevel,
                                          map<Id, String> userIdVskitchenPersona, map<String, Integer> personaVsHierarchyLevel){
        Integer NextSubmitterLevel;
        if(userIdVsManagerId.containsKey(currentSubmitterId) &&  
                            userIdVskitchenPersona.containsKey(userIdVsManagerId.get(currentSubmitterId)) 
                            && personaVsHierarchyLevel.containsKey(userIdVskitchenPersona.get(userIdVsManagerId.get(currentSubmitterId)))){
            NextSubmitterLevel = Integer.valueOf(personaVsHierarchyLevel.get(userIdVskitchenPersona.get(userIdVsManagerId.get(currentSubmitterId))));
                            
            if(NextSubmitterLevel >= maxLevel)
                NextSubmitterLevel = maxLevel;    
        } 
        return NextSubmitterLevel;                                      
    }
    
    
    /*------------------------------------------------------------------------
    Author:        Kishor Kumar
    Company:       Salesforce
    Description:   create Submitter Hierarchy for Interio Script Approval
    Inputs:       Quote record, Pricing Approval Request record, User map, Custom metadata map 
    
    History
    17-07-2020      Kishor Kumar     Initial Release
    ----------------------------------------------------------------------------*/
    public static Pricing_approval_request__c createHierarchyForInterioScript(Quote quoteRec, Pricing_approval_request__c par, map<Id, User> managerMap, 
                                                                              map<String, list<Approval_Submitter_Hierarchy_mapping__mdt>> approvalSubmitterHierarchyMap){
        map<Integer, String> hierarchyLevelVsPersona = new map<Integer, String>();
        map<String, Integer> personaVsHierarchyLevel = new map<String, Integer>();
        map<String, Id> scriptPersonaVsUserId = new map<String, Id>(); 
        map<Id, String> userIdVsScriptPersona = new map<Id, String>();
        map<Id, Id> userIdVsManagerId = new map<Id, Id>();
        Integer Interio_SCRIPT_max_approver_level = Integer.valueOf(System.Label.Interio_SCRIPT_max_approver_level);                                                                            
                                                                                  
        if (quoteRec.RecordType.DeveloperName == GlobalConstants.QUOTE_RECORDTYPE_INTERIO_SCRIPT 
                    && approvalSubmitterHierarchyMap.containsKey(GlobalConstants.QUOTE_RECORDTYPE_INTERIO_SCRIPT)){           
            //Fetch all the metadata mappings           
            for(Approval_Submitter_Hierarchy_mapping__mdt subMapping : approvalSubmitterHierarchyMap.get(GlobalConstants.QUOTE_RECORDTYPE_INTERIO_SCRIPT)){
                hierarchyLevelVsPersona.put(Integer.valueOf(subMapping.Submitter_Level__c), subMapping.Quote_Submitter_Persona__c.toupperCase()); 
                personaVsHierarchyLevel.put(subMapping.Quote_Submitter_Persona__c.toupperCase(), Integer.valueOf(subMapping.Submitter_Level__c));            
            }
                        
            //create Persona Vs User map
            User ScriptUser = managerMap.get(quoteRec.CreatedById);
            if(String.isNotEmpty(ScriptUser.Persona__c)){        
                scriptPersonaVsUserId.put(ScriptUser.Persona__c.toupperCase(), ScriptUser.Id);
                userIdVsScriptPersona.put(ScriptUser.Id, ScriptUser.Persona__c.toupperCase());
                userIdVsManagerId.put(ScriptUser.Id, ScriptUser.ManagerId);
            }//Submitter

            if(ScriptUser.ManagerId != null && String.isNotEmpty(ScriptUser.Manager.Persona__c)){      
                scriptPersonaVsUserId.put(ScriptUser.Manager.Persona__c.toupperCase(), ScriptUser.ManagerId);
                userIdVsScriptPersona.put(ScriptUser.ManagerId, ScriptUser.Manager.Persona__c.toupperCase());
                userIdVsManagerId.put(ScriptUser.ManagerId, ScriptUser.Manager.ManagerId);
            }//Level 1 : Approver
                        
            if(ScriptUser.Manager.ManagerId != null && String.isNotEmpty(ScriptUser.Manager.Manager.Persona__c)){ 
                scriptPersonaVsUserId.put(ScriptUser.Manager.Manager.Persona__c.toupperCase(), ScriptUser.Manager.ManagerId);
                userIdVsScriptPersona.put(ScriptUser.Manager.ManagerId, ScriptUser.Manager.Manager.Persona__c.toupperCase());
                userIdVsManagerId.put(ScriptUser.Manager.ManagerId, ScriptUser.Manager.Manager.ManagerId);
            }//Level 2 : Approver
            
            if(ScriptUser.Manager.Manager.ManagerId != null && String.isNotEmpty(ScriptUser.Manager.Manager.Manager.Persona__c)){        
                scriptPersonaVsUserId.put(ScriptUser.Manager.Manager.Manager.Persona__c.toupperCase(), ScriptUser.Manager.Manager.ManagerId);
                userIdVsScriptPersona.put(ScriptUser.Manager.Manager.ManagerId, ScriptUser.Manager.Manager.Manager.Persona__c.toupperCase());
                
                //No Need to Populate userIdVsManagerId as we don't need manager for this user level
            }//Level 3 : Approver
                        
            for(Approval_Submitter_Hierarchy_mapping__mdt subMapping : approvalSubmitterHierarchyMap.get(GlobalConstants.QUOTE_RECORDTYPE_INTERIO_SCRIPT)){
                Integer NextSubmitterLevel;
                
                if(ScriptUser.Persona__c.toupperCase() == subMapping.Quote_Submitter_Persona__c.toupperCase()){
                    par.Submitter_Hierarchy_Level__c = subMapping.Submitter_Level__c;
                    
                    //Check for max hierarchy level
                    if(par.Submitter_Hierarchy_Level__c < (Interio_SCRIPT_max_approver_level)){ 
                        NextSubmitterLevel = setNextSubmitter(ScriptUser.Id, userIdVsManagerId, Interio_SCRIPT_max_approver_level, 
                                                                    userIdVsScriptPersona, personaVsHierarchyLevel);
                    }else { 
                        //Assumption Queue user will not submit
                       NextSubmitterLevel = Interio_SCRIPT_max_approver_level +1; 
                    }
                    
                    
                    //InteroScript- COCO Store Manager
                    if(NextSubmitterLevel == 2 && hierarchyLevelVsPersona.containsKey(NextSubmitterLevel) && scriptPersonaVsUserId.containsKey(hierarchyLevelVsPersona.get(NextSubmitterLevel).toupperCase())){
                        par.Interio_Script_Store_Manager__c = scriptPersonaVsUserId.get(hierarchyLevelVsPersona.get(NextSubmitterLevel).toupperCase());
                        
                        NextSubmitterLevel = setNextSubmitter(par.Interio_Script_Store_Manager__c, userIdVsManagerId, Interio_SCRIPT_max_approver_level,
                                                                    userIdVsScriptPersona, personaVsHierarchyLevel);
                    }
                    
                    //InteroScript- HO Sales Support Manager
                    if(NextSubmitterLevel == 3 && hierarchyLevelVsPersona.containsKey(NextSubmitterLevel) && scriptPersonaVsUserId.containsKey(hierarchyLevelVsPersona.get(NextSubmitterLevel).toupperCase())){
                        par.Interio_Script_HO_Sales_Support_Manager__c = scriptPersonaVsUserId.get(hierarchyLevelVsPersona.get(NextSubmitterLevel).toupperCase());
                        
                        NextSubmitterLevel = setNextSubmitter(par.Interio_Script_HO_Sales_Support_Manager__c, userIdVsManagerId, Interio_SCRIPT_max_approver_level,
                                                                    userIdVsScriptPersona, personaVsHierarchyLevel);
                    }
                    
                    //InteroScript- Retail Operations Head
                    if(NextSubmitterLevel == 4 && hierarchyLevelVsPersona.containsKey(NextSubmitterLevel) && scriptPersonaVsUserId.containsKey(hierarchyLevelVsPersona.get(NextSubmitterLevel).toupperCase())){
                        par.Interio_Script_Retails_Operation_Head__c = scriptPersonaVsUserId.get(hierarchyLevelVsPersona.get(NextSubmitterLevel).toupperCase());
                        
                    }
                }
            }
        }
        return par;                                                                              
    }
    
    
     /*------------------------------------------------------------------------
    Author:        Kishor Kumar
    Company:       Salesforce
    Description:   create Submitter Hierarchy for SSG - SFS Category
    Inputs:       Quote record, Pricing Approval Request record, User map, Custom metadata map 
    
    History
    15-07-2020      Kishor Kumar     Initial Release
    ----------------------------------------------------------------------------*/
    //public static Pricing_approval_request__c createHierarchyForSSG_SFS(Quote quoteRec, Pricing_approval_request__c par, map<Id, User> managerMap, 
                                                                               // map<String, list<Approval_Submitter_Hierarchy_mapping__mdt>> approvalSubmitterHierarchyMap){
      /*  map<Id, Id> userIdVsManagerId = new map<Id, Id>(); 
        Integer SSG_SFS_max_approver_level = Integer.valueOf(System.Label.SSG_SFS_max_approver_level);                                                                            
     
        if (quoteRec.RecordType.DeveloperName == GlobalConstants.QUOTE_RECORDTYPE_SSG 
                    && (quoteRec.Category__c == 'SFS Imported' || quoteRec.Category__c == 'SFS In-house') 
                    && approvalSubmitterHierarchyMap.containsKey(GlobalConstants.QUOTE_RECORDTYPE_SSG)){
                       
            //create Persona Vs User map
            User SFSUser = managerMap.get(quoteRec.CreatedById);
                        
            if(SFSUser.ManagerId != null){        
                userIdVsManagerId.put(SFSUser.Id, SFSUser.ManagerId);
            
                if(SFSUser.Manager.ManagerId != null)      
                    userIdVsManagerId.put(SFSUser.ManagerId, SFSUser.Manager.ManagerId);
            }//Submitter : Sales Engineer 
                        
            for(Approval_Submitter_Hierarchy_mapping__mdt subMapping : approvalSubmitterHierarchyMap.get(GlobalConstants.QUOTE_RECORDTYPE_SSG)){
                
                if(subMapping.Category__c == 'SFS' && SFSUser.Persona__c.toupperCase() == subMapping.Quote_Submitter_Persona__c.toupperCase()){
                    par.Submitter_Hierarchy_Level__c = subMapping.Submitter_Level__c;
                    
                    //set Sales & Marketing Head 
                    if(Integer.valueOf(par.Submitter_Hierarchy_Level__c) < SSG_SFS_max_approver_level  
                            && SFSUser.ManagerId != null && userIdVsManagerId.containsKey(SFSUser.ManagerId))
                        par.SSG_SFS_Sales_Marketing_Head__c = userIdVsManagerId.get(SFSUser.ManagerId);
                    else if(Integer.valueOf(par.Submitter_Hierarchy_Level__c) == SSG_SFS_max_approver_level   
                                        && userIdVsManagerId.containsKey(SFSUser.Id))
                        par.SSG_SFS_Sales_Marketing_Head__c = userIdVsManagerId.get(SFSUser.Id);
                }
            }
                        
        }       */                                                                    
     //   return par;                                                                               
    //}
    
    /*------------------------------------------------------------------------
    Author:        Kishor Kumar
    Company:       Salesforce
    Description:   create Submitter Hierarchy for SSG - Regular/Key Category
    Inputs:       Quote record, Pricing Approval Request record, User map, Custom metadata map 
    
    History
    22-07-2020      Kishor Kumar     Initial Release
    ----------------------------------------------------------------------------*/
    public static Pricing_approval_request__c createHierarchyForSSG_Regular_Key(Quote quoteRec, Pricing_approval_request__c par, map<Id, User> managerMap, 
                                                                                map<String, list<Approval_Submitter_Hierarchy_mapping__mdt>> approvalSubmitterHierarchyMap){
        map<Integer, String> hierarchyLevelVsPersona = new map<Integer, String>();
        map<String, Integer> personaVsHierarchyLevel = new map<String, Integer>();
        map<String, Id> ssgPersonaVsUserId = new map<String, Id>(); 
        map<Id, String> userIdVsSSGPersona = new map<Id, String>();
        map<Id, Id> userIdVsManagerId = new map<Id, Id>();  
                                                                                    
        Integer SSG_REGULAR_KEY_max_approver_level = Integer.valueOf(System.Label.SSG_REGULAR_KEY_max_approver_level);                                                                            
     
        if (quoteRec.RecordType.DeveloperName == GlobalConstants.QUOTE_RECORDTYPE_SSG 
                    && (quoteRec.Category__c == 'Regular' || quoteRec.Category__c == 'Key' 
                    //Added by prachi on 12-02-2021 added category for ticket no 30315883
                    || quoteRec.Category__c == 'Consulting' || quoteRec.Category__c == 'Swift' || quoteRec.Category__c == 'Life Cycle Services' || quoteRec.Category__c == 'Storage 2.0'
                       //Added by Vikrant on 14-04-2021 added category for Ticket#30356659
                       || quoteRec.Category__c == 'SFS In-house' || quoteRec.Category__c == 'SFS Imported' || quoteRec.Category__c == 'Key - Life cycle services'
                       || quoteRec.Category__c == 'Regular Swift' || quoteRec.Category__c == 'Key Swift'
                       ) 
                    && approvalSubmitterHierarchyMap.containsKey(GlobalConstants.QUOTE_RECORDTYPE_SSG)){
            
            //Fetch all the metadata mappings           
            for(Approval_Submitter_Hierarchy_mapping__mdt subMapping : approvalSubmitterHierarchyMap.get(GlobalConstants.QUOTE_RECORDTYPE_SSG)){
                if(subMapping.Category__c == 'Regular/Key'){
                    
                    hierarchyLevelVsPersona.put(Integer.valueOf(subMapping.Submitter_Level__c), subMapping.Quote_Submitter_Persona__c.toupperCase()); 
                    personaVsHierarchyLevel.put(subMapping.Quote_Submitter_Persona__c.toupperCase(), Integer.valueOf(subMapping.Submitter_Level__c));            
                }
            }            
                        
            //create Persona Vs User map
            User createdByUser = managerMap.get(quoteRec.CreatedById);
                        
            if(String.isNotEmpty(createdByUser.Persona__c)){        
                ssgPersonaVsUserId.put(createdByUser.Persona__c.toupperCase(), createdByUser.Id);
                userIdVsSSGPersona.put(createdByUser.Id, createdByUser.Persona__c.toupperCase());
                userIdVsManagerId.put(createdByUser.Id, createdByUser.ManagerId);
              
            }//Level 1 : Sales Engineer

            if(createdByUser.ManagerId != null && String.isNotEmpty(createdByUser.Manager.Persona__c)){      
                ssgPersonaVsUserId.put(createdByUser.Manager.Persona__c.toupperCase(), createdByUser.ManagerId);
                userIdVsSSGPersona.put(createdByUser.ManagerId, createdByUser.Manager.Persona__c.toupperCase());
                userIdVsManagerId.put(createdByUser.ManagerId, createdByUser.Manager.ManagerId);
               
            }//Level 2 : Territory
                        
            if(createdByUser.Manager.ManagerId != null && String.isNotEmpty(createdByUser.Manager.Manager.Persona__c)){ 
                ssgPersonaVsUserId.put(createdByUser.Manager.Manager.Persona__c.toupperCase(), createdByUser.Manager.ManagerId);
                userIdVsSSGPersona.put(createdByUser.Manager.ManagerId, createdByUser.Manager.Manager.Persona__c.toupperCase());
               
            }//Level 3 : Regional
                        
            for(Approval_Submitter_Hierarchy_mapping__mdt subMapping : approvalSubmitterHierarchyMap.get(GlobalConstants.QUOTE_RECORDTYPE_SSG)){
                Integer NextSubmitterLevel;
                
                if(subMapping.Category__c == 'Regular/Key' && createdByUser.Persona__c.toupperCase() == subMapping.Quote_Submitter_Persona__c.toupperCase()){
                    par.Submitter_Hierarchy_Level__c = subMapping.Submitter_Level__c;
                    
                    //Check for max hierarchy level
                    if(par.Submitter_Hierarchy_Level__c < (SSG_REGULAR_KEY_max_approver_level)){ 
                        NextSubmitterLevel = setNextSubmitter(createdByUser.Id, userIdVsManagerId, SSG_REGULAR_KEY_max_approver_level, 
                                                                    userIdVsSSGPersona, personaVsHierarchyLevel);
                    }else { 
                        //Assumption Queue user will not submit
                       NextSubmitterLevel = SSG_REGULAR_KEY_max_approver_level +1; 
                    }
                    
                    //Territory sales Manager
                    if(NextSubmitterLevel == 2 && hierarchyLevelVsPersona.containsKey(NextSubmitterLevel) && ssgPersonaVsUserId.containsKey(hierarchyLevelVsPersona.get(NextSubmitterLevel).toupperCase())){
                        par.Territory_Sales_manager__c = ssgPersonaVsUserId.get(hierarchyLevelVsPersona.get(NextSubmitterLevel).toupperCase());
                        
                        NextSubmitterLevel = setNextSubmitter(par.Territory_Sales_manager__c, userIdVsManagerId, SSG_REGULAR_KEY_max_approver_level,
                                                                    userIdVsSSGPersona, personaVsHierarchyLevel);
                    }
                    
                    //Regional sales Manager
                    if((NextSubmitterLevel == 3 || NextSubmitterLevel == 4) && hierarchyLevelVsPersona.containsKey(NextSubmitterLevel) && ssgPersonaVsUserId.containsKey(hierarchyLevelVsPersona.get(NextSubmitterLevel).toupperCase())){
                        par.Regional_Sales_manager__c = ssgPersonaVsUserId.get(hierarchyLevelVsPersona.get(NextSubmitterLevel).toupperCase());
                      
                    }
                }
            }
                        
        }                                                                            
        return par;                                                                                 
    }
    
    
}