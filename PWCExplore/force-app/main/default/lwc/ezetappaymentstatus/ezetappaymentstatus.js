/**
 * @Description       : 
 * @Author            : Varun Rajpoot
 * @last modified on  : 12-12-2023
 * @last modified by  : Varun Rajpoot
 * Modifications Log
 * Ver   Date         Author          Modification
 * 1.0   12-11-2023   Varun Rajpoot   Initial Version
**/
import { LightningElement, api, track } from 'lwc';

export default class Ezetappaymentstatus extends LightningElement {
    //@api calloutResponse;
    @api calloutResponseTrack;
    @api states;
    connectedCallback() {

    }

    @api
    get calloutResponse() {
        return this.calloutResponseTrack;
    }

    set calloutResponse(value) {
        this.calloutResponseTrack = value;
        if (this.calloutResponseTrack && this.calloutResponseTrack.states && typeof this.calloutResponseTrack.states !== 'undefined') {
            this.states = this.calloutResponseTrack.states.toString();
        }
    }

}