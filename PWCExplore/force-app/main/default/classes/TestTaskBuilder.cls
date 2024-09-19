/*------------------------------------------------------------------------------------
 * Author        :        Shreela Nair
 * Company       :        GITL
 * Description   :        Test Builder for Tasks
 * History
 * --------
 * 01-09-2023      Shreela Nair     Initial Release
 * 12-09-2023      Shreela Nair     Adding new method to set Start Date
 * 29-09-2023      Shreela Nair     Adding new method to set Action to be taken 
 * ----------------------------------------------------------------------------------*/
@isTest
public with sharing class TestTaskBuilder {
    Task taskInstance;

    public TestTaskBuilder() {
        taskInstance = new Task();

    }
    
    public TestTaskBuilder setSubject(String subject) {
        taskInstance.Subject = subject;
        return this;
    }
    
    public TestTaskBuilder setType(String type) {
        taskInstance.Type = type;
        return this;
    }
    
    //Added by Shreela on 29th Sept 2023 for SPEP - 30
    public TestTaskBuilder setActionToBeTaken(String atbt) {
        taskInstance.Action_to_be_taken__c = atbt;
        return this;
    }
    
    public TestTaskBuilder setStatus(String status) {
        taskInstance.Status = status;
        return this;
    }
    
    //Added by Shreela on 12th Sept 2023 for SPEP - 24
    public TestTaskBuilder setStartDate(Date startDate) {
        taskInstance.Start_Date_for_GPE__c = startDate;
        return this;
    }
    
    public TestTaskBuilder setActivityDate(Date activityDate) {
        taskInstance.ActivityDate = activityDate;
        return this;
    }
    
    public TestTaskBuilder setWhoId(Id whoId) {
        taskInstance.WhoId = whoId;
        return this;
    }
    
    public Task getTestRecord() {
        return taskInstance;
    }

    public Task getSavedTestRecord() {
        // Add errors for all required fields here
        if (String.isBlank(taskInstance.Subject)) {
            throw new TestDataException('Subject should not be null');
        }
        if (String.isBlank(taskInstance.Status)) {
            throw new TestDataException('Status should not be null');
        }
        insert taskInstance;
        return taskInstance;
    }

}