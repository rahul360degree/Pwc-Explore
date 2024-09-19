import { LightningElement,api } from 'lwc';
import saveSign from '@salesforce/apex/SignatureHelper.saveSign';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { loadScript } from 'lightning/platformResourceLoader';
import signaturePadURL from '@salesforce/resourceUrl/signature_pad';

let canvasElement, ctx; //storing canvas context
let dataURL,convertedDataURI; //holds image data

export default class SignaturePad extends LightningElement {

    @api recordId;

    sigPadInitialized = false;
    canvasWidth = 400;
    canvasHeight = 200;

    renderedCallback() {
        if (this.sigPadInitialized) {
            return;
        }
        this.sigPadInitialized = true;

        Promise.all([
            loadScript(this, signaturePadURL)
        ])
            .then(() => {
                this.initialize();
            })
            .catch(error => {
                console.log(error);
            });
    }

    initialize() {
        canvasElement = this.template.querySelector('canvas.signature-pad');
        this.signaturePad = new window.SignaturePad(canvasElement);
        ctx = canvasElement.getContext("2d");

    }

    handleClick() {
        console.log(this.signaturePad.toDataURL())
    }

    closeQuickAction() {
        const closeQA = new CustomEvent('close');
        // Dispatches the event.
        this.dispatchEvent(closeQA);
    }


    //clear the signature from canvas
    handleClearClick(){
        ctx.clearRect(0, 0, canvasElement.width, canvasElement.height);          
    }
    
    /*
        handler to perform save operation.
        save signature as attachment.
        after saving shows success or failure message as toast
    */
   handleSaveClick(){  

    //set to draw behind current content
    ctx.globalCompositeOperation = "destination-over";
    ctx.fillStyle = "#FFFF"; //white
    ctx.fillRect(0,0,canvasElement.width, canvasElement.height); 


    //convert to png image as dataURL
    dataURL = canvasElement.toDataURL("image/png");
    //convert that as base64 encoding
    convertedDataURI = dataURL.replace(/^data:image\/(png|jpg);base64,/, "");

    ctx.clearRect(0, 0, canvasElement.width, canvasElement.height);
    console.log('cleared '+this.recordId);

    //call Apex method imperatively and use promise for handling sucess & failure
    saveSign({strSignElement: convertedDataURI, recId : this.recordId})
        .then(result => {
            this.attachment = result;
            console.log('contentVersion id=' + this.attachment.Id);
            this.closeQuickAction();
            //show success message
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'File created for Signature',
                    variant: 'success',
                }),
            );
        })
        .catch(error => {
            //show error message
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error creating File record',
                    message: error.body.message,
                    variant: 'error',
                }),
            );
        });
        
}


}