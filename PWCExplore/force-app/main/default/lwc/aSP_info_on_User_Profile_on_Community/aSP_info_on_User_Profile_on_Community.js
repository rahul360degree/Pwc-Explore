import { LightningElement,api } from 'lwc';
import getASPaccountFromUserId from '@salesforce/apex/ASP_info_on_User_Profile_on_Community.getASPaccountFromUserId';
import updateRecord from '@salesforce/apex/ASP_info_on_User_Profile_on_Community.updateRecord';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class ASP_info_on_User_Profile_on_Community extends LightningElement {
    @api UserId;
    recordId;
    showSpinner = true;
    async connectedCallback() {
        try{ 
            this.showSpinner = true;
            const data = await getASPaccountFromUserId({recordId : this.UserId});
            this.recordId = data.Id;
            this.showSpinner = false;
        } catch (e) {
            this.showMessage(e.body.message, 'Error', 'error');
        }
    }
    showMessage(message, title, variant){
        const e = new ShowToastEvent({
                                    title: title,
                                    message: message,
                                    variant: variant,
                        });
        this.dispatchEvent(e);
    }
    async handleSubmit(event) {
        event.preventDefault();
        const fields = event.detail.fields;
        fields.Id = this.recordId;
        try{
            this.showSpinner = true;
            await updateRecord({fields : fields});
            this.showSpinner = false;
            this.showMessage('Record Updated Successfully', 'Success', 'success');
            window.location.reload();
        } catch (e) {
            this.showMessage(e.body.message, 'Error', 'error');
        }

    }
}