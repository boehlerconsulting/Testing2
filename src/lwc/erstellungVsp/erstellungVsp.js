/**
 *@author       Mats Böhler
 *@created      04.01.2022
 *
 *
 *@description  erstellungVsp
 *
 *
 *@changelog    04.01.2022 Mats Böhler - Created
 *
 *
 */

import {LightningElement, api, track, wire} from 'lwc';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import init from '@salesforce/apex/ErstellungVspCtrl.initialize';
import create from '@salesforce/apex/ErstellungVspCtrl.create';
import save from '@salesforce/apex/ErstellungVspCtrl.save';
import validateImageSize from '@salesforce/apex/ErstellungVspCtrl.validateImageSize';
import {reduceErrors} from 'c/errorHandler';
import {CloseActionScreenEvent} from 'lightning/actions';
import pdflib from "@salesforce/resourceUrl/pdflib";
import {loadScript} from "lightning/platformResourceLoader";
import {NavigationMixin} from 'lightning/navigation';
// Import message service features required for publishing and the message channel
import {publish, MessageContext} from 'lightning/messageService';
import refresh from '@salesforce/messageChannel/Refresh__c';
import filePreview from '@salesforce/messageChannel/FilePreview__c';

export default class ErstellungVsp extends NavigationMixin(LightningElement) {

    @api recordId;
    winterdienstValue = false;
    aussenreinigungValue = false;
    winterdienstLPSValue = false;
    vollstaendigValue = false;
    werktagsValue = false;
    feiertagenValue = false;
    sonstigesValue = false;
    vollstaendigSolarValue = false;
    sonstigeBemerkungValue = '';
    lead;
    showSpinner = false;
    isInitialized = false;
    showFiles = false;
    showPageOne = true;
    response;
    selectedFileIds = new Set();
    noneSelected = true;
    uploadedContentDocumentIds = [];
    files = [];
    maximumFilesExceeded = false;
    user;
    csgAddress;
    isPng = false;
    fileId;
    parsedValue;
    imageBites;
    pdfBytes;
    pdfUrl;
    pdfBlob;
    @wire(MessageContext)
    messageContext;

    renderedCallback() {
        if (!this.isInitialized && this.recordId) {
            loadScript(this, pdflib).then(() => {
                this.init();
            });
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

    get activeSections() {
        return ['A', 'B'];
    }

    handleNext() {
        this.showPageOne = false;
        this.showFiles = true;
    }

    handleValueChange(event) {
        this[event.target.name] = event.detail.checked ? event.detail.checked : event.detail.value;
    }

    closeAction() {
        let payload = {contentDocumentId: this.fileId};
        let context = this.messageContext;
        publish(context, filePreview, payload);
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleErstellen() {

        this.showSpinner = true;

        if (this.displayWarning) {
            const evt = new ShowToastEvent({
                title: 'Error!',
                message: 'Die Erstellung der VSP ist erst möglich, wenn Sie ein Bild auswählen.',
                variant: 'error',
                mode: 'sticky'
            });
            this.dispatchEvent(evt);
            this.showSpinner = false;
        } else {
            create({
                selectedContentDocumentId: Array.from(this.selectedFileIds).join(','),
                leadString: JSON.stringify(this.lead)
            })
                .then(result => {
                    let instance = JSON.parse(result);
                    this.lead = instance.lead;
                    this.parsedValue = instance.encodedPdf;
                    this.pdfBytes = instance.encodedPdf;
                    this.imageBites = instance.encodedImage;
                    this.isPng = instance.isPng;
                    this.mergeNewPdf();
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
        this.user = this.response.currentUser;
        this.csgAddress = this.response.csgAddress;
        this.winterdienstLPSValue = this.lead.Stromanschluss__c === 'Solar';
        this.vollstaendigSolarValue = this.winterdienstLPSValue;
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
            return 'Es ist kein Bild vorhanden. Bitte laden Sie eine entsprechende Datei hoch.'
        } else if (this.maximumFilesExceeded) {
            return 'Es darf maximal ein Bild ausgewählt werden.'
        } else {
            return 'Es ist kein Bild ausgewählt. Die Erstellung der VSP ist erst möglich, wenn Sie ein Bild auswählen.'
        }
    }

    handleOnChange(event) {
        if (event.target.checked === true) {
            this.selectedFileIds.add(this.files[event.target.dataset.item].ContentDocumentId);
        }
        if (event.target.checked === false) {
            this.selectedFileIds.delete(this.files[event.target.dataset.item].ContentDocumentId);
        }
        this.maximumFilesExceeded = this.selectedFileIds.size > 1;
        this.noneSelected = this.selectedFileIds.size === 0;
    }

    handleFileUploadFinished(event) {
        this.showSpinner = true;
        let uploadedFiles = event.detail.files;
        validateImageSize({
            contentDocumentId: uploadedFiles[0].documentId
        })
            .then(result => {
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
                this.maximumFilesExceeded = this.selectedFileIds.size > 1;
                this.files = JSON.parse(JSON.stringify(this.files));
                this.noneSelected = this.selectedFileIds.size === 0;
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

    get erstellenDisabled() {
        return this.displayWarning;
    }

    get isUploadDisabled() {
        return this.uploadedContentDocumentIds.length > 1;
    }

    saveByteArray() {
        this.pdfBlob = new Blob([this.pdfBytes], {type: "application/pdf"});
        this.pdfUrl = URL.createObjectURL(this.pdfBlob);
    }

    async mergeNewPdf() {
        await this.setFields();
        await this.convert();
    }

    setCheckbox(form, fieldName, value) {
        if (value === true) {
            form.getCheckBox(fieldName).check();
        } else {
            form.getCheckBox(fieldName).uncheck();
        }
        form.getCheckBox(fieldName).enableReadOnly();
    }

    setTextField(form, fieldName, value) {
        form.getTextField(fieldName).setText(value);
        if (fieldName === 'RVU'){
            form.getTextField(fieldName).setAlignment(PDFLib.TextAlignment.Center);
        }
        form.getTextField(fieldName).enableReadOnly();
    }

    async setFields() {
        const formPdfBytes = this.parsedValue;
        const pdfDoc = await PDFLib.PDFDocument.load(formPdfBytes);
        const form = pdfDoc.getForm();
        this.setTextField(form, 'PODID', this.lead.PODID_Lookup__r.Wert__c);
        this.setTextField(form, 'SID', this.lead.PODID_Lookup__r.Short_ID__c);
        this.setTextField(form, 'POSTALCODE', this.lead.PostalCode);
        this.setTextField(form, 'CITY', this.lead.City);
        this.setTextField(form, 'STREET', this.lead.Street);
        this.setTextField(form, 'NAME', this.lead.Name);
        this.setTextField(form, 'PHONE', this.lead.Phone);
        this.setTextField(form, 'MOBILE', this.lead.MobilePhone);
        this.setTextField(form, 'FAX', this.lead.Fax);
        this.setTextField(form, 'EMAIL', this.lead.Email);
        this.setTextField(form, 'ADRESS', this.lead.Street + '\n' + this.lead.PostalCode + ' ' + this.lead.City);
        this.setTextField(form, 'CSG_Street', this.csgAddress.Strasse__c);
        this.setTextField(form, 'CSG_POSTALCODE_CITY', this.csgAddress.Postleitzahl__c + ' ' + this.csgAddress.Ort__c);
        this.setCheckbox(form, 'Winterdienst', this.winterdienstValue);
        this.setCheckbox(form, 'Aussenreinigung', this.aussenreinigungValue);
        this.setCheckbox(form, 'vollstaendig', this.vollstaendigValue);
        this.setCheckbox(form, 'werktags_ausserhalb_OEZ', this.werktagsValue);
        this.setCheckbox(form, 'Sonn_und_Feiertagen', this.feiertagenValue);
        this.setCheckbox(form, 'zu_sonstigen_Zeiten', this.sonstigesValue);
        this.setCheckbox(form, 'vollstaendig_LPS', this.vollstaendigSolarValue);
        this.setCheckbox(form, 'Winterdienst_LPS', this.winterdienstLPSValue);
        this.setTextField(form, 'DESCRIPTION', this.sonstigeBemerkungValue);
        this.setTextField(form, 'CITY_DATE_NAME', this.user.City + ', ' + this.getToday() + ', ' + this.user.Name);
        if (this.lead.Akquisemodus__c && this.lead.Akquisemodus__c.includes('rVU')){
            this.setTextField(form, 'RVU', 'rVU ' + this.lead.VL__r.GL__r.RVU_Team__r.Name);
        }
        else{
            this.setTextField(form, 'RVU', 'VL ' + this.lead.VL__r.Name);
        }


        let image;
        if (this.isPng) {
            image = await pdfDoc.embedPng(this.imageBites);
        } else {
            image = await pdfDoc.embedJpg(this.imageBites);
        }
        const page = pdfDoc.getPage(1);
        const scaled = image.scaleToFit(475, 600);

        page.drawImage(image, {
            x: 50,
            y: page.getHeight() - 150 - scaled.height,
            width: scaled.width,
            height: scaled.height,
        });
        this.pdfBytes = await pdfDoc.save();
        this.saveByteArray();
    }

    getToday() {
        let today = new Date();
        let dd = today.getDate();
        let mm = today.getMonth() + 1;
        const yyyy = today.getFullYear();
        if (dd < 10) {
            dd = `0${dd}`;
        }
        if (mm < 10) {
            mm = `0${mm}`;
        }
        return `${dd}.${mm}.${yyyy}`;
    }

    async convert() {
        const convertBlobToBase64 = async (blob) => { // blob data
            return await blobToBase64(blob);
        }

        const blobToBase64 = blob => new Promise((resolve, reject) => {
            const reader = new FileReader();
            reader.readAsDataURL(blob);
            reader.onload = () => resolve(reader.result);
            reader.onerror = error => reject(error);
        });
        let encodedString = await convertBlobToBase64(this.pdfBlob);
        save({
            data: encodedString.replace('data:application/pdf;base64,', ''),
            leadString: JSON.stringify(this.lead)
        })
            .then(result => {
                this.fileId = result;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Erfolg',
                        message: 'VSP wurde erfolgreich erstellt.',
                        variant: 'success',
                    }));
                this.showSpinner = false;
                publish(this.messageContext, refresh, {});
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
}