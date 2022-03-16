/**
 *@author       Mats Böhler
 *@created      15.05.2020
 *
 *
 *@description  emailDispatcher
 *
 *
 *@changelog    15.05.2020 Mats Böhler - Created
 *
 *
 */

import {LightningElement, wire, track, api} from 'lwc';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import {CurrentPageReference} from 'lightning/navigation';

// importing apex class methods
import loadData from '@salesforce/apex/EmailDispatcherCtrl.init';
import sendEmail from '@salesforce/apex/EmailDispatcherCtrl.sendEmail';

export default class EmailDispatcher extends LightningElement {

    @api recordId;
    @api fromAddress;
    @api toAddress;
    @api ccAddress;
    @api emailTemplate;
    @api document;
    @api relationFieldName;
    @track showSpinner = true;
    @track initialized = false;
    @track response;
    @track selectedFileIds = new Set();
    @track noneSelected = false;

    connectedCallback() {

        this.loadData();
    }

    loadData() {
        loadData({
            recordId: this.recordId
        })

            .then(result => {

                this.initializeData(result);

            })
            .catch(error => {
                this.error = error;
                const evt = new ShowToastEvent({
                    title: this.error.statusText,
                    message: this.error.body ? this.error.body.message : 'Something went wrong.',
                    variant: 'error',
                    mode: 'sticky'
                });
                this.dispatchEvent(evt);
                this.showSpinner = false;
            });
    }

    handleSendEmail() {
        this.sendEmail();
    }

    @api
    sendEmail() {

        this.showSpinner = true;

        if (this.displayWarning) {
            const evt = new ShowToastEvent({
                title: 'Error!',
                message: 'Der Emailversand ist nur mit mindestens einem Anhang möglich.',
                variant: 'error',
                mode: 'sticky'
            });
            this.dispatchEvent(evt);
            this.showSpinner = false;
        } else {
            sendEmail({
                message: JSON.stringify({
                    relatedRecord: this.recordId,
                    selectedFileIds: Array.from(this.selectedFileIds).join(','),
                    fromAddress: this.fromAddress,
                    toAddress: this.toAddress,
                    ccAddress: this.ccAddress,
                    emailTemplate: this.emailTemplate,
                    document: this.document,
                    relationFieldName: this.relationFieldName
                })
            })

                .then(result => {
                    this.dispatchEvent(new CustomEvent('success'));
                })
                .catch(error => {
                    this.error = error;
                    const evt = new ShowToastEvent({
                        title: this.error.statusText,
                        message: this.error.body ? this.error.body.message : 'Something bad happened.',
                        variant: 'error',
                        mode: 'sticky'
                    });
                    this.dispatchEvent(evt);
                });
        }
    }

    initializeData(result) {
        this.response = JSON.parse(result);
        for (let file of this.response.data) {
            file.isSelected = false;
        }
        this.showSpinner = false;
        this.initialized = true;
    }

    get noData() {
        return this.response.data.length === 0;
    }

    get displayWarning() {
        return this.noData || this.noneSelected;
    }

    get displayText() {
        if (this.noData) {
            return 'Es ist keine Datei vorhanden. Der Emailversand ist daher nicht möglich.'
        } else {
            return 'Es ist keine Datei ausgewählt. Der Emailversand ist erst möglich, wenn Sie mindestens einen Anhang auswählen.'
        }
    }

    handleOnChange(event) {
        if (event.target.checked === true) {
            this.selectedFileIds.add(this.response.data[event.target.dataset.item].ContentDocumentId);
        }
        if (event.target.checked === false) {
            this.selectedFileIds.delete(this.response.data[event.target.dataset.item].ContentDocumentId);
        }
        this.noneSelected = this.selectedFileIds.size === 0;
    }
}