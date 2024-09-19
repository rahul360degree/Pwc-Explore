import { LightningElement, api, wire, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getOAData from '@salesforce/apex/ServiceAuditController.getOAData';
import getSARLIRecordsByOAIds from '@salesforce/apex/ServiceAuditController.getSARLIRecordsByOAIds';
import updateSARLIRecords from '@salesforce/apex/ServiceAuditController.updateSARLIRecords';

export default class ServiceAuditForm extends LightningElement {

        @api recordId;

        oaRecords = [];
        sarliRecordsByOA = {};

        @track sections = [];
        
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
            
                

        columns = 
        [
            { label: 'Question', fieldName: 'Observation_Question__c', type: 'text', editable: false, wrapText: true },
            { label: 'Maximum Score', fieldName: 'Maximum_Score__c', type: 'decimal', editable: false},
            { label: 'Achieved Score', fieldName: 'Achieved_Score__c', type: 'decimal', editable: true },
            { label: 'Observation Details', fieldName: 'Observation_Details__c', type: 'text', editable: true},
            { label: 'Recommendation', fieldName: 'Recommendation__c', type: 'text', editable: true}
        ]

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


        */
        
        @wire(getOAData, { sarId: '$recordId'})
        async wiredGetOARecords ({ error, data })
        {
            if (data)
            {
                
                this.oaRecords = data;  
                //console.log('oarec', this.oaRecords)           
                const sarliRecords = await this.loadSARLIRecords();

                console.log('sarli rec', this.sarliRecordsByOA)

                //console.log(this.sarliRecordsByOA['a3SC40000004WqvMAE'])
                //console.log('SARLI records', this.sarliRecordsByOA)
                
                this.oaRecords.forEach((oaRecord) => 
                {
                    //console.log(oaRecord.Id, oaRecord.Name)
            

                    data = [];
                    this.sarliRecordsByOA[oaRecord.Id].forEach((sarliRecord) =>
                    {

                        //console.log('array', sarliRecord)

                        data.push({
                                Id: sarliRecord.Id, 
                                Observation_Question__c: sarliRecord.Observation_Question__c,
                                Maximum_Score__c: sarliRecord.Maximum_Score__c,
                                Achieved_Score__c: sarliRecord.Achieved_Score__c,
                                Observation_Details__c: sarliRecord.Observation_Details__c,
                                Recommendation__c: sarliRecord.Recommendation__c
                            }
                        )

                        
                    })

                    let section = 
                    {
                        Id: oaRecord.Id,
                        name: oaRecord.Name,
                        data: data,
                        columns: this.columns,
                        status: oaRecord.Status__c
                    }

                    if(oaRecord.Percentile_Achieved__c)
                    {
                        section.percentile_achieved = oaRecord.Percentile_Achieved__c;
                        if (section.percentile_achieved >= 75.00)
                        {section.variant = 'base';}
                        else if (section.percentile_achieved < 75.00 && section.percentile_achieved >= 50.00)
                        {section.variant = 'warning'}
                        else if(section.percentile_achieved < 50.00)
                        {
                            section.variant = 'expired';
                        }
                    }
                    else
                    {
                        section.percentile_achieved = 0;
                        section.variant = 'expired';
                    }

                    this.sections.push(section);
                })

                // console.log(this.recordId)
                 console.log(this.oaRecords)

                // console.log('SARLI Records outside', this.sarliRecordsByOA)
            }

            else if (error)
            {
                console.log('oa records not present')
                // handle error
            }
        }

        async loadSARLIRecords() 
        {
            const oaIds = this.oaRecords.map(oa => oa.Id);
            console.log('oaIds', oaIds);

            // getSARLIRecordsByOAIds({ oaIds })
            // .then(result => {
            //     this.sarliRecordsByOA = result;
            //     //console.log('works)
            //     console.log('SARLI Records inside', this.sarliRecordsByOA)
            // })
            //     .catch(error => {
            //         console.error('Error fetching SARLI records', error);
            //     });

            const result = await getSARLIRecordsByOAIds({ oaIds})
            this.sarliRecordsByOA = result;
            console.log('SARLI Records', this.sarliRecordsByOA)
            
        } 
        
        //handling toggle
        handleSectionToggle(event) {
            // Fetch data for the section when it is expanded
            const sectionId = event.detail.name;
            const section = this.sections.find(sec => sec.Id === sectionId);
            if (section && section.data.length === 0) {
                // Fetch data here for the section if needed
                // For example: section.data = fetchData(sectionId);
            }
        }

        handleSave(event) {
            const draftValues = event.detail.draftValues;
        
            if (draftValues.length > 0) {
                //console.log(draftValues.length)
                const updatedRecords = draftValues.map(item => {
                    console.log(item)
                    return {
                        Id: item.Id,
                        Observation_Details__c: item.Observation_Details__c,
                        Achieved_Score__c: item.Achieved_Score__c,
                        Recommendation__c: item.Recommendation__c,
                    };
                    
                });
        
                // Call Apex method to update records if there are changes
                    updateSARLIRecords({ updatedRecords })
                        .then(result => {
                            // Handle success response
                            console.log('Records updated successfully:', result);
                            
                            // Optionally, refresh data after successful save
                            this.refreshData()
                        })
                        .catch(error => {
                            // Handle errors
                            console.error('there is Error updating records:', error);
                        })
            }
        }

        refreshData() {
            this.sarliRecordsByOA = {};
            this.wiredGetOARecords();
        }

        green
}



// import { LightningElement, track } from 'lwc';
// import './serviceAuditReportAccordionTest.css'
// export default class serviceAuditReportAccordionTest extends LightningElement {
//     @track sections = [
//         {
//             id: 'A',
//             name: 'ASP Structure and Owner Involvement',
//             data: [
//                 { id: '1', col1: 'Infrastructure - Available Area/ Utilization/ Housekeeping/ Location(Accessibility)/ Appearance/ Glow Sign Board/ Rate Chart', col2: '4.0', col3: '', col4: '' },
//                 { id: '2', col1: 'Internet connection/PC-Laptops/Printer/Power Backup', col2: '1.0', col3: '', col4: '' },
//                 { id: '3', col1: 'Safety - Fire Extinguishers/first aid / Safety Belts/ Workplace Safety/ Hygiene', col2: '1.0', col3: '', col4: '' },
//                 { id: '4', col1: 'ASP Owner - Involvement/ Delegation/ Performance/ Control/ Review Process/ Audit Implementations', col2: '4.0', col3: '', col4: '' },
//             ],
//             columns: [
//                 { label: 'Observation Question', fieldName: 'col1', type: 'text', wrapText: true, editable: false },
//                 { label: 'Maximum Score', fieldName: 'col2', type: 'text', editable: false },
//                 { label: 'Achieved Score', fieldName: 'col3', type: 'text', editable: true },
//                 { label: 'Recommendation', fieldName: 'col4', type: 'text', editable: true, wrapText: true, cellAttributes: { alignment: 'left', class: 'large-input' }  }
//             ]
//         },
//         {
//             id: 'B',
//             name: 'Adequacy of Resources',
//             data: [
//                 { id: '5', col1: 'Technicians & Support Staff -  Adequacy/ Retention/ Man-days/ Productivity', col2: '5.0', col3: '', col4: '' },
//                 { id: '6', col1: 'Uniforms & ID cards - Prescribed Format/ Details Available in system', col2: '2.0', col3: '', col4: '' },
//                 { id: '7', col1: 'Tools, Spares & Field documents - Availability of Power operated & other tools/ Quality/ Periodic Checks.', col2: '3.0', col3: '', col4: '' }
//             ],
//             columns: [
//                 { label: 'Observation Question', fieldName: 'col1', type: 'text', wrapText: true, editable: false },
//                 { label: 'Maximum Score', fieldName: 'col2', type: 'text', editable: false },
//                 { label: 'Achieved Score', fieldName: 'col3', type: 'text', editable: true },
//                 { label: 'Recommendation', fieldName: 'col4', type: 'text', editable: true, wrapText: true}
//             ]
//         }
//     ];

//     handleSectionToggle(event) {
//         // Fetch data for the section when it is expanded
//         const sectionId = event.detail.name;
//         const section = this.sections.find(sec => sec.id === sectionId);
//         if (section && section.data.length === 0) {
//             // Fetch data here for the section if needed
//             // For example: section.data = fetchData(sectionId);
//         }
//     }
// }