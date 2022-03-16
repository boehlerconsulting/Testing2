/**
 *@author       Mats Böhler
 *@created      08.04.2021
 *
 *
 *@description  einrichtungsKonfiguratorAbbau
 *
 *
 *@changelog    08.04.2021 Mats Böhler - Created
 *
 *
 */

import {LightningElement, api, track, wire} from "lwc";
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import init from '@salesforce/apex/EinrichtungsKonfiguratorAbbauCtrl.init';
import initZusatz from '@salesforce/apex/EinrichtungsKonfiguratorAbbauZusatzCtrl.init';
import saveOptionsState from '@salesforce/apex/EinrichtungsKonfiguratorAbbauCtrl.saveOptionsState';
import saveOptionQuantityZusatz from '@salesforce/apex/EinrichtungsKonfiguratorAbbauZusatzCtrl.saveOptionQuantity';
import saveOptionQuantity from '@salesforce/apex/EinrichtungsKonfiguratorAbbauCtrl.saveOptionQuantity';
import saveOptionsStateZusatz from '@salesforce/apex/EinrichtungsKonfiguratorAbbauZusatzCtrl.saveOptionsState';
import {NavigationMixin} from 'lightning/navigation';

export default class EinrichtungsKonfiguratorAbbau extends NavigationMixin(LightningElement) {

    @api account;
    @api einrichtungsprozess;
    @api isAbbauZusatz = false;
    @api process = 'Teilabbau';
    @track showSpinner = false;
    @track isInitialized = false;
    @track categories = [];
    @track activeSections = [];
    @track optionByIds;
    selectedOptions = [];
    deselectedOptions = [];
    @track isEinrichtungskoordinator = false;
    @track initialSelectionById = new Map();

    get isZusatz() {
        return this.isAbbauZusatz == 'true';
    }

    get title() {
        return this.isZusatz
            ? 'In der Filiale nicht hinterlegte Filialausstattung'
            : 'Filialausstattung Bestand';
    }

    get hasProducts() {
        return this.optionByIds.size > 0;
    }

    connectedCallback() {

        if (this.isZusatz) {
            this.initZusatz();
        } else {
            this.init();
        }
    }

    init() {
        this.showSpinner = true;
        init({
            accountId: this.account.Id
        })
            .then(result => {
                let response = JSON.parse(result);
                this.categories = response.categories;
                this.optionByIds = new Map(Object.entries(response.optionByIds));
                this.isEinrichtungskoordinator = response.isEinrichtungskoordinator;
                this.initialSelectionById = new Map();
                this.isInitialized = true;
                this.showSpinner = false;
            })
            .catch(error => {
                this.dispatchErrorToast(error);
            });
    }

    initZusatz() {
        this.showSpinner = true;
        initZusatz({
            accountId: this.account.Id
        })
            .then(result => {
                let response = JSON.parse(result);
                this.categories = response.categories;
                this.optionByIds = new Map(Object.entries(response.optionByIds));
                this.isEinrichtungskoordinator = response.isEinrichtungskoordinator;
                this.initialSelectionById = new Map();
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

    @api
    handleOpenAllSections() {

        let activeSections = [];
        this.categories.forEach(kategorie => {
            activeSections.push(kategorie.title);
        });
        this.activeSections = activeSections;
    }

    @api
    handleCloseAllSections() {

        this.activeSections = [];
    }

    @api
    handleSelectAllOptions() {

        this.categories.forEach(category => {
            category.products.forEach(product => {
                let optionId = product.product.Id;
                this.selectOption(optionId);
            });
            category.products = JSON.parse(JSON.stringify(category.products));
        });

        this.optionByIds = new Map(this.optionByIds);
        this.saveOptionState();
    }

    @api
    handleDeselectAllOptions() {

        this.categories.forEach(category => {
            category.products.forEach(product => {
                let optionId = product.product.Id;
                this.deselectOption(optionId);
            });
            category.products = JSON.parse(JSON.stringify(category.products));
        });

        this.optionByIds = new Map(this.optionByIds);
        this.saveOptionState();
    }

    setSelectionOnChildren(option, isSelected) {

        if (option.hasOptions) {
            option.options.forEach(childOption => {
                let optionId = childOption.product.Id;
                isSelected ? this.selectOption(optionId) : this.deselectOption(optionId);
                this.setSelectionOnChildren(childOption);
            });
        }
    }

    selectOption(optionId) {

        let option = this.optionByIds.get(optionId);
        this.selectedOptions.push(this.optionByIds.get(optionId));
        option.isSelected = true;
        option.quantityAbbau = option.quantity;
        this.setQuantityOnChildren(option, 'quantityAbbau');
    }

    deselectOption(optionId) {

        let option = this.optionByIds.get(optionId);
        this.deselectedOptions.push(this.optionByIds.get(optionId));
        option.isSelected = false;
    }

    handleOptionChange(event) {

        let category = this.categories[event.detail.categoryIndex];
        let optionId = event.detail.optionId;

        if (event.detail.isSelected) {
            this.selectOption(optionId);
        } else {
            this.deselectOption(optionId);
        }

        this.optionByIds = new Map(this.optionByIds);
        category.products = JSON.parse(JSON.stringify(category.products));
        this.saveOptionState();
    }

    saveOptionState() {
        this.showSpinner = true;

        if (this.isZusatz) {
            saveOptionsStateZusatz({
                accountId: this.account.Id,
                selectedOptionsString: JSON.stringify(this.selectedOptions),
                deselectedOptionsString: JSON.stringify(this.deselectedOptions)
            })
                .then(result => {
                    this.selectedOptions = [];
                    this.deselectedOptions = [];
                    this.showSpinner = false;
                })
                .catch(error => {
                    this.dispatchErrorToast(error);
                });
        } else {
            saveOptionsState({
                accountId: this.account.Id,
                selectedOptionsString: JSON.stringify(this.selectedOptions),
                deselectedOptionsString: JSON.stringify(this.deselectedOptions)
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
    }

    handleChange(event) {

        this.showSpinner = true;

        let fieldName = event.detail.fieldName;
        let optionId = event.detail.optionId;
        let quantity = event.detail.value;
        let option = this.optionByIds.get(optionId);
        option[fieldName] = parseInt(quantity);
        this.setQuantityOnChildren(option, fieldName);
        this.optionByIds = new Map(this.optionByIds);

        if (this.isZusatz) {
            saveOptionQuantityZusatz({
                accountId: this.account.Id,
                optionString: JSON.stringify(option)
            })
                .then(result => {

                    this.showSpinner = false;
                })
                .catch(error => {
                    this.dispatchErrorToast(error);
                });
        } else {
            saveOptionQuantity({
                accountId: this.account.Id,
                optionString: JSON.stringify(option)
            })
                .then(result => {

                    this.showSpinner = false;
                })
                .catch(error => {
                    this.dispatchErrorToast(error);
                });
        }
    }

    setQuantityOnChildren(option, fieldName) {

        option.options.forEach(childOption => {
            let childOptionId = childOption.product.Id;
            childOption[fieldName] = option[fieldName] * (childOption.quantity / option.quantity);
            this.optionByIds.get(childOptionId)[fieldName] = option[fieldName] * (this.optionByIds.get(childOptionId).quantity / option.quantity);
            this.setQuantityOnChildren(childOption, fieldName);
        });
    }
}