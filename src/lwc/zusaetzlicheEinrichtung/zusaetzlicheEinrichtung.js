/**
 * @author      Stefan Richter (stefan.richter@hundw.de)
 *              H+W CONSULT GmbH
 *              Bahnhofstr. 3
 *              21244 Buchholz i. d. Nordheide
 *              Germany
 *              https://www.hundw.de
 *
 * @description class for <insert-description-here>
 *
 * TIMELINE
 * 24.09.21      Stefan Richter  Initial release.
 **/
import {api, LightningElement} from 'lwc';
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import {CloseActionScreenEvent} from "lightning/actions";
import createTask from '@salesforce/apex/ZusaetzlicheEinrichtungCtrl.createTask';
import init from '@salesforce/apex/ZusaetzlicheEinrichtungCtrl.init';

export default class ZusaetzlicheEinrichtung extends LightningElement {
    @api recordId;
    task;
    showSpinner = true;
    isSaveValid = false;
    isInitialized = false;

    connectedCallback() {
        init({})
            .then(result => {
                this.task = JSON.parse(result);
                this.showSpinner = false;
                this.isInitialized = true;
            })
            .catch(error => {
                this.error = error;
                const evt = new ShowToastEvent({
                    title: 'Error',
                    message: error,
                    variant: 'error',
                    mode: 'sticky'
                });
                this.dispatchEvent(evt);
                this.showSpinner = false;
                this.closeAction();
            });
    }

    addDays(date, days) {
        let result = new Date(date);
        result.setDate(result.getDate() + days);
        return result;
    }

    createTask() {
        this.showSpinner = true;
        createTask({
            fnaeId: this.recordId,
            jsonTaskRecord: JSON.stringify(this.task)
        })

            .then(result => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Erfolg',
                        message: 'Die Aufgaben ' + this.task.Aufgabenart__c + ' wurde angelegt',
                        variant: 'success',
                    }));
                this.showSpinner = false;
                this.closeAction();
            })
            .catch(error => {
                this.error = error;
                const evt = new ShowToastEvent({
                    title: 'Error',
                    message: error,
                    variant: 'error',
                    mode: 'sticky'
                });
                this.dispatchEvent(evt);
                this.showSpinner = false;
                this.closeAction();
            });
    }

    handleDescriptionChange(event) {
        this.task.Description = event.target.value;
        this.validateAction();
    }

    handleTaskTypeChange(event) {
        this.task.Aufgabenart__c = event.target.value;
        this.validateAction();
    }

    handleTargetAmountChange(event) {
        this.task.ZielFachanzahl__c = event.target.value;
        this.validateAction();
    }

    handleActivityDateChange(event) {
        this.task.ActivityDate = event.target.value;
        this.validateAction();
    }

    handleDueDateChange(event) {
        this.task.Erledigung_bis_zum__c = event.target.value;
        this.validateAction();
    }

    validateAction(event) {
        this.isSaveValid = true;
        this.template.querySelectorAll("lightning-input").forEach(item => {
            this.itemValidation(item);
        });
    }

    itemValidation(item) {
        let fieldErrorMsg = "Bitte Feld befüllen";
        let fieldValue = item.value;
        let fieldLabel = item.label;
        if (!fieldValue) {
            item.setCustomValidity(fieldErrorMsg + ' ' + fieldLabel);
        } else {
            item.setCustomValidity("");
        }
        this.isSaveValid = this.isSaveValid && !!fieldValue
        item.reportValidity();
    }

    get options() {
        return [
            {
                label: 'Akquiseauftrag Poststation - zusätzliche Einrichtung',
                value: 'Akquiseauftrag Poststation - zusätzliche Einrichtung'
            },
            {
                label: 'Akquiseauftrag Packstation - zusätzliche Einrichtung',
                value: 'Akquiseauftrag Packstation - zusätzliche Einrichtung'
            },
        ];
    }

    get disableSaveButton() {
        return !this.isSaveValid;
    }

    closeAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}