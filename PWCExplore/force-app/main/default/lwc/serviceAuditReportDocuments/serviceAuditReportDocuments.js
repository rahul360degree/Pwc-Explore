import { LightningElement, api, wire, track } from 'lwc';
import getOAData from '@salesforce/apex/ServiceAuditController.getOAData';
import linkUploadedDocumentsToOA from '@salesforce/apex/ServiceAuditController.linkUploadedDocumentsToOA';
import getDocumentRecordsByOAIds from '@salesforce/apex/ServiceAuditController.getDocumentRecordsByOAIds';

import { refreshApex } from '@salesforce/apex'
export default class ServiceAuditReportDocuments extends LightningElement {

        @api recordId;

        @track oaRecords = [];
        @track documentRecordsByOA = {};

        @track sections = [];

        @track isActionsMenuOpen = false
        
        acceptedFormats = ['.pdf', '.png', '.jpg', '.jpeg', '.txt']

        actions = [
            { label: 'View File', name: 'view', value: 'view'}
        ]

        // columns = [
        //     { label: 'File Name', fieldName: 'Title', type: 'text', editable: false},
        //     { label: 'File Type', fieldName: 'FileExtension', type: 'text', editable: false},
        //     {
        //         type: 'action',
        //         typeAttributes: { rowActions: this.actions },
        //     },
        // ]
        handleOnSelect(event)
        {
            const selectedMenuItemValue = event.detail.value;
            const cardId = event.currentTarget.dataset.id

            console.log(cardId)
            if (selectedMenuItemValue == 'view')
            {
                window.open('/lightning/r/ContentDocument/' + cardId + '/view')
            }
        }
        handleUploadFinished(event) 
        {
            //console.log(event.detail.files)
            const OAId = event.target.recordId;
            //console.log(OAId)
            const uploadedFileIds = event.detail.files.map(file => ({
                id: file.documentId,
            }))

            
            linkUploadedDocumentsToOA({ OAId, uploadedFileIds}).then(result =>
                {
                    console.log('documents uploaded and linked to OA', result)
                })
                .catch(error => 
                    {
                        console.log('documents not uploaded', error)
                    })

            window.location.reload()
        }
        
        handleRowAction(event)

        {
            const actionName = event.detail.action.name;
            const row = event.detail.row;
            switch (actionName)
            {
                case 'view':
                    window.open('/lightning/r/ContentDocument/' + row.Id + '/view')
                    break;
                default:

            }
           
        }

        @wire(getOAData, { sarId: '$recordId'})
        async wiredGetOARecords ({ error, data })
        {
            if (data)
            {
                
                this.oaRecords = data;      
                //console.log('all OAs 1', this.oaRecords)    
                const documentRecords = await this.loadDocumentRecords();
                //console.log('all OAs 2', this.oaRecords)  
                //console.log('get sarli', await this.sarliRecordsByOA['a3SC40000004XQPMA2'])
                console.log('data', data)
                this.oaRecords.forEach((oaRecord) => 
                {
                    console.log('test OA', oaRecord)
            
                    data = [];
                    if (this.documentRecordsByOA.hasOwnProperty(oaRecord.Id))
                    {
                        this.documentRecordsByOA[oaRecord.Id].forEach((documentRecord) =>
                        {

                        //console.log('array', sarliRecord)

                            data.push({
                                    Id: documentRecord.Id, 
                                    Title: documentRecord.Title,
                                    FileExtension: documentRecord.FileExtension,
                                    CreatedBy: documentRecord.CreatedBy.Name,
                                    Icon: "doctype:" + String(documentRecord.FileExtension).toLowerCase()
                                }
                            )

                        
                        })
                    }
                    let section = 
                    {
                        Id: oaRecord.Id,
                        name: oaRecord.Name,
                        data: data ? data: '',
                    }

                    if (data.length == 0)
                    {
                        section.NoFiles = true;
                    }
                    else
                    {
                        section.NoFiles = false;
                    }

                    console.log('section', section)
                    this.sections.push(section);
                })


                // console.log(this.recordId)
                 console.log('all sections', this.sections)
                // console.log('SARLI Records outside', this.sarliRecordsByOA)
            }

            else if (error)
            {
                console.log('oa records not present')
                // handle error
            }
        }

        async loadDocumentRecords() 
        {
            const oaIds = this.oaRecords.map(oa => oa.Id);
            //console.log('oaIds', oaIds);

            // getSARLIRecordsByOAIds({ oaIds })
            // .then(result => {
            //     this.sarliRecordsByOA = result;
            //     //console.log('works)
            //     console.log('SARLI Records inside', this.sarliRecordsByOA)
            // })
            //     .catch(error => {
            //         console.error('Error fetching SARLI records', error);
            //     });

            const result = await getDocumentRecordsByOAIds({ oaIds })
            this.documentRecordsByOA = result;
            console.log('Document Records', this.documentRecordsByOA)
            
        } 

        
        onClickHandler(event)
        {
            console.log(event.target.id) //for id
            //console.log('parent', event.target.parentElement.parentElement.parentElement.className)
            //console.log('parent', event.target)
            //let sectionElement = this.template.querySelectorAll('section[id="' + event.target.id + '"]');
            
            //console.log(this.template.querySelectorAll('section[id="' + event.target.id + '"]'))
            //console.log('selected section', $("'section#" + event.target.id + "'"))
            
            let sectionAccordionHeader = [...this.template.querySelectorAll('section[id="' + event.target.id + '"]')][0];
            console.log(sectionAccordionHeader)
            let divAccordionSection = [...this.template.querySelectorAll('div[id="' + event.target.id + '"]')][0];
            console.log(divAccordionSection.hidden)
            let buttonAccordionHeader = [...this.template.querySelectorAll('button[id="' + event.target.id + '"]')][0];
            console.log(buttonAccordionHeader)

            let iconAccordion = [...this.template.querySelectorAll('lightning-icon[id="' + event.target.id + '"]')][0];
            console.log(iconAccordion)

             //console.log(sectionAccordionHeader.className)
            //console.log(divAccordionSection.hidden)

            if(sectionAccordionHeader.className === "slds-accordion__summary")
            {

                sectionAccordionHeader.className = "slds-accordion__summary slds-is-open";
                divAccordionSection.removeAttribute("hidden");
                iconAccordion.iconName ="utility:chevrondown";

            }
            else if (sectionAccordionHeader.className = "slds-accordion__summary slds-is-open")
            {
                sectionAccordionHeader.className = "slds-accordion__summary"
                divAccordionSection.setAttribute("hidden", '');
                iconAccordion.iconName ="utility:chevronright";
            }

            console.log(divAccordionSection.hidden)
           

            //unique 3 digits added to id at the end

            //const matches = container.querySelectorAll("li[data-active='1']");
            //document.querySelectorAll("section[id='a3SC40000004WlMAE']")

            
        }
}