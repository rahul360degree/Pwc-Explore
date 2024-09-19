Trigger paymentTerm on Payment_Term__c (before insert) {
    if(trigger.isBefore && trigger.isInsert) {
        paymentTermHelper.paymentTermError(trigger.new);
    }
}