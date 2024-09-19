public without sharing class ASP_info_on_User_Profile_on_Community {
    @AuraEnabled
    public static Account getASPaccountFromUserId(Id recordId){
        try {
            User u = [SELECT ContactId,Contact.AccountID FROM User WHERE ID =: recordId LIMIT 1];
            System.debug(u.ContactId);
            System.debug(u.Contact.AccountId);
            Account a = [SELECT Id FROM Account WHERE ID =: u.Contact.AccountId];
            return a;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static void updateRecord(Map<String, Object> fields){
        try {
            SObject record = Schema.getGlobalDescribe().get('Account').newSObject((Id)fields.get('Id'));
            for (String fieldName : fields.keySet()) {
                System.debug('fieldName ==' +  fieldName + 'Value ==' + fields.get(fieldName));
                if (fieldName != 'Id' && fields.get(fieldName) != null) {
                    record.put(fieldName, fields.get(fieldName));
                }
            }
            System.debug(record);
            update record;
        } catch (Exception e) {
            system.debug('Error updating record: ' + e.getMessage());
            throw new AuraHandledException('Error updating record: ' + e.getMessage());
        }
    }
}