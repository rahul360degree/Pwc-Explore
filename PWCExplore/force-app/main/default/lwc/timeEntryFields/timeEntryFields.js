import { LightningElement, api } from 'lwc';

export default class TimeEntryFields extends LightningElement {
    @api startTime;
    @api endTime;

    handleStartTimeChange(event) {
        this.startTime = event.target.value;
    }

    handleEndTimeChange(event) {
        this.endTime = event.target.value;
    }
}