@isTest
public with sharing class SalesAckowledgementControllerTest{
    
    @TestSetup static void createData(){
        Test.startTest();
        
        Profile userProfile = [Select Id from Profile where Name = 'System Administrator' LIMIT 1];
        // Create User record.
        User userToRun = new User(EmailEncodingKey = 'UTF-8', firstName = 'Test', lastname = 'User', Alias = 'tuser',
                                  languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = userProfile.id,
                                  timezonesidkey = 'Asia/Kolkata', email = 'test.userSAC@godrej.com', username = 'test.userSAC@godrej.com', Business_Unit__c = GlobalConstants.MHE_DIVISION_CODE);
        
        userToRun.Sub_Division__c = 'B2B';
        userToRun.Logistic_Company__c = '2000';
        userToRun.Area_Code__c = 'WN1';
        insert userToRun;
        
        System.runAs(userToRun) { 
            
            Discount_Matrix__c defaultDiscountMatrix=new Discount_Matrix__c(Name='No Discount',Discount_Code__c='HDH',
                                                                            Start_Date__c=System.Today(),End_Date__c=System.Today(),
                                                                            Gross_Net__c='1', Level__c='2', Stage__c='Active');
            Insert defaultDiscountMatrix; 
            
            PriceBook2 standardPriceBook = new PriceBook2(Id = Test.getStandardPricebookId(), LN_PriceList_Code__c = 'ST', PriceList_Code__c = 'ST');
            update standardPriceBook;
            
            PriceBook2 rentalPriceBook = new PriceBook2(Name = System.Label.MHE_SF_Local_Rental_PB, IsActive = true, LN_PriceList_Code__c = 'REN', PriceList_Code__c = 'REN');
            insert rentalPriceBook;
            
            List<Product2> allProducts = new List<Product2> {
                new TestProductBuilder().setName('GX 300').setDescription('GX 300 Forklift').setItemCode('GX1').setComponentType('Base Product').setCommodityCode('R18VII').getTestRecord(),
                    new TestProductBuilder().setName('GX 300 Attachment').setItemCode('GX2').setDescription('GX 300 Forklift Attachment').setComponentType('Attachments').setCommodityCode('R18VII').getTestRecord(),
                    new TestProductBuilder().setName('Operator - Delhi').setItemCode('GX3').setDescription('Operator').setComponentType('Operator').setCommodityCode('R18VII').getTestRecord(),
                    new TestProductBuilder().setName('Technician - Delhi').setItemCode('GX4').setDescription('Technician').setComponentType('Technician').setCommodityCode('R18VII').getTestRecord(),
                    new TestProductBuilder().setName('Supervisor - Delhi').setItemCode('GX5').setDescription('Supervisor').setComponentType('Supervisor').setCommodityCode('R18VII').getTestRecord()
                    };
                        insert allProducts;
            
            List<PriceBookEntry> allPBEs = new List<PriceBookEntry> {
                new TestPriceBookEntryBuilder().setProduct2Id(allProducts[0].Id).setPricebook2Id(rentalPriceBook.Id).setUnitPrice(50000).getTestRecord(),
                    new TestPriceBookEntryBuilder().setProduct2Id(allProducts[1].Id).setPricebook2Id(rentalPriceBook.Id).setUnitPrice(3000).getTestRecord(),
                    new TestPriceBookEntryBuilder().setProduct2Id(allProducts[2].Id).setPricebook2Id(rentalPriceBook.Id).setUnitPrice(30000).getTestRecord(),
                    new TestPriceBookEntryBuilder().setProduct2Id(allProducts[3].Id).setPricebook2Id(rentalPriceBook.Id).setUnitPrice(32000).getTestRecord(),
                    new TestPriceBookEntryBuilder().setProduct2Id(allProducts[4].Id).setPricebook2Id(rentalPriceBook.Id).setUnitPrice(32000).getTestRecord()
                    };
                        insert allPBEs;
            
            Address__c addr = createPrimaryAddress();
            insert addr;
            
            Account accountRecord = new TestAccountBuilder()
                .setName('TEST ACCOUNT')
                .setRecordTypeId(Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business_Account').getRecordTypeId())
                .getSavedTestRecord();
            accountRecord.Primary_Address__c = addr.id;
            accountRecord.Business_Unit__c = 'K';
            update accountRecord;
            
            list<ZipCode__c> ZipCodesToCreate = new list<ZipCode__c>();
            list<Address__c> AddressesToCreate = new list<Address__c>();
            //Create Zip Code Data
            for(Integer i = 1; i<3; i++){
                ZipCode__c zipCode = new ZipCode__c();
                if(i == 1){
                    zipCode.Name = '410002';
                    zipCode.CityCode__c = 'PUNE';
                    zipCode.City_Name__c = 'PUNE';
                    zipCode.StateCode__c = 'MH';
                    zipCode.StateName__c = 'Maharashtra';
                    zipCode.CountryCode__c = 'IN';   
                    zipCode.CountryName__c = 'INDIA';   
                    zipCode.ZipCodeExternalId__c = 'IN_410002';
                } else {
                    zipCode.Name = '110008';
                    zipCode.CityCode__c = 'Delhi';
                    zipCode.City_Name__c = 'DELHI';
                    zipCode.StateCode__c = 'DL';
                    zipCode.StateName__c = 'Delhi';
                    zipCode.CountryCode__c = 'IN';   
                    zipCode.CountryName__c = 'INDIA';   
                    zipCode.ZipCodeExternalId__c = 'IN_110008';
                }
                
                ZipCodesToCreate.add(zipCode);
            }
            insert ZipCodesToCreate;
            Test.stopTest();
            
        
        //Create Address records
        for(Integer i = 1; i<3; i++){
            Address__c address = new Address__c();
                address.Address_Type__c = 'B2B';
                address.Address_Format__c = 'ADR';
            if(i == 1){
                address.Name__c = 'NUVOCO LIMITED';
                address.Telephone__c = '8765432111';
                address.Email__c = 'punetest1234@nuvoco.com';
                address.ZipCode__c = ZipCodesToCreate[0].Id;
            } else {
                address.Name__c = 'NUVOCO LIMITED';
                address.Telephone__c = '8765432110';
                address.Email__c = 'delhitest1234@nuvoco.com';
                address.ZipCode__c = ZipCodesToCreate[1].Id;
            }
            AddressesToCreate.add(address);
        }
        insert AddressesToCreate;
            
            //Create Account
            Account acc = new Account();
            acc.Name = 'NUVOCO LIMITED';
            acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Dealer').getRecordTypeId();
            acc.PAN__c = 'ASDFG0987Z';
            acc.Business_Unit__c = 'K'; //MHE division
            acc.Primary_Address__c = AddressesToCreate[0].Id;
            acc.Business_Partner_Status__c = 'Open';
            acc.One_Time_Business_Partner__c = 'No';
            
            insert acc;
            
            //Create Tax Number record
            Tax_Number__c tax = new Tax_Number__c();
            tax.Business_Partner__c = acc.Id;
            tax.Country__c = 'IND';
            tax.Tax_Number__c = 'AASCS6585A';
            tax.Category__c = 'PAN';
            tax.Tax_Number_Ext__c = 'WDX001015___PAN_AASCS6585A';
            
            insert tax;
            
            //Create Branch
            Branch__c branch = new Branch__c();
            branch.Business_Partner__c = acc.Id;
            branch.Business_Partner_Status__c = 'Open';
            branch.Business_Partner_Status_Ship_To__c = 'Open';
            branch.Branch_Name__c = '5020';
            branch.Line_of_Business__c = 'AGRO';
            branch.Area__c = 'WN1';
            branch.Ship_To_Address__c = AddressesToCreate[0].Id;
            branch.Sold_To_Address__c = AddressesToCreate[0].Id;
            
            insert branch;
            
            Address_by_BP__c shipToAddress = createShipToAddress(branch, acc, AddressesToCreate);
            insert shipToAddress;
            
            Opportunity oppRecord = new TestOpportunityBuilder()
                .setRecordTypeId(Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('MHE_Rental').getRecordTypeId())
                .setMHEDivision('Godrej RenTRUST').getSavedTestRecord();
            
            User usrWithSal = new User(UserRoleId = UserInfo.getUserRoleId(), ProfileId = UserInfo.getProfileId(), Account__c = accountRecord.id, 
                                       Alias = 'hasrole', Email='userwithrole@godrej.com', Salary_Code__c = 'tst1231231',
                                       EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',LocaleSidKey='en_US',
                                       TimeZoneSidKey='America/Los_Angeles',Username = 'test12345_gnbtest@godrej.com',CommunityNickname = 'test12345'); 
            insert usrWithSal;
           
            
            
            List<Order> orderRecords = createOrderRecords(1, accountRecord, oppRecord, shipToAddress, usrWithSal, rentalPriceBook);
            insert orderRecords;
           
            
            
            List<Tax_Number__c> taxNumbers=createTaxRecords(acc,AddressesToCreate[0]);
            insert taxNumbers;
            
            List<OrderItem> orderItems = createOrderItems(orderRecords, allPBEs);
            insert orderItems;
            
            List<Advance_Payment_Details__c> advPaymentRecords = createAdvPaymentRecords(orderRecords);
            insert advPaymentRecords; 
        }
        
    }
    
    private static List<Order> createOrderRecords(Integer noOfRecords, Account accountRecord, Opportunity oppRecord, Address_by_BP__c shipToAddress, User usr, PriceBook2 pb) {
        
        List<Order> orderRecords = new List<Order>();
        for(Integer i=1; i<=noOfRecords; i++) {
            Order orderRecord = new Order();
            orderRecord.Sold_to_Business_Partner__c=accountRecord.Id;
            orderRecord.AccountId = accountRecord.Id;
            orderRecord.Order_Amount__c = 100000 + (1000*i) + 350.75;
            orderRecord.EffectiveDate = Date.today();
            orderRecord.Status = 'Draft';
            orderRecord.opportunityId = oppRecord.id;
            orderRecord.Ship_To_Address__c = shipToAddress.id;
            orderRecord.Sold_To_Address__c = shipToAddress.id;
            orderRecord.Internal_Sales_Representative__c = usr.id;
            orderRecord.Intent__c = 'True';
            orderRecord.Pricebook2Id = pb.id;
            orderRecord.Business_Unit__c = 'K';
            orderRecords.add(orderRecord);
        }
        
        return orderRecords;
         
    }
    
    private static List<Tax_Number__c> createTaxRecords(Account accountRecord, Address__c addressRec) {
        List<Tax_Number__c> taxRecs=new List<Tax_Number__c>(); 
        Tax_Number__c taxRec=new Tax_Number__c();
        taxRec.Business_Partner__c = accountRecord.Id;
        taxRec.Address_Code__c = addressRec.Id;
        taxRec.Tax_Number__c='23AASCS6585A23D';
        taxRec.Category__c='GSTIN';
        taxRec.Effective_Date__c=System.today().addDays(4);
        taxRecs.add(taxRec);
        Tax_Number__c storeTaxRec=new Tax_Number__c();
        storeTaxRec.Business_Partner__c=accountRecord.Id;
        storeTaxRec.Address_Code__c = addressRec.Id;
        storeTaxRec.Tax_Number__c='23AASCS6585A23H';
        storeTaxRec.Category__c='GSTIN';
        storeTaxRec.Effective_Date__c=System.today().addDays(4);
        storeTaxRec.Sequence_Number__c='3';
        taxRecs.add(storeTaxRec);
        return taxRecs;
    }
    
    private static List<OrderItem> createOrderItems(List<Order> orders, List<priceBookEntry> pbe){
        List<OrderItem> orderItems = new List<OrderItem>();
        OrderItem oitem = new OrderItem(Orderid = orders[0].id, PricebookEntryId = pbe[0].id, Quantity = 1, UnitPrice = 50000);
        orderItems.add(oitem);
        return orderItems;
    }
    
    private static List<Advance_Payment_Details__c> createAdvPaymentRecords(List<Order> orderRecords) {
        List<Advance_Payment_Details__c> advPaymentDetails = new List<Advance_Payment_Details__c>();
        Integer i=1;
         
        for(Order orderRecord : orderRecords) {
            Advance_Payment_Details__c apd = new Advance_Payment_Details__c();
            apd.Amount__c = Decimal.valueOf(500*i);
            apd.Payment_Date__c = Date.today();
            apd.Payment_Mode__c = i == 1 ? 'Others' : i/2 == 0 ? 'Others' : 'Others';
            apd.Mode_of_Advance_Payment__c=i == 1 ? 'Cash' : i/2 == 0 ? 'Card' : 'Cheque';
            apd.Bank_Provider_Name__c = apd.Payment_Mode__c != 'Others' ? 'Axis Bank' : 'Axis Bank';
            apd.Reference_Number__c = apd.Payment_Mode__c != 'Others' ? 'REF-'+String.valueOf(i) : 'REF-'+String.valueOf(i);
            apd.Credit_Debit_Card_Approval_Code__c='mkaka';
            apd.Credit_Card_Last_four_digits__c='7617';
            apd.Order__c = orderRecord.Id;
            system.debug('orderRecord'+orderRecord.Id);
            //apd.Type_of_Transaction__c='Advance';
            //apd.Batch_Reference_Number__c='123';
            advPaymentDetails.add(apd);
            i+=1;
        }
         
        return advPaymentDetails;
    }
    
    private static Address__c createPrimaryAddress(){
        ZipCode__c zipcd = new ZipCode__c(City_Name__c ='citytst', StateName__c = 'sttetst', name='zpcdtst');
        insert zipcd;
        Address__c addr = new Address__c(Name__c = 'TEST ACCOUNT', Street__c='strttst',ZipCode__c = zipcd.id);
        return addr;
    }
    
    private static Address_by_BP__c createShipToAddress(Branch__c branch, Account accRecord, List<Address__c> addressesToCreate){
         Address_by_BP__c shipToAdd = new Address_by_BP__c();
            shipToAdd.Account__c = accRecord.Id;
            shipToAdd.Branch__c = branch.Id;
            shipToAdd.isPrimary__c = true;
            shipToAdd.Address_Code__c = addressesToCreate[0].Id;
            shipToAdd.Ship_To__c = true;
            shipToAdd.Sold_To__c = true;
            shipToAdd.Branch_Name__c = '5020';
         return shipToAdd;
    }
    
    @isTest private static void SalesAcknowledgementControllerShouldReturnSalesData() {
         Test.startTest();
        String URL;
             
        Order ordRec = [Select id,Name,Sales_Type__c,Internal_Sales_Representative__r.Account__c,Internal_Sales_Representative__c,Ship_To_Address__r.Address_Code__r.House_Number__c,RecordType.DeveloperName,
                                 Sold_to_Business_Partner__r.Name,Ship_To_Address__r.Address_Code__r.City__c,Ship_To_Address__r.Address_Code__r.Country__c,
                                 Ship_To_Address__r.Address_Code__r.Building__c,Ship_To_Address__r.Address_Code__r.Floor__c,Ship_To_Address__r.Address_Code__r.Street__c,
                                 Logistics_Company_Branch__c,Ship_To_Address__r.Address_Code__r.State_Province__c,Ship_To_Address__r.Address_Code__r.ZipCode__r.Name,
                                 Sold_to_Business_Partner__r.PersonMobilePhone,Internal_Sales_Representative__r.Salary_Code__c,Planned_Delivery_Date__c,
                                 Internal_Sales_Representative__r.Name,Payment_Terms__c,Sold_to_Business_Partner__r.CIN__c,Sold_To_Business_Partner__r.PersonEmail,
                                 Ship_To_Address__r.Name__c,Sold_To_Address__r.Address_Code__r.City__c,Sold_To_Address__r.Address_Code__r.Country__c,Sold_To_Address__r.Address_Code__r.State_Province__c,
                                 Sold_To_Address__r.Address_Code__r.Building__c,Sold_To_Address__r.Address_Code__r.Floor__c,Sold_To_Address__r.Address_Code__r.Street__c,
                                 Sold_To_Address__r.Address_Code_Ext__c,OrderReferenceNumber,CreatedDate,Customer_Order__c,WarehouseCode__r.Warehouse__c,Scheme_Code__r.Name,
                                 Scheme_Code__r.Description__c,Delivery_Terms_C__c,Total_Advance_Amount__c,Total_Due_Amount__c,Sales_Classification__c,Internal_Sales_Representative__r.Email,
                                 Sold_To_Address__r.Address_Code__r.House_Number__c,Sold_To_Address__r.Address_Code__r.ZipCode__r.Name,Reference_A__c,Reference_B__c,Sold_To_Address__r.Address_Code__c, Ship_To_Address__r.Address_Code__r.StateName__c,
                                 Account.PersonMobilePhone,Ship_To_Address__r.Address_Code__c,
                                 Sold_to_Business_Partner__r.GSTN__c,
                                 Sold_to_Business_Partner__r.Effective_Date_GSTN__c from Order LIMIT 1];
        
       	ordRec.Sales_Type__c='Primary';  
        User usr = [Select id, Account__c from User WHERE username =: 'test12345_gnbtest@godrej.com'];
        
        PageReference pref = Page.InterioSalesAcknowledgement;
        System.runAs(usr){
            
            pref.getParameters().put('orderId', ordRec.id);
            Test.setCurrentPage(pref);
            SalesAcknowledgementController sack = new SalesAcknowledgementController();
            
            
           
            URL = '/apex/interiosalesacknowledgement?orderId=' + ordRec.id;
            
        }
        System.assertEquals(pref.getUrl(), URL); 
        Test.stopTest();
    }
}