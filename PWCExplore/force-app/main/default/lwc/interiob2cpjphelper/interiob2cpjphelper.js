import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
export default class Interiopjphelper extends LightningElement {
    @api counter;
    @track questionField;
    @track answerField;
    @api record;
    @track question;
    connectedCallback() {
        this.record = Object.assign({}, this.record);
        this.questionField = 'Question_' + this.counter + '__c';
        this.answerField = 'Answer_' + this.counter + '__c';
        this.question = this.record[this.questionField];
    }
    //Fire the event
    handleInputChange(event) {
        this.record[this.answerField] = event.target.value;

        let obj = {
            Q_F: this.questionField,
            A_F: this.answerField,
            A: event.target.value

        }
        this.dispatchEvent(new CustomEvent('answerupdate', {
            detail: obj
        }));
    }

}