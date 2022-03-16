/**
 *@author       Mats Böhler
 *@created      01.07.2021
 *
 *
 *@description  aktivitaetsDetail
 *
 *
 *@changelog    01.07.2021 Mats Böhler - Created
 *
 *
 */

import {LightningElement, wire, track, api} from 'lwc';
import init from '@salesforce/apex/AktivitaetsDetailCtrl.init';
import {ShowToastEvent} from "lightning/platformShowToastEvent";

export default class AktivitaetsDetail extends LightningElement {

    @api recordId;
    @track showSpinner = true;
    @track isInitialized = false;
    @track details = [];

    connectedCallback() {

        this.init();
    }

    init() {
        init({
            taskId: this.recordId
        })
            .then(result => {

                this.details = JSON.parse(result);
                this.showSpinner = false;
                this.isInitialized = true;
            })
            .catch(error => {
                this.error = error;
                const evt = new ShowToastEvent({
                    title: this.error.statusText,
                    message: this.error.body.message,
                    variant: 'error',
                    mode: 'sticky'
                });
                this.dispatchEvent(evt);
                this.showSpinner = false;
            });
    }

}