/**
 * @description       : 
 * @author            : vrajpoot@godrej.com
 * @group             : 
 * @last modified on  : 03-27-2022
 * @last modified by  : vrajpoot@godrej.com
**/
import { api, track, LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
export default class DsaAttachmentIcon extends NavigationMixin(LightningElement) {
    @track docObj = {};
    @api record;
    @api usedInCommunity;

    connectedCallback() {
        this.docObj = {};
        if (this.record) {
            if (this.record.FileType == 'PDF') {
                this.docObj['isPdf'] = true;
            }
            else if (this.record.FileType == 'EXCEL_X' || this.record.FileType == 'EXCEL') {
                this.docObj['isExcel'] = true;
            }
            else if (this.record.FileType == 'PNG') {
                this.docObj['Image'] = true;
            }
        }

    }
    handleClick(event) {
        let contnentDocumentId, contnetVersionId;
        contnetVersionId = event.currentTarget.dataset.id;
        contnentDocumentId = event.currentTarget.dataset.name;

        if (!this.usedInCommunity) {
            this[NavigationMixin.Navigate]({
                type: 'standard__namedPage',
                attributes: {
                    pageName: 'filePreview'
                },
                state: {
                    recordIds: contnentDocumentId //your ContentDocumentId here
                }
            });
        }
        else {
            this.handleCommunityClick(contnetVersionId,'preview');
        }

    }

    handleDownload(event){        
        let contnentDocumentId = event.currentTarget.dataset.name;
        this.handleCommunityClick(contnentDocumentId,'download');
    }

handleCommunityClick(id,action){
    let baseURL = this.getBaseUrl();
    let previewURL;
    if(action=='preview'){
        previewURL = baseURL + 'sfc/servlet.shepherd/version/renditionDownload?rendition=THUMB720BY480&versionId=' + id;
    }else{
        previewURL = baseURL + 'sfc/servlet.shepherd/document/download/' + id;
    }
    
    this[NavigationMixin.Navigate]({
        type: 'standard__webPage',
        attributes: {
            url: previewURL
        }
    }, false);


}

    getBaseUrl() {
        let baseUrl = "";
        if (this.usedInCommunity) {
            baseUrl = 'https://' + location.host + '/gbpartners/';
        } else {
            baseUrl = 'https://' + location.host + '/';
        }
        return baseUrl;
    }
}