import { LightningElement,api } from 'lwc';
import { FlowAttributeChangeEvent } from 'lightning/flowSupport';
export default class GenericRecordTypeSpecificPicklistValueSelector extends LightningElement {
   @api objectName;
   @api fieldName;
   @api recordTypeId;
   @api fieldValue;
 
   handleFieldChange( event ){
       this.fieldValue = event.target.value;
       const attributeChangeEvent = new FlowAttributeChangeEvent('fieldValue', this.fieldValue);
       this.dispatchEvent(attributeChangeEvent);
   }
}