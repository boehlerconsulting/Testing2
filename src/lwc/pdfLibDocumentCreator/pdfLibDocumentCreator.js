/**
 *@author       Mats Böhler
 *@created      22.03.2022
 *
 *
 *@description  pdfLibDocumentCreator
 *
 *
 *@changelog    22.03.2022 Mats Böhler - Created
 *
 *
 */

import {LightningElement, api, track, wire} from 'lwc';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import init from '@salesforce/apex/DocumentCreatorCtrl.initialize';
import save from '@salesforce/apex/DocumentCreatorCtrl.save';
import {reduceErrors} from 'c/errorHandler';
import pdflib from "@salesforce/resourceUrl/pdflib";
import {loadScript} from "lightning/platformResourceLoader";
import {publish, MessageContext} from 'lightning/messageService';
import refresh from '@salesforce/messageChannel/Refresh__c';
import filePreview from '@salesforce/messageChannel/FilePreview__c';

export default class PdfLibDocumentCreator extends LightningElement {

    @api recordId;
    @api relateToRecordFieldName;
    @api emailSettingDeveloperName;
    @api sourceDocumentIndexName;
    @api successMessage;
    @api fileName = 'Undefined';

    @track showSpinner = true;
    isInitialized = false;
    @wire(MessageContext)
    messageContext;
    pdfBytes;
    mappings;
    pdfBlob;
    fileId;

    renderedCallback() {
        if (!this.isInitialized && this.recordId) {
            this.isInitialized = true;
            loadScript(this, pdflib).then(() => {
                this.init();
            });
        }
    }

    init() {
        init({
            recordId: this.recordId,
            relateToRecordFieldName: this.relateToRecordFieldName,
            sourceDocumentIndexName: this.sourceDocumentIndexName
        })
            .then(result => {
                let instance = JSON.parse(result);
                this.pdfBytes = instance.encodedPdf;
                this.mappings = instance.mappings;
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
            });
    }

    saveByteArray() {
        this.pdfBlob = new Blob([this.pdfBytes], {type: "application/pdf"});
    }

    async mergeNewPdf() {
        await this.setFields();
        await this.convert();
    }

    setCheckbox(form, mapping) {
        let field = form.getCheckBox(mapping.name);
        if (mapping.value === 'true') {
            field.check();
        } else {
            field.uncheck();
        }
        if (mapping.isReadOnly){
            field.enableReadOnly();
        }
    }

    setTextField(form,mapping) {
        let field = form.getTextField(mapping.name);
        field.setText(mapping.value);
        if (mapping.isReadOnly){
            field.enableReadOnly();
        }
    }

    setRadioGroup(form,mapping) {
        let field = form.getRadioGroup(mapping.name);
        field.select(mapping.value);
        if (mapping.isReadOnly){
            field.enableReadOnly();
        }
    }

    async setFields() {
        const formPdfBytes = this.pdfBytes;
        const pdfDoc = await PDFLib.PDFDocument.load(formPdfBytes);
        const form = pdfDoc.getForm();

        for (const mapping of this.mappings) {
            if (mapping.type === 'CheckBox'){
                this.setCheckbox(form, mapping);
            }
            if (mapping.type === 'RadioGroup'){
                this.setRadioGroup(form, mapping);
            }
            if (mapping.type === 'TextField' || mapping.type === 'TextFieldDate'){
                this.setTextField(form, mapping);
            }
        }
        this.pdfBytes = await pdfDoc.save();
        this.saveByteArray();
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
            recordId: this.recordId,
            relateToRecordFieldName: this.relateToRecordFieldName,
            sourceDocumentIndexName: this.sourceDocumentIndexName,
            emailSettingDeveloperName: this.emailSettingDeveloperName,
            fileName: this.fileName
        })
            .then(result => {
                this.fileId = result;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Erfolg',
                        message: this.successMessage,
                        variant: 'success',
                    }));
                this.showSpinner = false;
                let payload = {contentDocumentId: this.fileId};
                let context = this.messageContext;
                publish(context, filePreview, payload);
                publish(this.messageContext, refresh, {});
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