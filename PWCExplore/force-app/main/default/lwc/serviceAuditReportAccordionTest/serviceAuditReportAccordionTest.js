import { LightningElement, track } from 'lwc';
import './serviceAuditReportAccordionTest.css'
export default class serviceAuditReportAccordionTest extends LightningElement {
    @track sections = [
        {
            id: 'A',
            name: 'ASP Structure and Owner Involvement',
            data: [
                { id: '1', col1: 'Infrastructure - Available Area/ Utilization/ Housekeeping/ Location(Accessibility)/ Appearance/ Glow Sign Board/ Rate Chart', col2: '4.0', col3: '', col4: '' },
                { id: '2', col1: 'Internet connection/PC-Laptops/Printer/Power Backup', col2: '1.0', col3: '', col4: '' },
                { id: '3', col1: 'Safety - Fire Extinguishers/first aid / Safety Belts/ Workplace Safety/ Hygiene', col2: '1.0', col3: '', col4: '' },
                { id: '4', col1: 'ASP Owner - Involvement/ Delegation/ Performance/ Control/ Review Process/ Audit Implementations', col2: '4.0', col3: '', col4: '' },
            ],
            columns: [
                { label: 'Observation Question', fieldName: 'col1', type: 'text', wrapText: true, editable: false },
                { label: 'Maximum Score', fieldName: 'col2', type: 'text', editable: false },
                { label: 'Achieved Score', fieldName: 'col3', type: 'text', editable: true },
                { label: 'Recommendation', fieldName: 'col4', type: 'text', editable: true, wrapText: true, cellAttributes: { alignment: 'left', class: 'large-input' }  }
            ]
        },
        {
            id: 'B',
            name: 'Adequacy of Resources',
            data: [
                { id: '5', col1: 'Technicians & Support Staff -  Adequacy/ Retention/ Man-days/ Productivity', col2: '5.0', col3: '', col4: '' },
                { id: '6', col1: 'Uniforms & ID cards - Prescribed Format/ Details Available in system', col2: '2.0', col3: '', col4: '' },
                { id: '7', col1: 'Tools, Spares & Field documents - Availability of Power operated & other tools/ Quality/ Periodic Checks.', col2: '3.0', col3: '', col4: '' }
            ],
            columns: [
                { label: 'Observation Question', fieldName: 'col1', type: 'text', wrapText: true, editable: false },
                { label: 'Maximum Score', fieldName: 'col2', type: 'text', editable: false },
                { label: 'Achieved Score', fieldName: 'col3', type: 'text', editable: true },
                { label: 'Recommendation', fieldName: 'col4', type: 'text', editable: true, wrapText: true}
            ]
        }
    ];

    handleSectionToggle(event) {
        // Fetch data for the section when it is expanded
        const sectionId = event.detail.name;
        const section = this.sections.find(sec => sec.id === sectionId);
        if (section && section.data.length === 0) {
            // Fetch data here for the section if needed
            // For example: section.data = fetchData(sectionId);
        }
    }
}