/**
 *@author       Mats Böhler
 *@created      22.07.2021
 *
 *
 *@description  packstationDatenaenderung
 *
 *
 *@changelog    22.07.2021 Mats Böhler - Created
 *
 *
 */

import {LightningElement, api, wire} from 'lwc';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import sendEmail from '@salesforce/apex/PackstationDatenaenderungCtrl.sendEmail';
import {reduceErrors} from 'c/errorHandler';
import {getRecordNotifyChange} from 'lightning/uiRecordApi';
import {CloseActionScreenEvent} from 'lightning/actions';
import modal from '@salesforce/resourceUrl/modalMedium';
import {loadStyle} from 'lightning/platformResourceLoader';
import {getObjectInfo} from 'lightning/uiObjectInfoApi';
import LEAD_OBJECT from '@salesforce/schema/Lead';

export default class PackstationDatenaenderung extends LightningElement {

    @api recordId;
    @api objectApiName = 'Lead';
    @wire(getObjectInfo, {objectApiName: LEAD_OBJECT})
    objectInfo;
    showSpinner = false;
    oldLeadInfo;
    isLoaded = false;

    connectedCallback() {

        Promise.all([
            loadStyle(this, modal)
        ])
    }

    sendEmail(fields) {
        this.showSpinner = true;
        sendEmail({
            leadId: this.recordId,
            oldLeadState: JSON.stringify(this.oldLead),
            newLeadState: JSON.stringify(fields)
        })
            .then(result => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Erfolg',
                        message: 'Das Baumanagement Packstation wird über die Datenänderung informiert.',
                        variant: 'success',
                    }));
                getRecordNotifyChange([{recordId: this.recordId}]);
                this.showSpinner = false;
                this.isLoaded = false;
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

    closeAction() {
        this.isLoaded = false;
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    get recordTypeId() {
        // Returns a map of record type Ids
        const rtis = this.objectInfo.data.recordTypeInfos;
        return Object.keys(rtis).find(rti => rtis[rti].name === 'Packstation');
    }

    handleOnLoad(event) {
        if (!this.isLoaded){
            this.oldLeadInfo = event.detail.records[this.recordId].fields;
            this.isLoaded = true;
        }
    }

    handleOnSubmit(event) {
        this.showSpinner = true;
        event.preventDefault();
        const fields = event.detail.fields;
        this.sendEmail(fields);
    }

    get oldLead(){
        return {
            Id : this.recordId,
            Download_LTE_Messung_MBit__c: this.oldLeadInfo.Download_LTE_Messung_MBit__c.value,
            Upload_LTE_Messung_MBit__c: this.oldLeadInfo.Upload_LTE_Messung_MBit__c.value,
            ADM_Typ__c: this.oldLeadInfo.ADM_Typ__c.value,
            ADM_Hersteller__c: this.oldLeadInfo.ADM_Hersteller__c.value,
            Fundament__c: this.oldLeadInfo.Fundament__c.value,
            Aufbauform__c: this.oldLeadInfo.Aufbauform__c.value,
            Fachmodule__c: this.oldLeadInfo.Fachmodule__c.value,
            Unterbrechung__c: this.oldLeadInfo.Unterbrechung__c.value,
            Steuermodule__c: this.oldLeadInfo.Steuermodule__c.value,
            Eckmodule__c: this.oldLeadInfo.Eckmodule__c.value,
            Anmerkungen_zum_Bau__c: this.oldLeadInfo.Anmerkungen_zum_Bau__c.value,
            Bemerkungen_zur_Dispo__c: this.oldLeadInfo.Bemerkungen_zur_Dispo__c.value,
            Summe_aller_Module__c: this.oldLeadInfo.Summe_aller_Module__c.value,
            Kostenstelle__c: this.oldLeadInfo.Kostenstelle__c.value
        };
    }
}