import { LightningElement, api, wire, track } from 'lwc';
import getOAData from '@salesforce/apex/ServiceAuditController.getOAData';
import getSARLIRecordsByOAIds from '@salesforce/apex/ServiceAuditController.getSARLIRecordsByOAIds';
import updateSARLIRecords from '@salesforce/apex/ServiceAuditController.updateSARLIRecords';
import ServiceAuditReportRecordEditForm from 'c/serviceAuditReportRecordEditForm';
import getSARAuditType from '@salesforce/apex/ServiceAuditController.getSARAuditType'

import Penalty_Recovery__c from '@salesforce/schema/Observation_Area__c.Penalty_Recovery__c';
import Target_Date__c from '@salesforce/schema/Observation_Area__c.Target_Date__c';
import Auditor__c from '@salesforce/schema/Observation_Area__c.Auditor__c';
import BE_Remark__c from '@salesforce/schema/Observation_Area__c.BE_Remark__c';
import Auditor_Remark__c from '@salesforce/schema/Observation_Area__c.Auditor_Remark__c';
import Escalator_1__c from '@salesforce/schema/Observation_Area__c.Escalator_1__c';
import Escalator_2__c from '@salesforce/schema/Observation_Area__c.Escalator_2__c';
import First_Response_Date__c from '@salesforce/schema/Observation_Area__c.First_Response_Date__c'
import Closed_Response_Date__c from '@salesforce/schema/Observation_Area__c.Closed_Response_Date__c'


import getUserProfile from '@salesforce/apex/ServiceAuditController.getUserProfile';
import { refreshApex } from '@salesforce/apex';
import getFormSubmitted from '@salesforce/apex/ServiceAuditController.getFormSubmitted'
import getOAIdFromSARLIId from '@salesforce/apex/ServiceAuditController.getOAIdFromSARLIId'

export default class ServiceAuditReportForm extends LightningElement {

        // to show in Observation Area accordion sections
        fields = [Penalty_Recovery__c, Target_Date__c, Auditor__c, BE_Remark__c, Auditor_Remark__c, Escalator_1__c, Escalator_2__c, Closed_Response_Date__c, First_Response_Date__c]

        @api recordId;
        
        // sent over to serviceAuditReportRecordEdit with the data related to the row to be edited
        @track recordEditData;
        recordEditDataId;

        @track refreshOA;

        // this is what's going to contain all the old + new data
        @track refreshSARLI;

        // to store the OA and SARLI data retrieved from apex
        @track oaRecords = [];
        sarliRecordsByOA = {};

        // list of all the sections to be iterated over to render the accordion section and datatable
        @track sections = [];

        @track sarliRecordsDB = {}; 

        @track formSubmitted;

        flagForRefresh = false;
        sarliIdToBeChanged;
        oaIdToBeChanged;

        // used to retrieve current user's profile data and also set OA record form mode
        profileData = {};
        OA_record_form_mode;
        
        SAR_metadata = {};

        // list of actions to be displayed for each row of the datatable
        actions = 
        [
            { label: 'Edit', name: 'edit'}
        ]   

        // list of columns to be displayed for each datatable (for ASP)
        columns = 
        [
            { label: 'Question', fieldName: 'Observation_Question__c', type: 'text', editable: false, wrapText: true },
            { label: 'Maximum Score', fieldName: 'Maximum_Score__c', type: 'decimal',  editable: false},
            { label: 'Achieved Score', fieldName: 'Achieved_Score__c', type: 'decimal', editable: false },
            { label: 'Observation Details', fieldName: 'Observation_Details__c', type: 'text', editable: false, wrapText: false},
            { label: 'Recommendation', fieldName: 'Recommendation__c', type: 'text', editable: false, wrapText: false},
            { label: 'Corrective Actions', fieldName: 'Corrective_Actions__c', type: 'text',  editable: false, wrapText: false},
            { label: 'Preventive Actions', fieldName: 'Preventive_Actions__c', type: 'text',  editable: false, wrapText: false},
            { label: 'Status', fieldName: 'Status__c', type: 'text', editable: false, wrapText: true},
            { label: 'Exclude Observation', fieldName: 'Exclude_Observation__c', type: 'boolean', editable: false},
            {
                type: 'action',
                typeAttributes: { rowActions: this.actions},
            }
        ]

        columns_other =
        [
            { label: 'Question', fieldName: 'Observation_Question__c', type: 'text', editable: false, wrapText: true },
            { label: 'Observation Details', fieldName: 'Observation_Details__c', type: 'text', editable: false, wrapText: false},
            { label: 'Recommendation', fieldName: 'Recommendation__c', type: 'text', editable: false, wrapText: false},
            { label: 'Corrective Actions', fieldName: 'Corrective_Actions__c', type: 'text',  editable: false, wrapText: false},
            { label: 'Preventive Actions', fieldName: 'Preventive_Actions__c', type: 'text',  editable: false, wrapText: false},
            { label: 'Status', fieldName: 'Status__c', type: 'text', editable: false, wrapText: true},
            /*{ label: 'Exclude Observation', fieldName: 'Exclude_Observation__c', type: 'boolean', editable: false},*/
            {
                type: 'action',
                typeAttributes: { rowActions: this.actions},
            }
        ]



        // @track sections = [
        //             {
        //                 id: 'A',
        //                 name: 'ASP Structure and Owner Involvement',
        //                 data: [
        //                     { id: '1', col1: 'Infrastructure - Available Area/ Utilization/ Housekeeping/ Location(Accessibility)/ Appearance/ Glow Sign Board/ Rate Chart', col2: '4.0', col3: '', col4: '' },
        //                     { id: '2', col1: 'Internet connection/PC-Laptops/Printer/Power Backup', col2: '1.0', col3: '', col4: '' },
        //                     { id: '3', col1: 'Safety - Fire Extinguishers/first aid / Safety Belts/ Workplace Safety/ Hygiene', col2: '1.0', col3: '', col4: '' },
        //                     { id: '4', col1: 'ASP Owner - Involvement/ Delegation/ Performance/ Control/ Review Process/ Audit Implementations', col2: '4.0', col3: '', col4: '' },
        //                 ],
        //                 columns: [
        //                     { label: 'Observation Question', fieldName: 'col1', type: 'text', wrapText: true, editable: false },
        //                     { label: 'Maximum Score', fieldName: 'col2', type: 'text', editable: false },
        //                     { label: 'Achieved Score', fieldName: 'col3', type: 'text', editable: true },
        //                     { label: 'Recommendation', fieldName: 'col4', type: 'text', editable: true, wrapText: true, cellAttributes: { alignment: 'left', class: 'large-input' }  }
        //                 ]
        //             },
        //             {
        //                 id: 'B',
        //                 name: 'Adequacy of Resources',
        //                 data: [
        //                     { id: '5', col1: 'Technicians & Support Staff -  Adequacy/ Retention/ Man-days/ Productivity', col2: '5.0', col3: '', col4: '' },
        //                     { id: '6', col1: 'Uniforms & ID cards - Prescribed Format/ Details Available in system', col2: '2.0', col3: '', col4: '' },
        //                     { id: '7', col1: 'Tools, Spares & Field documents - Availability of Power operated & other tools/ Quality/ Periodic Checks.', col2: '3.0', col3: '', col4: '' }
        //                 ],
        //                 columns: [
        //                     { label: 'Observation Question', fieldName: 'col1', type: 'text', wrapText: true, editable: false },
        //                     { label: 'Maximum Score', fieldName: 'col2', type: 'text', editable: false },
        //                     { label: 'Achieved Score', fieldName: 'col3', type: 'text', editable: true },
        //                     { label: 'Recommendation', fieldName: 'col4', type: 'text', editable: true, wrapText: true}
        //                 ]
        //             }
        //         ];
            

        

        
        // columns = 
        // [
        //     { label: 'Question', fieldName: 'Observation_Question__c', type: 'text', initialWidth: 260, editable: false, wrapText: true },
        //     { label: 'Maximum Score', fieldName: 'Maximum_Score__c', type: 'decimal', initialWidth: 110, editable: false},
        //     { label: 'Achieved Score', fieldName: 'Achieved_Score__c', type: 'decimal', initialWidth: 110, editable: false },
        //     { label: 'Observation Details', fieldName: 'Observation_Details__c', type: 'text', initialWidth: 170, editable: false, wrapText: false},
        //     { label: 'Recommendation', fieldName: 'Recommendation__c', type: 'text', initialWidth: 160, editable: false, wrapText: false},
        //     { label: 'Corrective Actions', fieldName: 'Corrective_Actions__c', type: 'text', initialWidth: 160, editable: false, wrapText: false},
        //     { label: 'Preventive Actions', fieldName: 'Preventive_Actions__c', type: 'text', initialWidth: 170, editable: false, wrapText: false},
        //     {
        //         type: 'action',
        //         typeAttributes: { rowActions: this.actions},
        //     }
        // ]

        
        // connected callback runs when LWC component is loaded, currently fetching total width of the screen
       async connectedCallback()
        {
            console.log('fired')
        }

        @wire(getSARAuditType, { sarId: '$recordId'})
        wiredGetSARAuditType({error, data})
        {
            console.log('this is the data', data)
            if(data != 'ASP Audit')
                {
                    this.SAR_metadata.isASPAudit = false;
                    console.log('fired not ASP Audit')
                }
                else if(data == 'ASP Audit')
                {
                    this.SAR_metadata.isASPAudit = true;
                    console.log('fired ASP Audit')
                }
                this.SAR_metadata.AuditType = data;
    
                console.log('is ASP audit?', this.SAR_metadata.isASPAudit)
                console.log('audit type', this.SAR_metadata.AuditType)
            
        }


        @wire(getFormSubmitted, { sarId: '$recordId'})
        wiredGetFormSubmitted ( {error, data })
        {
        console.log('the data', data)
        this.formSubmitted = data;
        console.log('is the form submitted', this.formSubmitted)
         }
        
        async refreshData(event)
        {
            this.flagForRefresh = true;
            this.sarliIdToBeChanged = event.detail.sarliId
            // the refresh happens immediately only when i pause it here in the debugger and add a breakpoint.
            // i'm guessing i have to give this statement enough time to run.
            await refreshApex(this.refreshOA)
               // refreshApex(this.refreshSARLI)

            //setTimeout(() => console.log('this is the sarliId from child', event.detail.sarliId))
             

            //this.refreshSARLIDataTableForId(sarliId)


            // so here when the event is dispatched from child to parent, it's probably best to just rerender only
            // that datatable which is specific to the SARLI. so can fetch the SARLI Id from the event, and write
            // a new function that repopulates this.sarliRecordsbyOAId just for that OAId which can be fetched. 
            // because the issue now is that you're updating one SARLI and it's having to populate the entire
            // form SARLI again and again which is not required. 

        }   

       
        // wire method to fetch the user's profile. 

        // if auditor -> sets the OA record to edit mode and displays the auditor record edit form.
        // if auditee -> sets the OA record to read only mode and displays the auditee record edit form.

        // for now, checking if sysadmin as don't have access to ASP profile.
        // once ASP profile acquired, then change else into else if block and add the condition.
        

        @wire(getUserProfile)
        getUserProfile ({ error, data })
        {
            if (data)
            {
                this.profileData.profile = data;

                if (data == 'System Administrator')
                {     
                    this.profileData.isAuditor = true;
                    this.profileData.isAuditee = false;
                    this.OA_record_form_mode = "view"
                }


                // profile -> Partner Community User

                else if(data == 'Partner Community User')
                {
                    this.profileData.isAuditor = false;
                    this.profileData.isAuditee = true;
                    this.OA_record_form_mode = "readonly"
                }
                //console.log('profileData', this.profileData)
            }
        }

        handleResize(event)
        {
            //console.log(event.detail.columnWidths)
        }

        // event handler when user clicks on a row and displays all actions, calls editSARLIrecord on edit.
        handleRowAction(event)
        {
            const actionName = event.detail.action.name;
            const row = event.detail.row;
            console.log(row.Id)
            this.recordEditDataId = row.Id;

            switch(actionName)
            {
                case 'edit':
                    //console.log(rowId)

                    let modal = this.template.querySelector("c-service-Audit-Report-Record-Edit-Form")

                    //console.log(modal)

                    //this.recordEditData = await row.Id; 
                    

            
                    //console.log('recordeditdata id', this.recordEditDataId)
                    setTimeout(() => modal.show(), 1000);
                    break;
                    default:
            }
        }

        // asynchronous method to call child LWC and displays modal with record edit form, passes in the target id from the event
        async editSARLIrecord(row)
        {
            //console.log('this is the SARLI row Id', row.Id)
            //let divEditFormSection = [...this.template.querySelectorAll('div[id="' + rowId + '"]')][0];
            //console.log(row)
            
            //console.log('row Id', row.Id)
            //console.log('recordEditData', this.recordEditData)

            //console.log(this.recordEditData.Maximum_Score__c, this.recordEditData.Achieved_Score__c)
        }

        /* sample JSON

        section in sections:
        
        {
            id: 'observationAreaId',
            name: 'ObservationAreaName',
            percentage: 'ObservationAreaPercentage',
            status: 'ObservationAreaStatus',

            data: 
            [
            {id: 'SARLIId1',  Observation_Question__c: 'ObservationQuestion1'... ,Recommendation__c: 'Recommendation1'}
            {id: 'SARLIId2',  Observation_Question__c: 'ObservationQuestion2'... ,Recommendation__c: 'Recommendation2'}
            ]

            columns: this.columns;
        }


        {
            id: 'observationAreaId',
            name: 'ObservationAreaName',
            percentage: 'ObservationAreaPercentage',
            status: 'ObservationAreaStatus',

            data: 
            [
            {id: 'SARLIId1',  Observation_Question__c: 'ObservationQuestion1'... ,Recommendation__c: 'Recommendation1'}
            {id: 'SARLIId2',  Observation_Question__c: 'ObservationQuestion2'... ,Recommendation__c: 'Recommendation2'}
            ]

            columns: this.columns;
        }


        // rerender only section, don't rerender entire thing. 

        */
        
        // wire method to fetch OA data
        // populate 'sections' property for the required data in the datatable 
        // assigns colours to badge component based on percentage achieved
        @wire(getOAData, { sarId: '$recordId'})
        async wiredGetOARecords (result)
        {
            this.refreshOA = result;
            if (this.refreshOA.data)
            {   
                this.oaRecords = await this.refreshOA.data;  
                console.log('oa record runs', this.oaRecords)
         
                //setTimeout(() => this.loadSARLIRecords(), 1000);

                console.log('heres')
                console.time('start')
                await this.loadSARLIRecords()
                console.timeEnd('start')
                //console.log('SARLI Records', this.refreshSARLI)

                //console.log('get sarli', await this.sarliRecordsByOA['a3SC40000004XQPMA2'])
                let dataSections = [];

                console.time('time')
                this.oaRecords.forEach(async (oaRecord) => 
                {
                    //console.log(oaRecord.Id, oaRecord.Name)
                    let SARLIdata = [];

                    
                    this.sarliRecordsByOA[oaRecord.Id].forEach(async (sarliRecord) =>
                    {
                        //console.log('array', sarliRecord)
                        //console.log('this is the question', sarliRecord.Observation_Question_LU__r.Question_Text__c)
                        SARLIdata.push({
                                Id: sarliRecord.Id, 
                                Observation_Question__c: sarliRecord.Observation_Question_LU__r.Question_Text__c,
                                Maximum_Score__c: sarliRecord.Maximum_Score__c,
                                Achieved_Score__c: sarliRecord.Achieved_Score__c,
                                Observation_Details__c: sarliRecord.Observation_Details__c,
                                Recommendation__c: sarliRecord.Recommendation__c,
                                Corrective_Actions__c: sarliRecord.Corrective_Actions__c,
                                Preventive_Actions__c: sarliRecord.Preventive_Actions__c,
                                Status__c: sarliRecord.Status__c,
                                Response_Required__c: sarliRecord.Response_Required__c,
                                Exclude_Observation__c: sarliRecord.Exclude_Observation__c
                            
                            }
                        )
                    })

                    let section = await this.populateOASection(oaRecord, SARLIdata)
                    dataSections.push(section)
                    
                    //this.sections.push(section);
                })
                
                this.sections = dataSections;
                console.timeEnd('time')
                // till here shouldn't run if it's being refreshed
                // console.log(this.oaRecords)
                // console.log('SARLI Records outside', this.sarliRecordsByOA)
            }

            else if (error)
            {
                console.log('OA records not present')
                // handle error
            }
        }

        async populateOASection(oaRecord, SARLIdata)
        {
            let section =
            {
                Id: oaRecord.Id,
                name: oaRecord.Name,
                data: SARLIdata,
                status: oaRecord.Status__c
            }

            if (this.SAR_metadata.isASPAudit == true)
            {
                section.columns = this.columns
            }
            else 
            {
                section.columns = this.columns_other
            }

            // do not add await here
            if(oaRecord.Percentage_Achieved__c)
            {
                //section.Percentage_Achieved__c = oaRecord.Percentage_Achieved__c;
                if (oaRecord.Percentage_Achieved__c >= 75.00)
                {
                    section.style = 'background-color: #2cb52a; --slds-c-badge-sizing-border: 3px'
                }
                else if (oaRecord.Percentage_Achieved__c < 75.00 && oaRecord.Percentage_Achieved__c > 25.00)
                {
                    section.style = 'background-color: #ebba34; --slds-c-badge-sizing-border: 3px'
                }
                else if(oaRecord.Percentage_Achieved__c <= 25.00)
                {
                    section.style = 'background-color: #d13451; --slds-c-badge-sizing-border: 3px';
                }

                //console.log('percentage achieved', oaRecord.Percentage_Achieved__c)

                //over here, i'm assuming that the percentage has already been refreshed and reflected in the database
                // because oaRecord.Percentage_Achieved__c = updated percentage.
                //this assignment maybe has to be looked into? but section.percentage_achieved in the following line reflects the new percentage.

                // nothing wrong with assignments. 100% an issue with the timing. because when i use breakpoints and progress slowly it gets updated.
                // even with the SARLI table, it's an issue with the timing 

                // do not add await here
                section.percentage_achieved =  oaRecord.Percentage_Achieved__c + "%";
                //console.log('section percentage achieved', section.percentage_achieved)
            }
            else
            {
                section.style = 'background-color: #d13451; --slds-c-badge-sizing-border: 3px';
                section.percentage_achieved = '0%';
                
            }
            //console.log('section', section)
            return section
        }


        async loadSARLIRecords() 
        {
            
            
            //const result = await getSARLIRecordsByOAIds({ oaIds : oaIds })
            
            //console.log('result', result)
        
        
            //this.refreshSARLI = result;
            //console.log('this is refreshSARLI in loadSARLIRecords', this.refreshSARLI)

            const oaIds = this.oaRecords.map(oa => oa.Id);

            //runs when not refreshed -> at the start
            if(this.flagForRefresh == false)
            {
                let result = await getSARLIRecordsByOAIds({ oaIds : oaIds })
                this.sarliRecordsByOA = {...result};
            }
            else if (this.flagForRefresh == true)
            {
                //runs when refreshed
                this.oaIdToBeChanged = await getOAIdFromSARLIId({sarliId : this.sarliIdToBeChanged});
                
                //works
                let result = await getSARLIRecordsByOAIds({ oaIds : [this.oaIdToBeChanged] })
                let sarliRecordsByOAtemp = {...result};
                console.log('this.sarliRecordsByOA[this.oaIdToBeChanged]', this.sarliRecordsByOA[this.oaIdToBeChanged])
                console.log('sarliRecordsByOAtemp[this.oaIdToBeChanged]', sarliRecordsByOAtemp[this.oaIdToBeChanged])
                this.sarliRecordsByOA[this.oaIdToBeChanged] =  sarliRecordsByOAtemp[this.oaIdToBeChanged];

                //test
                // let result = await getSARLINew({ oaId: this.oaIdToBeChanged })
                // let sarliRecordsByOAtemp = {...result}

                // console.log('sarlirecordsbyOAtemp', sarliRecordsByOAtemp[this.oaIdToBeChanged])
                // //console.log('result is now', sarliRecordsByOAtemp[this.oaIdToBeChanged][0])
                // //console.log('this.sarliRecordsByOA achieved score', this.sarliRecordsByOA[this.oaIdToBeChanged][0])
                // //this.sarliRecordsByOA[this.oaIdToBeChanged].Achieved_Score__c = sarliRecordsByOAtemp[this.oaIdToBeChanged].Achieved_Score__c;
                // for (let index = 0; index<sarliRecordsByOAtemp[this.oaIdToBeChanged].length; index = index+1)
                // {
                //     if(sarliRecordsByOAtemp[this.oaIdToBeChanged][index].Achieved_Score__c != null)
                //     {
                //         this.sarliRecordsByOA[this.oaIdToBeChanged][index].Achieved_Score__c = sarliRecordsByOAtemp[this.oaIdToBeChanged][index].Achieved_Score__c
                //     }
                //     if(sarliRecordsByOAtemp[this.oaIdToBeChanged][index].Recommendation__c != null)
                //     {
                //         this.sarliRecordsByOA[this.oaIdToBeChanged][index].Recommendation__c = sarliRecordsByOAtemp[this.oaIdToBeChanged][index].Recommendation__c
                //     }
                //     if(sarliRecordsByOAtemp[this.oaIdToBeChanged][index].Observation_Details__c != null)
                //     {
                //         this.sarliRecordsByOA[this.oaIdToBeChanged][index].Observation_Details__c = sarliRecordsByOAtemp[this.oaIdToBeChanged][index].Observation_Details__c
                //     }
                //     if(sarliRecordsByOAtemp[this.oaIdToBeChanged][index].Status__c != null)
                //     {
                //         this.sarliRecordsByOA[this.oaIdToBeChanged][index].Status__c = sarliRecordsByOAtemp[this.oaIdToBeChanged][index].Status__c
                //     }
                //     if(sarliRecordsByOAtemp[this.oaIdToBeChanged][index].Response_Required__c != null)
                //     {
                //         this.sarliRecordsByOA[this.oaIdToBeChanged][index].Response_Required__c = sarliRecordsByOAtemp[this.oaIdToBeChanged][index].Response_Required__c
                //     }
                //     if(sarliRecordsByOAtemp[this.oaIdToBeChanged][index].Exclude_Observation__c != null)
                //     {
                //         this.sarliRecordsByOA[this.oaIdToBeChanged][index].Exclude_Observation__c = sarliRecordsByOAtemp[this.oaIdToBeChanged][index].Exclude_Observation__c
                //     }
                // }
            }

            
            
        } 

        handleSectionToggle(event) 
        {

            const sectionId = event.detail.name;
            const section = this.sections.find(sec => sec.Id === sectionId);
            /*if (section && section.data.length === 0) 
            {

            }*/
        }


        // event handler when accordion section is clicked to open and close
        onClickHandler(event)
        {
            //console.log(event.target.id) //for id
            //console.log('parent', event.target.parentElement.parentElement.parentElement.className)
            //console.log('parent', event.target)
            //let sectionElement = this.template.querySelectorAll('section[id="' + event.target.id + '"]');
            
            //console.log(this.template.querySelectorAll('section[id="' + event.target.id + '"]'))
            //console.log('selecdiv ted section', $("'section#" + event.target.id + "'"))
            
            let sectionAccordionHeader = [...this.template.querySelectorAll('section[id="' + event.target.id + '"]')][0];
            //console.log(sectionAccordionHeader)
            let divAccordionSection = [...this.template.querySelectorAll('div[id="' + event.target.id + '"]')][0];
            //console.log(divAccordionSection)
            let buttonAccordionHeader = [...this.template.querySelectorAll('button[id="' + event.target.id + '"]')][0];
            //console.log(buttonAccordionHeader)

            let iconAccordion = [...this.template.querySelectorAll('lightning-icon[id="' + event.target.id + '"]')][0];
            //console.log(iconAccordion)
            //console.log(sectionAccordionHeader.className)
            //console.log(divAccordionSection.hidden)
            console.log('this is the event target id', event.target.id)
            if(sectionAccordionHeader.className === "slds-accordion__summary")
            {

                sectionAccordionHeader.className = "slds-accordion__summary slds-is-open";
                divAccordionSection.removeAttribute("hidden");
                iconAccordion.iconName ="utility:chevrondown";
                

            }
            else if (sectionAccordionHeader.className = "slds-accordion__summary slds-is-open")
            {
                sectionAccordionHeader.className = "slds-accordion__summary"
                divAccordionSection.setAttribute("hidden", 'hidden');
                iconAccordion.iconName ="utility:chevronright";
                
            }

            //console.log(divAccordionSection.hidden)

            //const matches = container.querySelectorAll("li[data-active='1']");
            //document.querySelectorAll("section[id='a3SC40000004WlMAE']")

            
        }        
}