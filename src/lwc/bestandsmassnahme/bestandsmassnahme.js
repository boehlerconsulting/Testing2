/**
 *@author       Mats Böhler
 *@created      30.08.2021
 *
 *
 *@description  bestandsmassnahme
 *
 *
 *@changelog    30.08.2021 Mats Böhler - Created
 *
 *
 */

import {LightningElement, api} from 'lwc';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import createLead from '@salesforce/apex/BestandsmassnahmeCtrl.createLead';
import saveAccount from '@salesforce/apex/BestandsmassnahmeCtrl.saveAccount';
import {reduceErrors} from 'c/errorHandler';
import {getRecordNotifyChange} from 'lightning/uiRecordApi';
import {CloseActionScreenEvent} from 'lightning/actions';
import modal from '@salesforce/resourceUrl/modalMedium';
import {loadStyle} from 'lightning/platformResourceLoader';
import {NavigationMixin} from "lightning/navigation";

export default class Bestandsmassnahme extends NavigationMixin(LightningElement) {

    @api recordId;
    @api objectApiName = 'Account';
    showSpinner = false;
    bestandsmassnahmeValue;
    bestandsmassnahmeDatumValue;
    kuendigungDurchValue;
    oldLeadInfo;
    isLoaded = false;
    isSaveDisabled = true;
    @api showKuendigung = false;
    @api isAbbau = false;

    connectedCallback() {

        Promise.all([
            loadStyle(this, modal)
        ])
    }

    handleChangeBestandsmassnahme(event) {
        this.bestandsmassnahmeValue = event.detail.value;
        this.showKuendigung = this.bestandsmassnahmeValue === 'Kündigung';
        this.isAbbau = this.bestandsmassnahmeValue === 'Abbau';
        this.setIsSaveDisabled();
    }

    handleChangeBestandsmassnahmeDatum(event) {
        this.bestandsmassnahmeDatumValue = event.detail.value;
        this.setIsSaveDisabled();
    }

    handleChangeKuendigungDurch(event) {
        this.kuendigungDurchValue = event.detail.value;
        this.setIsSaveDisabled();
    }

    handleOnLoad(event) {
        if (!this.isLoaded) {
            this.oldLeadInfo = event.detail.records[this.recordId].fields;
            if (this.oldLeadInfo.Bestandsmassnahme__c) {
                this.isLoaded = true;
                this.bestandsmassnahmeValue = this.oldLead.Bestandsmassnahme__c;
                this.bestandsmassnahmeDatumValue = this.oldLead.Bestandsmassnahme_Datum__c;
                this.showKuendigung = this.bestandsmassnahmeValue === 'Kündigung';
                this.isAbbau = this.bestandsmassnahmeValue === 'Abbau';
            }
        }
    }

    get oldLead() {
        if (this.isLoaded) {
            return {
                Id: this.recordId,
                Bestandsmassnahme__c: this.oldLeadInfo.Bestandsmassnahme__c.value,
                Bestandsmassnahme_Datum__c: this.oldLeadInfo.Bestandsmassnahme_Datum__c.value
            };
        }
    }

    setIsSaveDisabled() {
        if (this.bestandsmassnahmeValue === 'Kündigung' && this.kuendigungDurchValue === 'Kündigung zurückgezogen') {
            this.isSaveDisabled = false;
        } else {
            this.isSaveDisabled = this.oldLead.Bestandsmassnahme__c === this.bestandsmassnahmeValue
                || this.oldLead.Bestandsmassnahme_Datum__c === this.bestandsmassnahmeDatumValue;
        }
    }

    createLead(fields) {
        createLead({
            accountId: this.recordId,
            accountString: JSON.stringify(fields)
        })
            .then(result => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Erfolg',
                        message: 'Die Bestandsmaßnahme wurde erfasst.',
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
            });
    }

    saveAccount(fields) {
        saveAccount({
            accountId: this.recordId,
            accountString: JSON.stringify(fields)
        })
            .then(result => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Erfolg',
                        message: 'Die Bestandsmaßnahme wurde erfasst.',
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
            });
    }

    handleSubmit(event) {
        this.showSpinner = true;
        event.preventDefault();
        const fields = event.detail.fields;
        if (fields.Kuendigung_durch__c === 'Kündigung zurückgezogen') {
            this.saveAccount(fields);
        } else {
            this.createLead(fields);
        }
    }

    closeAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    get isNoKuendigung(){
        return !this.showKuendigung && !this.isAbbau;
    }
}