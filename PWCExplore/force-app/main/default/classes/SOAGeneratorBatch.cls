/**
 * @description       : 
 * @author            : vrajpoot@godrej.com
 * @group             : 
 * @last modified on  : 01-31-2023
 * @last modified by  : vrajpoot@godrej.com
**/
global class SOAGeneratorBatch implements Database.Batchable<sObject>,Schedulable{    
    global final string query;
    global SOAGeneratorBatch(){
        query = 'SELECT Id, Name, OwnerId,Owner.ManagerId,Owner.Manager.ManagerId, DSA_Contact_User__c, Account_Code__c,Primary_Address__r.ZipCode__r.CityCode__c,Area_Code_of_Owner__c '
                +'FROM Account where (Account_Code__c like \'HDX%\' OR Account_Code__c like \'3HX%\' ) and DSA_Automation_Level__c IN(\'Email\',\'Full\')  ';
    } 

    global Database.QueryLocator start(Database.BatchableContext BC){    
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope){
        SOAGeneratorHelper helper = new SOAGeneratorHelper();        
        List<Account> accountList = (List<Account>) scope;
        List<Statement_Of_Account__c> lstSOA = new List<Statement_Of_Account__c>();
        List<String> lstCityCodes = new List<String>();
        for(Account record : accountList){
            lstCityCodes.add(record.Primary_Address__r.ZipCode__r.CityCode__c);
        }
        Map<String, Id> mapUserIDSalaryCode = helper.userMapWithSalaryCode();
        Map<String, Id> mapCityCodeBA = helper.getBrandedAccounttantCity(mapUserIDSalaryCode,lstCityCodes);
        Date dtToday  = helper.dtDate();
        Map<String,Branch_Accountant_Area_Code_Mappings__mdt> branchAccountantAreaCodeMAP = Branch_Accountant_Area_Code_Mappings__mdt.getAll();
       //Code to set Branch Accountant
        Set<String> salaryCodes = new Set<String>();
        for(Branch_Accountant_Area_Code_Mappings__mdt record:branchAccountantAreaCodeMAP.values()){
            salaryCodes.add(record.Branch_Accountant_Salary_Code__c);
        }
        Map<String,Id> salaryCodeWithUserId = new Map<String,Id>();
        for(User user:[Select Id,Salary_Code__c from User where Salary_Code__c IN:salaryCodes]){
            salaryCodeWithUserId.put(user.Salary_Code__c,user.Id);
        }


        for(Account acn : accountList){
            Statement_Of_Account__c soa = helper.initializeSOA(acn,dtToday,mapCityCodeBA,
            branchAccountantAreaCodeMAP,salaryCodeWithUserId);
            lstSOA.add(soa);
        }

        if(!lstSOA.isEmpty()){
            helper.createSOARecords(lstSOA);
        }
    }
    
    global void finish(Database.BatchableContext BC){
        system.debug('Finished my first batch class!');
    }


    public void execute(SchedulableContext ctx) {
        Integer batchSize  = GlobalConstants.DEFAULT_BATCH_SIZE;
        SOAGeneratorBatch soa = new SOAGeneratorBatch(); 
        Database.executeBatch(soa,batchSize);
    }
    
}