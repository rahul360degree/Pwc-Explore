/*------------------------------------------------------------------------
Author:        Manasi Londhe
Company:       Salesforce
Description:   Class to populate zip code rule  fields
Inputs:        map of created records
Test Class:   

History
08-05-2020      Manasi Londhe     Initial Release
----------------------------------------------------------------------------*/
public without sharing class ZipCodeRuleFieldPopulator {
     /*------------------------------------------------------------------------
    Author:        Manasi Londhe
    Company:       Salesforce
    Description:   Method to validate Queue name populated on zip code rule
    Inputs:        list of created order records
    Test Class:   

    History
    08-05-2020      Manasi Londhe     Initial Release
    ----------------------------------------------------------------------------*/
    public void validateQueueNamePopulated(List<Zip_Code_Rule__c> ziprules,Map<Id,Zip_Code_Rule__c> mapOldRules){
          List<Zip_Code_Rule__c> rules=new List<Zip_Code_Rule__c>(); 
          if(mapOldRules==null){
            rules=ziprules;
          }
          else{
            for(Zip_Code_Rule__c rule:zipRules){
                if(checkIfApplicableForUpdate(rule,mapOldRules.get(rule.Id))){
                    rules.add(rule);
                }
            }
          }
          Set<String> orgQueues=new Set<String>(); 
          List<String> queueDeveloperNames=getAllQueueNames(rules);   
        for(Group q:[Select DeveloperName From Group where Type='Queue' And DeveloperName in :queueDeveloperNames]){
            orgQueues.add(q.DeveloperName);
        }
        for(Zip_Code_Rule__c rule:rules){
            Set<String> invalidQueueNames=new Set<String>();
            for(Integer i=1;i<=7;i++){ 
                if(!String.isBlank((String)rule.get('Queue_'+i+'__c')) && !orgQueues.contains((String)rule.get('Queue_'+i+'__c'))){
                    invalidQueueNames.add((String)rule.get('Queue_'+i+'__c'));
                }
            }
            String errorString='';
            for(String invalidQueueName:invalidQueueNames){
                errorString=errorString+invalidQueueName+' '; 
            }
            if(errorString!=''){
                errorString=errorString+System.Label.Invalid_Queue_Name;
                rule.adderror(errorString);
            }    
        }
    }

    /*------------------------------------------------------------------------
    Author:        Manasi Londhe
    Company:       Salesforce
    Description:   Method to validate if queue names are populated in sequence
    Inputs:        list of created order records
    Test Class:   

    History
    08-05-2020      Manasi Londhe     Initial Release
    ----------------------------------------------------------------------------*/
    public void validateQueueSequence(List<Zip_Code_Rule__c> ziprules,Map<Id,Zip_Code_Rule__c> mapOldRules){
        List<Zip_Code_Rule__c> rules=new List<Zip_Code_Rule__c>(); 
          if(mapOldRules==null){
            rules=ziprules;
          }
          else{
            for(Zip_Code_Rule__c rule:zipRules){
                if(checkIfApplicableForUpdate(rule,mapOldRules.get(rule.Id))){
                    rules.add(rule);
                }
            }
          }
         for(Zip_Code_Rule__c rule:rules){
             List<String> queues=getAllQueueNames(new List<Zip_Code_Rule__c>{rule});
             Integer size=queues.size();
             for(Integer i=1;i<=size;i++){
                 if(String.isBlank((String)rule.get('Queue_'+i+'__c'))){
                    rule.adderror(System.Label.Add_Queue_Name_Sequence_Wise);
                 }
             }
         }
    }

    /*------------------------------------------------------------------------
    Author:        Manasi Londhe
    Company:       Salesforce
    Description:   Method to validate rule name populated
    Inputs:        list of created order records
    Test Class:   

    History
    08-05-2020      Manasi Londhe     Initial Release
    ----------------------------------------------------------------------------*/
    public void validateRuleNamePopulated(List<Zip_Code_Rule__c> ziprules,Map<Id,Zip_Code_Rule__c> mapOldRules){
        List<Zip_Code_Rule__c> rules=new List<Zip_Code_Rule__c>(); 
        if(mapOldRules==null){
            rules=ziprules;
        }
        else{
            for(Zip_Code_Rule__c rule:zipRules){
                if(rule.Name!=mapOldRules.get(rule.Id).Name){
                    rules.add(rule);
                }
            }
        }
        Set<String> businessUnitValues=Utility.getPicklistValues('Lead','Business_Unit__c');
        Set<String> subDivision=Utility.getPicklistValues('Lead','Sub_Division__c');
        Set<String> interioSubDiv=Utility.getPicklistValues('Lead','Interio_Sub_Division__c');
        Set<String> ruleZipCodes=new Set<String>();  
        Set<String> orgZipCodes=new Set<String>();  
        for(Zip_Code_Rule__c rule:rules){
            List<String> codeBUSubDiv=rule.Name.Split('-');
            if(codeBUSubDiv.size()!=3 && codeBUSubDiv.size()!=4){
                rule.adderror(System.Label.Invalid_Zip_Code_Rule_Name);
            }
            else{
                ruleZipCodes.add(codeBUSubDiv[2]);
            }
        }
         if(ruleZipCodes.size()>0){
            for(ZipCode__c zipCode:[Select Name From ZipCode__c where Name in :ruleZipCodes]){
                orgZipCodes.add(zipCode.Name);
            }
            for(Zip_Code_Rule__c rule:rules){
                Set<String> errors=new Set<String>(); 
                List<String> codeBUSubDiv=rule.Name.Split('-');
                if(!orgZipCodes.contains(codeBUSubDiv[2])){
                    errors.add(System.Label.Invalid_Zip_Code);
                }
                if(!businessUnitValues.contains(codeBUSubDiv[0])){
                    errors.add(System.Label.Invalid_Business_Unit);
                }
                else{
                    if(codeBUSubDiv[0]==GlobalConstants.INTERIO_BUSINESS_UNIT){
                        if(!interioSubDiv.contains(codeBUSubDiv[1])){
                            errors.add(System.Label.Invalid_Sub_Division);
                        }
                    }
                    else{
                        if(!subDivision.contains(codeBUSubDiv[1])){
                            errors.add(System.Label.Invalid_Sub_Division);
                        }
                    }
                }
                if(errors.size()>0)
                {
                    String errorString='';
                    for(String e:errors){
                        errorString=errorString+e+', ';
                    }
                    rule.adderror(errorString);
                }
            }
        }
    }

     /*------------------------------------------------------------------------
    Author:        Manasi Londhe
    Company:       Salesforce
    Description:   Method to populate Queues_And_LastAssignedId__c  
    Inputs:        list of created order records
    Test Class:   

    History
    08-05-2020      Manasi Londhe     Initial Release
    ----------------------------------------------------------------------------*/
    public void populateQueueVsLastAssignedId(List<Zip_Code_Rule__c> ziprules){
          for(Zip_Code_Rule__c rule:ziprules){
              List<String> queueNames=getAllQueueNames(new List<Zip_Code_Rule__c>{rule});
              Map<String,String> queueNameVsLastAssignedId=new Map<String,String>();
              for(String queue:queueNames){
                queueNameVsLastAssignedId.put(queue,''); 
              }
              rule.Queues_And_LastAssignedId__c=JSON.Serialize(queueNameVsLastAssignedId);
          }  
    }

    /*------------------------------------------------------------------------
    Author:        Manasi Londhe
    Company:       Salesforce
    Description:   Method to update Queues_And_LastAssignedId__c  
    Inputs:        list of created order records
    Test Class:   

    History
    08-05-2020      Manasi Londhe     Initial Release
    ----------------------------------------------------------------------------*/
    public void updateQueueVsLastAssignedId(List<Zip_Code_Rule__c> ziprules,Map<Id,Zip_Code_Rule__c> mapOldRules){
        for(Zip_Code_Rule__c rule:ziprules){
            List<String> allNewQueueNames=getAllQueueNames(new List<Zip_Code_Rule__c>{rule});
            Set<String> newQueueNames=new Set<String>();
            Set<String> oldQueueNames=new Set<String>();
            for(Integer i=1;i<=7;i++){
               String oldQueueName=(String)mapOldRules.get(rule.Id).get('Queue_'+i+'__c');
               if((String)rule.get('Queue_'+i+'__c')!=oldQueueName){
                    newQueueNames.add((String)rule.get('Queue_'+i+'__c'));
                    oldQueueNames.add(oldQueueName);
                }  
            }
            if(newQueueNames.size()>0){
                Map<String,Object> queueNameVsLastAssigned=rule.Queues_And_LastAssignedId__c!=null?(Map<String,Object>)JSON.deserializeUntyped(rule.Queues_And_LastAssignedId__c):new Map<String,Object>();
                for(String queueName:newQueueNames){
                    if(!String.isBlank(queueName) && !queueNameVsLastAssigned.keySet().contains(queueName)){
                        queueNameVsLastAssigned.put(queueName,'');
                    }
                }
                for(String queueName:oldQueueNames){
                   if(!String.isBlank(queueName) && !allNewQueueNames.contains(queueName) && queueNameVsLastAssigned.containsKey(queueName)){
                      queueNameVsLastAssigned.remove(queueName);
                   }
                }
                rule.Queues_And_LastAssignedId__c=JSON.Serialize(queueNameVsLastAssigned);
            }
        } 
    }

     /*------------------------------------------------------------------------
    Author:        Manasi Londhe
    Company:       Salesforce
    Description:   Method to get all queues names from the zip code rules 
    Inputs:        list of created order records
    Test Class:   

    History
    08-05-2020      Manasi Londhe     Initial Release
    ----------------------------------------------------------------------------*/
    public Static List<String> getAllQueueNames(List<Zip_Code_Rule__c> ziprules){
        List<String> queueDeveloperNames=new List<String>();  
        for(Zip_Code_Rule__c rule:ziprules){
            for(Integer i=1;i<=7;i++){
              if(!String.isBlank((String)rule.get('Queue_'+i+'__c'))){
                queueDeveloperNames.add((String)rule.get('Queue_'+i+'__c'));
              }
            }
          }
          return queueDeveloperNames;
    }
    
    /*------------------------------------------------------------------------
    Author:        Manasi Londhe
    Company:       Salesforce
    Description:   Method to get check if rule is applicable for queue fields update validation  
    Inputs:        list of created order records
    Test Class:   

    History
    08-05-2020      Manasi Londhe     Initial Release
    ----------------------------------------------------------------------------*/
    public Boolean checkIfApplicableForUpdate(Zip_Code_Rule__c newRule,Zip_Code_Rule__c oldRule){
        return newRule.Queue_1__c!=oldRule.Queue_1__c || newRule.Queue_2__c!=oldRule.Queue_2__c || newRule.Queue_3__c!=oldRule.Queue_3__c 
        || newRule.Queue_4__c!=oldRule.Queue_4__c || newRule.Queue_5__c!=oldRule.Queue_5__c || 
        newRule.Queue_6__c!=oldRule.Queue_6__c || newRule.Queue_7__c!=oldRule.Queue_7__c;
    }

     /*------------------------------------------------------------------------
    Author:        Manasi Londhe
    Company:       Salesforce
    Description:   validates if channel is entered only when BU is Appliance and 
                   then appending the channel to zip code rule name
                   User story=>W-000112
                   Sprint 2 
                   Phase 3 
    Inputs:        list of Zip code rules
    Test Class:   

    History
    30-10-2020      Manasi Londhe     Initial Release
    ----------------------------------------------------------------------------*/
    public void appendChannelToRuleName(List<Zip_Code_Rule__c> ziprules,Map<Id,Zip_Code_Rule__c> mapOldRules){
        List<Zip_Code_Rule__c> rules=new List<Zip_Code_Rule__c>(); 
        if(mapOldRules==null){
          rules=ziprules;
        }
        else{
          for(Zip_Code_Rule__c rule:zipRules){
              if(rule.channel__c!=mapOldRules.get(rule.Id).channel__c
                 && rule.Name!=null){
                 if(mapOldRules.get(rule.Id).channel__c!=null && rule.Name.lastIndexOfChar(45)!=-1){
                    rule.Name=rule.Name.substring(0,rule.Name.lastIndexOfChar(45));
                 }
                 rules.add(rule);
              }
          }
        }
        for(Zip_Code_Rule__c zipRule:rules){
            String businessUnit=zipRule.Name!=null && (zipRule.Name.split('-')).size()>0 ?(zipRule.Name.split('-'))[0]:null;
            if(businessUnit!=GlobalConstants.APPLIANCE_BUSINESS_UNIT && zipRule.channel__c!=null){
                zipRule.addError(System.Label.Can_only_add_channel_to_Appliance_Zip_rule);
            }
            else if(zipRule.channel__c!=null && zipRule.name!=null && (zipRule.name.split('-')).size()==3){
                zipRule.name=zipRule.name+'-'+zipRule.channel__c;
            }
        }
    }
    
     /*------------------------------------------------------------------------
    Author:        Manasi Londhe
    Company:       Salesforce
    Description:   checks duplicate zip code rule.
                   User story=>W-000112
                   Sprint 2 
                   Phase 3 
    Inputs:        list of Zip code rules
    Test Class:   

    History
    30-10-2020      Manasi Londhe     Initial Release
    ----------------------------------------------------------------------------*/
    public void checkDuplicateRule(List<Zip_Code_Rule__c> ziprules,Map<Id,Zip_Code_Rule__c> mapOldRules){
        List<Zip_Code_Rule__c> rules=new List<Zip_Code_Rule__c>(); 
        Set<String> newRuleNames=new Set<String>();
        Set<String> existingRuleNames=new Set<String>();
        if(mapOldRules==null){
          rules=ziprules;
        }
        else{
          for(Zip_Code_Rule__c rule:zipRules){
              if(rule.Name!=mapOldRules.get(rule.Id).Name){
                rules.add(rule);
              }
          }
        }
        for(Zip_Code_Rule__c rule:rules){
            newRuleNames.add(rule.Name);
        }
        for(Zip_Code_Rule__c existingRule:[Select Name From Zip_Code_Rule__c where Name in :newRuleNames]){
            existingRuleNames.add(existingRule.Name);
        }
        for(Zip_Code_Rule__c r:rules){
           if(existingRuleNames.contains(r.Name)){
              r.addError(System.Label.Duplicate_Zip_Code_Rule);
           }
        }
    }
}