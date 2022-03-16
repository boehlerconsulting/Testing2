/**
 *@author       Mats Böhler
 *@created      05.02.2021
 *
 *
 *@description  einrichtungsprozess
 *
 *
 *@changelog    05.02.2021 Mats Böhler - Created
 *
 *
 */

import {LightningElement, api, track, wire} from "lwc";
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import init from '@salesforce/apex/EinrichtungsprozessCtrl.init';
import saveProcessState from '@salesforce/apex/EinrichtungsprozessCtrl.saveProcessState';
import saveProcessStateBestand from '@salesforce/apex/EinrichtungsBestandskonfiguratorCtrl.saveProcessState';
import saveFieldValue from '@salesforce/apex/EinrichtungsprozessBaseCtrl.saveFieldValue';
import getDocumentUrl from '@salesforce/apex/EinrichtungsprozessCtrl.getDocumentUrl';
import getPreviewUrl from '@salesforce/apex/EinrichtungsprozessCtrl.getPreviewUrl';
import saveDocument from '@salesforce/apex/EinrichtungsprozessCtrl.saveDocument';
import saveDocumentVorschau from '@salesforce/apex/EinrichtungsprozessCtrl.saveDocumentVorschau';
import copyFieldsFromAndienung from '@salesforce/apex/EinrichtungsprozessCtrl.copyFieldsFromAndienung';
import triggerBestellung from '@salesforce/apex/EinrichtungsprozessCtrl.triggerBestellung';
import triggerBestellungErsatz from '@salesforce/apex/EinrichtungsprozessCtrl.triggerBestellungErsatz';
import triggerBestellungZusatz from '@salesforce/apex/EinrichtungsprozessCtrl.triggerBestellungZusatz';
import saveAbbauProcess from '@salesforce/apex/EinrichtungsprozessCtrl.saveAbbauProcess';
import resetFilialausstattung from '@salesforce/apex/EinrichtungsprozessBaseCtrl.resetFilialausstattung';
import HwApexRequest from "c/hwApexRequest";
import hwRequestEvaluator from "c/hwRequestEvaluator";
import {NavigationMixin} from 'lightning/navigation';

export default class Einrichtungsprozess extends NavigationMixin(LightningElement) {

    @api recordId;
    @api isErsatzZusatz = false;
    @api isErsatz = false;
    @api isZusatz = false;
    @api isAbbau = false;
    @api process = '';
    @track isInitialized = false;
    @track showSpinner = true;
    @track screens;
    @track steps;
    @track oeffnungszeiten;
    @track activeStepIndex = 0;
    @track einrichtungsprozess;
    @track account;
    @track variant = 'Kühnert';
    fieldByFieldNames = new Map();
    fieldsWithDependantFields = [];
    hasPermission = false;
    @track apexRequests = [];
    @track isSaving = false;
    @track isEinrichtungskoordinator = false;
    @track beschreibungNachbesserung = '';

    connectedCallback() {

        this.init();
    }

    get activeScreen() {
        return this.screens[this.activeStepIndex];
    }

    init() {
        init({
            recordId: this.recordId,
            isErsatzZusatz: this.isErsatzZusatz,
            isAbbau: this.isAbbau,
            isErsatz: this.isErsatz
        })
            .then(result => {

                this.initialize(result);
            })
            .catch(error => {
                this.dispatchErrorToast(error);
            });
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

            if (field.fieldName === 'Geschaeftsvorfall__c' && this.account.Filialtyp_OZ__c === '82') {
                field.isReadOnly = true;
            }
            if (field.fieldName === 'AnzahlSchalter__c' && !this.isEinrichten) {
                field.isReadOnly = true;
            }
            if (field.fieldName === 'Wunschlieferuhrzeit__c'
                && (this.account.Filialtyp_OZ__c === '84' || this.account.Filialtyp_OZ__c === '78')) {
                field.isReadOnly = true;
            }
            field.hasPermission = this.hasPermission;
            field.isDisabled = !field.hasPermission || (field.hasPermission && field.isReadOnly)
            field.dependantFields = [];

            if (field.fieldName === 'Geschaeftsvorfall__c') {
                field.dependantFields.push('ASt_Id_Vorgaengerfiliale__c');
                this.fieldsWithDependantFields.push(field);
            }
            if (field.fieldName === 'Abweichende_Lieferanschrift__c') {
                field.dependantFields.push('Lieferanschrift__c');
                this.fieldsWithDependantFields.push(field);
            }
            if (field.fieldName === 'BA_Filiale_im_Einkaufszentrum__c') {
                field.dependantFields.push('BA_Etage_der_Postfiliale_ggf_Lage__c');
                this.fieldsWithDependantFields.push(field);
            }
            if (field.fieldName === 'BA_Fu_g_ngerzone__c') {
                field.dependantFields.push('BA_Einschr_nkungen_Fu_g_ngerzone__c');
                this.fieldsWithDependantFields.push(field);
            }
            if (field.fieldName === 'BA_Halteverbote__c') {
                field.dependantFields.push('BA_Einschr_nkungen_Halteverbote__c');
                this.fieldsWithDependantFields.push(field);
            }
            if (field.fieldName === 'BA_Markttage__c') {
                field.dependantFields.push('BA_Einschr_nkungen_Markttage__c');
                this.fieldsWithDependantFields.push(field);
            }
            if (field.fieldName === 'BA_Genehmigungen_erforderlich__c') {
                field.dependantFields.push('BA_Erforderliche_Genehmigungen__c');
                this.fieldsWithDependantFields.push(field);
            }
            if (field.fieldName === 'BA_Stufen_vorhanden__c') {
                field.dependantFields.push('BA_AnzahlStufen__c');
                this.fieldsWithDependantFields.push(field);
            }
            if (field.fieldName === 'BA_Anlieferung_ber_Aufzug__c') {
                field.dependantFields.push('BA_Angabe_Ma_e_Tragkraft_und_Zug_nglich__c');
                this.fieldsWithDependantFields.push(field);
            }
        }
    }

    initializeSections(screen) {
        for (let j = 0; j < screen.sections.length; j++) {
            let section = screen.sections[j];
            section.index = j;
            screen.activeSections.push(section.title);
            section.isFirstSectionOfFirstScreen = screen.index === 0 && j === 0;
            this.initializeFields(section);
        }
    }

    initializeScreens() {
        for (let i = 0; i < this.screens.length; i++) {
            let screen = this.screens[i];
            screen.index = i;
            screen.activeSections = [];
            screen.hasSections = screen.sections.length > 0;
            screen.showKonfigurator = i === 2 && !this.isErsatzZusatz && !this.isAbbau;
            screen.showBestand = i === 1 && !this.isErsatzZusatz && !this.isAbbau;
            screen.showErsatzZusatz = i === 1 && this.isErsatzZusatz;
            screen.showAbbau = i === 1 && this.isAbbau;
            this.initializeSections(screen);
        }
    }

    initialize(result) {
        let instance = JSON.parse(result);
        this.activeStepIndex = parseInt(instance.process.IndexAktivesFenster__c);
        this.screens = instance.screens;
        if (this.activeStepIndex > this.screens.length - 1) {
            this.activeStepIndex = this.screens.length - 1;
        }
        this.steps = instance.steps;
        this.oeffnungszeiten = instance.filialOeffnungszeiten;
        this.einrichtungsprozess = instance.process;
        this.account = instance.account;
        this.hasPermission = instance.hasPermission;
        this.isEinrichtungskoordinator = instance.isEinrichtungskoordinator;
        this.process = this.einrichtungsprozess.SubProzess__c
            ? this.einrichtungsprozess.SubProzess__c
            : this.process;
        this.abbauValue = this.einrichtungsprozess.ProzessAbbau__c
            ? this.einrichtungsprozess.ProzessAbbau__c
            : this.abbauValue;

        this.initializeScreens();

        this.fieldsWithDependantFields.forEach(field => {
            this.setDepandantFields(field, field.value);
        });

        for (let i = 0; i < this.steps.length; i++) {
            let step = this.steps[i];
            step.isOpen = i !== this.activeStepIndex;
            step.isActive = i === this.activeStepIndex;
        }
        this.calculateProgressValueWidth();
        this.isInitialized = true;
        this.showSpinner = false;
        this.isSaving = false;
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

    calculateProgressValueWidth() {

        this.template.querySelector(".slds-progress-bar__value").style.width =
            `${100 / (this.steps.length - 1) * (this.activeStepIndex)}%`;
    }

    handlePrevious() {
        this.showSpinner = true;
        this.setSteps(this.activeStepIndex - 1);
    }

    handleNext() {
        this.showSpinner = true;
        this.setSteps(this.activeStepIndex + 1);
    }

    handleStepChange(event) {
        this.showSpinner = true;
        this.setSteps(event.target.name ? event.target.name : event.target.alternativeText);
    }

    setSteps(activeStepIndex) {
        this.activeStepIndex = parseInt(activeStepIndex);

        for (let i = 0; i < this.steps.length; i++) {
            let step = this.steps[i];
            step.isOpen = i !== this.activeStepIndex;
            step.isActive = i === this.activeStepIndex;
        }
        this.saveActiveScreen();
        this.calculateProgressValueWidth();
    }

    saveActiveScreen() {

        saveProcessState({
            processId: this.einrichtungsprozess.Id,
            indexAktivesFenster: this.activeStepIndex
        })
            .then(url => {
                this.showSpinner = false;
            })
            .catch(error => {
                this.dispatchErrorToast(error);
            });
    }

    get showBackButton() {
        return this.activeStepIndex !== 0;
    }

    get showNextButton() {
        return this.steps && this.activeStepIndex < this.steps.length - 1;
    }

    get firstPage() {
        return this.activeStepIndex === 0;
    }

    closeModal() {

        this.dispatchEvent(
            new CustomEvent('closeModal')
        );
    }

    handleOpenAllSections() {

        let activeSections = [];
        for (let j = 0; j < this.activeScreen.sections.length; j++) {
            let section = this.activeScreen.sections[j];
            activeSections.push(section.title);
        }
        this.screens[this.activeStepIndex].activeSections = activeSections;
    }

    handleCloseAllSections() {

        this.screens[this.activeStepIndex].activeSections = [];
    }

    get fieldStyle() {
        return '';
    }

    setDepandantFields(field, value) {
        if (field.fieldName === 'Abweichende_Lieferanschrift__c'
            || field.fieldName === 'BA_Filiale_im_Einkaufszentrum__c'
            || field.fieldName === 'BA_Fu_g_ngerzone__c'
            || field.fieldName === 'BA_Halteverbote__c'
            || field.fieldName === 'BA_Markttage__c'
            || field.fieldName === 'BA_Genehmigungen_erforderlich__c'
            || field.fieldName === 'BA_Stufen_vorhanden__c'
            || field.fieldName === 'BA_Anlieferung_ber_Aufzug__c') {
            field.dependantFields.forEach(fieldName => {

                let dependantField = this.fieldByFieldNames.get(fieldName);
                dependantField.isReadOnly = value !== 'Ja';
                dependantField.isDisabled = !dependantField.hasPermission || (dependantField.hasPermission && dependantField.isReadOnly);
            });
        }
        if (field.fieldName === 'Geschaeftsvorfall__c') {
            field.dependantFields.forEach(fieldName => {

                let dependantField = this.fieldByFieldNames.get(fieldName);
                dependantField.isHidden = !(this.anschriftVorgaengerfilialeEqualsAnschrift
                    && (value === 'Betreiberwechsel' || value === 'Up-/Downgrade'));
            });
        }
    }

    get anschriftVorgaengerfilialeEqualsAnschrift() {
        return this.account.Vorgaengerfiliale__r ? this.account.ShippingStreet === this.account.Vorgaengerfiliale__r.ShippingStreet
            && this.account.ShippingPostalCode === this.account.Vorgaengerfiliale__r.ShippingPostalCode
            && this.account.ShippingCity === this.account.Vorgaengerfiliale__r.ShippingCity : false;
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

            if (field.fieldName === 'Geschaeftsvorfall__c'
                && this.einrichtungsprozess.AusstattungUebernahmeVorgaenger__c === undefined) {

                this.saveProcessStateBestand(value === 'Neueinrichtung' ? 'Nein' : 'Ja');
            }
            if (field.fieldName === 'Geschaeftsvorfall__c') {

                this.einrichtungsprozess.Geschaeftsvorfall__c = value;
            }
            if ( field.fieldName === 'AnzahlSchalter__c'){
                resetFilialausstattung({
                    accountId: this.account.Id,
                    einrichtungsprozessId: this.einrichtungsprozess.Id,
                })
                    .then(url => {
                        this.account.AnzahlSchalter__c = parseInt(value);
                        this.einrichtungsprozess.initialisiert__c = false;
                        if (this.template.querySelector('c-einrichtungs-konfigurator')){
                            this.template.querySelector('c-einrichtungs-konfigurator').reset();
                        }
                    })
                    .catch(error => {
                        this.dispatchErrorToast(error);
                    });
            }
        }
    }

    saveProcessStateBestand(zeigeBundles) {
        this.showSpinner = true;
        this.einrichtungsprozess.VorgaengerfilialeExistiert__c = 'Ja';
        this.einrichtungsprozess.AusstattungUebernahmeVorgaenger__c = zeigeBundles;
        this.einrichtungsprozess.Prozess__c = zeigeBundles === 'Ja' ? 'Vorgängerfiliale' : 'Neubestellung';

        saveProcessStateBestand({
            accountId: this.account.Id,
            einrichtungsprozessId: this.einrichtungsprozess.Id,
            previousExists: this.einrichtungsprozess.VorgaengerfilialeExistiert__c,
            zeigeBundles: zeigeBundles
        })
            .then(result => {

                if (this.template.querySelector('c-einrichtungs-konfigurator')) {
                    this.template.querySelector('c-einrichtungs-konfigurator').init();
                }
                if (this.template.querySelector('c-einrichtungs-bestandskonfigurator')) {
                    this.template.querySelector('c-einrichtungs-bestandskonfigurator').init();
                }
                this.showSpinner = false;
            })
            .catch(error => {
                this.dispatchErrorToast(error);
            });
    }

    handleKommentarChange(event) {

        let field = {};
        field.objectName = 'Einrichtungsprozess__c';
        field.fieldName = 'Kommentar_VM__c';
        field.fieldType = 'text';
        this.processSave(field, event.target.value);
    }

    handleKostenstelleChange(event) {

        let field = {};
        field.objectName = 'Einrichtungsprozess__c';
        field.fieldName = 'AbweichendeKostenstelle__c';
        field.fieldType = 'text';
        this.processSave(field, event.target.value);
    }

    handleLieferantentextChange(event) {

        let field = {};
        field.objectName = 'Einrichtungsprozess__c';
        field.fieldName = 'LieferantentextZusatz__c';
        field.fieldType = 'text';
        this.processSave(field, event.target.value);
    }

    handleLagerstandortChange(event) {

        let field = {};
        field.objectName = 'Einrichtungsprozess__c';
        field.fieldName = 'Lagerstandort__c';
        field.fieldType = 'text';
        this.processSave(field, event.target.value);
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
                recordId: this.einrichtungsprozess.Id,
                variant: this.variant,
                process: this.isAbbau ? this.abbauValue : this.documentVersion
            })
                .then(url => {
                    window.open(url, '_blank');
                    this.showSpinner = false;
                    this.isSaving = false;
                })
                .catch(error => {

                    this.dispatchErrorToast(error);
                });
            this.showSpinner = false;
        } else {
            let variants = new Set();
            this.variantOptions.forEach(variantOption => {
                for (const [key, value] of Object.entries(variantOption)) {

                    variants.add(value);
                }
            });

            let process = this.isAbbau ? this.abbauValue : this.documentVersion;

            saveDocument({
                accountId: this.account.Id,
                recordId: this.einrichtungsprozess.Id,
                variants: Array.from(variants).join(','),
                process: process
            })
                .then(response => {

                    if (response === 'Ersatzbestellung') {
                        saveDocument({
                            accountId: this.account.Id,
                            recordId: this.einrichtungsprozess.Id,
                            variants: Array.from(variants).join(','),
                            process: 'Teilabbau'
                        })
                            .then(response => {

                                const evt = new ShowToastEvent({
                                    title: 'Erfolg!',
                                    message: 'Die Bestellblätter wurden erfolgreich generiert.',
                                    variant: 'success'
                                });
                                this.dispatchEvent(evt);
                                this.dispatchEvent(
                                    new CustomEvent('refreshView')
                                );
                                this.showSpinner = false;
                                this.isSaving = false;
                                this.closeModal();
                            })
                            .catch(error => {

                                this.dispatchErrorToast(error);
                                this.showSpinner = false;
                            });
                    } else {
                        const evt = new ShowToastEvent({
                            title: 'Erfolg!',
                            message: 'Die Bestellblätter wurden erfolgreich generiert.',
                            variant: 'success'
                        });
                        this.dispatchEvent(evt);
                        this.dispatchEvent(
                            new CustomEvent('refreshView')
                        );
                        this.showSpinner = false;
                        this.isSaving = false;
                        this.closeModal();
                    }
                })
                .catch(error => {

                    this.dispatchErrorToast(error);
                    this.showSpinner = false;
                });
        }
    }

    generateDocumentVorschau() {
        this.showSpinner = true;
        this.isSaving = true;

        let process = this.isAbbau ? this.abbauValue : this.documentVersion;

        saveDocumentVorschau({
            accountId: this.account.Id,
            recordId: this.einrichtungsprozess.Id,
            process: process
        })
            .then(response => {

                this.bestellungAusloesenProcessed();
            })
            .catch(error => {

                this.dispatchErrorToast(error);
                this.showSpinner = false;
            });
    }

    generateDocumentVorschauAbbau() {
        this.showSpinner = true;
        this.isSaving = true;

        let process = this.isAbbau ? this.abbauValue : this.documentVersion;

        saveDocumentVorschau({
            accountId: this.account.Id,
            recordId: this.einrichtungsprozess.Id,
            process: process
        })
            .then(response => {

                const evt = new ShowToastEvent({
                    title: 'Erfolg!',
                    message: 'Der Rückbau wurde ausgelöst und der Einrichtungskoordinator informiert.',
                    variant: 'success'
                });
                this.dispatchEvent(evt);
                this.dispatchEvent(
                    new CustomEvent('refreshView')
                );
                this.isSaving = false;
                this.showSpinner = false;
                this.closeModal();
            })
            .catch(error => {

                this.dispatchErrorToast(error);
                this.showSpinner = false;
            });
    }

    previewDocument() {
        this.showSpinner = true;
        this.isSaving = true;

        getPreviewUrl({
            recordId: this.einrichtungsprozess.Id,
            process: this.isAbbau ? this.abbauValue : this.documentVersion
        })
            .then(url => {
                window.open(url, '_blank');
                this.showSpinner = false;
                this.isSaving = false;
            })
            .catch(error => {

                this.dispatchErrorToast(error);
            });
        this.showSpinner = false;
    }

    get documentVersion() {
        return this.isErsatzZusatz ? this.process : '';
    }

    get isPageOne() {
        return this.activeStepIndex === 0;
    }

    get isNeubestellungPageThree() {
        return this.activeStepIndex === 2 && !this.isErsatzZusatz;
    }

    get isErsatzPageTwo() {
        return this.activeStepIndex === 1 && this.isErsatzZusatz && this.isErsatz;
    }

    get isZusatzPageTwo() {
        return this.activeStepIndex === 1 && this.isErsatzZusatz && this.isZusatz;
    }

    handleCopyFields() {
        this.isSaving = true;
        this.showSpinner = true;

        copyFieldsFromAndienung({
            processId: this.einrichtungsprozess.Id
        })
            .then(result => {

                this.init();
            })
            .catch(error => {
                this.dispatchErrorToast(error);
            });
    }

    handleProcessChanged(event) {
        this.einrichtungsprozess.Prozess__c = event.detail.process;
        this.einrichtungsprozess.AusstattungUebernahmeVorgaenger__c = event.detail.zeigeBundles;
        this.einrichtungsprozess.VorgaengerfilialeExistiert__c = event.detail.previousExists;
        if (this.template.querySelector('c-einrichtungs-konfigurator')) {
            this.template.querySelector('c-einrichtungs-konfigurator').init();
        }
    }

    handleBestellungAusloesen() {
        this.isSaving = true;
        this.showSpinner = true;

        if (this.isErsatzZusatz && this.isErsatz) {
            triggerBestellungErsatz({
                accountId: this.account.Id,
                einrichtungsprozessId: this.einrichtungsprozess.Id
            })
                .then(result => {

                    this.generateDocumentVorschau();
                })
                .catch(error => {
                    this.dispatchErrorToast(error);
                });
        } else if (this.isErsatzZusatz && this.isZusatz) {
            triggerBestellungZusatz({
                accountId: this.account.Id,
                einrichtungsprozessId: this.einrichtungsprozess.Id
            })
                .then(result => {

                    this.generateDocumentVorschau();
                })
                .catch(error => {
                    this.dispatchErrorToast(error);
                });
        } else {
            triggerBestellung({
                accountId: this.account.Id,
                einrichtungsprozessId: this.einrichtungsprozess.Id
            })
                .then(result => {

                    this.generateDocumentVorschau();
                })
                .catch(error => {
                    this.dispatchErrorToast(error);
                });
        }
    }

    handleAbbauAusloesen() {

        this.generateDocumentVorschauAbbau();
    }

    bestellungAusloesenProcessed() {
        const evt = new ShowToastEvent({
            title: 'Erfolg!',
            message: 'Die Bestellung wurde ausgelöst und der Einrichtungskoordinator informiert.',
            variant: 'success'
        });
        this.dispatchEvent(evt);
        this.dispatchEvent(
            new CustomEvent('refreshView')
        );
        this.isSaving = false;
        this.showSpinner = false;
        this.closeModal();
    }

    get variantOptions() {
        return [
            {label: 'Kühnert', value: 'Kühnert'},
            {label: 'DHL-Solutions', value: 'DHL-Solutions'},
            {label: 'EK', value: 'EK'},
            {label: 'Spedition', value: 'Spedition'},
            {label: 'GeT-Bot', value: 'GeT-Bot'},
        ];
    }

    handleVariantChange(event) {
        this.variant = event.target.value;
    }

    handleRefreshView() {
        this.dispatchEvent(
            new CustomEvent('refreshView')
        );
        this.closeModal();
    }

    get abbauOptions() {
        return [
            {label: 'Teilabbau', value: 'Teilabbau'},
            {label: 'Filialschließung', value: 'Filialschließung'}
        ];
    }

    @track abbauValue = '';

    handleAbbauOptionChange(event) {
        this.abbauValue = event.target.value;
        this.isSaving = true;
        this.showSpinner = true;

        saveAbbauProcess({
            recordId: this.einrichtungsprozess.Id,
            abbauProcess: this.abbauValue
        })
            .then(result => {

                if (this.template.querySelector('c-einrichtungs-konfigurator-abbau')
                    && this.abbauValue === 'Filialschließung') {

                    this.template.querySelector('c-einrichtungs-konfigurator-abbau').handleSelectAllOptions();

                } else if (this.template.querySelector('c-einrichtungs-konfigurator-abbau')
                    && this.abbauValue === 'Teilabbau') {

                    this.template.querySelector('c-einrichtungs-konfigurator-abbau').handleDeselectAllOptions();
                }

                this.dispatchEvent(
                    new CustomEvent('refreshView')
                );
                this.isSaving = false;
                this.showSpinner = false;
            })
            .catch(error => {
                this.dispatchErrorToast(error);
            });
    }

    handleCloseAllSectionsKonfigurator() {
        if (this.isErsatzZusatz) {
            if (this.template.querySelector('c-einrichtungs-konfigurator-ersatz')) {
                this.template.querySelector('c-einrichtungs-konfigurator-ersatz').handleCloseAllSections();
            }
        } else if (this.isAbbau) {
            if (this.template.querySelector('c-einrichtungs-konfigurator-abbau')) {
                this.template.querySelector('c-einrichtungs-konfigurator-abbau').handleCloseAllSections();
            }
        }
    }

    handleOpenAllSectionsKonfigurator() {

        if (this.isErsatzZusatz) {
            if (this.template.querySelector('c-einrichtungs-konfigurator-ersatz')) {
                this.template.querySelector('c-einrichtungs-konfigurator-ersatz').handleOpenAllSections();
            }
        } else if (this.isAbbau) {
            if (this.template.querySelector('c-einrichtungs-konfigurator-abbau')) {
                this.template.querySelector('c-einrichtungs-konfigurator-abbau').handleOpenAllSections();
            }
        }
    }

    handleCloseAllSectionsKonfiguratorZusatz() {
        if (this.template.querySelectorAll('c-einrichtungs-konfigurator-abbau')[1]) {
            this.template.querySelectorAll('c-einrichtungs-konfigurator-abbau')[1].handleCloseAllSections();
        }
    }

    handleOpenAllSectionsKonfiguratorZusatz() {

        if (this.template.querySelectorAll('c-einrichtungs-konfigurator-abbau')[1]) {
            this.template.querySelectorAll('c-einrichtungs-konfigurator-abbau')[1].handleOpenAllSections();
        }
    }

    get isAbbauPageTwo() {
        return this.activeStepIndex === 1 && this.isAbbau;
    }

    get hideCopyButton() {
        return this.isEinrichtungskoordinator
            && this.account.Filialart__c
            && !this.account.Filialart__c.startsWith('DPS');
    }

    get isEinrichten(){
        return !this.isErsatz && !this.isZusatz && !this.isAbbau;
    }
}