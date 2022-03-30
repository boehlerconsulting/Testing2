/**
 *@author       Mats Böhler
 *@created      22.03.2022
 *
 *
 *@description  postgesetzPdfLib
 *
 *
 *@changelog    22.03.2022 Mats Böhler - Created
 *
 *
 */

import {api, LightningElement, track} from 'lwc';
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import init from '@salesforce/apex/PostgesetzPdfLibCtrl.initialize';
import {reduceErrors} from 'c/errorHandler';

export default class PostgesetzPdfLib extends LightningElement {

    @api recordId;
    @track isInitialized = false;
    @track isExecuting = false;
    pdfLibRecordId;
    relateToRecordFieldName;

    @api invoke() {

        if (!this.isExecuting) {
            this.isExecuting = true;
            this.init();
        }
    }

    init() {
        init({
            accountId: this.recordId
        })
            .then(result => {
                let instance = JSON.parse(result);
                this.pdfLibRecordId = instance.recordId;
                this.relateToRecordFieldName = instance.relateToRecordFieldName;
                this.isInitialized = true;
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