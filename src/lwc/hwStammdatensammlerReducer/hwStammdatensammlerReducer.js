/**
 *@author       Mats Böhler
 *@created      02.04.2019
 *@version      1.0
 *@since        45.0
 *
 *
 *@description  hwStammdatensammlerReducer
 *
 *
 *@changelog    02.04.2019 Mats Böhler - Created
 *
 *
 */
//Custom Javascript
import * as Logger from "c/hwLogger";
import {showSpinner, hideSpinner} from "c/hwSpinnerController";
import HwApexRequest from "c/hwApexRequest";
import hwRequestEvaluator from "c/hwRequestEvaluator";

//Custom Apex
import saveSteps from '@salesforce/apex/HW_Stammdatensammler_LC.saveSteps';
import saveSObject from '@salesforce/apex/HW_Stammdatensammler_LC.saveSObject';
import saveOeffnungszeiten from '@salesforce/apex/HW_Stammdatensammler_LC.saveOeffnungszeiten';
import getMAEFUrl from '@salesforce/apex/HW_Stammdatensammler_LC.getMAEFUrl';

const reduce = (po_State, po_Action, po_Caller) => {
    switch (po_Action.type) {
        case "setFieldValue":
            reduceSetFieldValue(po_Action, po_State, po_Caller);
            break;
        case "setCurrentStep":
            reduceSetCurrentStep(po_State, po_Action);
            break;
        case "setSteps":
            reduceSetSteps(po_State, po_Action, po_Caller);
            break;
        case "setWarningFalse":
            reduceSetWarningFalse(po_State, po_Action, po_Caller);
            break;
        case "setStepDone":
            reduceSetStepDone(po_State, po_Action, po_Caller);
            break;
        case "setButtonDisable":
            reduceSetButtonDisable(po_Action, po_State, po_Caller);
            break;
        case "setOeffnungszeiten":
            reduceSetOeffnungszeiten(po_State, po_Action, po_Caller);
            break;
        case "setMaefUrl":
            reduceSetMaefUrl(po_State, po_Caller, po_Action);
            break;
        case "setActiveSectionsEmpty":
            reduceSetActiveSectionsEmpty(po_Action.screenIndex, po_Caller, po_State, po_Action);
            break;
        case "setActiveSectionsAll":
            reduceSetActiveSectionsAll(po_Action.screenIndex, po_Caller, po_State, po_Action);
            break;
        default:
    }
};

function reduceSetActiveSectionsEmpty( pv_ScreenIndex, po_Caller, po_State, po_Action ) {
    po_State.screens.find(x => x.key === pv_ScreenIndex).activeSections = [];
}

function reduceSetActiveSectionsAll( pv_ScreenIndex, po_Caller, po_State, po_Action ) {

    let allSections = po_State.screens.find(x => x.key === pv_ScreenIndex).sections;
    let activeSections = [];

    for (let i = 0; i < allSections.length; i++) {
        activeSections.push(allSections[i].iv_Title);
    }
    po_State.screens.find(x => x.key === pv_ScreenIndex).activeSections = activeSections;
}

function reduceSetCurrentStep(po_State, po_Action) {
    po_State.currentStep = po_Action.value;
}

function reduceSetFieldValue(po_Action, po_State, po_Caller) {
    let lo_SObject;
    if (po_Action.field.Objektname === 'Contract') {
        po_State.contract[po_Action.field.Feldname] = po_Action.value;
        if (po_Action.field.isCheckbox) {
            po_State.contract[po_Action.field.Feldname] = po_Action.value === 'true'
                || po_Action.value === true;
        }
        lo_SObject = po_State.contract;
    } else {
        po_State.object[po_Action.field.Feldname] = po_Action.value;
        if (po_Action.field.isCheckbox) {
            po_State.object[po_Action.field.Feldname] = po_Action.value === 'true'
                || po_Action.value === true;
        }
        lo_SObject = po_State.object;
    }
    if (po_Action.field.Feldname === 'Filialtyp__c') {
        po_State.isFiliale95 = false;
        po_State.isFiliale79 = false;
        po_State.isFiliale84 = false;

        if (po_State.contract[po_Action.field.Feldname] === '95') {
            po_State.isFiliale95 = true;
        }
        if (po_State.contract[po_Action.field.Feldname] === '79') {
            po_State.isFiliale79 = true;
        }
        if (po_State.contract[po_Action.field.Feldname] === '84') {
            po_State.isFiliale84 = true;
        }
        checkFieldVisibility(po_State);
        checkButtonVisibility(po_State);
    }
    if (po_Action.field.Feldname === 'Filialstandort_abw_Rechnungsempfaenger__c') {
        po_State.isDifferent_RE_EKP_known = false;
        po_State.isDifferent_RE_EKP_unknown = false;

        if (po_State.object[po_Action.field.Feldname] === 'ja, EKP-Nr. siehe nachfolgende Zeile') {
            po_State.isDifferent_RE_EKP_known = true;
        }
        if (po_State.object[po_Action.field.Feldname] === 'ja, EKP-Nr. anlegen, siehe Debitor II') {
            po_State.isDifferent_RE_EKP_unknown = true;
        }
        checkFieldVisibility(po_State);
    }
    if (po_Action.field.Feldname === 'Filialstandort_abw_Zahlungsregulierer__c') {
        po_State.isDifferent_ZR_EKP_known = false;
        po_State.isDifferent_ZR_EKP_unknown = false;

        if (po_State.object[po_Action.field.Feldname] === 'ja, EKP-Nr. siehe nachfolgende Zeile') {
            po_State.isDifferent_ZR_EKP_known = true;
        }
        if (po_State.object[po_Action.field.Feldname] === 'ja, EKP-Nr. anlegen, siehe Debitor III') {
            po_State.isDifferent_ZR_EKP_unknown = true;
        }
        checkFieldVisibility(po_State);
    }
    if (po_Action.field.Feldname === 'PostfachanlageVorhanden__c') {
        po_State.isPostfachanlagePresent = po_State.contract[po_Action.field.Feldname];
        checkFieldVisibility(po_State);
        checkOeffnungszeitVisibility(po_State);
    }
    if (po_Action.field.Feldname === 'AenderungAnKassenErforderlich__c') {
        po_State.isKasseChangeRequired = po_State.contract[po_Action.field.Feldname];
        checkFieldVisibility(po_State);
    }
    if (po_Action.field.Feldname === 'VorgaengerfilialeVorhanden__c') {
        po_State.isVorgaengerfilialePresent = po_State.contract[po_Action.field.Feldname];
        checkFieldVisibility(po_State);
    }
    if (po_Action.field.Feldname === 'Anzahl_Schalter_ZORA_Geraete__c'){
        lo_SObject.AnzahlSchalter__c = po_Action.value;
    }
    setFieldValues(po_State, po_Action);
    saveObject(lo_SObject, po_Caller, po_State, po_Action);
    setButtonVisibility(po_State, po_Action.field, true);
    setSectionVisibility(po_State, po_Action.field);
}

function reduceSetStepDone(po_State, po_Action, po_Caller) {
    po_State.steps[po_Action.index] = {
        ...po_State.steps[po_Action.index],
        isDone: false,
        isActive: false,
        isOpen: false,
        isSkipped: false,
        isDoneAndActive: true,
        iv_Status: 'doneAndActive'
    };
    po_State.screens[po_Action.index] = {
        ...po_State.screens[po_Action.index],
        isDone: true
    };

    for (let i = 0; i < po_State.steps.length; i++) {
        let lo_Step = po_State.steps[i];
        if (lo_Step.isDoneAndActive && i !== po_Action.index) {
            lo_Step.isDoneAndActive = false;
            lo_Step.isActive = true;
            lo_Step.iv_Status = 'doneAndActive';
        }
    }

    handleSaveSteps(po_State, po_Caller);
}

function reduceSetButtonDisable(po_Action, po_State, po_Caller) {
    let lo_Button = po_Action.button;
    po_State.sentDocuments.add(lo_Button.iv_VisualforceName);
    po_State.screens[lo_Button.screenPosition].buttons[lo_Button.position] = {
        ...po_State.screens[lo_Button.screenPosition].buttons[lo_Button.position],
        isDisabled: true,
        allRequiredDocumentsSent: true,
        lv_AllFieldsValid: true,
        isDocumentSent: true
    };
    po_State.screens[lo_Button.screenPosition] = {
        ...po_State.screens[lo_Button.screenPosition]
    };

    let lv_AllButtonsDisabled = true;
    let lv_AllDocumentsSent = true;
    for (let i = 0; i < po_State.screens[lo_Button.screenPosition].buttons.length; i++) {
        let lo_ScreenButton = po_State.screens[lo_Button.screenPosition].buttons[i];
        if (!lo_ScreenButton.iv_isPreview) {
            if (lo_ScreenButton.isHidden) {
                continue;
            }
            if (!lo_ScreenButton.isDisabled) {
                lv_AllButtonsDisabled = false;
            }
            if (!lo_ScreenButton.isDocumentSent) {
                lv_AllDocumentsSent = false;
            }
        }
    }
    for (let i = 0; i < po_State.screens.length; i++) {
        for (let j = 0; j < po_State.screens[i].buttons.length; j++) {
            let button = po_State.screens[i].buttons[j];
            if (!button.iv_isPreview
                && lo_Button.iv_VisualforceName !== button.iv_VisualforceName){
                button.allRequiredDocumentsSent = true;
                for (let k = 0; k < button.pflichtdokumente.length; k++) {
                    let pflichtdokument = button.pflichtdokumente[k];
                    if (!po_State.sentDocuments.has(pflichtdokument.Pflichtdokument__r.Visualforce_Page__c)){
                        button.allRequiredDocumentsSent = false;
                    }
                }
                button.isDisabled = ! button.lv_AllFieldsValid || ! button.allRequiredDocumentsSent;
            }
        }
    }


    if (lv_AllDocumentsSent) {
        po_State.screens[lo_Button.screenPosition] = {
            ...po_State.screens[lo_Button.screenPosition],
            isLocked: true
        };
        po_State.steps[lo_Button.screenPosition] = {
            ...po_State.steps[lo_Button.screenPosition],
            isDone: false,
            isActive: false,
            isOpen: false,
            isSkipped: false,
            isDoneAndActive: true,
            iv_Status: 'doneAndActive',
            iv_IsLocked: true
        };
        po_State.screens[lo_Button.screenPosition] = {
            ...po_State.screens[lo_Button.screenPosition],
            isDone: true
        };

        for (let i = 0; i < po_State.steps.length; i++) {
            let lo_Step = po_State.steps[i];
            if (lo_Step.isDoneAndActive && i !== lo_Button.screenPosition) {
                lo_Step.isDoneAndActive = false;
                lo_Step.isActive = true;
                lo_Step.iv_Status = 'doneAndActive';
            }
        }

        handleSaveSteps(po_State, po_Caller);
    }

    let sObject;
    let account;

    switch (lo_Button.iv_VisualforceName) {
        case "HW_Postbankanfrage":
            po_State.object["Postbankanfrage_versendet__c"] = true;
            sObject = po_State.object;
            break;
        case "HW_Selbstauskunft":
            po_State.object["Selbstauskunft_versendet__c"] = true;
            sObject = po_State.object;
            break;
        case "HW_SAP_Debitoren_beantragen":
            po_State.object["Debitoranfrage_versendet__c"] = true;
            sObject = po_State.object;
            break;
        case "HW_Vertragsdokument":
            po_State.contract["Vertragsdokument_versendet__c"] = true;
            sObject = po_State.contract;
            break;
        case "HW_MAEF":
            po_State.contract["MAEF_versendet__c"] = true;
            sObject = po_State.contract;
            break;
        case "HW_SAP_Neuanlage":
            po_State.contract["Kontraktpflege_versendet__c"] = true;
            sObject = po_State.contract;
            break;
        case "HW_FACTS_Stammdatenbeleg":
            po_State.contract["FACTS_versendet__c"] = true;
            sObject = po_State.contract;
            po_State.isFactsSent = true;
            break;
        default:
            break;
    }
    saveObject(sObject, po_Caller, po_State, po_Action);
}

function reduceSetOeffnungszeiten(po_State, po_Action, po_Caller) {
    let lo_Oeffnungszeit = po_State.screens[po_Action.screenIndex].sections[po_Action.sectionIndex].il_Oeffnungszeits[po_Action.categoryIndex].pl_Oeffnungszeitens[po_Action.weekdayIndex];
    lo_Oeffnungszeit[po_Action.fieldName] = po_Action.value;
    lo_Oeffnungszeit.manuallyEdited = true;

    let lm_OeffnungszeitenToSave = new Map();
    if (!lm_OeffnungszeitenToSave.has(lo_Oeffnungszeit.Id)) {
        lm_OeffnungszeitenToSave.set(lo_Oeffnungszeit.Id, lo_Oeffnungszeit);
    }

    let lv_FieldName = po_Action.fieldName;

    if (lo_Oeffnungszeit.Wochentag__c === 'Montag'
        && lo_Oeffnungszeit.Kategorie__c === 'Filialöffnungszeiten') {
        for (let i = 0; i < po_State.screens.length; i++) {
            for (let j = 0; j < po_State.screens[i].sections.length; j++) {
                let lo_Section = po_State.screens[i].sections[j];

                if (lo_Section.iv_HasOeffnungszeiten) {
                    for (let k = 0; k < lo_Section.il_Oeffnungszeits.length; k++) {

                        for (let l = 0; l < lo_Section.il_Oeffnungszeits[k].pl_Oeffnungszeitens.length; l++) {
                            let lo_OeffnungszeitWochentag = lo_Section.il_Oeffnungszeits[k].pl_Oeffnungszeitens[l];

                            if (lv_FieldName === 'vm_von__c' || lv_FieldName === 'vm_bis__c') {
                                if (lo_OeffnungszeitWochentag.Wochentag__c !== 'Sonntag' && !lo_OeffnungszeitWochentag.manuallyEdited) {
                                    lo_OeffnungszeitWochentag[lv_FieldName] = po_Action.value;

                                    po_State.screens[i].sections[j].il_Oeffnungszeits[k].pl_Oeffnungszeitens[l] = {
                                        ...po_State.screens[i].sections[j].il_Oeffnungszeits[k].pl_Oeffnungszeitens[l],
                                        [lv_FieldName]: po_Action.value
                                    };
                                    if (!lm_OeffnungszeitenToSave.has(lo_OeffnungszeitWochentag.Id)) {
                                        lm_OeffnungszeitenToSave.set(lo_OeffnungszeitWochentag.Id, lo_OeffnungszeitWochentag);
                                    }
                                }
                            }
                            if (lv_FieldName === 'nm_von__c' || lv_FieldName === 'nm_bis__c') {
                                if (lo_OeffnungszeitWochentag.Wochentag__c !== 'Sonntag'
                                    && lo_OeffnungszeitWochentag.Wochentag__c !== 'Samstag'
                                    && !lo_OeffnungszeitWochentag.manuallyEdited) {
                                    lo_OeffnungszeitWochentag[lv_FieldName] = po_Action.value;

                                    po_State.screens[i].sections[j].il_Oeffnungszeits[k].pl_Oeffnungszeitens[l] = {
                                        ...po_State.screens[i].sections[j].il_Oeffnungszeits[k].pl_Oeffnungszeitens[l],
                                        [lv_FieldName]: po_Action.value
                                    };
                                    if (!lm_OeffnungszeitenToSave.has(lo_OeffnungszeitWochentag.Id)) {
                                        lm_OeffnungszeitenToSave.set(lo_OeffnungszeitWochentag.Id, lo_OeffnungszeitWochentag);
                                    }
                                }
                            }

                        }
                        po_State.screens[i].sections[j].il_Oeffnungszeits[k] = {
                            ...po_State.screens[i].sections[j].il_Oeffnungszeits[k],

                        };
                    }
                }

            }
        }
    }
    if (lo_Oeffnungszeit.Wochentag__c !== 'Montag'
        && lo_Oeffnungszeit.Kategorie__c === 'Filialöffnungszeiten') {
        let lv_Wochentag = lo_Oeffnungszeit.Wochentag__c;
        for (let i = 0; i < po_State.screens.length; i++) {
            for (let j = 0; j < po_State.screens[i].sections.length; j++) {
                let lo_Section = po_State.screens[i].sections[j];

                if (lo_Section.iv_HasOeffnungszeiten) {
                    for (let k = 0; k < lo_Section.il_Oeffnungszeits.length; k++) {

                        for (let l = 0; l < lo_Section.il_Oeffnungszeits[k].pl_Oeffnungszeitens.length; l++) {
                            let lo_OeffnungszeitWochentag = lo_Section.il_Oeffnungszeits[k].pl_Oeffnungszeitens[l];

                            if (lo_OeffnungszeitWochentag.Wochentag__c === lv_Wochentag
                                && !lo_OeffnungszeitWochentag.manuallyEdited) {
                                lo_OeffnungszeitWochentag[lv_FieldName] = po_Action.value;

                                po_State.screens[i].sections[j].il_Oeffnungszeits[k].pl_Oeffnungszeitens[l] = {
                                    ...po_State.screens[i].sections[j].il_Oeffnungszeits[k].pl_Oeffnungszeitens[l],
                                    [lv_FieldName]: po_Action.value
                                };
                                if (!lm_OeffnungszeitenToSave.has(lo_OeffnungszeitWochentag.Id)) {
                                    lm_OeffnungszeitenToSave.set(lo_OeffnungszeitWochentag.Id, lo_OeffnungszeitWochentag);
                                }
                            }

                        }
                        po_State.screens[i].sections[j].il_Oeffnungszeits[k] = {
                            ...po_State.screens[i].sections[j].il_Oeffnungszeits[k],

                        };
                    }
                }

            }
        }
    }

    let ll_OeffnungszeitenToSave = [];
    for (let lo_Oeffnungszeit of lm_OeffnungszeitenToSave.values()) {
        ll_OeffnungszeitenToSave.push(lo_Oeffnungszeit);
    }
    handleSaveOeffnungszeiten(ll_OeffnungszeitenToSave, po_Caller, po_State, po_Action);
}

function reduceSetMaefUrl(po_State, po_Caller, po_Action) {
    po_State.showSpinner = true;

    const lo_ApexRequest = new HwApexRequest(po_Caller);
    lo_ApexRequest
        .setMethod(getMAEFUrl)
        .setMethodName("HW_Stammdatensammler_LC.getMAEFUrl")
        .setParameters({
            isPreview: po_Action.button.iv_Label !== 'MAEF Beleg versenden',
            accountString: JSON.stringify(po_State.object),
            contractString: JSON.stringify(po_State.contract)
        })
        .setConfig({
            showSpinner: false,
            showErrorMessage: true,
            showSuccessMessage: false,
            successMessage: "Success"
        })
        .execute()
        .then((url) => {
            po_State.showSpinner = false;
            po_State.screens[0] = {
                ...po_State.screens[0],

            };
            if (po_Action.button.iv_Label !== 'MAEF Beleg versenden'){
                window.open(url, '_blank');
            }
            else{
                po_Caller.closeModal();
                po_Caller.showToast('Der MAEF Beleg wurde erfolgreich versendet.');
            }
        })
        .catch((pv_ErrorMessage) => {
            Logger.logError("Error", {data: pv_ErrorMessage})();
        });
}

function reduceSetSteps(po_State, po_Action, po_Caller) {

    let lv_ActiveIndex = po_Action.value;

    let lo_ActiveStep = po_State.steps[lv_ActiveIndex];

    if (lo_ActiveStep.isDone || lo_ActiveStep.isDoneAndActive) {
        lo_ActiveStep.isDone = false;
        lo_ActiveStep.isActive = false;
        lo_ActiveStep.isOpen = false;
        lo_ActiveStep.isSkipped = false;
        lo_ActiveStep.isDoneAndActive = true;
        lo_ActiveStep.iv_Status = 'doneAndActive';
    } else {
        lo_ActiveStep.isDone = false;
        lo_ActiveStep.isActive = true;
        lo_ActiveStep.isOpen = false;
        lo_ActiveStep.isSkipped = false;
        lo_ActiveStep.isDoneAndActive = false;
        lo_ActiveStep.iv_Status = 'active';
    }

    for (let i = 0; i < po_State.steps.length; i++) {

        po_State.screens[i].isActive = false;
        let lo_Step = po_State.steps[i];
        if (i < lv_ActiveIndex) {

            if (lo_Step.isDone || lo_Step.isDoneAndActive) {
                lo_Step.isDone = true;
                lo_Step.isActive = false;
                lo_Step.isOpen = false;
                lo_Step.isSkipped = false;
                lo_Step.isDoneAndActive = false;
                lo_Step.iv_Status = 'done';
            } else {
                lo_Step.isDone = false;
                lo_Step.isActive = false;
                lo_Step.isOpen = false;
                lo_Step.isSkipped = true;
                lo_Step.isDoneAndActive = false;
                lo_Step.iv_Status = 'incomplete';
            }

        } else if (i > lv_ActiveIndex) {

            if (lo_Step.isDone || lo_Step.isDoneAndActive) {
                lo_Step.isDone = true;
                lo_Step.isActive = false;
                lo_Step.isOpen = false;
                lo_Step.isSkipped = false;
                lo_Step.isDoneAndActive = false;
                lo_Step.iv_Status = 'done';
            } else {
                lo_Step.isDone = false;
                lo_Step.isActive = false;
                lo_Step.isOpen = true;
                lo_Step.isSkipped = false;
                lo_Step.isDoneAndActive = false;
                lo_Step.iv_Status = 'open';
            }
        }

    }

    po_State.currentStep = po_State.steps[lv_ActiveIndex];

    po_State.screens[lv_ActiveIndex].isActive = true;

    for (let i = 0; i < po_State.screens.length; i++) {

        po_State.screens[i] = {
            ...po_State.screens[i],
        };
        for (let j = 0; j < po_State.screens[i].buttons.length; j++) {
            po_State.screens[i].buttons[j] = {
                ...po_State.screens[i].buttons[j],
            };
        }
    }
    handleSaveSteps(po_State, po_Caller);
}

function reduceSetWarningFalse(po_State, po_Action, po_Caller) {

    for (let i = 0; i < po_State.screens.length; i++) {

        po_State.screens[i] = {
            ...po_State.screens[i]
        };
        if (po_Action.index === 'First') {
            po_State.screens[i].showFirstWarning = false;
        } else if (po_Action.index === 'Second') {
            po_State.screens[i].showSecondWarning = false;
        }
    }
    if (po_Action.index === 'First') {
        po_State.object["Zeige_Hinweis_Gewerbeschein__c"] = false;
    } else if (po_Action.index === 'Second') {
        po_State.object["Zeige_Hinweis_Polizeiliches_Fuhrungszeug__c"] = false;
    }
    saveObject(po_State.object, po_Caller, po_State, po_Action);
}

function handleSaveSteps(po_State, po_Caller) {

    Logger.startBlock("hwStammdatensammlerReducer.handleSaveSteps")();

    const lo_ApexRequest = new HwApexRequest(po_Caller);
    lo_ApexRequest
        .setMethod(saveSteps)
        .setMethodName("HW_Stammdatensammler_LC.saveSteps")
        .setParameters({
            pv_Steps: JSON.stringify(po_State.steps)
        })
        .setConfig({
            showSpinner: false,
            showErrorMessage: true,
            showSuccessMessage: false,
            successMessage: "Success"
        })
        .execute()
        .then((pv_Data) => {

        })
        .catch((pv_ErrorMessage) => {
            Logger.logError("Error", {data: pv_ErrorMessage})();
        });

    Logger.endBlock()();
}

function setFieldValues(po_State, po_Action) {

    let lo_Field = po_Action.field;
    po_State.screens[lo_Field.screenPosition].sections[lo_Field.sectionPosition].il_Fields[lo_Field.position] = {
        ...po_State.screens[lo_Field.screenPosition].sections[lo_Field.sectionPosition].il_Fields[lo_Field.position],
        value: lo_Field.Objektname !== 'Contract' ? po_State.object[lo_Field.Feldname] : po_State.contract[lo_Field.Feldname]
    };

}

function checkFieldVisibility(po_State) {

    for (let i = 0; i < po_State.conditionallyRenderedFields.length; i++) {

        let lo_FieldMarker = po_State.conditionallyRenderedFields[i];

        po_State.screens[lo_FieldMarker.screenPosition].sections[lo_FieldMarker.sectionPosition].il_Fields[lo_FieldMarker.position] = {
            ...po_State.screens[lo_FieldMarker.screenPosition].sections[lo_FieldMarker.sectionPosition].il_Fields[lo_FieldMarker.position],
        };

        let lo_Field = po_State.screens[lo_FieldMarker.screenPosition].sections[lo_FieldMarker.sectionPosition].il_Fields[lo_FieldMarker.position];
        let originalFieldHideValue = lo_Field.hide;

        lo_Field.hide = false;

        if(!po_State.contract.Formataenderung__c) {
            if (po_State.isFiliale84 && !lo_Field.OZ_84) {
                lo_Field.hide = true;
            }
            if (po_State.isFiliale79 && !lo_Field.OZ_79) {
                lo_Field.hide = true;
            }
            if (po_State.isFiliale95 && !lo_Field.OZ_95) {
                lo_Field.hide = true;
            }
            if (!po_State.isDifferent_RE_EKP_known && lo_Field.Abweichender_RE_und_EKP_bekannt) {
                lo_Field.hide = true;
            }
            if (!po_State.isDifferent_RE_EKP_unknown && lo_Field.Abweichender_RE_und_EKP_unbekannt) {
                lo_Field.hide = true;
            }
            if (!po_State.isDifferent_ZR_EKP_known && lo_Field.Abweichender_ZR_und_EKP_bekannt) {
                lo_Field.hide = true;
            }
            if (!po_State.isDifferent_ZR_EKP_unknown && lo_Field.Abweichender_ZR_und_EKP_unbekannt) {
                lo_Field.hide = true;
            }
            if (!po_State.isPostfachanlagePresent && lo_Field.Postfachanlage_vorhanden) {
                lo_Field.hide = true;
            }
            if (!po_State.isKasseChangeRequired && lo_Field.Aenderung_an_Kasse_erforderlich) {
                lo_Field.hide = true;
            }
            if (!po_State.isVorgaengerfilialePresent && lo_Field.VorgaengerfilialeVorhanden) {
                lo_Field.hide = true;
            }
        }

        let isValid = false;
        if (lo_Field.hide) {
            isValid = true;
        } else if (!lo_Field.hide && lo_Field.value) {
            isValid = true;
        } else if (!lo_Field.Erforderlich) {
            isValid = true;
        } else if (lo_Field.isCheckbox) {
            isValid = true;
        } else if (lo_Field.isFormula) {
            isValid = true;
        }
        setButtonVisibility(po_State, lo_Field, isValid);
        if (originalFieldHideValue !== lo_Field.hide) {
            setSectionVisibility(po_State, lo_Field);
        }
    }
}

function checkOeffnungszeitVisibility(po_State) {

    for (let i = 0; i < po_State.screens.length; i++) {

        for (let j = 0; j < po_State.screens[i].sections.length; j++) {
            let section = po_State.screens[i].sections[j];
            section.hide = false;
            if (section.iv_HasOeffnungszeiten) {
                for (let k = 0; k < section.il_Oeffnungszeits.length; k++) {
                    let oeffnungszeit = section.il_Oeffnungszeits[k];
                    oeffnungszeit.hide = false;
                    if (!po_State.isPostfachanlagePresent && section.iv_Title === 'Veränderungsmeldung zu Postfachanlagen (PfA)') {
                        oeffnungszeit.hide = true;
                    }
                }
            }
        }
    }


    for (let i = 0; i < po_State.conditionallyRenderedFields.length; i++) {

        let lo_FieldMarker = po_State.conditionallyRenderedFields[i];

        po_State.screens[lo_FieldMarker.screenPosition].sections[lo_FieldMarker.sectionPosition].il_Fields[lo_FieldMarker.position] = {
            ...po_State.screens[lo_FieldMarker.screenPosition].sections[lo_FieldMarker.sectionPosition].il_Fields[lo_FieldMarker.position],
        };

        let lo_Field = po_State.screens[lo_FieldMarker.screenPosition].sections[lo_FieldMarker.sectionPosition].il_Fields[lo_FieldMarker.position];

        lo_Field.hide = false;

        if (po_State.isFiliale84 && !lo_Field.OZ_84) {
            lo_Field.hide = true;
        }
        if (po_State.isFiliale79 && !lo_Field.OZ_79) {
            lo_Field.hide = true;
        }
        if (po_State.isFiliale95 && !lo_Field.OZ_95) {
            lo_Field.hide = true;
        }
        if (!po_State.isDifferent_RE_EKP_known && lo_Field.Abweichender_RE_und_EKP_bekannt) {
            lo_Field.hide = true;
        }
        if (!po_State.isDifferent_RE_EKP_unknown && lo_Field.Abweichender_RE_und_EKP_unbekannt) {
            lo_Field.hide = true;
        }
        if (!po_State.isDifferent_ZR_EKP_known && lo_Field.Abweichender_ZR_und_EKP_bekannt) {
            lo_Field.hide = true;
        }
        if (!po_State.isDifferent_ZR_EKP_unknown && lo_Field.Abweichender_ZR_und_EKP_unbekannt) {
            lo_Field.hide = true;
        }
        if (!po_State.isPostfachanlagePresent && lo_Field.Postfachanlage_vorhanden) {
            lo_Field.hide = true;
        }
        if (!po_State.isKasseChangeRequired && lo_Field.Aenderung_an_Kasse_erforderlich) {
            lo_Field.hide = true;
        }
        if (!po_State.isVorgaengerfilialePresent && lo_Field.VorgaengerfilialeVorhanden) {
            lo_Field.hide = true;
        }

        let isValid = false;
        if (lo_Field.hide) {
            isValid = true;
        } else if (!lo_Field.hide && lo_Field.value) {
            isValid = true;
        } else if (!lo_Field.Erforderlich) {
            isValid = true;
        } else if (lo_Field.isCheckbox) {
            isValid = true;
        } else if (lo_Field.isFormula) {
            isValid = true;
        }
        setButtonVisibility(po_State, lo_Field, isValid);
    }
}

function checkButtonVisibility(po_State) {

    for (let i = 0; i < po_State.screens[0].buttons.length; i++) {

        let lo_Button = po_State.screens[0].buttons[i];

        if (po_State.isFiliale95 && lo_Button.iv_VisualforceName === 'HW_Postbankanfrage') {
            po_State.screens[0].buttons[i] = {
                ...po_State.screens[0].buttons[i],
                isHidden: false
            };
        }
        if (!po_State.isFiliale95 && lo_Button.iv_VisualforceName === 'HW_Postbankanfrage') {
            po_State.screens[0].buttons[i] = {
                ...po_State.screens[0].buttons[i],
                isHidden: true
            };
        }
    }
    if(po_State.screens.length>=4) {
        for (let i = 0; i < po_State.screens[4].buttons.length; i++) {

            let lo_Button = po_State.screens[4].buttons[i];

            if (po_State.isFiliale84 && lo_Button.iv_VisualforceName === 'HW_Zuverlaessigkeitspruefung') {
                po_State.screens[4].buttons[i] = {
                    ...po_State.screens[4].buttons[i],
                    isHidden: true
                };
            }
            if (!po_State.isFiliale84 && lo_Button.iv_VisualforceName === 'HW_Zuverlaessigkeitspruefung') {
                po_State.screens[4].buttons[i] = {
                    ...po_State.screens[4].buttons[i],
                    isHidden: false
                };
            }
        }
    }
}

function setButtonVisibility(po_State, po_Field, pv_IsValid) {
    for( let x = 0; x < po_State.screens.length; x++){
        for (let i = 0; i < po_State.screens[x].buttons.length; i++) {

            let lo_Button = po_State.screens[x].buttons[i];
            if (!lo_Button.iv_isPreview && !lo_Button.isDocumentSent) {
                if (lo_Button.fieldMappingMap.has(po_Field.Objektname + po_Field.Feldname)) {
                    let lo_FieldMapping = lo_Button.fieldMappingMap.get(po_Field.Objektname + po_Field.Feldname);
                    lo_FieldMapping.isValid = pv_IsValid;
                }

                lo_Button.lv_AllFieldsValid = true;
                for (let [key, lo_FieldMapping] of lo_Button.fieldMappingMap) {
                    if (!lo_FieldMapping.isValid) {
                        lo_Button.lv_AllFieldsValid = false;
                    }
                }
                lo_Button.isDisabled = ! lo_Button.lv_AllFieldsValid || ! lo_Button.allRequiredDocumentsSent;
                forceButtonRerender(po_State);
            }
        }
    }
}

function forceButtonRerender(po_State){
    for (let i = 0; i < po_State.screens.length; i++) {
        for (let j = 0; j < po_State.screens[i].buttons.length; j++) {
            po_State.screens[i].buttons[j] = {
                ...po_State.screens[i].buttons[j]
            };
        }
    }
}

function setSectionVisibility(po_State, po_Field) {

    let section = po_State.screens[po_Field.screenPosition].sections[po_Field.sectionPosition];
    let hideSection = true;
    for (let i = 0; i < section.il_Fields.length; i++) {

        let field = section.il_Fields[i];

        if (!field.hide && !field.Ausblenden) {
            hideSection = false;
            break;
        }
    }
    po_State.screens[po_Field.screenPosition].sections[po_Field.sectionPosition] = {
        ...po_State.screens[po_Field.screenPosition].sections[po_Field.sectionPosition],
        hide: hideSection,
    };
}

function saveObject(po_SObject, po_Caller, po_State, po_Action) {

    if (!po_State.isExistingMAEF) {

        let lo_ApexRequest = new HwApexRequest(po_Caller);
        lo_ApexRequest
            .setMethod(saveSObject)
            .setMethodName("HW_Stammdatensammler_LC.saveSObject")
            .setParameters({
                po_SObject: JSON.stringify(po_SObject),
                pl_FormulaFieldNamesSObject: po_State.formulaFieldNamesSObject,
                pl_FormulaFieldNamesContract: po_State.formulaFieldNamesContract,
                pv_AccountId: po_State.recordId
            })
            .setConfig({
                showSpinner: false,
                showErrorMessage: true,
                showSuccessMessage: false,
                successMessage: "Success"
            });

        po_State.apexRequests.unshift(lo_ApexRequest);

        if (new hwRequestEvaluator().isExecuting){
            return;
        }
        new hwRequestEvaluator().isExecuting = true;
        spinnerOnButtons(true, po_State);
        lo_ApexRequest = po_State.apexRequests[po_State.apexRequests.length - 1];
        processRequestQueue(po_SObject, po_Caller, po_State, po_Action, lo_ApexRequest);
    }
}

function spinnerOnButtons(enabled, state){
    for( let x = 0; x < state.screens.length; x++){
        for (let i = 0; i < state.screens[x].buttons.length; i++) {

            state.screens[x].buttons[i] = {
                ...state.screens[x].buttons[i],
                showSpinner: enabled
            };
        }
    }
}

function processRequestQueue(po_SObject, po_Caller, po_State, po_Action, request) {
    request
        .execute()
        .then((pv_Data) => {
            po_State.apexRequests.pop();
            if (request.getMethod() === saveSObject){
                let lo_ControllerInstance = JSON.parse(pv_Data);
                let lo_Object = lo_ControllerInstance.io_SObject;
                let lo_Contract = lo_ControllerInstance.io_Contract;

                if (lo_Object) {
                    for (let i = 0; i < po_State.formulaFieldsSObject.length; i++) {

                        let lo_FormulaFieldDefinition = po_State.formulaFieldsSObject[i];

                        po_State.screens[lo_FormulaFieldDefinition.screenPosition].sections[lo_FormulaFieldDefinition.sectionPosition].il_Fields[lo_FormulaFieldDefinition.position] = {
                            ...po_State.screens[lo_FormulaFieldDefinition.screenPosition].sections[lo_FormulaFieldDefinition.sectionPosition].il_Fields[lo_FormulaFieldDefinition.position],
                        };

                        let lo_Field = po_State.screens[lo_FormulaFieldDefinition.screenPosition].sections[lo_FormulaFieldDefinition.sectionPosition].il_Fields[lo_FormulaFieldDefinition.position];

                        lo_Field.value = lo_Object[lo_FormulaFieldDefinition.Feldname];
                    }
                }

                if (lo_Contract) {
                    for (let i = 0; i < po_State.formulaFieldsContract.length; i++) {

                        let lo_FormulaFieldDefinition = po_State.formulaFieldsContract[i];

                        po_State.screens[lo_FormulaFieldDefinition.screenPosition].sections[lo_FormulaFieldDefinition.sectionPosition].il_Fields[lo_FormulaFieldDefinition.position] = {
                            ...po_State.screens[lo_FormulaFieldDefinition.screenPosition].sections[lo_FormulaFieldDefinition.sectionPosition].il_Fields[lo_FormulaFieldDefinition.position],
                        };

                        let lo_Field = po_State.screens[lo_FormulaFieldDefinition.screenPosition].sections[lo_FormulaFieldDefinition.sectionPosition].il_Fields[lo_FormulaFieldDefinition.position];

                        lo_Field.value = lo_Contract[lo_FormulaFieldDefinition.Feldname];
                    }
                }
            }
            if (po_State.apexRequests.length > 0){
                processRequestQueue(po_SObject, po_Caller, po_State, po_Action, po_State.apexRequests[po_State.apexRequests.length - 1]);
            }
            else{
                new hwRequestEvaluator().isExecuting = false;
                spinnerOnButtons(false, po_State);
            }
            forceButtonRerender(po_State);
        })
        .catch((pv_ErrorMessage) => {
            Logger.logError("Error", {data: pv_ErrorMessage})();
        });
}

function handleSaveOeffnungszeiten(pl_Oeffnungszeiten, po_Caller, po_State, po_Action) {

    let lo_ApexRequest = new HwApexRequest(po_Caller);
    lo_ApexRequest
        .setMethod(saveOeffnungszeiten)
        .setMethodName("HW_Stammdatensammler_LC.saveOeffnungszeiten")
        .setParameters({
            po_SObjects: JSON.stringify(pl_Oeffnungszeiten)
        })
        .setConfig({
            showSpinner: false,
            showErrorMessage: true,
            showSuccessMessage: false,
            successMessage: "Success"
        });

    po_State.apexRequests.unshift(lo_ApexRequest);

    if (new hwRequestEvaluator().isExecuting){
        return;
    }
    new hwRequestEvaluator().isExecuting = true;
    spinnerOnButtons(true, po_State);
    lo_ApexRequest = po_State.apexRequests[po_State.apexRequests.length - 1];
    processRequestQueue(pl_Oeffnungszeiten, po_Caller, po_State, po_Action, lo_ApexRequest);
}

export {
    reduce
};