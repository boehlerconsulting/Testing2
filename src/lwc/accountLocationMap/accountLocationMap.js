/**
 *@author       Mats Böhler
 *@created      21.06.2021
 *
 *
 *@description  accountLocationMap
 *
 *
 *@changelog    21.06.2021 Mats Böhler - Created
 *
 *
 */

import {LightningElement, api, wire, track} from 'lwc';
import {getRecord} from 'lightning/uiRecordApi';

export default class AccountLocationMap extends LightningElement {

    @api recordId;
    @api street;
    @api postalCode;
    @api city;
    @api country;
    @api state;
    @api name;
    @api iconName;
    @api zoomLevel = 15;
    @track record;
    @track error;

    @wire(getRecord, {recordId: '$recordId', fields: '$fields'})
    wiredAccount({error, data}) {
        if (data) {
            this.record = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.record = undefined;
        }
    }

    get fields() {
        return [
            this.street,
            this.postalCode,
            this.city,
            this.country,
            this.state,
            this.name
        ];
    }

    get isLoaded() {
        return this.record;
    }

    get mapMarkers() {
        return [{
            location: {
                City: this.record.fields[this.city.split('.')[1]].value,
                Country: this.record.fields[this.country.split('.')[1]].value,
                PostalCode: this.record.fields[this.postalCode.split('.')[1]].value,
                State: this.record.fields[this.state.split('.')[1]].value,
                Street: this.record.fields[this.street.split('.')[1]].value
            },
            title: this.record.fields[this.name.split('.')[1]].value,
            icon: this.iconName
        }];
    }
}