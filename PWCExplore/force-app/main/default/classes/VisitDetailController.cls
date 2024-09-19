public class VisitDetailController {
    public Visit__c visit { get; set; }
    public String visitRecordTypeName { get; set; }

    public VisitDetailController(ApexPages.StandardController controller) {
        Id visitId = ApexPages.currentPage().getParameters().get('id');
        visit = [SELECT Id, OwnerId, RecordType.Name, 
                         Name, 
                         Account__r.Name, 
                         Account_Email_ID__c, 
                         Action_Plan_ASP_Stock_And_Inventory__c, 
                         Action_Plan_SDP__c, 
                         Action_Plan_SR__c, 
                         Action_Plan_General_Observation__c, 
                         Action_Plan_Outstanding__c, 
                         Action_Plan_Process_and_System_Adherence__c, 
                         Action_Plan_Showroom_Observation__c, 
                         Action_Plan_Service_Infrastructure__c,
                         Action_Plan_Warehouse_Observation__c, 
                         Action_Plan_Revenue_Observation__c, 
                         Additional_Observations__c, 
                         Address__c, 
                         Any_specific_customer_remark_about_the_t__c, 
                         ASP_Email_ID__c, 
                         ASP_Stock_Inventory__c, 
                         ASP_Technician_is_able_to_demonstrate_us__c, 
                         ASP_Technician_is_carrying_First_Aid_Box__c, 
                         ASP_Technician_is_carrying_proper_tools__c, 
                         ASP_Technician_is_carrying_spares_for_ca__c,
                         ASP_Technician_is_in_uniform_and_carryin__c, 
                         ASP_Technician_is_maintaining_cleanlines__c, 
                         ASP_Technician_is_maintaining_customer_s__c, 
                         ASP_Technician_is_maintaining_personal_h__c, 
                         ASP_Technician_is_promoting_service_acce__c,
                         ASP_Technician_is_trained_enough_for_ass__c, 
                         ASP_Technician_is_trained_on_soft_skill__c,
                 		 Branch__c,
                         Business_Potential__c, 
                         Business_Unit__c, 
                         Contact_number__c, 
                         Current_Status_of_Complaints__c, 
                         Customer_Complaints__c, 
                         Customer_Location__c, 
                         Customer_type__c, 
                         Date__c, 
                         Designation__c, 
                         Email_id_Contacted_person__c, 
                         Email_to_be_sent_to__c, 
                         Geolocation__c, 
                         Member_Designation__c, 
                         Member_Name__r.Name, 
                         Name_of_the_Person_Interacted_with__c, 
                         Name_of_the_person_interacted_with_ASP__c, 
                         Next_Course_of_action__c, 
                         Observations_Pending_Issues__c, 
                         Outstanding__c, 
                         Overall_Remarks__c, 
                         Person_Met__c, 
                         Pincode__c, 
                         PJP__c, 
                         Points_Discussed__c, 
                         Potential_Realised__c, 
                         Process_and_System_Adherence__c, 
                         RecordTypeId, 
                         Remarks__c, 
                         Remarks_and_Observation__c, 
                         Remarks_by_Executive_PD_with_TP__c, 
                         Remarks_by_Executive_Customer_Complaints__c, 
                         Responsibility_ASP_Stock_And_Inventory__c, 
                         Responsibility_Outstanding__c, 
                         Responsibility_SDP__c, 
                         Responsibility_Process_and_System_Adhere__c, 
                         Responsibility_General_Observation__c, 
                         Responsibility_SR__c, 
                         Responsibility_Revenue_Observation__c, 
                         Responsibility_Warehouse_Observation__c, 
                         Responsibility_Showroom_Observation__c, 
                         Responsibility_Service_Infrastructure__c, 
                         Service_Delivery_Performance__c, 
                         Service_Revenue__c, 
                         Status__c, 
                         Target_Date_ASP_Stock_And_Inventory__c, 
                         Target_Date_Warehouse_Observation__c, 
                         Target_Date_Outstanding__c, 
                         Target_Date_Process_and_System_Adherence__c, 
                         Target_Date_Service_Infrastructure__c, 
                         Target_Date_SDP__c, 
                         Target_Date_SR__c, 
                         Target_Date_General_Observation__c, 
                         Target_Date_Revenue_Observation__c, 
                         Target_Date_Showroom_Observation__c, 
                         Team_Members__c, 
                         Technician_Code__c, 
                         Technician_Name__c, 
                         Trained_Technician_was_deputed_byb_ASP__c,
                 		 Visit_Category__c,
                         Visit_End_Date__c, 
                         Visit_Planned_Date__c, 
                         Visit_Scheduled_Date__c, 
                         Visit_Start_Date__c, 
                         Warehouse_Email_ID__c, 
                         Zero_Pendency_Certificate__c, 
                         Zone__c 
                     FROM Visit__c 
                     WHERE Id = :visitId];
        
        visitRecordTypeName = visit.RecordTypeId;
    }
    @InvocableMethod(label='Visit Details PDF' description='Generates and Emails Visit Details PDF')
    public static void generatePDF(List<List<String>> args){
        
        OrgWideEmailAddress orgWideEmailObj = [SELECT Id, Address FROM OrgWideEmailAddress where Address = 'onecrm@godrej.com' ];
        List<String> nested = args[0];
        
        String email1 = nested[0];
        String email2 = nested[1];
        String visitId = nested[2];
        String visitRecordTypeName = nested[3];
        
        PageReference visitdetailsPDF;
        
        if(visitRecordTypeName == 'ASP Visit'){
            visitdetailsPDF = new PageReference('/apex/ASPVisitDetailPage?id=' + visitId);
        }
        
        else if (visitRecordTypeName == 'Trade Partner Visit'){
            visitdetailsPDF = new PageReference('/apex/TradePartnerVisitDetailPage?id=' + visitId);
        }
        else if (visitRecordTypeName == 'Dealer Visit'){
            visitdetailsPDF = new PageReference('/apex/DealerVisitDetailPage?id=' + visitId);
        }
        else if (visitRecordTypeName == 'Service Camp'){
            visitdetailsPDF = new PageReference('/apex/ServiceCampDetailPage?id=' + visitId);
        }
        
        Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
        attachment.setContentType('application/pdf');
        attachment.setFileName('Visit Details.pdf');
        
        if(!test.isRunningTest()){
            attachment.body = visitdetailsPDF.getContent();
        } else {
           attachment.body = blob.valueOf('blob');
        }
        
        attachment.setInline(false);
        
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new String[] {email1});
        mail.setCcAddresses(new String[] {email2});
        mail.setSubject('Visit Details PDF');
        mail.setHtmlBody('Here\'s the Visit Details PDF you requested.');
        mail.setFileAttachments(new Messaging.EmailFileAttachment[] { attachment });
        mail.setOrgWideEmailAddressId(orgWideEmailObj.Id);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
}