/**
 *@author       Mats Böhler
 *@created      16.08.2021
 *
 *
 *@description  produktoptionDelete
 *
 *
 *@changelog    16.08.2021 Mats Böhler - Created
 *
 *
 */

import {LightningElement, api, track} from 'lwc';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import {reduceErrors} from 'c/errorHandler';
import {getRecordNotifyChange} from 'lightning/uiRecordApi';
import {updateRecord} from 'lightning/uiRecordApi';
import IST_ZUSATZ_FIELD from '@salesforce/schema/Produktoption__c.istZusatz__c';
import IST_ERSATZ_FIELD from '@salesforce/schema/Produktoption__c.istErsatz__c';
import IST_UNSICHTBAR_NEUBESTELLUNG_FIELD from '@salesforce/schema/Produktoption__c.IstUnsichtbarNeubestellung__c';
import GELOESCHT_FIELD from '@salesforce/schema/Produktoption__c.Geloescht__c';

export default class ProduktoptionDelete extends LightningElement {

    @api recordId;
    @track showSpinner = true;
    @track isExecuting = false;
    @track error;

    @api invoke() {

        if (!this.isExecuting) {
            this.updateRecord();
        }
    }

    updateRecord() {
        this.isExecuting = true;
        this.showSpinner = true;

        const fields = {};
        fields.Id = this.recordId;
        fields[IST_ZUSATZ_FIELD.fieldApiName] = false;
        fields[IST_ERSATZ_FIELD.fieldApiName] = false;
        fields[IST_UNSICHTBAR_NEUBESTELLUNG_FIELD.fieldApiName] = true;
        fields[GELOESCHT_FIELD.fieldApiName] = true;

        const recordInput = {fields};

        updateRecord(recordInput)
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Erfolg',
                        message: 'Produktoption wurde gelöscht (Flags wurden gesetzt).',
                        variant: 'success'
                    })
                );
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