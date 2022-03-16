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
import {LightningElement, api, track, wire} from "lwc";
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import {getRecord, getFieldValue, updateRecord} from "lightning/uiRecordApi";


//Custom Javascript
import * as Logger from "c/hwLogger";
import {showSpinner, hideSpinner} from "c/hwSpinnerController";
import HwApexRequest from "c/hwApexRequest";
import HwApplicationState from "c/hwApplicationState";
import HwApplicationStateActionDispatcher from "c/hwApplicationStateActionDispatcher";
import * as ActionCreator from "c/hwStammdatensammlerActionCreator";
import {reduce} from "c/hwStammdatensammlerReducer";

//Apex
import {refreshApex} from "@salesforce/apex";

//Custom Apex
import loadData from '@salesforce/apex/HW_Stammdatensammler_LC.loadData';
import resetFirstRun from '@salesforce/apex/HW_Stammdatensammler_LC.resetFirstRunHelper';

export default class HW_Stammdatensammler extends LightningElement {

    @api recordId;
    @api isExistingMAEF = false;
    @api isFirstLoad = false;
    @api isFormataenderung = false;

    //Tracked Properties
    @track io_State = {
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

    @track iv_ButtonName = 'Prozess starten';
    @track iv_ShowComponent = false;

    //Private Properties
    io_ApplicationState = null;
    io_Dispatcher = null;

    connectedCallback() {
        Logger.setLoggingLevel(40);
        Logger.startBlock("hwStammdatensammler.connectedCallback")();

        this.loadData();

        Logger.endBlock()();
    }

    loadData() {
        loadData({
                recordId: this.recordId,
                isExistingMAEF: this.isExistingMAEF
            })
            .then(result => {
                this.initializeContainerComponent(result);
            })
            .catch(p_Error => {
                Logger.log("p_Error", {data: p_Error})();
                hideSpinner(this);
                var errorTitle
                if(p_Error.body.message) {
                    errorTitle = p_Error.body.message;
                } else {
                    errorTitle = "Error initializing container component. Please contact your system administrator.";
                }
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: errorTitle,
                        message: p_Error.body.message,
                        variant: "error"
                    })
                );
                this.closeModal();
            });
    }

    initializeContainerComponent(po_Result) {
        Logger.startBlock("hwStammdatensammler.initializeContainerComponent")();

        let lo_ControllerInstance = po_Result;
        if (!lo_ControllerInstance) {

            window.open('/' + this.recordId, '_Self');

        } else {
            lo_ControllerInstance = JSON.parse(po_Result);

            this.io_State.object = lo_ControllerInstance.io_SObject;
            this.io_State.contract = lo_ControllerInstance.io_Contract;
            this.io_State.screens = lo_ControllerInstance.il_Screens;
            this.io_State.steps = lo_ControllerInstance.il_Steps;
            this.io_State.recordId = this.io_State.object.Id;
            this.io_State.isExistingMAEF = this.isExistingMAEF;

            resetFirstRun({
                contractString: JSON.stringify(this.io_State.contract),
            })
            .then(result => {
                this.io_State.contract.SDS_Helper_FirstRun__c = result;
            })
            .catch(p_Error => {
                //Sonarqube -> do nothing
            });

            if (!this.isExistingMAEF){
                this.setStepStages();
            }

            this.isFirstLoad = this.io_State.contract.SDS_Helper_FirstRun__c;

            //MYPM-1130
            if(this.isFirstLoad) {
                this.io_State.showModal = true;
            }

            //MYPM-1129
            this.isFormataenderung = this.io_State.contract.Formataenderung__c;

            for (let i = 0; i < this.io_State.screens.length; i++) {

                this.io_State.screens[i].showFirstWarning = this.io_State.object.Zeige_Hinweis_Gewerbeschein__c;
                this.io_State.screens[i].showSecondWarning = this.io_State.object.Zeige_Hinweis_Polizeiliches_Fuhrungszeug__c;

                if(this.isFormataenderung) {
                    this.io_State.screens[i].showFirstWarning = false;
                    this.io_State.screens[i].showSecondWarning = false;
                }

                for (let j = 0; j < this.io_State.screens[i].buttons.length; j++) {

                    let lo_Button = this.io_State.screens[i].buttons[j];
                    lo_Button.isDisabled = false;
                    lo_Button.screenPosition = i;
                    lo_Button.position = j;

                    lo_Button.fieldMappingMap = new Map();

                    if (!lo_Button.iv_isPreview) {
                        let lv_AllFieldsValid = true;

                        let fieldMappings = lo_Button.pflichtfelder;

                        for (let k = 0; k < fieldMappings.length; k++) {
                            let lo_FieldMapping = fieldMappings[k];
                            let lv_ObjectName = lo_FieldMapping.Feld__r.Objektname__c;
                            let lv_FieldName = lo_FieldMapping.Feld__r.Feldname__c;
                            let lv_Erforderlich = true;
                            let lv_Ausblenden = lo_FieldMapping.Feld__r.Ausblenden__c;
                            let lv_Feldtyp = lo_FieldMapping.Feld__r.Feldtyp__c;
                            let lv_IstFormelfeld = lo_FieldMapping.Feld__r.ist_Formelfeld__c;
                            let lv_FieldValue = lv_ObjectName !== 'Contract' ? this.io_State.object[lv_FieldName] : this.io_State.contract[lv_FieldName];
                            lo_FieldMapping.isValid = false;

                            if (lv_FieldValue
                                || lv_FieldValue === 0
                                || lv_FieldValue === '0'
                                || !lv_Erforderlich
                                || lv_Ausblenden
                                || lv_Feldtyp === 'checkbox'
                                || lv_IstFormelfeld) {

                                lo_FieldMapping.isValid = true;

                            }
                            if (!lo_Button.fieldMappingMap.has(lv_ObjectName + lv_FieldName)) {
                                lo_Button.fieldMappingMap.set(lv_ObjectName + lv_FieldName, lo_FieldMapping);
                            }
                        }
                    }
                }

                for (let j = 0; j < this.io_State.screens[i].sections.length; j++) {
                    let section = this.io_State.screens[i].sections[j];
                    this.setActiveSections(i, j);
                    this.setFieldClassifications(i, j);
                    section.hide = false;
                    if (section.iv_HasOeffnungszeiten) {
                        for (let k = 0; k < this.io_State.screens[i].sections[j].il_Oeffnungszeits.length; k++) {
                            let oeffnungszeit = this.io_State.screens[i].sections[j].il_Oeffnungszeits[k];
                            oeffnungszeit.hide = false;
                            if (!this.io_State.isPostfachanlagePresent && section.iv_Title === 'Veränderungsmeldung zu Postfachanlagen (PfA)') {
                                oeffnungszeit.hide = true;
                            }
                        }
                    }
                }
            }
            this.setFieldVisibility();
            this.setSentDocuments();
            for (let i = 0; i < this.io_State.screens.length; i++) {

                for (let j = 0; j < this.io_State.screens[i].buttons.length; j++) {

                    let lo_Button = this.io_State.screens[i].buttons[j];

                    lo_Button.showSpinner = false;
                    lo_Button.isHidden = false;
                    lo_Button.isDocumentSent = false;
                    if (!this.io_State.isFiliale95 && lo_Button.iv_VisualforceName === 'HW_Postbankanfrage') {
                        lo_Button.isHidden = true;
                    }
                    if ( this.io_State.isFiliale84  && lo_Button.iv_VisualforceName === 'HW_Zuverlaessigkeitspruefung') {
                        lo_Button.isHidden = true;
                    }
                    if (!lo_Button.iv_isPreview && this.io_State.sentDocuments.has(lo_Button.iv_VisualforceName)) {
                        lo_Button.isDisabled = true;
                        lo_Button.allRequiredDocumentsSent = true;
                        lo_Button.lv_AllFieldsValid = true;
                        lo_Button.isDocumentSent = true;
                    }
                    else if (!lo_Button.iv_isPreview) {
                        lo_Button.lv_AllFieldsValid = true;
                        for (let [key, lo_FieldMapping] of lo_Button.fieldMappingMap) {
                            if (!lo_FieldMapping.isValid) {
                                lo_Button.lv_AllFieldsValid = false;
                            }
                        }
                        lo_Button.allRequiredDocumentsSent = true;
                        for (let k = 0; k < lo_Button.pflichtdokumente.length; k++) {
                            let pflichtdokument = lo_Button.pflichtdokumente[k];
                            if (!this.io_State.sentDocuments.has(pflichtdokument.Pflichtdokument__r.Visualforce_Page__c)){
                                lo_Button.allRequiredDocumentsSent = false;
                            }
                        }
                        lo_Button.isDisabled = ! lo_Button.lv_AllFieldsValid || ! lo_Button.allRequiredDocumentsSent;
                    }
                }

                this.setSectionVisibility(i);
            }
            this.io_ApplicationState = new HwApplicationState(this, reduce, {historicizeState: false});
            this.io_Dispatcher = new HwApplicationStateActionDispatcher(this);
            this.iv_ShowComponent = true;
            this.io_State.showSpinner = false;
        }


        Logger.endBlock()();
    }

    setSentDocuments(){
        if (this.io_State.object["Postbankanfrage_versendet__c"]){
            this.io_State.sentDocuments.add('HW_Postbankanfrage');
        }
        if (this.io_State.object["Selbstauskunft_versendet__c"]){
            this.io_State.sentDocuments.add('HW_Selbstauskunft');
        }
        if (this.io_State.object["Debitoranfrage_versendet__c"]){
            this.io_State.sentDocuments.add('HW_SAP_Debitoren_beantragen');
        }
        if (this.io_State.contract["Vertragsdokument_versendet__c"]){
            this.io_State.sentDocuments.add('HW_Vertragsdokument');
        }
        if (this.io_State.contract["MAEF_versendet__c"]){
            this.io_State.sentDocuments.add('HW_MAEF');
        }
        if (this.io_State.contract["Kontraktpflege_versendet__c"]){
            this.io_State.sentDocuments.add('HW_SAP_Neuanlage');
        }
        if (this.io_State.contract["FACTS_versendet__c"]){
            this.io_State.sentDocuments.add('HW_FACTS_Stammdatenbeleg');
            this.io_State.isFactsSent = true;
        }
    }

    setSectionVisibility( screenIndex ){
        let screen = this.io_State.screens[screenIndex];
        for (let i = 0; i < screen.sections.length; i++) {
            let section = screen.sections[i];
            section.hide = true;
            for (let j = 0; j < section.il_Fields.length; j++) {
                let field = section.il_Fields[j];

                if( !field.hide && !field.Ausblenden){
                    section.hide = false;
                    break;
                }
            }
        }
    }

    setStepStages() {
        Logger.startBlock("hwStammdatensammler.setStepStages")();

        for (let i = 0; i < this.io_State.steps.length; i++) {
            let lo_Step = this.io_State.steps[i];
            lo_Step.isDone = false;
            lo_Step.isActive = false;
            lo_Step.isOpen = false;
            lo_Step.isSkipped = false;
            lo_Step.isDoneAndActive = false;
            this.io_State.screens[i].isDone = false;
            this.io_State.screens[i].isLocked = false;

            switch (lo_Step.iv_Status) {
                case "open":
                    lo_Step.isOpen = true;
                    break;
                case "active":
                    lo_Step.isActive = true;
                    break;
                case "incomplete":
                    lo_Step.isSkipped = true;
                    break;
                case "done":
                    lo_Step.isDone = true;
                    break;
                case "doneAndActive":
                    lo_Step.isDoneAndActive = true;
                    break;
                default:
                    lo_Step.isOpen = true;
                    break;
            }

            if (lo_Step.iv_Status === 'active' || lo_Step.iv_Status === 'doneAndActive') {
                this.io_State.currentStep = lo_Step;
                this.io_State.screens[i].isActive = true;
            }
            if (lo_Step.iv_Status === 'done' || lo_Step.iv_Status === 'doneAndActive') {
                this.io_State.screens[i].isDone = true;
            }
            if (lo_Step.iv_IsLocked) {
                this.io_State.screens[i].isLocked = true;
            }
            this.io_State.screens[i].position = i;
        }

        Logger.endBlock()();
    }

    setActiveSections(pv_ScreenIndex, pv_SectionIndex) {
        Logger.startBlock("hwStammdatensammler.setActiveSections")();

        if (pv_SectionIndex === 0) {
            this.io_State.screens[pv_ScreenIndex].activeSections.push(this.io_State.screens[pv_ScreenIndex].sections[pv_SectionIndex].iv_Title);
        }

        Logger.endBlock()();
    }

    setFieldClassifications(pv_ScreenIndex, pv_SectionIndex) {
        Logger.startBlock("hwStammdatensammler.setFieldClassifications")();

        if (this.io_State.screens[pv_ScreenIndex].sections[pv_SectionIndex].il_Fields) {
            this.io_State.screens[pv_ScreenIndex].sections[pv_SectionIndex].recordsExist = true;

            for (let k = 0; k < this.io_State.screens[pv_ScreenIndex].sections[pv_SectionIndex].il_Fields.length; k++) {

                let fieldName = this.io_State.screens[pv_ScreenIndex].sections[pv_SectionIndex].il_Fields[k].Feldname;
                let field = this.io_State.screens[pv_ScreenIndex].sections[pv_SectionIndex].il_Fields[k];
                field.screenPosition = pv_ScreenIndex;
                field.sectionPosition = pv_SectionIndex;
                field.position = k;
                field.value = field.Objektname !== 'Contract' ? this.io_State.object[fieldName] : this.io_State.contract[fieldName];
                field.valueOld = field.Objektname !== 'Contract' ? this.io_State.object[fieldName] : this.io_State.contract[fieldName];
                field.Id = field.Objektname !== 'Contract' ? this.io_State.object['Id'] : this.io_State.contract['Id'];
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
                    if (this.io_State.contract[fieldName] === '95') {
                        this.io_State.isFiliale95 = true;
                    }
                    if (this.io_State.contract[fieldName] === '79') {
                        this.io_State.isFiliale79 = true;
                    }
                    if (this.io_State.contract[fieldName] === '84') {
                        this.io_State.isFiliale84 = true;
                    }
                }
                if (fieldName === 'Filialstandort_abw_Rechnungsempfaenger__c') {
                    if (this.io_State.object[fieldName] === 'ja, EKP-Nr. siehe nachfolgende Zeile') {
                        this.io_State.isDifferent_RE_EKP_known = true;
                    }
                    if (this.io_State.object[fieldName] === 'ja, EKP-Nr. anlegen, siehe Debitor II') {
                        this.io_State.isDifferent_RE_EKP_unknown = true;
                    }
                }
                if (fieldName === 'Filialstandort_abw_Zahlungsregulierer__c') {
                    if (this.io_State.object[fieldName] === 'ja, EKP-Nr. siehe nachfolgende Zeile') {
                        this.io_State.isDifferent_ZR_EKP_known = true;
                    }
                    if (this.io_State.object[fieldName] === 'ja, EKP-Nr. anlegen, siehe Debitor III') {
                        this.io_State.isDifferent_ZR_EKP_unknown = true;
                    }
                }
                if (fieldName === 'PostfachanlageVorhanden__c') {
                    this.io_State.isPostfachanlagePresent = this.io_State.contract[fieldName];
                }
                if (fieldName === 'AenderungAnKassenErforderlich__c') {
                    this.io_State.isKasseChangeRequired = this.io_State.contract[fieldName];
                }
                if (fieldName === 'VorgaengerfilialeVorhanden__c') {
                    this.io_State.isVorgaengerfilialePresent = this.io_State.contract[fieldName];
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

                    this.io_State.conditionallyRenderedFields.push(field);
                }
                if (field.isFormula && field.Objektname !== 'Contract') {

                    this.io_State.formulaFieldsSObject.push(field);
                    this.io_State.formulaFieldNamesSObject.push(String(field.Feldname));
                } else if (field.isFormula) {
                    this.io_State.formulaFieldsContract.push(field);
                    this.io_State.formulaFieldNamesContract.push(String(field.Feldname));
                }
                field.hide = false;
            }
        } else {
            this.io_State.screens[pv_ScreenIndex].sections[pv_SectionIndex].recordsExist = false;
        }

        Logger.endBlock()();
    }

    setFieldVisibility() {
        Logger.startBlock("hwStammdatensammler.setFieldVisibility")();

        for (let i = 0; i < this.io_State.conditionallyRenderedFields.length; i++) {

            let fieldMarker = this.io_State.conditionallyRenderedFields[i];

            let field = this.io_State.screens[fieldMarker.screenPosition].sections[fieldMarker.sectionPosition].il_Fields[fieldMarker.position];

            if(!this.io_State.contract.Formataenderung__c) {
                if (this.io_State.isFiliale84 && !field.OZ_84) {
                    field.hide = true;
                }
                if (this.io_State.isFiliale79 && !field.OZ_79) {
                    field.hide = true;
                }
                if (this.io_State.isFiliale95 && !field.OZ_95) {
                    field.hide = true;
                }
                if (!this.io_State.isDifferent_RE_EKP_known && field.Abweichender_RE_und_EKP_bekannt) {
                    field.hide = true;
                }
                if (!this.io_State.isDifferent_RE_EKP_unknown && field.Abweichender_RE_und_EKP_unbekannt) {
                    field.hide = true;
                }
                if (!this.io_State.isDifferent_ZR_EKP_known && field.Abweichender_ZR_und_EKP_bekannt) {
                    field.hide = true;
                }
                if (!this.io_State.isDifferent_ZR_EKP_unknown && field.Abweichender_ZR_und_EKP_unbekannt) {
                    field.hide = true;
                }
                if (!this.io_State.isPostfachanlagePresent && field.Postfachanlage_vorhanden) {
                    field.hide = true;
                }
                if (!this.io_State.isKasseChangeRequired && field.Aenderung_an_Kasse_erforderlich) {
                    field.hide = true;
                }
                if (!this.io_State.isVorgaengerfilialePresent && field.VorgaengerfilialeVorhanden) {
                    field.hide = true;
                }
            }

            for (let i = 0; i < this.io_State.screens[fieldMarker.screenPosition].buttons.length; i++) {

                let lo_Button = this.io_State.screens[fieldMarker.screenPosition].buttons[i];
                if (lo_Button.fieldMappingMap.has(field.Objektname + field.Feldname) && !lo_Button.iv_isPreview) {
                    let lo_FieldMapping = lo_Button.fieldMappingMap.get(field.Objektname + field.Feldname);
                    if (field.hide || !field.Erforderlich || field.isCheckbox || field.isFormula) {
                        lo_FieldMapping.isValid = true;
                    }
                }
            }
            if (fieldMarker.screenPosition === 3){
                for (let i = 0; i < this.io_State.screens[fieldMarker.screenPosition + 1].buttons.length; i++) {

                    let button = this.io_State.screens[fieldMarker.screenPosition + 1].buttons[i];
                    if (button.fieldMappingMap.has(field.Objektname + field.Feldname) && !button.iv_isPreview) {
                        let lo_FieldMapping = button.fieldMappingMap.get(field.Objektname + field.Feldname);
                        if (field.hide || !field.Erforderlich || field.isCheckbox || field.isFormula) {
                            lo_FieldMapping.isValid = true;
                        }
                    }
                }
            }
        }

        Logger.endBlock()();
    }

    openModal() {
        Logger.startBlock("hwStammdatensammler.openModal")();

        this.io_State.showModal = true;

        Logger.endBlock()();
    }

    @api
    closeModal() {
        Logger.startBlock("hwStammdatensammler.closeModal")();
        this.dispatchEvent(
            new CustomEvent('closeModal')
        );
        this.dispatchEvent(
            new CustomEvent('refreshView')
        );
        this.io_State.showModal = false;
        Logger.endBlock()();
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
        Logger.startBlock("hwStammdatensammler.setCurrentStep")();

        const stepIndex = event.detail.index;
        if (stepIndex !== undefined){

            this.io_Dispatcher.dispatch(
                ActionCreator.setSteps(
                    stepIndex
                )
            );
        }

        Logger.endBlock()();
    }

    get isWrongRecordType(){
        let recordType = this.io_State.object ? this.io_State.object.RecordType.DeveloperName : '';
        return recordType === 'Filiale_Dummy' || recordType === 'Filialpartner' || recordType === 'OrgE_Dummy';
    }
}