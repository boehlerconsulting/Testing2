/**
 *@author       Mats Böhler
 *@created      21.07.2021
 *
 *
 *@description  stornierungVorDispo
 *
 *
 *@changelog    21.07.2021 Mats Böhler - Created
 *
 *
 */

import {LightningElement, api, track} from 'lwc';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import sendEmail from '@salesforce/apex/StornierungVorDispoCtrl.sendEmail';
import {reduceErrors} from 'c/errorHandler';
import {getRecordNotifyChange} from 'lightning/uiRecordApi';

export default class StornierungVorDispo extends LightningElement {

    @api recordId;
    @track showSpinner = true;
    @track isExecuting = false;

    @api invoke() {

        if (!this.isExecuting) {
            this.sendEmail();
        }
    }

    sendEmail() {
        this.isExecuting = true;
        sendEmail({
            leadId: this.recordId
        })

            .then(result => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Erfolg',
                        message: 'Das Baumanagement Packstation wird über die Stornierung informiert.',
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