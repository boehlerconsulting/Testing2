/**
 *@author       Mats Böhler
 *@created      22.03.2021
 *
 *
 *@description  einrichtungsprozessAndienung
 *
 *
 *@changelog    22.03.2021 Mats Böhler - Created
 *
 *
 */

import {LightningElement, api, track, wire} from "lwc";
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import init from '@salesforce/apex/EinrichtungsprozessAndienungCtrl.init';
import saveFieldValue from '@salesforce/apex/EinrichtungsprozessBaseCtrl.saveFieldValue';
import getDocumentUrl from '@salesforce/apex/EinrichtungsprozessAndienungCtrl.getDocumentUrl';
import saveDocument from '@salesforce/apex/EinrichtungsprozessAndienungCtrl.saveDocument';
import saveWochentag from '@salesforce/apex/EinrichtungsprozessAndienungCtrl.saveWochentag';
import HwApexRequest from "c/hwApexRequest";
import hwRequestEvaluator from "c/hwRequestEvaluator";
import {NavigationMixin} from 'lightning/navigation';

export default class EinrichtungsprozessAndienung extends NavigationMixin(LightningElement) {

    @api recordId;
    @track isInitialized = false;
    @track showSpinner = true;
    @track screen = {};
    @track oeffnungszeiten;
    @track einrichtungsprozess;
    @track account;
    fieldByFieldNames = new Map();
    fieldsWithDependantFields = [];
    hasPermission = false;
    @track apexRequests = [];
    @track isSaving = false;

    connectedCallback() {

        this.init();
    }

    init() {
        init({
            recordId: this.recordId
        })
            .then(result => {

                this.initialize(result);
            })
            .catch(error => {
                this.dispatchErrorToast(error);
            });
    }

    initialize(result) {
        let instance = JSON.parse(result);
        this.screen = instance.screens[0];
        this.oeffnungszeiten = instance.filialOeffnungszeiten;
        this.einrichtungsprozess = instance.process;
        this.account = instance.account;
        this.hasPermission = instance.hasPermission;

        this.initializeScreen();

        this.fieldsWithDependantFields.forEach(field => {
            this.setDepandantFields(field, field.value);
        });

        this.isInitialized = true;
        this.showSpinner = false;
    }

    initializeScreen() {
        this.screen.activeSections = [];
        this.screen.hasSections = this.screen.sections.length > 0;
        this.initializeSections();
    }

    initializeSections() {
        for (let j = 0; j < this.screen.sections.length; j++) {
            let section = this.screen.sections[j];
            section.index = j;
            if (j > 0) {
                this.screen.activeSections.push(section.title);
            }
            section.isFirstSectionOfFirstScreen = j === 0;
            this.initializeFields(section);
        }
    }

    initializeFields(section) {
        for (let k = 0; k < section.fields.length; k++) {
            let field = section.fields[k];
            this.fieldByFieldNames.set(field.fieldName, field);
            field.isHidden = false;
            field.value = field.objectName === 'Account'
                ? this.account[field.fieldName]
                : this.einrichtungsprozess[field.fieldName];
            field.hasPicture = field.pictureId;
            field.layoutItemSize = field.hasPicture ? '11' : '12';
            field.isText = field.fieldType === 'text';
            field.isCheckbox = field.fieldType === 'checkbox';
            field.isNumber = field.fieldType === 'number';
            field.isPercent = field.fieldType === 'percent';
            field.isCurrency = field.fieldType === 'currency';
            field.isPhone = field.fieldType === 'tel';
            field.isDate = field.fieldType === 'date';
            field.isDateTime = field.fieldType === 'datetime';
            field.isTime = field.fieldType === 'time';
            field.isEmail = field.fieldType === 'email';
            field.isPicklist = field.fieldType === 'picklist';
            field.isTextarea = field.fieldType === 'textarea';
            field.isFilialoeffnungszeiten = field.fieldName === 'EP_Filialoeffnungszeiten';
            field.hasPermission = this.hasPermission;
            field.isDisabled = !field.hasPermission || (field.hasPermission && field.isReadOnly)
            field.dependantFields = [];

            if (field.fieldName === 'Filiale_im_Einkaufszentrum__c') {
                field.dependantFields.push('Etage_der_Postfiliale_ggf_Lage__c');
                this.fieldsWithDependantFields.push(field);
            }
            if (field.fieldName === 'Fussgaengerzone__c') {
                field.dependantFields.push('EinschraenkungenFussgaengerzone__c');
                this.fieldsWithDependantFields.push(field);
            }
            if (field.fieldName === 'Halteverbote__c') {
                field.dependantFields.push('EinschraenkungenHalteverbote__c');
                this.fieldsWithDependantFields.push(field);
            }
            if (field.fieldName === 'Markttage__c') {
                field.dependantFields.push('EinschraenkungenMarkttage__c');
                this.fieldsWithDependantFields.push(field);
            }
            if (field.fieldName === 'GenehmigungenErforderlich__c') {
                field.dependantFields.push('ErforderlicheGenehmigungen__c');
                this.fieldsWithDependantFields.push(field);
            }
            if (field.fieldName === 'StufenVorhanden__c') {
                field.dependantFields.push('AnzahlStufen__c');
                this.fieldsWithDependantFields.push(field);
            }
            if (field.fieldName === 'AnlieferungUeberAufzug__c') {
                field.dependantFields.push('AngabeMasseTragkraftUndZugaenglichkeit__c');
                this.fieldsWithDependantFields.push(field);
            }
            if (field.fieldName === 'PaketrollbehaelterEinsatzMoeglich__c') {
                field.dependantFields.push('AnzahlStellmoeglichkeiten__c');
                this.fieldsWithDependantFields.push(field);
            }
            if (field.fieldName === 'BriefbehaelterwagenEinsatzMoeglich__c') {
                field.dependantFields.push('AnzahlBriefbehaelterwagen__c');
                this.fieldsWithDependantFields.push(field);
            }
        }
    }

    dispatchErrorToast(error) {

        const evt = new ShowToastEvent({
            title: error.statusText ? error.statusText : 'Error',
            message: error.body ? error.body.message : 'Something went wrong.',
            variant: 'error',
            mode: 'sticky'
        });
        this.dispatchEvent(evt);
        this.showSpinner = false;
        this.isSaving = false;
    }

    closeModal() {

        this.dispatchEvent(
            new CustomEvent('closeModal')
        );
    }

    handleOpenAllSections() {

        let activeSections = [];
        for (let j = 0; j < this.screen.sections.length; j++) {
            let section = this.screen.sections[j];
            activeSections.push(section.title);
        }
        this.screen.activeSections = activeSections;
    }

    handleCloseAllSections() {

        this.screen.activeSections = [];
    }

    get fieldStyle() {
        return '';
    }

    setDepandantFields(field, value) {
        if (field.fieldName === 'Filiale_im_Einkaufszentrum__c'
            || field.fieldName === 'Halteverbote__c'
            || field.fieldName === 'Markttage__c'
            || field.fieldName === 'GenehmigungenErforderlich__c'
            || field.fieldName === 'StufenVorhanden__c'
            || field.fieldName === 'AnlieferungUeberAufzug__c'
            || field.fieldName === 'PaketrollbehaelterEinsatzMoeglich__c'
            || field.fieldName === 'BriefbehaelterwagenEinsatzMoeglich__c'
            || field.fieldName === 'Fussgaengerzone__c') {
            field.dependantFields.forEach(fieldName => {

                let dependantField = this.fieldByFieldNames.get(fieldName);
                dependantField.isReadOnly = value !== 'Ja';
                dependantField.isDisabled = !dependantField.hasPermission || (dependantField.hasPermission && dependantField.isReadOnly);
            });
        }
    }

    handleDataChange(event) {

        let field = event.target.name;
        let value = field.isCheckbox ? event.target.checked : event.target.value;
        let newField = this.fieldByFieldNames.get(field.fieldName);
        newField.value = value;

        let isValid = field.fieldType === 'picklist' || field.fieldType === 'date' || field.fieldType === 'datetime'
            ? true
            : this.validateInput(event);

        if (isValid) {
            this.processSave(field, value);
        }
    }

    processSave(field, value) {
        this.isSaving = true;
        this.setDepandantFields(field, value);

        let apexRequest = new HwApexRequest(this);
        apexRequest
            .setMethod(saveFieldValue)
            .setMethodName("EinrichtungsprozessCtrl.saveFieldValue")
            .setParameters({
                recordId: field.objectName === 'Account' ? this.account.Id : this.einrichtungsprozess.Id,
                fieldName: field.fieldName,
                dataType: field.fieldType,
                value: value
            })
            .setConfig({
                showSpinner: false,
                showErrorMessage: false,
                showSuccessMessage: false,
                successMessage: "Success"
            });

        this.apexRequests.unshift(apexRequest);

        if (new hwRequestEvaluator().isExecuting) {
            return;
        }
        new hwRequestEvaluator().isExecuting = true;
        this.processRequestQueue(this.apexRequests[this.apexRequests.length - 1]);
    }

    processRequestQueue(request) {
        request
            .execute()
            .then((data) => {
                this.apexRequests.pop();

                if (this.apexRequests.length > 0) {
                    this.processRequestQueue(this.apexRequests[this.apexRequests.length - 1]);
                } else {
                    new hwRequestEvaluator().isExecuting = false;
                    this.isSaving = false;
                }
            })
            .catch((error) => {
                this.dispatchErrorToast(error);
            });
    }

    validateInput(event) {
        let inputComponent = event.target;
        inputComponent.setCustomValidity("");
        let isValid = inputComponent.checkValidity();
        inputComponent.reportValidity();
        return isValid;
    }

    openFilePreview(event) {

        let fileId = event.target.name.pictureId;
        this[NavigationMixin.Navigate]({
            type: 'standard__namedPage',
            attributes: {
                pageName: 'filePreview'
            },
            state: {
                recordIds: fileId,
                selectedRecordId: fileId
            }
        })
    }

    handleDocumentCreation(event) {

        if (!this.isSaving) {

            this.generateDocuments(event.target.title === 'Vorschau anzeigen');
        }
    }

    generateDocuments(isPreview) {
        this.showSpinner = true;
        this.isSaving = true;

        if (isPreview) {

            getDocumentUrl({
                recordId: this.einrichtungsprozess.Id
            })
                .then(url => {
                    window.open(url, '_blank');
                    this.showSpinner = false;
                    this.isSaving = false;
                })
                .catch(error => {

                    this.dispatchErrorToast(error);
                });

        } else {

            saveDocument({
                recordId: this.einrichtungsprozess.Id
            })
                .then(documentVersion => {
                    this.einrichtungsprozess.Dokumentenversion__c = documentVersion;
                    const evt = new ShowToastEvent({
                        title: 'Erfolg!',
                        message: 'Das Dokument wurde erfolgreich generiert.',
                        variant: 'success'
                    });
                    this.dispatchEvent(evt);
                    this.dispatchEvent(
                        new CustomEvent('refreshView')
                    );
                    this.showSpinner = false;
                    this.isSaving = false;
                })
                .catch(error => {

                    this.dispatchErrorToast(error);
                });
        }
    }

    get oeffnungszeitenExistieren(){
        return this.account && !this.account.FehlendeFactsOez__c;
    }

    handleChangeOeffnungszeiten(event){
        let wochentag = this.oeffnungszeiten[event.target.name];
        wochentag[event.target.label] = event.detail.value;
        this.isSaving = true;
        let apexRequest = new HwApexRequest(this);
        apexRequest
            .setMethod(saveWochentag)
            .setMethodName("EnrichtungsprozessAndienungCtrl.saveWochentag")
            .setParameters({
                wochentagString: JSON.stringify(wochentag)
            })
            .setConfig({
                showSpinner: false,
                showErrorMessage: false,
                showSuccessMessage: false,
                successMessage: "Success"
            });
        this.apexRequests.unshift(apexRequest);
        if (new hwRequestEvaluator().isExecuting) {
            return;
        }
        new hwRequestEvaluator().isExecuting = true;
        this.processRequestQueue(this.apexRequests[this.apexRequests.length - 1]);
    }
}