/**
 *@author       Mats Böhler
 *@created      13.06.2020
 *
 *
 *@description  anlagennummer
 *
 *
 *@changelog    13.06.2020 Mats Böhler - Created
 *
 *
 */

import {LightningElement, wire, track, api} from 'lwc';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';

// importing apex class methods
import generate from '@salesforce/apex/AnlagennummerCtrl.generate';

export default class Anlagennummer extends LightningElement {

    @api iconName;
    @api title;
    @track startNumber = '00000000';
    @track endNumber = '00000000';
    @track showSpinner;

    generate() {
        this.showSpinner = true;
        generate({
            startNumber: this.startNumber,
            endNumber: this.endNumber
        })
            .then(result => {

                if (result === this.startNumber) {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Erfolg',
                            message: 'Die Anlagennummern wurden erfolgreich generiert.',
                            variant: 'success',
                        }));
                    this.startNumber = '';
                    this.endNumber = '';
                    this.showSpinner = false;
                } else {
                    this.startNumber = result;
                    this.generate();
                }
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

    handleOnChangeStartnummer(event) {
        this.startNumber = event.detail.value;
    }

    handleOnChangeEndnummer(event) {
        this.endNumber = event.detail.value;
    }

    handleOnGenerate() {
        this.generate();
    }
}