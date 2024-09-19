public class ScheduleServiceAppointment {
	
    @InvocableMethod(label='Assign SA to ASP' description='' category='ServiceAppointment')
    public static void ScheduleSA(List<ServiceAppointment> serviceAppointmentList) {
    	Id schedulingPolicyId = [SELECT Id FROM FSL__Scheduling_Policy__c WHERE Name='Customer First' LIMIT 1].Id;
        for (ServiceAppointment sa : serviceAppointmentList){
            FSL.ScheduleResult myResult = new FSL.ScheduleResult();
            myResult = FSL.ScheduleService.schedule(schedulingPolicyId,sa.Id); //schedule the job
            //system.debug(myResult);
        }
    }

}