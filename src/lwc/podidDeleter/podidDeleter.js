/**
 *@author       Mats Böhler
 *@created      19.10.2021
 *
 *
 *@description  podidDeleter
 *
 *
 *@changelog    19.10.2021 Mats Böhler - Created
 *
 *
 */

import {LightningElement, api, track} from 'lwc';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import deleteId from '@salesforce/apex/PodIdCtrl.deleteId';
import {reduceErrors} from 'c/errorHandler';
import {getRecordNotifyChange} from 'lightning/uiRecordApi';

export default class PodidDeleter extends LightningElement {

    @api recordId;
    @track showSpinner = true;
    @track isExecuting = false;

    @api invoke() {

        if (!this.isExecuting) {
            this.deleteId();
        }
    }

    deleteId() {
        this.isExecuting = true;
        deleteId({
            podId: this.recordId
        })
            .then(result => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Erfolg',
                        message: 'Die PODID wurde erfolgreich aus allen Leads und Accounts entfernt.',
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