/**
 *@author       Mats Böhler
 *@created      11.03.2021
 *
 *
 *@description  einrichtungsBestandskonfigurator
 *
 *
 *@changelog    11.03.2021 Mats Böhler - Created
 *
 *
 */

import {LightningElement, api, track, wire} from "lwc";
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import init from '@salesforce/apex/EinrichtungsKonfiguratorCtrl.init';
import saveProcessState from '@salesforce/apex/EinrichtungsBestandskonfiguratorCtrl.saveProcessState';
import saveOptionsState from '@salesforce/apex/EinrichtungsKonfiguratorCtrl.saveOptionsState';
import saveOptionQuantity from '@salesforce/apex/EinrichtungsKonfiguratorCtrl.saveOptionQuantity';
import saveFieldValue from '@salesforce/apex/EinrichtungsprozessBaseCtrl.saveFieldValue';
import HwApexRequest from "c/hwApexRequest";
import hwRequestEvaluator from "c/hwRequestEvaluator";
import {NavigationMixin} from 'lightning/navigation';

export default class EinrichtungsBestandskonfigurator extends NavigationMixin(LightningElement) {

    @api account;
    @api einrichtungsprozess;
    @track showSpinner = false;
    @track zeigeBundles = '';
    @track isInitialized = false;
    @track process = '';
    @track categories = [];
    @track activeSections = [];
    @track optionByIds;
    @track previousExists = 'Ja';
    selectedOptions = [];
    deselectedOptions = [];
    @track apexRequests = [];

    connectedCallback() {

        this.previousExists = this.einrichtungsprozess.VorgaengerfilialeExistiert__c;
        this.zeigeBundles = this.einrichtungsprozess.AusstattungUebernahmeVorgaenger__c;
        this.process = this.einrichtungsprozess.Prozess__c;

        if (this.process === 'Vorgängerfiliale') {

            this.init();
        } else {
            this.isInitialized = true;
            this.showSpinner = false;
        }
    }

    @api
    init() {
        this.showSpinner = true;
        init({
            oz: '',
            vertriebssegment: '',
            anzahlSchalter: '',
            variant: '',
            accountId: this.account.Id,
            process: 'Vorgängerfiliale'
        })
            .then(result => {
                let response = JSON.parse(result);
                this.categories = response.categories;
                this.optionByIds = new Map(Object.entries(response.optionByIds));
                this.isInitialized = true;
                this.showSpinner = false;
            })
            .catch(error => {
                this.dispatchErrorToast(error);
            });
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
    }

    get processOptions() {
        return [
            {label: 'Ja', value: 'Ja'},
            {label: 'Nein', value: 'Nein'}
        ];
    }

    handleProcessChange(event) {
        this.showSpinner = true;
        this[event.target.name] = event.target.value;

        saveProcessState({
            accountId: this.account.Id,
            einrichtungsprozessId: this.einrichtungsprozess.Id,
            previousExists: this.previousExists,
            zeigeBundles: this.zeigeBundles
        })
            .then(result => {

                this.process = result;

                if (this.process === 'Vorgängerfiliale') {

                    this.init();
                }

                this.dispatchEvent(
                    new CustomEvent('processchanged', {
                        detail: {
                            process: this.process,
                            zeigeBundles: this.zeigeBundles,
                            previousExists: this.previousExists
                        }
                    })
                );
                this.showSpinner = false;
            })
            .catch(error => {
                this.dispatchErrorToast(error);
            });
    }

    get showBundles() {
        return this.zeigeBundles === 'Ja';
    }

    handleOpenAllSections() {

        let activeSections = [];
        this.categories.forEach(kategorie => {
            activeSections.push(kategorie.title);
        });
        this.activeSections = activeSections;
    }

    handleCloseAllSections() {

        this.activeSections = [];
    }

    handleOptionChange(event) {

        let optionId = event.detail.optionId;

        let option = this.optionByIds.get(optionId);

        if (event.detail.isSelected) {
            this.selectedOptions.push(this.optionByIds.get(optionId));
            option.isSelected = true;

        } else {
            this.deselectedOptions.push(this.optionByIds.get(optionId));
            option.isSelected = false;
        }

        this.optionByIds = new Map(this.optionByIds);

        this.saveOptionState();
    }

    saveOptionState() {
        this.showSpinner = true;

        saveOptionsState({
            accountId: this.account.Id,
            selectedOptionsString: JSON.stringify(this.selectedOptions),
            deselectedOptionsString: JSON.stringify(this.deselectedOptions),
            process: this.process
        })
            .then(result => {
                this.selectedOptions = [];
                this.deselectedOptions = [];
                this.showSpinner = false;
            })
            .catch(error => {
                this.dispatchErrorToast(error);
            });
    }

    handleChange(event) {

        this.showSpinner = true;

        let optionId = event.detail.optionId;
        let quantity = event.detail.value;
        let option = this.optionByIds.get(optionId);
        option.quantity = parseInt(quantity);
        this.setQuantityOnChildren(option);
        this.optionByIds = new Map(this.optionByIds);

        saveOptionQuantity({
            accountId: this.account.Id,
            optionString: JSON.stringify(option)
        })
            .then(result => {
                this.dispatchEvent(
                    new CustomEvent('processchanged', {
                        detail: {
                            process: this.process,
                            zeigeBundles: this.zeigeBundles,
                            previousExists: this.previousExists
                        }
                    })
                );
                this.showSpinner = false;
            })
            .catch(error => {
                this.dispatchErrorToast(error);
            });
    }

    setQuantityOnChildren(option) {

        if (option.hasOptions) {
            option.options.forEach(childOption => {
                let childOptionId = childOption.product.Id;
                childOption.quantity = option.quantity * childOption.originalQuantity;
                this.optionByIds.get(childOptionId).quantity = option.quantity * this.optionByIds.get(childOptionId).originalQuantity;
                this.setQuantityOnChildren(childOption);
            });
        }
    }

    get previousAccountHasValue() {
        return this.account.Vorgaengerfiliale__r
            && this.account.Vorgaengerfiliale__r.ShippingStreet === this.account.ShippingStreet
            && this.account.Vorgaengerfiliale__r.ShippingPostalCode === this.account.ShippingPostalCode
            && this.account.Vorgaengerfiliale__r.ShippingCity === this.account.ShippingCity;
    }

    openPreviousAccount() {
        window.open('/' + this.account.Vorgaengerfiliale__c, '_blank');
    }

    handleBegruendungChange(event) {

        let apexRequest = new HwApexRequest(this);
        apexRequest
            .setMethod(saveFieldValue)
            .setMethodName("EinrichtungsprozessCtrl.saveFieldValue")
            .setParameters({
                recordId: this.einrichtungsprozess.Id,
                fieldName: 'BegruendungNeubestellung__c',
                dataType: 'text',
                value: event.target.value
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

    get showHinweis(){
        return this.zeigeBundles === 'Nein' && this.einrichtungsprozess.Geschaeftsvorfall__c !== 'Neueinrichtung'
    }
}