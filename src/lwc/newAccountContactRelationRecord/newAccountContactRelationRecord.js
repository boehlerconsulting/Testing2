/**
 *@author       Mats Böhler
 *@created      08.09.2021
 *
 *
 *@description  newAccountContactRelationRecord
 *
 *
 *@changelog    08.09.2021 Mats Böhler - Created
 *
 *
 */

import {LightningElement, api, wire} from 'lwc';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import createNewAccountContactRelation from '@salesforce/apex/NewAccountContactRelationRecordCtrl.createNewAccountContactRelation';
import createNewContactWithAccountContactRelation from '@salesforce/apex/NewAccountContactRelationRecordCtrl.createNewContactWithAccountContactRelation';
import {reduceErrors} from 'c/errorHandler';
import { CloseActionScreenEvent } from 'lightning/actions';
import searchContacts from '@salesforce/apex/NewAccountContactRelationRecordCtrl.searchContacts';
import {NavigationMixin} from "lightning/navigation";
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import ROLES_FIELD from '@salesforce/schema/AccountContactRelation.Roles';

// Import message service features required for publishing and the message channel
import { publish, MessageContext } from 'lightning/messageService';
import recordSelected from '@salesforce/messageChannel/NewAccountContactRelationRecordChange__c';

export default class NewAccountContactRelationRecord extends NavigationMixin(LightningElement) {

    @api recordId;
    showModal = true;
    showSpinner = false;
    errors = [];
    selectedContactId = null;
    selectedRoles = [];
    roleOptions;
    error;

    @wire(getPicklistValues, { recordTypeId: '012000000000000AAA', fieldApiName: ROLES_FIELD })
    getRoleOptions({ error, data }) {
        if (data) {
            this.roleOptions = data.values;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.roleOptions = undefined;
        }
    }

    @wire(MessageContext)
    messageContext;

    handleSubmit(event){
        event.preventDefault();
        const fields = event.detail.fields;
        this.showSpinner = true;
        createNewContactWithAccountContactRelation({
            contactString: JSON.stringify(fields),
            accountId: this.recordId,
            selectedRoles: this.selectedRoles
        })
            .then(result => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Erfolg',
                        message: 'Der Kontakt wurde erfolgreich angelegt',
                        variant: 'success',
                    }));
                this.closeAction();
                this.publishChange();
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

    publishChange(){
        const payload = { recordId: this.recordId };
        publish(this.messageContext, recordSelected, payload);
    }

    handleSave(){
        if (this.selectedContactId != null){
            this.showSpinner = true;
            createNewAccountContactRelation({
                contactId: this.selectedContactId,
                accountId: this.recordId,
                selectedRoles: this.selectedRoles
            })

                .then(result => {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Erfolg',
                            message: 'Die Kontaktbeziehnung wurde erfolgreich angelegt',
                            variant: 'success',
                        }));
                    this.closeAction();
                    this.publishChange();
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

    handleSearch(event) {

        searchContacts(event.detail)
            .then((results) => {
                this.template.querySelector('c-lookup').setSearchResults(results);
            })
            .catch((error) => {
                this.notifyUser('Lookup Error', 'An error occured while searching with the lookup field.', 'error');
                this.errors = [error];
            });
    }

    handleSelectionChange() {

        this.errors = [];
        const selection = this.template.querySelector('c-lookup').getSelection();
        this.selectedContactId = selection.length !== 0 ? selection[0].id : null;
    }

    handleChange(event){
        this.selectedRoles = event.detail.value;
    }

    closeAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
        this.showModal = false;
        this.showSpinner = false;
        this.dispatchEvent(
            new CustomEvent('refreshView')
        );
    }

    get isRequired(){
        return this.selectedRoles.includes('Vertragspartner');
    }
}