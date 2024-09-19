import { LightningElement, api ,wire} from 'lwc';
import getOrderSpecification from '@salesforce/apex/IsobController.getOrderSpecificationDetails';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import ORDER_SPECIFICATION_OBJECT from '@salesforce/schema/Order_Specification__c';
/*import NAME_FIELD from '@salesforce/schema/Order_Specification__c.Name';
import RecordTypeId_Field from '@salesforce/schema/Order_Specification__c.RecordTypeId';
import DRAWING_NO_FIELD_1 from '@salesforce/schema/Order_Specification__c.Drawing_No_1__c';
import DRAWING_NO_FIELD_2 from '@salesforce/schema/Order_Specification__c.Drawing_No_2__c';
import DRAWING_NO_FIELD_3 from '@salesforce/schema/Order_Specification__c.Drawing_No_3__c';
import DRAWING_NO_FIELD_4 from '@salesforce/schema/Order_Specification__c.Drawing_No_4__c';
import DRAWING_NO_FIELD_5 from '@salesforce/schema/Order_Specification__c.Drawing_No_5__c';
import DRAWING_NO_FIELD_6 from '@salesforce/schema/Order_Specification__c.Drawing_No_6__c';
import DRAWING_NO_FIELD_7 from '@salesforce/schema/Order_Specification__c.Drawing_No_7__c';
import WARRANTY_CERTFICATE_FIELD from '@salesforce/schema/Order_Specification__c.Any_warranty_certificate_required__c';
import SPECIFY_FIELD from '@salesforce/schema/Order_Specification__c.Specify__c';
import IS_IT_TENDER_FIELD from '@salesforce/schema/Order_Specification__c.Is_it_a_tender__c';
import IF_YES_SPECIFY_FIELD from '@salesforce/schema/Order_Specification__c.If_Yes_specify_details__c';
import ADDITIONAL_SCOPE from '@salesforce/schema/Order_Specification__c.Whether_any_additional_scope_to_be_consi__c';
import MODIFICATION_FIELD from '@salesforce/schema/Order_Specification__c.Whether_any_modifications_or_changes_in__c';
import ENTIRE_FIELD from '@salesforce/schema/Order_Specification__c.Whether_the_entire_scope_provided_in_the__c';
import PAST_SUPPLY from '@salesforce/schema/Order_Specification__c.This_order_related_to_a_past_supply__c';
import SO_NO_FIELD from '@salesforce/schema/Order_Specification__c.SO_No__c';
import YEAR_FIELD from '@salesforce/schema/Order_Specification__c.Year__c';
import LOCATION_FIELD from '@salesforce/schema/Order_Specification__c.Location__c';
import PRE_ORDER_ENGINEER_FIELD from '@salesforce/schema/Order_Specification__c.Pre_Order_Engineer__c';*/

 
export default class IsobDetails extends LightningElement {


    @api recordId; // this is the Order Id
    @api OrderSpecificationrecordId; // To store the OrderSpecificationrecordId
    @api objectApiName = ORDER_SPECIFICATION_OBJECT;
    fields = []; // Initialize as an empty array



    @wire(getObjectInfo, { objectApiName: ORDER_SPECIFICATION_OBJECT })
    objectInfo;

    @wire(getOrderSpecification, { OrderId: '$recordId' })
    wiredOrdSpc({ data, error }) {
       
        if (data) {           
            this.OrderSpecificationrecordId = data;
						console.log(this.OrderSpecificationrecordId) ;
					
        } else if (error) {           
            console.log('error :' + JSON.stringify(error));
        }
    }
}