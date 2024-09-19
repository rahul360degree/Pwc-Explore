import { LightningElement, api, track, wire } from 'lwc';
import getSurveyQuestions from '@salesforce/apex/SurveyForceLWCController.getSurveyQuestions';

export default class CreateSurveyQuestion extends LightningElement
{
    @api recordId;
    @api surveyId;

    
    @track questionText = '';

    @api dependencyCriteria = '';

    @track logic = 'AND'
    @track conditions = [];
    
    @track conditionValueOptions = [];

    logicOptions = [
        { label: 'All conditions are met', value: 'AND' },
        { label: 'Any condition is met', value: 'OR'}
    ]

    operatorOptions = [
        { label: 'equals to', value: '==' },
        { label: 'not equal to', value: '!=' },
        { label: 'greater than', value: '>' },
        { label: 'greater than or equal to', value: '>=' },
        { label: 'less than', value: '<' },
        { label: 'less than or equal to', value: '<=' },
    ]

    @wire(getSurveyQuestions,  { surveyId: '$surveyId'})
    wiredSurveyQuestions({ error, data })
    {
        if(data)
        {
            console.log('data retrieved')
            console.log(data)
            this.questionOptions = data.map(question => 
                ({ label: `${question.Question__c} | ${question.Description__c}`, 
                    value: question.Id }))
            console.log('question options', this.questionOptions)
        }
        else
        {
            console.log('no survey selected or error')
        }
    }

    handleLogicChange(event)
    {
        this.logic = event.target.value;
        console.log('display logic is now ', this.logic)
        this.updateDependencyCriteria();
    }

    addCondition() {

        //const previousValues = this.conditions.map(condition => ({ questionId: condition.questionId, operator: condition.operator, value: condition.value }))

        this.conditions.push({
            questionId: '',
            operator: '',
            value: '',
            valueOptions: []
        })

        this.updateDependencyCriteria()
    }
    
    removeCondition(event)
    {
        const index = event.target.dataset.index;
        this.conditions.splice(index, 1);

       
        this.updateDependencyCriteria()
    }
    handleConditionChange(event)
    {
        const index = event.target.dataset.index;
        const field = event.target.dataset.field;
        const value = event.target.value;

        console.log('field', field);

        this.conditions[index][field] = value;

        //console.log('updated conditions', this.conditions)

      
        if (field == 'questionId')
        {

            this.loadConditionValueOptions(value, index);
        }

        this.updateDependencyCriteria();
    }

    async loadConditionValueOptions(questionId, index)
    {
        let result = await getSurveyQuestions({surveyId: this.surveyId})
        let question;

        for (let i = 0; i < result.length; i++)
        {
            if(result[i].Id === questionId)
            {
                question = result[i];
                break;
            }
        }
        console.log('question loadConditionValue', question)
        if(question)
        {
            this.conditions[index].valueOptions = question.Choices__c.split('\n').map((choice, idx) => ({ label: choice.trim(), value: idx.toString() }))
            console.log('value options', this.conditions[index].valueOptions)
            //this.conditionValueOptions = question.Choices__c.split('\n').map(choice => ({ label: choice, value: choice }))
        }
    }

    updateDependencyCriteria()
    {
        
        if(this.conditions.length === 0)
        {
            this.dependencyCriteria = '';
        }
        else
        {
            const criteria = 
            {
                logic: this.logic,
                conditions: this.conditions.map(condition => ({
                    questionId: condition.questionId,
                    operator: condition.operator,
                    value: condition.value.trim()
                }))
    
            }
            this.dependencyCriteria = JSON.stringify(criteria)
        }
        
        console.log('new dependency criteria', this.dependencyCriteria)
    }
}