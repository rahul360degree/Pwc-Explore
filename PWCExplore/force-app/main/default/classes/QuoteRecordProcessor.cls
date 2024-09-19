/*------------------------------------------------------------------------
Author:        Kishor Kumar
Company:       Salesforce
Description:   Processor class for 'Quote' Records
Inputs:        NA
Test Class:    
History 
08-04-2020      Kishor Kumar     Initial Release
----------------------------------------------------------------------------*/
public with sharing class QuoteRecordProcessor {
    Set<Id> quoteLineApprovalStatusSet = new Set<Id>();
    private static Map<Id, Opportunity> opportunityRecordMap = new Map<Id, Opportunity>();
    private static List<QuoteLineItem> lstQLI = new List<QuoteLineItem>();
    
    
    /*------------------------------------------------------------------------
Author:        Subhojit
Company:       Salesforce
Description:   Method to prepopulate fields on Quote
Inputs:        list of updated Quotes
Test Class:    
History
08-04-2020      Kishor Kumar     Initial Release
13-08-2020      Amit Shingavi    Added mapping for Currency field  
----------------------------------------------------------------------------*/
    public void prepopulateQuoteField(list<Quote> newQuotes){
         //List<Appliance_Approver_Setting__mdt> applData = [SELECT Area_Code__c,Level_1_Approver_Role__c,Level_2_Approver_Role__c FROM Appliance_Approver_Setting__mdt Limit 49999];
        List<Appliance_Approver_Setting__mdt> applData = new List<Appliance_Approver_Setting__mdt>(Appliance_Approver_Setting__mdt.getAll().values());
        Set<Id> setOppIds=new Set<Id>();
        Map<Id, String> ownerToSalesBranchMap = new Map<Id, String>();
        for(Quote oQVar: newQuotes){
            setOppIds.add(oQVar.OpportunityId);
        }
        Utility utilityVar = new Utility();
        map<String, Id> rtNameVsId =  utilityVar.fetchRecordTypes('Quote');
        List<String> recordtypesNotApplicable = new List<String>();
        
        if(String.IsNotBlank(System.Label.Quote_Interio_B2B_Record_Types))
            recordtypesNotApplicable = System.Label.Quote_Interio_B2B_Record_Types.split(',');
        
        //Quote : MHE Rentals has a different list of Order Type
        recordtypesNotApplicable.add(GlobalConstants.QUOTE_MHE_RENTALS_RECORDTYPE_APINAME);
        Set<Id> notApplicableRecordTypeIds = new Set<Id>();
        for (String each: recordtypesNotApplicable) {
            notApplicableRecordTypeIds.add(rtNameVsId.get(each));
        }
        // Added Owner.Manager.Email field in query by Rohit Jadhav on 1st August 2023 for SLF-118
        // Added RecordType.DeveloperName field in query by Rohit Jadhav for PED on 6th july 2023
        Map<Id,Opportunity> mapOpp=new Map<Id,Opportunity>([select Id,OwnerId,Business_Unit__c,SSG_Territory__c,Dealer_Name__c,End_Customer__c,AccountId,Sales_Branch_Name__c, Service_Branch_Name__c, Area_Code__c, Opportunity_Type__c,Currency__c,LocksSegment__c, OEM__C,Influencer__c,ZipCode__c,LOB_N__c,Site__c,Plant_Location__c,
                                                            Basic_Rate_Per_CBM__c,Cluster__c,Sub_segment__c,Internal_Sales_Rep__c,Project_qty_m3_1000__c, Rating_N__c, Grade__c, Probability__c, G_B_qty_m3_300__c,Account.Name,Project_Details__c,Converted_Lead__r.Name,Regular_Key__c,Dealer_Involved_Y_N__c,City_Details__c,
                                                            Estimated_Project_AAC_Qty_in_CBM__c,Estimated_Project_Duroplast_Qty_Bag__c,Estimated_Project_EasyFix_Qty_Bag__c,Product_List__c,
                                                            Est_Project_Solid_Concrete_Block_Nos__c,Estimated_Project_Pavers_in_Sqm__c,Estimated_Project_Curb_Stone_in_Nos__c,
                                                            G_B_Quantity_Curb_Stone_in_Nos__c,G_B_Quantity_Pavers_in_Sqm__c,G_B_Quantity_Solid_Concrete_Block_Nos__c,//Added by Poonam for SCF- 69 & SCF - 102
                                                            G_B_Quantity_AAC_Qty_in_CBM__c,G_B_Quantity_Duroplast_Qty_Bags__c,G_B_Quantity_EasyFix_Qty_Bags__c,Estimated_Project_Tilefix_Qty_Bag__c,G_B_Quantity_Tilefix_Qty_Bags__c,
                                                            Solution_Offering_Level_1__c,Solution_Offering_Level_2__c,Owner.Manager.Email,RecordType.DeveloperName,Geographical_Location__c,Export_Control_End_Use_Certificate__c,Incoterm__c,
                                                            Conversion_Rate__c from Opportunity where Id IN :setOppIds]);        
        
        //Branch Champion & Service Addresses
       // List<Branch_Champion_ServiceAddress_Config__mdt> branchRelations = new List<Branch_Champion_ServiceAddress_Config__mdt>([SELECT ID, Branch__c, Champion_Code__c, Service_Address__c 
       //                                                                                                                      FROM Branch_Champion_ServiceAddress_Config__mdt Limit 49999]);
    List<Branch_Champion_ServiceAddress_Config__mdt> branchRelations = Branch_Champion_ServiceAddress_Config__mdt.getAll().values();
        Map<String, Branch_Champion_ServiceAddress_Config__mdt> branchRelationMap = new Map<String, Branch_Champion_ServiceAddress_Config__mdt>();
        Set<String> championCodeSet = new Set<String>();
        // Added by Rohit Jadhav for PED on 18th August 2023
        String pedRecordTypeId=Schema.SObjectType.Quote.RecordTypeInfosByName.get(GlobalConstants.PED_QUOTE_RT).RecordTypeId;        
        for(Branch_Champion_ServiceAddress_Config__mdt bRelation : branchRelations)
        {
            branchRelationMap.put(bRelation.Branch__c, bRelation);
            championCodeSet.add(bRelation.Champion_Code__c);
        }
        List<User> championUsers = new List<User>([Select Id, Salary_Code__c  From User where Salary_Code__c IN :championCodeSet]);
        Map<String, ID> champUserMap = new Map<String, ID>();        
        for(User champ : championUsers)
            champUserMap.put(champ.Salary_Code__c, champ.ID);
        //Added by Anupam Mishra to fetch details from logged In user records
        map<Id, User> userMap = new map<Id, User>();    
        // Added new field in query by Rohit Jadhav on 11 July 2023 for PED. -->  Manager.Manager.persona__c
        for(User userRec: [SELECT Id, Business_Unit__c, Sub_Division__c,
                           ManagerId,Persona__c,Manager.persona__c,Manager.Manager.persona__c, Manager.ManagerId, Manager.Manager.ManagerId FROM User                                                                        
                           WHERE Id  =: userInfo.getUserId()]){
                               userMap.put(userRec.Id, userRec);
                           }
        Set<Id> oprIdSet = new Set<Id>();
        for(Quote oQVar: newQuotes){
            if(mapOpp.get(oQvar.OpportunityId).Converted_Lead__c != null && mapOpp.get(oQvar.OpportunityId).Business_Unit__c == GlobalConstants.Construction_BUSINESS_UNIT){
                oprIdSet.add(oQvar.OpportunityId);
            }
        }
        Map<Id,String> opID_ContactName = new Map<Id,String>();
        if(!oprIdSet.isEmpty()){
            List<Lead> convertedlead = [Select Id, ConvertedContact.Name,ConvertedContact.Salutation,
                                        ConvertedOpportunityId 
                                        from Lead 
                                        where ConvertedOpportunityId IN:oprIdSet];
            //Declared variable to append salutation to contact name 
            
            for(Lead lead:convertedlead){
                String fullName = lead.ConvertedContact.Salutation + lead.ConvertedContact.Name; 
                opID_ContactName.put(lead.convertedOpportunityId, fullName);
            }
        }
        
        map<Id, User> userMapRecords = new map<Id, User>([SELECT Id,Business_Unit__c, Sub_Division__c,Persona__c,Role_Name__c,Name
                           FROM User 
                           WHERE Persona__c=:GlobalConstants.APPL_REG_MANAGER_PERSONA
                           OR Persona__c=:GlobalConstants.APPL_DSM_PERSONA
                           OR Persona__c=:GlobalConstants.APPL_HO_PERSONA]);    //Added lines 89 - 93 by Shreela Nair and Namrata Negi on 26th August 2022 for SAEPB - 44
               
        for(Quote oQVar: newQuotes){
            if(oQVar.Record_Type_Developer_Name__c == GlobalConstants.QUOTE_RECORDTYPE_APPLIANCE){
                //To assign HO as Level 3 Approver
                for(User usr : userMapRecords.values()){
                    if(usr.Name == System.label.HO_Approver_for_Appliance_D2D){
                        oQVar.Level_3_Approver__c =  usr.Id;                            
                    }
                    
                }
                                
                //To assign Level 1 Approver (Branch Manager) and Level 2 Approver (ZonaL Manager) according to area code
                for (Appliance_Approver_Setting__mdt mdt : applData ){
                    if(mapOpp.get(oQVar.OpportunityId).Area_Code__c == mdt.Area_Code__c){
                        for(User usr : userMapRecords.values()){
                            if(usr.Role_Name__c == mdt.Level_1_Approver_Role__c){
                                oQVar.Level_1_Approver__c = usr.Id; 
                            }                           
                        }
                        
                        for(User usr : userMapRecords.values()){
                            if(usr.Role_Name__c == mdt.Level_2_Approver_Role__c){
                                oQVar.Level_2_Approver__c = usr.Id; 
                            }  
                        }
                        
                    }
                }  //Added Lines 106 - 121 by Shreela Nair on 3rd October 2022 for SAEPB - 44
                
            }  //Added 96 - 123 Lines by Shreela Nair and Namrata Negi on 26th August 2022 for SAEPB - 44
                        
            //Added by Anupam Mishra
            if(mapOpp.get(oQVar.OpportunityId).Business_Unit__c == GlobalConstants.Locks_BUSINESS_UNIT){        
                if(userMap.get(userInfo.getUserId()).Persona__c == GlobalConstants.locks_bde_persona){
                    system.debug('test1:'+userMap.get(userInfo.getUserId()).Manager.persona__c);
                    If(userMap.get(userInfo.getUserId()).Manager.persona__c == GlobalConstants.locks_zm_persona){ //Changed by Srini as per new hierarchy on 09 May 2023
                     
                    oQVar.Locks_Zonal_Manager__c=userMap.get(userInfo.getUserId()).ManagerId;  //Changed by Srini as per new hierarchy on 09 May 2023
                    oQVar.Locks_Regional_Manager__c=userMap.get(userInfo.getUserId()).Manager.ManagerId;  //Changed by Srini as per new hierarchy on 09 May 2023   
                    system.debug('test2:'+userMap.get(userInfo.getUserId()).ManagerId);
                    }else{
                    oQVar.Locks_Zonal_Manager__c=userMap.get(userInfo.getUserId()).Manager.ManagerId;  //Changed by Srini as per new hierarchy on 09 May 2023
                    oQVar.Locks_Regional_Manager__c=userMap.get(userInfo.getUserId()).Manager.Manager.ManagerId;  //Changed by Srini as per new hierarchy on 09 May 2023
                    system.debug('test3:'+userMap.get(userInfo.getUserId()).Manager.Manager.ManagerId);
                    }    
                }else if(userMap.get(userInfo.getUserId()).Persona__c == GlobalConstants.locks_bdm_persona){
                    oQVar.Locks_Zonal_Manager__c = userMap.get(userInfo.getUserId()).ManagerId;//Changed by Srini as per new hierarchy on 09 May 2023
                    oQVar.Locks_Regional_Manager__c = userMap.get(userInfo.getUserId()).Manager.ManagerId;  //Changed by Srini as per new hierarchy on 09 May 2023
                }
                else if(userMap.get(userInfo.getUserId()).Persona__c == GlobalConstants.locks_zm_persona){
                    oQVar.Locks_Regional_Manager__c = userMap.get(userInfo.getUserId()).ManagerId; // Changed by Srini as per new hierarchy on 18th May 2023
                }
                
             	// Added by Rohit Jadhav on 1st August 2023 for SLF-118
                if(mapOpp.get(oQVar.OpportunityId).Owner.Manager.Email!=null){
                    oQVar.Manager_s_Email_Id__c=mapOpp.get(oQVar.OpportunityId).Owner.Manager.Email;
                }                    
            }
       		 
            if(mapOpp.containsKey(oQVar.OpportunityId)){
                oQVar.Opportunity_Owner__c=mapOpp.get(oQVar.OpportunityId).OwnerId;
                
                //Added By Kishor :: DE528 :: opportunity type from opportunity should be auto populated as category in the quote  
                if(String.isBlank(oQVar.Category__c))
                    oQVar.Category__c = mapOpp.get(oQVar.OpportunityId).Opportunity_Type__c; 
                
                // Updated by Anupam:::: For SSG division Populate these fields only if not selected by User  
                if(oQVar.Dealer_Name__c== null && oQVar.Dealer_Involved_Y_N__c=='Yes' && oQVar.Record_Type_Developer_Name__c == GlobalConstants.QUOTE_RECORDTYPE_SSG )
                    oQVar.Dealer_Name__c=mapOpp.get(oQVar.OpportunityId).Dealer_Name__c;
                
                if(oQVar.Dealer_Involved_Y_N__c=='Yes' && oQVar.Record_Type_Developer_Name__c == GlobalConstants.QUOTE_RECORDTYPE_SSG) {  
                    oQVar.Dealer_Direct_Customer_order__c='Dealer';
                }else{                   
                    oQVar.Dealer_Direct_Customer_order__c='Direct';
                }
                
                // Start: Added by Anupam on 28/02/2022 :To Autopopulate Opportunity fields on Quote for Locks B2B
                if(mapOpp.get(oQVar.OpportunityId).LocksSegment__c != null && oQvar.Record_Type_Developer_Name__c == GlobalConstants.RECORDTYPE_Locks_B2B)
                    oQVar.Segment__c=mapOpp.get(oQVar.OpportunityId).LocksSegment__c;  
                
                if(mapOpp.get(oQVar.OpportunityId).Sub_segment__c!= null && oQvar.Record_Type_Developer_Name__c == GlobalConstants.RECORDTYPE_Locks_B2B)
                    oQVar.Sub_segment__c=mapOpp.get(oQVar.OpportunityId).Sub_segment__c; 
                
                if(mapOpp.get(oQVar.OpportunityId).Dealer_Name__c !=null &&  oQVar.Record_Type_Developer_Name__c == GlobalConstants.RECORDTYPE_Locks_B2B )
                    oQVar.Dealer_Name__c=mapOpp.get(oQVar.OpportunityId).Dealer_Name__c;
                
                if(mapOpp.get(oQVar.OpportunityId).Project_Details__c != null && oQvar.Record_Type_Developer_Name__c == GlobalConstants.RECORDTYPE_Locks_B2B)
                    oQVar.Project_Details__c=mapOpp.get(oQVar.OpportunityId).Project_Details__c; 
                
                if(mapOpp.get(oQVar.OpportunityId).OEM__c != null){
                    if(oQVar.OEM__c== null && oQVar.Record_Type_Developer_Name__c == GlobalConstants.RECORDTYPE_Locks_B2B)
                        oQVar.OEM__c=mapOpp.get(oQVar.OpportunityId).OEM__c;
                }
                if(mapOpp.get(oQVar.OpportunityId).Influencer__c != null){ 
                    if(oQVar.Influencer__c== null && oQVar.Record_Type_Developer_Name__c == GlobalConstants.RECORDTYPE_Locks_B2B)
                        oQVar.Influencer__c=mapOpp.get(oQVar.OpportunityId).Influencer__c;
                } 
                
                if(mapOpp.get(oQVar.OpportunityId).ZipCode__c!= null){ 
                    if(oQVar.Zip_Code__c== null && oQVar.Record_Type_Developer_Name__c == GlobalConstants.RECORDTYPE_Locks_B2B)
                        oQVar.Zip_Code__c=mapOpp.get(oQVar.OpportunityId).ZipCode__c;
                } 
                // End: Added by Anupam on 28/02/2022 :To Autopopulate Opportunity fields on Quote     
                //Start: Added by Siddhesh on 18/03/2022 :To Autopopulate Opportunity fields on Quote for Const B2B & mandatory field validation for based on LOB            
                if(mapOpp.get(oQvar.OpportunityId).LOB_N__c != null && mapOpp.get(oQvar.OpportunityId).Business_Unit__c == GlobalConstants.Construction_BUSINESS_UNIT){
                    if(oQvar.LOB_N__c  == null && oQvar.Record_Type_Developer_Name__c == GlobalConstants.RECORDTYPE_Construction_B2B)
                        oQvar.LOB_N__c = mapOpp.get(oQvar.OpportunityId).LOB_N__c;
                }
                if(mapOpp.get(oQvar.OpportunityId).Converted_Lead__c != null && mapOpp.get(oQvar.OpportunityId).Business_Unit__c == GlobalConstants.Construction_BUSINESS_UNIT){
                    oQvar.QuoteToName = mapOpp.get(oQvar.OpportunityId).Converted_Lead__r.Name.SubStringBefore(',');
                }
                
                if(mapOpp.get(oQvar.OpportunityId).Site__c != null && mapOpp.get(oQvar.OpportunityId).Business_Unit__c == GlobalConstants.Construction_BUSINESS_UNIT){
                    if(oQvar.Site__c  == null && oQvar.Record_Type_Developer_Name__c == GlobalConstants.RECORDTYPE_Construction_B2B)
                        oQvar.Site__c = mapOpp.get(oQvar.OpportunityId).Site__c;
                }
                if(mapOpp.get(oQvar.OpportunityId).Basic_Rate_Per_CBM__c != null && mapOpp.get(oQvar.OpportunityId).Business_Unit__c == GlobalConstants.Construction_BUSINESS_UNIT){
                    if(oQvar.Basic_Rate_Per_CBM__c  == null && oQvar.Record_Type_Developer_Name__c == GlobalConstants.RECORDTYPE_Construction_B2B)
                        oQvar.Basic_Rate_Per_CBM__c = mapOpp.get(oQvar.OpportunityId).Basic_Rate_Per_CBM__c;
                }
                if(mapOpp.get(oQvar.OpportunityId).Plant_Location__c != null && mapOpp.get(oQvar.OpportunityId).Business_Unit__c == GlobalConstants.Construction_BUSINESS_UNIT){
                    if(oQvar.Plant_Location__c  == null && oQvar.Record_Type_Developer_Name__c == GlobalConstants.RECORDTYPE_Construction_B2B)
                        oQvar.Plant_Location__c = mapOpp.get(oQvar.OpportunityId).Plant_Location__c;
                }
                if(mapOpp.get(oQvar.OpportunityId).Cluster__c != null){
                    if(oQvar.Cluster__c  == null && oQvar.Record_Type_Developer_Name__c == GlobalConstants.RECORDTYPE_Construction_B2B)
                        oQvar.Cluster__c = mapOpp.get(oQvar.OpportunityId).Cluster__c;
                }   
                
                if(mapOpp.get(oQvar.OpportunityId).Internal_Sales_Rep__c != null && mapOpp.get(oQvar.OpportunityId).Business_Unit__c == GlobalConstants.Construction_BUSINESS_UNIT){
                    if(oQvar.Internal_Sales_Representative__c  == null && oQvar.Record_Type_Developer_Name__c == GlobalConstants.RECORDTYPE_Construction_B2B)
                        oQvar.Internal_Sales_Representative__c = mapOpp.get(oQvar.OpportunityId).Internal_Sales_Rep__c;
                }   
                
                if (oQvar.Record_Type_Developer_Name__c == GlobalConstants.RECORDTYPE_Construction_B2B){
                    if(oQvar.LOB_N__c  == GlobalConstants.Construction_LOB_RMC){
                        if(mapOpp.get(oQvar.OpportunityId).Project_qty_m3_1000__c != null && mapOpp.get(oQvar.OpportunityId).Business_Unit__c == GlobalConstants.Construction_BUSINESS_UNIT){
                    	if(oQvar.Project_qty_m3_1000__c  == null)
                        	oQvar.Project_qty_m3_1000__c = mapOpp.get(oQvar.OpportunityId).Project_qty_m3_1000__c;
                		}
                
                		if(mapOpp.get(oQvar.OpportunityId).G_B_qty_m3_300__c != null && mapOpp.get(oQvar.OpportunityId).Business_Unit__c == GlobalConstants.Construction_BUSINESS_UNIT){
                    		if(oQvar.G_B_qty_m3_300__c  == null)
                        		oQvar.G_B_qty_m3_300__c = mapOpp.get(oQvar.OpportunityId).G_B_qty_m3_300__c;
                		}
                    }
                    //Added by Poonam for SCF - 69
                    
                    if(oQvar.LOB_N__c  == GlobalConstants.Construction_LOB_WPS){        
                        if(mapOpp.get(oQvar.OpportunityId).Product_List__c != null && mapOpp.get(oQvar.OpportunityId).Business_Unit__c == GlobalConstants.Construction_BUSINESS_UNIT){                  //Added for SCF -69
                            if(oQvar.Product_List__c == null)
                                oQvar.Product_List__c = mapOpp.get(oQvar.OpportunityId).Product_List__c;
                        }
                        if(mapOpp.get(oQvar.OpportunityId).Estimated_Project_AAC_Qty_in_CBM__c != null && mapOpp.get(oQvar.OpportunityId).Business_Unit__c == GlobalConstants.Construction_BUSINESS_UNIT){                  //Added for SCF -69
                            if(oQvar.Estimated_Project_AAC_Qty_in_CBM__c == null)
                                oQvar.Estimated_Project_AAC_Qty_in_CBM__c = mapOpp.get(oQvar.OpportunityId).Estimated_Project_AAC_Qty_in_CBM__c;
                        }
                        if(mapOpp.get(oQvar.OpportunityId).Estimated_Project_Duroplast_Qty_Bag__c != null && mapOpp.get(oQvar.OpportunityId).Business_Unit__c == GlobalConstants.Construction_BUSINESS_UNIT){                //Added for SCF -69
                            if(oQvar.Estimated_Project_Duroplast_Qty_Bag__c == null)
                                oQvar.Estimated_Project_Duroplast_Qty_Bag__c = mapOpp.get(oQvar.OpportunityId).Estimated_Project_Duroplast_Qty_Bag__c;
                        }
                        
                        if(mapOpp.get(oQvar.OpportunityId).Estimated_Project_EasyFix_Qty_Bag__c != null && mapOpp.get(oQvar.OpportunityId).Business_Unit__c == GlobalConstants.Construction_BUSINESS_UNIT){                //Added for SCF -69
                            if(oQvar.Estimated_Project_EasyFix_Qty_Bag__c == null)
                                oQvar.Estimated_Project_EasyFix_Qty_Bag__c = mapOpp.get(oQvar.OpportunityId).Estimated_Project_EasyFix_Qty_Bag__c;
                        }
                        
                        if(mapOpp.get(oQvar.OpportunityId).G_B_Quantity_AAC_Qty_in_CBM__c != null && mapOpp.get(oQvar.OpportunityId).Business_Unit__c == GlobalConstants.Construction_BUSINESS_UNIT){                       //Added for SCF -69
                            if(oQvar.G_B_Quantity_AAC_Qty_in_CBM__c == null)
                                oQvar.G_B_Quantity_AAC_Qty_in_CBM__c = mapOpp.get(oQvar.OpportunityId).G_B_Quantity_AAC_Qty_in_CBM__c;
                        }
                        
                        if(mapOpp.get(oQvar.OpportunityId).G_B_Quantity_Duroplast_Qty_Bags__c != null && mapOpp.get(oQvar.OpportunityId).Business_Unit__c == GlobalConstants.Construction_BUSINESS_UNIT){                   //Added for SCF -69
                            if(oQvar.G_B_Quantity_Duroplast_Qty_Bags__c == null)
                                oQvar.G_B_Quantity_Duroplast_Qty_Bags__c = mapOpp.get(oQvar.OpportunityId).G_B_Quantity_Duroplast_Qty_Bags__c;
                        }
                        
                        if(mapOpp.get(oQvar.OpportunityId).G_B_Quantity_EasyFix_Qty_Bags__c != null && mapOpp.get(oQvar.OpportunityId).Business_Unit__c == GlobalConstants.Construction_BUSINESS_UNIT){                    //Added for SCF -69
                            if(oQvar.G_B_Quantity_EasyFix_Qty_Bags__c == null)
                                oQvar.G_B_Quantity_EasyFix_Qty_Bags__c = mapOpp.get(oQvar.OpportunityId).G_B_Quantity_EasyFix_Qty_Bags__c;
                        }
                        
                        if(mapOpp.get(oQvar.OpportunityId).Est_Project_Solid_Concrete_Block_Nos__c != null && mapOpp.get(oQvar.OpportunityId).Business_Unit__c == GlobalConstants.Construction_BUSINESS_UNIT){                    //Added for SCF -69
                            if(oQvar.Est_Project_Solid_Concrete_Block_Nos__c == null)
                                oQvar.Est_Project_Solid_Concrete_Block_Nos__c = mapOpp.get(oQvar.OpportunityId).Est_Project_Solid_Concrete_Block_Nos__c;
                        }
                        
                        if(mapOpp.get(oQvar.OpportunityId).G_B_Quantity_Solid_Concrete_Block_Nos__c != null && mapOpp.get(oQvar.OpportunityId).Business_Unit__c == GlobalConstants.Construction_BUSINESS_UNIT){                    //Added for SCF -69
                            if(oQvar.G_B_Quantity_Solid_Concrete_Block_Nos__c == null)
                                oQvar.G_B_Quantity_Solid_Concrete_Block_Nos__c = mapOpp.get(oQvar.OpportunityId).G_B_Quantity_Solid_Concrete_Block_Nos__c;
                        }
                        
                        if(mapOpp.get(oQvar.OpportunityId).Estimated_Project_Pavers_in_Sqm__c != null && mapOpp.get(oQvar.OpportunityId).Business_Unit__c == GlobalConstants.Construction_BUSINESS_UNIT){                    //Added for SCF -69
                            if(oQvar.Estimated_Project_Pavers_in_Sqm__c == null)
                                oQvar.Estimated_Project_Pavers_in_Sqm__c = mapOpp.get(oQvar.OpportunityId).Estimated_Project_Pavers_in_Sqm__c;
                        }
                        
                        if(mapOpp.get(oQvar.OpportunityId).G_B_Quantity_Pavers_in_Sqm__c != null && mapOpp.get(oQvar.OpportunityId).Business_Unit__c == GlobalConstants.Construction_BUSINESS_UNIT){                    //Added for SCF -69
                            if(oQvar.G_B_Quantity_Pavers_in_Sqm__c == null)
                                oQvar.G_B_Quantity_Pavers_in_Sqm__c = mapOpp.get(oQvar.OpportunityId).G_B_Quantity_Pavers_in_Sqm__c;
                        }
                        
                        if(mapOpp.get(oQvar.OpportunityId).Estimated_Project_Curb_Stone_in_Nos__c != null && mapOpp.get(oQvar.OpportunityId).Business_Unit__c == GlobalConstants.Construction_BUSINESS_UNIT){                    //Added for SCF -69
                            if(oQvar.Estimated_Project_Curb_Stone_in_Nos__c == null)
                                oQvar.Estimated_Project_Curb_Stone_in_Nos__c = mapOpp.get(oQvar.OpportunityId).Estimated_Project_Curb_Stone_in_Nos__c;
                        }
                        
                        if(mapOpp.get(oQvar.OpportunityId).G_B_Quantity_Curb_Stone_in_Nos__c != null && mapOpp.get(oQvar.OpportunityId).Business_Unit__c == GlobalConstants.Construction_BUSINESS_UNIT){                    //Added for SCF -69
                            if(oQvar.G_B_Quantity_Curb_Stone_in_Nos__c == null)
                                oQvar.G_B_Quantity_Curb_Stone_in_Nos__c = mapOpp.get(oQvar.OpportunityId).G_B_Quantity_Curb_Stone_in_Nos__c;
                        }
                        
                        if(mapOpp.get(oQvar.OpportunityId).Estimated_Project_Tilefix_Qty_Bag__c != null && mapOpp.get(oQvar.OpportunityId).Business_Unit__c == GlobalConstants.Construction_BUSINESS_UNIT){                    //Added for SCF -102
                            if(oQvar.Estimated_Project_Tilefix_Qty_Bag__c == null)
                                oQvar.Estimated_Project_Tilefix_Qty_Bag__c = mapOpp.get(oQvar.OpportunityId).Estimated_Project_Tilefix_Qty_Bag__c;
                        }
                        
                        if(mapOpp.get(oQvar.OpportunityId).G_B_Quantity_Tilefix_Qty_Bags__c != null && mapOpp.get(oQvar.OpportunityId).Business_Unit__c == GlobalConstants.Construction_BUSINESS_UNIT){                    //Added for SCF -102
                            if(oQvar.G_B_Quantity_Tilefix_Qty_Bags__c == null)
                                oQvar.G_B_Quantity_Tilefix_Qty_Bags__c = mapOpp.get(oQvar.OpportunityId).G_B_Quantity_Tilefix_Qty_Bags__c;
                        }
                    }
                }
                
                if(mapOpp.get(oQvar.OpportunityId).Converted_Lead__c != null && mapOpp.get(oQvar.OpportunityId).Business_Unit__c == GlobalConstants.Construction_BUSINESS_UNIT){
                    oQvar.QuoteToName = opID_ContactName.get(oQvar.OpportunityId);                      
                }
                
                //End: Added by Siddhesh on 18/03/2022 :To Autopopulate Opportunity fields on Quote for Const B2B    
                
                if(oQVar.End_Customer__c== null && oQVar.Record_Type_Developer_Name__c == GlobalConstants.QUOTE_RECORDTYPE_SSG)
                    oQVar.End_Customer__c=mapOpp.get(oQVar.OpportunityId).End_Customer__c; //Modified by pankaj on 23 march 2023                        
                
                if(oQVar.SSG_Territory__c== null && oQVar.Record_Type_Developer_Name__c == GlobalConstants.QUOTE_RECORDTYPE_SSG)
                    oQVar.SSG_Territory__c=mapOpp.get(oQVar.OpportunityId).SSG_Territory__c;    
                
                //Populate the Custom Account Name field for Sold To/Ship To Address lookup filter  
                oQVar.Account_Name__c = mapOpp.get(oQVar.OpportunityId).AccountId;  
                oQVar.Area_Code__c = mapOpp.get(oQVar.OpportunityId).Area_Code__c;
                oQVar.Sales_Branch_Name__c = mapOpp.get(oQVar.OpportunityId).Sales_Branch_Name__c;
                oQVar.Currency__c = mapOpp.get(oQVar.OpportunityId).Currency__c;
                //oQVar.Branch__c = mapOpp.get(oQVar.OpportunityId).Sales_Branch_Name__c;
                ownerToSalesBranchMap.put(oQVar.Opportunity_Owner__c, mapOpp.get(oQVar.OpportunityId).Sales_Branch_Name__c);
                
                //Branch Champion & Service Addresses
                if(String.isNotBlank(mapOpp.get(oQVar.OpportunityId).Service_Branch_Name__c) 
                   && (branchRelationMap.get(mapOpp.get(oQVar.OpportunityId).Service_Branch_Name__c)<>NULL))
                {
                    //1. populate Service Address
                    oQVar.Service_Address__c = branchRelationMap.get(mapOpp.get(oQVar.OpportunityId).Service_Branch_Name__c).Service_Address__c;
                    //2. populate Branch Champion
                    if(champUserMap.containsKey(branchRelationMap.get(mapOpp.get(oQVar.OpportunityId).Service_Branch_Name__c).Champion_Code__c))
                        oQVar.Branch_Champion__c = champUserMap.get(branchRelationMap.get(mapOpp.get(oQVar.OpportunityId).Service_Branch_Name__c).Champion_Code__c);
                }
                
                //MHE Rentals Default for uptime required - 87%
                if(oQVar.Record_Type_Developer_Name__c == GlobalConstants.QUOTE_MHE_RENTALS_RECORDTYPE_APINAME
                   && (oQVar.Uptime__c == NULL))
                {
                    oQVar.Uptime__c = Double.ValueOf(System.Label.MHERentalUptimeDefault);
                }
            }
            
            // Added by Rohit Jadhav for PED on 6th july 2023
            if(oQVar.RecordTypeId == pedRecordTypeId){
                if(userMap.get(userInfo.getUserId()).Persona__c == GlobalConstants.PED_Head_Sales_T_Band){
                    oQVar.Level_1_Approver__c=userMap.get(userInfo.getUserId()).Id;
                }else if(userMap.get(userInfo.getUserId()).Persona__c == GlobalConstants.PED_Manager_P_Band || 
                         userMap.get(userInfo.getUserId()).Persona__c == GlobalConstants.PED_PED_Asst_Manager_O_Band)
                {
                    If(userMap.get(userInfo.getUserId()).Manager.persona__c == GlobalConstants.PED_Head_Sales_T_Band ){
                        oQVar.Level_1_Approver__c=userMap.get(userInfo.getUserId()).ManagerId;
                    }else if(userMap.get(userInfo.getUserId()).Manager.Manager.persona__c == GlobalConstants.PED_Head_Sales_T_Band){
                        oQVar.Level_1_Approver__c=userMap.get(userInfo.getUserId()).Manager.ManagerId;
                    }
                }
                oQVar.Quote_Type__c=mapOpp.get(oQVar.OpportunityId).RecordType.DeveloperName==GlobalConstants.PED_BQ_OPPORTUNITY_RT ? GlobalConstants.PED_BQ : GlobalConstants.PED_FIRM ;
                oQVar.Currency__c=mapOpp.get(oQVar.OpportunityId).Currency__c ;
                oQVar.Internal_Sales_Representative__c=mapOpp.get(oQVar.OpportunityId).Internal_Sales_Rep__c ;
                oQVar.Conversion_Rate__c=mapOpp.get(oQVar.OpportunityId).Conversion_Rate__c ;
                oQVar.Incoterm__c=mapOpp.get(oQVar.OpportunityId).Incoterm__c; 
            }
        }
        Map<Id, Boolean> userPersonaMap = SoldToPricebookUtility.getUserPersonaDetails(ownerToSalesBranchMap);
        for (Quote eachQuote : newQuotes) {
            if(!notApplicableRecordTypeIds.contains(eachQuote.RecordTypeId)) {
                if (eachQuote.Opportunity_Owner__c != null && userPersonaMap.containsKey(eachQuote.Opportunity_Owner__c)
                    && userPersonaMap.get(eachQuote.Opportunity_Owner__c)  ) {
                        //Added and condition to execute the code only if it is null
                        if(eachQuote.Transaction_Type__c == null && eachQuote.Record_Type_Developer_Name__c == GlobalConstants.QUOTE_RECORDTYPE_SSG){
                            eachQuote.Transaction_Type__c = GlobalConstants.ORDER_TYPE_PRIMARY;
                        } else if(eachQuote.Transaction_Type__c != GlobalConstants.ORDER_TYPE_SECONDARY && eachQuote.Opportunity_Owner__c != null && userPersonaMap.containsKey(eachQuote.Opportunity_Owner__c)
                                  && userPersonaMap.get(eachQuote.Opportunity_Owner__c) && eachQuote.Record_Type_Developer_Name__c != GlobalConstants.QUOTE_RECORDTYPE_SSG  && eachQuote.Record_Type_Developer_Name__c != GlobalConstants.QUOTE_RECORDTYPE_SSD) {
                                      eachQuote.Transaction_Type__c = GlobalConstants.ORDER_TYPE_PRIMARY;
                                  } 
                    } else {
                        //Added a condition to execute the code only if it is null
                        if (eachQuote.Transaction_Type__c == null  && eachQuote.Record_Type_Developer_Name__c != GlobalConstants.QUOTE_RECORDTYPE_SSD){
                            eachQuote.Transaction_Type__c = GlobalConstants.ORDER_TYPE_SECONDARY;
                           
                             
                        }
                    }
            } 
            //aDDED BY PANKAJ ON 14 MARCH for JIRA-SSEPB-35
            if(mapOpp.get(eachQuote.OpportunityId).Business_unit__c == GlobalConstants.SSG_BUSINESS_UNIT){
                if(String.isBlank(eachQuote.Regular_Key__c))
                    eachQuote.Regular_Key__c = mapOpp.get(eachQuote.OpportunityId).Regular_Key__c; 
                if(String.isBlank(eachQuote.Opportunity_Type__c))
                    eachQuote.Opportunity_Type__c = mapOpp.get(eachQuote.OpportunityId).Opportunity_Type__c;
                if(String.isBlank(eachQuote.SSG_Territory__c))
                    eachQuote.SSG_Territory__c = mapOpp.get(eachQuote.OpportunityId).SSG_Territory__c;
                if(String.isBlank(eachQuote.Dealer_Involved__c))
                    eachQuote.Dealer_Involved__c = mapOpp.get(eachQuote.OpportunityId).Dealer_Involved_Y_N__c;
                if(String.isBlank(eachQuote.Site_Location__c)) 
                    eachQuote.Site_Location__c = mapOpp.get(eachQuote.OpportunityId).City_Details__c;
                if(String.isBlank(eachQuote.Solution_Offering_Level_1__c)) 
                    eachQuote.Solution_Offering_Level_1__c = mapOpp.get(eachQuote.OpportunityId).Solution_Offering_Level_1__c;
                if(String.isBlank(eachQuote.Solution_Offering_Level_2__c)) 
                    eachQuote.Solution_Offering_Level_2__c = mapOpp.get(eachQuote.OpportunityId).Solution_Offering_Level_2__c;
                //Update Category Field
                if(eachQuote.Regular_Key__c == GlobalConstants.Regular_Category && (eachQuote.Opportunity_Type__c == GlobalConstants.Opportunity_type_Swift || eachQuote.Opportunity_Type__c == GlobalConstants.Opportunity_type_Non_Swift)){
                    eachQuote.Category__c = GlobalConstants.Regular_Category;
                }
                else if(eachQuote.Regular_Key__c == GlobalConstants.Key_Category && (eachQuote.Opportunity_Type__c == GlobalConstants.Opportunity_type_Swift || eachQuote.Opportunity_Type__c == GlobalConstants.Opportunity_type_Non_Swift)){
                    eachQuote.Category__c = GlobalConstants.Key_Category;
                }
                else if(eachQuote.Regular_Key__c == GlobalConstants.Regular_Category && eachQuote.Opportunity_Type__c == GlobalConstants.Opportunity_type_Service){
                    eachQuote.Category__c = GlobalConstants.Lcs_Category;
                }
                else if(eachQuote.Regular_Key__c == GlobalConstants.Key_Category && eachQuote.Opportunity_Type__c == GlobalConstants.Opportunity_type_Service){
                    eachQuote.Category__c = GlobalConstants.Key_Lcs_Category;
                }
            }//end by pankaj
        }
    }
    
    /*------------------------------------------------------------------------
Author:        Kishor Kumar
Company:       Salesforce
Description:   Method to check if loggedin User have edit access to locked 'Quote' record
Inputs:        list of updated Quotes
Test Class:    
History
13-04-2020      Kishor Kumar     Initial Release
----------------------------------------------------------------------------*/
    public map<Id, Boolean> checkLockedRecordAccess(map<Id, Quote> newQuotes, map<Id, Quote> oldQuotes){
        map<Id, Id> QuoteIdVsPARId = new map<Id, Id>();
        map<Id,boolean> lockedParIdVsAccessMap = new map<Id,boolean>();
        map<Id, Boolean> quoteVsAccessMap = new map<Id,boolean>();
        Set<Id> quotesTocheck = new Set<Id>();
        
        for(Id newQId : newQuotes.keySet()){
            if((newQuotes.get(newQId).Approval_Status__c == oldQuotes.get(newQId).Approval_Status__c ) 
               && (newQuotes.get(newQId).Approval_Status__c == GlobalConstants.Submitted_for_Approval)){
                   quotesTocheck.add(newQId);
               }
        }
        
        for(Quote quot : [Select Id, (Select Id FROM Pricing_approval_requests__r),
                          (Select Id from QuoteLineItems WHERE Approval_Status__c = :GlobalConstants.APPROVAL_REQUIRED_STATUS)
                          FROM Quote 
                          WHERE ID IN: newQuotes.keySet()]){
                              if (quotesTocheck.contains(quot.Id)) {
                                  QuoteIdVsPARId.put(quot.Id, quot.Pricing_approval_requests__r[0].Id);
                              }
                              if (!quot.QuoteLineItems.isEmpty()) {
                                  quoteLineApprovalStatusSet.add(quot.Id);
                              }
                          }
        
        //Fetch Locked PAR Ids
        if(!QuoteIdVsPARId.isEmpty()){
            lockedParIdVsAccessMap = Utility.recordLockCheck(QuoteIdVsPARId.values());
        }
        
        if(!lockedParIdVsAccessMap.isEmpty()){
            for(Id qId : QuoteIdVsPARId.keyset()){
                if(lockedParIdVsAccessMap.containsKey(QuoteIdVsPARId.get(qId))){
                    quoteVsAccessMap.put(qId, lockedParIdVsAccessMap.get(QuoteIdVsPARId.get(qId)));
                } else {
                    //if lockedParIdVsAccessMap doesn't contains so by default that user will have access to quote record
                    quoteVsAccessMap.put(qId, true);
                }
                
            }
        }
        
        return quoteVsAccessMap;
    }
    
    /*------------------------------------------------------------------------
Author:        Kishor Kumar
Company:       Salesforce
Description:   Method to update approval status of associated 'Quote' Record
Inputs:        list of updated Quotes
Test Class:    
History
08-04-2020      Kishor Kumar     Initial Release
----------------------------------------------------------------------------*/
    public void updateQuoteApprovalStatus(map<Id, Quote> newQuotes, map<Id, Quote> oldQuotes){
        
        set<Id> quoteRecordTypeIds = new set<Id>();
        set<String> quoteRtDevNames = new set<String>(System.label.Bypass_Auto_Quote_Approval_Status_Calc.split(','));  // Updated to ignore logic for SSG
        //Added by rohit jadhav to bypass for PED on 29th Aug 2023
        String pedRecordTypeId=Schema.SObjectType.Quote.RecordTypeInfosByName.get(GlobalConstants.PED_QUOTE_RT).RecordTypeId;
        
        //Fetch Record types from Utility Class
        Utility utilityVar = new Utility();
        map<String, Id> rtNameVsId =  utilityVar.fetchRecordTypes('Quote');
        
        //Fetch all the quote record accessible to users
        map<Id, Boolean> quoteVsAccessMap = checkLockedRecordAccess(newQuotes, oldQuotes);
        Id interio_B2B_Finished_Good_RecordTypeId;
        
        if(!rtNameVsId.isEmpty()){
            for(String rtDevName : rtNameVsId.keySet()){
                if(quoteRtDevNames.contains(rtDevName)){
                    quoteRecordTypeIds.add(rtNameVsId.get(rtDevName));
                    if(rtDevName==GlobalConstants.Interio_B2B_Finished_Good_RT)
                    {
                        interio_B2B_Finished_Good_RecordTypeId=rtNameVsId.get(rtDevName);
                    }
                }
            }
        }
        
        for(Quote qRec : newQuotes.values()){
        //Added by rohit jadhav to bypass for PED on 29th Aug 2023
        if(qRec.RecordTypeId!=pedRecordTypeId){    
            if(quoteVsAccessMap.isEmpty() || (quoteVsAccessMap.containsKey(qRec.Id) 
                                              && quoteVsAccessMap.get(qRec.Id)) 
               || !quoteVsAccessMap.containsKey(qRec.Id)){
                   if(!quoteRecordTypeIds.contains(qRec.RecordTypeId) && 
                      qRec.Submit_for_Approval_QLI_Count__c > 0 && 
                      qRec.Approval_Status__c == GlobalConstants.Approval_Not_Required){
                          qRec.Approval_Status__c = GlobalConstants.Approval_Required;
                      } else if( qRec.Submit_for_Approval_QLI_Count__c ==0 && !quoteRecordTypeIds.contains(qRec.RecordTypeId)
                                && (qRec.Approval_Status__c == GlobalConstants.Approval_Required)) {
                                    qRec.Approval_Status__c = GlobalConstants.Approval_Not_Required;
                                }
               } else if(quoteVsAccessMap.containsKey(qRec.Id) && !quoteVsAccessMap.get(qRec.Id)){
                   if(!GlobalConstants.SKIP_QUOTE_LOCK)
                   {
                         qRec.addError(GlobalConstants.RECORD_LOCK_ERROR_MSG);
                   }            
               }
            
            // Second level of check for quotes where customer discount is edited again
            // Joshna - added this as part of rentals & DE996
            // Added recordTypeId filter in if condition to skip for Interio_B2B_Finished_Good by rohit jadhav
            // Added else if condition for Locks_B2C_ISTD by rohit jadhav
            if (quoteLineApprovalStatusSet.contains(qRec.Id) && qRec.RecordTypeId!=interio_B2B_Finished_Good_RecordTypeId && qRec.Record_Type_Developer_Name__c!=GlobalConstants.RECORDTYPE_Locks_B2C_ISTD) {                
                qRec.Approval_Status__c = GlobalConstants.Approval_Required;
            }
            else if (quoteLineApprovalStatusSet.contains(qRec.Id) && qRec.Record_Type_Developer_Name__c==GlobalConstants.RECORDTYPE_Locks_B2C_ISTD && qRec.Approval_Status__c==GlobalConstants.Approval_Not_Required) {      
                   qRec.Approval_Status__c = GlobalConstants.Approval_Required;
            }
        }        
        }
    }
    
    
    /*------------------------------------------------------------------------
Author:        Kishor Kumar
Company:       Salesforce
Description:   Method to update approval status of associated 'Quote Line Item' Records
Inputs:        map of updated Quotes
Test Class:    
History
08-04-2020      Kishor Kumar     Initial Release
----------------------------------------------------------------------------*/
    public void updateQLIsApprovalStatus(map<Id, Quote> newQuotes, map<Id, Quote> oldQuotes){
        
        list<QuoteLineItem> quoteLineItemsToSubmitForApproval = new list<QuoteLineItem>();
        list<QuoteLineItem> quoteLineItemsToApproveOrReject = new list<QuoteLineItem>();
        
        map<Id, String> quoteIdVsApprovalStatus = new map<Id, String>();
        map<Id, list<QuoteLineItem>> quoteIdVsQLIs = new map<Id, list<QuoteLineItem>>();
        
        set<Id> quoteRecordTypeIds = new set<Id>();
        //set<String> quoteRtDevNames = new set<String>{'Interio_B2C_VFD','Interio_Script', 'Interio_Kitchen'}; 
        set<String> quoteRtDevNames =  GlobalConstants.QUOTE_RT_FOR_APPROVAL;
        
        //set<String> qliApprovalStatus = new set<String>{GlobalConstants.Submitted_for_Approval, GlobalConstants.Approval_Required}; 
        
        //Fetch Record types from Utility Class
        Utility utilityVar = new Utility();
        map<String, Id> rtNameVsId =  utilityVar.fetchRecordTypes('Quote');
        
        //Fetch all the quote record accessible to users
        map<Id, Boolean> quoteVsAccessMap = checkLockedRecordAccess(newQuotes, oldQuotes);
        Id interio_B2B_Finished_Good_RecordTypeId;
        
        if(!rtNameVsId.isEmpty()){
            for(String rtDevName : rtNameVsId.keySet()){
                if(quoteRtDevNames.contains(rtDevName)){
                    System.debug('rtDevName  :'+rtDevName);
                    System.debug('rtNameVsId.get(rtDevName) :'+rtNameVsId.get(rtDevName));
                    quoteRecordTypeIds.add(rtNameVsId.get(rtDevName));
                    if(rtDevName==GlobalConstants.Interio_B2B_Finished_Good_RT)
                    {
                        interio_B2B_Finished_Good_RecordTypeId=rtNameVsId.get(rtDevName);
                    }
                }
            }
        }
        
        for(Id qId : newQuotes.keyset()){
            if((quoteVsAccessMap.isEmpty() || (quoteVsAccessMap.containsKey(qId) 
                                              && quoteVsAccessMap.get(qId)) 
               || !quoteVsAccessMap.containsKey(qId))
                && (newQuotes.get(qId).RecordTypeId!=interio_B2B_Finished_Good_RecordTypeId)){  
                   System.debug('oldQuotes.get(qId).Approval_Status__c :'+oldQuotes.get(qId).Approval_Status__c);
                   System.debug('newQuotes.get(qId).Approval_Status__c'+newQuotes.get(qId).Approval_Status__c);
                   System.debug('quoteRecordTypeIds.contains(newQuotes.get(qId).RecordTypeId) :'+quoteRecordTypeIds.contains(newQuotes.get(qId).RecordTypeId));
                   if(oldQuotes.get(qId).Approval_Status__c !=  newQuotes.get(qId).Approval_Status__c  && 
                      quoteRecordTypeIds.contains(newQuotes.get(qId).RecordTypeId) && 
                      (newQuotes.get(qId).Approval_Status__c == GlobalConstants.Submitted_for_Approval || 
                       newQuotes.get(qId).Approval_Status__c == GlobalConstants.Approved || 
                       newQuotes.get(qId).Approval_Status__c == GlobalConstants.Rejected) ||
                      (newQuotes.get(qId).Approval_Status__c == GlobalConstants.APPROVAL_REQUIRED_STATUS && newQuotes.get(qId).Record_Type_Developer_Name__c == 'Appliances') //Added by Shreela on 8th September 2022 for SAEPB - 44 Appliance B2B
                     ){
                         quoteIdVsApprovalStatus.put(qId, newQuotes.get(qId).Approval_Status__c);
                     }
               } else if(quoteVsAccessMap.containsKey(qId) && !quoteVsAccessMap.get(qId)){
                   if(!GlobalConstants.SKIP_QUOTE_LOCK)
                   {
                        newQuotes.get(qId).addError(GlobalConstants.RECORD_LOCK_ERROR_MSG);
                   }
               }
        }
        
        if(!quoteIdVsApprovalStatus.isEmpty()){
            for(QuoteLineItem qli : [Select Id, Approval_Status__c, QuoteId,Quote_Record_Type__c  //Added Quote_Record_Type__c by Shreela on 7th September 2022 for SAEPB - 44 Appliance B2B
                                     FROM QuoteLineItem 
                                     WHERE QuoteId IN: quoteIdVsApprovalStatus.keyset() 
                                     /*AND Approval_Status__c IN : qliApprovalStatus*/]){
                                         
                                         if(!quoteIdVsQLIs.isEmpty() && quoteIdVsQLIs.containsKey(qli.QuoteId)){
                                             quoteIdVsQLIs.get(qli.QuoteId).add(qli);                            
                                         } else{
                                             quoteIdVsQLIs.put(qli.QuoteId, new list<QuoteLineItem>{qli});
                                         }
                                     }
        }
        
        
        if(!quoteIdVsApprovalStatus.isEmpty() && !quoteIdVsQLIs.isEmpty()){
            for(Id quoteId : quoteIdVsApprovalStatus.keyset()){
                if(quoteIdVsQLIs.containsKey(quoteId) && quoteIdVsQLIs.get(quoteId).size() > 0){
                    //Quote with 'Submitted for Approval' status
                    if(quoteIdVsApprovalStatus.get(quoteId) == GlobalConstants.Submitted_for_Approval){
                        //Change QLI status to 'Submitted for Approval' from 'Approval Required'
                        for(QuoteLineItem submittedQLI : quoteIdVsQLIs.get(quoteId)){
                            if(submittedQLI.Approval_Status__c == GlobalConstants.Approval_Required 
                               || submittedQLI.Approval_Status__c == GlobalConstants.Rejected
                               || submittedQLI.Approval_Status__c == GlobalConstants.Approved
                              ){
                                  QuoteLineItem arQLI = new QuoteLineItem();
                                  arQLI.Id = submittedQLI.Id;
                                  arQLI.Approval_Status__c = GlobalConstants.Submitted_for_Approval;
                                  quoteLineItemsToSubmitForApproval.add(arQLI);
                              } 
                            else {
                                //Just Lock the record without any update
                                quoteLineItemsToSubmitForApproval.add(submittedQLI);
                            }
                        }
                        
                    } else { //Approved or Rejected quotes
                        //Change QLI status to 'Approved or Rejected' from 'Submitted for Approval'
                        for(QuoteLineItem submittedQLI : quoteIdVsQLIs.get(quoteId)){
                            System.debug('submittedQLI.Approval_Status__c :'+submittedQLI.Approval_Status__c);
                            if(submittedQLI.Approval_Status__c == GlobalConstants.Submitted_for_Approval
                               //&& submittedQLI.Quote_Record_Type__c != GlobalConstants.QUOTE_RECORDTYPE_APPLIANCE
                              ){
                                  QuoteLineItem subQLI = new QuoteLineItem();
                                  subQLI.Id = submittedQLI.Id;
                                  subQLI.Approval_Status__c = quoteIdVsApprovalStatus.get(quoteId);
                                  quoteLineItemsToApproveOrReject.add(subQLI);
                              } 
                            else {
                                //Just unlock the record without any update
                                quoteLineItemsToApproveOrReject.add(submittedQLI);
                            }
                        }
                    }
                }
            }
        }
        
        //update Quote Line Items Approval status with record Lock/Unlock 
        try{
            //Update Approval Status to 'Submitted for Approval' and Lock the record for being edited
            if(quoteLineItemsToSubmitForApproval.size() > 0){
                GlobalConstants.ALLOW_TRIGGER_TO_EXECUTE = false;
                //update quoteLineItemsToSubmitForApproval;
                Database.SaveResult[] srList = Database.update(quoteLineItemsToSubmitForApproval, true);
                
            }
            
            //Update Approval Status to 'Approved/Rejected' and Lock the record for editing
            if(quoteLineItemsToApproveOrReject.size() > 0){
                GlobalConstants.ALLOW_TRIGGER_TO_EXECUTE = false;
                update quoteLineItemsToApproveOrReject;
                
                //unLock records
                //List<Approval.UnlockResult> urList = Approval.unlock(quoteLineItemsToApproveOrReject);
            }
        } catch(Exception ex){
            system.debug('==Exception occurred in QLI updates. Error message: '+ex.getMessage());
        }
        
    }
    
    public void populateCustomerGSTN(List<Quote> quotes,Map<Id,Quote> oldQuotes){
        List<Quote> applicableQuotes=new List<Quote>(); 
        Set<Id> recordTypesApplicable=new Set<Id>();
        Map<Id,List<Tax_Number__c>> soldToBpIdVsTaxRecords=new Map<Id,List<Tax_Number__c>>();
        Set<Id> soldToBPIds=new Set<Id>(); 
        Set<Id> soldToAddressIds=new Set<Id>();
        Map<Id,Address_by_BP__c> idVsSoldToAddress=new Map<Id,Address_by_BP__c>();
        recordTypesApplicable.add(Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get(GlobalConstants.QUOTE_RECORDTYPE_INTERIO_B2C_VFD).getRecordTypeId());
        recordTypesApplicable.add(Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get(GlobalConstants.QUOTE_RECORDTYPE_INTERIO_KITCHEN).getRecordTypeId());
        recordTypesApplicable.add(Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get(GlobalConstants.QUOTE_RECORDTYPE_INTERIO_SCRIPT).getRecordTypeId());
        if(oldQuotes==null)
            for(Quote q:quotes){
                if(recordTypesApplicable.contains(q.RecordTypeId))
                    applicableQuotes=quotes;
            }
        else{
            for(Quote quote:quotes){
                if(recordTypesApplicable.contains(quote.RecordTypeId)  &&
                   (quote.Sold_to_Address__c!=oldQuotes.get(quote.Id).Sold_to_Address__c ||
                    quote.Sold_To_Business_Partner__c!=oldQuotes.get(quote.Id).Sold_To_Business_Partner__c)){
                        applicableQuotes.add(quote);
                    }
            }
        }
        if(applicableQuotes.size()>0){
            for(Quote q:applicableQuotes){
                if(q.Sold_To_Business_Partner__c!=null && q.Sold_to_Address__c!=null){
                    soldToBPIds.add(q.Sold_To_Business_Partner__c);
                    soldToAddressIds.add(q.Sold_to_Address__c);
                }
            }
            for(Tax_Number__c taxRec:[Select Category__c,Address_Code__c,Tax_Number__c,Business_Partner__c From Tax_Number__c
                                      Where Category__c='GSTIN' And Business_Partner__c In :soldToBPIds]){
                                          if(!soldToBpIdVsTaxRecords.containsKey(taxRec.Business_Partner__c))
                                              soldToBpIdVsTaxRecords.put(taxRec.Business_Partner__c,new List<Tax_Number__c>{taxRec});
                                          else
                                              soldToBpIdVsTaxRecords.get(taxRec.Business_Partner__c).add(taxRec);
                                      }
            idVsSoldToAddress = new Map<Id,Address_by_BP__c>([Select Id,Address_Code__c From Address_by_BP__c Where Id In :soldToAddressIds]);
            
            for(Quote q:applicableQuotes){
                if(q.Sold_To_Business_Partner__c!=null && q.Sold_to_Address__c!=null && idVsSoldToAddress.containsKey(q.Sold_to_Address__c) && soldToBpIdVsTaxRecords.containsKey(q.Sold_To_Business_Partner__c)){
                    for(Tax_Number__c taxRec:soldToBpIdVsTaxRecords.get(q.Sold_To_Business_Partner__c)){
                        if(idVsSoldToAddress.get(q.Sold_to_Address__c).Address_Code__c==taxRec.Address_Code__c){
                            q.Customer_GSTN__c=taxRec.Tax_Number__c;
                            break;
                        }
                        else
                            q.Customer_GSTN__c=null;
                    }
                }
                else
                    q.Customer_GSTN__c=null;
            }
            
        }
        
    }
    
    /*------------------------------------------------------------------------
Author:        Kishor
Company:       Salesforce
Description:   Method to auto approve Quote for 'SFS' category of SSG
Inputs:        list<Quote>, map<Id, Quote>

//Updated on 2-11-2020 Shankar Sahu
----------------------------------------------------------------------------*/
    public void validateAndAutoapproveForSSG_SFS(list<Quote> newItems, map<Id, Quote> oldItems){
        set<Id> quoteIds = new set<Id>();
        map<Id, Quote> idVsQueriedQuotes = new map<Id, Quote>();
        map<String, Integer> personaVsHierarchyLevel = new map<String, Integer>();
        Double SSG_SFS_min_discount = Double.valueof(System.Label.SSG_SFS_min_discount);  
        Double SSG_SFS_max_discount = Double.valueof(System.Label.SSG_SFS_max_discount); 
        
        map<Id, user> userMap = new map<Id, user>([SELECT Id, Persona__c FROM User 
                                                   WHERE Id =: userInfo.getUserId() 
                                                   AND Persona__c != '']);
        //Create PersonaVsHierarchy data for SSG :: SFS categories
        for(Approval_Submitter_Hierarchy_mapping__mdt sHierarchy : [SELECT Quote_Business_Unit__c, Submitter_Level__c, Quote_Submitter_Persona__c, Category__c  
                                                                    FROM Approval_Submitter_Hierarchy_mapping__mdt 
                                                                    WHERE Quote_Business_Unit__c =: GlobalConstants.QUOTE_RECORDTYPE_SSG
                                                                    AND Category__c = 'SFS']){
                                                                        
                                                                        if(String.isNotEmpty(sHierarchy.Quote_Submitter_Persona__c)){
                                                                            personaVsHierarchyLevel.put(sHierarchy.Quote_Submitter_Persona__c.toUpperCase(), Integer.valueOf(sHierarchy.Submitter_Level__c));
                                                                        }                                                            
                                                                    } 
        
        
        for(Quote newQuote : newItems){
            if(newQuote.Requested_Customer_discount_max__c > 0 &&
               newQuote.Record_Type_Developer_Name__c == GlobalConstants.QUOTE_RECORDTYPE_SSG &&
               (newQuote.Category__c == 'SFS Imported' || newQuote.Category__c == 'SFS In-house') && 
               (oldItems == null || (!oldItems.isEmpty() && oldItems.containsKey(newQuote.Id) 
                                     && newQuote.CreatedById == userInfo.getUserId() &&  
                                     (oldItems.get(newQuote.Id).Category__c != newQuote.Category__c || 
                                      oldItems.get(newQuote.Id).Requested_Customer_discount_max__c != newQuote.Requested_Customer_discount_max__c))) && 
               !personaVsHierarchyLevel.isEmpty() &&
               userMap.containsKey(userInfo.getUserId()) &&
               personaVsHierarchyLevel.containsKey(userMap.get(userInfo.getUserId()).Persona__c.toUpperCase())){
                   
                   Double requestedDiscount  = Double.valueof(newQuote.Requested_Customer_discount_max__c);
                   
                   if(requestedDiscount <= SSG_SFS_min_discount ){
                       newQuote.Approval_Status__c = GlobalConstants.APPROVED_STATUS;
                       newQuote.Is_autoapproved__c = true;
                   }  else if(requestedDiscount > SSG_SFS_min_discount && requestedDiscount <= SSG_SFS_max_discount 
                              && personaVsHierarchyLevel.get(userMap.get(userInfo.getUserId()).Persona__c.toUpperCase())> 1){
                                  newQuote.Approval_Status__c = GlobalConstants.APPROVED_STATUS;
                                  newQuote.Is_autoapproved__c = true;
                              } else if(requestedDiscount > SSG_SFS_max_discount 
                                        && personaVsHierarchyLevel.get(userMap.get(userInfo.getUserId()).Persona__c.toUpperCase())> 2){
                                            newQuote.Approval_Status__c = GlobalConstants.APPROVED_STATUS;
                                            newQuote.Is_autoapproved__c = true;
                                        }        
               } 
        }
    }
    
    /*------------------------------------------------------------------------
Author:        Kishor
Company:       Salesforce
Description:   Method to auto approve Quote for 'Regular/Key' category of SSG
Inputs:        list<Quote>, map<Id, Quote>
----------------------------------------------------------------------------*/
    public void validateAndAutoapproveForSSG_Regular_Key(list<Quote> newItems, map<Id, Quote> oldItems){
        /*
set<Id> quoteIds = new set<Id>();
map<Id, Quote> idVsQueriedQuotes = new map<Id, Quote>();
map<String, Integer> personaVsHierarchyLevel = new map<String, Integer>();

map<Id, user> userMap = new map<Id, user>([SELECT Id, Persona__c FROM User 
WHERE Id =: userInfo.getUserId() 
AND Persona__c != '']);

//Create PersonaVsHierarchy data for SSG :: Regular/Key categories
for(Approval_Submitter_Hierarchy_mapping__mdt sHierarchy : [SELECT Quote_Business_Unit__c, Submitter_Level__c, Quote_Submitter_Persona__c, Category__c  
FROM Approval_Submitter_Hierarchy_mapping__mdt 
WHERE Quote_Business_Unit__c =: GlobalConstants.QUOTE_RECORDTYPE_SSG
AND Category__c = 'Regular/Key']){

if(String.isNotEmpty(sHierarchy.Quote_Submitter_Persona__c)){
personaVsHierarchyLevel.put(sHierarchy.Quote_Submitter_Persona__c.toUpperCase(), Integer.valueOf(sHierarchy.Submitter_Level__c));
}                                                            
} 

for(Quote newQuote : newItems){
if(
//Updated on 2-11-2020 Shankar Sahu 
//newQuote.Quote_Discount__c > 0 &&
newQuote.Requested_Customer_discount_max__c > 0 &&
newQuote.Record_Type_Developer_Name__c == GlobalConstants.QUOTE_RECORDTYPE_SSG &&
//Shankar Sahu added categories for otrs #30315383
(newQuote.Category__c == 'Regular' || newQuote.Category__c == 'Key'
|| newQuote.Category__c == 'Consulting'  || newQuote.Category__c == 'Life Cycle Services' || newQuote.Category__c == 'Swift' || newQuote.Category__c == 'Storage 2.0' ) && 
(oldItems == null || (!oldItems.isEmpty() && oldItems.containsKey(newQuote.Id) && 
newQuote.CreatedById == userInfo.getUserId() &&                 
(oldItems.get(newQuote.Id).Category__c != newQuote.Category__c || 
oldItems.get(newQuote.Id).Requested_Customer_discount_max__c != newQuote.Requested_Customer_discount_max__c))) && 
!personaVsHierarchyLevel.isEmpty() && userMap.containsKey(userInfo.getUserId()) &&
personaVsHierarchyLevel.containsKey(userMap.get(userInfo.getUserId()).Persona__c.toUpperCase())){

Double requestedDiscount  = Double.valueof(newQuote.Requested_Customer_discount_max__c);
//Auto-approve till 15% 
if(requestedDiscount <= 15  && newQuote.Category__c=='Swift'){
newQuote.Approval_Status__c = GlobalConstants.APPROVED_STATUS;
newQuote.Is_autoapproved__c = true; 
} else if(requestedDiscount > 15 && requestedDiscount <= 20 && 
personaVsHierarchyLevel.get(userMap.get(userInfo.getUserId()).Persona__c.toUpperCase())> 1 ){
//Auto-approve from 15 to 20% for Territory sales manager or above persona
newQuote.Approval_Status__c = GlobalConstants.APPROVED_STATUS;
newQuote.Is_autoapproved__c = true;  
} else if(requestedDiscount > 20 && requestedDiscount <= 30 && 
personaVsHierarchyLevel.get(userMap.get(userInfo.getUserId()).Persona__c.toUpperCase())> 2 ){
//Auto-approve from 20 to 30% for Regional sales manager or above persona
newQuote.Approval_Status__c = GlobalConstants.APPROVED_STATUS;
newQuote.Is_autoapproved__c = true;  
} else if(requestedDiscount > 30 && requestedDiscount <= 40 && 
personaVsHierarchyLevel.get(userMap.get(userInfo.getUserId()).Persona__c.toUpperCase())> 4 ){
//Auto-approve from 30 to 40% for National sales manager or above persona
newQuote.Approval_Status__c = GlobalConstants.APPROVED_STATUS;
newQuote.Is_autoapproved__c = true;  
} else if(requestedDiscount > 40 && 
personaVsHierarchyLevel.get(userMap.get(userInfo.getUserId()).Persona__c.toUpperCase())> 6 ){
//Auto-approve greater than 40% for sales and marketing head or above persona
newQuote.Approval_Status__c = GlobalConstants.APPROVED_STATUS;
newQuote.Is_autoapproved__c = true;  
}   
}
}
*/
    }
    /*------------------------------------------------------------------------
Author:        Kishor
Company:       Salesforce
Description:   Method to update PAR on autoapproval of Quote for certain scenario
Inputs:        Map<Id, Quote>, Map<Id,Quote> 
----------------------------------------------------------------------------*/
    public void updatePARForAutoapprovedQuotes(Map<Id, Quote> newItems){
        set<Id> quoteIds = new set<Id>();
        map<Id, Quote> idVsQueriedQuotes = new map<Id, Quote>();
        list<Pricing_approval_request__c> pricingRecordsToUpdate  = new list<Pricing_approval_request__c>();
        
        for(Id newQuoteId : newItems.Keyset()){ 
            if(newItems.get(newQuoteId).Record_Type_Developer_Name__c == GlobalConstants.QUOTE_RECORDTYPE_SSG 
               && (newItems.get(newQuoteId).Category__c == 'SFS Imported' || newItems.get(newQuoteId).Category__c == 'SFS In-house' ||
                   newItems.get(newQuoteId).Category__c == 'Regular' || newItems.get(newQuoteId).Category__c == 'Key')
               && newItems.get(newQuoteId).Is_autoapproved__c && newItems.get(newQuoteId).Approval_Status__c == GlobalConstants.APPROVED_STATUS){
                   quoteIds.add(newQuoteId);
               } 
        }
        
        if(quoteIds.size() > 0){
            for(Id qId : quoteIds){
                //Update PAR record approval status and Auto-approved flag
                Pricing_approval_request__c par = new Pricing_approval_request__c();
                if (Schema.sObjectType.Pricing_approval_request__c.fields.Id.isUpdateable()) { 
                par.Id =  newItems.get(qId).Pricing_approval_request__c;
                   }
                if (Schema.sObjectType.Pricing_approval_request__c.fields.Is_autoapproved__c.isUpdateable() && Schema.sObjectType.Pricing_approval_request__c.fields.Approval_Status__c .isUpdateable()){ 
                par.Is_autoapproved__c = true;
                par.Approval_Status__c = GlobalConstants.APPROVED_STATUS;
                  }
                
                pricingRecordsToUpdate.add(par);        
            } 
        }
        if (Schema.sObjectType.Pricing_approval_request__c.fields.Approval_Status__c.isUpdateable()){ 
        if(pricingRecordsToUpdate.size() > 0){
            try{
                update pricingRecordsToUpdate;
            }catch(Exception ex){
                Logger.logError('QuoteRecordProcessor', 'updatePARForAutoapprovedQuotes', '', ex);
            } 
        }
    }
 }
    public Map<Id, Opportunity> getOpportunityMap(Set<Id> oppIds) {
        opportunityRecordMap = new Map<Id, Opportunity>([Select Id, SyncedQuoteId, RecordTypeId, Business_Unit__c, WarehouseCode__c, 
                                                         //Added by Praful - 22-Feb-2021
                                                         Duration_Unit__c, Duration__c, Contract_Start_Date__c, Contract_End_Date__c
                                                         From Opportunity Where Id IN: oppIds]);
        return opportunityRecordMap;
    }
    /*------------------------------------------------------------------------
Author:        Kartik Shetty
Company:       Salesforce
Description:   Method to copy over associated opportunity warehouse to quote.
Inputs:        List<Quote> quoteRecords
----------------------------------------------------------------------------*/
    public void populateQuoteWarehouses_BasedOnOpportunity(List<Quote> quoteRecords) {
        Set<Id> oppIds = new Set<Id>();
        for(Quote quoteRecord : quoteRecords) {
            oppIds.add(quoteRecord.OpportunityId);
        }
        Map<Id, Opportunity> oppRecordMap = getOpportunityMap(oppIds);        
        for(Quote quoteRecord : quoteRecords) {
            Opportunity oppRecord = new Opportunity();
            oppRecord = oppRecordMap.get(quoteRecord.OpportunityId);
            //Added RecordType Check By Rohit Jadhav to bypass the functionality for PED - 12 July 2023            
            if(quoteRecord.Record_Type_Developer_Name__c != GlobalConstants.PED_QUOTE_RT && quoteRecord.WarehouseCode__c == null && oppRecord.WarehouseCode__c != null) {
                quoteRecord.WarehouseCode__c = oppRecord.WarehouseCode__c;
            }
        }
    }
    /*------------------------------------------------------------------------
Author:        Kartik Shetty
Company:       Salesforce
Description:   Method to prepopulate warehouse lookup field on the quote record.
Inputs:        List<Quote> quoteRecords
----------------------------------------------------------------------------*/
    public void populateQuoteWarehouse(List<Quote> quoteRecords) {
        List<Quote> quoteWarehousesToDefault = new List<Quote>();
        for(Quote quoteRecord : quoteRecords) {
            //Added RecordType Check By Rohit Jadhav to bypass the functionality for PED - 12 July 2023
            if(quoteRecord.Record_Type_Developer_Name__c != GlobalConstants.PED_QUOTE_RT && quoteRecord.WarehouseCode__c == null) {
                quoteWarehousesToDefault.add(quoteRecord);
            }
        }
        if(quoteWarehousesToDefault.size() > 0) {
            (new InventoryUtilityController()).defaultApplianceAndNormalQuoteWarehouse(quoteWarehousesToDefault);
        }
    }
    /*------------------------------------------------------------------------
Author:        Kartik Shetty
Company:       Salesforce
Description:   Method to validate whether the correct warehouse record is being populated on the quote records.
Inputs:        Map<Id, Quote> newRecordMap, List<Quote> oldRecords
----------------------------------------------------------------------------*/
    public void validateQuoteWarehouses(Map<Id, Quote> newRecordMap, List<Quote> oldRecords) {
        InventoryUtilityController inventoryUtilityControllerObj = new InventoryUtilityController();
        if(oldRecords.size() == 0) {
            inventoryUtilityControllerObj.validateApplianceAndNormalQuoteWarehouses(newRecordMap.values());
        } else {
            List<Quote> quoteWarehousesToValidate = new List<Quote>();
            for(Quote oldQuoteRecord : oldRecords) {
                Quote newQuoteRecord = newRecordMap.get(oldQuoteRecord.Id);
               
            	//Added RecordType Check By Rohit Jadhav to bypass the functionality for PED - 12 July 2023
            	if(newQuoteRecord.Record_Type_Developer_Name__c != GlobalConstants.PED_QUOTE_RT && newQuoteRecord.WarehouseCode__c != null && oldQuoteRecord.WarehouseCode__c != newQuoteRecord.WarehouseCode__c) {
                    quoteWarehousesToValidate.add(newQuoteRecord);
                }
            }
            
            if(quoteWarehousesToValidate.size() > 0) {
                inventoryUtilityControllerObj.validateApplianceAndNormalQuoteWarehouses(quoteWarehousesToValidate);
            }
        }
    }
    /*------------------------------------------------------------------------
Author:        Kartik Shetty
Company:       Salesforce
Description:   Method to update the warehouse lookup of child records if parent record is updated.
Inputs:        Map<Id, Quote> newRecordMap, List<Quote> oldRecords
----------------------------------------------------------------------------*/
    public void updateQLIWarehouses(Map<Id, Quote> newRecordMap, List<Quote> oldRecords) {
        // Create a set of quoteIds which will be used to query quote line items.
        Set<Id> quoteIds = new Set<Id>();
        Set<Id> quoteIdsToUpdateDuration = new Set<Id>();
        for(Quote oldQuoteRecord : oldRecords) {
            Quote newQuoteRecord =  newRecordMap.get(oldQuoteRecord.Id);
            if(oldQuoteRecord.WarehouseCode__c != newQuoteRecord.WarehouseCode__c) {
                quoteIds.add(newQuoteRecord.Id);
            }
            if(oldQuoteRecord.Duration_Unit__c != newQuoteRecord.Duration_Unit__c || oldQuoteRecord.Duration__c != newQuoteRecord.Duration__c
               || oldQuoteRecord.Contract_Start_Date__c != newQuoteRecord.Contract_Start_Date__c){
                   quoteIdsToUpdateDuration.add(newQuoteRecord.Id);
               }
        }
        
        // Get quote line items and iterate over them to update their warehouse lookup values to that of their respective quotes.
        List<QuoteLineItem> quoteLineItems = new List<QuoteLineItem>();
        for(QuoteLineItem quoteLineItem : [Select Id, QuoteId, Warehouse__c, Duration_Unit__c, Duration__c, Contract_Start_Date__c, Contract_End_Date__c
                                           FROM QuoteLineItem WHERE QuoteId IN :quoteIds OR QuoteId IN :quoteIdsToUpdateDuration ]) {
                                               
                                               Boolean isQLIChanged = false;
                                               
                                               if(quoteIds.contains(quoteLineItem.QuoteId)){
                                                   quoteLineItem.Warehouse__c = newRecordMap.get(quoteLineItem.QuoteId).WarehouseCode__c;
                                                   isQLIChanged = true;
                                               }
                                               if(quoteIdsToUpdateDuration.contains(quoteLineItem.QuoteId)){
                                                   quoteLineItem.Duration_Unit__c=newRecordMap.get(quoteLineItem.QuoteId).Duration_Unit__c;
                                                   quoteLineItem.Duration__c=newRecordMap.get(quoteLineItem.QuoteId).Duration__c;
                                                   quoteLineItem.Contract_Start_Date__C=newRecordMap.get(quoteLineItem.QuoteId).Contract_Start_Date__C;
                                                   quoteLineItem.Contract_End_Date__C=newRecordMap.get(quoteLineItem.QuoteId).Contract_End_Date__C;
                                                   isQLIChanged = true;
                                               }
                                               if(isQLIChanged)
                                                   quoteLineItems.add(quoteLineItem);
                                           }
        
        if(quoteLineItems.size() > 0) {
            update quoteLineItems;
        }
    }
    /*------------------------------------------------------------------------
Author:        Abhishek
Company:       Salesforce
Description:   Validate commission % when entered or edited
Inputs:        List<Quote>
----------------------------------------------------------------------------*/
    public void validateCommissionWhenUpdated(Map<Id,Quote> newQuotes,Map<Id,Quote> oldQuotes) {
        Map<String, Schema.RecordTypeInfo> quoteREcordTypeMap = Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName();
        Set<Id> recordTypeIds = new Set<Id>();
        recordTypeIds.add(quoteREcordTypeMap.get('MHE_Contracts').getRecordTypeId());
        recordTypeIds.add(quoteREcordTypeMap.get('MHE_Equipments').getRecordTypeId());
        recordTypeIds.add(quoteREcordTypeMap.get('MHE_Parts').getRecordTypeId());
        recordTypeIds.add(quoteREcordTypeMap.get('MHE_Rental').getRecordTypeId());
        List<Quote> quotesToValidate = new List<Quote>();
        for(Quote quote : newQuotes.values()) {
            if(recordTypeIds.contains(quote.RecordTypeId)) {
                if((quote.Commission__c != (oldQuotes.get(quote.Id).Commission__c) && quote.Commission__c != NULL) 
                   || (quote.SCC_Activities__c != (oldQuotes.get(quote.Id).SCC_Activities__c))) {
                       quotesToValidate.add(quote);
                   }
            }
            
        }
        if(quotesToValidate.size() > 0) {
            validateCommissionPercent(quotesToValidate);
        }
    }
    public void validateCommissionWhenInserted(List<Quote> newQuotes) {
        Map<String, Schema.RecordTypeInfo> quoteREcordTypeMap = Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName();
        Set<Id> recordTypeIds = new Set<Id>();
        recordTypeIds.add(quoteREcordTypeMap.get('MHE_Contracts').getRecordTypeId());
        recordTypeIds.add(quoteREcordTypeMap.get('MHE_Equipments').getRecordTypeId());
        recordTypeIds.add(quoteREcordTypeMap.get('MHE_Parts').getRecordTypeId());
        recordTypeIds.add(quoteREcordTypeMap.get('MHE_Rental').getRecordTypeId());
        List<Quote> quotesToValidate = new List<Quote>();
        for(Quote quote : newQuotes) {
            if(recordTypeIds.contains(quote.RecordTypeId)) {
                quotesToValidate.add(quote);
            }
            
        }
        if(quotesToValidate.size() > 0) {
            validateCommissionPercent(quotesToValidate);
        }
    }
    
    public void validateCommissionPercent(List<Quote> newItems) {
        List<Application_Settings__mdt> applicationSettings = [SELECT Id,DeveloperName,Value__c FROM Application_Settings__mdt WHERE DeveloperName LIKE 'CommPerOnQuote%'];
        for(Quote updatedQuote : newItems) {
            if(updatedQuote.Commission__c != NULL) {
                if(updatedQuote.SCC_Activities__c != NULL) {
                    string sccActivitiesString = updatedQuote.SCC_Activities__c;
                    List<string> sccActivities = sccActivitiesString.split(';');
                    Decimal maxAllowedCommissionPercent = 0;
                    Decimal minAllowedCommissionPercent = 0;
                    integer lowerLimitForThisRecord = null;
                    Map<integer,Decimal> upperLimitVsValue = new Map<integer,Decimal>();
                    
                    for(Application_Settings__mdt setting : applicationSettings){
                        string recordName = setting.DeveloperName;
                        List<string> stringWithLimits = recordName.split('_');
                        integer lowerLimit = Integer.valueOf(stringWithLimits[1]);
                        integer upperLimit = Integer.valueOf(stringWithLimits[2]);
                        upperLimitVsValue.put(upperLimit,Decimal.valueOf(setting.Value__c));
                        if(lowerLimit <= sccActivities.size() && sccActivities.size() <=  upperLimit) {
                            maxAllowedCommissionPercent = Decimal.valueOf(setting.Value__c);
                            lowerLimitForThisRecord = lowerLimit - 1;
                        }
                    }
                    if(lowerLimitForThisRecord != NULL && upperLimitVsValue.containsKey(lowerLimitForThisRecord)) {
                        minAllowedCommissionPercent = upperLimitVsValue.get(lowerLimitForThisRecord);
                    }
                    if(maxAllowedCommissionPercent == 0){
                        updatedQuote.addError(System.Label.InvalidCommissionPercentOnQuoteErrorNotEnoughActivities);
                    }else if(updatedQuote.Commission__c > maxAllowedCommissionPercent) {
                        updatedQuote.addError(System.Label.InvalidCommissionPercentOnQuoteError +' '+ maxAllowedCommissionPercent);
                    } else if(updatedQuote.Commission__c <= minAllowedCommissionPercent) {
                        updatedQuote.addError(System.Label.InvalidCommissionPercentTooLowOnQuoteError+' '+minAllowedCommissionPercent);
                    }
                } else {
                    updatedQuote.addError(System.Label.SCCActivitiesMissingOnQuoteError);
                }
            } else if(updatedQuote.SCC_Activities__c != NULL) {
                updatedQuote.addError(System.Label.CannotAddSCCActivitiesWithoutCommission);
            }
        }
    }
    
    
    /*------------------------------------------------------------------------
Author:        Anupam Mishra
Company:       Godrej
Description:   Method to update end date based on start date, duration and unit.
Inputs:        Map<Id, Opportunity> newRecordMap, Map<Id, Opportunity> oldRecordMap
----------------------------------------------------------------------------*/
    public void populateEndDate(Map<Id, Quote> newRecordMap, Map<Id, Quote> oldRecordMap){
        
        for(Quote newQuoteRec : newRecordMap.values())
        {       
            Quote oldQuoteRec = oldRecordMap.get(newQuoteRec.Id);
            if(oldQuoteRec.Record_Type_Developer_Name__c == GlobalConstants.QUOTE_MHE_CONTRACTS_RECORDTYPE_APINAME && (oldQuoteRec.Duration_Unit__c != newQuoteRec.Duration_Unit__c || oldQuoteRec.Duration__c != newQuoteRec.Duration__c 
                                                                                                                       || oldQuoteRec.Contract_Start_Date__c != newQuoteRec.Contract_Start_Date__c)){
                                                                                                                           populateEndDate(newRecordMap.values());
                                                                                                                       }
        }
        
    }
    
    /*------------------------------------------------------------------------
Author:        Anupam Mishra
Company:       Godrej
Description:   Method to update end date based on start date, duration and unit.
Inputs:        List<Opportunity> newRecords
----------------------------------------------------------------------------*/
    public void populateEndDate(List<Quote> newRecords){
        try{ //Added try catch by Shreela on 30th Nov 2022 - To resolve null pointer exception
        Set<Id> oppIds = new Set<Id>();
        for(Quote newQuoteRec : newRecords) {
            if(newQuoteRec.Duration_Unit__c == null && newQuoteRec.Duration__c == null && newQuoteRec.Contract_Start_Date__c == null )
                oppIds.add(newQuoteRec.OpportunityId);
        }
        
        Map<Id, Opportunity> oppRecordMap = getOpportunityMap(oppIds);
        
        for(Quote newQuoteRec : newRecords)
        {
            
            if(newQuoteRec.Record_Type_Developer_Name__c == GlobalConstants.QUOTE_MHE_CONTRACTS_RECORDTYPE_APINAME){ 
                if(newQuoteRec.Duration_Unit__c != null && newQuoteRec.Duration__c != null && newQuoteRec.Contract_Start_Date__c != null )
                    newQuoteRec.Contract_End_Date__c = getEndDateBasedOnDuration(newQuoteRec.Contract_Start_Date__c, newQuoteRec.Duration__c, newQuoteRec.Duration_Unit__c);
                else{                    
                    newQuoteRec.Duration_Unit__c = oppRecordMap.get(newQuoteRec.OpportunityId).Duration_Unit__c;
                    newQuoteRec.Duration__c = oppRecordMap.get(newQuoteRec.OpportunityId).Duration__c;
                    newQuoteRec.Contract_Start_Date__c = oppRecordMap.get(newQuoteRec.OpportunityId).Contract_Start_Date__c;
                    newQuoteRec.Contract_End_Date__c = oppRecordMap.get(newQuoteRec.OpportunityId).Contract_End_Date__c;
                    
                }
            }
        }
            }
        catch(Exception e){
            Logger.logError('QuoteRecordProcessor', 'populateEndDate', '', e);            
        }
        
        
    }
    
    /*------------------------------------------------------------------------
Author:        Anupam Mishra
Company:       Godrej
Description:   Method to update end date based on start date, duration and unit.
Inputs:        List<Opportunity> newRecords
----------------------------------------------------------------------------*/
    public date getEndDateBasedOnDuration(Date startDate, Decimal intDuration, String strDurationUnit){
        
        if( strDurationUnit != null && intDuration != null && startDate != null )
        {
            switch on strDurationUnit {
                when 'Day' {
                    return startDate.addDays((integer)intDuration)-1;
                }
                when 'Week' {
                    return startDate.addDays((integer)(intDuration*7 ))-1;
                }
                when 'Month' {
                    return startDate.addMonths((integer)intDuration)-1;
                }
                when 'Quarter' {
                    return startDate.addMonths((integer)intDuration*3)-1;
                }
                when 'Year' {
                    return startDate.addMonths((integer)(12 * intDuration))-1;
                }
                when else {
                    return null;
                }
            }
        }else{
            return null;
        }
    }
    
    /*------------------------------------------------------------------------
Author:        Priyanka Mukkavalli
Company:       GITL
Description:   Method to stamp the quote version on Locks quote record.
Inputs:        List<Quote> newItems
----------------------------------------------------------------------------*/    
    public void populateQuoteVersion(List<Quote> newItems) {
        for(Quote updatedQuote : newItems) {
            if(updatedQuote.Quote_Key__c.contains(GlobalConstants.RECORDTYPE_Locks_B2B)){
                updatedQuote.Quote_Version__c = [select quotecount__c from opportunity where id =: updatedQuote.OpportunityId].quotecount__c+1;
            }
        }
    }
    /*------------------------------------------------------------------------
Author:        Shreela Nair
Company:       GITL
Description:   Method to update Stage of Opportunity for SAEPB - 44 Appliance B2B
Inputs:        List<Quote> newItems
Date :         09-08-2022
----------------------------------------------------------------------------*/    
    public void updateOpportunityStage(List<Quote> newQuotes) {       
        Set<Id> opportunityIds = new Set<Id>();
        for( Quote quoteRecord : newQuotes){
            if(quoteRecord.Status==GlobalConstants.QUOTE_STATUS_FINALIZED && quoteRecord.Record_Type_Developer_Name__c == GlobalConstants.QUOTE_RECORDTYPE_APPLIANCE){
                opportunityIds.add(quoteRecord.OpportunityId);
                }
        }
        List<Opportunity> oppUpdateData = new List<Opportunity>();
        if(!opportunityIds.isEmpty()){
            for(Id opId:opportunityIds){
                oppUpdateData.add(new Opportunity(Id=opId,StageName = GlobalConstants.OPP_STAGE_WON));
            }
        }
        if(!oppUpdateData.isEmpty()){
            try{
                update oppUpdateData; 
            }
            catch(DMLException ex){
                Logger.logError('QuoteRecordProcessor', 'updateOpportunityStage', '', ex); 
            }   
        }
         
    }   
    
    /*------------------------------------------------------------------------
Author:        Shreela Nair
Company:       GITL
Description:   Method to update Payment Terms  for SAEPB - 44 Appliance B2B
Inputs:        List<Quote> newItems
Date :         14-11-2022
----------------------------------------------------------------------------*/ 
    
    public void updatePaymentTermsofQLI(List<Quote> newRecordItems,Map<Id, Quote> oldRecordMap) {
        String oldPaymentTerms;
        Set<Id> oppId = new Set<Id>();
        Set<Id> quoteId = new Set<Id>();
        for(Quote qRecord : newRecordItems){
            if(qRecord.Record_Type_Developer_Name__c == GlobalConstants.QUOTE_RECORDTYPE_APPLIANCE){
                oppId.add(qRecord.OpportunityId);
                quoteId.add(qRecord.Id);
            }            
        }
        Map<Id,Quote> quoteMap;
        Map<Id,QuoteLineItem> qliMap;        
        List<QuoteLineItem> qliList2 = new List<QuoteLineItem>();
        QuoteLineItem qliRecord;
                    if(quoteId.size()>0){
                    for(Quote qRecord : [SELECT Id,Payment_Terms__c,OpportunityId,Record_Type_Developer_Name__c,Approval_Status__c,(Select Id,Approval_Status__c from QuoteLineItems),Opportunity.Sub_Division__c
                                          FROM Quote
                                          WHERE Id IN :quoteId
                                          AND Opportunity.Sub_Division__c =: GlobalConstants.B2B_SUBDIVISION ]){
                        if(oldRecordMap!=null && oldRecordMap.get(qRecord.Id).Payment_Terms__c!=null){
                            oldPaymentTerms = oldRecordMap.get(qRecord.Id).Payment_Terms__c;
                        }
                        if(qRecord.Payment_Terms__c!=  oldPaymentTerms){
                            if(qRecord.Payment_Terms__c == GlobalConstants.Payment_Terms_Value_Within_7_Days ||qRecord.Payment_Terms__c ==GlobalConstants.PAYMENT_MODE_OTHERS ){
                                    for(QuoteLineItem qli : [SELECT Id,Approval_Status__c,QuoteId
                                                             FROM QuoteLineItem
                                                             WHERE QuoteId IN:quoteId]){
                                        if(qli.QuoteId == qRecord.Id){
                                            qli.Payment_Terms__c  = qRecord.Payment_Terms__c;
                                            qli.Approval_Status__c = GlobalConstants.APPROVAL_REQUIRED_STATUS;
                                            qliList2.add(qli);
                                        }
                                    }
                                
                            }  
                            else if(qRecord.Payment_Terms__c !=GlobalConstants.Payment_Terms_Value_Within_7_Days && qRecord.Payment_Terms__c !=GlobalConstants.PAYMENT_MODE_OTHERS ){
                                    for(QuoteLineItem qli :[SELECT Id,Approval_Status__c,QuoteId
                                                            FROM QuoteLineItem
                                                            WHERE QuoteId IN:quoteId]){
                                        if(qli.QuoteId == qRecord.Id){
                                            qli.Payment_Terms__c  = qRecord.Payment_Terms__c;
                                            qli.Approval_Status__c = GlobalConstants.APPROVAL_NOT_REQUIRED_STATUS;
                                            qliList2.add(qli);
                                        }
                                    }
                            }  
                        }
                    }
         }

        try{
            if(qliList2.size()>0)
            update qliList2;
        }
        catch(DMLException e){
            Logger.logError('QuoteRecordProcessor', 'updatePaymentTermsofQLI', '', e);
            
        }
        
    }
         
    /*------------------------------------------------------------------------
    Author:        Shreela Nair
    Company:       GITL
    Description:   Method to update Last Approved Date  for SAEPB - 44 Appliance B2B HIX
    Inputs:        List<Quote> newItems
    Date :         14-11-2022
    ----------------------------------------------------------------------------*/ 
    
    public void updateLastApprovedDate(Map<Id, Quote> newItems,Map<Id, Quote> oldRecordMap) { 
        try{
            Set<Id> setOppIds = new Set<Id>();
            Map <Id,Quote> mapApplB2BQuotes = new map<Id,Quote>();
            Map<Id,Opportunity> mapOpp;
            
            for(Quote qRecord : newItems.values()){ //Populating Quote Map and Opp set only if Quote is of type Appliances
                if(qRecord.Record_Type_Developer_Name__c == GlobalConstants.QUOTE_RECORDTYPE_APPLIANCE){
                    setOppIds.add(qRecord.OpportunityId);
                    mapApplB2BQuotes.put(qRecord.id, qRecord);
                }                           
            } 
            
            if(!mapApplB2BQuotes.isempty() && mapApplB2BQuotes!=null && !setOppIds.isempty() && setOppIds!=null ){
                mapOpp = new Map<Id,Opportunity>([SELECT Id,Sub_Division__c
                                               FROM Opportunity
                                               WHERE Id IN : setOppIds]);
                
                for(Quote qRecord : mapApplB2BQuotes.values()){
                   
                    if(oldRecordMap.get(qRecord.Id).Approval_Status__c== GlobalConstants.Submitted_for_Approval //Checking if before update the quote approval status was Submitted for Approval
                        && mapOpp.get(qRecord.OpportunityId).Sub_Division__c == GlobalConstants.B2B_SUBDIVISION // Checking if it is Appl B2B record
                        && qRecord.Approval_Status__c == GlobalConstants.APPROVED_STATUS){ //Checking if after update the quote approval status is Approved
                            qRecord.Last_Approved_Date__c = System.Today();                  
                        }
                }
            } 
        }
        catch(Exception e){
            Logger.logError('QuoteRecordProcessor', 'updateLastApprovedDate', '', e);
      }
        
    }
    /*------------------------------------------------------------------------
Author:        Shreela Nair
Company:       GITL
Description:   Method to update Payment Terms  for SAEPB - 44 Appliance B2B
Inputs:        List<Quote> newItems
Date :         14-12-2022
----------------------------------------------------------------------------*/ 
    
    public void updatePaymentTermsofQuote(List<Quote> newRecordItems,Map<Id, Quote> oldRecordMap) {
        try{
            String oldPaymentTerms;
            Set<Id> oppId = new Set<Id>();
            Set<Id> quoteId = new Set<Id>();
            for(Quote qRecord : newRecordItems){
                if(qRecord.Record_Type_Developer_Name__c == GlobalConstants.QUOTE_RECORDTYPE_APPLIANCE){
                    oppId.add(qRecord.OpportunityId);
                    quoteId.add(qRecord.Id);
                }            
            }
            
            Map<Id,Quote> quoteMap;
            if(quoteId.size()>0){ //Added this line  by Shreela on 19th January 2023
                quoteMap= new Map<Id,Quote>([SELECT Id,Payment_Terms__c,OpportunityId,Record_Type_Developer_Name__c,Approval_Status__c,(Select Id,Approval_Status__c from QuoteLineItems),Opportunity.Sub_Division__c
                                             FROM Quote
                                             WHERE Id IN :quoteId
                                             AND Opportunity.Sub_Division__c =: GlobalConstants.B2B_SUBDIVISION ]); //Add sub division check
            }
            
            for(Quote qRecord : newRecordItems){
                if(quoteMap<>null && quoteMap.size()>0){ //Added this line to avoid Attempt to deference null object by Shreela on 19th January 2023
                    if(quoteMap!=null && quoteMap.get(qRecord.Id).Opportunity.Sub_Division__c == GlobalConstants.B2B_SUBDIVISION){
                        if(oldRecordMap!=null && oldRecordMap.get(qRecord.Id).Payment_Terms__c!=null){
                            oldPaymentTerms = oldRecordMap.get(qRecord.Id).Payment_Terms__c;
                        }
                    }

                    if(qRecord.Payment_Terms__c!=  oldPaymentTerms){
                        if(qRecord.Payment_Terms__c == GlobalConstants.Payment_Terms_Value_Within_7_Days ||qRecord.Payment_Terms__c ==GlobalConstants.PAYMENT_MODE_OTHERS ){
                            qRecord.Approval_Status__c = GlobalConstants.APPROVAL_REQUIRED_STATUS;
                        }  
                        else if(qRecord.Payment_Terms__c !=GlobalConstants.Payment_Terms_Value_Within_7_Days && qRecord.Payment_Terms__c !=GlobalConstants.PAYMENT_MODE_OTHERS ){
                            qRecord.Approval_Status__c = GlobalConstants.APPROVAL_NOT_REQUIRED_STATUS;
                        }  
                    }
                    
                }
                
            }
        } 
        
        catch(Exception e){
            Logger.logError('QuoteRecordProcessor', 'updatePaymentTermsofQuote', '', e);
            
        } 
    }
    
    /*------------------------------------------------------------------------
    Author:        Priyanka Mukkavalli
    Company:       GITL
    Description:   Method to check if the MHE contract Quotes have duration of more than a year for Non Silver PLans in QLI
    Inputs:        List<Quote> newItems,Map<Id, Quote> oldRecordMap
    Date :         11-05-2023
    ----------------------------------------------------------------------------*/ 
   /* public void checkMHEContractQuotePlan(List<Quote> newRecordItems,Map<Id, Quote> oldRecordMap){
        set <Id> qIds = new set <Id>();
        for (Quote qRecord : newRecordItems){//to check if the MHE Contracts Quotes have contract start date - contract end date > year for non Silver plans 
            if(qRecord.Record_Type_Developer_Name__c== GlobalConstants.QUOTE_MHE_CONTRACTS_RECORDTYPE_APINAME 
               && qRecord.Contract_Start_Date__c != null && qRecord.Contract_End_Date__c != null
               && qRecord.Contract_Start_Date__c.daysBetween(qRecord.Contract_End_Date__c) > 366
               && (qRecord.Contract_Start_Date__c != oldRecordMap.get(qRecord.Id).Contract_Start_Date__c ||
                qRecord.Contract_End_Date__c != oldRecordMap.get(qRecord.Id).Contract_End_Date__c)){
                qIds.add(qRecord.id);   
            }
        }
        if(!qIds.isEmpty()){
            Map<Id,Quote> quoteMap = getQLIList(qIds);
            if(!quoteMap.isEmpty()){
                for (Quote qRecord : quoteMap.values()){
                   List<QuoteLineItem> qliRecords =  quoteMap.get(qRecord.Id).QuoteLineItems;
                   if(qliRecords.isEmpty()){//Throw the error as Silver Plan NOT found in QLI for > year long contract period 
                        qRecord.addError(System.label.MHEContract_Non_Silver_Error);
                   }
                }
            }
        }

    }*/
    
    /*------------------------------------------------------------------------
    Author:        Priyanka Mukkavalli
    Company:       GITL
    Description:   Method to fetch the QLI records (Silver) for the MHE contract Quotes with contract duration > a year 
    Inputs:        Set<Id> quoteIds
    Date :         11-05-2023
    ----------------------------------------------------------------------------*/ 
    /*public Map<Id,Quote> getQLIList(Set<Id> qIds) {
        Map<Id,Quote> quoteMap = new Map<Id,Quote> ([ Select Id, 
        (Select Id, product_name__c From QuoteLineItems Where product_name__c like '%Silver%')
        from Quote where ID IN:qIds ]); // if any of the qli have Silver Plan associated
        return quoteMap;
    }*/
    
    /*------------------------------------------------------------------------
    Author:        Rohit Jadhav
    Company:       GITL
    Description:   Method to fecth Locks B2B Quote Record Id's for which Approval Status has changed as Approve/Reject.
    Inputs:        List<Quote> newItems,Map<Id, Quote> oldRecordMap
    Date :         01-06-2023
    ----------------------------------------------------------------------------*/ 
    public void sendEmailNotificationOnLocksB2BQuoteApproval(List<Quote> newRecordItems,Map<Id, Quote> oldRecordMap){
        set <Id> qIds = new set <Id>();
        for (Quote qRecord : newRecordItems){
            if(qRecord.Record_Type_Developer_Name__c== GlobalConstants.RECORDTYPE_Locks_B2B 
               && ( qRecord.Approval_Status__c =='Approved' || qRecord.Approval_Status__c =='Rejected' ) //to check if the Quote Status Changed as Approved or Rejected 
               && qRecord.Approval_Status__c != oldRecordMap.get(qRecord.Id).Approval_Status__c ){
                qIds.add(qRecord.id);   
            }
        }
        if(!qIds.isEmpty()) // Check qIds set is empty or not.
        {
            sendEmailNotification(qIds);
        }
    }
    
     /*------------------------------------------------------------------------
    Author:        Rohit Jadhav
    Company:       GITL
    Description:   Method to Send Email Notification To Opportunity Owner and his manager when Quote Approve/Reject.
    Inputs:        Set<Id> quoteIds
    Date :         01-06-2023
    ----------------------------------------------------------------------------*/ 
   
    public void sendEmailNotification(Set<Id> quoteIds){
            List<Messaging.SingleEmailMessage> mailList = new List<Messaging.SingleEmailMessage>(); 
            // To Fetch OneCrm email address.
            OrgWideEmailAddress owea =  [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress WHERE DisplayName=:GlobalConstants.One_CRM];
            
            // To Fetch stored email template. 
            EmailTemplate template=[Select id from EmailTemplate where DeveloperName =:GlobalConstants.Locks_B2B_Quote_Approval_Template limit 1];   
            
            /* Map to store processInstanceStep
               Key --> QuoteId, Values--> List<ProcessInstanceStep> */
            Map<String,List<ProcessInstanceStep>> processStepMap=new Map<String,List<ProcessInstanceStep>>();
            
            for(ProcessInstanceStep processStep : [Select id,StepStatus,ProcessInstance.TargetObjectId,OriginalActorId,ActorId,Actor.Name,Comments,
                                                   SystemModStamp from ProcessInstanceStep where ProcessInstance.TargetObjectId IN:quoteIds ORDER BY SystemModStamp])
            {
                // If Map contains QuoteId as key then add processInstanceStep in List<ProcessInstanceStep>
                if(!processStepMap.isEmpty() && processStepMap.containsKey(processStep.ProcessInstance.TargetObjectId)){
                    processStepMap.get(processStep.ProcessInstance.TargetObjectId).add(processStep);
                }else{ 
                    /* If Map does not contains QuoteId as key then add QuoteId as key in map and create List<ProcessInstanceStep>,
                       add processInstanceStep in List and add List as map value. */
                    List<ProcessInstanceStep> processStepList = new List<ProcessInstanceStep>();
                    processStepList.add(processStep);
                    processStepMap.put(processStep.ProcessInstance.TargetObjectId,processStepList);
                }
            }
            
            // To Query quote record with all related QLI records for all QuoteId's present in set.
            for(Quote quoteRecord : [Select Id,Opportunity.OwnerId,Opportunity.Owner.ManagerID,Opportunity.Owner.Manager.ManagerID,OpportunityId,
                                     Opportunity.Enquiry_Number__c,Opportunity.Name,QuoteNumber,Approval_Status__c,Price_Support__c,Throughput_on_system_basic__c,
                                     (Select Id, product_name__c,Product2.Name,Product_Type_Code__c,Quantity,UnitPrice,PricebookEntry.UnitPrice,TVC__c,MRP__c,Discount__c,
                                      ThroughPut_on_System_Basic__c,Price_Support__c,Total_Sales_Price__c,Total_List_Price__c,Total_TVC__c From QuoteLineItems) from Quote where ID IN:quoteIds])
            {
                Integer Count=1;
                Decimal totalSalesPrice=0.0; // Used to calculate and store total sales price of all qli records.
                Decimal totalListPrice=0.0; // Used to calculate and store total list price of all qli records.
                Decimal totalTVCPrice=0.0; // Used to calculate and store total TVC price of all qli records.
                
                List<String> toAddressList=new List<String>();
                if(quoteRecord.Opportunity.OwnerId!=null){  // Check opportunity ownerId not null.
                    toAddressList.add(quoteRecord.Opportunity.OwnerId);
                    if(quoteRecord.Opportunity.Owner.ManagerId!=null){ //Check opportunity owner's ManagerId not null.
                        toAddressList.add(quoteRecord.Opportunity.Owner.ManagerId);
                    }
                }
                
                Messaging.SingleEmailMessage message = Messaging.renderStoredEmailTemplate(template.ID, null, quoteRecord.Id);
                
                
                

                // Replace place holder's present in email template subject.
                String subject=message.getSubject();
                subject=subject.replace('DOCUMENT_NO', quoteRecord.QuoteNumber); 
                subject=subject.replace('APPROVAL_STATUS', quoteRecord.Approval_Status__c);  
                
                // Replace place holder's present in email template htmlBody.
                String htmlBody=message.gethtmlBody();
                htmlBody=htmlBody.replace('OPPORTUNITY_NO', quoteRecord.Opportunity.Enquiry_Number__c);       
                htmlBody=htmlBody.replace('OPPORTUNITY_NAME', quoteRecord.Opportunity.Name);
               
                // To add QLI Information table in email template htmlBody.
                htmlBody += '<br /><table border="1">';
                htmlBody += '<tr><td colspan="11" style="padding:5px;">Details of Item for Discount</td></tr>';
                htmlBody += '<tr><td style="padding:5px;">Sr No</td>';
                htmlBody += '<td style="padding:5px;">Product</td>';
                htmlBody += '<td style="padding:5px;">Product Type/Code</td>';
                htmlBody += '<td style="padding:5px;">Quantity</td>';
                htmlBody += '<td style="padding:5px;">Sales Price/Total Sales Price</td>';
                htmlBody += '<td style="padding:5px;">List Price/Total List Price</td>';
                htmlBody += '<td style="padding:5px;">TVC / Total TVC</td>';
                htmlBody += '<td style="padding:5px;">MRP</td>';
                htmlBody += '<td style="padding:5px;">Discount %</td>';
                htmlBody += '<td style="padding:5px;">Throughput on List Price %</td>';
                htmlBody += '<td style="padding:5px;">Price Support %</td></tr>';
                
                for(QuoteLineItem qliRecord : quoteRecord.QuoteLineItems)
                {
                    htmlBody += '<tr><td style="padding:5px;">'+Count+'</td>';
                    htmlBody += '<td style="padding:5px;">'+qliRecord.Product2.Name+'</td>';
                    htmlBody += '<td style="padding:5px;">'+qliRecord.Product_Type_Code__c+'</td>';
                    htmlBody += '<td style="padding:5px;">'+qliRecord.Quantity+'</td>';
                    htmlBody += '<td style="padding:5px;">'+qliRecord.UnitPrice +' / '+qliRecord.Total_Sales_Price__c+'</td>';
                    htmlBody += '<td style="padding:5px;">'+qliRecord.PricebookEntry.UnitPrice+' / '+qliRecord.Total_List_Price__c+'</td>';
                    htmlBody += '<td style="padding:5px;">'+qliRecord.TVC__c+' / '+qliRecord.Total_TVC__c+'</td>';
                    htmlBody += '<td style="padding:5px;">'+qliRecord.MRP__c+'</td>';
                    htmlBody += '<td style="padding:5px;">'+qliRecord.Discount__c+'</td>';
                    htmlBody += '<td style="padding:5px;">'+qliRecord.ThroughPut_on_System_Basic__c+'</td>';
                    htmlBody += '<td style="padding:5px;">'+qliRecord.Price_Support__c+'</td></tr>';
                    
                    count++;
                    totalSalesPrice+=qliRecord.Total_Sales_Price__c;
                    totalListPrice+=qliRecord.Total_List_Price__c;
                    totalTVCPrice+=qliRecord.Total_TVC__c;                    
                }
                
                // To add totalSalesPrice,totalListPrice,totalTVCPrice in QLI Information table as new row.
                htmlBody += '<tr><td colspan="4" style="padding:5px;">TOTAL</td>';
                htmlBody += '<td style="padding:5px;">'+totalSalesPrice+'</td>';
                htmlBody += '<td style="padding:5px;">'+totalListPrice+'</td>';
                htmlBody += '<td style="padding:5px;">'+totalTVCPrice+'</td>';
                htmlBody += '<td colspan="4" style="padding:5px;">&nbsp;</td></tr>';
                
                // To add Price_Support__c,Throughput_on_system_basic__c in QLI Information table as new row.
                htmlBody += '<tr><td colspan="3" style="padding:5px;">Price Support %</td>';
                htmlBody += '<td colspan="2" style="padding:5px;">'+quoteRecord.Price_Support__c+'</td>';
                htmlBody += '<td colspan="3" style="padding:5px;">Throughput on List Price %</td>';
                htmlBody += '<td colspan="3" style="padding:5px;">'+quoteRecord.Throughput_on_system_basic__c+'</td>';
                
                // To add Approval History in email template htmlBody if present.
                if(!processStepMap.isEmpty()){
                    for(ProcessInstanceStep processStep:processStepMap.get(quoteRecord.Id)){
                        String processComments=processStep.Comments!=null ? processStep.Comments : '';
                        htmlBody += '<tr><td colspan="3" style="padding:5px;">Remarks By '+processStep.Actor.Name+'</td>';
                        htmlBody += '<td colspan="8" style="padding:5px;">'+processComments+'</td></tr>';
                          
                        htmlBody += '<tr><td colspan="3" style="padding:5px;">Remarks inserted on</td>';
                        htmlBody += '<td colspan="8" style="padding:5px;">'+processStep.SystemModStamp.format('MM/dd/yyyy')+'</td></tr>';
                     }
                }
                htmlBody += '</table><br />';
                htmlBody +='Quote Record Link : '+ URL.getOrgDomainUrl().toExternalForm()+'/lightning/r/Quote/'+quoteRecord.Id+'/view';  
                        
                message.setSubject(subject);
                message.sethtmlBody(htmlBody);
                message.setOrgWideEmailAddressId(owea.id);
                message.setToAddresses(toAddressList);
                    
                mailList.add(message);   
                
            }
            if(!mailList.isEmpty()) {  
                    try {
                        Messaging.sendEmail(mailList);
                    }
                    catch (Exception ex) {
                        Logger.logError('QuoteRecordProcessor', 'sendEmailNotification', '', ex);
                    }
            }
    }
    
 
    /*------------------------------------------------------------------------
   Author:        Varun Rajpoot
   Company:       GITL
   Description:   SLEPBS-50: Method to Update QLI Approval Status on Quote Status change.
   Inputs:        map<Id, sObject> newItems, map<Id, sObject> oldItems
   ----------------------------------------------------------------------------*/    
    
    public void updateQLIForLocksB2B(map<Id, sObject> newItems, map<Id, sObject> oldItems){
        Set<Id> qId = new Set<Id>();
        List<Quote> newQLI = (List<Quote>)newItems.values();
 		Id locksB2B = Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get(GlobalConstants.RECORDTYPE_Locks_B2B).getRecordTypeId();
        for(Quote record: newQLI){
            if( ((Quote)oldItems.get(record.Id)).Approval_Status__c != record.Approval_Status__c && record.recordTypeId == locksB2B){
                qId.add(record.Id);
            }
        }
        if(!qId.isEmpty()){
			QuoteRecordProcessor_SystemContext.updateQLIForLocksB2B(qId);
        }
    }
    
     /*------------------------------------------------------------------------
   Author:        Rohit Jadhav
   Company:       GITL
   Description:   Method to stop quote creation if Opportunity Geographical Location is Not Conductive for PED Division.
   Inputs:        List<Quote> newItems
   ----------------------------------------------------------------------------*/    
    
    public void validateOpportunityGeographicalLocationAndHighCustomerCreditAssessment(List<Quote> newItems) {
        Id pedQuoteRecordTypeId = Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get(GlobalConstants.PED_QUOTE_RT).getRecordTypeId();
        Set<Id> opportunityIdSet=new Set<Id>();
        Set<Id> nonConductiveOpportunityIdSet=new Set<Id>();
        Set<Id> moderateOrHighCustomerCreditAssessmentOpportunityIdSet=new Set<Id>();
        for(Quote quoteRecord : newItems) {
            if(quoteRecord.RecordTypeId==pedQuoteRecordTypeId){
                opportunityIdSet.add(quoteRecord.OpportunityId);
            }
        }
        if(!opportunityIdSet.isEmpty()){
            for(Opportunity oppRecord:[Select Id,Geographical_Location__c,RecordType.DeveloperName,New_Customer_Credit_Assessment_Risk__c from Opportunity where Id IN : opportunityIdSet and ( Geographical_Location__c!=:GlobalConstants.Conductive or (RecordType.DeveloperName=:GlobalConstants.PED_FIRM_OPPORTUNITY_RT and New_Customer_Credit_Assessment_Risk__c!=:GlobalConstants.Low))]){
                if(oppRecord.Geographical_Location__c!=GlobalConstants.Conductive){
                    nonConductiveOpportunityIdSet.add(oppRecord.Id);
                }else{
                    moderateOrHighCustomerCreditAssessmentOpportunityIdSet.add(oppRecord.Id);
                }
            }
        }
        if(!nonConductiveOpportunityIdSet.isEmpty() || !moderateOrHighCustomerCreditAssessmentOpportunityIdSet.isEmpty()){
            for(Quote quoteRecord : newItems) {
                if(nonConductiveOpportunityIdSet.contains(quoteRecord.OpportunityId)){
                    quoteRecord.addError(System.Label.PED_Geographic_Location_Error);
                }
                else if(moderateOrHighCustomerCreditAssessmentOpportunityIdSet.contains(quoteRecord.OpportunityId)){
                    quoteRecord.addError(System.Label.PED_New_Customer_Risk_Assesment_Error);
                }
            }
        }        
    }
    
    /*------------------------------------------------------------------------
    Author:        Rohit Jadhav
    Company:       GITL
    Description:   Method to Send Email Notification To Level_Approver_c and Submitter when Quote Submitted for approval.
    Inputs:        List<Quote> newRecordItems,Map<Id, Quote> oldRecordMap
    Date :         17-10-2023
    ----------------------------------------------------------------------------*/
    
    public void sendEmailNotificationToPEDUsers(List<Quote> newRecordItems,Map<Id, Quote> oldRecordMap){
        Set<Id> quoteIds=new Set<Id>();
        for (Quote qRecord : newRecordItems){
            if(qRecord.Record_Type_Developer_Name__c== GlobalConstants.PED_QUOTE_RT 
               &&  qRecord.Approval_Status__c ==GlobalConstants.Submitted_for_Approval //to check if the Quote Approval Status Changed as Submitted For Approval
               && qRecord.Approval_Status__c != oldRecordMap.get(qRecord.Id).Approval_Status__c ){
        		quoteIds.add(qRecord.Id);  
            }
        }
        if(!quoteIds.isEmpty()) // Check qIds set is empty or not.
        {
            QuoteRecordProcessor.sendEmailToApprover(quoteIds); 
        }
    }  
    
    @future(callout=true)
    public static void sendEmailToApprover(Set<Id> quoteIds){
        List<Quote> quoteRecordList = [Select Id,Name,Level_1_Approver__c,Quote_Type__c,PED_Quote_PDF_Type__c,Opportunity.EST_FILE_NO_Firm__c,Opportunity.EST_FILE_NO_Budgetory__c from Quote where Id IN :quoteIds ];
        if(!quoteRecordList.isEmpty()) // Check qIds set is empty or not.
        {
            List<Messaging.SingleEmailMessage> mailList = new List<Messaging.SingleEmailMessage>(); 
            
            // To Fetch OneCrm email address.
            OrgWideEmailAddress owea =  [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress WHERE DisplayName=:GlobalConstants.One_CRM];
            
            // To Fetch stored email template. 
            EmailTemplate template=[Select id from EmailTemplate where DeveloperName =:GlobalConstants.PED_Quote_Approval_Email_Template limit 1];   
            for(Quote quoteRecord:quoteRecordList){
                List<String> toAddressList=new List<String>();
                if(quoteRecord.Level_1_Approver__c!=null){  // Check Level_1_Approver__c not null.
                    toAddressList.add(quoteRecord.Level_1_Approver__c);
                    toAddressList.add(UserInfo.getUserEmail());                    
                }
                
                List<Messaging.Emailfileattachment> fileAttachments = new List<Messaging.Emailfileattachment>();
                 //generate and attach the PDF document
                PageReference pdfPage = Page.PedQuotePdf;// page reference
                pdfPage.getParameters().put('id',quoteRecord.Id);
                Blob pdfBlob; //create a blob for the PDF content
                pdfBlob = Test.isRunningTest() ? Blob.valueOf('generate pdf') : pdfPage.getContent();
                Messaging.Emailfileattachment efa = new Messaging.Emailfileattachment();
                String FileNo=quoteRecord.Quote_Type__c==GlobalConstants.PED_FIRM ? quoteRecord.Opportunity.EST_FILE_NO_Firm__c : quoteRecord.Opportunity.EST_FILE_NO_Budgetory__c;
                efa.setFileName(quoteRecord.PED_Quote_PDF_Type__c+' - '+FileNo);
                efa.setBody(pdfBlob);
                fileAttachments.add(efa);
                 
                Messaging.SingleEmailMessage message = Messaging.renderStoredEmailTemplate(template.ID, null, quoteRecord.Id);                        

                // Replace place holder's present in email template htmlBody.
                String recordLink ='Quote Record Link : '+ URL.getOrgDomainUrl().toExternalForm()+'/lightning/r/Quote/'+quoteRecord.Id+'/view';  
                String htmlBody=message.gethtmlBody();                
                htmlBody=htmlBody.replace('RECORD_LINK', recordLink);   
                         
                message.setSubject(message.getSubject());
                message.sethtmlBody(htmlBody);
                message.setOrgWideEmailAddressId(owea.id);
                message.setToAddresses(toAddressList); 
                message.setFileAttachments(fileAttachments); 
                mailList.add(message);                   
            }
            if(!mailList.isEmpty()) {  
            	try {
                	Messaging.sendEmail(mailList);
                }
                catch (Exception ex) {
                    Logger.logError('QuoteRecordProcessor', 'sendEmailToApprover', '', ex);
                }
            }
        }
    }
    
     /*------------------------------------------------------------------------
    Author:        Rohit Jadhav
    Company:       GITL
    Description:   Method to throw validation error if offer date field is blank while quote is submitted for approval.
    Inputs:        List<Quote> newRecordItems,Map<Id, Quote> oldRecordMap
    Date :         20-11-2023
    ----------------------------------------------------------------------------*/
    
     public void validateOfferDateForPED(List<Quote> newItems,Map<Id, Quote> oldRecordMap) {
        for(Quote qRecord : newItems){
                if (qRecord.Record_Type_Developer_Name__c== GlobalConstants.PED_QUOTE_RT 
               		&& qRecord.Approval_Status__c ==GlobalConstants.Submitted_for_Approval
               		&& qRecord.Approval_Status__c != oldRecordMap.get(qRecord.Id).Approval_Status__c
                    && qRecord.Offer_Date__c==null) {
                    qRecord.addError(System.Label.PED_Offer_Date_Validation);
                }
        }
     }
}