/**
 *@author       Mats Böhler
 *@created      07.12.2021
 *
 *
 *@description  beauftragungTvm
 *
 *
 *@changelog    07.12.2021 Mats Böhler - Created
 *
 *
 */

import {LightningElement, api, track} from 'lwc';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import init from '@salesforce/apex/BeauftragungTvMCtrl.initialize';
import sendEmail from '@salesforce/apex/BeauftragungTvMCtrl.sendEmail';
import {reduceErrors} from 'c/errorHandler';
import {getRecordNotifyChange} from 'lightning/uiRecordApi';
import {CloseActionScreenEvent} from 'lightning/actions';

export default class BeauftragungTvm extends LightningElement {

    @api recordId;
    lead;
    sonstiges;
    vertragsanpassungen;
    miete;
    strom;
    showSpinner = false;
    isInitialized = false;
    showFiles = false;
    showBeauftragung = true;
    response;
    selectedFileIds = new Set();
    noneSelected = true;
    uploadedContentDocumentIds = [];
    files = [];
    maximumFilesExceeded = false;

    renderedCallback() {
        if (!this.isInitialized && this.recordId) {
            this.init();
        }
    }

    init() {
        init({
            leadId: this.recordId
        })
            .then(result => {
                this.initializeData(result);
            })
            .catch(error => {
                this.error = error;
                const evt = new ShowToastEvent({
                    title: this.error.statusText,
                    message: reduceErrors(error)[0],
                    variant: 'error',
                    mode: 'sticky'
                });
                this.dispatchEvent(evt);
                this.showSpinner = false;
            });
    }

    get showStromkosten() {
        return this.lead.Stromanschluss__c !== 'Solar';
    }

    beauftragen() {
        this.showBeauftragung = false;
        this.showFiles = true;
    }

    get beauftragenDisabled() {
        return !this.miete || (!this.strom && this.showStromkosten);
    }

    handleValueChange(event) {
        this[event.target.name] = event.detail.value;
    }

    closeAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

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
                leadId: this.recordId,
                miete: this.miete === undefined || this.miete === null ? '' : this.miete.toString(),
                strom: this.strom === undefined || this.strom === null ? '' : this.strom.toString(),
                vertragsanpassungen: this.vertragsanpassungen,
                sonstiges: this.sonstiges,
                fileIds: Array.from(this.selectedFileIds).join(',')
            })
                .then(result => {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Erfolg',
                            message: 'TVM wurde erfolgreich beauftragt.',
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
    }

    initializeData(result) {
        this.response = JSON.parse(result);
        this.lead = this.response.lead;
        for (let file of this.response.data) {
            file.isSelected = false;
            this.files.push(file);
        }
        this.showSpinner = false;
        this.isInitialized = true;
    }

    get noData() {
        return this.files.length === 0;
    }

    get displayWarning() {
        return this.noData || this.noneSelected || this.maximumFilesExceeded;
    }

    get displayText() {
        if (this.noData) {
            return 'Es ist keine Datei vorhanden. Der Emailversand ist daher nicht möglich.'
        } else if (this.maximumFilesExceeded) {
            return 'Es dürfen maximal 2 Dateien ausgewählt werden.'
        } else {
            return 'Es ist keine Datei ausgewählt. Der Emailversand ist erst möglich, wenn Sie mindestens einen Anhang auswählen.'
        }
    }

    handleOnChange(event) {
        if (event.target.checked === true) {
            this.selectedFileIds.add(this.files[event.target.dataset.item].ContentDocumentId);
        }
        if (event.target.checked === false) {
            this.selectedFileIds.delete(this.files[event.target.dataset.item].ContentDocumentId);
        }
        this.maximumFilesExceeded = this.selectedFileIds.size > 2;
        this.noneSelected = this.selectedFileIds.size === 0;
    }

    handleFileUploadFinished(event) {
        let uploadedFiles = event.detail.files;
        uploadedFiles.forEach(file => {
            let fileData = {
                ContentDocumentId: file.documentId,
                ContentDocument: {
                    FileExtension: file.name.substring(file.name.lastIndexOf('.') + 1),
                    Title: file.name
                },
                isSelected: true
            };
            this.files.push(fileData);
            this.uploadedContentDocumentIds.push(file.documentId);
            this.selectedFileIds.add(file.documentId);
        });
        this.maximumFilesExceeded = this.selectedFileIds.size > 2;
        this.files = JSON.parse(JSON.stringify(this.files));
        this.noneSelected = this.selectedFileIds.size === 0;
    }

    get sendEmailDisabled() {
        return this.displayWarning;
    }

    get isUploadDisabled() {
        return this.uploadedContentDocumentIds.length > 1;
    }

    get mieteFieldLevelHelp() {
        return 'Monatliche Vergütung Miete in € je Modul';
    }

    get stromFieldLevelHelp() {
        return 'Monatliche Vergütung Strom in Cent je kWh';
    }

    get showMessageMiete() {
        return this.miete !== undefined && this.miete > this.schwellenwertMiete;
    }

    get schwellenwertMiete() {
        return this.response.schwellenwerteVertragserstellung.MieteInEuro__c;
    }

    get messageMiete() {
        return 'Vergütung Strom über Schwellenwert von ' + this.schwellenwertMiete + ',00 €';
    }

    get showMessageStrom() {
        return this.strom !== undefined && this.strom > this.schwellenwertStrom;
    }

    get schwellenwertStrom() {
        return this.response.schwellenwerteVertragserstellung.StrompreisInCent__c;
    }

    get messageStrom() {
        return 'Vergütung Miete über Schwellenwert von ' + this.schwellenwertStrom + ' ¢';
    }

    get showFreigabeVertriebsleiter() {
        return (this.showMessageMiete || this.showMessageStrom)
            && this.lead.Akquisemodus__c !== 'Standortaufnahme vor Ort; Danach Übergabe an rVU';
    }
}