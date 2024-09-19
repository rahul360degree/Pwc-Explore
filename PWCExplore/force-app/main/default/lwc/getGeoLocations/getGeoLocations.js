import { LightningElement, api, track } from 'lwc';
import { FlowAttributeChangeEvent, FlowNavigationNextEvent } from 'lightning/flowSupport';
import componentTitle from '@salesforce/label/c.Map_Component_Title';
import holdTillLocationIsCaptured from '@salesforce/label/c.Hold_till_location_is_captured';

export default class GetGeoLocations extends LightningElement {
    @api latitude;
    @api longitude;
    @track wasLocationCaptured = false; 
    mapMarkers = [{
        location: {
            Latitude: '20.5937',
            Longitude: '-122.3968'
        }
    }];

    zoomLevel = 15;
    @track selectedMarkerValue;
    hasRendered = false;
   
    renderedCallback() {
        if (!this.hasRendered) {
            if (navigator.geolocation && !this.showAddressOnly) {
                navigator.geolocation.getCurrentPosition(position => {
                    this.latitude = position.coords.latitude;
                    this.longitude = position.coords.longitude;
                    this.mapMarkers = [{
                        location: {
                            Latitude: this.latitude,
                            Longitude: this.longitude
                        },
                        title: componentTitle
                    }];
                    this.wasLocationCaptured = true;
                });
            }
            this.hasRendered = true;
        }
    }

    @api
    validate() {
        if(!this.wasLocationCaptured) {
            return { 
                isValid: false, 
                errorMessage: holdTillLocationIsCaptured
            }; 
        }
        return { isValid: true };
    }
}