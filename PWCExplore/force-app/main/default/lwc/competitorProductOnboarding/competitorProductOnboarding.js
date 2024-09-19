import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import saveAsset from '@salesforce/apex/CompetitorProductOnboardingController.saveAsset';

export default class CompetitorProductOnboarding extends LightningElement {
    @api recordId;
    @track brandName;
    @track assetType;
    @track assetName;
    @track capacity;
    @track ageOfProduct;
    @track manufacturingDate;
    @track files = [];

    handleBrandNameChange(event) {
        this.brandName = event.target.value;
    }

    handleAssetTypeChange(event) {
        this.assetType = event.target.value;
    }

    handleAssetNameChange(event) {
        this.assetName = event.target.value;
    }

    handleCapacityChange(event) {
        this.capacity = event.target.value;
    }

    handleAgeOfProductChange(event) {
        this.ageOfProduct = event.target.value;
    }

    handleManufacturingDateChange(event) {
        this.manufacturingDate = event.target.value;
    }

    handleFileChange(event) {
        this.files = Array.from(event.target.files);
    }

    async handleSave() {
        console.log('RecordId--->', this.recordId);
        if (!this.brandName) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Brand Name is required',
                    variant: 'error'
                })
            );
            return;
        }

        try {
            for (let file of this.files) {
                const fileContent = await this.readFileContents(file);
                console.log('File content:', fileContent); // Log the file content
                const result = await saveAsset({
                    brandName: this.brandName,
                    assetType: this.assetType,
                    assetName: this.assetName,
                    capacity: this.capacity,
                    ageOfProduct: this.ageOfProduct,
                    manufacturingDate: this.manufacturingDate,
                    fileName: file.name,
                    fileContent: fileContent,
                    recordId: this.recordId
                });
                console.log('Save result:', result);
            }
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Record saved successfully',
                    variant: 'success'
                })
            );
            // Optionally, reset form fields or navigate to another page
        } catch (error) {
            console.error('Error while saving:', error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'An error occurred while saving the record',
                    variant: 'error'
                })
            );
        }
    }

    readFileContents(file) {
        return new Promise((resolve, reject) => {
            const reader = new FileReader();
            reader.onloadend = () => resolve(reader.result.split(',')[1]);
            reader.onerror = reject;
            reader.readAsDataURL(file);
        });
    }
}