import { LightningElement, api, track, wire } from 'lwc';
import updatePercentageAchieved from '@salesforce/apex/ServiceAuditController.updatePercentageAchieved'
import getExcludeObservation from '@salesforce/apex/ServiceAuditController.getExcludeObservation'
//import updateResponseRequiredOnServiceAudit from '@salesforce/apex/ServiceAuditController.updateResponseRequiredOnServiceAudit'
import { refreshApex } from '@salesforce/apex'
const CSS_CLASS = "modal-hidden";

export default class ServiceAuditReportRecordEditForm extends LightningElement 
{
    @track showModal = false;

    @api formsubmitted;
    @api recordeditdataid;
    @api profiledata;
    @api sarmetadata;
    //@api recordeditdataid;

    @track isDisabled = false;
    @track lightningButtonDisabled = false;
    @track excludeObservation;

    @track spinner = true;
    
    connectedCallback()
    {
        // console.log('when record edit form opens', this.profiledata.profile);
        // console.log('when record edit form opens', this.profiledata.isAuditor);
        // console.log('when record edit form opens', this.profiledata.isAuditee);
        console.log('SAR metadata', this.sarmetadata.isASPAudit, this.sarmetadata.AuditType)
    }

    @api show()
    {
        
        console.log('child component recordeditdataid', this.recordeditdataid)
        this.showModal = false;
        console.log('showmodal value before', this.showModal)
        this.showModal = !this.showModal;
        console.log('showmodal value after', this.showModal)

        console.log('modal should be displayed')
        setTimeout(() => 
        {
            
            let ExcludeObservationElementValue = [...this.template.querySelectorAll('lightning-input-field[data-id="Exclude_Observation__c"]')][0].value
             this.isDisabled = ExcludeObservationElementValue;
             //this.spinner = false;
        }, 1700)
        
    }
    
    // method to update the OA percentage when the record edit form is submitted

    // @wire(getExcludeObservation, { sarliId: this.recordeditdataid })
    // wiredGetExcludeObservation ( {error, data })
    // {
    // console.log('the data', data)
    // this.excludeObservation = data;
    // console.log('is observation excluded', this.excludeObservation)
    //  }
    
    async handleSuccess(event)
    {

        // console.time('update')
        // console.log('event detail values', event.detail)
        // console.log('this is the event.detail.id', event.detail.id)
        await updatePercentageAchieved( {sarliId : event.detail.id }).then(result =>
            {
                console.log('percentage updated successfully')
            }).catch((error) =>
                {
                    console.log('percentage not updated')
                })
        // console.log('fired')

        setTimeout(() => this.dispatchEvent(new CustomEvent("modalsave", {detail: 
            {
                sarliId: event.detail.id
            }})), 1000) 

        console.log('event has been dispatched from child -> parent', event.detail.id)

        console.timeEnd('update')
        // no point in adding delay here
        this.handleDialogClose()
        
    }

    // closes the modal
    
    handleDialogClose()
    {
        this.showModal = !this.showModal;
    }

    handleAchievedScoreChange(event)
    {
        let AchievedScore = event.target.value
        console.log('entered achieved score', AchievedScore)
        let MaximumScoreStringText = [...this.template.querySelectorAll('lightning-output-field[data-id="Maximum_Score__c"]')][0].outerText
        let MaximumScoreStringArray = MaximumScoreStringText.split('\n')
        let MaximumScoreStringValue = MaximumScoreStringArray[MaximumScoreStringArray.length - 1]
        let MaximumScore = parseFloat(MaximumScoreStringValue)
        console.log('maximum score', MaximumScore)

        let errorMessage = [...this.template.querySelectorAll('.error-message')][0]
        console.log(errorMessage)

        if (AchievedScore > MaximumScore)
        {
            errorMessage.innerText = "Achieved Score cannot be more than the Maximum Score. Please enter a lower value.";
            let LightningButtonElement = [...this.template.querySelectorAll('lightning-button[data-id="lightning-button"]')][0];
            this.lightningButtonDisabled = true

        }
        else
        {
            errorMessage.innerText = ""
            this.lightningButtonDisabled = false
        }
    }

    handleExcludeObservationChange(event)
    {
        let ExcludeObservationBool = event.target.value
        console.log('excludeobservationbool', ExcludeObservationBool)

        let AchievedScoreElement = [...this.template.querySelectorAll('lightning-input-field[data-id="Achieved_Score__c"]')][0]
        let RecommendationElement = [...this.template.querySelectorAll('lightning-input-field[data-id="Recommendation__c"]')][0]
        let ObservationDetailsElement = [...this.template.querySelectorAll('lightning-input-field[data-id="Observation_Details__c"]')][0]

        this.isDisabled = !this.isDisabled
        
        // if (ExcludeObservationBool = true)
        //     {
        //         // AchievedScoreElement.setAttribute("disabled", 'true');
        //         // RecommendationElement.setAttribute("disabled", 'true');
        //         // ObservationDetailsElement.setAttribute("disabled", 'true');
                
        //         //console.log(AchievedScoreElement.disabled, RecommendationElement.disabled, ObservationDetailsElement.disabled)
                
        //     }
        // else if(ExcludeObservationBool = false)
        // {
        //     this.isDisabled = false
        // }

    }
}