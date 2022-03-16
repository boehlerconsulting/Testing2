/**
 *@author       Mats Böhler
 *@created      28.09.2019
 *@version      1.0
 *@since        45.0
 *
 *
 *@description  hwLightningDatatableCell
 *
 *
 *@changelog    28.09.2019 Mats Böhler - Created
 *
 *
 */

import {LightningElement, api, track, wire} from 'lwc';
import searchOwners from '@salesforce/apex/MassenzuweisungCtrl.searchOwners';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import BEWERTUNG_VM from '@salesforce/schema/Lead.Bewertung_VM__c';

export default class hwLightningDatatableCell extends LightningElement {

    @api
    get rowData() {
        return this.recordData;
    }
    set rowData(value) {

        this.recordData = value;
        if (this.initialized && this.bewertungOptions){
            let options = [];
            for (let picklistValue of this.bewertungOptions) {
                let option = {};
                option.value = picklistValue.value;
                option.label = picklistValue.label;
                if (picklistValue.value === this.rowData['Bewertung_VM__c']){
                    option.isSelected = true;
                }
                options.push(option);
            }
            this.bewertungOptions = options;
        }
    }
    @track recordData;
    @api column;
    @api columns;
    @api rowIndex;
    @api columnIndex;
    @api isCheckboxCell = false;
    @api isActionCell = false;
    @api isSelected = false;
    @track isChecked = false;
    @api erledigungstypPicklistValues;
    @api isTermin = false;
    @api isSelectedById;
    @api initialSelectionById;
    @api plannedDateByLeadId;
    @api isMassenzuweisung = false;

    @track initialized = false;

    renderedCallback(){

        if (!this.initialized){
            this.recordTypeId = this.rowData.RecordTypeId;
        }
    }

    @api recordTypeId;
    @wire(getPicklistValues, { recordTypeId: '$recordTypeId', fieldApiName: BEWERTUNG_VM })
    bewertungValues({ error, data }) {

        if (error) {
            //sonarqube -> do nothing
        } else if (data) {
            let options = [];
            for (let picklistValue of data.values) {
                let option = {};
                option.value = picklistValue.value;
                option.label = picklistValue.label;
                if (picklistValue.value === this.rowData['Bewertung_VM__c']){
                    option.isSelected = true;
                }
                options.push(option);
            }
            options.unshift({label: '', value:''})
            this.bewertungOptions = options;
            this.initialized = true;
        }
    }

    get fieldLabel() {
        return this.column.fieldLabel.includes('.') && this.rowData[this.column.fieldLabel.split('.')[0]]
            ? this.rowData[this.column.fieldLabel.split('.')[0]][this.column.fieldLabel.split('.')[1]]
            : this.rowData[this.column.fieldLabel];
    }

    get fieldValue() {
        return this.column.fieldName.includes('.') && this.rowData[this.column.fieldName.split('.')[0]]
            ? this.rowData[this.column.fieldName.split('.')[0]][this.column.fieldName.split('.')[1]]
            : this.rowData[this.column.fieldName];
    }

    get richtext() {
        return this.column.type === 'richtext';
    }

    get text() {
        return this.column.type === 'text';
    }

    get textarea() {
        return this.column.type === 'textarea';
    }

    get date() {
        return this.column.type === 'date';
    }

    get number() {
        return this.column.type === 'number';
    }

    get currency() {
        return this.column.type === 'currency';
    }

    get email() {
        return this.column.type === 'email';
    }

    get phone() {
        return this.column.type === 'phone';
    }

    get checkbox() {
        return this.column.type === 'checkbox';
    }

    get lookup() {
        return this.column.type === 'lookup';
    }

    get picklist() {
        return this.column.type === 'picklist';
    }

    get lookupFieldValue() {
        return this.rowData[this.column.fieldName] ? '/' + this.rowData[this.column.fieldName] : '';
    }

    get isCheckboxCellDisabled() {
        return this.rowData['PriohilfeAufgabenverwaltung__r'] ? this.rowData['PriohilfeAufgabenverwaltung__r']['Dokumentationspflicht__c'] : false;
    }

    get selected() {
        return this.isSelectedById ? this.isSelectedById.get(this.rowData.Id) : this.isSelected;
    }

    get plannedDate() {
        return this.plannedDateByLeadId ? this.plannedDateByLeadId.get(this.rowData.Id) : null;
    }

    get edit() {
        return this.column.isEditable && !this.editAktivitaetsstatus;
    }

    get editAktivitaetsstatus() {
        return this.column.isEditable && this.column.fieldName === 'Aktivitaetsstatus__c';
    }

    get statusFieldValue() {
        return this.rowData[this.column.fieldName] === 'aktiv' || this.rowData[this.column.fieldName] === 'aktiv durch Zentrale';
    }

    handleOnChange(event) {

        this.isChecked = event.detail.checked;
        this.dispatchEvent(
            new CustomEvent('selected', {
                detail: {
                    checked: event.detail.checked,
                    taskId: this.rowData['Id'],
                    rowIndex: this.rowIndex
                }
            })
        );
    }

    @track picklistValue;

    get options() {
        return this.erledigungstypPicklistValues;
    }

    handleChange(event) {
        this.picklistValue = event.detail.value;
        this.dispatchEvent(
            new CustomEvent('typchanged', {
                detail: {
                    erledigungstypValue: event.detail.value,
                    taskId: this.rowData['Id'],
                    rowIndex: this.rowIndex
                }
            })
        );
    }

    get isErledigungstyp() {
        return this.column.fieldName === 'Typc__c' && !this.isTermin;
    }

    get erledigungstypValue() {
        return this.picklistValue ? this.picklistValue : this.fieldValue;
    }

    get isTerminiertZum() {
        return this.column.fieldName === 'TerminiertZum__c' && !this.isTermin;
    }

    get isUnplanned() {
        return this.column.fieldName === 'GeplantesDatum__c';
    }

    get isStandard() {
        return !this.isTerminiertZum && !this.isErledigungstyp && !this.isUnplanned;
    }

    @track terminiertZum;

    get terminiertZumValue() {
        return this.terminiertZum ? this.terminiertZum : this.fieldValue;
    }

    handleTerminiertZumChange(event) {
        this.terminiertZum = event.target.value;
        this.dispatchEvent(
            new CustomEvent('terminiertchanged', {
                detail: {
                    terminiertValue: event.target.value,
                    taskId: this.rowData['Id'],
                    rowIndex: this.rowIndex
                }
            })
        );
    }

    handlePlannedDateChange(event) {
        this.terminiertZum = event.target.value;
        this.dispatchEvent(
            new CustomEvent('plannedchanged', {
                detail: {
                    plannedValue: event.target.value,
                    leadId: this.rowData['Id'],
                    rowIndex: this.rowIndex
                }
            })
        );
    }

    handleDateChange(event) {

        this.dispatchEvent(
            new CustomEvent('datechanged', {
                detail: {
                    value: event.target.value,
                    leadId: this.rowData['Id'],
                    fieldName: this.column.fieldName
                }
            })
        );
    }

    handleFieldChange(event) {
        let value = event.target.value;
        if (this.column.fieldName === 'Aktivitaetsstatus__c'){
            value = event.target.checked === true ? 'aktiv' : 'inaktiv';
        }
        this.dispatchEvent(
            new CustomEvent('fieldchanged', {
                detail: {
                    value: value,
                    leadId: this.rowData['Id'],
                    fieldName: this.column.fieldName
                }
            })
        );
    }

    // Use alerts instead of toast to notify user
    @api notifyViaAlerts = false;

    get initialSelection() {
        let selection = this.initialSelectionById ? this.initialSelectionById.get(this.rowData.Id) : [];
        /*if (selection[0]){
            selection[0].title = this.fieldLabel;
        }*/
        return selection;
    }

    errors = [];

    handleSearch(event) {
        if ( this.isMassenzuweisung) {
            searchOwners(event.detail)
                .then((results) => {
                    this.template.querySelector('c-lookup').setSearchResults(results);
                })
                .catch((error) => {
                    this.notifyUser('Lookup Error', 'An error occured while searching with the lookup field.', 'error');
                    this.errors = [error];
                });
        }
    }

    handleSelectionChange() {
        this.checkForErrors();
    }

    checkForErrors() {
        this.errors = [];
        const selection = this.template.querySelector('c-lookup').getSelection();
        // Enforcing required field
        if (selection.length === 0 && this.column.fieldName === 'OwnerId') {
            this.errors.push({message: 'Bitte neuen Inhaber auswählen.'});
        }
        else  {

            this.dispatchEvent(
                new CustomEvent('ownerchanged', {
                    detail: {
                        ownerId: selection.length !== 0 ? selection[0].id : null,
                        leadId: this.rowData.Id,
                        title: selection.length !== 0 ? selection[0].title : null,
                        subtitle: selection.length !== 0 ? selection[0].subtitle : null
                    }
                })
            );
        }
    }

    notifyUser(title, message, variant) {
        const toastEvent = new ShowToastEvent({title, message, variant});
        this.dispatchEvent(toastEvent);
    }

    get hasInitialSelection(){
        return this.initialSelectionById ? this.initialSelectionById.has(this.rowData.Id) : false;
    }

    get statusOptions() {
        let options = [
            { label: 'PLA', value: 'PLA' },
            { label: 'AUF', value: 'AUF' },
            { label: 'RIO', value: 'RIO' },
            { label: 'OK', value: 'OK' }
        ];
        for (let option of options) {
            if (option.value === this.rowData[this.column.fieldName]){
                option.isSelected = true;
            }
        }
        return options;
    }

    get redText(){
        return this.column.fieldName === 'Delta__c' && this.rowData['Delta__c'] < 0 ? 'textRed' : '';
    }

    get isDriawa(){
        return this.column.fieldName === 'Freigabe_DRIAWA_TB__c'
            || this.column.fieldName === 'Freigabe_DRIAWA_EG__c'
            || this.column.fieldName === 'Freigabe_DRIAWA_SON__c';
    }

    get isBewertungVM(){
        return this.column.fieldName === 'Bewertung_VM__c' && this.bewertungOptions;
    }

    get showLookup(){
        return this.column.fieldName === 'OwnerId' && this.column.isEditable;
    }

   @track bewertungOptions;

}