public class LeadCreationFormController {
    
    @AuraEnabled
    public static String createLead(String selectedProductId, Decimal quantity, Decimal finalSalePrice, String preferredTime,
                                    String billToLocation, String shipToLocation, Boolean externalMaterialPurchase, String invoiceNumber, Date invoiceDate,
                                    String existingSecurityStrength, String proposedSecurityStrength, String entryPoint, String competitionReplaced,String recordId) {
                                        try {
                                            List<ServiceAppointment> serviceApptList = [SELECT ASP_Account__c,Street,City,PostalCode,State,Country ,ParentRecordId,AccountId, Account.FirstName, Account.LastName,Account.PersonEmail,Account.PersonMobilePhone FROM ServiceAppointment WHERE ParentRecordId =: recordId];
                                              List<ServiceTerritoryMember> serviceTerritoryList = [SELECT ASP_Account_Id__c, ServiceResource.RelatedRecordId,Dispatcher__c,ServiceResource.ASP_Account__r.Id FROM ServiceTerritoryMember WHERE ServiceResource.ASP_Account__r.Id = :serviceApptList[0].ASP_Account__c AND Dispatcher__c = TRUE];
                                            System.debug('SA-->' + serviceApptList);
                                            //    System.debug('STM-->' + serviceTerritoryList);
                                            System.debug('Inside 1234');
                                            
                                            List<RecordType> recordTypeList = [SELECT Id, Name, SobjectType 
                                                                               FROM RecordType 
                                                                               WHERE SobjectType = 'Lead' AND DeveloperName = 'Lead_from_FSL'];
                                            System.debug('62' + serviceApptList[0].Street);
                                            Lead newLead = new Lead();
                                            newLead.Product__c = selectedProductId;
                                            newLead.FirstName = serviceApptList[0].Account.FirstName;
                                            newLead.LastName = serviceApptList[0].Account.LastName;
                                            newLead.Work_Order_Line_Item__c = recordId;
                                            newLead.Quantity__c = quantity;
                                            newLead.Street = serviceApptList[0].Street;
                                            newLead.City = serviceApptList[0].City;
                                            newLead.PostalCode = serviceApptList[0].PostalCode;
                                            newLead.State = serviceApptList[0].State;
                                            newLead.Country = serviceApptList[0].Country;
                                            newLead.Email = serviceApptList[0].Account.PersonEmail;
                                            newLead.MobilePhone = serviceApptList[0].Account.PersonMobilePhone;
                                            newLead.Final_Sale_Price__c = finalSalePrice;
                                            newLead.Account__c = serviceApptList[0].AccountId;
                                            newLead.Preferred_Time_to_Call__c = preferredTime;
                                            newLead.Bill_to_Location__c = billToLocation;
                                            newLead.Ship_to_Location__c = shipToLocation;
                                            newLead.External_Material_Purchase__c = externalMaterialPurchase;
                                            newLead.Invoice_Number__c = invoiceNumber;
                                            newLead.Invoice_Date__c = invoiceDate;
                                            newLead.Existing_Security_Strength__c = existingSecurityStrength;
                                            newLead.Proposed_Security_Strength__c = proposedSecurityStrength;
                                            newLead.Entry_Point__c = entryPoint;
                                            newLead.LeadSource = 'Field Service';
                                            newLead.Competition_Replaced__c = competitionReplaced;
                                            newLead.OwnerId = '005C4000002YEllIAG';//serviceTerritoryList[0].ServiceResource.RelatedRecordId;
                                            newLead.RecordTypeId = recordTypeList[0].Id; // Assigning the record type Id
                                            System.debug('Lead-->' + newLead);
                                            insert newLead;
                                            CustomNotificationType notificationType = [ SELECT Id, DeveloperName FROM CustomNotificationType
                                                                                       WHERE DeveloperName = 'Cancelled_SA_Notification_to_ASP' Limit 1
                                                                                      ];
                                            
                                            Messaging.CustomNotification notification = new Messaging.CustomNotification();
                                            
                                            notification.setTitle('Lead is assigned to you');
                                            notification.setBody('Please Check the lead assigned');
                                            notification.setTargetId(newLead.Id); 
                                            notification.setNotificationTypeId(notificationType.Id);
                                            
                                            Set<String> targetIds = new Set<String>();
                                            targetIds.add('005C4000002YEllIAG'); 
                                            
                                            try {
                                                notification.send(targetIds);
                                            }
                                            catch (Exception e) {
                                                System.debug('Problem sending notification: ' + e.getMessage());
                                            }
                                            return 'Lead created successfully.';
                                        } catch (Exception e) {
                                            System.debug('Exception--->' + e.getMessage());
                                            return 'Error creating lead: ' + e.getMessage();
                                        }
                                        
                                        
                                    }
    // Method to retrieve the Record Type Id for the given Developer Name
    public static Id getLeadRecordTypeId(String developerName) {
        Map<String, Schema.RecordTypeInfo> rtMap = Lead.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName();
        Id recordTypeId = rtMap.get(developerName).getRecordTypeId();
        return recordTypeId;
    }
    
    @AuraEnabled(cacheable=true)
    public static Boolean isLocksBusinessUnit(Id workOrderLineItemId) {
        System.debug('HIII');
        
        List<WorkOrderLineItem> woliList = [SELECT Id, WorkOrderId, WorkOrder.Business_Unit__c FROM WorkOrderLineItem WHERE Id = :workOrderLineItemId LIMIT 1];
        System.debug('CHECKKKK===' + woliList[0].WorkOrder.Business_Unit__c);
        
        if (woliList != null && woliList[0].WorkOrder != null && woliList[0].WorkOrder.Business_Unit__c != null) {
            System.debug('CHECKKKK===' + woliList[0].WorkOrder.Business_Unit__c);
            return woliList[0].WorkOrder.Business_Unit__c == 'Locks';
        }
        System.debug('HIII');
        return false;
    }
}