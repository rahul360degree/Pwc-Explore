@isTest
public class CreateSecondaryAddressAndABPTest {
     @testsetup
    private static void testData() {
        Profile profile = [SELECT Id FROM Profile WHERE Name =:GlobalConstants.SYSTEM_ADMIN_PROFILE_NAME];
            User contextuser = new TestUserBuilder().setProfileId(profile.Id)
                .setBusinessUnit(GlobalConstants.Locks_BUSINESS_UNIT).setSalaryCode('25389')                
                .setPersona(GlobalConstants.locks_bde_persona)
                .setLastName('Locks BDE User')
                .getSavedTestRecord();
            
            System.runAs(contextuser) {
                Account acc = new TestAccountBuilder()
                .setRecordTypeId(Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business_Account').getRecordTypeId())
                .setBusinessUnit(GlobalConstants.Locks_BUSINESS_UNIT)
                .getSavedTestRecord();
                
                ZipCode__c zipCode = new ZipCode__c();
                zipCode.Name = '410002';
                zipCode.CityCode__c = 'PUNE';
                zipCode.City_Name__c = 'PUNE';
                zipCode.StateCode__c = 'MH';
                zipCode.StateName__c = 'Maharashtra';
                zipCode.CountryCode__c = 'IN';   
                zipCode.CountryName__c = 'INDIA';   
                zipCode.ZipCodeExternalId__c = 'IN_410002';
                insert zipCode;
                
                Address__c address=new Address__c();
                address.Name__c='Test address2'.toUpperCase();
                address.Address_Type__c='B2B';
                address.Telephone__c='6677645565';
                address.building__c ='VIKHROLI-WEST';
                insert address;
                
                Set<String> branchNameSet=new Set<String>{'1000','1030','5010','5020'};
                List<Branch__c> branchListToInsert=new List<Branch__c>();
                for(String branchName : branchNameSet){
                    Branch__c branchRec = new Branch__c();
                    branchRec.Business_Partner__c=acc.Id;
                    branchRec.Ship_To_Address__c=address.Id;
                    branchRec.Sold_To_Address__c=address.Id;
                    branchRec.Branch_Name__c=branchName;
                    branchListToInsert.add(branchRec);
                }
                insert branchListToInsert;
            }
        }
    
        static testMethod void testCreateSecondaryAddressAndABP(){
            Test.startTest();  
                List<Branch__c> branchList =[Select ID,Branch_Name__c,Business_Partner__c,Business_Partner__r.Name FROM Branch__c limit 10];
                List<ZipCode__c> zipCodeList =[Select ID,Name FROM ZipCode__c limit 10];
                User adminUser = [Select Id,LastName From User where LastName='Locks BDE User' Limit 1];  
                List<QuoteLineItem> qliList=new List<QuoteLineItem>();
                System.runAs(adminUser){
                    List<Address__c> addressList=new List<Address__c>();
                    Address__c address=new Address__c();
                    address.Name__c=branchList[0].Business_Partner__r.Name;
                    address.Address_Type__c='B2B';
                    address.building__c ='Test Building';
                    address.Account_Name__c=branchList[0].Business_Partner__c;
                    address.Address_Format__c='ADR';
                    address.Pincode__c='410002';
                    addressList.add(address);
                   
                    List<CreateSecondaryAddressAndABP.MethodParameter> parameterList=new List<CreateSecondaryAddressAndABP.MethodParameter>();
                    CreateSecondaryAddressAndABP.MethodParameter parameter=new CreateSecondaryAddressAndABP.MethodParameter();
                    parameter.addressList=addressList;
                    parameter.zipcodeList=zipCodeList;
                    parameter.branchList=branchList;
                    parameterList.add(parameter);
                    
                    CreateSecondaryAddressAndABP.createAddressAndABP(parameterList);
                }
            Test.stopTest();
        }
}