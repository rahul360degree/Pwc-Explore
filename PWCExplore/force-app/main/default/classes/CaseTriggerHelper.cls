/*------------------------------------------------------------------------
Author:        Shailja Mishra
Company:       Salesforce
Description:   Helper class for Case Trigger
Inputs:        NA
Test Class:    CaseTriggerTest
---------------------------------------------------------------------------
History
16-09-2020      Shailja Mishra     Initial Release
25-04-2024      HansRaj Yadav      Added CaseDeduplication() for service implementation

----------------------------------------------------------------------------*/
public without sharing class CaseTriggerHelper {
    //Service Request record type id
     public static final Id SERVICE_REQUEST_RECORDTYPE_ID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(GlobalConstants.CASE_RECORDTYPE_SERVICE_REQUEST).getRecordTypeId();
    
    /*--------------------------------------------------------------------------
    Author:        Shailja Mishra
    Company:       Salesforce
    Description:   Method to validate Dealer/Retailer can create Service request type = 'REPAIR'
                   Before Insert
                   We have written this logic into the trigger because 'IsPartner' field on Account
                   cannot be accessed in the Validation rule/Formula field(Platform limitation).
    Inputs:        list of inserted records
    Test Class:   
    -----------------------------------------------------------------------------
    History
    16-09-2020      Shailja Mishra     Initial Release
    ----------------------------------------------------------------------------*/
    public static void validateServiceRequestForDealer(List<Case> newCases){
        List<Id> contactIds = new List<Id>();
        Set<Id> partnerContactIds = new Set<Id>();
        for(Case cs : newCases){
            contactIds.add(cs.ContactId);
        }
        
        partnerContactIds = getPartnerContactIds(contactIds);
        if(partnerContactIds.size() > 0){
            for(Case cs : newCases){
                if(partnerContactIds.contains(cs.ContactId)
                   && cs.RecordTypeId == SERVICE_REQUEST_RECORDTYPE_ID
                   && String.isNotBlank(cs.Service_Request_Type__c)
                   && !cs.Service_Request_Type__c.equals(GlobalConstants.SERVICE_REQUEST_TYPE_REPAIR)
                  ){
                      cs.addError(System.Label.Restrict_Dealer_Calls_To_Service_Request_Type_Repair);  
                  }
            }
        }
        
    }
    /*------------------------------------------------------------------------
    Author:        Shailja
    Company:       Salesforce
    Description:   Method to get partner contact ids
    Inputs:        list of contactIds
    Test Class:   
    ----------------------------------------------------------------------------
    History
    16-09-2020      Shailja     Initial Release
    ----------------------------------------------------------------------------*/
    private static Set<Id> getPartnerContactIds(List<Id> contactIds){
        Set<Id> partnerContactIds = new Set<Id>();
        List<User> users = [Select Id, ContactId From User Where ContactId IN : contactIds limit 9999];
        for(User usr : users){
            if(usr.ContactId != null){
                partnerContactIds.add(usr.ContactId);
            }
        } 
        return partnerContactIds;
    }
    
    
    /*------------------------------------------------------------------------
    Author:        Shailja
    Company:       Salesforce
    Description:   Populate defaults on Service Request Records from Product based on Item Code
                   Before Update
    Inputs:        Map<Id, Case> newCases, Map<Id, Case> oldCases
    Test Class:   
    ----------------------------------------------------------------------------
    History
    18-09-2020      Shailja     Initial Release
    ----------------------------------------------------------------------------*/
    public static void populateServiceRequestDefaultsFromItemCodeOrProduct(Map<Id, Case> newCases, Map<Id, Case> oldCases){
        List<Case> finalCases = new List<Case>();
        Map<String, Product2> idOrItemVsProduct = new Map<String, Product2>();
        Map<String, String> itemGroupVsProductCategory = new Map<String, String>();
        for(Case cs : newCases.values()){
            if(cs.Item_Code__c != null && (cs.Item_Code__c != oldCases.get(cs.Id).Item_Code__c)){
                finalCases.add(cs);
                idOrItemVsProduct.put(cs.Item_Code__c, new Product2());
            }
        }
        
        itemGroupVsProductCategory = getItemGroupVsProductCategory();
        idOrItemVsProduct = getIdVsProduct(idOrItemVsProduct);
        if(!idOrItemVsProduct.isEmpty()){
            for(Case cs : newCases.values()){
                if(idOrItemVsProduct.containsKey(cs.Item_Code__c)
                   && itemGroupVsProductCategory.containsKey(idOrItemVsProduct.get(cs.Item_Code__c).Item_Group__c)
                  ){
                      cs.Product_Category__c = itemGroupVsProductCategory.get(idOrItemVsProduct.get(cs.Item_Code__c).Item_Group__c);
                  }else{
                      cs.Product_Category__c = '';
                  }
                if(idOrItemVsProduct.containsKey(cs.Item_Code__c)){
                    cs.ProductId = idOrItemVsProduct.get(cs.Item_Code__c).Id;
                }
            }
        }
    }
    /*------------------------------------------------------------------------
    Author:        Shailja
    Company:       Salesforce
    Description:   Populate defaults on Service Request Records from Product based on ProductId/Item Code
                   Before Insert
    Inputs:        list of new case records
    Test Class:   
    ----------------------------------------------------------------------------
    History
    18-09-2020      Shailja     Initial Release
    ----------------------------------------------------------------------------*/
    public static void populateServiceRequestDefaultsFromItemCodeOrProduct(List<Case> newCases){
        
        Set<Id> productIds = new Set<Id>();
        Set<Id> itemCodes = new Set<Id>();
        Map<String, String> itemGroupVsProductCategory = new Map<String, String>();
        Map<String, Product2> idOrItemVsProduct = new Map<String, Product2>();
        for(Case cs : newCases){
            if(cs.RecordTypeId == SERVICE_REQUEST_RECORDTYPE_ID && cs.Order_Product__c == null){
                if(cs.ProductId != null){
                    idOrItemVsProduct.put(cs.ProductId, new Product2());
                }else if(cs.Item_Code__c != null){
                    idOrItemVsProduct.put(cs.Item_Code__c, new Product2());
                }
            }
        }
        itemGroupVsProductCategory = getItemGroupVsProductCategory();
        idOrItemVsProduct = getIdVsProduct(idOrItemVsProduct);
        if(!idOrItemVsProduct.isEmpty()){
            for(Case cs : newCases){
                if(idOrItemVsProduct.containsKey(cs.ProductId)){
                    cs.Item_Code__c = idOrItemVsProduct.get(cs.ProductId).Item__c;
                }else if(idOrItemVsProduct.containsKey(cs.Item_Code__c)){
                    cs.ProductId = idOrItemVsProduct.get(cs.Item_Code__c).Id;
                }
                if(idOrItemVsProduct.containsKey(cs.ProductId) && itemGroupVsProductCategory.containsKey(idOrItemVsProduct.get(cs.ProductId).Item_Group__c)){
                    cs.Product_Category__c = itemGroupVsProductCategory.get(idOrItemVsProduct.get(cs.ProductId).Item_Group__c);
                }else if(idOrItemVsProduct.containsKey(cs.Item_Code__c) && itemGroupVsProductCategory.containsKey(idOrItemVsProduct.get(cs.Item_Code__c).Item_Group__c)){
                    cs.Product_Category__c = itemGroupVsProductCategory.get(idOrItemVsProduct.get(cs.Item_Code__c).Item_Group__c);
                }
                cs.Division__c = GlobalConstants.APPLIANCE_BUSINESS_UNIT;
                cs.Integration_Status__c = GlobalConstants.INTEGRATION_STATUS_DRAFT;
            }
        }
    }
    /*------------------------------------------------------------------------
    Author:        Shailja
    Company:       Salesforce
    Description:   Responsible for getting map of productId/Item_code Vs Product
    Inputs:        Map<String, Product2>
    Test Class:   
    ----------------------------------------------------------------------------
    History
    18-09-2020      Shailja     Initial Release
    ----------------------------------------------------------------------------*/
    public static Map<String, Product2> getIdVsProduct(Map<String, Product2> idOrItemVsProduct){
        if(!idOrItemVsProduct.isEmpty()){
            for(Product2 pr : [Select Id, Item__c, Item_Group__c From Product2 Where (Id IN : idOrItemVsProduct.keySet()) OR (Item__c IN : idOrItemVsProduct.keySet())]){
                if(idOrItemVsProduct.containsKey(pr.Id)){
                    idOrItemVsProduct.put(pr.Id, pr);
                }else if(idOrItemVsProduct.containsKey(pr.Item__c)){
                    idOrItemVsProduct.put(pr.Item__c, pr);
                }
            }
        }
        return idOrItemVsProduct;
    }
    /*------------------------------------------------------------------------
    Author:        Shailja
    Company:       Salesforce
    Description:   Populate defaults on Service Request Records from order product
    Inputs:        list of new case records
    Test Class:   
    ----------------------------------------------------------------------------
    History
    18-09-2020      Shailja     Initial Release
    ----------------------------------------------------------------------------*/
    public static void populateServiceRequestDefaultsFromOrderProduct(List<Case> newCases){
        Map<Id, OrderItem> idVsOrderItem = new Map<Id, OrderItem>();
        Map<String, String> itemGroupVsProductCategory = new Map<String, String>();
        List<Id> orderItemIds = new List<Id>();
        List<Id> addressByBP = new List<Id>();
        Map<Id, Id> addressMap = new Map<Id, Id>();
        
        for(Case cs : newCases){
            if(cs.Order_Product__c != null
              && cs.RecordTypeId == SERVICE_REQUEST_RECORDTYPE_ID){
                orderItemIds.add(cs.Order_Product__c);
            } else {
                addressByBP.add(cs.Address_By_BP__c);
            }
        }
        idVsOrderItem = getOrderItems(orderItemIds);
        itemGroupVsProductCategory = getItemGroupVsProductCategory();
        
        if (!addressByBP.isEmpty()) {
            for (Address_By_BP__c each : [SELECT Id, Address_Code__c FROM Address_By_BP__c WHERE Id IN :addressByBP]) {
                addressMap.put(each.Id, each.Address_Code__c);
            }
        }
        
        for(Case cs : newCases){
            if(cs.Order_Product__c != null
               && idVsOrderItem.containsKey(cs.Order_Product__c)
               && cs.RecordTypeId == SERVICE_REQUEST_RECORDTYPE_ID
              ){
                  cs.Delivery_Date__c = idVsOrderItem.get(cs.Order_Product__c).Order.Planned_Delivery_Date__c != null ? idVsOrderItem.get(cs.Order_Product__c).Order.Planned_Delivery_Date__c.Date() : null;
                  cs.Service_Request_Type__c = cs.Service_Request_Type__c == null ? GlobalConstants.SERVICE_REQUEST_TYPE_DEMO_INSTALLATION : cs.Service_Request_Type__c;
                  cs.AccountId = idVsOrderItem.get(cs.Order_Product__c).Order.AccountId;
                  if(idVsOrderItem.get(cs.Order_Product__c).Order.Sold_To_Address__c != null && idVsOrderItem.get(cs.Order_Product__c).Order.Sold_To_Address__r.Address_Code__c != null){
                     cs.Address__c = idVsOrderItem.get(cs.Order_Product__c).Order.Sold_To_Address__r.Address_Code__c;
                     cs.Address_By_BP__c = idVsOrderItem.get(cs.Order_Product__c).Order.Sold_To_Address__c;
                  }
                  if(idVsOrderItem.get(cs.Order_Product__c).Order.Account.IsPersonAccount){
                      cs.ContactId = idVsOrderItem.get(cs.Order_Product__c).Order.Account.PersonContactId;
                  }
                  cs.Division__c = GlobalConstants.APPLIANCE_BUSINESS_UNIT;
                  cs.ProductId = idVsOrderItem.get(cs.Order_Product__c).Product2Id;
                  cs.Item_Code__c = idVsOrderItem.get(cs.Order_Product__c).Product2.Item__c;
                  if(!itemGroupVsProductCategory.isEmpty() && itemGroupVsProductCategory.containsKey(idVsOrderItem.get(cs.Order_Product__c).Product2.Item_Group__c)){
                      cs.Product_Category__c = itemGroupVsProductCategory.get(idVsOrderItem.get(cs.Order_Product__c).Product2.Item_Group__c);
                  }
                  cs.Service_Required_For__c = String.isBlank(cs.Service_Required_For__c) ? 'Installation' : cs.Service_Required_For__c;
                  cs.Integration_Status__c = GlobalConstants.INTEGRATION_STATUS_DRAFT;
              } else if (String.isNotBlank(cs.Address_By_BP__c) && addressMap.containsKey(cs.Address_By_BP__c)){
                  cs.Address__c = addressMap.get(cs.Address_By_BP__c);
              }
        }
    }
    
    /*------------------------------------------------------------------------
    Author:        Shailja
    Company:       Salesforce
    Description:   Method to get Map of OrderItem Id Vs OrderItem Record
    Inputs:        list of orderItemIds
    Test Class:   
    ----------------------------------------------------------------------------
    History
    18-09-2020      Shailja     Initial Release
    ----------------------------------------------------------------------------*/
    private static Map<Id, OrderItem> getOrderItems(List<Id> orderItemIds){
        return new Map<Id, OrderItem>([Select Id, Order.RecordType.Name, Order.AccountId, Order.Planned_Delivery_Date__c, Order.Account.IsPersonAccount,
                                              Order.Account.PersonContactId, Order.Is_Create_Demo_Installation_Request__c, Product2Id, Product2.Item_Code__c,
                                              Product2.Item_Group__c, Product2.Item__c, Order.Sold_To_Address__r.Address_Code__c, Asset_Serial_Number__c
                                       From OrderItem 
                                       where Id =: orderItemIds]);
    }
    
    /*------------------------------------------------------------------------
    Author:        Shailja
    Company:       Salesforce
    Description:   Method to get Map of ItemGroup Vs ProductCategory
    Inputs:        NA
    Test Class:   
    ----------------------------------------------------------------------------
    History
    18-09-2020      Shailja     Initial Release
    ----------------------------------------------------------------------------*/                                                                              
    private static Map<String, String> getItemGroupVsProductCategory(){
        Integer limitRows = Limits.getLimitQueryRows() - Limits.getQueryRows();
        List<Item_Group_Vs_Product_Category_Mapping__mdt> mdtRecords = [Select Id, Item_Group__c, Product_Category__c 
                                                                        From Item_Group_Vs_Product_Category_Mapping__mdt Limit :limitRows];
        Map<String, String> itemGroupVsProductCategory = new Map<String, String>();
        for(Item_Group_Vs_Product_Category_Mapping__mdt rec : mdtRecords){
            itemGroupVsProductCategory.put(rec.Item_Group__c, rec.Product_Category__c);
        }
        return itemGroupVsProductCategory;
    }

    

    public static void CaseDeduplication(List<Case> newCases){
 
        System.debug(' new acase list  '+newCases);
        Map<Id,Case> contactIdtoCaseMap = new Map<Id,Case>();
       
        //Contact mapped cases
        for(Case cRcrd : newCases){
            // && oldItems.get(cRcrd.Id).ContactId == null
            if(cRcrd.ContactId != null ){
                contactIdtoCaseMap.put(cRcrd.ContactId,cRcrd);
            }
        }
        
        //Existing cases on contact
        List<Case> existingCases = [    
                                        SELECT id,Type,ContactId,Service_Request_Type__c, AccountId, status, ProductId, Product_Category__c
                                        FROM case 
                                        WHERE status NOT IN ('Closed') 
                                        AND ContactId In :contactIdtoCaseMap.keySet()
                                    ];

        Map<Id,List<Case>> existingCaseWithCont = new Map<Id,List<Case>>();
        
        for( Case tempCase : existingCases ){
            if( !existingCaseWithCont.containsKey(tempCase.ContactId) ){
                existingCaseWithCont.put(tempCase.ContactId, new List<Case>{tempCase});
            }
            existingCaseWithCont.get(tempCase.ContactId).add(tempCase);
        }

        //Check for same type case existance
        for(Case toBeUpdateCase : newCases){
            
            if( toBeUpdateCase.ContactId != null && existingCaseWithCont.containsKey(toBeUpdateCase.ContactId) ){
                for(Case exists : existingCaseWithCont.get(toBeUpdateCase.ContactId)){

                    if( 
                        exists.ContactId==toBeUpdateCase.ContactId 
                        //&& exits.AccountId == toBeUpdateCase.AccountId
                        && exists.Service_Request_Type__c == toBeUpdateCase.Service_Request_Type__c && exists.Status == toBeUpdateCase.Status 
                        && exists.ProductId != null && toBeUpdateCase.ProductId != null
                        && exists.ProductId == toBeUpdateCase.ProductId
                    ){
                        
                        toBeUpdateCase.addError('Duplicate case already exits on this contact ');
                        // merge exists updatedcase;
                        //updatedcase.Service_Required_For__c='AC1';
                    }
                }
            }
        }
    }


    /*------------------------------------------------------------------------
    Author:        Hansraj Yadav
    Description:   Method to assign case to HO...
    Inputs:        list of Service Request
    Test Class:   
    ----------------------------------------------------------------------------*/

    public static void legalCaseAssignment(List<Case> newCases){

        // Map<Id, Case> newCaseRecordsMap = new Map<Id, Case>([SELECT Id, ownerId, owner.name, Is_Legal__c, ASP_Account__r.ASP_With_HO_Approver__c FROM Case WHERE Id IN :newCases]);
        // for(Case currentCase : newCases){
        //     if(currentCase.Is_Legal__c == true){
        //          currentCase.ownerId = newCaseRecordsMap.get(currentCase.Id).ASP_Account__r.ASP_With_HO_Approver__c;
        //     }
        // }
    }

    /*------------------------------------------------------------------------
    Author:        Hansraj Yadav
    Description:   Method to transfer case to THD...
    Inputs:        list of Service Request
    Test Class:   
    ----------------------------------------------------------------------------*/

    public static void transferToTHD(List<Case> newCases){
        Id thdQueueId = [SELECT Queue.Id, Queue.DeveloperName, Queue.Name FROM queuesobject WHERE Queue.DeveloperName = 'Technical_Help_Desk_Queue'].Queue.Id;
        for(Case currentCase : newCases){
            if(currentCase.Transfer_to_THD__c == true){
                currentCase.ownerId = thdQueueId;
            }
        }
    }

    /*------------------------------------------------------------------------
    Author:        Hansraj Yadav
    Description:   Method for Escalate Case...
    Inputs:        list of Service Request
    Test Class:   
    ----------------------------------------------------------------------------*/

    public static void caseEsclation(List<Case> newCases){

        // 'ASP_Account__c' LOOKUP TO ACCOUNT FIELD IS USED TO GET ASP...
        Map<Id, Case> mapOfnewCasesWithExtraParentFields = new Map<Id, Case>([SELECT Id, Closure_Date__c, IsEscalated, ASP_Account__r.Branch_Service_Executive__c, ASP_Account__r.Locks_Regional_Manager__r.Email, ASP_Account__r.ASP_With_HO_Approver__r.Email, ASP_Account__r.Branch_Service_Executive__r.email, ASP_Account__r.Owner.Email FROM Case WHERE Id IN :newCases]);
        Set<String> userToSendNotification = new Set<String>();
        List<String> toEmailAddress = new List<String>();
        List<String> ccEmailAddresses = new List<String>();
        //'Branch_Service_Executive__c' field on ACCOUNT IS USED TO GET BSE...
        // Here not diffrentiate with old values for now...
        for(case currentCase : newCases){
            if(currentCase.IsEscalated){
                currentCase.Branch_Service_Executive__c = mapOfnewCasesWithExtraParentFields.get(currentCase.Id).ASP_Account__r.Branch_Service_Executive__c;
                Long diffHours = (DateTime.now().getTime() - currentCase.CreatedDate.getTime())/3600000;
                System.debug('diffHours   ---   ' + diffHours);
                interior_Matrix__mdt intMatrix = [select Label, Case_Registered_to_escalation_date_time__c,  Level__c, To_User_Field__c, CC_Users_Fields__c from interior_Matrix__mdt where Case_Registered_to_escalation_date_time__c < :diffHours order by Case_Registered_to_escalation_date_time__c desc limit 1];
                System.debug('intMatrix   -    ' + intMatrix);
                toEmailAddress = getEmailAddresses(intMatrix.To_User_Field__c, (Sobject)mapOfnewCasesWithExtraParentFields.get(currentCase.Id));
                ccEmailAddresses = getEmailAddresses(intMatrix.CC_Users_Fields__c, (Sobject)mapOfnewCasesWithExtraParentFields.get(currentCase.Id));
                System.debug('toEmailAddress   ---   ' + toEmailAddress + 'ccEmailAddresses  --   ' + ccEmailAddresses);
            }
            // if(currentCase.Closure_Date__c != null && currentCase.Closure_Date__c.addDays(-1).date() == System.now().date()){
            //     userToSendNotification.add(mapOfnewCasesWithExtraParentFields.get(currentCase.Id).ASP_Account__r.ASP_With_HO_Approver__r.Email);
            // }
        }   
        
        List<String> userList = new List<String>();
        if(!toEmailAddress.isEmpty() || !ccEmailAddresses.isEmpty()){
            EmailManager.sendEMail(toEmailAddress, ccEmailAddresses, 'Test Case Esclation Mail Notification Subject....', 'Test Case Esclation Mail Notification Subject....');
        }           
    }


    public static List<String> getEmailAddresses(String relationShipFieldForEmail, sObject sObj){
        List<String> emailAddresses = new List<String>();
        List<String> relationshipFields = relationShipFieldForEmail.split('\\,');        
        for(String str : relationshipFields){
            String singleEmail = '';
            List<String> relationShipfield = str.split('\\.');
            if(sObj.getSObject(relationShipfield.get(0)) != null){                   
                singleEmail = (sObj.getSObject(relationShipfield.get(0)).getSobject(relationShipfield.get(1)) != null)?String.valueOf(sObj.getSObject(relationShipfield.get(0)).getSobject(relationShipfield.get(1)).get(relationShipfield.get(2))):singleEmail;              
            }
            if(singleEmail != ''){
                emailAddresses.add(singleEmail);
            }
        }
        return emailAddresses;
    }

}