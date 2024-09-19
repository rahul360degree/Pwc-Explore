import { LightningElement, wire, track, api } from 'lwc';
import getOQChoices from '@salesforce/apex/ServiceAuditController.getOQChoices'
import updateCallAuditForm from '@salesforce/apex/ServiceAuditController.updateCallAuditForm'
import getFormSubmitted from '@salesforce/apex/ServiceAuditController.getFormSubmitted'

export default class ServiceAuditReportCallAuditForm extends LightningElement
{

    @api recordId;

    @track SARLI_to_OQ_Records;
    
    @track sections = [];
    @track currentSelectedChoicesMap = {};

    @track formSubmitted = false;

    /* section in sections  
    {
        id = SARLI.id,
        question_text = SARLI.OQ_LU_r.question_text,
        choices = [SARLI.choice1, SARLI.choice2...]
    }*/

    connectedCallback()
    {
        console.log('all sections', this.sections)
    }

    @wire(getFormSubmitted, {sarId: '$recordId'})
    async getFormSubmitted({error, data})
    {
        if(data)
        {
            console.log('is it submitted', data)

            this.formSubmitted = data;
            console.log('is the form submitted', this.formSubmitted)
        }
        
    }

    @wire(getOQChoices, {sarId: '$recordId'})
    async getOQChoices({error, data})
    {
        if(data)
        {
            this.SARLI_to_OQ_Records = data;
            console.log('all SARLI records in call audit', this.SARLI_to_OQ_Records)

            this.SARLI_to_OQ_Records.forEach(async (SARLI_to_OQ_Record) =>
            {
                console.log('current SARLI record in Call Audit',SARLI_to_OQ_Record)
                
            
                this.currentSelectedChoicesMap[SARLI_to_OQ_Record.Id] = SARLI_to_OQ_Record.Response__c

                //console.log(this.currentSelectedChoicesMap)

                const choicesMap = await this.formatChoices(SARLI_to_OQ_Record.Observation_Question_LU__r.Choices__c)

                this.sections.push(
                    {
                        Id: SARLI_to_OQ_Record.Id,
                        question: SARLI_to_OQ_Record.Observation_Question_LU__r.Question_Text__c,
                        value: SARLI_to_OQ_Record.Response__c ? SARLI_to_OQ_Record.Response__c : '',
                        choices: choicesMap,
                        additionalDetailsRequired: SARLI_to_OQ_Record.Observation_Question_LU__r.Additional_Details_Required__c ? SARLI_to_OQ_Record.Observation_Question_LU__r.Additional_Details_Required__c : false
                    }
                )
            })
            /*this.SARLI_to_OQ_Records.forEach((SARLI_to_OQ_Record) =>
            {
                console.log(SARLI_to_OQ_Record.Id)
                console.log(SARLI_to_OQ_Record.Response__c)
                console.log(SARLI_to_OQ_Record.Observation_Question_LU__r.Question_Text__c)
                console.log(SARLI_to_OQ_Record.Observation_Question_LU__r.Choices__c)
            })*/
        }
    }

    async formatChoices(choicesString)
    {
        let choicesList = choicesString.split('\r\n')
        let choicesMap = choicesList.map(choice =>
            {
                return {
                    label: choice.trim(),
                    value: choice.trim()
                }
            })

        return choicesMap;
    }

    handleChange(event)
    {
        let selectedChoice = event.detail.value;
        let selectedId = event.target.name;

        this.currentSelectedChoicesMap[selectedId] = selectedChoice;
        console.log(this.currentSelectedChoicesMap)
    }

    handleSubmit()
    {
        // need to convert { id1: 'selchoice1', id2: 'selchoice2', id3: 'selchoice3'} = [{ Id: id1, Response__c: 'selchoice1'}, {Id: id2, Response__c: 'selchoice2'}]
        const updatedSARLIRecords = Object.keys(this.currentSelectedChoicesMap).map(key => ({
             Id: key, 
             Response__c: this.currentSelectedChoicesMap[key]}))
        
        console.log('submit was pressed')
        const radioGroups = [...this.template.querySelectorAll('lightning-radio-group')]
        const lightningInputs = [...this.template.querySelectorAll('lightning-input')]
        console.log('radio groups before' , radioGroups[0].disabled)
        
        radioGroups.forEach(radioGroup =>
            {
                radioGroup.disabled = true;
            })

        lightningInputs.forEach(lightningInput =>
            {
                lightningInput.disabled = true;
            })
        

        //console.log('disabled')
        
        // const radioGroupsAfter = [...this.template.querySelectorAll('lightning-radio-group')]
        // console.log('radio groups after', radioGroupsAfter[0].disabled)


        //console.log(updatedSARLIRecords, updateSubmitted)

        let updateFormSubmitted = [{ Id: this.recordId, Submitted__c: true}]

        updateCallAuditForm({ updatedSARLIRecords: updatedSARLIRecords, updateFormSubmitted : updateFormSubmitted }).then(result =>
            {
                console.log('records updated successfully')
            }).catch(error)
            {
                console.log('records did not update')
            }

        


        
    }
}