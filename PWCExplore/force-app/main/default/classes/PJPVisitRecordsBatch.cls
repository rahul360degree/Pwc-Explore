global class PJPVisitRecordsBatch implements Database.Batchable<sObject>,Schedulable {
    global void execute(SchedulableContext sc)
    {
        PJPVisitRecordsBatch b = new PJPVisitRecordsBatch(); // Your batch class
        database.executeBatch(b,300);
    }
    global Date today = Date.today();
    global Integer year = today.year();
    global Integer month = today.month();
    global Integer nextmonth = (month == 12) ? 1 : month+1;
    global Integer nextyear = (month==12) ? year+1 : year;
    
    global String formattedMonth = (nextmonth < 10) ? '0'+String.valueOf(nextmonth) : String.valueOf(nextmonth);
	global DateTime firstdayofmonthstring = DateTime.valueOf(String.valueOf(nextyear)+'-'+formattedMonth+'-'+'01 9:00:00.00');
    
    global DateTime firstdayofmonth = DateTime.newInstance(nextyear,nextmonth,1,9,0,0);
    global DateTime lastdayofmonth = firstdayofmonth.addMonths(1).addDays(-1);
    global Integer Category;
    global List<Visit__c> visitscreate = new List<Visit__c>(); 
    global List<Id> LocksUsers = new List<Id>();
    global List<Id> appliancesandssdUsers = new List<Id>();
    global List<Id> InterioUsers = new List<Id>();
    global List<PJP__c> InsertedPJPs = new List<PJP__c>();
    global Database.QueryLocator start(Database.BatchableContext BC){
        List <PJP__C> createdpjp = new List<PJP__C>();
        createdpjp=[Select OwnerId from PJP__C where Start_Date__c = :firstdayofmonth];
        return Database.getQueryLocator([SELECT Id, Username,Business_Unit__c,Name FROM User where userRole.Name Like 'Appliances Area%' AND Id NOT IN (Select OwnerId from PJP__C where Start_Date__c =: firstdayofmonthstring )]) ;
    }
    
    global void execute(Database.BatchableContext BC, List<User> scope){
        system.debug('hihi');
        List<Id> userIds = new List<Id>();
        Set<Id> useridssets = new Set<Id>();
        for(User sc:scope){
          useridssets.add(sc.Id);
          //system.debug('useridsdata'+sc.Id);
        }
        
        system.debug('userid'+useridssets.size());
        //quering the Visit_Creation_Logic__mdt records
        List<Visit_Creation_Logic__mdt> visitCreationLogic = new List<Visit_Creation_Logic__mdt>();
            visitCreationLogic =[Select Business_Unit__c,Business_Unit_API_Name__c,Type_of_account_Api_Name__c,BU_Role__c,Category_A__c,Category_B__c,Category_C__c,Type_of_Visit__c From Visit_Creation_Logic__mdt];
        //creating a map of Visit_Creation_Logic__mdt records
        Map<String,List<Visit_Creation_Logic__mdt>> basedonBUMap = new Map<String,List<Visit_Creation_Logic__mdt>>();
        for(Visit_Creation_Logic__mdt vis : visitCreationLogic){
            if(!basedonBUMap.containsKey(vis.Business_Unit_API_Name__c)){
                basedonBUMap.put(vis.Business_Unit_API_Name__c,new List<Visit_Creation_Logic__mdt>{vis});
            }
            else{
                basedonBUMap.get(vis.Business_Unit_API_Name__c).add(vis);
            }
        }
        system.debug('basedonBUMap'+basedonBUMap);
        List<Account> listOfAccounts = new List<Account>();
        //quering the account records
        
        listOfAccounts = [Select id,Name,OwnerId,Category__c,Type,Business_Unit__c,Owner.Business_Unit__c From Account where (OwnerId =: useridssets) AND ((Owner.Business_Unit__c IN ('H','U') and Type IN('3','E')) OR (Owner.Business_Unit__c = 'L' and Type IN('3')) OR (Owner.Business_Unit__c='W' and Type IN('3','D')))];

        system.debug('accounts'+listOfAccounts.size());
        
        //system.debug('acc'+acc);
        //creating a map of Account records
        Map<Id,List<Account>> uservsAccount = new Map<Id,List<Account>>();
        for(Account acc : listOfAccounts){
            if(!uservsAccount.containsKey(acc.OwnerId)){
                uservsAccount.put(acc.OwnerId,new List<Account>{acc});
                userIds.add(acc.OwnerId);
                //system.debug('acc.OwnerId'+userIds);
            }
            else{
                uservsAccount.get(acc.OwnerId).add(acc);
            }
        }
        List<User> haveaccounts = new List<User>();
        for(User haveacc : scope){
            if(userIds.contains(haveacc.Id)){
                haveaccounts.add(haveacc);
                system.debug('haveacc'+haveaccounts);
            }
        }
        integer size = scope.size();
        system.debug('size'+size);
        
        //creating PJP records
     	Map<String,String> mapofASM_PJP = new Map<String,String>();
       	List<PJP__c> pjpList = new List<PJP__c>();
        for (User us : haveaccounts){
            pjpList.add(new PJP__c(Name=us.Name +'-'+String.valueOf(Date.today().addMonths(1).toStartOfMonth()),
                                     Business_Unit__c = us.Business_Unit__c,
                                     OwnerId = us.Id,
                                   	 Start_Date__c = DateTime.newInstance(nextyear,nextmonth,1,9,0,0),
                                     End_Date__c = firstdayofmonth.addMonths(1).addDays(-1),
                                     Status__c = 'Draft'
                                    ));
                
          //system.debug('pjprecordis'+pjpList); 
        }
        integer pjpsize = pjpList.size();
        system.debug('pjpsize'+pjpsize);
        
            if(pjpList != null && pjpList.size() > 0){
                List<Id> PJPIds = PJPSaveResult(pjpList);
                InsertedPJPs = [select id,name,Business_Unit__c,OwnerId,Start_Date__c,End_Date__c,Status__c from PJP__c where Id =: PJPIds];
                //insert pjpList;
                for(PJP__c pjpRecord : InsertedPJPs){
            	mapofASM_PJP.put(pjpRecord.OwnerId, pjpRecord.Id);
                //system.debug(mapofASM_PJP);
        		}
            }
        CustomNotificationType notifytype = [Select Id from CustomNotificationType where CustomNotifTypeName='PJP Record Creation Notification'];
        for(PJP__c listofPJPs : InsertedPJPs){
            Messaging.CustomNotification msg = new Messaging.CustomNotification();
            
            msg.setTitle('New PJP Record is been Created');
            msg.setBody('A new PJP had been Assigned to you.');
            msg.setNotificationTypeId(notifytype.Id);
            msg.setTargetId(listofPJPs.Id);
            
            set<String> users = new set<String>{listofPJPs.OwnerId};
            msg.send(users);
        }
        
        //fetching the accounts based on the users
        for(Id listofusers : userIds){
          Id pjpid=mapofASM_PJP.get(listofusers);
          List<Account> useracc =  uservsAccount.get(listofusers);
            //system.debug('useracc'+useracc);
            //Logic for visit creation
            DateTime d = firstdayofmonth;
            Integer count = 0;
            
            for(Account accofUser : useracc){
                //system.debug('accofUser.Business_Unit__c'+accofUser.Owner.Business_Unit__c);
                //fetching the metadata record from the map based on the accounts Business unit & Record Type
                List<Visit_Creation_Logic__mdt> basedonAccBU = basedonBUMap.get(accofUser.Owner.Business_Unit__c);
                system.debug('basedonAccBU'+basedonAccBU);
                Map<String,Visit_Creation_Logic__mdt> visitlogicmap = new Map<String,Visit_Creation_Logic__mdt>();
                for(Visit_Creation_Logic__mdt metadatamap : basedonAccBU){
                 visitlogicmap.put(metadatamap.Type_of_account_Api_Name__c,metadatamap);
            	}
                Visit_Creation_Logic__mdt record = visitlogicmap.get(accofUser.Type);
                
                if(accofUser.Category__c == 'A'){
                    Category = (Integer)record.Category_A__c;
                }
                else if(accofUser.Category__c == 'B'){
                    Category = (Integer)record.Category_B__c;
                } 
                else{
                    Category = (Integer)record.Category_C__c;
                }
                //visit creation
                Id devRecordTypeId = Schema.SObjectType.Visit__c.getRecordTypeInfosByName().get(record.Type_of_Visit__c).getRecordTypeId();
                for(Integer i = 1; i <= Category ; i++){
                    	Visit__c vc = new Visit__c();
                        vc.Name=accofUser.Name +'-'+i+'-'+String.valueOf(Date.today().addMonths(1).toStartOfMonth());
                    	vc.Visit_Category__c='Planned';
                    	vc.RecordTypeId = devRecordTypeId;
                    	vc.Status__c='Not Started';
                    	vc.Account__c=accofUser.Id;
                    	vc.OwnerId=listofusers;
                        vc.PJP__c=pjpid;
                    if(!d.format('EEEE').equals('Sunday')){
                        vc.Visit_Scheduled_Date__c=d;
                        vc.Visit_Planned_Date__c=d;
                    }
                    else{
                        d=d.addDays(2);
                        vc.Visit_Scheduled_Date__c=d;
                        vc.Visit_Planned_Date__c=d;
                    } 
                     	d=d.addDays(2);
                    if(d > lastdayofmonth){
                        d=firstdayofmonth;
                        if(Math.Mod(count,2)==0){
                          d=d.addDays(1);
                        }
                        count = count+1;
                    }
                    visitscreate.add(vc);
                    //system.debug('visitrecord'+visitscreate);
                }
            }
            }
        integer listsize = visitscreate.size();
        system.debug('listsize'+listsize);
        insert visitscreate;
        }
	global void finish(Database.BatchableContext BC){
        system.debug('finish');
    }
    global List<Id> PJPSaveResult(List<Sobject> insertRecords){
        List<Id> lisofIds = new List<Id>();
    	Database.SaveResult[] srList = Database.insert(insertRecords, false);

       
        for (Database.SaveResult sr : srList) {
            if (sr.isSuccess()) {
                System.debug('Successfully inserted account. Account ID: ' + sr.getId());
                lisofIds.add(sr.getId());
            }
            else {              
                for(Database.Error err : sr.getErrors()) {
                    System.debug('The following error has occurred.');                    
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    System.debug('Account fields that affected this error: ' + err.getFields());
                }
            }  
        }
        return lisofIds;
    }
}