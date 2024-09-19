/*------------------------------------------------------------------------
Author:        Kishor Kumar
Company:       Salesforce
Description:   Class to populate Order fields
Inputs:        map of created records
Test Class:    OrderFieldPopulatorTest

History
02-04-2020      Kishor Kumar     Initial Release
07-07-2020      Kartik Shetty    Method to populate order type field based on opportunity type.
10-07-2020      Kartik Shetty    Method to enforce validation rules on order.
----------------------------------------------------------------------------*/
public without sharing class OrderFieldPopulator {
    public static User loggedInUser;
    private static Map<Id, Opportunity> IdVSOpportunity = new Map<Id, Opportunity>();
    private static String profileName = null;
    Map<String,Order> secondaryOrderMap;
    {
        //Get logged in user's profile, if 'Integration Administrator' then bypass few validations within code below 
        if(String.isBlank(profileName)){
            List<Profile> profile = [Select Id,Name FROM Profile WHERE Id =: UserInfo.getProfileId() LIMIT 1];
            if(profile != null && profile.size() > 0){
                profileName = profile[0].Name;    
            }
        }
    }
    
    /*------------------------------------------------------------------------
Author:        Kartik Shetty
Company:       Salesforce
Description:   Method to enforce validation rules on order.
Inputs:        Map of created order records and old order records
Test Class:   

History
10-07-2020      Kartik Shetty     Initial Release
03-10-2022      Alpana S          Modified
----------------------------------------------------------------------------*/
    public void orderValidations(Map<Id, Order> mapNewOrderRecords, Map<Id, Order> mapOldOrderRecords) {
        orderRecordLockedValidation(mapNewOrderRecords, mapOldOrderRecords);
    }    
    /*------------------------------------------------------------------------
Author:        Kartik Shetty
Company:       Salesforce
Description:   Method to enforce the validation that order record is locked.
Inputs:        Map of created order records and old order records
Test Class:   

History
10-07-2020      Kartik Shetty     Initial Release
03-10-2022      Alpana S          Modified
----------------------------------------------------------------------------*/
    public void orderRecordLockedValidation(Map<Id, Order> mapNewOrderRecords, Map<Id, Order> mapOldOrderRecords) {
        // Ensure that this validation runs on all other scenarios except on insert or update of Advance Payment Details.       
        if(!AdvancePaymentDetailTriggerHandler.SKIP_ORDER_VALIDATIONS && mapOldOrderRecords.size() > 0) {       
            Boolean skipOrderValidation = false; //Added by Alpana on 3rd Oct 2022 for Jira #SMEPB-46[SMF-83]
            for(Id orderId : mapNewOrderRecords.keySet()) {
                Order newOrderRecord = mapNewOrderRecords.get(orderId);
                Order oldOrderRecord = mapOldOrderRecords.get(orderId);
                if(oldOrderRecord != null && newOrderRecord.Order_Line_Status_record_count__c >= 1 && 
                   oldOrderRecord.Order_Line_Status_record_count__c > 0) {
                       //Start #SMEPB-46[SMF-83] Set skipOrderValidation to true for Integration user and MHE outright sales user
                       if (profileName == System.Label.Integration_User_Profile_Name 
                           || ((profileName == GlobalConstants.SYSTEM_ADMIN_PROFILE_NAME || profileName == GlobalConstants.MHE_SALES_USER_PROFILE_NAME 
                                || profileName == GlobalConstants.MHE_SALES_KAM_FUNCTIONAL_USER_PROFILE_NAME || profileName == GlobalConstants.MHE_CSG_HEAD_USER_PROFILE_NAME)
                               && newOrderRecord != null && newOrderRecord.Related_Secondary_Order__c !=null 
                               && newOrderRecord.MHE_Division__c==GlobalConstants.MHE_SUB_DIVISION_EQUIPMENT)) {
                                   skipOrderValidation= true; 
                               }
                       //End #SMEPB-46[SMF-83]
                       //Bypass if skipOrderValidation is true
                       if(skipordervalidation==False){
                           newOrderRecord.addError(System.Label.Order_locked_for_editing);
                       }
                   }
            }
        }
        
    }
    
    /*------------------------------------------------------------------------
Author:        subhojit
Company:       Salesforce
Description:   Method to populate calculate order amount
Inputs:        list of created order records
Test Class:   

History
02-04-2020      Kishor Kumar     Initial Release
30-05-2020      Manasi Londhe    Removed total_tax_amount_Edit__c and total_unit_price_edit__c from order amount calculation
----------------------------------------------------------------------------*/
    public void calculateOrderAmount(List<Order> orders,Map<Id, Order> mapOldOrderRecords){ //Added  old Map by Shreela on 24th March 2023 for comparing purpose
        //public void calculateOrderAmount(List<Order> orders){ //Commented by Shreela
        Double OrderAmountValueChanged; //Added by Shreela on 24th March 2023 to capture newly set Order Amount
        for(Order orderVar: orders){            
            Double dTotalUnitPrice=0.00;
            if(dTotalUnitPrice==0.00)
                dTotalUnitPrice+=orderVar.Total_Unit_Price__c;
            Double dTaxAmount=((orderVar.Total_Tax_Amount__c==null)?0.00:orderVar.Total_Tax_Amount__c);
            orderVar.Order_Amount__c=(dTotalUnitPrice-orderVar.Total_Line_Discount_Amount__c);
            if(orderVar.Order_Discount__c!=null)
                orderVar.Order_Amount__c=orderVar.Order_Amount__c*(100-orderVar.Order_Discount__c)/100;
            orderVar.Order_Amount__c +=dTaxAmount;
            OrderAmountValueChanged = orderVar.Order_Amount__c; //Added by Shreela on 24th March 2023 to capture newly set Order Amount
            /*  ---------------------------------------------------------------------------------------------------------------------  
Added by pankaj meshram on 14-07-2021 for MHE equipment (outright sales) order amount = bundled price after sync  
---------------------------------------------------------------------------------------------------------------------   */  
            
            if(orderVar.Business_Unit__c==GlobalConstants.MHE_BUSINESS_UNIT && orderVar.Integration_Status__c=='Synced' && orderVar.MHE_Division__c=='Outright Sales'){  
                orderVar.Order_Amount__c=orderVar.Total_Unit_Price_te__c;  
            }
            /*  --------------------------------------------
Added by pankaj meshram on 24-03-21 Ticket#30355199
--------------------------------------------    */
            
            if(orderVar.Business_Unit__c==GlobalConstants.SSG_BUSINESS_UNIT){
                orderVar.Order_Amount__c=(dTotalUnitPrice-orderVar.Total_Line_Discount_Amount__c);
                orderVar.Order_Amount__c +=dTaxAmount;                   
            }
            
            /*  --------------------------------------------
Added by Dinesh Gawande on 11-03-21
-------------------------------------------------*/
            if(orderVar.Business_Unit__c==GlobalConstants.APPLIANCE_BUSINESS_UNIT && orderVar.Integration_Status__c!='Synced' && 
               mapOldOrderRecords!=null && mapOldOrderRecords.size()>0 &&  //Added this and next line by Shreela on 24th March 2023 to check whether there is any change in Order amount of old and new context variable or not
               (mapOldOrderRecords.get(orderVar.Id).Order_Amount__c!=OrderAmountValueChanged))
            {
                orderVar.Order_Amount__c +=orderVar.Tax_Before_Sync__c;
                
                
            }
            
            
        }
    }
    /*------------------------------------------------------------------------
Author:        Kishor Kumar
Company:       Salesforce
Description:   Method to populate PriceBook Id on Order From Branch associated to record createdBy User
Inputs:        list of created order records
Test Class:   

History
02-04-2020      Kishor Kumar     Initial Release
----------------------------------------------------------------------------*/
    public void populatePriceBookonOrder(list<Order> Orders,Map<Id,Order> oldItems){
        set<Id> createdByIds = new set<Id>();
        map<Id, User> createdByUserMap = new map<Id, User>();
        map<Id, String> userVsBranch = new map<Id, String>();
        map<String, Id> branchNameVsPricebookId = new map<String, Id>();
        
        for(Order rec : Orders){
            
            if(rec.pricebook2Id==null && rec.Sales_Price_List__c!=null){
                rec.pricebook2Id=rec.Sales_Price_List__c;
            } else if(Order.pricebook2Id!=null){
                // Added by subhojit to avoid always overide scenario
                if(oldItems==null)
                    rec.Sales_Price_List__c=rec.pricebook2Id;
                else if(oldItems!=null && oldItems.get(rec.Id).pricebook2Id!=rec.pricebook2Id)
                    rec.Sales_Price_List__c=rec.pricebook2Id;
                else if(oldItems!=null && oldItems.get(rec.Id).Sales_Price_List__c!=rec.Sales_Price_List__c)
                    rec.pricebook2Id=rec.Sales_Price_List__c;
                
            }
        }            
        
    }
    
    /*------------------------------------------------------------------------
Author:        Pankaj Meshram
Company:       GITL
Description:   Method to get Quote Records from orders
Inputs:        list of created order records
Test Class:    orderFieldPopulatorTest

History
28-12-2021      Pankaj Meshram     Initial Release        
----------------------------------------------------------------------------*/
    Public Map<Id,Quote> quoteRecords;
    Set<String> quoteIds = new Set<String>();
    public map<id,quote> getQuoteRecords(List<Order> newRecords){
        for(Order orderRec : newRecords){
            if(orderRec.QuoteId != null) {
                quoteIds.add(orderRec.QuoteId);
            }
        }   
        //Added new fields in query by rohit for PED on 13 Aug 2023
        quoteRecords = new Map<Id,Quote>([Select Id,Transaction_Type__c,Ship_To_Account__c,
                                          Ship_To_Address__c,Scope_of_installation__c,Record_Type_Developer_Name__c,
                                          LD_Approver_Comments__c, CT_Approver_Comments__c, Special_Remarks_Approver__c, BG_Status__c, CG_Status__c,LD_Request_Comments__c,CT_Requested_Comments__c,Special_Remarks_Requested__c,
                                          Lead_Time__c,Total_BOM_Cost__c,Opportunity.PED_Sector__c,Opportunity.Opportunity_Region__c FROM QUOTE WHERE Id IN :quoteIds]);
        return quoteRecords;
    }
    
    /*------------------------------------------------------------------------
Author:        Pawan
Company:       Salesforce
Description:   Methos to populate sales office and change the record type based on selected value in Record Type field
Inputs:        list of created order records
Test Class:   

History
02-04-2020      Pawan     Initial Release
23-07-2020      Amit      Added a logic to populate the Sales Office from User if it is not present on Branch
----------------------------------------------------------------------------*/
    public void populateDefaults(List<Order> newRecords){
        quoteRecords = getQuoteRecords(newRecords);//Added by pankaj on 28-12-2021
        system.debug('Quote Records--->'+quoteRecords);
        set<Id> orderAccountIds = new set<Id>();
        map<Id, Account> accountMap = new map<Id, Account>();
        
        setRecordTypeForInforOrders(newRecords);
        List<Sales_Office__c> salesOfficeLst = new List<Sales_Office__c>();
        if(loggedInUser == null){
            loggedInUser = [SELECT Id,
                            ContactId, 
                            Salary_Code__c, 
                            Business_Unit__c, 
                            Area_Code__c, 
                            Logistic_Company__c,
                            Sales_Office__c
                            FROM USER 
                            WHERE Id =: UserInfo.getUserId()];
            
            salesOfficeLst = [SELECT Id,
                              LN_Sales_Office_Code__c 
                              FROM Sales_Office__c 
                              WHERE LN_Sales_Office_Code__c =: loggedInUser.Sales_Office__c LIMIT 1];
        } 
        
        
        //Iterate over Order records to determine the Sales Type from Quote Level
        for(Order orderRec : newRecords){
            //DE 824 : ISR should be Account Owner for Appliance- Dealer BU 
            if(orderRec.Business_Unit__c == GlobalConstants.APPLIANCE_BUSINESS_UNIT && 
               orderRec.AccountId != null){
                   orderAccountIds.add(orderRec.AccountId); 
               }
        } 
        
        if(orderAccountIds.size() > 0){
            accountMap = new map<Id, Account>([SELECT Id, OwnerId, RecordType.DeveloperName FROM Account WHERE Id IN : orderAccountIds 
                                               AND RecordType.DeveloperName =: GlobalConstants.ACCOUNT_RECORDTYPE_DEALER]);
        }
        
        Map<String,String> secondaryVsPrimaryOrder = new Map<String,String>();
        // List<Secoondary_Order_Primary_Order_Mapping__mdt> orderMapping = [Select Primary_Order_Record_Type__c,Secondary_Order_Record_Type__c FROM Secoondary_Order_Primary_Order_Mapping__mdt LIMIT 49999];
        List<Secoondary_Order_Primary_Order_Mapping__mdt> orderMapping = Secoondary_Order_Primary_Order_Mapping__mdt.getAll().values();
        
        for(Secoondary_Order_Primary_Order_Mapping__mdt mdt : orderMapping){
            secondaryVsPrimaryOrder.put(mdt.Secondary_Order_Record_Type__c,mdt.Primary_Order_Record_Type__c);
        }
        
        Map<String,Branch__c> branchNameVsSalesOffice = new Map<String,Branch__c>();
        //Store secondary order ids
        Set<String> secondaryOrderIds = new Set<String>();
        Set<String> branchNames = new Set<String>();
        Set<String> accountIds = new Set<String>();
        
        //Added by rohit jadhav on 31st July 2023 for PED to Autopopulate Sales Team Name on order
        Id pedRecordTypeId=Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get(GlobalConstants.PED_ORDER_RT).getRecordTypeId();
        
        for(Order newOrder : newRecords){
            //Populate Effective dates on orders
            if(newOrder.EffectiveDate == null){
                newOrder.EffectiveDate = System.Today();
            }
            
            // Populate Status on new orders
            if(newOrder.Status == null){
                newOrder.Status = 'Draft';
            }
            Id applianceDirectBillingRecordTypeId=Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get(GlobalConstants.APPLIANCE_DIRECT_BILLING).getRecordTypeId();
            //DE#824 : ISR should be Account Owner id BU = Appliance && Dealer Account RT
            if(!accountMap.isEmpty() && accountMap.containsKey(newOrder.AccountId) && 
               accountMap.get(newOrder.AccountId).OwnerId != null 
               //Added for Appliances Direct Billing Order
               && newOrder.RecordTypeId != applianceDirectBillingRecordTypeId
              ){
                  newOrder.Internal_Sales_Representative__c = accountMap.get(newOrder.AccountId).OwnerId;
              }
            //Added by pankaj on 28 Dec 2021 for MHE to populate actual dealer in ship to while creating primary order
            if(newOrder.Business_Unit__c==GlobalConstants.SSG_BUSINESS_UNIT && quoteRecords.get(newOrder.QuoteId).Scope_of_installation__c != Null){
                newOrder.Installation_scope__c = quoteRecords.get(newOrder.QuoteId).Scope_of_installation__c;
            }
            
            if(String.isNotBlank(newOrder.Record_Types__c)){//for secondary order
                //Check if record type is available to the logged in user
                if(Schema.SObjectType.Order.getRecordTypeInfosByName().get(newOrder.Record_Types__c).isAvailable()){//if available set the record type 
                    newOrder.RecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get(newOrder.Record_Types__c).getRecordTypeId();
                }else{// if not available add error to the record
                    newOrder.addError(System.Label.INCORRECT_ORDER_RECORD_TYPE);
                }
            }else if(String.isBlank(newOrder.Record_Types__c)
                     && newOrder.Related_Secondary_Order__c != null){//for primary order(from order screen :: record type should be from Secoondary Order Primary Order Mapping)
                         secondaryOrderIds.add(newOrder.Related_Secondary_Order__c);
                     }
            
            if(String.isNotBlank(newOrder.Logistics_Company_Branch__c)){
                branchNames.add(newOrder.Logistics_Company_Branch__c);
            }
            
            if(newOrder.Sold_to_Business_Partner__c != null){
                accountIds.add(newOrder.Sold_to_Business_Partner__c);
            }
            
            //Populate Sales Type On Order Record based on Order Type present on Quote
            if(String.isBlank(newOrder.Sales_Type__c)){
                if(quoteRecords.containsKey(newOrder.QuoteId) 
                   && String.isNotBlank(quoteRecords.get(newOrder.QuoteId).Transaction_Type__c)){
                       if(System.Label.Interio_B2B_Parimary.contains(quoteRecords.get(newOrder.QuoteId).Transaction_Type__c)){
                           newOrder.Sales_Type__c = GlobalConstants.ORDER_TYPE_PRIMARY;
                       }else if(System.Label.Interio_B2B_Secondary.contains(quoteRecords.get(newOrder.QuoteId).Transaction_Type__c)){
                           newOrder.Sales_Type__c = GlobalConstants.ORDER_TYPE_SECONDARY;
                       }else if(quoteRecords.get(newOrder.QuoteId).Transaction_Type__c == GlobalConstants.ORDER_TYPE_PRIMARY
                                || quoteRecords.get(newOrder.QuoteId).Transaction_Type__c == GlobalConstants.ORDER_TYPE_SECONDARY){
                                    newOrder.Sales_Type__c = quoteRecords.get(newOrder.QuoteId).Transaction_Type__c;  
                                }
                   }
            }
            
            //Added by rohit jadhav on 31st July 2023 for PED to Autopopulate Sales Team Name on order
            if(newOrder.RecordTypeId==pedRecordTypeId && quoteRecords.containsKey(newOrder.QuoteId)){
                if(quoteRecords.get(newOrder.QuoteId).Opportunity.PED_Sector__c !=null && quoteRecords.get(newOrder.QuoteId).Opportunity.PED_Sector__c ==GlobalConstants.PED_POWER_Sector){
                    newOrder.PED_Sales_Team__c=GlobalConstants.PED_POWER_Team;  
                }else if(quoteRecords.get(newOrder.QuoteId).Opportunity.Opportunity_Region__c !=null && quoteRecords.get(newOrder.QuoteId).Opportunity.Opportunity_Region__c ==GlobalConstants.PED_DOMESTIC_Region){
                    newOrder.PED_Sales_Team__c=GlobalConstants.PED_DOMESTIC_Team; 
                }else if(quoteRecords.get(newOrder.QuoteId).Opportunity.Opportunity_Region__c !=null && quoteRecords.get(newOrder.QuoteId).Opportunity.Opportunity_Region__c ==GlobalConstants.PED_MEA_Region){
                    newOrder.PED_Sales_Team__c=GlobalConstants.PED_MEA_Team;
                }else if(quoteRecords.get(newOrder.QuoteId).Opportunity.Opportunity_Region__c !=null && quoteRecords.get(newOrder.QuoteId).Opportunity.Opportunity_Region__c ==GlobalConstants.PED_SEFE_Region){
                    newOrder.PED_Sales_Team__c=GlobalConstants.PED_SEFE_Team;                                                                                              
                }else if(quoteRecords.get(newOrder.QuoteId).Opportunity.Opportunity_Region__c !=null && (quoteRecords.get(newOrder.QuoteId).Opportunity.Opportunity_Region__c ==GlobalConstants.PED_AMERICAS_Region ||
                                                                                                         quoteRecords.get(newOrder.QuoteId).Opportunity.Opportunity_Region__c ==GlobalConstants.PED_EUROPE_Region)){
                                                                                                             newOrder.PED_Sales_Team__c=GlobalConstants.PED_AMERICAS_EUROPE_Team;
                                                                                                         }
            }
        }
        
        List<Branch__c> branches = [Select Id,Name,Branch_Name__c,Sales_Office__c,Area__c,Internal_Sales_Representative__c, Business_Partner__c
                                    FROM Branch__c 
                                    WHERE Branch_Name__c IN: branchNames 
                                    AND Business_Partner__c IN : accountIds];
        for(Branch__c branch : branches){
            branchNameVsSalesOffice.put(branch.Branch_Name__c + '-' + branch.Business_Partner__c ,branch);
        }
        
        //Get all secondaryOrders 
        //Total_Line_Discount_Amount__c,Total_Unit_Price__c added by Pankaj on 28 -sep 2021
        secondaryOrderMap = new Map<String,Order>([Select Id,Total_Line_Discount_Amount__c,Total_Unit_Price__c,RecordType.DeveloperName FROM Order WHERE Id IN : secondaryOrderIds]);
        Id LocksB2CISTDRecordTypeId=Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get(GlobalConstants.RECORDTYPE_Locks_B2C_ISTD).getRecordTypeId();
        
        for(Order newOrder : newRecords){
            //SSD check added by Sreekanth Jujare to skip this for SSD
            if(String.isNotBlank(newOrder.Logistics_Company_Branch__c) && newOrder.Sold_to_Business_Partner__c != null 
               && branchNameVsSalesOffice.containsKey(newOrder.Logistics_Company_Branch__c+ '-' + newOrder.Sold_to_Business_Partner__c)){
                   if(String.isBlank(newOrder.Sales_Office__c) && newOrder.RecordTypeId!=LocksB2CISTDRecordTypeId && newOrder.Business_Unit__c != GlobalConstants.SSD_BUSINESS_UNIT ) // Added recordType filter by Rohit Jadhav to skip for Locks B2C ISTD)
                       newOrder.Sales_Office__c = branchNameVsSalesOffice.get(newOrder.Logistics_Company_Branch__c+ '-' + newOrder.Sold_to_Business_Partner__c).Sales_Office__c;
                   
                   if(String.isBlank(newOrder.Area__c) && newOrder.RecordTypeId!=LocksB2CISTDRecordTypeId && newOrder.Business_Unit__c != GlobalConstants.SSD_BUSINESS_UNIT ) // Added recordType filter by Rohit Jadhav to skip for Locks B2C ISTD)
                       newOrder.Area__c = branchNameVsSalesOffice.get(newOrder.Logistics_Company_Branch__c+ '-' + newOrder.Sold_to_Business_Partner__c).Area__c;
                   
                   //Internal Sales Rep should be from Branch only if blank then Logged in user
                   if(newOrder.Internal_Sales_Representative__c == null)
                       newOrder.Internal_Sales_Representative__c = branchNameVsSalesOffice.get(newOrder.Logistics_Company_Branch__c+ '-' + newOrder.Sold_to_Business_Partner__c).Internal_Sales_Representative__c;
               }
            
            if(newOrder.Internal_Sales_Representative__c == null 
               && String.isNotBlank(loggedInUser.Salary_Code__c)) {
                   newOrder.Internal_Sales_Representative__c = loggedInUser.Id; 
               }
            
            //Default Sales Office it is present on User and missing on branch
            if(newOrder.RecordTypeId!=LocksB2CISTDRecordTypeId && newOrder.Business_Unit__c != GlobalConstants.SSD_BUSINESS_UNIT ) // Added by Rohit Jadhav to skip for Locks B2C ISTD
            {
                newOrder.Sales_Office__c = !salesOfficeLst.isEmpty() && String.isBlank(newOrder.Sales_Office__c) ? salesOfficeLst[0].Id : newOrder.Sales_Office__c;
            }
            //for primary order only
            if(newOrder.Related_Secondary_Order__c != null 
               && secondaryOrderMap.containsKey(newOrder.Related_Secondary_Order__c)
               && secondaryVsPrimaryOrder.containsKey(secondaryOrderMap.get(newOrder.Related_Secondary_Order__c).RecordType.DeveloperName)){//For primary order only
                   String primaryRecordTypeName = secondaryVsPrimaryOrder.get(secondaryOrderMap.get(newOrder.Related_Secondary_Order__c).RecordType.DeveloperName);
                   //Check if record type is available to the logged in user
                   if(Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get(primaryRecordTypeName).isAvailable()){//if available set the record type 
                       newOrder.RecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get(primaryRecordTypeName).getRecordTypeId();
                   }else{// if not available add error to the record
                       newOrder.addError(System.Label.INCORRECT_ORDER_RECORD_TYPE);
                   }
               }
        }
    }
    
    public void populateMHESanctionApprovalFields(List<Order> newRecords){
        for(Order order:newRecords){
            if(quoteRecords == null){
                quoteRecords = getQuoteRecords(newRecords);
            }
            if(String.isNotBlank(order.QuoteId) && quoteRecords.containsKey(order.QuoteId) 
               && quoteRecords.get(order.QuoteId).Record_Type_Developer_Name__c == GlobalConstants.QUOTE_RECORDTYPE_DEV_NAME_MHE_EQUIPMENTS){
                   Quote quote = quoteRecords.get(order.QuoteId);
                   order.CG_Status__c = quote.CG_Status__c;
                   order.BG_Status__c = quote.BG_Status__c;
                   order.LD_Approver_Comments__c = quote.LD_Approver_Comments__c;
                   order.CT_Approver_Comments__c = quote.CT_Approver_Comments__c;
                   order.Special_Remarks_Approver__c = quote.Special_Remarks_Approver__c;
                   order.LD_Request_Comments__c = quote.LD_Request_Comments__c;
                   order.CT_Requested_Comments__c = quote.CT_Requested_Comments__c;
                   order.Special_Remarks_Requested__c = quote.Special_Remarks_Requested__c;                                   
               }
        }
        
    }
    //Added by pankaj Lead Time and BOM Cost Fields for SMEPB-85    
    public void populateMHELeadTimeBOMDiscountFields(List<Order> newRecords){
        for(Order order:newRecords){
            if(quoteRecords == null){
                quoteRecords = getQuoteRecords(newRecords);
            }
            if(String.isNotBlank(order.QuoteId) && quoteRecords.containsKey(order.QuoteId) && order.Infor_Sales_Order_status__c !='Closed' 
               && quoteRecords.get(order.QuoteId).Record_Type_Developer_Name__c == GlobalConstants.QUOTE_RECORDTYPE_DEV_NAME_MHE_EQUIPMENTS){
                   Quote quote = quoteRecords.get(order.QuoteId);
                   order.Lead_Time__c = quote.Lead_Time__c;
                   order.Total_BOM_Cost__c = quote.Total_BOM_Cost__c; 
               }
        }
    }//end by pankaj
    public void setRecordTypeForInforOrders(List<Order> newOrders){
        Set<Id> orderOwnerIds=new Set<Id>();
        List<Order> inforOrders=new List<Order>();
        Id integrationAdminProfileId=[Select Id From Profile Where Name=:GlobalConstants.INTEGRATION_ADMINISTRATOR_PROFILE_NAME].Id;
        for(Order o:newOrders){
            orderOwnerIds.add(o.OwnerId);
        }
        if(integrationAdminProfileId!=null){
            Map<Id,User> idVsUser=new Map<Id,User>([Select Id,ProfileId From User Where Id In :orderOwnerIds]);
            for(Order o:newOrders){
                if(idVsUser.get(o.OwnerId).ProfileId==integrationAdminProfileId)
                    inforOrders.add(o);
            }
        }
        if(inforOrders.size()>0){
            Set<Id> accountIds=new Set<Id>();
            for(Order o:inforOrders){
                if(o.AccountId!=null)
                    accountIds.add(o.AccountId);
            }
            Map<Id,Account> IdVsAccount=new Map<Id,Account>([Select Id,Business_Unit__c,Interio_Sub_Division__c,Sub_Division__c 
                                                             From Account
                                                             Where Id in :accountIds]);
            Id appliancePrimaryRecordTypeId=Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get(GlobalConstants.APPLIANCE_PRIMARY).getRecordTypeId();
            Id finishedGoodPrimaryRecordTypeId=Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get(GlobalConstants.FINISHED_GOODS_PRIMARY).getRecordTypeId();
            Id kitchenRecordTypeId=Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get(GlobalConstants.INTERIO_B2C_KITCHEN).getRecordTypeId();
            Id ScriptRecordTypeId=Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get(GlobalConstants.INTERIO_B2C_SCRIPT).getRecordTypeId();
            Id VFDPrimaryRecordTypeId=Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get(GlobalConstants.INTERIO_B2C_VFD_PRIMARY).getRecordTypeId();
            Id MHEPrimaryRecordTypeId=Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get(GlobalConstants.MHE_PRIMARY).getRecordTypeId();
            Id SSGPrimaryRecordTypeId=Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get(GlobalConstants.SSG_PRIMARY).getRecordTypeId();
            //Added for Appliances Direct Billing Order
            Id applianceDirectBillingRecordTypeId=Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get(GlobalConstants.APPLIANCE_DIRECT_BILLING).getRecordTypeId();            
            
            for(Order o:inforOrders){
                if(o.AccountId!=null && IdVsAccount.containsKey(o.AccountId)
                   //Adding another condition for Tally Integration on 28-Mar-2022
                   && o.RecordTypeId == null){
                       String businessUnit=IdVsAccount.get(o.AccountId).Business_Unit__c;
                       String interioSubDivision=IdVsAccount.get(o.AccountId).Interio_Sub_Division__c;
                       String subDiv=IdVsAccount.get(o.AccountId).Sub_Division__c;
                       if(businessUnit==GlobalConstants.APPLIANCE_BUSINESS_UNIT)
                           o.RecordTypeId=appliancePrimaryRecordTypeId;
                       else if(businessUnit==GlobalConstants.BUSINESS_UNIT_MHE_DIVISION)
                           o.RecordTypeId=MHEPrimaryRecordTypeId;
                       else if(businessUnit==GlobalConstants.SSG_BUSINESS_UNIT)
                           o.RecordTypeId=SSGPrimaryRecordTypeId;
                       else if(businessUnit==GlobalConstants.INTERIO_BUSINESS_UNIT){
                           if(interioSubDivision==GLobalConstants.INTERIO_SCRIPT)
                               o.RecordTypeId=ScriptRecordTypeId;
                           else if(interioSubDivision==GLobalConstants.INTERIO_VFD)
                               o.RecordTypeId=VFDPrimaryRecordTypeId;
                           else if(interioSubDivision==GLobalConstants.INTERIO_KITCHEN)
                               o.RecordTypeId=kitchenRecordTypeId;
                           else if(interioSubDivision!=null && interioSubDivision.Contains('B2B'))
                               o.RecordTypeId=finishedGoodPrimaryRecordTypeId;
                       }
                       //Adding condition for Tally Integration on 28-Mar-2022
                       if (o.Sales_Type__c == null)
                       {
                           o.Sales_Type__c=GlobalConstants.SALES_TYPE_PRIMARY;
                       }
                   }
            }
        }
    }
    
    
    public void createOrderItems(map<Id, sObject> newItems){
        //set of ProductIds  
        Set<Id> productIds = new Set<Id>();
        List<OrderItem> clonedOrderItems = new List<OrderItem>();
        List<QuoteLineItem> quoteItems = new List<QuoteLineItem>();
        Map<Id,QuoteLineItem> mapQuoteDiscount=new map<Id,QuoteLineItem>();
        List<Order> clonedOrderSecondaryB2B = new List<Order>();
        Map<String,Order> secondaryOrderVsPrimaryOrder = new Map<String,Order>();
        Map<String,Order> secondaryOrderVsPrimaryOrderB2B = new Map<String,Order>();
        Map<String,PriceBookEntry> productIdVsPriceBookEntryId = new Map<String,PriceBookEntry>();
        
        Set<String> priceBookIds = new Set<String>();
        for(Order newRecord : (List<Order>)newItems.values()){
            if(newRecord.Copy_LineItems__c == true && newRecord.Related_Secondary_Order__c != null){
                secondaryOrderVsPrimaryOrder.put(String.valueOf(newRecord.Related_Secondary_Order__c),newRecord);
            }
            
            List<String> transactionType = System.label.Interio_B2B_Secondary.split(',');
            
            if(newRecord.Pricebook2Id != null ) priceBookIds.add(newRecord.Pricebook2Id);
        }
        
        //Added by Nupoor : Removing 2 SOQL from for loop
        if(secondaryOrderVsPrimaryOrder.size()>0)
        {
            clonedOrderSecondaryB2B = new List<Order>([SELECT Id, QuoteId, Quote.RecordType.DeveloperName
                                                       FROM Order
                                                       WHERE Id IN :secondaryOrderVsPrimaryOrder.keySet()]);
            if(clonedOrderSecondaryB2B.size()>0)
            {
                Set<ID> quoteIdSet = new Set<ID>();
                for(Order secondaryOrder : clonedOrderSecondaryB2B){
                    if(String.isNotBlank(secondaryOrder.QuoteId)){
                        quoteIdSet.add(secondaryOrder.QuoteId);
                    }
                }
                
                quoteItems = new List<QuoteLineItem>([SELECT Id, Total_Approved_Discount__c, Product2Id, Quantity,
                                                      //Added the 3 below columns for generic product carry over for MHE Equipments 
                                                      Quote_Unit_Basics_Cust__c, Product2.Is_Generic_Product__c, Quote.RecordType.DeveloperName,Product2.item__c,
                                                      //Below fields added by pankaj on 28-sep-2021
                                                      Requested_Customer_Discount__c, Product_Storage_Clasification__c, Quote_Record_Type__c, UnitPrice,  
                                                      Skip_Generic_SPR__c
                                                      FROM QuoteLineItem
                                                      WHERE QuoteId IN :quoteIdSet]);
                
                for(QuoteLineItem qlVar: quoteItems){
                    mapQuoteDiscount.put(qlVar.Id,qlVar);
                    productIds.add(qlVar.Product2Id);
                }
            }
            
        }
        
        
        
        if(priceBookIds.size() > 0 ){
            for(PriceBookEntry pbEntry : [select Id,Pricebook2Id,Product2Id, UnitPrice FROM PriceBookEntry WHERE Pricebook2Id IN: priceBookIds And Product2Id IN: productIds]){
                productIdVsPriceBookEntryId.put(pbEntry.Product2Id,pbEntry);
            }
        }
        
        if(secondaryOrderVsPrimaryOrder.size() > 0){
            List<String> secondaryOrders = new List<String>(secondaryOrderVsPrimaryOrder.keySet());
            //added by pankaj on 28 sep 2021 for overall dealer discount on primary order
            Set<String> setSobjectFields = QueryBuilder.getSObjectFields(GlobalConstants.ORDER_ITEM_SOBJECT_API_NAME,true);  
            setSobjectFields.add('order.Total_Unit_Price__c');  
            setSobjectFields.add('order.Total_Line_Discount_Amount__c'); 
            setSobjectFields.add('Order.Business_Unit__c');
            setSobjectFields.add('Order.Related_Secondary_Order__c');
            setSobjectFields.add('Skip_Generic_SPR__c');
            setSobjectFields.add('product2.Product_Storage_Clasification__c');
            setSobjectFields.add('product2.Item__c');
            String query = QueryBuilder.build(GlobalConstants.ORDER_ITEM_SOBJECT_API_NAME,  
                                              //(QueryBuilder.getSObjectFields(GlobalConstants.ORDER_ITEM_SOBJECT_API_NAME,true)).add('Related_secondary_order__c'),  
                                              setSobjectFields,    
                                              ' OrderId IN: secondaryOrders');
            
            List<OrderItem> orderItems = Database.query(query);
            //order items without freight
            Decimal totalUnitPriceSecondary = 0.00;  
            for(OrderItem orderItemRec : orderItems){  
                if(orderItemRec.Skip_Generic_SPR__c == False){
                    //Added by pankaj on 14 Dec 2021 for Annexture B pricing issues
                    if(orderItemRec.Order.Business_Unit__c == GlobalConstants.MHE_BUSINESS_UNIT && orderItemRec.Order.Related_Secondary_Order__c != Null &&
                       orderItemRec.Order.MHE_Division__c == GlobalConstants.MHE_SUB_DIVISION_EQUIPMENT)
                        totalUnitPriceSecondary += orderItemRec.Total_Unit_Price__c; 
                    else
                        totalUnitPriceSecondary += orderItemRec.UnitPrice;
                    //End by pankaj                                                
                }  
            }
            //Added by pankaj on 06/01/2022 for MHE Equipments - Annexture A
            Boolean Is_Annexture_A = False;
            for(OrderItem orderItemRec : orderItems){  
                if(orderItemRec.product2.Product_Storage_Clasification__c == String.valueof('Category A') && orderItemRec.product2.Item__c !='72151701SD00818'){
                    Is_Annexture_A = True;  
                    Break;
                }  
            } 
            System.debug('Is_Annexture_A---'+Is_Annexture_A);
            
            for(OrderItem orderItemRec : orderItems){
                OrderItem cloneOrderItem = orderItemRec.clone(false,true,false,false);
                totalUnitPriceSecondary =  cloneOrderItem.order.Total_Unit_Price__c;//Uncommented by pankaj on 10 aug 2022 becuase it should work for more than 1 quantities                    
                Decimal totalDiscountSecondary =   cloneOrderItem.order.Total_Line_Discount_Amount__c;  
                Decimal TotalDiscountPercentSec =  totalDiscountSecondary/totalUnitPriceSecondary*100;
                if(mapQuoteDiscount.containsKey(orderItemRec.QuoteLineItemId)){                        
                    if(mapQuoteDiscount.get(orderItemRec.QuoteLineItemId).Quote_Record_Type__c == GlobalConstants.QUOTE_RECORDTYPE_DEV_NAME_MHE_EQUIPMENTS && (Is_Annexture_A == True)){  
                        cloneOrderItem.Discount_Amount__c = Decimal.valueOf(System.Label.BASE_PRODUCT_DISCOUNT);  
                    }                        
                    else if(mapQuoteDiscount.get(orderItemRec.QuoteLineItemId).Quote_Record_Type__c == GlobalConstants.QUOTE_RECORDTYPE_DEV_NAME_MHE_EQUIPMENTS  
                            && (Is_Annexture_A == False)){  
                                if(mapQuoteDiscount.get(orderItemRec.QuoteLineItemId).Skip_Generic_SPR__c == True){  
                                    cloneOrderItem.Discount_Amount__c = Decimal.valueOf(System.Label.BASE_PRODUCT_DISCOUNT);  
                                }  
                                else if(TotalDiscountPercentSec >= 0 && TotalDiscountPercentSec<= Decimal.valueOf(System.Label.MHE_CATEGORY_B_DISCOUNT_MIN_V1)){  
                                    
                                    cloneOrderItem.Discount_Amount__c = mapQuoteDiscount.get(orderItemRec.QuoteLineItemId).UnitPrice/100*((mapQuoteDiscount.get(orderItemRec.QuoteLineItemId).Requested_Customer_Discount__c + Decimal.valueOf(System.Label.MHE_CATEGORY_B_DISCOUNT_V1))-((mapQuoteDiscount.get(orderItemRec.QuoteLineItemId).Requested_Customer_Discount__c/100)*Decimal.valueOf(System.Label.MHE_CATEGORY_B_DISCOUNT_V1)));  
                                }  
                                else if(TotalDiscountPercentSec > Decimal.valueOf(System.Label.MHE_CATEGORY_B_DISCOUNT_MIN_V1)  && TotalDiscountPercentSec <= Decimal.valueOf(System.Label.MHE_CATEGORY_B_DISCOUNT_MIN_V2)){  
                                    cloneOrderItem.Discount_Amount__c = mapQuoteDiscount.get(orderItemRec.QuoteLineItemId).UnitPrice/100*((mapQuoteDiscount.get(orderItemRec.QuoteLineItemId).Requested_Customer_Discount__c + Decimal.valueOf(System.Label.MHE_CATEGORY_B_DISCOUNT_V2))-((mapQuoteDiscount.get(orderItemRec.QuoteLineItemId).Requested_Customer_Discount__c/100)*Decimal.valueOf(System.Label.MHE_CATEGORY_B_DISCOUNT_V2)));  
                                }  
                                else if(TotalDiscountPercentSec > Decimal.valueOf(System.Label.MHE_CATEGORY_B_DISCOUNT_MIN_V2)){  
                                    cloneOrderItem.Discount_Amount__c = mapQuoteDiscount.get(orderItemRec.QuoteLineItemId).UnitPrice/100*((mapQuoteDiscount.get(orderItemRec.QuoteLineItemId).Requested_Customer_Discount__c + Decimal.valueOf(System.Label.MHE_CATEGORY_B_DISCOUNT_V3))-((mapQuoteDiscount.get(orderItemRec.QuoteLineItemId).Requested_Customer_Discount__c/100)*Decimal.valueOf(System.Label.MHE_CATEGORY_B_DISCOUNT_V3)));  
                                }  
                            }else{  
                                cloneOrderItem.Discount_Amount__c=mapQuoteDiscount.get(orderItemRec.QuoteLineItemId).Total_Approved_Discount__c/mapQuoteDiscount.get(orderItemRec.QuoteLineItemId).Quantity;                   
                            }                                
                }  //end by pankaj on 28 sep 2021
                
                //commented by Praful - 03-Sep - this is to get per unit discount to Primary order
                //cloneOrderItem.Discount_Amount__c=mapQuoteDiscount.get(orderItemRec.QuoteLineItemId).Total_Approved_Discount__c;
                
                if(secondaryOrderVsPrimaryOrder.containsKey(String.valueOf(orderItemRec.OrderId))
                   && productIdVsPriceBookEntryId.containsKey(orderItemRec.Product2Id)){
                       cloneOrderItem.OrderId = secondaryOrderVsPrimaryOrder.get(orderItemRec.OrderId).Id;
                       cloneOrderItem.PricebookEntryId = productIdVsPriceBookEntryId.get(cloneOrderItem.Product2Id).Id;
                       cloneOrderItem.ListPrice = productIdVsPriceBookEntryId.get(cloneOrderItem.Product2Id).UnitPrice;                    
                       //If block for generic MHE Equipment product added(null check ) on 28-6-2021
                       if( mapQuoteDiscount.size()>0 &&
                          mapQuoteDiscount.get(orderItemRec.QuoteLineItemId) !=null &&
                          (mapQuoteDiscount.get(orderItemRec.QuoteLineItemId).Product2.Is_Generic_Product__c == true) && 
                          (mapQuoteDiscount.get(orderItemRec.QuoteLineItemId).Quote.RecordType.DeveloperName == 'MHE_Equipments')
                         )
                       {
                           //Added by Pankaj 10 aug 2022 for picked up unit price for atachment    
                           if(mapQuoteDiscount.get(orderItemRec.QuoteLineItemId).Product2.item__c != GlobalConstants.Other_Attachments)
                               cloneOrderItem.UnitPrice = mapQuoteDiscount.get(orderItemRec.QuoteLineItemId).Quote_Unit_Basics_Cust__c;
                           
                           cloneOrderItem.UnitPrice = mapQuoteDiscount.get(orderItemRec.QuoteLineItemId).UnitPrice;                            }
                       else
                       {
                           cloneOrderItem.UnitPrice = productIdVsPriceBookEntryId.get(cloneOrderItem.Product2Id).UnitPrice;
                       }
                       clonedOrderItems.add(cloneOrderItem);
                   }
            }
            
            if(clonedOrderItems.size() > 0) insert clonedOrderItems;
        }
    }                           
    
    /*------------------------------------------------------------------------
Author:        Kishor Kumar
Company:       Salesforce
Description:   Method to populate Ship To  on order
Inputs:        list of created order records
Test Class:   

History
14-05-2020   Kishor Kumar     Initial Release
11-02-2020   Shailja Mishra   Added orderVar.Service_Form__c == null
14-10-2021   pankaj meshram   Added for MHE to populate actual dealer in ship to while creating primary order
----------------------------------------------------------------------------*/
    public void populateShipToOnOrder(list<Order> orders){               
        for(Order orderVar:orders){
            if((orderVar.Sold_to_Business_Partner__c!= Null && orderVar.Service_Form__c == null 
                && orderVar.Business_Unit__c!=GlobalConstants.SSG_BUSINESS_UNIT && orderVar.MHE_Division__c !='Outright Sales' 
                && (orderVar.Business_Unit__c!= GlobalConstants.INTERIO_BUSINESS_UNIT && orderVar.Sub_Division__c != GlobalConstants.B2B_SUBDIVISION))
               || (orderVar.Ship_To_Account__c == null && orderVar.Business_Unit__c==GlobalConstants.SSG_BUSINESS_UNIT)
               || (orderVar.Ship_To_Account__c == null && orderVar.Business_Unit__c==GlobalConstants.MHE_BUSINESS_UNIT)
               
              ) {
                  orderVar.Ship_To_Account__c = orderVar.Sold_to_Business_Partner__c;                    
              }                
        } 
    }
    /*------------------------------------------------------------------------
Author:        Pankaj Meshram
Company:       GITL
Description:   Method to populate Order_Reference_Number_Ext__c on order for all Divisions
Inputs:        List of created order records
Test Class:    orderFieldPopulatorTest

History
4/3/2022       Pankaj Meshram     Initial Release
----------------------------------------------------------------------------*/
    public void populateOrderReferenceNumberExt(list<Order> orders){
        for(Order orderVar:orders){                
            if(orderVar.order_reference_number_ext__c == null && orderVar.Integration_Status__c == GlobalConstants.INTEGRATION_STATUS_SYNCED &&
               orderVar.Logistics_Company_Branch__c !=null && orderVar.OrderReferenceNumber!= null){
                   orderVar.Order_Reference_Number_Ext__c = orderVar.Logistics_Company_Branch__c+GlobalConstants.Underscore+orderVar.OrderReferenceNumber;                    
               }                
        }
    }
    /*------------------------------------------------------------------------
Author:        Shailja 
Company:       Salesforce
Description:   Method to populate End Customer from Opportunity to Order
Inputs:        list of created order records
Test Class:   
----------------------------------------------------------------------------
History
28-06-2020       Shailja     Initial Release
----------------------------------------------------------------------------*/
    public void populateEndCustomerOnOrder(list<Order> orders){
        if(IdVSOpportunity.isEmpty()) {
            Set<Id> optyIds = new Set<Id>();
            for(Order orderVar:orders){
                if(orderVar.OpportunityId != null)
                    optyIds.add(orderVar.OpportunityId);
            }
            IdVSOpportunity = getOpportunities(optyIds);
        }
        
        if(!IdVSOpportunity.isEmpty()){
            for(Order orderVar:orders){
                if(IdVSOpportunity.containsKey(orderVar.OpportunityId)) {
                    if(IdVSOpportunity.get(orderVar.OpportunityId).End_Customer__c != null){
                        orderVar.End_Customer__c = IdVSOpportunity.get(orderVar.OpportunityId).End_Customer__c;
                    }
                }
            }
        }
    }
    
    /*------------------------------------------------------------------------
Author:        Kartik Shetty 
Company:       Salesforce
Description:   Method to populate order type field based on opportunity type.
Inputs:        list of created order records
Test Class:   

History
07-07-2020      Kartik Shetty     Initial Release
----------------------------------------------------------------------------*/
    public void populateOrderTypeField(List<Order> orders) {
        Id LocksB2CISTDRecordTypeId=Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get(GlobalConstants.RECORDTYPE_Locks_B2C_ISTD).getRecordTypeId();
        if(IdVSOpportunity.isEmpty()) {
            Set<Id> optyIds = new Set<Id>();
            for(Order order : orders) {
                if(order.OpportunityId != null && order.RecordTypeId!=LocksB2CISTDRecordTypeId) {
                    optyIds.add(order.OpportunityId);
                }
            }
            IdVSOpportunity = getOpportunities(optyIds);
        }
        
        if(!IdVSOpportunity.isEmpty()) {
            for(Order order : orders) {
                Opportunity opp = IdVSOpportunity.get(order.OpportunityId);
                if(opp != null && opp.Opportunity_Type__c != null && 
                   GlobalConstants.OPPORTUNITY_TYPE_TO_ORDER_TYPE_MAPPING.containsKey(opp.Opportunity_Type__c)) {
                       order.Type = GlobalConstants.OPPORTUNITY_TYPE_TO_ORDER_TYPE_MAPPING.get(opp.Opportunity_Type__c);
                   }
                //Else if condition is added by Sreekanth Jujare
                else if(opp != null && opp.Order_Type__c == GlobalConstants.R_SERIES_BILLING){
                    order.Type = GlobalConstants.RSR_ORDER_TYPE;
                }
            }
        }
    }
    
    /*------------------------------------------------------------------------
Company:       Salesforce
Description:   Method to get Opportunities based on Ids
Inputs:        Set<Id>
--------------------------------------------------------------------------*/
    public Map<Id, Opportunity> getOpportunities(Set<Id> optyIds){
        return (new Map<Id, Opportunity>([Select Id, End_Customer__c, Opportunity_Type__c,Order_Type__c From Opportunity Where Id IN: optyIds]));
    }
    
    
    /*------------------------------------------------------------------------
Author:        Kishor Kumar
Company:       Salesforce
Description:   Method to check the sold to role's(Branch__c) business partner 
status should be Active(Open) before creating any order 
Inputs:        list of created order records
Test Class:   

History
15-05-2020      Kishor Kumar     Initial Release
08-06-2020      Manasi Londhe    Added Branch__c population logic
----------------------------------------------------------------------------*/
    public void CheckForActiveSoldToBranch(list<Order> newOrders,Map<Id,Order> oldOrders){
        List<Order> orders=new List<Order>();
        if(oldOrders!=null){
            for(Order o:newOrders){
                if(o.Sold_to_Business_Partner__c!=oldOrders.get(o.Id).Sold_to_Business_Partner__c
                   || o.Logistics_Company_Branch__c!=oldOrders.get(o.Id).Logistics_Company_Branch__c)
                    orders.add(o);
            }
        }
        else{
            orders=newOrders;
        }
        set<Id> orderSoldToAccount = new set<Id>();
        Set<String> activeBranches=new Set<String>();
        Set<String> logisticBranches=new Set<String>();
        Map<Id,List<Branch__c>> bpAccountVsBranches=new Map<Id,List<Branch__c>>();
        
        for(Order orderVar : orders){
            if(orderVar.Sales_Type__c==GlobalConstants.SALES_TYPE_PRIMARY &&
               orderVar.Sold_to_Business_Partner__c != null && 
               String.isNotBlank(orderVar.Logistics_Company_Branch__c)){
                   orderSoldToAccount.add(orderVar.Sold_to_Business_Partner__c);
                   logisticBranches.add(orderVar.Logistics_Company_Branch__c);
               }
        }
        if(orderSoldToAccount.size() > 0 && logisticBranches.size()>0){                        
            for(Branch__c branch : [SELECT Id,Branch_Name__c,Business_Partner__c  
                                    FROM Branch__c 
                                    WHERE Business_Partner__c IN : orderSoldToAccount
                                    AND Branch_Name__c IN : logisticBranches
                                    AND Business_Partner_Status__c = 'Open']){
                                        activeBranches.add(branch.Branch_Name__c);
                                        if(bpAccountVsBranches.containsKey(branch.Business_Partner__c))
                                            bpAccountVsBranches.get(branch.Business_Partner__c).add(branch);
                                        else
                                            bpAccountVsBranches.put(branch.Business_Partner__c,new List<Branch__c>{branch});
                                    }
        }
        
        //Iterate to check Active sold To Business Partner
        if(orderSoldToAccount.size() > 0 && logisticBranches.size()>0){
            
            for(Order orderRec : orders){
                
                //Added a check in IF condition to bypass the validation check for Integration User and SSD check added by Sreekanth Jujare 
                if(orderRec.Sales_Type__c==GlobalConstants.SALES_TYPE_PRIMARY && orderRec.Sold_to_Business_Partner__c!=null && orderRec.Logistics_Company_Branch__c!=null){
                    //No Active Branch found
                    if((activeBranches.size() == 0 || !activeBranches.contains(orderRec.Logistics_Company_Branch__c)) && profileName!=GlobalConstants.INTEGRATION_ADMINISTRATOR_PROFILE_NAME && orderRec.Business_Unit__c !=  GlobalConstants.SSD_BUSINESS_UNIT){
                        //Show error on UI
                        orderRec.addError(System.Label.Order_for_Inactive_Business_Partner_Status_Branch_error);
                    }
                    else if(bpAccountVsBranches.containsKey(orderRec.Sold_to_Business_Partner__c)){
                        Id branchId;
                        for(Branch__c branch:bpAccountVsBranches.get(orderRec.Sold_to_Business_Partner__c)){
                            if(branch.Branch_Name__c==orderRec.Logistics_Company_Branch__c)
                                branchId=branch.Id;
                            break;
                        }
                        if(branchId!=null)
                            orderRec.Branch__c=branchId;
                        else if(profileName!=GlobalConstants.INTEGRATION_ADMINISTRATOR_PROFILE_NAME && orderRec.Business_Unit__c !=  GlobalConstants.SSD_BUSINESS_UNIT)
                            orderRec.addError(System.Label.Order_for_Inactive_Business_Partner_Status_Branch_error);
                    }
                    else if(profileName!=GlobalConstants.INTEGRATION_ADMINISTRATOR_PROFILE_NAME && orderRec.Business_Unit__c !=  GlobalConstants.SSD_BUSINESS_UNIT)
                        orderRec.addError(System.Label.Order_for_Inactive_Business_Partner_Status_Branch_error);
                }
            }
        }
        
    }
    /*-------------------------------------------------------------------------------------
Author:       Shailja
Company:      Salesforce
Description:  Method to populate Account owner on 'External User's Order Approver' field.
On Before Update.
This is required for Appliances Order approval.
Inputs:       Map<Id, Order> newOrders, Map<Id, Order> oldOrders
---------------------------------------------------------------------------------------*/
    public void populateApproverForExternalUser(Map<Id, Order> newOrders, Map<Id, Order> oldOrders){
        List<Order> finalOrders = new List<Order>();
        for(Order rec : newOrders.values()){
            if(rec.Sold_to_Business_Partner__c != null
               && rec.Sold_to_Business_Partner__c != oldOrders.get(rec.Id).Sold_to_Business_Partner__c){
                   finalOrders.add(rec);
               }
        }
        
        if(finalOrders.size() > 0){
            populateApproverForExternalUser(finalOrders);
        }
        
    }
    
    /*-------------------------------------------------------------------------------------
Author:       Shailja
Company:      Salesforce
Description:  Method to populate Account owner on 'External User's Order Approver' field.
This is required for Appliances Order approval.
Inputs:       List<Order>
---------------------------------------------------------------------------------------*/
    public void populateApproverForExternalUser(List<Order> newOrders){
        List<Id> acctIds = new List<Id>();
        Map<Id, Account> idVsAccount;
        if(isExternalUser()){
            for(Order rec : newOrders){
                if(rec.Sold_to_Business_Partner__c != null)
                    acctIds.add(rec.Sold_to_Business_Partner__c);
            }
            idVsAccount = getActIdVsRecord(acctIds);
            Id appliancesPrimaryRecordTypeId =(RecordTypeUtils.getInstance()).getRecordTypeId(GlobalConstants.ORDER_SOBJECT_API_NAME,GlobalConstants.APPLIANCE_PRIMARY);
            Id appliancesSecondaryRecordTypeId = (RecordTypeUtils.getInstance()).getRecordTypeId(GlobalConstants.ORDER_SOBJECT_API_NAME,GlobalConstants.APPLIANCE_SECONDARY);
            if(!idVsAccount.isEmpty()){
                for(Order rec : newOrders){
                    if((rec.RecordTypeId == appliancesPrimaryRecordTypeId || rec.RecordTypeId == appliancesSecondaryRecordTypeId)
                       &&(rec.Sold_to_Business_Partner__c != null && idVsAccount.containsKey(rec.Sold_to_Business_Partner__c))){
                           rec.External_Users_Order_Approver__c = idVsAccount.get(rec.Sold_to_Business_Partner__c).OwnerId;
                           rec.Approval_Status__c = GlobalConstants.APPROVAL_REQUIRED_STATUS;
                           if (profileName != Null & profileName == GlobalConstants.ApplianceDoorToDoorUserSyncProfile)
                               rec.Approval_Status__c = GlobalConstants.APPROVED_STATUS;                         
                       }
                }
            }
        }
    }
    
    /*--------------------------------------------------------------------------------------
Author:       Shailja
Company:      Salesforce
Description:  Method is responsible for checking if current user is External User
Inputs:       NA
----------------------------------------------------------------------------------------*/
    public boolean isExternalUser(){
        if(UserInfo.getUserType().equalsIgnoreCase('Standard')) return false;
        return true; 
    }
    
    /*--------------------------------------------------------------------------------------
Author:       Shailja
Company:      Salesforce
Description:  Method is responsible returning map of AccountId Vs Account Record
Inputs:       List<Id>
----------------------------------------------------------------------------------------*/
    public Map<Id,Account> getActIdVsRecord(List<Id> acctIds){
        return (new Map<Id, Account>([Select Id, OwnerId From Account Where Id IN: acctIds]));
    }
    
    /*--------------------------------------------------------------------------------------
Author:       Shailja
Company:      Salesforce
Description:  Method is responsible populating Approvers for Internal Users on Order.
This is required for Appliances Order Approval.
Inputs:       List<Order>
----------------------------------------------------------------------------------------*/
    public void populateApproversForInternalUsers(List<Order> newOrders){
        Map<Id, User> userIdVsUser;
        List<Order> finalOrders = new List<Order>();
        List<Id> internalUserIds = new List<Id>();
        Id appliancesPrimaryRecordTypeId =(RecordTypeUtils.getInstance()).getRecordTypeId(GlobalConstants.ORDER_SOBJECT_API_NAME,GlobalConstants.APPLIANCE_PRIMARY);
        List<BU_Wise_Approval_Required_Not_Required__mdt> buWiseAprrovalRequiredMdtRecs = [Select Id, DeveloperName, MasterLabel, Language, Business_Unit__c, Persona__c, Is_Approval_Required__c 
                                                                                           FROM BU_Wise_Approval_Required_Not_Required__mdt where Business_Unit__c = 'H'  limit 999];
        Map<String, BU_Wise_Approval_Required_Not_Required__mdt> personaVsRecord = new Map<String, BU_Wise_Approval_Required_Not_Required__mdt>();
        
        if(buWiseAprrovalRequiredMdtRecs.size() > 0){
            for(BU_Wise_Approval_Required_Not_Required__mdt rec : buWiseAprrovalRequiredMdtRecs){
                personaVsRecord.put(rec.Persona__c, rec);
            }
        }
        if(!isExternalUser()){
            for(Order o : newOrders){
                if(o.RecordTypeId == appliancesPrimaryRecordTypeId){
                    finalOrders.add(o);
                    internalUserIds.add(o.OwnerId);
                }
            }
            userIdVsUser = getUsers(internalUserIds);
            if(!userIdVsUser.isEmpty()){
                for(Order o : finalOrders){
                    if(userIdVsUser.containsKey(o.OwnerId) && !personaVsRecord.isEmpty()){
                        if(personaVsRecord.containsKey(userIdVsUser.get(o.OwnerId).Persona__c)){
                            if(personaVsRecord.get(userIdVsUser.get(o.OwnerId).Persona__c).Is_Approval_Required__c){
                                o.Approval_Status__c = GlobalConstants.APPROVAL_REQUIRED_STATUS;
                                if(userIdVsUser.get(o.OwnerId).ManagerId != null)        
                                    o.Internal_Users_Order_Approver__c = userIdVsUser.get(o.OwnerId).ManagerId;
                            }else if(!personaVsRecord.get(userIdVsUser.get(o.OwnerId).Persona__c).Is_Approval_Required__c){
                                o.Approval_Status__c = GlobalConstants.APPROVED;
                            }
                        }
                    }                    
                }
            }
        }
    }
    
    Map<Id, User> getUsers(List<Id> userIds){
        return (new Map<Id, User>([Select Id, Persona__c, ManagerId, Manager.ManagerId, Manager.Manager.ManagerId, Manager.Manager.Manager.ManagerId,
                                   Manager.UserRole.Name, Manager.Manager.UserRole.Name From User Where Id IN: userIds]));   
    }
    
    /*------------------------------------------------------------------------
Author:        Shailja
Company:       Salesforce
Description:   Method is responsible for validating Planned Delivery Date on before insert
Inputs:        Map<Id, Order> newOrders, Map<Id, Order> oldOrders
Test Class:   
---------------------------------------------------------------------------
History
22-06-2020      Shailja     Initial Release
24-06-2022      Shreela     To let Approved , synced MHE Order of equiry Category Outright Sales to bypass the PDD validation
----------------------------------------------------------------------------*/
    public void validatePlannedDeliveryDate(Map<Id,Order> oldItems,List<Order> newOrders){
        Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
        if (setting.FirePlannedDeliveryDateValidation__c){
            for(Order item : newOrders){
                if(item.Planned_delivery_Date__c != null && item.Planned_delivery_Date__c.date() < Date.today()){//if populated && in past
                    if(AdvancePaymentDetailTriggerHandler.SKIP_ORDER_VALIDATIONS == false && //APD skip order validation check should bypass
                       //added by Shreela and Priyanka for SMEPB 32  
                       (oldItems == null // insert 
                        || !(item.MHE_Division__c==GlobalConstants.MHE_SUB_DIVISION_EQUIPMENT //update approved , synced , outrightsales and secondary order change should bypass
                             && item.Approval_Status__c ==GlobalConstants.APPROVED_STATUS  
                             && item.Integration_Status__c ==GlobalConstants.INTEGRATION_STATUS_SYNCED
                             && item.Related_Secondary_Order__c != oldItems.get(item.id).Related_Secondary_Order__c))
                       //Ended by Shreela and Priyanka for SMEPB 32
                      ){ 
                          System.debug('profile name+'+profilename);
                          if(profileName != System.Label.Integration_User_Profile_Name) //Bypass for Integration User         
                              item.addError(System.Label.Order_Planned_Delivery_Date_Validation_Error_Message);        
                      }
                }
            }
        }
    }
    
    
    /*------------------------------------------------------------------------
Author:        Shailja
Company:       Salesforce
Description:   Method to update intent
Inputs:        Map of records
Test Class:   
----------------------------------------------------------------------------
History
07-07-2020      Shailja     Initial Release
----------------------------------------------------------------------------*/
    public void updateIntentOnUpdate(map<Id, Order> newOrders, map<Id, Order> oldOrders){
        for(Order dv : newOrders.values()){
            if(String.isNotBlank(dv.Intent__c)){  
                dv.Intent__c = '';
            }
        }
    }
    
    /*------------------------------------------------------------------------
Author:        Kartik Shetty
Company:       Salesforce
Description:   Method to autopopulate the warehouse lookup field in order records.
Inputs:        List<Order>
----------------------------------------------------------------------------*/
    public void populateDefaultOrderWarehouses(List<Order> newLineItems) {        
        List<Order> orderWarehousesToDefault = new List<Order>();
        Id LocksB2CISTDRecordTypeId=Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get(GlobalConstants.RECORDTYPE_Locks_B2C_ISTD).getRecordTypeId();
        
        for(Order orderRecord : newLineItems) {
            //Added recordType filter for Locks_B2C_ISTD to Skip populateDefaultOrderWarehouses. SSD check added by Sreekanth Jujare
            if(orderRecord.WarehouseCode__c == null && orderRecord.RecordTypeId!=LocksB2CISTDRecordTypeId && orderRecord.Business_Unit__c !=  GlobalConstants.SSD_BUSINESS_UNIT) {
                orderWarehousesToDefault.add(orderRecord);
            }            
        }
        
        InventoryUtilityController inventoryUtilityControllerObj = new InventoryUtilityController();
        if(orderWarehousesToDefault.size() > 0) {
            inventoryUtilityControllerObj.defaultOrderWarehouses(orderWarehousesToDefault);
        }
    }
    
    /*------------------------------------------------------------------------
Author:        Kartik Shetty
Company:       Salesforce
Description:   Method to validate whether the currect warehouse lookup field is populated in order records.
Inputs:        Map<Id, Order> newRecordMap, List<Order> oldRecords
----------------------------------------------------------------------------*/
    public void validateOrderWarehouses(Map<Id, Order> newRecordMap, List<Order> oldRecords) {
        System.debug('validateOrderWarehouses');
        InventoryUtilityController inventoryUtilityControllerObj = new InventoryUtilityController();
        Id LocksB2CISTDRecordTypeId=Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get(GlobalConstants.RECORDTYPE_Locks_B2C_ISTD).getRecordTypeId();
        
        if(oldRecords.size() == 0) {
            inventoryUtilityControllerObj.validateOrderWarehouses(newRecordMap.values());
        } else {
            List<Order> orderWarehousesToValidate = new List<Order>();
            
            for(Order oldOrderRecord : oldRecords) {
                Order newOrderRecord = newRecordMap.get(oldOrderRecord.Id);
                if(newOrderRecord.WarehouseCode__c != null && oldOrderRecord.WarehouseCode__c != newOrderRecord.WarehouseCode__c && newOrderRecord.RecordTypeId!=LocksB2CISTDRecordTypeId && newOrderRecord.Business_Unit__c !=  GlobalConstants.SSD_BUSINESS_UNIT) {
                    orderWarehousesToValidate.add(newOrderRecord);
                }
            }
            
            System.debug('orderWarehousesToValidate:: ' + orderWarehousesToValidate.size());
            if(orderWarehousesToValidate.size() > 0) {
                inventoryUtilityControllerObj.validateOrderWarehouses(orderWarehousesToValidate);
            }
        }
    }
    
    /*------------------------------------------------------------------------
Author:        Kartik Shetty
Company:       Salesforce
Description:   Method to update the warehouse lookup of child records if parent record is updated.
Inputs:        Map<Id, Quote> newRecordMap, List<Quote> oldRecords
----------------------------------------------------------------------------*/
    public void updateOrderItemWarehouses(Map<Id, Order> newRecordMap, List<Order> oldRecords) {
        // Create a set of orderIds which will be used to query order items.
        Set<Id> orderIds = new Set<Id>();
        for(Order oldOrderRecord : oldRecords) {
            Order newOrderRecord =  newRecordMap.get(oldOrderRecord.Id);
            if(oldOrderRecord.WarehouseCode__c != newOrderRecord.WarehouseCode__c) {
                orderIds.add(newOrderRecord.Id);
            }
        }
        
        // Get order items and iterate over them to update their warehouse lookup values to that of their respective orders.
        List<OrderItem> orderItems = new List<OrderItem>();
        for(OrderItem orderItem : [Select Id, OrderId, Warehouse__c FROM OrderItem WHERE OrderId IN :orderIds]) {
            orderItem.Warehouse__c = newRecordMap.get(orderItem.OrderId).WarehouseCode__c;
            orderItems.add(orderItem);
        }
        
        if(orderItems.size() > 0) {
            update orderItems;
        }
    }
    
    /*------------------------------------------------------------------------
Author:        Abhishek
Company:       Salesforce
Description:   Generate claim request for Orders
Inputs:        Map<Id,Order> newQuotes,Map<Id,Order> oldQuotes
----------------------------------------------------------------------------*/
    
    public void generateClaimRequestForOrders(Map<Id,Order> newOrders,Map<Id,Order> oldOrders) {
        Id mhePrimaryOrderRecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get(GlobalConstants.MHE_PRIMARY).getRecordTypeId();
        id claimRequestRecordTypeId = Schema.SObjectType.Claim_Requests__c.getRecordTypeInfosByDeveloperName().get(GlobalConstants.CLAIM_REQUEST_RECORDTYPE_CLAIM_REQUEST).getRecordTypeId();
        List<Claim_Requests__c> claimRequestsToInsert = new List<Claim_Requests__c>();
        Set<Id> quotesToQuery = new Set<Id>();
        for(Order updatedOrder : newOrders.values()) {
            if(updatedOrder.RecordTypeId == mhePrimaryOrderRecordTypeId && updatedOrder.QuoteId != NULL) {
                if(updatedOrder.Order_Reference_Number_Ext__c != oldOrders.get(updatedOrder.Id).Order_Reference_Number_Ext__c 
                   && String.isNotBlank(updatedOrder.Order_Reference_Number_Ext__c)
                   && String.isBlank(oldOrders.get(updatedOrder.Id).Order_Reference_Number_Ext__c)) {
                       quotesToQuery.add(updatedOrder.QuoteId);
                   }
            }
        }
        
        if(quotesToQuery.size() > 0) {
            Map<Id,Quote> quoteMap = new Map<Id,Quote>([SELECT Id,Quantity__c,SCC_Activities__c,Associated_Dealer__c,Commission__c,Transaction_Type__c,OwnerId FROM Quote WHERE Id IN :quotesToQuery AND SCC_Activities__c != NULL AND Associated_Dealer__c != NULL AND quote.Commission__c > 0 AND quote.Transaction_Type__c = 'Primary']);
            
            for(Order updatedOrder : newOrders.values()) {
                if(updatedOrder.RecordTypeId == mhePrimaryOrderRecordTypeId && updatedOrder.QuoteId != NULL) {
                    if(quoteMap.containsKey(updatedOrder.QuoteId)) {
                        Quote associatedQuote = quoteMap.get(updatedOrder.QuoteId);
                        string activities = associatedQuote.SCC_Activities__c;
                        List<String> sccActivities = activities.split(';');
                        if(sccActivities.size() > 0) {
                            Claim_Requests__c newRequest = new Claim_Requests__c();
                            newRequest.Godrej_Sales_Order__c = updatedOrder.Id;
                            newRequest.Approval_Status__c = 'Approved';
                            newRequest.OwnerId = associatedQuote.OwnerId;
                            newRequest.Quote__c = associatedQuote.Id;
                            newRequest.Quantity__c = 1;
                            newRequest.Branch__c = updatedOrder.Area__c;
                            newRequest.Area_Code__c = updatedOrder.Area__c;
                            newRequest.Customer_Name__c = updatedOrder.End_Customer__c;
                            newRequest.SCC_Activities__c = associatedQuote.SCC_Activities__c;
                            newRequest.Commission__c = associatedQuote.Commission__c;
                            newRequest.RecordTypeId = claimRequestRecordTypeId;
                            newRequest.Business_Partner_Name__c = associatedQuote.Associated_Dealer__c;
                            newRequest.MHE_Division__c = updatedOrder.MHE_Division__c;
                            claimRequestsToInsert.add(newRequest);
                        }
                    }
                }
            }
        }
        
        insert claimRequestsToInsert;
    }
    /*------------------------------------------------------------------------
Author     :  Siddhesh Mayekar
Date       :  29/11/2021
Description:  Show validation error if User other than Order's owner/its L+1 is trying to submit order for approval(SSG-Primary).
Inputs     :  Map<Id, Order> mapNewOrderRecords, Map<Id, Order> mapOldOrderRecords)
----------------------------------------------------------------------------*/
    public void checkForOrderSubmitterForSSG(Map<Id, Order> mapNewOrderRecords, Map<Id, Order> mapOldOrderRecords){
        for(Id orderId : mapNewOrderRecords.keySet()) {
            if(mapNewOrderRecords.get(orderId).Business_Unit__c==GlobalConstants.SSG_BUSINESS_UNIT && mapNewOrderRecords.get(orderId).Approval_Status__c == GlobalConstants.Submitted_for_Approval && mapOldOrderRecords.get(orderId).Approval_Status__c != mapNewOrderRecords.get(orderId).Approval_Status__c){                                                                                                   
                if(userInfo.getUserId() != mapNewOrderRecords.get(orderId).Internal_Sales_Representative__c && userInfo.getUserId() != mapNewOrderRecords.get(orderId).Owner_Manager__c)
                    mapNewOrderRecords.get(orderId).addError(System.Label.Error_on_Submit_for_Approval);                                                               
            }
        }         
    } 
    
    /*------------------------------------------------------------------------
Author     :  Shreela Nair
Date       :  05/04/2022
Description:  To call OrderNotificationToMheOutrightUser method of EmailNotificationWithAttachments class. 
Added for Jira number - SMEPB 19
Inputs     :  Map<Id,Order> newOrders,Map<Id,Order> oldOrders 
----------------------------------------------------------------------------*/
    
    public void OrderNotificationToMheOutrightUser(Map<Id,Order> newOrders,Map<Id,Order> oldOrders) {
        //Added By Shreela on 5th April2022 for Jira number - SMEPB 19 
        Set<Id> orderIds = new Set<Id>();
        for(Order ord :  newOrders.values()){ 
            //Check whether the record is from Mhe business of  Outright Sales Record Type
            if(ord.Business_Unit__c== GlobalConstants.BUSINESS_UNIT_MHE_DIVISION && ord.Integration_Status__c==GlobalConstants.INTEGRATION_STATUS_SYNCED
               && ord.MHE_Division__c== GlobalConstants.MHE_SUB_DIVISION_EQUIPMENT 
               && ord.integration_Status__c!=oldOrders.get(ord.Id).integration_Status__c){                  
                   orderIds.add(ord.Id);
               }          
        }
        
        if(!orderIds.isempty()){
            EmailNotificationWithAttachments.OrderNotificationToMheOutrightUser(orderIds,oldOrders);
        }
    }
    
    /*------------------------------------------------------------------------
Author:        Priyanka Mukkavalli
Company:       GITL
Description:   Method to refrain any updates to an approved MHE order other than Integration status = Ready to Sync
Inputs:        list of created order records
Test Class:   

History
30-07-2022     Priyanka Mukkavalli     Initial Release
----------------------------------------------------------------------------*/
    //public void restrictUpdatesOnApprovedMHEOrders(list<Order> lstOrder,Map<Id,Order> mapOldItems){
    public void restrictUpdatesOnApprovedMHEOrders(Map<Id,Order> mapNewItems,Map<Id,Order> mapOldItems){
        List<Order> lstOrder = mapNewItems.values();
        for(Order objOrder : lstOrder){ 
            if(objOrder.Business_Unit__c==GlobalConstants.BUSINESS_UNIT_MHE_DIVISION && 
               (objOrder.MHE_Division__c==GlobalConstants.MHE_SUB_DIVISION_PARTS || objOrder.MHE_Division__c==GlobalConstants.MHE_SUB_DIVISION_EQUIPMENT) &&
               (objOrder.Mr_Type__c==GlobalConstants.MRType_Sales || objOrder.Mr_Type__c==GlobalConstants.MRTYPE_Service) &&
               (mapOldItems.get(objOrder.Id).Approval_Status__c==GlobalConstants.APPROVED && 
                mapOldItems.get(objOrder.Id).Approval_Status__c==objOrder.Approval_Status__c) &&
               profileName != System.Label.Integration_User_Profile_Name &&
               objOrder.Integration_Status__c!=GlobalConstants.INTEGRATION_STATUS_READY_TO_SYNC){
                   objOrder.addError(System.label.Order_cannot_be_edited_after_final_Approval);
               }
        }              
    }
    
    /*------------------------------------------------------------------------
Author:        Pankaj Meshram
Company:       GITL 
Description:   Method to give validation message if Logistic company is 2000/2010 and 
wrong warehouse/Sales office/Delivery Term/Order Type selected for MHE Equipments
Inputs:        list of created order records
Test Class:    OrderFieldPopulator
Jira      :    SMEPB-48
History
05-12-2022     Pankaj Meshram     Initial Release
----------------------------------------------------------------------------*/
    public void mheEquipOrderValidation(List<Order> lstOrder){ 
        set<Id> salesOfficeAndWarehouseIds = new set<Id>();
        Id mhePrimaryOrderRecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get(GlobalConstants.MHE_PRIMARY).getRecordTypeId();
        for(Order ord:lstOrder){
            salesOfficeAndWarehouseIds.add(ord.WarehouseCode__c);
            salesOfficeAndWarehouseIds.add(ord.Sales_Office__c);
        }
        
        Map<Id,Warehouse__c> WarehouseMap = new Map<Id,Warehouse__c>([select id,Warehouse__c from Warehouse__c where id IN:salesOfficeAndWarehouseIds]);
        Map<Id,Sales_Office__c> salesOfficeMap = new Map<Id,Sales_Office__c>([select id,Sales_Office_code__c from Sales_Office__c where id IN:salesOfficeAndWarehouseIds]);
        
        for(Order objOrder : lstOrder){            
            if(objOrder.Business_Unit__c==GlobalConstants.BUSINESS_UNIT_MHE_DIVISION && objOrder.MHE_Division__c==GlobalConstants.MHE_SUB_DIVISION_EQUIPMENT && objOrder.RecordTypeId == mhePrimaryOrderRecordTypeId)                
                if((objOrder.Logistics_Company_Branch__c == GlobalConstants.Logistics_Company_Branch_2000 || objOrder.Logistics_Company_Branch__c == GlobalConstants.Logistics_Company_Branch_2010)){                    
                    if(objOrder.Type == GlobalConstants.Order_Type_NOR && !isDeliveryTermMatched(objOrder.Delivery_Terms__c)){
                        objOrder.addError(System.Label.Invalid_Order_Type_Or_Delivery_Term);
                    } 
                    else if(objOrder.Type == GlobalConstants.Order_Type_NOF && objOrder.Delivery_Terms__c != GlobalConstants.Delivery_Term_EW1){
                        objOrder.addError(System.Label.Invalid_Order_Type_Or_Delivery_Term);
                    }
                    else if(objOrder.Logistics_Company_Branch__c == GlobalConstants.Logistics_Company_Branch_2000 && (WarehouseMap.get(objOrder.WarehouseCode__c).Warehouse__c != GlobalConstants.Warehouse_code_KAF11S || salesOfficeMap.get(objOrder.Sales_Office__c).Sales_Office_code__c != GlobalConstants.Sales_Office_code_KZA016)){
                        objOrder.addError(System.Label.Invalid_Warehouse_Or_Sales_Office_KAF11S_KZA016);
                    }
                    else if(objOrder.Logistics_Company_Branch__c == GlobalConstants.Logistics_Company_Branch_2010 && (WarehouseMap.get(objOrder.WarehouseCode__c).Warehouse__c != GlobalConstants.Warehouse_code_KBF11S || salesOfficeMap.get(objOrder.Sales_Office__c).Sales_Office_code__c != GlobalConstants.Sales_Office_code_KZASD1)){
                        objOrder.addError(System.Label.Invalid_Warehouse_Or_Sales_Office_KBF11S_KZASD1);
                    }
                }            
        } 
    } 
    /*------------------------------------------------------------------------
Author:        Pankaj Meshram
Company:       GITL 
Description:   Method to return delivery Term
Inputs:        Delivery Term available on Order
Test Class:    OrderFieldPopulator
Jira      :    SMEPB-48
History
07-12-2022     Pankaj Meshram     Initial Release
----------------------------------------------------------------------------*/
    Private Boolean isDeliveryTermMatched(String deliveryTerm){ 
        Boolean isDelTermMatched;
        if(deliveryTerm == GlobalConstants.Delivery_Term_EW4 || deliveryTerm == GlobalConstants.Delivery_Term_EW5 || deliveryTerm == GlobalConstants.Delivery_Term_EW6){
            isDelTermMatched=True;
        }else{
            isDelTermMatched=False;
        }
        return isDelTermMatched; 
    } 
    //added for SAF-196 TO UPDATE ORDER FIELD AFTER  NEW APD IS CREATED 
    public void SendOrderToLNonUpdateofNewAPD(list<Order> Orders,Map<Id,Order> oldItems){     
        
        for(Order rec : Orders){  
            if(rec.Business_Unit__c == GlobalConstants.APPLIANCE_BUSINESS_UNIT && 
               oldItems != null && oldItems.get(rec.Id) != null && 
               rec.Total_Due_Amount__c != oldItems.get(rec.Id).Total_Due_Amount__c && 
               oldItems.get(rec.Id).Header_Text__c == rec.Header_Text__c ){//added this condition SAF-99 to avoid flipping to DRAFT
                   rec.Integration_Status__c =GLobalConstants.INTEGRATION_STATUS_DRAFT ;
                   rec.Infor_Sales_Order_status__c=GLobalConstants.INFOR_SALES_ORDER_STATUS;
               }
        }
    }
}