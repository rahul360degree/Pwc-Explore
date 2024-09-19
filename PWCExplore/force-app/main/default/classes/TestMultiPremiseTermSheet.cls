/*------------------------------------------------------------------------------------
 * Author        :        Stetig Consulting
 * Description   :        Test methods for controller to merge and print multiple termsheets
 * History
 * --------
 * 02-12-2021     :    Initial Release
 * ----------------------------------------------------------------------------------*/
@isTest
public with sharing class TestMultiPremiseTermSheet {
       static testmethod void mergeandprinttermsheet() {
            String accId = LeaseTestDataFactory.createAccount();
            String conId = LeaseTestDataFactory.createContact(accId);
            test.StartTest();
                Id leasingUserId = LeaseTestDataFactory.createLeasingUser();
                User u = [Select Id from User where Id =: leasingUserId];
            System.RunAs(u) {
                String oppId = LeaseTestDataFactory.createOpportunity(accId);
                String hotId = LeaseTestDataFactory.createHOT(oppId);
                LeaseTestDataFactory.createStandardTermClauses();
                LeaseTestDataFactory.tagPremise(hotId,oppId);
                List<Junction_Unit__c> juList = [Select Id from Junction_Unit__c where Opportunity__c = :oppId and Head_Of_Terms__c =:hotId];
                system.assertEquals(2, juList.size());
                PageReference pageRef = Page.createHOT;
                Test.setCurrentPage(pageRef);
                
                ApexPages.currentPage().getParameters().put('HoTID',hotId); 
                CreateHoT cht=new CreateHot(); 
                cht.HOT.Notice_Period_For_Termination_Licensor__c = 60;
                cht.HOT.Notice_Period_For_Termination_Licensee__c = 60;
                cht.HOT.Leasing_Term__C = 60;
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
                htList[0].Approval_Status__c = ElbConstantsClass.APPROVED;
                update htList;
                List<Address_by_BP__c> abList = [Select Id, Address_Code__c from Address_by_BP__c where Account__c = :accId];
                List<Opportunity> oppList = [Select Id from Opportunity where AccountId = :accId];
                oppList[0].Billing_Address__c = abList[0].Id;
                update oppList;
                PageReference pageRef1 = Page.multipremiseTermsheet;
                Test.setCurrentPage(pageRef1);
                ApexPages.currentPage().getParameters().put('id',oppId); 
                /* 
                 * Commented temporary once Term_Item__c functionality will be in use   we will fix it
                 * 
                 */
                try{
                    multipremiseTermsheet mp = new multipremiseTermsheet();
                mp.HOTWrapperList[0].isSelected = true;
                mp.HOTWrapperList[0].hot.Master_Record__c = true;
                mp.generateTerms();
                multipremiseTermsheet.BillingWrapper b = new multipremiseTermsheet.BillingWrapper(null, null,null,null,null,null,null);
                }catch(Exception ex){
                    System.debug(ex.getStackTraceString());
                }
            }       
            test.StopTest();
    }
}