public class JobSheetController {
    public String accountName { get; set; }
    public String businessUnit { get; set; }
    public String email { get; set; }
    public String callCentreNumber { get; set; }
    public String buLogo { get; set; } 
    public String orderType {get; set;}
    public String caseNumber {get; set;}
    public String customerName {get; set;}
    public String addressInfo {get; set;}
    public String pincode {get; set;}
    public String mobile {get; set;}
    public String customerType {get;set;}
    
    
    public JobSheetController(ApexPages.StandardController stdController) {
        System.debug('VfPage');
        Id recordId = stdController.getId();
        System.debug('RecordId-->' + recordId);
        List<workOrderLineItem> woliList = new List<WorkOrderLineItem>();
        woliList = [SELECT Id, WorkOrderId FROM WorkOrderLineItem WHERE Id = :recordId];
        System.debug('WoloiList-->' + woliList);
        if(woliList[0].WorkOrderId != null) {
            WorkOrder woRecord = [SELECT Business_Unit__c,Account.Type_of_Customer__c,Case.CaseNumber,Contact.Name,Contact.Address_Information__c,Contact.Address_by_BP__r.Address_Code__r.ZipCode__r.Name,Contact.MobilePhone FROM WorkOrder WHERE Id = :woliList[0].WorkOrderId LIMIT 1];
            if(woRecord != null) {
                System.debug('Inside-----');
                customerType = woRecord.Account.Type_of_Customer__c;
                businessUnit = woRecord.Business_Unit__c;
                caseNumber = woRecord.Case.CaseNumber;
                customerName = woRecord.Contact.Name;
                addressInfo = woRecord.Contact.Address_Information__c;
                pincode = woRecord.Contact.Address_by_BP__r.Address_Code__r.ZipCode__r.Name;
                mobile = woRecord.Contact.MobilePhone;
                System.debug('Pincode-->' + pincode );
                List<JobSheet_Configration__mdt> configList = [SELECT Email__c, Call_Centre_Number__c, BU_logo__c 
                                                               FROM JobSheet_Configration__mdt 
                                                               WHERE DeveloperName = :businessUnit 
                                                               LIMIT 1];
                // Check if any custom metadata record is found
                if(!configList.isEmpty()) {
                    System.debug('Getting WOLI');
                    
                    JobSheet_Configration__mdt configRecord = configList[0];
                    email = configRecord.Email__c;
                    callCentreNumber = configRecord.Call_Centre_Number__c;
                    buLogo = configRecord.BU_logo__c;
                }
            }
            
        }
        List<ServiceAppointment> saList = [SELECT ASP_Account__r.Name,Order_type__c FROM ServiceAppointment WHERE ParentRecordId =:recordId];
        
        if(!saList.isEmpty()){
            System.debug('Inside--');
            System.debug('Buimage-->' + buLogo);
            ServiceAppointment saRecord = saList[0];
            accountName = saRecord.ASP_Account__r.Name;
            orderType = saRecord.Order_type__c;
        }
        
    }
}