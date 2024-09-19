public without sharing class FacilityBooking {
    public class inputWrapper{
        @InvocableVariable 
        public Date bookingDate;
        @InvocableVariable 
        public String bookingSlot;
        @InvocableVariable 
        public String facilityName;
    }
    @InvocableMethod(label='Get Slot Availablity'  category='Other')
    public static List<Boolean> getAvailabilty(List<inputWrapper> input){
        List<Boolean> result = new List<Boolean>();
        Boolean r = true;
        List<Slot__c> slotList = [SELECT Time_Slot__c FROM Slot__c 
                                  WHERE Date__c=: input[0].bookingDate AND Facility_Name__c =: input[0].facilityName AND 
                                  Status__c !=: ElbConstantsClass.FACILITY_STATUS_CRMHEAD_APPROVAL AND 
                                  Status__c !=: ElbConstantsClass.FACILITY_STATUS_REJECTED AND
                                  Status__c !=: ElbConstantsClass.FACILITY_STATUS_CANCELLED LIMIT 1000];
        if(slotList.isEmpty()){
            result.add(r);
            return result;
        }
        else if(input[0].bookingSlot == ElbConstantsClass.FACILITY_SLOTBOOKING_FULLDAY) r= false; 
        else{
            for(Slot__c s: slotList){
                if(s.Time_Slot__c == ElbConstantsClass.FACILITY_SLOTBOOKING_FULLDAY || s.Time_Slot__c == input[0].bookingSlot){ 
                    r= false;
                    break;
                }
            }
        }
        result.add(r);
        return result;
    }
}