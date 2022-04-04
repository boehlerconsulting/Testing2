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
import HwApexRequest from "c/hwApexRequest";
import hwRequestEvaluator from "c/hwRequestEvaluator";
import saveSteps from '@salesforce/apex/HW_Stammdatensammler_LC.saveSteps';
import saveSObject from '@salesforce/apex/HW_Stammdatensammler_LC.saveSObject';
import saveOeffnungszeiten from '@salesforce/apex/HW_Stammdatensammler_LC.saveOeffnungszeiten';
import getMAEFUrl from '@salesforce/apex/HW_Stammdatensammler_LC.getMAEFUrl';

const reduce = (state, action, caller) => {
    switch (action.type) {
        case "setFieldValue":
            reduceSetFieldValue(action, state, caller);
            break;
        case "setCurrentStep":
            reduceSetCurrentStep(state, action);
            break;
        case "setSteps":
            reduceSetSteps(state, action, caller);
            break;
        case "setWarningFalse":
            reduceSetWarningFalse(state, action, caller);
            break;
        case "setStepDone":
            reduceSetStepDone(state, action, caller);
            break;
        case "setButtonDisable":
            reduceSetButtonDisable(action, state, caller);
            break;
        case "setOeffnungszeiten":
            reduceSetOeffnungszeiten(state, action, caller);
            break;
        case "setMaefUrl":
            reduceSetMaefUrl(state, caller, action);
            break;
        case "setActiveSectionsEmpty":
            reduceSetActiveSectionsEmpty(action.screenIndex, state);
            break;
        case "setActiveSectionsAll":
            reduceSetActiveSectionsAll(action.screenIndex, state);
            break;
        default:
    }
};

function reduceSetActiveSectionsEmpty(screenIndex, state) {
    state.screens.find(x => x.key === screenIndex).activeSections = [];
}

function reduceSetActiveSectionsAll(screenIndex, state) {

    let allSections = state.screens.find(x => x.key === screenIndex).sections;
    let activeSections = [];

    for (let i = 0; i < allSections.length; i++) {
        activeSections.push(allSections[i].iv_Title);
    }
    state.screens.find(x => x.key === screenIndex).activeSections = activeSections;
}

function reduceSetCurrentStep(state, action) {
    state.currentStep = action.value;
}

function reduceSetFieldValue(action, state, caller) {
    let sObject;

    if (action.field.Objektname === 'Contract') {
        state.contract[action.field.Feldname] = action.value;
        if (action.field.isCheckbox) {
            state.contract[action.field.Feldname] = action.value === 'true'
                || action.value === true;
        }
        sObject = state.contract;
    } else {
        state.object[action.field.Feldname] = action.value;
        if (action.field.isCheckbox) {
            state.object[action.field.Feldname] = action.value === 'true'
                || action.value === true;
        }
        sObject = state.object;
    }
    if (action.field.Feldname === 'Filialtyp__c') {
        state.isFiliale95 = false;
        state.isFiliale79 = false;
        state.isFiliale84 = false;

        if (state.contract[action.field.Feldname] === '95') {
            state.isFiliale95 = true;
        }
        if (state.contract[action.field.Feldname] === '79') {
            state.isFiliale79 = true;
        }
        if (state.contract[action.field.Feldname] === '84') {
            state.isFiliale84 = true;
        }
        checkFieldVisibility(state);
        checkButtonVisibility(state);
    }
    if (action.field.Feldname === 'Filialstandort_abw_Rechnungsempfaenger__c') {
        state.isDifferent_RE_EKP_known = false;
        state.isDifferent_RE_EKP_unknown = false;

        if (state.object[action.field.Feldname] === 'ja, EKP-Nr. siehe nachfolgende Zeile') {
            state.isDifferent_RE_EKP_known = true;
        }
        if (state.object[action.field.Feldname] === 'ja, EKP-Nr. anlegen, siehe Debitor II') {
            state.isDifferent_RE_EKP_unknown = true;
        }
        checkFieldVisibility(state);
    }
    if (action.field.Feldname === 'Filialstandort_abw_Zahlungsregulierer__c') {
        state.isDifferent_ZR_EKP_known = false;
        state.isDifferent_ZR_EKP_unknown = false;

        if (state.object[action.field.Feldname] === 'ja, EKP-Nr. siehe nachfolgende Zeile') {
            state.isDifferent_ZR_EKP_known = true;
        }
        if (state.object[action.field.Feldname] === 'ja, EKP-Nr. anlegen, siehe Debitor III') {
            state.isDifferent_ZR_EKP_unknown = true;
        }
        checkFieldVisibility(state);
    }
    if (action.field.Feldname === 'PostfachanlageVorhanden__c') {
        state.isPostfachanlagePresent = state.contract[action.field.Feldname];
        checkFieldVisibility(state);
        checkOeffnungszeitVisibility(state);
    }
    if (action.field.Feldname === 'AenderungAnKassenErforderlich__c') {
        state.isKasseChangeRequired = state.contract[action.field.Feldname];
        checkFieldVisibility(state);
    }
    if (action.field.Feldname === 'VorgaengerfilialeVorhanden__c') {
        state.isVorgaengerfilialePresent = state.contract[action.field.Feldname];
        checkFieldVisibility(state);
    }
    if (action.field.Feldname === 'Anzahl_Schalter_ZORA_Geraete__c') {
        sObject.AnzahlSchalter__c = action.value;
    }
    setFieldValues(state, action);
    saveObject(sObject, caller, state, action);
    setButtonVisibility(state, action.field, true);
    setSectionVisibility(state, action.field);
}

function reduceSetStepDone(state, action, caller) {
    state.steps[action.index] = {
        ...state.steps[action.index],
        isDone: false,
        isActive: false,
        isOpen: false,
        isSkipped: false,
        isDoneAndActive: true,
        iv_Status: 'doneAndActive'
    };
    state.screens[action.index] = {
        ...state.screens[action.index],
        isDone: true
    };

    for (let i = 0; i < state.steps.length; i++) {
        let step = state.steps[i];
        if (step.isDoneAndActive && i !== action.index) {
            step.isDoneAndActive = false;
            step.isActive = true;
            step.iv_Status = 'doneAndActive';
        }
    }

    handleSaveSteps(state, caller);
}

function reduceSetButtonDisable(action, state, caller) {
    let actionButton = action.button;
    state.sentDocuments.add(actionButton.iv_VisualforceName);
    state.screens[actionButton.screenPosition].buttons[actionButton.position] = {
        ...state.screens[actionButton.screenPosition].buttons[actionButton.position],
        isDisabled: true,
        allRequiredDocumentsSent: true,
        lv_AllFieldsValid: true,
        isDocumentSent: true
    };
    state.screens[actionButton.screenPosition] = {
        ...state.screens[actionButton.screenPosition]
    };
    let allDocumentsSent = true;
    for (let i = 0; i < state.screens[actionButton.screenPosition].buttons.length; i++) {
        let screenButton = state.screens[actionButton.screenPosition].buttons[i];
        if (!screenButton.iv_isPreview) {
            if (screenButton.isHidden) {
                continue;
            }
            if (!screenButton.isDocumentSent) {
                allDocumentsSent = false;
            }
        }
    }
    for (let i = 0; i < state.screens.length; i++) {
        for (let j = 0; j < state.screens[i].buttons.length; j++) {
            let button = state.screens[i].buttons[j];
            if (!button.iv_isPreview
                && actionButton.iv_VisualforceName !== button.iv_VisualforceName){
                button.allRequiredDocumentsSent = true;
                for (let k = 0; k < button.pflichtdokumente.length; k++) {
                    let pflichtdokument = button.pflichtdokumente[k];
                    if (!state.sentDocuments.has(pflichtdokument.Pflichtdokument__r.Visualforce_Page__c)){
                        button.allRequiredDocumentsSent = false;
                    }
                }
                button.isDisabled = ! button.lv_AllFieldsValid || ! button.allRequiredDocumentsSent;
            }
        }
    }
    if (allDocumentsSent) {
        state.screens[actionButton.screenPosition] = {
            ...state.screens[actionButton.screenPosition],
            isLocked: true
        };
        state.steps[actionButton.screenPosition] = {
            ...state.steps[actionButton.screenPosition],
            isDone: false,
            isActive: false,
            isOpen: false,
            isSkipped: false,
            isDoneAndActive: true,
            iv_Status: 'doneAndActive',
            iv_IsLocked: true
        };
        state.screens[actionButton.screenPosition] = {
            ...state.screens[actionButton.screenPosition],
            isDone: true
        };

        for (let i = 0; i < state.steps.length; i++) {
            let step = state.steps[i];
            if (step.isDoneAndActive && i !== actionButton.screenPosition) {
                step.isDoneAndActive = false;
                step.isActive = true;
                step.iv_Status = 'doneAndActive';
            }
        }

        handleSaveSteps(state, caller);
    }
    saveObject(setDocumentSentState(actionButton, state), caller, state, action);
}

function setDocumentSentState(button, state) {
    let sObject;
    switch (button.iv_VisualforceName) {
        case "HW_Postbankanfrage":
            state.object["Postbankanfrage_versendet__c"] = true;
            sObject = state.object;
            break;
        case "HW_Selbstauskunft":
            state.object["Selbstauskunft_versendet__c"] = true;
            sObject = state.object;
            break;
        case "HW_SAP_Debitoren_beantragen":
            state.object["Debitoranfrage_versendet__c"] = true;
            sObject = state.object;
            break;
        case "HW_Vertragsdokument":
            state.contract["Vertragsdokument_versendet__c"] = true;
            sObject = state.contract;
            break;
        case "HW_MAEF":
            state.contract["MAEF_versendet__c"] = true;
            sObject = state.contract;
            break;
        case "HW_SAP_Neuanlage":
            state.contract["Kontraktpflege_versendet__c"] = true;
            sObject = state.contract;
            break;
        case "HW_FACTS_Stammdatenbeleg":
            state.contract["FACTS_versendet__c"] = true;
            sObject = state.contract;
            state.isFactsSent = true;
            break;
        default:
            break;
    }
    return sObject;
}

function reduceSetOeffnungszeiten(state, action, caller) {
    let oeffnungszeit
        = state.screens[action.screenIndex].sections[action.sectionIndex]
        .il_Oeffnungszeits[action.categoryIndex].pl_Oeffnungszeitens[action.weekdayIndex];
    oeffnungszeit[action.fieldName] = action.value;
    oeffnungszeit.manuallyEdited = true;

    let oeffnungszeitenToSaveById = new Map();
    if (!oeffnungszeitenToSaveById.has(oeffnungszeit.Id)) {
        oeffnungszeitenToSaveById.set(oeffnungszeit.Id, oeffnungszeit);
    }

    let fieldName = action.fieldName;

    if (oeffnungszeit.Wochentag__c === 'Montag'
        && oeffnungszeit.Kategorie__c === 'Filialöffnungszeiten') {
        for (let i = 0; i < state.screens.length; i++) {
            for (let j = 0; j < state.screens[i].sections.length; j++) {
                let section = state.screens[i].sections[j];

                if (section.iv_HasOeffnungszeiten) {
                    for (let k = 0; k < section.il_Oeffnungszeits.length; k++) {

                        for (let l = 0; l < section.il_Oeffnungszeits[k].pl_Oeffnungszeitens.length; l++) {
                            let oeffnungszeitWochentag = section.il_Oeffnungszeits[k].pl_Oeffnungszeitens[l];

                            if (fieldName === 'vm_von__c' || fieldName === 'vm_bis__c') {
                                if (oeffnungszeitWochentag.Wochentag__c !== 'Sonntag' && !oeffnungszeitWochentag.manuallyEdited) {
                                    oeffnungszeitWochentag[fieldName] = action.value;

                                    state.screens[i].sections[j].il_Oeffnungszeits[k].pl_Oeffnungszeitens[l] = {
                                        ...state.screens[i].sections[j].il_Oeffnungszeits[k].pl_Oeffnungszeitens[l],
                                        [fieldName]: action.value
                                    };
                                    if (!oeffnungszeitenToSaveById.has(oeffnungszeitWochentag.Id)) {
                                        oeffnungszeitenToSaveById.set(oeffnungszeitWochentag.Id, oeffnungszeitWochentag);
                                    }
                                }
                            }
                            if (fieldName === 'nm_von__c' || fieldName === 'nm_bis__c') {
                                if (oeffnungszeitWochentag.Wochentag__c !== 'Sonntag'
                                    && oeffnungszeitWochentag.Wochentag__c !== 'Samstag'
                                    && !oeffnungszeitWochentag.manuallyEdited) {
                                    oeffnungszeitWochentag[fieldName] = action.value;

                                    state.screens[i].sections[j].il_Oeffnungszeits[k].pl_Oeffnungszeitens[l] = {
                                        ...state.screens[i].sections[j].il_Oeffnungszeits[k].pl_Oeffnungszeitens[l],
                                        [fieldName]: action.value
                                    };
                                    if (!oeffnungszeitenToSaveById.has(oeffnungszeitWochentag.Id)) {
                                        oeffnungszeitenToSaveById.set(oeffnungszeitWochentag.Id, oeffnungszeitWochentag);
                                    }
                                }
                            }

                        }
                        state.screens[i].sections[j].il_Oeffnungszeits[k] = {
                            ...state.screens[i].sections[j].il_Oeffnungszeits[k],

                        };
                    }
                }

            }
        }
    }
    if (oeffnungszeit.Wochentag__c !== 'Montag'
        && oeffnungszeit.Kategorie__c === 'Filialöffnungszeiten') {
        let wochentag = oeffnungszeit.Wochentag__c;
        for (let i = 0; i < state.screens.length; i++) {
            for (let j = 0; j < state.screens[i].sections.length; j++) {
                let section = state.screens[i].sections[j];

                if (section.iv_HasOeffnungszeiten) {
                    for (let k = 0; k < section.il_Oeffnungszeits.length; k++) {

                        for (let l = 0; l < section.il_Oeffnungszeits[k].pl_Oeffnungszeitens.length; l++) {
                            let oeffnungszeitWochentag = section.il_Oeffnungszeits[k].pl_Oeffnungszeitens[l];

                            if (oeffnungszeitWochentag.Wochentag__c === wochentag
                                && !oeffnungszeitWochentag.manuallyEdited) {
                                oeffnungszeitWochentag[fieldName] = action.value;

                                state.screens[i].sections[j].il_Oeffnungszeits[k].pl_Oeffnungszeitens[l] = {
                                    ...state.screens[i].sections[j].il_Oeffnungszeits[k].pl_Oeffnungszeitens[l],
                                    [fieldName]: action.value
                                };
                                if (!oeffnungszeitenToSaveById.has(oeffnungszeitWochentag.Id)) {
                                    oeffnungszeitenToSaveById.set(oeffnungszeitWochentag.Id, oeffnungszeitWochentag);
                                }
                            }

                        }
                        state.screens[i].sections[j].il_Oeffnungszeits[k] = {
                            ...state.screens[i].sections[j].il_Oeffnungszeits[k],

                        };
                    }
                }

            }
        }
    }

    let oeffnungszeitenToSave = [];
    for (let oeffnungszeitValue of oeffnungszeitenToSaveById.values()) {
        oeffnungszeitenToSave.push(oeffnungszeitValue);
    }
    handleSaveOeffnungszeiten(oeffnungszeitenToSave, caller, state, action);
}

function reduceSetMaefUrl(state, caller, action) {
    state.showSpinner = true;

    const apexRequest = new HwApexRequest(caller);
    apexRequest
        .setMethod(getMAEFUrl)
        .setMethodName("HW_Stammdatensammler_LC.getMAEFUrl")
        .setParameters({
            isPreview: action.button.iv_Label !== 'MAEF Beleg versenden',
            accountString: JSON.stringify(state.object),
            contractString: JSON.stringify(state.contract)
        })
        .setConfig({
            showSpinner: false,
            showErrorMessage: true,
            showSuccessMessage: false,
            successMessage: "Success"
        })
        .execute()
        .then((url) => {
            state.showSpinner = false;
            state.screens[0] = {
                ...state.screens[0],

            };
            if (action.button.iv_Label !== 'MAEF Beleg versenden') {
                window.open(url, '_blank');
            } else {
                caller.closeModal();
                caller.showToast('Der MAEF Beleg wurde erfolgreich versendet.');
            }
        })
}

function reduceSetSteps(state, action, caller) {

    let activeIndex = action.value;

    let activeStep = state.steps[activeIndex];

    if (activeStep.isDone || activeStep.isDoneAndActive) {
        activeStep.isDone = false;
        activeStep.isActive = false;
        activeStep.isOpen = false;
        activeStep.isSkipped = false;
        activeStep.isDoneAndActive = true;
        activeStep.iv_Status = 'doneAndActive';
    } else {
        activeStep.isDone = false;
        activeStep.isActive = true;
        activeStep.isOpen = false;
        activeStep.isSkipped = false;
        activeStep.isDoneAndActive = false;
        activeStep.iv_Status = 'active';
    }

    for (let i = 0; i < state.steps.length; i++) {

        state.screens[i].isActive = false;
        let step = state.steps[i];
        if (i < activeIndex) {

            if (step.isDone || step.isDoneAndActive) {
                step.isDone = true;
                step.isActive = false;
                step.isOpen = false;
                step.isSkipped = false;
                step.isDoneAndActive = false;
                step.iv_Status = 'done';
            } else {
                step.isDone = false;
                step.isActive = false;
                step.isOpen = false;
                step.isSkipped = true;
                step.isDoneAndActive = false;
                step.iv_Status = 'incomplete';
            }

        } else if (i > activeIndex) {

            if (step.isDone || step.isDoneAndActive) {
                step.isDone = true;
                step.isActive = false;
                step.isOpen = false;
                step.isSkipped = false;
                step.isDoneAndActive = false;
                step.iv_Status = 'done';
            } else {
                step.isDone = false;
                step.isActive = false;
                step.isOpen = true;
                step.isSkipped = false;
                step.isDoneAndActive = false;
                step.iv_Status = 'open';
            }
        }

    }

    state.currentStep = state.steps[activeIndex];

    state.screens[activeIndex].isActive = true;

    for (let i = 0; i < state.screens.length; i++) {

        state.screens[i] = {
            ...state.screens[i],
        };
        for (let j = 0; j < state.screens[i].buttons.length; j++) {
            state.screens[i].buttons[j] = {
                ...state.screens[i].buttons[j],
            };
        }
    }
    handleSaveSteps(state, caller);
}

function reduceSetWarningFalse(state, action, caller) {

    for (let i = 0; i < state.screens.length; i++) {

        state.screens[i] = {
            ...state.screens[i]
        };
        if (action.index === 'First') {
            state.screens[i].showFirstWarning = false;
        } else if (action.index === 'Second') {
            state.screens[i].showSecondWarning = false;
        }
    }
    if (action.index === 'First') {
        state.object["Zeige_Hinweis_Gewerbeschein__c"] = false;
    } else if (action.index === 'Second') {
        state.object["Zeige_Hinweis_Polizeiliches_Fuhrungszeug__c"] = false;
    }
    saveObject(state.object, caller, state, action);
}

function handleSaveSteps(state, caller) {
    const apexRequest = new HwApexRequest(caller);
    apexRequest
        .setMethod(saveSteps)
        .setMethodName("HW_Stammdatensammler_LC.saveSteps")
        .setParameters({
            pv_Steps: JSON.stringify(state.steps)
        })
        .setConfig({
            showSpinner: false,
            showErrorMessage: true,
            showSuccessMessage: false,
            successMessage: "Success"
        })
        .execute()
}

function setFieldValues(state, action) {

    let field = action.field;
    state.screens[field.screenPosition].sections[field.sectionPosition].il_Fields[field.position] = {
        ...state.screens[field.screenPosition].sections[field.sectionPosition].il_Fields[field.position],
        value: field.Objektname !== 'Contract' ? state.object[field.Feldname] : state.contract[field.Feldname]
    };

}

function checkFieldVisibility(state) {

    for (let i = 0; i < state.conditionallyRenderedFields.length; i++) {

        let fieldMarker = state.conditionallyRenderedFields[i];

        state.screens[fieldMarker.screenPosition].sections[fieldMarker.sectionPosition].il_Fields[fieldMarker.position] = {
            ...state.screens[fieldMarker.screenPosition].sections[fieldMarker.sectionPosition].il_Fields[fieldMarker.position],
        };

        let field = state.screens[fieldMarker.screenPosition].sections[fieldMarker.sectionPosition].il_Fields[fieldMarker.position];
        let originalFieldHideValue = field.hide;

        field.hide = false;

        if (!state.contract.Formataenderung__c) {
            if (state.isFiliale84 && !field.OZ_84) {
                field.hide = true;
            }
            if (state.isFiliale79 && !field.OZ_79) {
                field.hide = true;
            }
            if (state.isFiliale95 && !field.OZ_95) {
                field.hide = true;
            }
            if (!state.isDifferent_RE_EKP_known && field.Abweichender_RE_und_EKP_bekannt) {
                field.hide = true;
            }
            if (!state.isDifferent_RE_EKP_unknown && field.Abweichender_RE_und_EKP_unbekannt) {
                field.hide = true;
            }
            if (!state.isDifferent_ZR_EKP_known && field.Abweichender_ZR_und_EKP_bekannt) {
                field.hide = true;
            }
            if (!state.isDifferent_ZR_EKP_unknown && field.Abweichender_ZR_und_EKP_unbekannt) {
                field.hide = true;
            }
            if (!state.isPostfachanlagePresent && field.Postfachanlage_vorhanden) {
                field.hide = true;
            }
            if (!state.isKasseChangeRequired && field.Aenderung_an_Kasse_erforderlich) {
                field.hide = true;
            }
            if (!state.isVorgaengerfilialePresent && field.VorgaengerfilialeVorhanden) {
                field.hide = true;
            }
        }
        setButtonVisibility(state, field, getFieldValidity(field));
        if (originalFieldHideValue !== field.hide) {
            setSectionVisibility(state, field);
        }
    }
}

function checkOeffnungszeitVisibility(state) {

    for (let i = 0; i < state.screens.length; i++) {

        for (let j = 0; j < state.screens[i].sections.length; j++) {
            let section = state.screens[i].sections[j];
            section.hide = false;
            if (section.iv_HasOeffnungszeiten) {
                for (let k = 0; k < section.il_Oeffnungszeits.length; k++) {
                    let oeffnungszeit = section.il_Oeffnungszeits[k];
                    oeffnungszeit.hide = !state.isPostfachanlagePresent && section.iv_Title === 'Veränderungsmeldung zu Postfachanlagen (PfA)';
                }
            }
        }
    }

    for (let i = 0; i < state.conditionallyRenderedFields.length; i++) {

        let fieldMarker = state.conditionallyRenderedFields[i];

        state.screens[fieldMarker.screenPosition].sections[fieldMarker.sectionPosition].il_Fields[fieldMarker.position] = {
            ...state.screens[fieldMarker.screenPosition].sections[fieldMarker.sectionPosition].il_Fields[fieldMarker.position],
        };

        let field = state.screens[fieldMarker.screenPosition].sections[fieldMarker.sectionPosition].il_Fields[fieldMarker.position];
        field.hide = false;
        if (state.isFiliale84 && !field.OZ_84) {
            field.hide = true;
        }
        if (state.isFiliale79 && !field.OZ_79) {
            field.hide = true;
        }
        if (state.isFiliale95 && !field.OZ_95) {
            field.hide = true;
        }
        if (!state.isDifferent_RE_EKP_known && field.Abweichender_RE_und_EKP_bekannt) {
            field.hide = true;
        }
        if (!state.isDifferent_RE_EKP_unknown && field.Abweichender_RE_und_EKP_unbekannt) {
            field.hide = true;
        }
        if (!state.isDifferent_ZR_EKP_known && field.Abweichender_ZR_und_EKP_bekannt) {
            field.hide = true;
        }
        if (!state.isDifferent_ZR_EKP_unknown && field.Abweichender_ZR_und_EKP_unbekannt) {
            field.hide = true;
        }
        if (!state.isPostfachanlagePresent && field.Postfachanlage_vorhanden) {
            field.hide = true;
        }
        if (!state.isKasseChangeRequired && field.Aenderung_an_Kasse_erforderlich) {
            field.hide = true;
        }
        if (!state.isVorgaengerfilialePresent && field.VorgaengerfilialeVorhanden) {
            field.hide = true;
        }
        setButtonVisibility(state, field, getFieldValidity(field));
    }
}

function getFieldValidity(field){
    let isValid = false;
    if (field.hide) {
        isValid = true;
    } else if (!field.hide && field.value) {
        isValid = true;
    } else if (!field.Erforderlich) {
        isValid = true;
    } else if (field.isCheckbox) {
        isValid = true;
    } else if (field.isFormula) {
        isValid = true;
    }
    return isValid;
}

function checkButtonVisibility(state) {

    for (let i = 0; i < state.screens[0].buttons.length; i++) {

        let button = state.screens[0].buttons[i];

        if (state.isFiliale95 && button.iv_VisualforceName === 'HW_Postbankanfrage') {
            state.screens[0].buttons[i] = {
                ...state.screens[0].buttons[i],
                isHidden: false
            };
        }
        if (!state.isFiliale95 && button.iv_VisualforceName === 'HW_Postbankanfrage') {
            state.screens[0].buttons[i] = {
                ...state.screens[0].buttons[i],
                isHidden: true
            };
        }
    }
    if (state.screens.length >= 4) {
        for (let i = 0; i < state.screens[4].buttons.length; i++) {

            let button = state.screens[4].buttons[i];

            if (state.isFiliale84 && button.iv_VisualforceName === 'HW_Zuverlaessigkeitspruefung') {
                state.screens[4].buttons[i] = {
                    ...state.screens[4].buttons[i],
                    isHidden: true
                };
            }
            if (!state.isFiliale84 && button.iv_VisualforceName === 'HW_Zuverlaessigkeitspruefung') {
                state.screens[4].buttons[i] = {
                    ...state.screens[4].buttons[i],
                    isHidden: false
                };
            }
        }
    }
}

function setButtonVisibility(state, field, isValid) {
    for (let x = 0; x < state.screens.length; x++) {
        for (let i = 0; i < state.screens[x].buttons.length; i++) {

            let button = state.screens[x].buttons[i];
            if (!button.iv_isPreview && !button.isDocumentSent) {
                if (button.fieldMappingMap.has(field.Objektname + field.Feldname)) {
                    let fieldMapping = button.fieldMappingMap.get(field.Objektname + field.Feldname);
                    fieldMapping.isValid = isValid;
                }

                button.lv_AllFieldsValid = true;
                for (let [key, fieldMapping] of button.fieldMappingMap) {
                    if (!fieldMapping.isValid) {
                        button.lv_AllFieldsValid = false;
                    }
                }
                button.isDisabled = !button.lv_AllFieldsValid || !button.allRequiredDocumentsSent;
                forceButtonRerender(state);
            }
        }
    }
}

function forceButtonRerender(state) {
    for (let i = 0; i < state.screens.length; i++) {
        for (let j = 0; j < state.screens[i].buttons.length; j++) {
            state.screens[i].buttons[j] = {
                ...state.screens[i].buttons[j]
            };
        }
    }
}

function setSectionVisibility(state, field) {

    let section = state.screens[field.screenPosition].sections[field.sectionPosition];
    let hideSection = true;
    for (let i = 0; i < section.il_Fields.length; i++) {

        let field = section.il_Fields[i];

        if (!field.hide && !field.Ausblenden) {
            hideSection = false;
            break;
        }
    }
    state.screens[field.screenPosition].sections[field.sectionPosition] = {
        ...state.screens[field.screenPosition].sections[field.sectionPosition],
        hide: hideSection,
    };
}

function saveObject(sObject, caller, state, action) {

    if (!state.isExistingMAEF) {

        let apexRequest = new HwApexRequest(caller);
        apexRequest
            .setMethod(saveSObject)
            .setMethodName("HW_Stammdatensammler_LC.saveSObject")
            .setParameters({
                po_SObject: JSON.stringify(sObject),
                pl_FormulaFieldNamesSObject: state.formulaFieldNamesSObject,
                pl_FormulaFieldNamesContract: state.formulaFieldNamesContract,
                pv_AccountId: state.recordId
            })
            .setConfig({
                showSpinner: false,
                showErrorMessage: true,
                showSuccessMessage: false,
                successMessage: "Success"
            });

        state.apexRequests.unshift(apexRequest);

        if (new hwRequestEvaluator().isExecuting) {
            return;
        }
        new hwRequestEvaluator().isExecuting = true;
        spinnerOnButtons(true, state);
        apexRequest = state.apexRequests[state.apexRequests.length - 1];
        processRequestQueue(sObject, caller, state, action, apexRequest);
    }
}

function spinnerOnButtons(enabled, state) {
    for (let x = 0; x < state.screens.length; x++) {
        for (let i = 0; i < state.screens[x].buttons.length; i++) {

            state.screens[x].buttons[i] = {
                ...state.screens[x].buttons[i],
                showSpinner: enabled
            };
        }
    }
}

function processRequestQueue(sObject, caller, state, action, request) {
    request
        .execute()
        .then((data) => {
            state.apexRequests.pop();
            if (request.getMethod() === saveSObject) {
                let controllerInstance = JSON.parse(data);
                let controllerObject = controllerInstance.io_SObject;
                let controllerContract = controllerInstance.io_Contract;

                if (controllerObject) {
                    for (let i = 0; i < state.formulaFieldsSObject.length; i++) {

                        let formulaFieldDefinition = state.formulaFieldsSObject[i];

                        state.screens[formulaFieldDefinition.screenPosition]
                            .sections[formulaFieldDefinition.sectionPosition].il_Fields[formulaFieldDefinition.position] = {
                            ...state.screens[formulaFieldDefinition.screenPosition]
                                .sections[formulaFieldDefinition.sectionPosition].il_Fields[formulaFieldDefinition.position],
                        };

                        let field = state.screens[formulaFieldDefinition.screenPosition]
                            .sections[formulaFieldDefinition.sectionPosition].il_Fields[formulaFieldDefinition.position];

                        field.value = controllerObject[formulaFieldDefinition.Feldname];
                    }
                }

                if (controllerContract) {
                    for (let i = 0; i < state.formulaFieldsContract.length; i++) {

                        let formulaFieldDefinition = state.formulaFieldsContract[i];

                        state.screens[formulaFieldDefinition.screenPosition]
                            .sections[formulaFieldDefinition.sectionPosition].il_Fields[formulaFieldDefinition.position] = {
                            ...state.screens[formulaFieldDefinition.screenPosition]
                                .sections[formulaFieldDefinition.sectionPosition].il_Fields[formulaFieldDefinition.position],
                        };

                        let field = state.screens[formulaFieldDefinition.screenPosition]
                            .sections[formulaFieldDefinition.sectionPosition].il_Fields[formulaFieldDefinition.position];

                        field.value = controllerContract[formulaFieldDefinition.Feldname];
                    }
                }
            }
            if (state.apexRequests.length > 0) {
                processRequestQueue(sObject, caller, state, action, state.apexRequests[state.apexRequests.length - 1]);
            } else {
                new hwRequestEvaluator().isExecuting = false;
                spinnerOnButtons(false, state);
            }
            forceButtonRerender(state);
        })
}

function handleSaveOeffnungszeiten(oeffnungszeiten, caller, state, action) {

    let apexRequest = new HwApexRequest(caller);
    apexRequest
        .setMethod(saveOeffnungszeiten)
        .setMethodName("HW_Stammdatensammler_LC.saveOeffnungszeiten")
        .setParameters({
            po_SObjects: JSON.stringify(oeffnungszeiten)
        })
        .setConfig({
            showSpinner: false,
            showErrorMessage: true,
            showSuccessMessage: false,
            successMessage: "Success"
        });

    state.apexRequests.unshift(apexRequest);

    if (new hwRequestEvaluator().isExecuting) {
        return;
    }
    new hwRequestEvaluator().isExecuting = true;
    spinnerOnButtons(true, state);
    apexRequest = state.apexRequests[state.apexRequests.length - 1];
    processRequestQueue(oeffnungszeiten, caller, state, action, apexRequest);
}

export {
    reduce
};