/*------------------------------------------------------------------------------------
* Author        :        Stetig Consulting
* Description   :        Test methods for controller print the termsheet
*                          talking sheet and calculation shset
* History
* --------
* 02-12-2021     :    Initial Release
* ----------------------------------------------------------------------------------*/
@isTest
public with sharing class TestLeasingOutputTemplates {
    static testmethod void termsheetViewCalculationSheetView() {
        
        String accId = LeaseTestDataFactory.createAccount();
        String conId = LeaseTestDataFactory.createContact(accId);
        PageReference pageRef = Page.createHOT;
        Test.setCurrentPage(pageRef);
        Id leasingUserId = LeaseTestDataFactory.createLeasingUser();
        User u = [Select Id from User where Id =: leasingUserId];
        System.RunAs(u) {
            
            String oppId = LeaseTestDataFactory.createOpportunity(accId);
            String hotId = LeaseTestDataFactory.createHOT(oppId);
            LeaseTestDataFactory.createStandardTermClauses();
            LeaseTestDataFactory.tagPremise(hotId,oppId);
            List<Junction_Unit__c> juList = [Select Id from Junction_Unit__c where Opportunity__c = :oppId and Head_Of_Terms__c =:hotId];
            system.assertEquals(2, juList.size());
            test.StartTest();
            ApexPages.currentPage().getParameters().put('HoTID',hotId); 
            CreateHoT cht=new CreateHot(); 
            cht.HOT.Notice_Period_For_Termination_Licensor__c = 60;
            cht.HOT.Notice_Period_For_Termination_Licensee__c = 60;
            cht.HOT.Leasing_Term__C = 87;
            cht.HOT.Carpark_Ratio__c = 1000;
            cht.HOT.Rent_escalation_structure__c = '';
            cht.HOT.Lock_in_period_in_months__c = 60;
            cht.HOT.Rent_per_sq_ft_monthly__c = 120;
            cht.HOT.Security_Deposit_Calculation_Type__c ='Simple';
            cht.HOT.Security_Deposit_Number_of_months__c = 9;
            cht.HOT.Security_Deposit__c = 20000;
            cht.HOT.Renewal_Terms__c = 48;
            cht.HOT.Terms_of_payment_CAM_fee__c = '7th of every month';
            cht.HOT.Terms_of_payment_license_fee__c = '1st of every month';
            cht.HOT.Compensation_free_period__c = 3;
            cht.HOT.Chareable_Carpark__c = 50;
            cht.HOT.Per_carpark_charge__c = 4000;
            cht.HOT.Validity_in_Days__c = 15;
            cht.generate();
            cht.updateData();
            cht.createHOT();
            List<Head_Of_Terms__c> htList = [select Id, Licence_commencement_date__c,Leasing_Term__C,Bill_Leasing_Term__c from Head_Of_Terms__c where Opportunity__r.Id = :OppId];
            system.assertEquals( 3, htList.size());
            
            htList[0].Licence_commencement_date__c = system.today();           
            LeaseTestDataFactory.createBillingSchedule(htList[0]);
            //fetching billing schedule list for displaying the details related to amount
            List<Billing_Schedule__c> billingSchList = [Select Id, Name, HEAD_OF_TERMS__c, Charges_Type__c, Net_usable_area_Area_Sq_ft__c, Start_Date__c, 
                                                        End_Date__c, From_Month__c, To_Month__c, Number_of_Months__c, Rate__c, Amount__c, Security_Deposit__c, Charges_Type__r.Name, Charges_Type__r.Charge_Type__c
                                                        from Billing_Schedule__c
                                                        where HEAD_OF_TERMS__c =: htList[0].Id   order by Name];
            htList = [select Id, Licence_commencement_date__c,Leasing_Term__C,Bill_Leasing_Term__c,Lease_Abstract__c from Head_Of_Terms__c where Opportunity__r.Id = :OppId];
            List<Address_by_BP__c> abList = [Select Id, Address_Code__c from Address_by_BP__c where Account__c = :accId];
            List<Opportunity> oppList = [Select Id from Opportunity where AccountId = :accId];
            oppList[0].Billing_Address__c = abList[0].Id;
            update oppList;
            
            PageReference pageRef1 = Page.CalculationSheet;
            Test.setCurrentPage(pageRef1);
            
            //system.assertEquals(htList[0].Leasing_Term__C, htList[0].Bill_Leasing_Term__c);
            ApexPages.currentPage().getParameters().put('hotId',htList[0].Id); 
            CalculationSheetController calcC =new CalculationSheetController(); 
            calcC.getDetails();
            htList[0].Security_Deposit__c = 90000101.50;
            NumberToWord nc = new NumberToWord();
            nc.getNumberToWordConvertion(htList[0].Security_Deposit__c);
            nc.INFormat(htList[0].Security_Deposit__c);
            htList[0].Security_Deposit__c = 91319111.50;
            nc.getNumberToWordConvertion(htList[0].Security_Deposit__c);
            nc.INFormat(htList[0].Security_Deposit__c);
            PageReference pageRef2 = Page.TermsheetPDF_GNB;
            Test.setCurrentPage(pageRef2);
            ApexPages.currentPage().getParameters().put('HoTID',htList[0].Id); 
            PremiseDocumentController pd = new PremiseDocumentController();
            pd.getDetails();
            
            PageReference pageRef3 = Page.Talkingsheet;
            Test.setCurrentPage(pageRef3);
            ApexPages.currentPage().getParameters().put('hotId',htList[0].Id); 
            TalkingSheetController ts = new TalkingSheetController();
            ts.getDetails();
            
            List<Term_Item__C> tList = [Select Id, Negotiation_Details__c, Negotiation_Status__c, Negotiation_Log__c from Term_Item__C where Head_Of_Terms__c =: htList[0].Id];
            if(!tList.isEmpty()){
                //system.assertEquals(tList.size(), 4);
                tList[1].Negotiation_Details__c = 'Looking for 120 Rs per Sq ft';
                tList[1].Negotiation_Status__c = ElbConstantsClass.NEGOTIATION_DISAGREED;
                update tList;
                
                tList[1].Negotiation_Details__c = 'Looking for 120 Rs per Sq ft';
                tList[1].Negotiation_Status__c = ElbConstantsClass.NEGOTIATION_DISAGREED;
                update tList; 
                tList[1].Negotiation_Details__c = 'Looking for 120 Rs per Sq ft';
                tList[1].Negotiation_Status__c = ElbConstantsClass.NEGOTIATION_AGREED;
                update tList;
                
                tList[1].Negotiation_Details__c = 'Looking for 120 Rs per Sq ft';
                tList[1].Negotiation_Status__c = 'Client to get back';
                update tList;
            }
        }
        test.stopTest();
        
    }
}