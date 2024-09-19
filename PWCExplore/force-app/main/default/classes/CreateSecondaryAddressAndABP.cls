public class CreateSecondaryAddressAndABP {
	@InvocableMethod(label='CreateSecondaryAddress' description='Create Secondary Address And ABP')
    public static void createAddressAndABP(List<MethodParameter> parameters ) {
        try{ 
                List<Address__c> addressList=new List<Address__c>();
        		List<Zipcode__c> zipcodeList=new List<Zipcode__c>();
        		List<Branch__c> branchList=new List<Branch__c>();
           		Map<String,String> zipcodeMap=new Map<String,String>();
                List<Address__c> addressListToInsert=new List<Address__c>();
            	List<Address_by_BP__c> addressByBpListToInsert=new List<Address_by_BP__c>();
        		addressList=parameters[0].addressList;
        		zipcodeList=parameters[0].zipcodeList;
        		branchList=parameters[0].branchList;
            
        	for(Zipcode__c zipcode: zipcodeList){
                zipcodeMap.put(zipcode.Name,zipcode.Id);
            }
            
            integer count=0;
            for(Address__c address : addressList){
                if(count < 50){
                    if(zipcodeMap.containsKey(address.Pincode__c)){                    
                        address.ZipCode__c=zipcodeMap.get(address.Pincode__c);                    
                    }
                    addressListToInsert.add(address);
                }
            }
            insert addressListToInsert;
            
            for(Address__c secondaryAddress : addressListToInsert){
                
                for(Branch__c branchRec : branchList){
                    if(branchRec.Branch_Name__c!=GlobalConstants.Sales_Branch_1000 && branchRec.Branch_Name__c!=GlobalConstants.Sales_Branch_1030){
                        Address_by_BP__c addByBpRec=new Address_by_BP__c();
                        addByBpRec.Account__c=secondaryAddress.Account_Name__c;
                        addByBpRec.Branch__c=branchRec.Id;
                        addByBpRec.Address_Code__c=secondaryAddress.id;
                        addByBpRec.Sold_To__c=true;
                        addByBpRec.Ship_To__c=true;
                        addByBpRec.isPrimary__c=false;
                        addressByBpListToInsert.add(addByBpRec);
                    }                    
                }
            }
            insert addressByBpListToInsert;
            
            }catch (Exception ex) {
                Logger.logError('CreateSecondaryAddressAndABP', 'CreateSecondaryAddress', '', ex);
            }  
    }
    
    public class MethodParameter {        
        @InvocableVariable(required=true)
        public List<Address__c> addressList;
        
        @InvocableVariable(required=true)
        public List<Zipcode__c> zipcodeList;
        
        @InvocableVariable(required=true)
        public List<Branch__c> branchList;
    }
}