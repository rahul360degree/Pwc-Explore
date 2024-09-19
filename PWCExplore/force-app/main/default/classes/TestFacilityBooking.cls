/*------------------------------------------------------------------------------------
 * Author        :        Stetig Consulting
 * Description   :        Test method for early term release/closure
 * History
 * --------
 * 09-12-2021     :    Initial Release
 * ----------------------------------------------------------------------------------*/
@isTest
public with sharing class TestFacilityBooking {
    public static testmethod void testFacilityBooking() {
        Id bId = LeaseTestDataFactory.createOfficeSpaceBuilding();
        
        List<Facilities__c> facilityList = new List<Facilities__c>();
        Facilities__c facility = new Facilities__c();
        facility.Name = 'Test North Pavilion';
        facility.Building__c = bId;
        facilityList.add(facility);
        insert facilityList;
        
        List<Slot__c> slotList = new List<Slot__c>();
        Slot__c slot = new Slot__c();
        slot.Date__c = system.today();
        slot.Status__c = 'Approved';
        slot.Facility__c = facilityList[0].Id;
        slotList.add(Slot);
        insert slotList;      
        
        System.debug('Slot List:' + SlotList[0]);
        test.startTest();
        List<FacilityBooking.inputWrapper> wrapList = new List<FacilityBooking.inputWrapper>();
        FacilityBooking.inputWrapper wrap = new FacilityBooking.inputWrapper();
        wrap.bookingDate = system.today();
        wrap.bookingSlot = 'Half Day';
        wrap.facilityName = 'Test North Pavilion';
        wrapList.add(wrap);
        FacilityBooking.getAvailabilty(wrapList);
        test.stopTest();

    }

    public static testmethod void testFacilityBooking1() {
        Id bId = LeaseTestDataFactory.createOfficeSpaceBuilding();
        
        List<Facilities__c> facilityList = new List<Facilities__c>();
        Facilities__c facility = new Facilities__c();
        facility.Name = 'Test North Pavilion';
        facility.Building__c = bId;
        facilityList.add(facility);
        insert facilityList;
        
        List<Slot__c> slotList = new List<Slot__c>();
        Slot__c slot = new Slot__c();
        slot.Facility__c = facilityList[0].Id;
        slot.Date__c = system.today();
        slot.Status__c = ElbConstantsClass.FACILITY_STATUS_CRMHEAD_APPROVAL;
        slotList.add(Slot);
        insert slotList;      
        
        test.startTest();
        List<FacilityBooking.inputWrapper> wrapList1 = new List<FacilityBooking.inputWrapper>();
        FacilityBooking.inputWrapper wrap1 = new FacilityBooking.inputWrapper();
        wrap1.bookingDate = system.today();
        wrap1.bookingSlot = 'Full Day';
        wrap1.facilityName = 'Test North Pavilion';
        wrapList1.add(wrap1);
        FacilityBooking.getAvailabilty(wrapList1);
        test.stopTest();
    }
}