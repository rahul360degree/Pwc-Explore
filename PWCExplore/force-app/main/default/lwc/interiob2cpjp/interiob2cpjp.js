/**
 * @description       : 
 * @author            : vrajpoot@godrej.com
 * @group             : 
 * @last modified on  : 06-20-2023
 * @last modified by  : vrajpoot@godrej.com
**/
import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { FlowNavigationNextEvent } from 'lightning/flowSupport';

export default class Interiopjp extends LightningElement {
    @api record;
    @api recordToUpdate;
    //init
    connectedCallback() {
        this.record = Object.assign({}, this.record);
    }
    //Assign the answer
    handleAnswerChange(event) {
        this.record[event.detail.A_F] = event.detail.A;
        this.recordToUpdate = this.record;
    }
    //Null check and go to next
    nullCheckHelper() {
        let error = '';
        if (typeof this.recordToUpdate === 'undefined') {
            error = 'All fields are mandatory';
        } else {
            for (let i = 1; i <= 10; i++) {
                const questionField = 'Question_' + i + '__c';
                let question = this.recordToUpdate[questionField];
                let answer = (this.recordToUpdate['Answer_' + i + '__c']);
                answer = answer ? answer.trim() : answer;

                if (question && question !== null && question !== '') {
                    if (!answer || answer === null || answer === '') {
                        //error += 'Question : ' + questionField + 'is mandatory.';
                        error = 'All fields are mandatory';
                        break;
                    }
                }
            }
        }
        if (error.length > 0) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: error,
                    variant: 'Error'
                })
            );
        } else {
            this.dispatchEvent(new FlowNavigationNextEvent());
        }
    }
}