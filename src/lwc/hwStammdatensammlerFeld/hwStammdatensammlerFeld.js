/**
 *@author       Mats Böhler
 *@created      01.04.2019
 *@version      1.0
 *@since        45.0
 *
 *
 *@description  hwStammdatensammlerFeld
 *
 *
 *@changelog    01.04.2019 Mats Böhler  - Created
 *
 *
 */

import {LightningElement, api, track, wire} from "lwc";
import * as FieldInputValidator from "c/hwFieldInputValidator";
import HwApplicationStateActionDispatcher from "c/hwApplicationStateActionDispatcher";
import * as ActionCreator from "c/hwStammdatensammlerActionCreator";
import {getObjectInfo} from "lightning/uiObjectInfoApi";

export default class HW_StammdatensammlerFeld extends LightningElement {

    @api field;
    @api recordId;
    @api screenLocked;
    @api isExistingMaef;

    @track fieldLevelHelp;
    @track fieldValue;
    @track fieldValueOld;
    @track maefCheck;

    io_Dispatcher = new HwApplicationStateActionDispatcher(this);

    //Wired Properties-------------------------------------------------------------------------
    @wire(getObjectInfo, {objectApiName: "$field.Objektname"}) io_SObjectInfo;

    connectedCallback() {

        this.fieldValue = this.field.value;
        this.fieldValueOld = this.field.valueOld;
        if(this.isExistingMaef) {
            this.maefCheck = this.field.Erforderlich;
        }
    }

    handleDataChange(event) {
        let isValid = this.field.Feldtyp === 'picklist' || this.field.Feldtyp === 'date' || this.field.Feldtyp === 'datetime'
            ? true
            : this.validateInput(event);

        if (isValid) {

            let lv_FieldValue = this.field.isCheckbox ? event.target.checked : event.target.value;
            lv_FieldValue = lv_FieldValue !== null ? String(lv_FieldValue) : null;
            this.fieldValue = lv_FieldValue;

            this.io_Dispatcher.dispatch(
                ActionCreator.setFieldValue(
                    lv_FieldValue,
                    this.field
                )
            );
        }
    }

    validateInput(event) {
        let lo_InputComponent = event.target;
        lo_InputComponent.setCustomValidity("");
        let lv_IsValid = lo_InputComponent.checkValidity();
        if (this.field.Validierung_Methode) {
            lv_IsValid = FieldInputValidator[this.field.Validierung_Methode](this.field, lo_InputComponent);
        }
        if (!lv_IsValid) {
            lo_InputComponent.setCustomValidity(this.field.Validierung_Fehlermeldung);
        }
        lo_InputComponent.reportValidity();
        return lv_IsValid;
    }

    handleMaefCheckChanged(event) {
        this.maefCheck = event.target.checked;
        var value;
        if (this.maefCheck) {
            value = this.fieldValue;
        } else {
            value = this.fieldValueOld;
        }
        this.io_Dispatcher.dispatch(
            ActionCreator.setFieldValue(
                value,
                this.field
            )
        );
    }

    get iv_InlineHelpText() {
        return this.field.Hilfetext;
    }

    get fieldLocked() {
        if(this.isExistingMaef) {
            return (this.field.Schreibschutz || this.screenLocked) || !this.maefCheck;
        } else {
            return this.field.Schreibschutz || this.screenLocked;
        }
    }

    get maefCheckLocked() {
        return this.field.Schreibschutz || this.screenLocked;
    }

    get fieldStyle() {
        return this.field.Erforderlich && (!this.fieldValue && this.fieldValue !== 0) ? 'slds-has-error' : '';
    }

    get hideField() {
        return this.field.Ausblenden || this.field.hide;
    }
    get itemSize() {
        return this.isExistingMaef ? "11" : "12";
    }
}