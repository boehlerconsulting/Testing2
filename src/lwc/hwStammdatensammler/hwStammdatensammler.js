/**
 *@author       Mats Böhler
 *@created      02.04.2019
 *@version      1.0
 *@since        45.0
 *
 *
 *@description  hwStammdatensammler
 *
 *
 *@changelog    02.04.2019 Mats Böhler - Created
 *
 *
 */

//LWC
import {LightningElement, api, track} from "lwc";
import {ShowToastEvent} from "lightning/platformShowToastEvent";
//Custom Javascript
import {hideSpinner} from "c/hwSpinnerController";
import HwApplicationState from "c/hwApplicationState";
import HwApplicationStateActionDispatcher from "c/hwApplicationStateActionDispatcher";
import * as ActionCreator from "c/hwStammdatensammlerActionCreator";
import {reduce} from "c/hwStammdatensammlerReducer";
//Custom Apex
import loadData from '@salesforce/apex/HW_Stammdatensammler_LC.loadData';
import resetFirstRun from '@salesforce/apex/HW_Stammdatensammler_LC.resetFirstRunHelper';

export default class HW_Stammdatensammler extends LightningElement {

    @api recordId;
    @api isExistingMAEF = false;
    @api isFirstLoad = false;
    @api isFormataenderung = false;
    @track state = {
        recordId: null,
        currentStep: 'default',
        showModal: false,
        screens: null,
        steps: null,
        object: null,
        contract: null,
        conditionallyRenderedFields: [],
        formulaFieldsSObject: [],
        formulaFieldNamesSObject: [],
        formulaFieldsContract: [],
        formulaFieldNamesContract: [],
        isFiliale95: false,
        isFiliale79: false,
        isFiliale84: false,
        isDifferent_RE_EKP_known: false,
        isDifferent_RE_EKP_unknown: false,
        isDifferent_ZR_EKP_known: false,
        isDifferent_ZR_EKP_unknown: false,
        isPostfachanlagePresent: false,
        isVorgaengerfilialePresent: false,
        isKasseChangeRequired: false,
        showSpinner: true,
        isFactsSent: false,
        isExistingMAEF: false,
        maefUrl: '',
        apexRequests: [],
        requestExecuting: false,
        sentDocuments: new Set()
    };
    @track buttonName = 'Prozess starten';
    @track showComponent = false;
    applicationState = null;
    dispatcher = null;

    connectedCallback() {
        this.loadData();
    }

    loadData() {
        loadData({
            recordId: this.recordId,
            isExistingMAEF: this.isExistingMAEF
        })
            .then(result => {
                this.initializeContainerComponent(result);
            })
            .catch(error => {
                hideSpinner(this);
                let errorTitle;
                if (error.body.message) {
                    errorTitle = error.body.message;
                } else {
                    errorTitle = "Error initializing container component. Please contact your system administrator.";
                }
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: errorTitle,
                        message: error.body.message,
                        variant: "error"
                    })
                );
                this.closeModal();
            });
    }

    initializeContainerComponent(po_Result) {
        let lo_ControllerInstance = po_Result;
        if (!lo_ControllerInstance) {
            window.open('/' + this.recordId, '_Self');
        } else {
            lo_ControllerInstance = JSON.parse(po_Result);
            this.state.object = lo_ControllerInstance.io_SObject;
            this.state.contract = lo_ControllerInstance.io_Contract;
            this.state.screens = lo_ControllerInstance.il_Screens;
            this.state.steps = lo_ControllerInstance.il_Steps;
            this.state.recordId = this.state.object.Id;
            this.state.isExistingMAEF = this.isExistingMAEF;

            resetFirstRun({
                contractString: JSON.stringify(this.state.contract),
            })
                .then(result => {
                    this.state.contract.SDS_Helper_FirstRun__c = result;
                })
            if (!this.isExistingMAEF) {
                this.setStepStages();
            }
            this.isFirstLoad = this.state.contract.SDS_Helper_FirstRun__c;
            if (this.isFirstLoad) {
                this.state.showModal = true;
            }
            this.isFormataenderung = this.state.contract.Formataenderung__c;

            for (let i = 0; i < this.state.screens.length; i++) {

                this.state.screens[i].showFirstWarning = this.state.object.Zeige_Hinweis_Gewerbeschein__c;
                this.state.screens[i].showSecondWarning = this.state.object.Zeige_Hinweis_Polizeiliches_Fuhrungszeug__c;

                if (this.isFormataenderung) {
                    this.state.screens[i].showFirstWarning = false;
                    this.state.screens[i].showSecondWarning = false;
                }

                for (let j = 0; j < this.state.screens[i].buttons.length; j++) {

                    let screenButton = this.state.screens[i].buttons[j];
                    screenButton.isDisabled = false;
                    screenButton.screenPosition = i;
                    screenButton.position = j;

                    screenButton.fieldMappingMap = new Map();

                    if (!screenButton.iv_isPreview) {

                        let fieldMappings = screenButton.pflichtfelder;

                        for (let k = 0; k < fieldMappings.length; k++) {
                            let fieldMapping = fieldMappings[k];
                            let objectName = fieldMapping.Feld__r.Objektname__c;
                            let fieldName = fieldMapping.Feld__r.Feldname__c;
                            let isRequired = true;
                            let isHidden = fieldMapping.Feld__r.Ausblenden__c;
                            let fieldType = fieldMapping.Feld__r.Feldtyp__c;
                            let isFormulaField = fieldMapping.Feld__r.ist_Formelfeld__c;
                            let fieldValue = objectName !== 'Contract' ? this.state.object[fieldName] : this.state.contract[fieldName];
                            fieldMapping.isValid = !!(fieldValue
                                || fieldValue === 0
                                || fieldValue === '0'
                                || !isRequired
                                || isHidden
                                || fieldType === 'checkbox'
                                || isFormulaField);
                            if (!screenButton.fieldMappingMap.has(objectName + fieldName)) {
                                screenButton.fieldMappingMap.set(objectName + fieldName, fieldMapping);
                            }
                        }
                    }
                }

                for (let j = 0; j < this.state.screens[i].sections.length; j++) {
                    let section = this.state.screens[i].sections[j];
                    this.setActiveSections(i, j);
                    this.setFieldClassifications(i, j);
                    section.hide = false;
                    if (section.iv_HasOeffnungszeiten) {
                        for (let k = 0; k < this.state.screens[i].sections[j].il_Oeffnungszeits.length; k++) {
                            let oeffnungszeit = this.state.screens[i].sections[j].il_Oeffnungszeits[k];

                            oeffnungszeit.hide = !this.state.isPostfachanlagePresent && section.iv_Title === 'Veränderungsmeldung zu Postfachanlagen (PfA)';
                        }
                    }
                }
            }
            this.setFieldVisibility();
            this.setSentDocuments();
            for (let i = 0; i < this.state.screens.length; i++) {

                for (let j = 0; j < this.state.screens[i].buttons.length; j++) {

                    let screenButton = this.state.screens[i].buttons[j];

                    screenButton.showSpinner = false;
                    screenButton.isHidden = false;
                    screenButton.isDocumentSent = false;
                    if (!this.state.isFiliale95 && screenButton.iv_VisualforceName === 'HW_Postbankanfrage') {
                        screenButton.isHidden = true;
                    }
                    if (this.state.isFiliale84 && screenButton.iv_VisualforceName === 'HW_Zuverlaessigkeitspruefung') {
                        screenButton.isHidden = true;
                    }
                    if (!screenButton.iv_isPreview && this.state.sentDocuments.has(screenButton.iv_VisualforceName)) {
                        screenButton.isDisabled = true;
                        screenButton.allRequiredDocumentsSent = true;
                        screenButton.lv_AllFieldsValid = true;
                        screenButton.isDocumentSent = true;
                    } else if (!screenButton.iv_isPreview) {
                        screenButton.lv_AllFieldsValid = true;
                        for (let [fieldMapping] of screenButton.fieldMappingMap) {
                            if (!fieldMapping.isValid) {
                                screenButton.lv_AllFieldsValid = false;
                            }
                        }
                        screenButton.allRequiredDocumentsSent = true;
                        for (let k = 0; k < screenButton.pflichtdokumente.length; k++) {
                            let pflichtdokument = screenButton.pflichtdokumente[k];
                            if (!this.state.sentDocuments.has(pflichtdokument.Pflichtdokument__r.Visualforce_Page__c)) {
                                screenButton.allRequiredDocumentsSent = false;
                            }
                        }
                        screenButton.isDisabled = !screenButton.lv_AllFieldsValid || !screenButton.allRequiredDocumentsSent;
                    }
                }

                this.setSectionVisibility(i);
            }
            this.applicationState = new HwApplicationState(this, reduce, {historicizeState: false});
            this.dispatcher = new HwApplicationStateActionDispatcher(this);
            this.showComponent = true;
            this.state.showSpinner = false;
        }
    }

    setSentDocuments() {
        if (this.state.object["Postbankanfrage_versendet__c"]) {
            this.state.sentDocuments.add('HW_Postbankanfrage');
        }
        if (this.state.object["Selbstauskunft_versendet__c"]) {
            this.state.sentDocuments.add('HW_Selbstauskunft');
        }
        if (this.state.object["Debitoranfrage_versendet__c"]) {
            this.state.sentDocuments.add('HW_SAP_Debitoren_beantragen');
        }
        if (this.state.contract["Vertragsdokument_versendet__c"]) {
            this.state.sentDocuments.add('HW_Vertragsdokument');
        }
        if (this.state.contract["MAEF_versendet__c"]) {
            this.state.sentDocuments.add('HW_MAEF');
        }
        if (this.state.contract["Kontraktpflege_versendet__c"]) {
            this.state.sentDocuments.add('HW_SAP_Neuanlage');
        }
        if (this.state.contract["FACTS_versendet__c"]) {
            this.state.sentDocuments.add('HW_FACTS_Stammdatenbeleg');
            this.state.isFactsSent = true;
        }
    }

    setSectionVisibility(screenIndex) {
        let screen = this.state.screens[screenIndex];
        for (let i = 0; i < screen.sections.length; i++) {
            let section = screen.sections[i];
            section.hide = true;
            for (let j = 0; j < section.il_Fields.length; j++) {
                let field = section.il_Fields[j];
                if (!field.hide && !field.Ausblenden) {
                    section.hide = false;
                    break;
                }
            }
        }
    }

    setStepStages() {
        for (let i = 0; i < this.state.steps.length; i++) {
            let step = this.state.steps[i];
            step.isDone = false;
            step.isActive = false;
            step.isOpen = false;
            step.isSkipped = false;
            step.isDoneAndActive = false;
            this.state.screens[i].isDone = false;
            this.state.screens[i].isLocked = false;
            switch (step.iv_Status) {
                case "open":
                    step.isOpen = true;
                    break;
                case "active":
                    step.isActive = true;
                    break;
                case "incomplete":
                    step.isSkipped = true;
                    break;
                case "done":
                    step.isDone = true;
                    break;
                case "doneAndActive":
                    step.isDoneAndActive = true;
                    break;
                default:
                    step.isOpen = true;
                    break;
            }
            if (step.iv_Status === 'active' || step.iv_Status === 'doneAndActive') {
                this.state.currentStep = step;
                this.state.screens[i].isActive = true;
            }
            if (step.iv_Status === 'done' || step.iv_Status === 'doneAndActive') {
                this.state.screens[i].isDone = true;
            }
            if (step.iv_IsLocked) {
                this.state.screens[i].isLocked = true;
            }
            this.state.screens[i].position = i;
        }
    }

    setActiveSections(screenIndex, sectionIndex) {
        if (sectionIndex === 0) {
            this.state.screens[screenIndex].activeSections.push(this.state.screens[screenIndex].sections[sectionIndex].iv_Title);
        }
    }

    setFieldClassifications(screenIndex, sectionIndex) {
        if (this.state.screens[screenIndex].sections[sectionIndex].il_Fields) {
            this.state.screens[screenIndex].sections[sectionIndex].recordsExist = true;

            for (let k = 0; k < this.state.screens[screenIndex].sections[sectionIndex].il_Fields.length; k++) {

                let fieldName = this.state.screens[screenIndex].sections[sectionIndex].il_Fields[k].Feldname;
                let field = this.state.screens[screenIndex].sections[sectionIndex].il_Fields[k];
                field.screenPosition = screenIndex;
                field.sectionPosition = sectionIndex;
                field.position = k;
                field.value = field.Objektname !== 'Contract' ? this.state.object[fieldName] : this.state.contract[fieldName];
                field.valueOld = field.Objektname !== 'Contract' ? this.state.object[fieldName] : this.state.contract[fieldName];
                field.Id = field.Objektname !== 'Contract' ? this.state.object['Id'] : this.state.contract['Id'];
                field.isFirstColumn = field.Spalte === '1';
                field.isSecondColumn = field.Spalte === '2';
                field.isText = field.Feldtyp === 'text';
                field.isCheckbox = field.Feldtyp === 'checkbox';
                field.isNumber = field.Feldtyp === 'number';
                field.isPhone = field.Feldtyp === 'tel';
                field.isDate = field.Feldtyp === 'date';
                field.isDateTime = field.Feldtyp === 'datetime';
                field.isEmail = field.Feldtyp === 'email';
                field.isPicklist = field.Feldtyp === 'picklist';
                field.isPercent = field.Feldtyp === 'percent';
                field.isCurrency = field.Feldtyp === 'currency';
                field.isFormula = field.ist_Formelfeld;

                if (fieldName === 'Filialtyp__c') {
                    if (this.state.contract[fieldName] === '95') {
                        this.state.isFiliale95 = true;
                    }
                    if (this.state.contract[fieldName] === '79') {
                        this.state.isFiliale79 = true;
                    }
                    if (this.state.contract[fieldName] === '84') {
                        this.state.isFiliale84 = true;
                    }
                }
                if (fieldName === 'Filialstandort_abw_Rechnungsempfaenger__c') {
                    if (this.state.object[fieldName] === 'ja, EKP-Nr. siehe nachfolgende Zeile') {
                        this.state.isDifferent_RE_EKP_known = true;
                    }
                    if (this.state.object[fieldName] === 'ja, EKP-Nr. anlegen, siehe Debitor II') {
                        this.state.isDifferent_RE_EKP_unknown = true;
                    }
                }
                if (fieldName === 'Filialstandort_abw_Zahlungsregulierer__c') {
                    if (this.state.object[fieldName] === 'ja, EKP-Nr. siehe nachfolgende Zeile') {
                        this.state.isDifferent_ZR_EKP_known = true;
                    }
                    if (this.state.object[fieldName] === 'ja, EKP-Nr. anlegen, siehe Debitor III') {
                        this.state.isDifferent_ZR_EKP_unknown = true;
                    }
                }
                if (fieldName === 'PostfachanlageVorhanden__c') {
                    this.state.isPostfachanlagePresent = this.state.contract[fieldName];
                }
                if (fieldName === 'AenderungAnKassenErforderlich__c') {
                    this.state.isKasseChangeRequired = this.state.contract[fieldName];
                }
                if (fieldName === 'VorgaengerfilialeVorhanden__c') {
                    this.state.isVorgaengerfilialePresent = this.state.contract[fieldName];
                }
                if (!field.OZ_95
                    || !field.OZ_84
                    || !field.OZ_79
                    || field.Abweichender_RE_und_EKP_bekannt
                    || field.Abweichender_RE_und_EKP_unbekannt
                    || field.Abweichender_ZR_und_EKP_bekannt
                    || field.Abweichender_ZR_und_EKP_unbekannt
                    || field.Postfachanlage_vorhanden
                    || field.VorgaengerfilialeVorhanden
                    || field.Aenderung_an_Kasse_erforderlich) {

                    this.state.conditionallyRenderedFields.push(field);
                }
                if (field.isFormula && field.Objektname !== 'Contract') {

                    this.state.formulaFieldsSObject.push(field);
                    this.state.formulaFieldNamesSObject.push(String(field.Feldname));
                } else if (field.isFormula) {
                    this.state.formulaFieldsContract.push(field);
                    this.state.formulaFieldNamesContract.push(String(field.Feldname));
                }
                field.hide = false;
            }
        } else {
            this.state.screens[screenIndex].sections[sectionIndex].recordsExist = false;
        }
    }

    setFieldVisibility() {
        for (let i = 0; i < this.state.conditionallyRenderedFields.length; i++) {
            let fieldMarker = this.state.conditionallyRenderedFields[i];
            let field = this.state.screens[fieldMarker.screenPosition].sections[fieldMarker.sectionPosition].il_Fields[fieldMarker.position];
            if (!this.state.contract.Formataenderung__c) {
                if (this.state.isFiliale84 && !field.OZ_84) {
                    field.hide = true;
                }
                if (this.state.isFiliale79 && !field.OZ_79) {
                    field.hide = true;
                }
                if (this.state.isFiliale95 && !field.OZ_95) {
                    field.hide = true;
                }
                if (!this.state.isDifferent_RE_EKP_known && field.Abweichender_RE_und_EKP_bekannt) {
                    field.hide = true;
                }
                if (!this.state.isDifferent_RE_EKP_unknown && field.Abweichender_RE_und_EKP_unbekannt) {
                    field.hide = true;
                }
                if (!this.state.isDifferent_ZR_EKP_known && field.Abweichender_ZR_und_EKP_bekannt) {
                    field.hide = true;
                }
                if (!this.state.isDifferent_ZR_EKP_unknown && field.Abweichender_ZR_und_EKP_unbekannt) {
                    field.hide = true;
                }
                if (!this.state.isPostfachanlagePresent && field.Postfachanlage_vorhanden) {
                    field.hide = true;
                }
                if (!this.state.isKasseChangeRequired && field.Aenderung_an_Kasse_erforderlich) {
                    field.hide = true;
                }
                if (!this.state.isVorgaengerfilialePresent && field.VorgaengerfilialeVorhanden) {
                    field.hide = true;
                }
            }
            for (let i = 0; i < this.state.screens[fieldMarker.screenPosition].buttons.length; i++) {
                let lo_Button = this.state.screens[fieldMarker.screenPosition].buttons[i];
                if (lo_Button.fieldMappingMap.has(field.Objektname + field.Feldname) && !lo_Button.iv_isPreview) {
                    let lo_FieldMapping = lo_Button.fieldMappingMap.get(field.Objektname + field.Feldname);
                    if (field.hide || !field.Erforderlich || field.isCheckbox || field.isFormula) {
                        lo_FieldMapping.isValid = true;
                    }
                }
            }
            if (fieldMarker.screenPosition === 3) {
                for (let i = 0; i < this.state.screens[fieldMarker.screenPosition + 1].buttons.length; i++) {

                    let button = this.state.screens[fieldMarker.screenPosition + 1].buttons[i];
                    if (button.fieldMappingMap.has(field.Objektname + field.Feldname) && !button.iv_isPreview) {
                        let fieldMapping = button.fieldMappingMap.get(field.Objektname + field.Feldname);
                        if (field.hide || !field.Erforderlich || field.isCheckbox || field.isFormula) {
                            fieldMapping.isValid = true;
                        }
                    }
                }
            }
        }
    }

    openModal() {
        this.state.showModal = true;
    }

    @api
    closeModal() {
        this.dispatchEvent(
            new CustomEvent('closeModal')
        );
        this.dispatchEvent(
            new CustomEvent('refreshView')
        );
        this.state.showModal = false;
    }

    @api
    showToast(message) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Erfolg',
                message: message,
                variant: "success"
            })
        );
    }

    setCurrentStep(event) {
        const stepIndex = event.detail.index;
        if (stepIndex !== undefined) {
            this.dispatcher.dispatch(
                ActionCreator.setSteps(
                    stepIndex
                )
            );
        }
    }

    get isWrongRecordType() {
        let recordType = this.state.object ? this.state.object.RecordType.DeveloperName : '';
        return recordType === 'Filiale_Dummy' || recordType === 'Filialpartner' || recordType === 'OrgE_Dummy';
    }
}