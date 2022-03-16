/**
 *@author       Mats Böhler
 *@created      18.08.2020
 *
 *
 *@description  wartezeitrisiko
 *
 *
 *@changelog    18.08.2020 Mats Böhler - Created
 *
 *
 */

import {LightningElement, wire, track, api} from 'lwc';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import {CurrentPageReference} from 'lightning/navigation';

// importing apex class methods
import loadData from '@salesforce/apex/WartezeitrisikoDataCtrl.loadData';

export default class Wartezeitrisiko extends LightningElement {

    @api recordId;
    @track showSpinner = true;
    @track initialized = false;
    @track dataset;
    @track calendarWeeks = [];
    kwVon = 1;
    kwBis = 53;
    startingYear = new Date().getFullYear() - 1;

    connectedCallback() {

        this.loadData();

    }

    loadData() {
        loadData({
            recordId: this.recordId,
            kwVon: this.kwVon,
            kwBis: this.kwBis,
            startingYear: this.startingYear,
        })

            .then(result => {

                this.dataset = JSON.parse(result);

                if (!this.initialized){
                    for (let i = 1; i < 54; i++) {
                        this.calendarWeeks.push({label: i.toString(), value: i})
                    }
                }

                this.showSpinner = false;
                this.initialized = true;

            })
            .catch(error => {
                this.error = error;
                const evt = new ShowToastEvent({
                    title: this.error.statusText,
                    message: this.error.body ? this.error.body.message : '',
                    variant: 'error',
                    mode: 'sticky'
                });
                this.dispatchEvent(evt);
                this.showSpinner = false;
            });
    }

    handleChangeKwVon(event) {
        this.kwVon = parseInt(event.detail.value);
        if (this.kwVon > this.kwBis){
            this.kwBis = this.kwVon;
        }
        this.loadData();
    }

    handleChangeKwBis(event) {
        this.kwBis = parseInt(event.detail.value);
        if (this.kwBis < this.kwVon){
            this.kwVon = this.kwBis;
        }
        this.loadData();
    }

    get yearOptions() {
        return [
            {label: 'diesem Jahr', value: new Date().getFullYear()},
            {label: 'letzten 2 Jahren', value: new Date().getFullYear() - 1},
            {label: 'letzten 3 Jahren', value: new Date().getFullYear() - 2},
        ];
    }

    handleChangeSelectedYearOption(event) {
        this.startingYear = parseInt(event.detail.value);
        this.loadData();
    }
}