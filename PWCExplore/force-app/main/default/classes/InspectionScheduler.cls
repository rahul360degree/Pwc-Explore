public with sharing class InspectionScheduler implements Schedulable {
    public void execute(SchedulableContext ctx) {
        Map<Id, Case> accountIdtoCaseMap = new Map<Id, Case>();
        Map<Id, WorkOrder> accountIdtoWorkOrderMap = new Map<Id, WorkOrder>();
        for(Account a : [SELECT ID,RecordTypeId,BP_Code__c,(SELECT ID FROM Contacts LIMIT 1) FROM Account WHERE BP_Code__c != NULL AND RecordType.DeveloperName = 'Dealer' AND Id IN (SELECT AccountId FROM Contact)]) {
            Case inspectionCases = new Case();
            WorkOrder inspectionWorkOrders = new WorkOrder();
            inspectionCases.AccountId = a.Id;
            inspectionCases.ContactId = a.Contacts.isEmpty() ? null : a.Contacts[0].Id;

            inspectionWorkOrders.AccountId = a.Id;
            inspectionWorkOrders.ContactId = a.Contacts.isEmpty() ? null : a.Contacts[0].Id;
        
            accountIdtoCaseMap.put(a.Id, inspectionCases);
            accountIdtoWorkOrderMap.put(a.Id, inspectionWorkOrders);
        }
        List<ServiceAppointment> serviceAppList = new List<ServiceAppointment>();

        // WorkType workTypeRecord = [SELECT ID,ShouldAutoCreateSvcAppt FROM WorkType WHERE ShouldAutoCreateSvcAppt = TRUE LIMIT 1];
        if(!accountIdtoCaseMap.isEmpty()) {
            insert accountIdtoCaseMap.values();
            for(Case c : accountIdtoCaseMap.values()) {
                WorkOrder wo = accountIdtoWorkOrderMap.get(c.AccountId);
                wo.CaseId = c.Id;
                ServiceAppointment ss = new ServiceAppointment();
                ss.ContactId = c.ContactId;
                ss.SchedStartTime = System.now() +1;
                ss.SchedEndTime = System.now() + 2;
                ss.DueDate = System.now() + 1;
                ss.EarliestStartTime = System.now();
                ss.Order_type__c = 'Repair';
                ss.PostalCode = '6025';
                ss.Installation_Type__c = 'CHOTUKOOL';
                ss.ParentRecordId = c.Id;
                serviceAppList.add(ss);
                // wo.WorkTypeId = workTypeRecord.Id;
                accountIdtoWorkOrderMap.put(c.AccountId, wo);
            }
            insert accountIdtoWorkOrderMap.values();
            insert serviceAppList;
        } 
    }

    // InspectionScheduler scheduler = new InspectionScheduler();
    // String jobName = 'Inspection_Scheduler_Job';
    // String scheduleExpression = '0 0 0 1,16 * ? *';
    // System.schedule(jobName, scheduleExpression, scheduler);
}