import { LightningElement,track } from 'lwc';

export default class OpenCalls extends LightningElement {
    @track field1 = '';
    @track field2 = '';
    @track field3 = '';
    @track field4 = '';
    @track field5 = '';
    @track field6 = '';

    handleInputChange(event) {
        const field = event.target.label.toLowerCase().replace(' ', '');
        this[field] = event.target.value;
    }

    handleSubmit() {
        console.log('Form submitted with values:', {
            field1: this.field1,
            field2: this.field2,
            field3: this.field3,
            field4: this.field4,
            field5: this.field5,
            field6: this.field6
        });
    }
}