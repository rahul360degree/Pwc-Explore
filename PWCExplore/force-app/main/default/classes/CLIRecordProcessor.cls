/*------------------------------------------------------------------------
Author:        Kartik Shetty
Company:       Salesforce
Description:   Processor class for 'Contract Line Item' Records
Inputs:        NA
Test Class:    
History
23-05-2020      Kartik Shetty     Initial Release
----------------------------------------------------------------------------*/
public with sharing class CLIRecordProcessor {
    /*------------------------------------------------------------------------
    Author:        Kartik Shetty
    Company:       Salesforce
    Description:   Method to populate Configuration Line Item field.
    Inputs:        NA
    Test Class:    
    History
    23-05-2020      Kartik Shetty     Initial Release
    29-12-2020      Amit Shingavi     Revamped this method to make it bulkified
    ----------------------------------------------------------------------------*/
    public void updateConfigurationLineItemNumber(List<ContractLineItem> contractLineItems) {
        
        Decimal LINE_SERIES_INCREMENT = 10;

        Set<Id> contractIds = new Set<Id>();
        Map<Id, Decimal> contractMap = new Map<Id, Decimal>();
        for(ContractLineItem cli : contractLineItems){
            contractIds.add(cli.ServiceContractId);
        }
        
        // Find the last maximum configuratin line number 
        for(ServiceContract  scItr : [SELECT Id,(SELECT Id,Configuration_Line_Number__c FROM ContractLineItems 
                                                 ORDER BY Configuration_Line_Number__c DESC LIMIT 1) FROM ServiceContract 
                                     WHERE Id IN: contractIds]){
            if(!scItr.ContractLineItems.isEmpty())  
            {
                contractMap.put(scItr.Id,Decimal.valueOf(scItr.ContractLineItems[0].Configuration_Line_Number__c));
            }else{
                contractMap.put(scItr.Id,0);
            }
        }

        for(ContractLineItem cli : contractLineItems){
            if(contractMap.containsKey(cli.ServiceContractId))
            {
                cli.Configuration_Line_Number__c = String.ValueOf(contractMap.get(cli.ServiceContractId) + LINE_SERIES_INCREMENT);
                contractMap.put(cli.ServiceContractId,Decimal.valueOf(cli.Configuration_Line_Number__c));
            }
        }
      /*  Decimal LINE_SERIES_START = 0.0;
        // Get one of cli based on configuration line item number on descending order and update the current one on 10s series.
        List<ContractLineItem> cliList = [Select Id, Configuration_Line_Number__c FROM ContractLineItem
            WHERE Configuration_Line_Number__c != null
            ORDER BY Configuration_Line_Number__c DESC LIMIT 1
        ];

        if(cliList.size() > 0 && cliList[0].Configuration_Line_Number__c != null) {
            LINE_SERIES_START = Decimal.valueOf(cliList[0].Configuration_Line_Number__c);
        }
        for(ContractLineItem cli : contractLineItems) {
            cli.Configuration_Line_Number__c  = String.valueOf(LINE_SERIES_START + LINE_SERIES_INCREMENT);
            system.debug('======'+cli.Configuration_Line_Number__c);
            LINE_SERIES_START = LINE_SERIES_START + LINE_SERIES_INCREMENT;
        }*/
    }

    /*------------------------------------------------------------------------
    Author:        Kartik Shetty
    Company:       Salesforce
    Description:   Method to Asset serial number to Serial Number field on Contract Line Item if Asset is populated.
    Inputs:        NA
    Test Class:    
    History
    23-05-2020      Kartik Shetty     Initial Release
    ----------------------------------------------------------------------------*/
    public void updateAssetSerialNumber(List<ContractLineItem> contractLineItems) {
        Map<Id, ContractLineItem> assetIdVSContractLineItem = new Map<Id, ContractLineItem>();
        for(ContractLineItem cli : contractLineItems) {
            if(cli.AssetId != null) {
                assetIdVSContractLineItem.put(cli.AssetId, cli);
            }
        }
        if(assetIdVSContractLineItem.size() > 0) {
            Map<Id, Asset> assetMap = new Map<Id, Asset>([Select Id, SerialNumber,Equipment_Serial_No__c FROM Asset WHERE Id IN :assetIdVSContractLineItem.keySet()]);
            
            // Update those Contract Line Items that have asset records populated.
            for(Id assetId : assetIdVSContractLineItem.keySet()) {
                Asset assetRecord = assetMap.get(assetId);
                ContractLineItem cli = assetIdVSContractLineItem.get(assetId);
                cli.Serial_Number__c = assetRecord.Equipment_Serial_No__c;
            }
        }
    }

    /*------------------------------------------------------------------------
    Author:        Kishor Kumar
    Company:       Salesforce
    Description:   Method to validate Only one CLI can be active across an asset 
                    at a time for certail date range
    Inputs:        
    Test Class:    
    History
    07-11-2020      Kishor Kumar     Initial Release
    ----------------------------------------------------------------------------*/
    public void validateActiveCLIforAsset(List<ContractLineItem> contractLineItems){
        set<Id> AssetIds = new set<Id>();
        set<Id> serviceContractIds = new set<Id>();
        map<Id, ContractLineItem> assetVsExistingCLI = new map<Id, ContractLineItem>();

        //get all the asset Ids 
        for(ContractLineItem cli : contractLineItems){
            if(cli.AssetId != null && cli.StartDate != null && cli.EndDate != null){
                AssetIds.add(cli.AssetId);
            }
        }
        
        //Fetch existing CLIs for an asset
        if(AssetIds.size() > 0){
            for(ContractLineItem cliVar : [SELECT Id, AssetId, StartDate, EndDate 
                                                FROM ContractLineItem 
                                                WHERE AssetId IN : AssetIds 
                                                AND ServiceContract.Status__c =: GlobalConstants.SERVICE_CONTRACT_ACTIVE_STATUS 
                                                AND StartDate != null 
                                                AND EndDate != null LIMIT 1]){
                assetVsExistingCLI.put(cliVar.AssetId, cliVar);
            }
        }

        //Check for active CLI for an asset with existing CLIs
        for(ContractLineItem cli : contractLineItems){
            if(cli.AssetId != null && assetVsExistingCLI.containsKey(cli.AssetId) 
                    && cli.StartDate != null && cli.EndDate != null){
                ContractLineItem  existingCLI =  assetVsExistingCLI.get(cli.AssetId);  
                
                Boolean showError = false;
                //Start Date before or same as existing Active CLI start date & End date after or same as existing Active CLI start date
                if(cli.StartDate <= existingCLI.StartDate && cli.EndDate >= existingCLI.StartDate ){
                    //display error
                    showError = true;
                }

                //Start Date before or same as existing Active CLI end date & End date after or same as existing Active CLI end date
                if(cli.StartDate <= existingCLI.EndDate && cli.EndDate >= existingCLI.EndDate ){
                    //display error
                    showError = true;
                }

                //Start Date & End date falls within the Active CLI date range
                if(cli.StartDate >= existingCLI.StartDate && cli.EndDate <= existingCLI.EndDate ){
                    //display error
                    showError = true;
                }

                //Start Date before or same as existing Active CLI start date & End date after or same as existing Active CLI End date
                if(cli.StartDate <= existingCLI.StartDate && cli.EndDate >= existingCLI.EndDate ){
                    //display error
                    showError = true;
                }

                if(showError){
                    cli.addError(System.Label.Active_CLI_for_an_Asset_validation);
                }
            }
        }
    }
    /*------------------------------------------------------------------------
    Author:        Amit Shingavi
    Company:       Salesforce
    Description:   Method to auto populate the dates on line
    Inputs:        NA
    Test Class:    
    History
    29-12-2020      Amit Shingavi     Revamped this method to make it bulkified
    ----------------------------------------------------------------------------*/
    public void populateDatesOnLineFromSR(List<ContractLineItem> contractLineItems) {
        Set<Id> scIds = new Set<Id>();
        
        for(ContractLineItem clItem : contractLineItems){
            scIds.add(clItem.ServiceContractId);
        }
        
        Map<Id,ServiceContract> contractMap = new Map<Id,ServiceContract>([SELECT Id, 
                                                                                  StartDate,
                                                                                  EndDate,
                                                                                  
                                                                                  //Added by Praful - 02-March-2021
                                                                                  Duration_Unit__c, Duration__c,
                                                                                  
                                                                                  Contract_Template__c 
                                                                             FROM ServiceContract 
                                                                            WHERE Id IN: scIds
                                                                          ]);
        
        for(ContractLineItem clItem : contractLineItems){
            clItem.StartDate = clItem.StartDate == null ? contractMap.get(clItem.ServiceContractId).StartDate : clItem.StartDate;
            clItem.EndDate   = clItem.EndDate == null ? contractMap.get(clItem.ServiceContractId).EndDate : clItem.EndDate;
            
            //Added by Praful - 02-March-2021
            clItem.Duration_Unit__c = clItem.Period_Unit__c = contractMap.get(clItem.ServiceContractId).Duration_Unit__c;
            clItem.Duration__c = (contractMap.get(clItem.ServiceContractId).Duration__c != null ?
                                        decimal.valueOf(contractMap.get(clItem.ServiceContractId).Duration__c) : null);
            
            clItem.Contract_Template__c  = contractMap.get(clItem.ServiceContractId).Contract_Template__c ;
        }
    }

    /*------------------------------------------------------------------------
    Author:        Amit Shingavi
    Company:       Salesforce
    Description:   Ingore the price changes from LN
    Inputs:        map of updated records
    Test Class:   

    History
    19-01-2020      Amit Shingavi    Initial Draft
    ----------------------------------------------------------------------------*/
    public void IgnorethePriceChangesFromLN(Map<Id,ContractLineItem> newItems,Map<Id,ContractLineItem> oldItems){
        
        try{
            List<ContractLineItem> cliLst = new List<ContractLineItem>();
            system.debug(newItems.keySet());
            List<User> userList = [SELECT Profile.Name FROM User WHERE id =: UserInfo.getUserId()];
            if(userList[0].Profile.Name == System.Label.Integration_User_Profile_Name){
                for(ContractLineItem scItr : [SELECT Id, ListPrice,UnitPrice  
                                            FROM ContractLineItem 
                                            WHERE Id IN: newItems.keySet()] 
                                            ){
                    newItems.get(scItr.Id).UnitPrice = oldItems.get(scItr.Id).UnitPrice;
                }
            }
            update cliLst;
        }catch(Exception ex){
            system.debug('Exception Message : '+ex.getMessage());
            Logger.logError('CLIRecordProcessor', 'IgnorethePriceChangesFromLN', null, ex);
        }
    }
    
     /*------------------------------------------------------------------------
    Author:        Amit Shingavi
    Company:       Salesforce
    Description:   Tag pricebook entry based on the tyep of contract, 
                   this is required for the Service Contract flowing from Infor
    Inputs:        map of updated records
    Test Class:   

    History
    19-01-2020      Amit Shingavi    Initial Draft
    ----------------------------------------------------------------------------*/
    public void populatePriceBookEntryForIntegrationUser(List<ContractLineItem> contractLineItems) {
        try{
            List<User> userList = [SELECT Profile.Name FROM User WHERE id =: UserInfo.getUserId()];

            if(userList[0].Profile.Name == System.Label.Integration_User_Profile_Name){
                
                Map<String,String> productItemCode = new Map<String,String>{
                    'PMC' => 'Bronze_PH_INF_INT', 
                    'CMT' => 'Titanium_PH_INF_INT',
                    'CMP' => 'Platinum_PH_INF_INT', 
                    'CMG' => 'Gold_PH_INF_INT', 
                    'EWP' => 'Silver_PH_INF_INT',
                    'CMD' => 'Diamond_PH_INF_INT'   

                };
                
                Map<String,Id> contractTypePricebookEntry = new Map<String,Id>();
                for(PricebookEntry contractPricebook : [SELECT Id, Product2.Item__c 
                                                         FROM PricebookEntry 
                                                        WHERE Pricebook2.Name =: System.Label.MHE_SF_Local_Contract_PB AND
                                                              Product2.Item__c IN: productItemCode.values()]){
                    contractTypePricebookEntry.put(contractPricebook.Product2.Item__c,contractPricebook.Id);                                                   
                }
                Set<Id> serviceContractIds = new Set<Id>();
                
                for(ContractLineItem cliItr : contractLineItems){
                    serviceContractIds.add(cliItr.ServiceContractId);
                }
                
                Map<Id,ServiceContract> srcMap = new Map<Id,ServiceContract>([SELECT Contract_Type__c 
                                                                                FROM ServiceContract 
                                                                                WHERE Id IN: serviceContractIds]);

                for(ContractLineItem cliItr : contractLineItems){
                    String contractType = srcMap.get(cliItr.ServiceContractId).Contract_Type__c;

                    String productCode = !String.isBlank(contractType) && productItemCode.containsKey(contractType) ? 
                                          productItemCode.get(contractType) : '';
                    if(!String.isBlank(productCode) &&
                        contractTypePricebookEntry.containsKey(productCode) 
                    ){
                        cliItr.pricebookEntryId = contractTypePricebookEntry.get(productCode);
                        cliItr.Quantity = 1;
                    }
                } 
            }
        }catch(Exception ex){
            system.debug('Exception Message :'+ ex.getMessage());
            Logger.logError('CLIRecordProcessor', 'populatePriceBookEntryForIntegrationUser', null, ex);
        }        
    }  
}