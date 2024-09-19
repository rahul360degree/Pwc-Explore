import { LightningElement,api } from 'lwc';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
export default class ToastMessageFlow extends LightningElement {

    @api mode;
    @api variant;
    @api message;
    @api title;
    connectedCallback(){
        this.handleShowToast();
    }
    handleShowToast(){
        const event=new ShowToastEvent({
            title:this.title,
            variant:this.variant,
            mode:this.mode,
            message:this.message,
        });
        this.dispatchEvent(event);
    }
}