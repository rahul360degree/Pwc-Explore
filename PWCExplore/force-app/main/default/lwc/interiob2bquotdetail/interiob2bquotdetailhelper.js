/**
 * @description       : 
 * @author            : vrajpoot@godrej.com
 * @group             : 
 * @last modified on  : 11-18-2022
 * @last modified by  : vrajpoot@godrej.com
**/
export class helperFiler {
    static skipFields = ['Product2.Id','Product2.Name','Product2.Description','Product2.Item__c','Quantity','Effective_Pricebook_Date__c','ListPrice','Requested_Customer_Discount__c','UnitPrice','Approved_Customer_Discounted_Basic_Price__c','Req_WD_Ret_SAC_OnReqDiscBasic__c','Req_WD_CONT__c','COP__c','Requested_COP_Factor__c','Approved_COP_Factor__c','toLabel(Product_Line_c__c)','List_of_Approvers__c','Current_Approver__c','Approval_Status__c','Quote.Opportunity.OwnerId','Pending_With_Owner__c','Requested_WD_CONT_Req_Disc_Basic__c'];
    static nullValueAssignment(record,fields) {
        let fieldArray = fields.split(',');
            for (let field of fieldArray) {
                field = field.trim();
                if(!helperFiler.skipFields.includes(field)){
                    helperFiler.assignDefaultValue(record,field);
                }
            }
    }

    static assignDefaultValue(record,key){
        let value = record[key];
        if(typeof value ==undefined || isNaN(value)){
            value =  0;
        }

        record[key] = value;
    }
}