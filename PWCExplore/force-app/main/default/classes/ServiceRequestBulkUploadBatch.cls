global class ServiceRequestBulkUploadBatch implements Database.Batchable<sObject>,Schedulable {
    
    global Map<Id, Case> caseRecsToUpdate = new Map<Id, Case>();
    global void execute(SchedulableContext sc)
    {
        ServiceRequestBulkUploadBatch b = new ServiceRequestBulkUploadBatch(); 
        database.executeBatch(b,5);
    }
    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator([Select Id,AccountId,ContactId,Mobile__c,Primary_Contact_Email__c,Case_Owner_Name__c,Records_Creation_Status__c,Address1__c,Address2__c,Address3__c,Address4__c,State__c,City__c,Country__c,Pincode__c from Case where Bulk_Upload__c=true]);
    }
    global void execute(Database.BatchableContext BC, List<Case> scope){
        List<Case> UpdateCase = new List<Case>();
        DateTime today = DateTime.NOW().addDays(3);
        DateTime startdate = DateTime.NOW().addDays(1);
        DateTime enddate = DateTime.NOW().addDays(1).addHours(1);
        List<WorkOrderLineItem> UpdateWoliRecords = new List<WorkOrderLineItem>();
        List<ServiceAppointment> listOfNewServiceAppointments = new List<ServiceAppointment>();
        List<WorkOrder> listOfNewWorkOrders = new List<WorkOrder>();
        List<WorkOrder> listOfBulkUploadWorkOrders = new List<WorkOrder>();
        List<WorkOrder> UpdateWorkOrderRecords = new List<WorkOrder>();
        List<WorkOrderLineItem> listOfNewWorkOrderLineItems = new List<WorkOrderLineItem>();
        List<Case> UpdateCases = new List<Case>();
        List<String> phonenumberlist = new List<String>();
        List<String> emailList = new List<String>();
        List<Account> AccountList = new List<Account>();
        List<ContactPointPhone> cppList = new List<ContactPointPhone>();
        List<ContactPointEmail> cpeList = new List<ContactPointEmail>();
        List<ContactPointAddress> cpaList = new List<ContactPointAddress>();
        Map<Id,Id> accountIdvsContactId = new Map<Id,Id>();
        Map<Id,Id> accountIdvsAddressId = new Map<Id,Id>();
        Map<String,Id> mobilevsaccountId = new Map<String,Id>();
        Map<String,Id> emailvsaccountId = new Map<String,Id>();
        List<ContactPointEmail> listofcontactpointemail = new List<ContactPointEmail>();
        for(case cs : scope){
                if(cs.Mobile__c != NULL){
                    Boolean phoneNumberExists=phonenumberlist.contains(cs.Mobile__c);
                    if(phoneNumberExists == False){
                        phonenumberlist.add(cs.Mobile__c);
                    }  
                }
                if(cs.Primary_Contact_Email__c != NULL){
                    Boolean emailExists = emailList.contains(cs.Primary_Contact_Email__c);
                    if(emailExists == False){
                        emailList.add(cs.Primary_Contact_Email__c);
                    }  
                }
                system.debug('phonenumberlist'+phonenumberlist);
            system.debug('emaillist'+emailList);
                
                
        }
        system.debug('phonenumberlist'+phonenumberlist);
        if(!phonenumberlist.isEmpty() || !emailList.isEmpty()){
            
            List<ContactPointPhone> listofcontactpointphone = [select ParentId,TelephoneNumber from contactpointphone where TelephoneNumber IN :phonenumberlist];
            if(!emailList.isEmpty()){
                listofcontactpointemail = [select ParentId,EmailAddress from ContactPointEmail where EmailAddress IN : emailList];
            }
            
            
            if(!listofcontactpointphone.isEmpty()){
                for(ContactPointPhone ContactPointPhones : listofcontactpointphone){
                    if(ContactPointPhones.TelephoneNumber != NULL){
                        mobilevsaccountId.put(ContactPointPhones.TelephoneNumber,ContactPointPhones.ParentId);
                        system.debug('begining'+mobilevsaccountId);
                    }    
                }
            }
            if(!listofcontactpointemail.isEmpty()){
                for(ContactPointEmail ContactPointEmails : listofcontactpointemail){
                    if(ContactPointEmails.EmailAddress != NULL){
                        emailvsaccountId.put(ContactPointEmails.EmailAddress,ContactPointEmails.ParentId);
                    }   
                }
            }
            for(case caseAccountCreation :scope){
                Id ContactPointPhonerecord = mobilevsaccountId.get(caseAccountCreation.Mobile__c);
                Id ContactPointEmailrecord = emailvsaccountId.get(caseAccountCreation.Primary_Contact_Email__c);
                system.debug('ContactPointPhonerecord'+ContactPointPhonerecord);
                if(ContactPointPhonerecord == NULL && ContactPointEmailrecord == NULL){
                    account createaccount = new Account(
                        LastName=caseAccountCreation.Case_Owner_Name__c,
                        PersonMobilePhone=caseAccountCreation.Mobile__c,
                        PersonEmail=caseAccountCreation.Primary_Contact_Email__c,
                        BillingStreet = caseAccountCreation.Address1__c+'-'+caseAccountCreation.Address2__c+'-'+caseAccountCreation.Address3__c+'-'+caseAccountCreation.Address4__c,
                        BillingState=caseAccountCreation.State__c,
                        BillingCountry=caseAccountCreation.Country__c,
                        BillingCity=caseAccountCreation.City__c,
                        BillingPostalCode=caseAccountCreation.Pincode__c
                    );
                    AccountList.add(createaccount);
                }
            }
            system.debug('ok'+AccountList);
            List<Id> AccountIds = ServiceRequestSaveResult(AccountList);
        	List<Account> SuccessAccountRecords = [Select Id,LastName,PersonMobilePhone,PersonEmail,BillingStreet,BillingState,BillingCity,BillingCountry,BillingPostalcode from Account where Id =: AccountIds];
            
            for(Account accountContactPointsCreation :SuccessAccountRecords){
                mobilevsaccountId.put(accountContactPointsCreation.PersonMobilePhone,accountContactPointsCreation.Id);
                emailvsaccountId.put(accountContactPointsCreation.PersonEmail,accountContactPointsCreation.Id);
                ContactPointPhone cpp = new ContactPointPhone(
                    TelephoneNumber=accountContactPointsCreation.PersonMobilePhone,
                    ParentId=accountContactPointsCreation.Id
                );
                cppList.add(cpp);
                if(accountContactPointsCreation.PersonEmail != NULL){
                    ContactPointEmail cpe = new ContactPointEmail(
                        EmailAddress=accountContactPointsCreation.PersonEmail,
                        ParentId=accountContactPointsCreation.Id
                    );
                    cpeList.add(cpe);
                }
                ContactPointAddress cpa = new ContactPointAddress(
                    Name=accountContactPointsCreation.LastName,
                    Street = accountContactPointsCreation.BillingStreet,
                    State=accountContactPointsCreation.BillingState,
                    Country=accountContactPointsCreation.BillingCountry,
                    City=accountContactPointsCreation.BillingCity,
                    PostalCode=accountContactPointsCreation.BillingPostalCode,
                    ParentId=accountContactPointsCreation.Id
                );
                cpaList.add(cpa);
            }
            if(!cppList.isEmpty()){
                insert cppList;
                
            }
            if(!cpeList.isEmpty()){
                insert cpeList;
            }
            if(!cpaList.isEmpty()){
                insert cpaList;
            }
            List<Contact> listofcontacts = [select id,AccountId from Contact where AccountId IN : mobilevsaccountId.Values() or AccountId IN : emailvsaccountId.Values() ];
            List<ContactPointAddress> listofcpa = [select id,ParentId from ContactPointAddress where ParentId IN : mobilevsaccountId.Values() or ParentId IN : emailvsaccountId.Values()];
            for(Contact contacts : listofcontacts ){
                if(!listofcontacts.isEmpty()){
                    accountIdvsContactId.put(contacts.AccountId,contacts.id);
                }
            }
            for(ContactPointAddress contactpointadd : listofcpa){
                if(!listofcpa.isEmpty()){
                    accountIdvsAddressId.put(contactpointadd.ParentId,contactpointadd.Id);
                }
            }
            for(case cases:scope){
                if(cases.AccountId == NULL){
                    Id accountrecords = mobilevsaccountId.get(cases.Mobile__c);
                    system.debug('test'+accountrecords);
                    Id contactId = accountIdvsContactId.get(accountrecords);
                    Id addressId = accountIdvsAddressId.get(accountrecords);
                    if(accountrecords != NULL){
                        system.debug('contactrecordsid'+accountrecords);
                        cases.AccountId=accountrecords;
                        
                        if(contactId != NULL){
                            cases.ContactId=contactId;
                        }
                        if(addressId != NULL){
                            cases.Contact_Point_Address__c=addressId;
                        }
                        UpdateCases.add(cases);
                    }
                    else{
                        Id accountemailrecord = emailvsaccountId.get(cases.Primary_Contact_Email__c);
                        cases.AccountId=accountemailrecord;
                        
                        if(contactId != NULL){
                            cases.ContactId=contactId;
                        }
                        if(addressId != NULL){
                            cases.Contact_Point_Address__c=addressId;
                        }
                        UpdateCases.add(cases);
                    }
                }
            }
            Update UpdateCases;
        }
        //work order creation
        for(Case blkCases :scope){
           WorkOrder workOrderCreation = new WorkOrder(
               AccountId=blkCases.AccountId,
               ContactId=blkCases.ContactId,
               CaseId=blkCases.Id
           );
           listOfNewWorkOrders.add(workOrderCreation);
       }
        //woli creation
        List<Id> workOrderIds = ServiceRequestSaveResult(listOfNewWorkOrders);
        List<WorkOrder> SuccessWorkOrder = [Select Id,CaseId,AccountId,ContactId,Case.Records_Creation_Status__c from WorkOrder where Id =: workOrderIds];
        for(WorkOrder workorder : SuccessWorkOrder){
            UpdateCase = UpdateCaseRecord(workorder.CaseId,'Work Order Created'); 
            WorkOrderLineItem workOrderLineItemCreation = new WorkOrderLineItem(
            	WorkOrderId=workorder.Id
            );
            listOfNewWorkOrderLineItems.add(workOrderLineItemCreation);
        }
        //service appointment creation
        List<Id> workOrderLineItemIds = ServiceRequestSaveResult(listOfNewWorkOrderLineItems);
        List<WorkOrderLineItem> SuccessWorkOrderLineItem = [Select Id,WorkOrder.CaseId,WorkOrder.Case.Address1__c,WorkOrder.Case.Address2__c,WorkOrder.Case.Address3__c,WorkOrder.Case.Address4__c,WorkOrder.Case.State__c,WorkOrder.Case.City__c,WorkOrder.Case.Country__c,WorkOrder.Case.Pincode__c,WorkOrder.Case.Service_Request_Type__c,WorkOrder.Case.Product_Category__c from WorkOrderLineItem where Id =: workOrderLineItemIds];
       
        for(WorkOrderLineItem woli : SuccessWorkOrderLineItem){
            UpdateCase = UpdateCaseRecord(woli.WorkOrder.CaseId,'Work Order Line Item Created'); 
            ServiceAppointment ServiceAppointmentCreation = new ServiceAppointment(
            	ParentRecordId=woli.Id,
                DueDate=today,
                EarliestStartTime=today,
                Service_Request__c=woli.WorkOrder.CaseId,
                Street = woli.WorkOrder.Case.Address1__c+'-'+woli.WorkOrder.Case.Address2__c+'-'+woli.WorkOrder.Case.Address3__c+'-'+woli.WorkOrder.Case.Address4__c,
                State=woli.WorkOrder.Case.State__c,
                Country=woli.WorkOrder.Case.Country__c,
                City=woli.WorkOrder.Case.City__c,
                PostalCode=woli.WorkOrder.Case.Pincode__c,
                //Status='Scheduled',
                SchedStartTime=startdate,
                SchedEndTime=enddate,
                Order_type__c=woli.WorkOrder.Case.Service_Request_Type__c,
                Installation_Type__c=woli.WorkOrder.Case.Product_Category__c
            );
          	listOfNewServiceAppointments.add(ServiceAppointmentCreation);
        }
        List<Id> ServiceAppointmentIds = ServiceRequestSaveResult(listOfNewServiceAppointments);
        List<ServiceAppointment> SuccessServiceAppointment = [Select Id,Service_Request__c from ServiceAppointment where Id =: ServiceAppointmentIds];
        for(ServiceAppointment ServiceApp : SuccessServiceAppointment){
            UpdateCase = UpdateCaseRecord(ServiceApp.Service_Request__c,'Service Appointment Created'); 
        }
         
        Update UpdateCase;
    }
    global void finish(Database.BatchableContext BC){
        system.debug('finish');
    }
    global List<Id> ServiceRequestSaveResult(List<Sobject> insertRecords){
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
    global List<Case> UpdateCaseRecord(Id CaseId,String CaseRecordStatus){ 
       
        if(!caseRecsToUpdate.containsKey(CaseId)) {
                Case tempCaseRec = new Case();
                tempCaseRec.Id = CaseId;
                tempCaseRec.Records_Creation_Status__c =CaseRecordStatus;
                caseRecsToUpdate.put(CaseId, tempCaseRec);
            } else {
                case tempCaseRec2 = caseRecsToUpdate.get(CaseId);
                tempCaseRec2.Records_Creation_Status__c =CaseRecordStatus;
                caseRecsToUpdate.put(CaseId, tempCaseRec2);
            }
        return caseRecsToUpdate.Values();
    }
}