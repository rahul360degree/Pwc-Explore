import { LightningElement, api, track,wire } from 'lwc';
import getOrderRiskMatrix from '@salesforce/apex/PedOrderRiskMatrix.getOrderRiskMatrix';
import getLoggedInUserDetails from '@salesforce/apex/PedOrderRiskMatrix.getLoggedInUserDetails';
import updateOrderRiskMatrixRecord from '@salesforce/apex/PedOrderRiskMatrix.updateOrderRiskMatrixRecord';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import { NavigationMixin } from 'lightning/navigation';

export default class PedOrderRiskMatrix extends NavigationMixin(LightningElement) {
    @api recordId;
    riskMatrixData;
    dataRecord;
    loggedInUserDetails;
    showDetails=false;
    DivCSSType='';
    showFooter=true;
    @track RiskRating={};
    

    connectedCallback() {
        this.getUserInfo();
        this.getOpportunityInfo();        
    }

    getUserInfo() {
        // Fetch opportunity data using Apex method getOrderRiskMatrix
        getLoggedInUserDetails()
        .then(result => {            
            this.loggedInUserDetails = result;
            })
        .catch(error=>{
            this.showToast('Error', error.body.message, 'error');
        });
    }

    getOpportunityInfo() {
        // Fetch opportunity data using Apex method getOrderRiskMatrix
        getOrderRiskMatrix({ quoteId: this.recordId })
        .then(result => {            
            this.dataRecord = result;

            // Calculate and set various properties based on dataRecord values
            // (e.g., RMTable1Risk1Rating1, RMTable1Risk1Rating2, etc.)       
            this.RiskRating.RMTable1Risk1Rating1=this.calculateRMTable1RiskRating(this.dataRecord.RM_Table_1_Risk_1_Likelihood_1__c,this.dataRecord.RM_Table_1_Risk_1_Consequence_1__c);
            this.RiskRating.RMTable1Risk1Rating2=this.calculateRMTable1RiskRating(this.dataRecord.RM_Table_1_Risk_1_Likelihood_2__c,this.dataRecord.RM_Table_1_Risk_1_Consequence_2__c);
            this.RiskRating.RMTable1Risk2Rating1=this.calculateRMTable1RiskRating(this.dataRecord.RM_Table_1_Risk_2_Likelihood_1__c,this.dataRecord.RM_Table_1_Risk_2_Consequence_1__c);
            this.RiskRating.RMTable1Risk2Rating2=this.calculateRMTable1RiskRating(this.dataRecord.RM_Table_1_Risk_2_Likelihood_2__c,this.dataRecord.RM_Table_1_Risk_2_Consequence_2__c);
            this.RiskRating.RMTable1Risk3Rating1=this.calculateRMTable1RiskRating(this.dataRecord.RM_Table_1_Risk_3_Likelihood_1__c,this.dataRecord.RM_Table_1_Risk_3_Consequence_1__c);
            this.RiskRating.RMTable1Risk3Rating2=this.calculateRMTable1RiskRating(this.dataRecord.RM_Table_1_Risk_3_Likelihood_2__c,this.dataRecord.RM_Table_1_Risk_3_Consequence_2__c);
            this.RiskRating.RMTable1Risk4Rating1=this.calculateRMTable1RiskRating(this.dataRecord.RM_Table_1_Risk_4_Likelihood_1__c,this.dataRecord.RM_Table_1_Risk_4_Consequence_1__c);
            this.RiskRating.RMTable1Risk4Rating2=this.calculateRMTable1RiskRating(this.dataRecord.RM_Table_1_Risk_4_Likelihood_2__c,this.dataRecord.RM_Table_1_Risk_4_Consequence_2__c);
            this.RiskRating.RMTable1Risk5Rating1=this.calculateRMTable1RiskRating(this.dataRecord.RM_Table_1_Risk_5_Likelihood_1__c,this.dataRecord.RM_Table_1_Risk_5_Consequence_1__c);
            this.RiskRating.RMTable1Risk5Rating2=this.calculateRMTable1RiskRating(this.dataRecord.RM_Table_1_Risk_5_Likelihood_2__c,this.dataRecord.RM_Table_1_Risk_5_Consequence_2__c);
            this.RiskRating.RMTable1Risk6Rating1=this.calculateRMTable1RiskRating(this.dataRecord.RM_Table_1_Risk_6_Likelihood_1__c,this.dataRecord.RM_Table_1_Risk_6_Consequence_1__c);
            this.RiskRating.RMTable1Risk6Rating2=this.calculateRMTable1RiskRating(this.dataRecord.RM_Table_1_Risk_6_Likelihood_2__c,this.dataRecord.RM_Table_1_Risk_6_Consequence_2__c);
            this.calculateRMTable1RiskScore();
            this.calculateRMTable2SubCriteriaWeight1();
            this.calculateRMTable2SubCriteriaWeight2();
            this.calculateRMTable2SubCriteriaWeight3();
            this.calculateRMTable2OverallScore();
            this.RiskRating.DMTable1RiskLevel1=this.calculateDMTable1RiskLevel1(this.dataRecord.DM_Table_1_Parameter_1_Measure__c);
            this.RiskRating.DMTable1RiskLevel4=this.calculateDMTable1RiskLevel1(this.dataRecord.DM_Table_1_Parameter_4_Measure__c);
            this.RiskRating.DMTable1RiskLevel5=this.calculateDMTable1RiskLevel2(this.dataRecord.DM_Table_1_Parameter_5_Measure__c);
            this.RiskRating.DMTable1RiskLevel6=this.calculateDMTable1RiskLevel2(this.dataRecord.DM_Table_1_Parameter_6_Measure__c);
            this.RiskRating.DMTable1RiskLevel7=this.calculateDMTable1RiskLevel1(this.dataRecord.DM_Table_1_Parameter_7_Measure__c);
            this.RiskRating.DMTable1RiskLevel8=this.calculateDMTable1RiskLevel2(this.dataRecord.DM_Table_1_Parameter_8_Measure__c);
            this.RiskRating.DMTable1RiskLevel9=this.calculateDMTable1RiskLevel2(this.dataRecord.DM_Table_1_Parameter_9_Measure__c);
            this.RiskRating.DMTable1RiskLevel10=this.calculateDMTable1RiskLevel2(this.dataRecord.DM_Table_1_Parameter_10_Measure__c);
            this.RiskRating.DMTable1RiskLevel11=this.calculateDMTable1RiskLevel2(this.dataRecord.DM_Table_1_Parameter_11_Measure__c);
            this.RiskRating.DMTable1RiskLevel12=this.calculateDMTable1RiskLevel2(this.dataRecord.DM_Table_1_Parameter_12_Measure__c);

            // Check the Quote status and update UI accordingly
            if(this.dataRecord.Quote__r.Status=='Approved' ||  this.dataRecord.Quote__r.Status=='Finalized' || ( this.dataRecord.Quote__r.Status=='Submitted for Approval' &&
                this.loggedInUserDetails.Persona__c!='PED Head Sales - T Band' & this.loggedInUserDetails.Persona__c!='PED Head Sales - E Band'))
            {
                this.DivCSSType='readOnlyDiv';
                this.showFooter=false;
            }  
            this.showDetails=true;
            })
        .catch(error=>{
            this.showToast('Error', error.body.message, 'error');
        });
    }

   

    saveDetails(event) {
        var checkValidity=true;
        var savetype=event.currentTarget.dataset.name;
        // Used to check that all the required fields have been filled.
        this.template.querySelectorAll('lightning-input-field').forEach(element => {
            element.reportValidity();
            console.log("saveDetails button clicked"+element.reportValidity());
            
            if(element.reportValidity()==false){
                checkValidity=false;
            }
        });

        // If all required fields have been filled save the record and show success message else throw error and show error message.
        if(checkValidity || savetype =='tempSave' ){
            var isORMFormCompleted= checkValidity ? true : false ;
            updateOrderRiskMatrixRecord({orderRiskMatrixRecord : this.dataRecord,isORMFormCompleted : isORMFormCompleted })
            .then(result => {
                this.showToast('success', 'Order risk matrix record updated succesfully.','success');
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: this.recordId,
                        objectApiName: 'Quote',
                        actionName: 'view'
                    }
                });
            })
            .catch(error => {
                this.showToast('Error', error.body.message, 'error');
            });
        }else{
            this.showToast('Error','Please complete all mandatory fields', 'error');
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant,
            }),
        );
    }

    cancelOperation(event) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: 'Quote',
                actionName: 'view'
            }
        });
    }

    handleInputChange(event) {
        const fieldName = event.currentTarget.dataset.name;
        this.dataRecord[fieldName] = event.detail.value;
    }

    handleRMTable1LikeConChange(event) {
        const fieldName = event.currentTarget.dataset.name;
        const likelihood = event.currentTarget.dataset.likelihood;
        const consequence = event.currentTarget.dataset.consequence;
        const riskrating = event.currentTarget.dataset.riskrating;
        this.dataRecord[fieldName] = event.detail.value;  
        this.RiskRating[riskrating]=this.calculateRMTable1RiskRating(this.dataRecord[likelihood],this.dataRecord[consequence]);
        this.calculateRMTable1RiskScore();
    }

    calculateRMTable1RiskRating(likelihood, consequence) {
        const riskRatingTable = {
            'Almost Certain': {'Extreme': 'R','High': 'R','Moderate': 'R','Low': 'A','Negligible': 'A'},
            'Likely': {'Extreme': 'R','High': 'R','Moderate': 'A','Low': 'A','Negligible': 'Y'},
            'Possible': {'Extreme': 'R','High': 'A','Moderate': 'A','Low': 'Y','Negligible': 'Y'},
            'Unlikely': {'Extreme': 'R','High': 'A','Moderate': 'Y','Low': 'Y','Negligible': 'G'},
            'Rare': {'Extreme': 'A','High': 'Y','Moderate': 'Y','Low': 'G','Negligible': 'G'}
        };

        if (likelihood in riskRatingTable && consequence in riskRatingTable[likelihood]) {
            return riskRatingTable[likelihood][consequence];
        }

        return ' ';
    }

    calculateRMTable1RiskScore() {
        this.RiskRating.riskScore = 0;

        const riskMappings = {
            R: 4,
            A: 3,
            Y: 2,
        };

        const fieldsToCheck = [
            'RMTable1Risk1Rating2',
            'RMTable1Risk2Rating2',
            'RMTable1Risk4Rating2',
            'RMTable1Risk6Rating2',
        ];

        for (const field of fieldsToCheck) {
            const rating = this.RiskRating[field];
            if (riskMappings.hasOwnProperty(rating)) {
            this.RiskRating.riskScore += riskMappings[rating];
            } else {
            this.RiskRating.riskScore += 1;
            }
        }

        if (this.RiskRating.riskScore > 0) {
            this.RiskRating.riskScore = Math.round((this.RiskRating.riskScore / (fieldsToCheck.length * 4)) * 100);
        }

        this.dataRecord.DM_Table_1_Parameter_2_Measure__c = this.RiskRating.riskScore > 50 ? 'Yes' : 'No' ;
        this.RiskRating.DMTable1RiskLevel2 = this.RiskRating.riskScore > 50 ? 'R' : 'G' ;
    }

    handleRMTable2CriteriaChange(event){
        if(event.currentTarget.dataset.name == 'RM_Table_2_Sub_Criteria_1__c'){
            this.dataRecord.RM_Table_2_Sub_Criteria_1__c = event.detail.value;
            this.calculateRMTable2SubCriteriaWeight1();
        }        
        else if(event.currentTarget.dataset.name == 'RM_Table_2_Sub_Criteria_2__c'){
            this.dataRecord.RM_Table_2_Sub_Criteria_2__c = event.detail.value;
            this.calculateRMTable2SubCriteriaWeight2();
        }        
        else{
            this.dataRecord.RM_Table_2_Sub_Criteria_3__c = event.detail.value;
            this.calculateRMTable2SubCriteriaWeight3();
        } 
        this.calculateRMTable2OverallScore();

    }

    calculateRMTable2SubCriteriaWeight1(){
        if(this.dataRecord.RM_Table_2_Sub_Criteria_1__c=='High')
            this.RiskRating.RMTable2SubCriteriaWeight1=60;
        else if(this.dataRecord.RM_Table_2_Sub_Criteria_1__c=='Medium')
            this.RiskRating.RMTable2SubCriteriaWeight1=30;
        else if(this.dataRecord.RM_Table_2_Sub_Criteria_1__c=='Low')
            this.RiskRating.RMTable2SubCriteriaWeight1=10;    
    }

    calculateRMTable2SubCriteriaWeight2(){
        if(this.dataRecord.RM_Table_2_Sub_Criteria_2__c=='Product/Service in restricted list')
            this.RiskRating.RMTable2SubCriteriaWeight2=85;
        else if(this.dataRecord.RM_Table_2_Sub_Criteria_2__c=='Product/Service not in Restricted List')
            this.RiskRating.RMTable2SubCriteriaWeight2=15;
    }

    calculateRMTable2SubCriteriaWeight3(){  
        if(this.dataRecord.RM_Table_2_Sub_Criteria_3__c=='Contract Value greater than INR 50 crs')
            this.RiskRating.RMTable2SubCriteriaWeight3=60;
        else if(this.dataRecord.RM_Table_2_Sub_Criteria_3__c=='Contract Value between INR 15 crs to 50 crs')
            this.RiskRating.RMTable2SubCriteriaWeight3=30;
        else if(this.dataRecord.RM_Table_2_Sub_Criteria_3__c=='Contract Value less than INR 15 crs')
            this.RiskRating.RMTable2SubCriteriaWeight3=10;  
    }

    calculateRMTable2OverallScore(){
        this.RiskRating.RMTable2OverallScore=((25 * this.RiskRating.RMTable2SubCriteriaWeight1) + (40 * this.RiskRating.RMTable2SubCriteriaWeight2) + (35 * this.RiskRating.RMTable2SubCriteriaWeight3))/100;
        this.RiskRating.RMTable2RiskProfile=this.RiskRating.RMTable2OverallScore>=30 ? 'High' : this.RiskRating.RMTable2OverallScore<=20 ? 'Low' : 'Medium'
        this.dataRecord.DM_Table_1_Parameter_3_Measure__c = this.RiskRating.RMTable2OverallScore>30 ? 'Yes' : 'No';
        this.RiskRating.DMTable1RiskLevel3 = this.RiskRating.RMTable2OverallScore>30 ? 'R' : 'G';        
    }

    handleDMTable1ParameterMeasureChange1(event) {
        const fieldName = event.currentTarget.dataset.name;
        const risklevel = event.currentTarget.dataset.risklevel;
        this.dataRecord[fieldName] = event.detail.value;
        this.RiskRating[risklevel]=this.calculateDMTable1RiskLevel1(this.dataRecord[fieldName]);       
    }

    handleDMTable1ParameterMeasureChange2(event) {
        const fieldName = event.currentTarget.dataset.name;
        const risklevel = event.currentTarget.dataset.risklevel;
        this.dataRecord[fieldName] = event.detail.value;
        this.RiskRating[risklevel]=this.calculateDMTable1RiskLevel2(this.dataRecord[fieldName]);        
    }

    calculateDMTable1RiskLevel1(measure){
        return measure === 'No' ? 'R' : measure === 'Yes' ? 'G' : measure === 'Not Applicable' ? 'Not Applicable' : undefined;       
    }

    calculateDMTable1RiskLevel2(measure){
        return measure === 'No' ? 'G' : measure === 'Yes' ? 'R' : measure === 'Not Applicable' ? 'Not Applicable' : undefined; 
    }
}