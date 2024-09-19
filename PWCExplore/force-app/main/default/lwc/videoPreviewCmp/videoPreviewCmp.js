import { LightningElement, wire, api } from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import getAttachedDocuments from '@salesforce/apex/VideoPreviewerController.getAttachedDocuments';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'


export default class VideoPreviewCmp extends NavigationMixin(LightningElement) {
    @api recordId;
    KnowledgeArticleVideos = [];
    loading = true;
    currentVideoFile = {};
    currentIndexFile = 0;
    showDiv = false;
    @api contentVideoUrl = '';



    @wire(getAttachedDocuments, { recordId: '$recordId' })
    wiredgetAttachedDocuments({ error, data }) {
        if (error) {
            console.error(error);
        } else if (data) {
            let result = data;
            let tempArray = [];
            if (result.length) {


                for (let i = 0; i < result.length; i++) {
                    if (!this.contentVideoUrl.length) {
                        tempArray.push({
                            index: i, fileName: result[i].ContentDocument.Title + '.' + result[i].ContentDocument.FileExtension
                            , videoFileUrl: window.location.origin + '/sfc/servlet.shepherd/document/download/' + result[i].ContentDocumentId
                        });
                    } else {
                        tempArray.push({
                            index: i, fileName: result[i].ContentDocument.Title + '.' + result[i].ContentDocument.FileExtension
                            , videoFileUrl: this.contentVideoUrl + '/sfc/servlet.shepherd/document/download/' + result[i].ContentDocumentId
                        });
                    }

                }
                this.KnowledgeArticleVideos = tempArray;
                this.currentVideoFile = this.KnowledgeArticleVideos[0];
                this.showDiv = true;
                this.loading = false;
            } else {
                this.loading = false;
            }


        }
    }

    previousVideo(event) {
        let currentIndex = event.currentTarget.dataset.id;
        this.currentIndexFile = parseInt(currentIndex);
        if (this.KnowledgeArticleVideos[this.currentIndexFile - 1]) {
            this.loading = true;
            this.showDiv = false;
            this.currentVideoFile = {};
            this.currentVideoFile = this.KnowledgeArticleVideos[this.currentIndexFile - 1];
            this.showDiv = true;
            this.loading = false;
        } else {
            this.showToastMessage('Error', 'No More videos present to Scroll', 'error')
        }
    }

    nextVideo(event) {
        let currentIndex = event.currentTarget.dataset.id;

        this.currentIndexFile = parseInt(currentIndex) + 1;
        if (this.KnowledgeArticleVideos[this.currentIndexFile]) {
            this.loading = true;
            this.showDiv = false;
            this.currentVideoFile = {};
            this.currentVideoFile = this.KnowledgeArticleVideos[this.currentIndexFile];
            this.showDiv = true;
            this.loading = false;
        } else {
            this.showToastMessage('Error', 'No More videos present to Scroll', 'error')
        }
    }


    showToastMessage(title, message, varaiant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: varaiant
        });
        this.dispatchEvent(event);
    }



}