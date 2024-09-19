@isTest
public class BranchRecordHandlerTest {
    
    @TestSetup static void createData(){
        
         Profile userProfile = [Select Id from Profile where Name = 'System Administrator' LIMIT 1];
        // Create User record.
        User userToRun = new User(EmailEncodingKey = 'UTF-8', firstName = 'Test', lastname = 'User', Alias = 'tuser',
                            languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = userProfile.id,
                            timezonesidkey = 'Asia/Kolkata', email = 'test.user@godrej.com', username = 'test.user@godrej.com', Business_Unit__c = GlobalConstants.MHE_DIVISION_CODE);

        userToRun.Persona__c = 'MHE Sales-KAM';
        userToRun.Sub_Division__c = 'B2B';
        userToRun.Logistic_Company__c = '2000';
        userToRun.Area_Code__c = 'WN1';
        insert userToRun;
        Sales_Office__c salesOffice;
        System.runas(userToRun){
           salesOffice = insertSalesOffice();
           List<Address__c> addresses=insertAddressRecords();
           Account acct=insertAccount(addresses[0].Name__c=='Test address1'.toUpperCase()?addresses[0]:addresses[1]); 
        }
        userToRun.Sales_Office__c=salesOffice.LN_Sales_Office_Code__c;
        update userToRun;
        
    }
    
    public static Sales_Office__c insertSalesOffice(){
        Sales_Office__c salesoffice=new Sales_Office__c();
        salesoffice.Name='test Sales Office';
        salesoffice.LN_Sales_Office_Code__c='SO1';
        insert salesoffice;
        return salesoffice;
    }
    
    public static List<Address__c> insertAddressRecords(){
        List<Address__c> addresses=new List<Address__c>();
        Address__c address1=new Address__c();
        address1.Name__c='Test address1'.toUpperCase();
        address1.Address_Type__c='B2C';
        address1.Telephone__c='6677664565';
        addresses.add(address1);
        Address__c address2=new Address__c();
        address2.Name__c='Test address2'.toUpperCase();
        address2.Address_Type__c='B2C';
        address2.Telephone__c='6677645565';
        address2.building__c ='VIKHROLI-WEST';
        addresses.add(address2);
        insert addresses;
        return addresses;
    }
    
    public static Account insertAccount(Address__c primaryAddress){
        Account acc=new Account();
        acc.Primary_Address__c=primaryAddress.Id;
        acc.Name=primaryAddress.Name__c;
        insert acc;
        return acc;
    }
    
    @isTest public static void salesOfficeAndAreaCodeShouldPopulateOnBranch(){
        User userToRun=[Select Id from User Where Sales_Office__c='SO1' Limit 1];
        System.runAs(userToRun){
            Branch__c branch=new Branch__c();
            test.startTest();
            insert branch;
            Branch__c insertedBranch=[Select Sales_Office__c From Branch__c Limit 1];
            test.stopTest();
            System.assertNotEquals(null,insertedBranch.Sales_Office__c);
        }
    }
    
    @isTest public static void soldToAddressShouldBePopulated(){
        User userToRun=[Select Id from User Where Sales_Office__c='SO1' Limit 1];
        List<Address__c> addresses=[Select Id,Name__c From Address__c];
        Account acct=[Select Id From Account Limit 1];
        List<Branch__c> branchesToInsert=new List<Branch__c>();
        System.runAs(userToRun){
            Branch__c branch1=new Branch__c();
            branch1.Business_Partner__c=acct.Id;
            branch1.Ship_To_Address__c=addresses[0].Name__c=='Test address2'?addresses[0].Id:addresses[1].Id;
            branchesToInsert.add(branch1);
            test.startTest();
            insert branchesToInsert;
            test.stopTest();
         }
         Branch__c branch=[Select Sold_To_Address__c From Branch__c Limit 1];
         System.assertNotEquals(null,branch.Sold_To_Address__c);
    }
    
    
    @isTest public static void addressByBpRecordsShouldGetInserted(){
        User userToRun=[Select Id from User Where Sales_Office__c='SO1' Limit 1];
        List<Address__c> addresses=[Select Id,Name__c From Address__c];
        Account acct=[Select Id From Account Limit 1];
        List<Branch__c> branchesToInsert=new List<Branch__c>();
        System.runAs(userToRun){
            Branch__c branch1=new Branch__c();
            branch1.Business_Partner__c=acct.Id;
            branch1.Ship_To_Address__c=addresses[0].Name__c=='Test address1'.toUpperCase()?addresses[0].Id:addresses[1].Id;
            Branch__c branch2=new Branch__c();
            branch2.Business_Partner__c=acct.Id;
            branch2.Sold_To_Address__c=addresses[0].Name__c=='Test address1'.toUpperCase()?addresses[0].Id:addresses[1].Id;
            Branch__c branch3=new Branch__c();
            branch3.Business_Partner__c=acct.Id;
            branchesToInsert.add(branch1);
            branchesToInsert.add(branch2);
            branchesToInsert.add(branch3);
            test.startTest();
            Insert branchesToInsert;
            BranchRecordHandler branchHandler=new BranchRecordHandler();
            branchHandler.createAddressByBPRecords(branchesToInsert);
            test.stopTest();
         }
         List<Address_By_BP__c> addressByBpRecords=[Select Id From Address_By_BP__c];
         System.assertNotEquals(0,addressByBpRecords.size());
    }
    
     @isTest public static void addressByBpRecordsShouldNotGetInserted(){
        User userToRun=[Select Id from User Where Sales_Office__c='SO1' Limit 1];
        List<Address__c> addresses=[Select Id,Name__c From Address__c];
        Account acct=[Select Id From Account Limit 1];
        System.runAs(userToRun){
            Branch__c branch1=new Branch__c();
            branch1.Ship_To_Address__c=addresses[0].Name__c=='Test address2'?addresses[0].Id:addresses[1].Id;
            test.startTest();
            Insert branch1;
            test.stopTest();
         }
         List<Address_By_BP__c> addressByBpRecords=[Select Id From Address_By_BP__c];
         System.assertEquals(0,0);
    }
    
    @isTest public static void soldToShipToShouldBeFalseForPrimary(){
        User userToRun=[Select Id from User Where Sales_Office__c='SO1' Limit 1];
        List<Address__c> addresses=[Select Id,Name__c From Address__c];
        Account acct=[Select Id From Account Limit 1];
        System.runAs(userToRun){
            Branch__c branch1=new Branch__c();
            branch1.Business_Partner__c=acct.Id;
            branch1.Ship_To_Address__c=addresses[0].Name__c=='Test address2'?addresses[0].Id:addresses[1].Id;
            test.startTest();
            Insert branch1;
            branch1.Ship_To_Address__c=addresses[0].Name__c=='Test address1'?addresses[0].Id:addresses[1].Id; 
            Update branch1;
            List<Address_By_BP__c> abp=[Select Id,Ship_To__c,Sold_To__c From Address_By_BP__c where isPrimary__c=true 
                                  And Ship_To__c=false And Sold_To__c=false];
            test.stopTest();
            System.assertEquals(1,abp.size());
         }
    }
    
    @isTest public static void soldToTrueShipToFalseForPrimary(){
        User userToRun=[Select Id from User Where Sales_Office__c='SO1' Limit 1];
        List<Address__c> addresses=[Select Id,Name__c From Address__c];
        Account acct=[Select Id From Account Limit 1];
        System.runAs(userToRun){
            Branch__c branch1=new Branch__c();
            branch1.Business_Partner__c=acct.Id;
            branch1.Ship_To_Address__c=addresses[0].Name__c=='Test address1'?addresses[0].Id:addresses[1].Id;
            test.startTest();
            Insert branch1;
            branch1.Ship_To_Address__c=addresses[0].Name__c=='Test address2'?addresses[0].Id:addresses[1].Id; 
            Update branch1;
            List<Address_By_BP__c> abp=[Select Id,Ship_To__c,Sold_To__c From Address_By_BP__c where isPrimary__c=true 
                                  And Ship_To__c=false And Sold_To__c=true];
            test.stopTest();
            System.assertEquals(1,abp.size());
         }
    }
    
    @isTest public static void soldToShipToShouldBeTrueForPrimary(){
        User userToRun=[Select Id from User Where Sales_Office__c='SO1' Limit 1];
        List<Address__c> addresses=[Select Id,Name__c From Address__c];
        Account acct=[Select Id From Account Limit 1];
        System.runAs(userToRun){
            Branch__c branch1=new Branch__c();
            branch1.Business_Partner__c=acct.Id;
            branch1.Ship_To_Address__c=addresses[0].Name__c=='Test address1'.toUpperCase()?addresses[0].Id:addresses[1].Id;
            test.startTest();
            Insert branch1;
            branch1.Ship_To_Address__c=addresses[0].Name__c=='Test address1'.toUpperCase()?addresses[0].Id:addresses[1].Id; 
            branch1.Sold_To_Address__c=addresses[0].Name__c=='Test address1'.toUpperCase()?addresses[0].Id:addresses[1].Id; 
            Update branch1;
            List<Address_By_BP__c> abp=[Select Id,Ship_To__c,Sold_To__c From Address_By_BP__c where isPrimary__c=true 
                                  And Ship_To__c=true And Sold_To__c=true];
            test.stopTest();
            System.assertEquals(1,abp.size());
         }
    }

}