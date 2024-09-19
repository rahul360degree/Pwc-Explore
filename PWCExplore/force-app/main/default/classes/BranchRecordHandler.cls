/*------------------------------------------------------------------------
Author:        Kishor Kumar
Company:       Salesforce
Description:   Class to handle Branch record activities
Test Class:   

History
15-05-2020      Kishor Kumar     Initial Release
----------------------------------------------------------------------------*/
public with sharing class BranchRecordHandler {
    
    /*------------------------------------------------------------------------
    Author:        Kishor Kumar
    Company:       Salesforce
    Description:   Method to populate Defaults on records
    Inputs:        list of created Branch records
    Test Class:   

   History
    08-06-2020      Kishor Kumar     Initial Release
    22-07-2020	    Amit Shingavi    Updating code to consider the Sales Office code for mapping
    ----------------------------------------------------------------------------*/
    public void populateDefaultsOnBranch(List<Branch__c> branches){
		set<Branch__c> branchesToPopulate = new set<Branch__c>();
        map<Id, User> userMap = new map<Id, User>();
        set<String> salesOffices = new set<String>();
        map<String, Id> salesOfficeMap = new map<String, Id>();
        
        try{
            for(Branch__c branch : branches){
                if(String.isBlank(branch.Area__c) || branch.Sales_Office__c == null || 
                   			String.isBlank(branch.Branch_Name__c)){
                    branchesToPopulate.add(branch);
                } 
            }
            
            for(User userRec: [SELECT Id, Sales_Office__c, Area_Code__c, Logistic_Company__c 
                               FROM User 
                               Where Id  =: userInfo.getUserId()]){
               userMap.put(userRec.Id, userRec);
               salesOffices.add(userRec.Sales_Office__c);                    
            }
            
            if(salesOffices.size() > 0){
                for(Sales_Office__c sOffice : [Select Id, Name, LN_Sales_Office_Code__c  
                                              	FROM Sales_Office__c 
                                              	WHERE LN_Sales_Office_Code__c  IN: salesOffices]){
                    salesOfficeMap.put(sOffice.LN_Sales_Office_Code__c , sOffice.Id);
                }
            }
            
            //Populate Defaults
            for(Branch__c branch : branchesToPopulate){
                if(userMap.containsKey(userInfo.getUserId())){
                    //Populate Area
                   if(String.isBlank(branch.Area__c))
                    	branch.Area__c = userMap.get(userInfo.getUserId()).Area_Code__c;
                    //Populate Sales Office
                    if(branch.Sales_Office__c == null &&
                       String.isNotBlank(userMap.get(userInfo.getUserId()).Sales_Office__c ) &&
                       salesOfficeMap.containsKey(userMap.get(userInfo.getUserId()).Sales_Office__c)){
						
                           branch.Sales_Office__c = salesOfficeMap.get(userMap.get(userInfo.getUserId()).Sales_Office__c);
					}
                    	
                    //Populate Branch Name
                    if(String.isBlank(branch.Branch_Name__c))
                        branch.Branch_Name__c = userMap.get(userInfo.getUserId()).Logistic_Company__c;
                }
            }
        }catch(Exception ex){
            Logger.logError('BranchRecordHandler', 'populateDefaultsOnBranch', '', ex);
        }
    }
    
    /*------------------------------------------------------------------------
    Author:        Kishor Kumar
    Company:       Salesforce
    Description:   Method to Update Ship To & Sold To address on records
    Inputs:        list of created Branch records
    Test Class:   

    History
    15-05-2020      Kishor Kumar     Initial Release
    ----------------------------------------------------------------------------*/
    public void updateAddressesOnBranch(List<Branch__c> branches){
        set<Id> accountIds = new set<Id>();
        map<Id, Id> accIdVsAddressId = new map<Id, Id>();
        
        try{
            for(Branch__c branch : branches){
                if(branch.Business_Partner__c != null && branch.Sold_To_Address__c == null){
                    accountIds.add(branch.Business_Partner__c);
                }
            }
            if(accountIds.size()> 0){
                for(Account acc : [Select Id, Primary_Address__c FROM Account WHERE Id IN : accountIds]){
                    accIdVsAddressId.put(acc.Id, acc.Primary_Address__c);
                }
            }
            for(Branch__c branch : branches){
                if(branch.Sold_To_Address__c == null && 
                   branch.Business_Partner__c != null && 
                   accIdVsAddressId.containsKey(branch.Business_Partner__c)){
                       branch.Sold_To_Address__c = accIdVsAddressId.get(branch.Business_Partner__c); 
                   }
                if(branch.Ship_To_Address__c == null)
                    branch.Ship_To_Address__c = branch.Sold_To_Address__c;
            }
            
        }catch(Exception ex){
            Logger.logError('BranchRecordHandler', 'updateAddressesOnBranch', '', ex);
        }
        
    }

    
    /*------------------------------------------------------------------------
    Author:        Kishor Kumar
    Company:       Salesforce
    Description:   Method to validate Address against relevant Tax Number details
    Inputs:        list of created Branch records
    Test Class:   

    History
    26-05-2020      Kishor Kumar     Initial Release
    ----------------------------------------------------------------------------*/
    public void validateTaxNumberForSelectedAddress(List<Branch__c> branches){       
        set<Id> addressIds = new set<Id>();
        map<Id,Address__c> addressMap = new map<Id,Address__c>();
        set<Id> accountIds = new set<Id>();
        map<Id, list<Tax_Number__c>> AccountIdVsTaxNumbers = new map<Id, list<Tax_Number__c>>();
        
        try{
            for(Branch__c branch : branches){
                if(branch.Sold_To_Address__c != null && branch.Business_Partner__c != null){
                   addressIds.add(branch.Sold_To_Address__c); 
                    accountIds.add(branch.Business_Partner__c);
                }
            }
            
            //fetch Address State details 
            if(addressIds.size() > 0){
                for(Address__c address : [Select Id, State_Province__c , StateName__c 
                                          FROM Address__c 
                                          WHERE ID IN: addressIds AND State_Province__c  != '' ]){
                     addressMap.put(address.Id, address);                         
                }
            }
            
            //fetch Account details with relevant Tax Number records
            if(accountIds.size() > 0){
                for(Account acc : [Select Id, (Select Id, State_Province__c, Business_Partner__c FROM Tax_Numbers__r WHERE State_Province__c != '') 
                                    FROM Account 
                                    WHERE Id IN: accountIds]){
                       if((acc.Tax_Numbers__r).size() > 0){
                            AccountIdVsTaxNumbers.put(acc.Id, new list<Tax_Number__c>(acc.Tax_Numbers__r));                         
                       }
                } 
            }
            
            //Validate Branch records with Corresponding Address & relevant Tax Number details
            for(Branch__c branchRec : branches){
                Boolean showerror = false;
                if(branchRec.Sold_To_Address__c != null && branchRec.Business_Partner__c != null){
                    //No tax number across Account is found: Show error
                    if(AccountIdVsTaxNumbers.isEmpty() || !AccountIdVsTaxNumbers.containsKey(branchRec.Business_Partner__c)){
                        showerror = true;
                    }else if(!AccountIdVsTaxNumbers.isEmpty() && !addressMap.isEmpty() && AccountIdVsTaxNumbers.containsKey(branchRec.Business_Partner__c)) {
                        for(Tax_Number__c taxNumber : AccountIdVsTaxNumbers.get(branchRec.Business_Partner__c)){
                            //Iterate Tax number across the account to check for valid Tax number with Address's State code
                            if((addressMap.get(branchRec.Sold_To_Address__c).State_Province__c).toUpperCase() == (taxNumber.State_Province__c).toUpperCase()){
                                showerror = false;
                                break;
                            } else {
                                showerror = true;
                            }
                        }
                    }
                    
                    if(showerror){
                        branchRec.addError(System.Label.Tax_Number_error_for_Address + ' - ' + addressMap.get(branchRec.Sold_To_Address__c).StateName__c + '('+ addressMap.get(branchRec.Sold_To_Address__c).State_Province__c +')');
                    }
                }
            }
        }catch(Exception ex){
            Logger.logError('BranchRecordHandler', 'validateTaxNumberForSelectedAddress', '', ex);
        }
    }
    
    /*------------------------------------------------------------------------
    Author:        Kishor Kumar
    Company:       Salesforce
    Description:   Method to Create Address By BP records
    Inputs:        list of created Branch records
    Test Class:   

    History
    15-05-2020      Kishor Kumar     Initial Release
    ----------------------------------------------------------------------------*/
    public void createAddressByBPRecords(List<Branch__c> branches){
        list<Address_by_BP__c> ABPsToCreate = new list<Address_by_BP__c>();
        String strRestrictedBranches = System.label.Restricted_branches_for_ABP_creation;//Added by pankaj on 2/72023 for restricting ABP creation
        List<String> lstRestrictedBranches = strRestrictedBranches.split(',');//Added by pankaj on 2/72023 for restricting ABP creation
        
        for(Branch__c branch : branches){
            if(branch.Ship_To_Address__c != null && branch.Sold_To_Address__c != null){
                if(branch.Ship_To_Address__c == branch.Sold_To_Address__c){
                    //Initialize Address By BP Instance
                    Address_by_BP__c abp = new Address_by_BP__c();
                    abp.Account__c = branch.Business_Partner__c;
                    abp.Branch__c = branch.Id;
                    abp.isPrimary__c = true;
                    abp.Address_Code__c = branch.Ship_To_Address__c;
                    abp.Ship_To__c = true;
                    abp.Sold_To__c = true;
                    if(!lstRestrictedBranches.contains(branch.Branch_Name__c)){
                        ABPsToCreate.add(abp);
                    }
                } else {
                    //Initialize Address By BP Instance for Sold To
                    Address_by_BP__c abp1 = new Address_by_BP__c();
                    abp1.Account__c = branch.Business_Partner__c;
                    abp1.Branch__c = branch.Id;
                    abp1.isPrimary__c = true;
                    abp1.Address_Code__c = branch.Sold_To_Address__c;
                    abp1.Ship_To__c = false;
                    abp1.Sold_To__c = true;
                    if(!lstRestrictedBranches.contains(branch.Branch_Name__c)){
                    	ABPsToCreate.add(abp1);
                    }
                    //Initialize Address By BP Instance for Ship To
                    Address_by_BP__c abp2 = new Address_by_BP__c();
                    abp2.Account__c = branch.Business_Partner__c;
                    abp2.Branch__c = branch.Id;
                    abp2.isPrimary__c = true;
                    abp2.Address_Code__c = branch.Ship_To_Address__c;
                    abp2.Ship_To__c = true;
                    abp2.Sold_To__c = false;
                    if(!lstRestrictedBranches.contains(branch.Branch_Name__c)){
                        ABPsToCreate.add(abp2);
                    }
                }
                
            } else if(branch.Ship_To_Address__c != null && branch.Sold_To_Address__c == null){
                //Initialize Address By BP Instance
                Address_by_BP__c abp1 = new Address_by_BP__c();
                abp1.Account__c = branch.Business_Partner__c;
                abp1.Branch__c = branch.Id;
                abp1.isPrimary__c = true;
                abp1.Address_Code__c = branch.Ship_To_Address__c;
                abp1.Ship_To__c = true;
                abp1.Sold_To__c = false;
                if(!lstRestrictedBranches.contains(branch.Branch_Name__c)){
                    ABPsToCreate.add(abp1);
                }
            } else if(branch.Ship_To_Address__c == null && branch.Sold_To_Address__c != null){
                //Initialize Address By BP Instance
                Address_by_BP__c abp2 = new Address_by_BP__c();
                abp2.Account__c = branch.Business_Partner__c;
                abp2.Branch__c = branch.Id;
                abp2.isPrimary__c = true;
                abp2.Address_Code__c = branch.Sold_To_Address__c;
                abp2.Ship_To__c = false;
                abp2.Sold_To__c = true;
                if(!lstRestrictedBranches.contains(branch.Branch_Name__c)){
                    ABPsToCreate.add(abp2);
                }
            }
        }
        try{
            if(ABPsToCreate.size() > 0){
            	insert ABPsToCreate;
        	}
        } catch(Exception ex){
            Logger.logError('BranchRecordHandler', 'createAddressByBPRecords', '', ex);
        }
    }
    
    /*------------------------------------------------------------------------
    Author:        Kishor Kumar
    Company:       Salesforce
    Description:   Method to Create Address By BP records
    Inputs:        list of created Branch records
    Test Class:   

    History
    16-05-2020      Kishor Kumar     Initial Release
    ----------------------------------------------------------------------------*/
    public void CheckAndCreateAddressByBPRecords(map<Id, Branch__c> newItems, map<Id, Branch__c> oldItems){
        set<Id> branchIds = new set<Id>();
        map<Id, list<Address_by_BP__c>> branchIdVsABPs = new map<Id, list<Address_by_BP__c>>();
        list<Address_by_BP__c> ABPsToUpsert = new list<Address_by_BP__c>();
        
        for(Id newItemId : newItems.keyset()){
            if(newItems.get(newItemId).Ship_To_Address__c != oldItems.get(newItemId).Ship_To_Address__c  || 
              	newItems.get(newItemId).Sold_To_Address__c != oldItems.get(newItemId).Sold_To_Address__c){
                branchIds.add(newItemId);
            }
        } 
        
        branchIdVsABPs = checkforExistingAddressByBPRecords(branchIds);
        for(Id branchId : newItems.keyset()){
            if(oldItems.get(branchId).Ship_To_Address__c != oldItems.get(branchId).Sold_To_Address__c && 
                     	!branchIdVsABPs.isEmpty()){
                //2 => 2
                if((newItems.get(branchId).Ship_To_Address__c != oldItems.get(branchId).Ship_To_Address__c ||
                     newItems.get(branchId).Sold_To_Address__c != oldItems.get(branchId).Sold_To_Address__c) && 
                  	 newItems.get(branchId).Ship_To_Address__c != newItems.get(branchId).Sold_To_Address__c){
                        //Retrieve both Existing ABP record from Map & update for Ship To address
                        branchIdVsABPs.get(branchId)[0].Address_Code__c = newItems.get(branchId).Ship_To_Address__c;
                        branchIdVsABPs.get(branchId)[0].Ship_To__c = true;
                        branchIdVsABPs.get(branchId)[0].Sold_To__c = false;
                        branchIdVsABPs.get(branchId)[0].isPrimary__c = true;
                        
                        ABPsToUpsert.add(branchIdVsABPs.get(branchId)[0]);   
                        
                        //update for Sold To address
                        branchIdVsABPs.get(branchId)[1].Address_Code__c = newItems.get(branchId).Sold_To_Address__c;
                        branchIdVsABPs.get(branchId)[1].Ship_To__c = false;
                        branchIdVsABPs.get(branchId)[1].Sold_To__c = true;
                        branchIdVsABPs.get(branchId)[1].isPrimary__c = true;
                        
                        ABPsToUpsert.add(branchIdVsABPs.get(branchId)[1]);
                } 
                
                //2 =>1
                if((newItems.get(branchId).Ship_To_Address__c != oldItems.get(branchId).Ship_To_Address__c ||
                     newItems.get(branchId).Sold_To_Address__c != oldItems.get(branchId).Sold_To_Address__c) && 
                  	 newItems.get(branchId).Ship_To_Address__c == newItems.get(branchId).Sold_To_Address__c){
                        
                         Integer loopIndex =1;
                         Boolean isMatchingRecordFound = false;
                         for(Address_by_BP__c abpRec : branchIdVsABPs.get(branchId)){
                             if(abpRec.Address_Code__c == newItems.get(branchId).Ship_To_Address__c){
                                 abpRec.Address_Code__c = newItems.get(branchId).Ship_To_Address__c;
                                 abpRec.Ship_To__c = true;
                                 abpRec.Sold_To__c = true;
                                 abpRec.isPrimary__c = true;
                                 
                                 isMatchingRecordFound = true;
                             } else if(!isMatchingRecordFound && loopIndex == branchIdVsABPs.size()){
                                 abpRec.Address_Code__c = newItems.get(branchId).Ship_To_Address__c;
                                 abpRec.Ship_To__c = true;
                                 abpRec.Sold_To__c = true;
                                 abpRec.isPrimary__c = true;
                                 
                                 isMatchingRecordFound = false;
                             } else {
                               if (Schema.sObjectType.Address_by_BP__c.isupdateable()){
                                   abpRec.Ship_To__c = false;
                                   abpRec.Sold_To__c = false;
                                   abpRec.isPrimary__c = true;
                                 }
                             }
                             
                             ABPsToUpsert.add(abpRec);
                             loopIndex++;
                         }
                         
                } 
            } else if(oldItems.get(branchId).Ship_To_Address__c == oldItems.get(branchId).Sold_To_Address__c && 
                     	!branchIdVsABPs.isEmpty()){
                //1=>1
                if((newItems.get(branchId).Ship_To_Address__c != oldItems.get(branchId).Ship_To_Address__c ||
                    newItems.get(branchId).Sold_To_Address__c != oldItems.get(branchId).Sold_To_Address__c) && 
                    newItems.get(branchId).Ship_To_Address__c == newItems.get(branchId).Sold_To_Address__c){
                    //Same ABP update
                        Integer loopcount = 1;
                        for(Address_by_BP__c abpVar : branchIdVsABPs.get(branchId)){
                            //mark all the record inactive if more than 1 record exists
                            if(loopcount == 1){
                                abpVar.Address_Code__c = newItems.get(branchId).Sold_To_Address__c;
                                abpVar.Ship_To__c = true;
                                abpVar.Sold_To__c = true;
                                abpVar.isPrimary__c = true;
                                
                                ABPsToUpsert.add(abpVar);
                            } else {
                                abpVar.Ship_To__c = false;
                                abpVar.Sold_To__c = false;
                                abpVar.isPrimary__c = true;
                                ABPsToUpsert.add(abpVar);
                            }
                             loopcount++;
                            
                        }
                }
                //1=>2
                if((newItems.get(branchId).Ship_To_Address__c != oldItems.get(branchId).Ship_To_Address__c ||
                    newItems.get(branchId).Sold_To_Address__c != oldItems.get(branchId).Sold_To_Address__c) && 
                    newItems.get(branchId).Ship_To_Address__c != newItems.get(branchId).Sold_To_Address__c){
                    	//Retrieve Existing ABP record from Map & update for Ship To address
                    	if(branchIdVsABPs.get(branchId).size() == 1){
                            branchIdVsABPs.get(branchId)[0].Address_Code__c = newItems.get(branchId).Ship_To_Address__c;
                            branchIdVsABPs.get(branchId)[0].Ship_To__c = true;
                            branchIdVsABPs.get(branchId)[0].Sold_To__c = false;
                            branchIdVsABPs.get(branchId)[0].isPrimary__c = true;
                            
                            ABPsToUpsert.add(branchIdVsABPs.get(branchId)[0]); 
                            
                            //Create New Address By BP for sold to address
                            Address_by_BP__c abp = new Address_by_BP__c();
                            if(Schema.sObjectType.Address_by_BP__c.fields.Account__c.isCreateable() && Schema.sObjectType.Address_by_BP__c.fields.Branch__c.isUpdateable()){ 
                            	abp.Account__c = newItems.get(branchId).Business_Partner__c;
                            	abp.Branch__c = branchId;
                            	abp.isPrimary__c = true;
                            	abp.Address_Code__c = newItems.get(branchId).Sold_To_Address__c;
                            	abp.Ship_To__c = false;
                            	abp.Sold_To__c = true;
                              }
                            ABPsToUpsert.add(abp);
                         
                        } else {
                            //If size =2
                            
                            branchIdVsABPs.get(branchId)[0].Address_Code__c = newItems.get(branchId).Ship_To_Address__c;
                            branchIdVsABPs.get(branchId)[0].Ship_To__c = true;
                            branchIdVsABPs.get(branchId)[0].Sold_To__c = false;
                            branchIdVsABPs.get(branchId)[0].isPrimary__c = true;
                            
                            ABPsToUpsert.add(branchIdVsABPs.get(branchId)[0]);
                            
                            branchIdVsABPs.get(branchId)[1].Address_Code__c = newItems.get(branchId).Sold_To_Address__c;
                            branchIdVsABPs.get(branchId)[1].Ship_To__c = false;
                            branchIdVsABPs.get(branchId)[1].Sold_To__c = true;
                            branchIdVsABPs.get(branchId)[1].isPrimary__c = true;
                            
                            ABPsToUpsert.add(branchIdVsABPs.get(branchId)[1]);
                        }
                }
            }
        }
        
        //Upsert ABP record
        try{
            if(ABPsToUpsert.size() > 0  && Schema.sObjectType.Address_by_BP__c.isupdateable()){
                 upsert ABPsToUpsert; 
           }
        } catch(Exception ex){
            Logger.logError('BranchRecordHandler', 'CheckAndCreateAddressByBPRecords', '', ex);
        }
    }
    
    private map<Id, list<Address_by_BP__c>> checkforExistingAddressByBPRecords(set<Id> branchIds){
        map<Id, list<Address_by_BP__c>> branchIdVsABPs = new map<Id, list<Address_by_BP__c>>();
        
        for(Address_by_BP__c abp : [Select Id, Branch__c, isPrimary__c, Address_Code__c, 
                                    	Ship_To__c, Sold_To__c, Account__c 
                                   		FROM Address_by_BP__c  
                                   		WHERE isPrimary__c = true 
                                   		AND Branch__c IN : branchIds]){
            if(branchIdVsABPs.isEmpty() || !branchIdVsABPs.containsKey(abp.Branch__c)){
                branchIdVsABPs.put(abp.Branch__c, new list<Address_by_BP__c>{abp});
            } else {
                branchIdVsABPs.get(abp.Branch__c).add(abp);
            }
        }
        
        return branchIdVsABPs;
    }
    
}