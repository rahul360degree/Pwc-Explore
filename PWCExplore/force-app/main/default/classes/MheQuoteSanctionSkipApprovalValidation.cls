/**
 * @description       : 
 * @author            : vrajpoot@godrej.com
 * @group             : 
 * @last modified on  : 02-24-2023
 * @last modified by  : vrajpoot@godrej.com
**/
public with sharing class MheQuoteSanctionSkipApprovalValidation {
    
    @InvocableMethod(label='Records for Output' description='yourDescription' )
    public static void skipLockedValidation() {
        //Will skip lock validation for QuoteRecordProcessor.updateQuoteApprovalStatus()
        GlobalConstants.SKIP_QUOTE_LOCK = true;
    }
}