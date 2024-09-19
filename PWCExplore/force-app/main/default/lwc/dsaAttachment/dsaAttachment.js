/**
 * @description       : 
 * @author            : vrajpoot@godrej.com
 * @group             : 
 * @last modified on  : 03-26-2022
 * @last modified by  : vrajpoot@godrej.com
**/
import { LightningElement, api, wire } from 'lwc';

import fetchAttachments from '@salesforce/apex/DSA_Attachment.getAttchments';
import APPROVAL_REQUEST from '@salesforce/schema/ProcessInstanceWorkitem';


export default class DsaAttachment extends LightningElement {
    objectApiName = APPROVAL_REQUEST;
    @api recordId;
    @api contentVersions;
    @api usedInCommunity;

    @wire(fetchAttachments, { recordId: '$recordId' })
    workItem({ error, data }) {
        if (data) {
            console.log(data);
            console.log(this.recordId);
            this.contentVersions = data;

        } else if (error) {
            console.log(error);
        }
    }

}