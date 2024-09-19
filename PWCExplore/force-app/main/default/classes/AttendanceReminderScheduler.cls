/*------------------------------------------------------------------------
Author:        Mahith Madwesh
Company:       Salesforce
Description:   Responsible for alerting Attendance to relevant personas
Inputs:        NA
Test Class:    
---------------------------------------------------------------------------
History
03-11-2020      Mahith      Initial Release
----------------------------------------------------------------------------*/
global class AttendanceReminderScheduler implements Schedulable {
    public enum NotificationType {STARTOFDAY, ENDOFDAY}
    String chatterMessage;
    Set<String> groupNames = new Set<String>{'Appliances Users', 'Appliances Community Users'};
    Id externalGroupId;
    Id internalGroupId;
    Set<Id> internalUserIdSet = new Set<Id>();
    Set<Id> externalUserIdSet = new Set<Id>();
    List<String> attendanceUserPersonas = new List<String>();
    List<ConnectApi.BatchInput> batchInputs = new List<ConnectApi.BatchInput>();
    List<ConnectApi.FeedItemInput> feedInputs = new List<ConnectApi.FeedItemInput>();
    List<ConnectApi.BatchInput> batchInputsExternal = new List<ConnectApi.BatchInput>();
    String standardCollabRole = 'Standard';
    String everyPostFrequency = 'P';

    public AttendanceReminderScheduler(NotificationType type) {
        if (type == NotificationType.STARTOFDAY) {
            chatterMessage = GlobalConstants.START_OF_DAY_ATTENDANCE_REMINDER_CHATTER_MESSAGE;
        } else {
            chatterMessage = GlobalConstants.END_OF_DAY_ATTENDANCE_REMINDER_CHATTER_MESSAGE;
        }
    }

    public void execute(SchedulableContext ctx) {
        List<CollaborationGroupMember> collaborationGroupMembers = new List<CollaborationGroupMember>();
        Id externalNetworkId;
        if (Test.isRunningTest()) {
            groupNames = new Set<String>{'Appliances Test Group', 'Appliances Community Test Group'};
        }
        try {
            for(CollaborationGroup each : [SELECT Id, NetworkId, Name FROM CollaborationGroup WHERE Name IN :groupNames]) {
                if (each.Name.contains('Community')) {
                    externalGroupId = each.Id;
                    externalNetworkId = each.NetworkId;
                } else {
                    internalGroupId = each.Id;
                }
            }
            for (Attendance_Personas__mdt each : [SELECT Id, Persona_Name__c FROM Attendance_Personas__mdt WHERE Persona_Name__c LIKE 'Appliances%']) {
                attendanceUserPersonas.add(each.Persona_Name__c);
            }
            for (User each : [SELECT Id, ContactId FROM User WHERE Persona__c IN :attendanceUserPersonas AND IsActive = true]) {
                if (String.isNotBlank(each.ContactId)) {
                    externalUserIdSet.add(each.Id);
                } else {
                    internalUserIdSet.add(each.Id);
                }
            }
            for (CollaborationGroupMember each : [SELECT MemberId FROM CollaborationGroupMember WHERE CollaborationGroupId = :externalGroupId OR CollaborationGroupId = :internalGroupId]) {
                internalUserIdSet.remove(each.MemberId);
                externalUserIdSet.remove(each.MemberId);
            }
            if (!internalUserIdSet.isEmpty()) {
                for (Id each : internalUserIdSet) {
                    collaborationGroupMembers.add(new CollaborationGroupMember(MemberId = each, CollaborationGroupId = internalGroupId,
                        NotificationFrequency = everyPostFrequency, CollaborationRole = standardCollabRole));
                }
            }
            if (!externalUserIdSet.isEmpty()) {
                for (Id each : externalUserIdSet) {
                    collaborationGroupMembers.add(new CollaborationGroupMember(MemberId = each, CollaborationGroupId = externalGroupId,
                        NotificationFrequency = everyPostFrequency, CollaborationRole = standardCollabRole));
                }
            }
            insert collaborationGroupMembers;

            ChatterUtility utilityInstance = new ChatterUtility();
            utilityInstance.addMention(internalGroupId);
            utilityInstance.setSubjectId(internalGroupId);
            utilityInstance.addTextWithMarkupType(chatterMessage, ConnectApi.MarkupType.PARAGRAPH);
            ConnectApi.FeedItemInput feedItemInput = utilityInstance.build();
            ConnectApi.BatchInput batchInput = new ConnectApi.BatchInput(feedItemInput);
            feedInputs.add(feedItemInput);
            batchInputs.add(batchInput);
            if (Test.isRunningTest()) {
                ChatterUtility.postChatterForTestClass(feedInputs);
            } else {
                ConnectApi.ChatterFeeds.postFeedElementBatch(Network.getNetworkId(), batchInputs);
            }

            utilityInstance = new ChatterUtility();
            utilityInstance.addMention(externalGroupId);
            utilityInstance.setSubjectId(externalGroupId);
            utilityInstance.addTextWithMarkupType(chatterMessage, ConnectApi.MarkupType.PARAGRAPH);
            feedItemInput = utilityInstance.build();
            batchInput = new ConnectApi.BatchInput(feedItemInput);
            batchInputsExternal.add(batchInput);
            
            if (!Test.isRunningTest()) {
                ConnectApi.ChatterFeeds.postFeedElementBatch(externalNetworkId, batchInputsExternal);
            }
        } catch(Exception e){
            Logger.logError('AttendanceReminderScheduler', 'execute', '', e);
        }
    }
}