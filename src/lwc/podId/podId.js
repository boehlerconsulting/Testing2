/**
 *@author       Mats Böhler
 *@created      04.08.2021
 *
 *
 *@description  podId
 *
 *
 *@changelog    04.08.2021 Mats Böhler - Created
 *
 *
 */

import {LightningElement, api, track} from 'lwc';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import init from '@salesforce/apex/PodIdCtrl.init';
import {reduceErrors} from 'c/errorHandler';
import {getRecordNotifyChange} from 'lightning/uiRecordApi';

export default class PodId extends LightningElement {

    @api recordId;
    @track showSpinner = true;
    @track isExecuting = false;

    @api invoke() {

        if (!this.isExecuting) {
            this.init();
        }
    }

    init() {
        this.isExecuting = true;
        init({
            leadId: this.recordId
        })
            .then(result => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Erfolg',
                        message: 'Die PODID wurde erfolgreich generiert.',
                        variant: 'success',
                    }));
                getRecordNotifyChange([{recordId: this.recordId}]);
                this.showSpinner = false;
            })
            .catch(error => {
                this.error = error;

                const evt = new ShowToastEvent({
                    title: 'Error',
                    message: reduceErrors(error)[0],
                    variant: 'error',
                    mode: 'sticky'
                });
                this.dispatchEvent(evt);
                this.showSpinner = false;
            });
    }
}