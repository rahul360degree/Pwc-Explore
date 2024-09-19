/**
 * @Description       : Display the QR Code
 * @Author            : Varun Rajpoot
 * @last modified on  : 12-18-2023
 * @last modified by  : Varun Rajpoot
 * Modifications Log
 * Ver   Date         Author          Modification
 * 1.0   11-15-2023   Varun Rajpoot   Initial Version
**/
import { LightningElement, api } from 'lwc';
import qrcode from './qrcodehelper.js';
export default class Qrcode extends LightningElement {
    @api paymentUrl;
    renderedCallback() {
        if (this.paymentUrl) {
            console.log(this.paymentUrl);
            const qrCodeGenerated = new qrcode(0, 'H');
            qrCodeGenerated.addData(this.paymentUrl);
            qrCodeGenerated.make();
            let element = this.template.querySelector(".qrcode2");
            element.innerHTML = qrCodeGenerated.createSvgTag({});
        }
    }
}