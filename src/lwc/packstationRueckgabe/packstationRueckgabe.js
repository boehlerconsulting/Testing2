/**
 *@author       Mats Böhler
 *@created      26.07.2021
 *
 *
 *@description  packstationRueckgabe
 *
 *
 *@changelog    26.07.2021 Mats Böhler - Created
 *
 *
 */

import {LightningElement,api} from 'lwc';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import sendEmail from '@salesforce/apex/PackstationRueckgabeCtrl.sendEmail';
import {reduceErrors} from 'c/errorHandler';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class PackstationRueckgabe extends LightningElement {

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
                        message: 'Das zuständige rVU Team wird über die Rückgabe informiert.',
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