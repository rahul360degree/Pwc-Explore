import { LightningElement, api, wire } from 'lwc';
import getArticles from '@salesforce/apex/DisplaySuggestedArticlesController.getArticles';
import createCaseArticles from '@salesforce/apex/DisplaySuggestedArticlesController.createCaseArticle';
import getArticlesBySearch from '@salesforce/apex/DisplaySuggestedArticlesController.getArticlesBySearch';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';


export default class DisplaySuggestedArticles extends NavigationMixin(LightningElement) {

    @api recordId;
    @api cardName;
    articles = [];
    searchInput;
    loading = true;
    defaultSearchArticles = [];
    attachArticles = [];



    connectedCallback() {
        if (this.recordId) {
            getArticles({ caseId: this.recordId })
                .then(result => {
                    this.defaultSearchArticles = result;
                    this.articles = result;
                })
                .catch(error => {
                    console.log(error);
                });
        }
        this.loading = false;
    }
    // constructor() {
    //     super(); // Must be called first
    //     // console.log(">>> articles... "+articles);
    // }

    searchChangeHandler(event) {
        this.searchInput = event.target.value;
    }

    searchButton() {

        //call apex action with searchInput
        if (this.searchInput) {
            this.loading = true;
            getArticlesBySearch({ searchInput: this.searchInput })
                .then(result => {
                    this.articles = [];
                    console.log('search result', result)
                    this.articles = result;
                    this.loading = false;
                })
                .catch(error => {
                    console.error(error);
                });
        } else {
            this.showToastMessage("Error", "Enter Search Text to search articles", "error");
        }


    }


    resetSearchHandler() {
        this.searchInput = '';
        this.articles = [];
        this.articles = this.defaultSearchArticles;
    }

    checkboxChangeHandler(event) {
        let chekdbox = event.target.checked;
        let articleId = event.currentTarget.dataset.id;
        if (chekdbox) {
            this.attachArticles.push(articleId);
        } else {
            this.attachArticles.splice(this.attachArticles.indexOf(articleId), 1);
        }
    }

    handleClick() {

        if (this.attachArticles.length === 0) {
            // alert('None of the articles are selected');
            this.showToastMessage('Error', "'None of the articles are selected'", 'error');

        } else {
            createCaseArticles({ articleIds: this.attachArticles, caseId: this.recordId })
                .then(result => {
                    console.log('result is coming', result)
                    if (result) {
                        this.showToastMessage('Success', "Knowledge Articles are attached successfully to the service request", 'success');

                    } else {
                        this.showToastMessage('Error', "Knowledge Articles could not be attached successfully to the service request.Please try again", 'error');
                    }
                })
                .catch(error => {
                    this.showToastMessage('Error', "There is an error attaching the article to the service request : " + JSON.parse(JSON.stringify(error)), 'error');
                });
        }
    }

    navigateToKAMPage(event) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: event.currentTarget.dataset.value,
                objectApiName: 'KnowledgeArticle',
                actionName: 'view'
            }
        });
    }

    showToastMessage(title, message, variant) {
        const event = new ShowToastEvent({
            "title": title,
            "message": message,
            "variant": variant
        });
        this.dispatchEvent(event);
    }
}