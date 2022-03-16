/**
 *@author       Mats Böhler
 *@created      21.07.2021
 *
 *
 *@description  stornierungNachDispo
 *
 *
 *@changelog    21.07.2021 Mats Böhler - Created
 *
 *
 */

import {LightningElement,api} from 'lwc';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import sendEmail from '@salesforce/apex/StornierungNachDispoCtrl.sendEmail';
import {reduceErrors} from 'c/errorHandler';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class StornierungNachDispo extends LightningElement {

    @api recordId;
    stornierungsgrund;
    showSpinner = false;

    sendEmail() {
        this.showSpinner = true;
        sendEmail({
            leadId: this.recordId,
            stornogrund: this.stornierungsgrund
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
                this.closeAction();
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
                this.closeAction();
            });
    }

    handleStorierungsgrundChange(event){
        this.stornierungsgrund = event.target.value;
    }

    get stornoDisabled(){
        return !this.stornierungsgrund;
    }

    closeAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}