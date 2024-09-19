import { LightningElement } from 'lwc';

export default class GenerateOutwardClaimLWC extends LightningElement {
    value = 'Advance - Chargeable';
    claimStatusValue = 'Initiated';
    get claimRequestedDate () {
        var today = new Date();
        console.log(today.toISOString())
        var last=new Date(new Date().getFullYear(), 11, 32);
        var date1=last.toISOString();
        return today.toISOString()
    }
    get claimStatusOptions() {
        return [
            { label: 'Initiated', value : 'Initiated'},
        ];
    }
    get options() {
        return [
            { label: 'Advance - Chargeable', value: 'Advance - Chargeable' },
            { label: 'Consumed-Chargeable', value: 'Consumed-Chargeable' },
            { label: 'Advance-FOC', value: 'Advance-FOC' },
            { label: 'Consumed-FOC', value: 'Consumed-FOC' },
            { label: 'Manual Request-Chargeable', value: 'Manual Request-Chargeable' },
            { label: 'Counter Sales-Chargeable', value: 'Counter Sales-Chargeable' },
            { label: 'Dispute-Short', value: 'Dispute-Short' },
            { label: 'Dispute-Damage/Wrong/Stock Return', value: 'Dispute-Damage/Wrong/Stock Return' },
        ];
    }

    handleChange(event) {
        this.value = event.detail.value;
    }

    handleClaimStatusChange(event) {
        this.claimStatusValue = event.detail.value;
    }

    handleGenerate(event) {

    }
}