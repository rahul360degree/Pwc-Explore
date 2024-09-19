/* eslint-disable no-console */

import { LightningElement, track, wire, api } from 'lwc';

import { NavigationMixin } from 'lightning/navigation';

import KnowledgeRecordTypes from '@salesforce/apex/KnowledgeSearchController.KnowledgeRecordTypes';
import KnowledgeArticles from '@salesforce/apex/KnowledgeSearchController.KnowledgeArticles';
import sendKnowledgeArticleRecord from '@salesforce/apex/KnowledgeSearchController.sendKnowledgeArticle'
import  {ShowToastEvent} from 'lightning/platformShowToastEvent';
//import getPicklistValues from '@salesforce/apex/knowledgeSearchLWC.getPicklistValues_old';

export default class KnowledgeSearchLWC extends NavigationMixin(LightningElement) {
    @track article;
    @track articleList = [];
    @track selectedRecordIds = [];
    @track results;
    @api recordId;
    //@track cible = 'Tous';

    @track rt = 'All';
    @track rtList = [];

    @api displayCard;

    handleCheckboxChange(event){
        let selectedId = event.target.value;
        let isChecked = event.target.checked;
        console.log('RecordID', this.recordId);

        console.log('RecordId-->' , event.target.value);
        
        if(isChecked){
            console.log('Inside');
            this.selectedRecordIds.push(event.target.value);
            console.log('Array-->' , this.selectedRecordIds);
        }
        else{
            let index = this.selectedRecordIds.indexOf(selectedId);
            if(index!==-1){
                console.log('Inside Bad');

                this.selectedRecordIds.splice(index,1);
            }
        }
        console.log('SelectArticles--->' , this.selectedRecordIds);
    }

    handleSendClick(){
            console.log('RecordID', this.recordId);
        sendKnowledgeArticleRecord({knowledgeRecordIdList:this.selectedRecordIds,recordId:this.recordId})
        .then(result=>{
           this.showToast('Success','Email sent to the customer','success');

        })
        .catch(error=>{
            console.error('Error',error);
            this.showToast('Error','An Error occured while sending the email','error');
        })

    }

    showToast(title,message,variant){
        console.log('Inside Toast');
        this.dispatchEvent(new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        }));
    }

    get componentClass() {
        return (this.displayCard ? 'slds-page-header' : 'slds-m-around_medium');
    }

    @wire(KnowledgeRecordTypes)
    wiredRecordTypes({error, data}) {
        if (data) {
            this.rtList = data;
            console.log('data', data);
            this.error = undefined;
        }
        if (error) {
            this.error = error;
            console.log('data error', error);
            this.rtList = undefined;
        }
    };
    
    @wire(KnowledgeArticles, {input : '$article', cat : '$rt'})
    wiredArticles({error, data}) {
        if (data) {

            this.articleList = [];
            for (let article of data) {
                let myArticle = {};
                myArticle.data = article;

                // Get article url
                this.KnowledgePageRef = {
                    type: "standard__recordPage",
                    attributes: {
                        "recordId": article.Id,
                        "objectApiName": "Knowledge__kav",
                        "actionName": "view"
                    }
                };

                this[NavigationMixin.GenerateUrl](this.KnowledgePageRef)
                    .then(articleUrl => {
                        myArticle.url = articleUrl; 
                        this.articleList.push(myArticle);
                    });
            }

            this.error = undefined;
        }
        if (error) {
            this.error = error;
            this.articleList = undefined;
        }
    }

    changeHandler(event) {
        this.article = event.target.value;
        console.log('article', this.article);
    }

    handleCible(event) {
        this.rt = event.target.value;
        console.log('rt', this.rt);
    }

    redirectToArticle(event) {
            // Navigate to the CaseComments related list page
            // for a specific Case record.
            event.preventDefault();

            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: event.currentTarget.dataset.toto,
                    objectApiName: 'Knowledge__kav',
                    actionName: 'view'
                }
            });
    }
}