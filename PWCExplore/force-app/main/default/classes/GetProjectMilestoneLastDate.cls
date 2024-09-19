/*------------------------------------------------------------------------
    Author:        Anupam Mishra && Shankar Sahu
    Company:       GITL
    Description:   Controller class for FOC Number Lightning components.
    Inputs:        NA
    Test Class:    TestGetProjectMilestoneLastDate
    ----------------------------------------------------------------------------*/

    public class GetProjectMilestoneLastDate {
     
      // Method to call FOC API with future method
     
        public static list<id> callFocAPI(List<Id> PmId) {
         system.debug('PMid'+PmId[0]);
         list<id> allids= new list<id>(PmId);
           
           /*  Id profileId= UserInfo.getProfileId();
            String profileName='';
            
            List<Profile> pro;
            
            pro = [Select Id,Name from Profile where Id=:profileId];
            
            if(pro != null && pro.size() > 0)
                profileName = pro[0].Name;
            
            if( profileName != 'Integration Administrator' ){ */
            
            callGetLastDate(PmId[0]);
            return allids;
              }
              
         //}                          
        @future(callout=true)
        public static void callGetLastDate(Id PmId) {
        system.debug('Ino 2ndst line');
            GetLastDate( PmId); 
         }
     
        @AuraEnabled
        
       /*Method to get the delivery date for Foc Number */  
        public static String GetLastDate( Id PmId) { 
           
            List<String> FocNumbers = new List<String>();      
            set<string>FocNumbersSet = new set<String>();                      
            Project_milestone__c ProjectMilestones=[ select recordtype.developername,name,
                                                    Project_Number__c,Foc_Number__c,Service_Request__c  from Project_milestone__c where Id =: PmId ];
            
            Id caseIds = ProjectMilestones.Service_Request__c;
           
            list<Project_milestone__c> SupplyPmIDs=[select id from project_milestone__c where service_request__r.id=:caseIds and recordtypeid=:system.label.PMSupplyRecordTypeId limit 1 ];
            
            list<String> FcNumbers =  ProjectMilestones.FOC_Number__c.remove(' ').split(',');
            
            FocNumbersSet.addAll(FcNumbers);
            FocNumbers.addAll(FocNumbersSet);
            //Serialize the list of FOC No into Json String
            
            String jsonString = JSON.serialize(FocNumbers);
            //Get the response            
            FOCNumberExtension requestorObject = new FOCNumberExtension();
            HttpResponse response = requestorObject.generateRequest(jsonString);
            Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
            //For the status Code 204 in response                                   
            if((response.getBody()).contains( '"Order lines not delivered yet"') && SupplyPmIDs.size()>0){                
                    Project_Milestone__c pmc = new Project_Milestone__c(
                     Id = PmId,
                     FOC_Last_synced__c=system.now(),
                     FOC_End_Date_status__c = 'Order lines not delivered yet'                                    
                    );
                
                    Project_Milestone__c pmc2 = new Project_Milestone__c(
                     Id = SupplyPmIDs[0].id,
                     Status__c='Work in progress',
                      End_Date__c=null
                                                         
                    );
                
                 update pmc;
                 update pmc2;
                
                 return 'Order lines not delivered yet, please refresh this page.';
                }else 
              //For the status code 200 in response
             if(response.getStatusCode() == 200 && SupplyPmIDs.size()>0){                       
                 string newDeserialized  = string.valueOf(responseMap.get('deliveryDate'));
                 if(newDeserialized !=''){
                 system.debug('>>>RES BODY>>>'+newDeserialized);
                 Date dt = Date.parse( newDeserialized );
                 system.debug(' Parsed Date is ' + dt );                                                                
                 Project_Milestone__c pmc = new Project_Milestone__c(
                     Id = SupplyPmIDs[0].id,
                     End_Date__c = dt
                 );
                     Project_Milestone__c pmc2 = new Project_Milestone__c(
                     Id = PmId,
                     
                     FOC_End_Date_status__c = 'Success',
                     FOC_Last_synced__c=system.now()
                 );
                 update pmc;
                 update pmc2;    
                  }
                 }
                  return 'End Date successfully updated , please refresh this page.';
            }       
        
    }