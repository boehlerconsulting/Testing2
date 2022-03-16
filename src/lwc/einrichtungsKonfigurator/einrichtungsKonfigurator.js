/**
 *@author       Mats Böhler
 *@created      22.02.2021
 *
 *
 *@description  einrichtungsKonfigurator
 *
 *
 *@changelog    22.02.2021 Mats Böhler - Created
 *
 *
 */

import {LightningElement, api, track, wire} from "lwc";
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import init from '@salesforce/apex/EinrichtungsKonfiguratorCtrl.init';
import initWithNewVariant from '@salesforce/apex/EinrichtungsKonfiguratorCtrl.initWithNewVariant';
import saveOptionsState from '@salesforce/apex/EinrichtungsKonfiguratorCtrl.saveOptionsState';
import saveOptionQuantity from '@salesforce/apex/EinrichtungsKonfiguratorCtrl.saveOptionQuantity';
import {NavigationMixin} from 'lightning/navigation';

export default class EinrichtungsKonfigurator extends NavigationMixin(LightningElement) {

    @api account;
    @api einrichtungsprozess;
    @track showSpinner = false;
    @track isInitialized = false;
    @track oz;
    @track vertriebssegment;
    @api anzahlSchalter;
    @track variant = '';
    @track categories = [];
    @track activeSections = [];
    @track optionByIds;
    @track isEinrichtungskoordinator = false;
    selectedOptions = [];
    deselectedOptions = [];

    connectedCallback() {
        this.oz = this.account.Filialtyp_OZ__c;
        this.vertriebssegment = this.account.Vertriebssegment__c;
        this.anzahlSchalter = this.account.AnzahlSchalter__c === 0 ? null : this.account.AnzahlSchalter__c.toString();
        this.variant = this.einrichtungsprozess.Variante__c;
        if (this.showVariants && this.variant !== 'XL' && this.variant !== 'X') {
            this.variant = 'X';
        }
        this.init();
    }

    @api
    init() {
        if (this.oz && this.vertriebssegment && this.anzahlSchalter
            && (!this.showVariants || this.variant)) {

            this.showSpinner = true;
            init({
                oz: this.oz,
                vertriebssegment: this.vertriebssegment,
                anzahlSchalter: this.anzahlSchalter,
                variant: this.variant,
                accountId: this.account.Id,
                process: 'Neubestellung'
            })
                .then(result => {
                    let response = JSON.parse(result);
                    this.categories = response.categories;
                    this.optionByIds = new Map(Object.entries(response.optionByIds));
                    this.isEinrichtungskoordinator = response.isEinrichtungskoordinator;
                    this.isInitialized = true;
                    this.showSpinner = false;
                })
                .catch(error => {
                    this.dispatchErrorToast(error);
                });
        } else {
            this.isInitialized = true;
        }
    }

    @api
    reset(anzahlSchalter){
        this.anzahlSchalter = anzahlSchalter;
        this.init();
    }

    handleSearch(event) {
        this[event.target.name] = event.target.value;
    }

    handleVariantChange(event) {
        this.showSpinner = true;
        this.isInitialized = false;
        this[event.target.name] = event.target.value;

        initWithNewVariant({
            oz: this.oz,
            vertriebssegment: this.vertriebssegment,
            anzahlSchalter: this.anzahlSchalter,
            variant: this.variant,
            accountId: this.account.Id,
            einrichtungsprozessId: this.einrichtungsprozess.Id,
            process: 'Neubestellung'
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

    get ozOptions() {
        return [
            {label: '79', value: '79'},
            {label: '76', value: '76'},
            {label: '95', value: '95'},
            {label: '84', value: '84'},
            {label: '78', value: '78'},
        ];
    }

    get vertriebssegmentOptions() {
        return [
            {label: 'A', value: 'A'},
            {label: 'B', value: 'B'},
            {label: 'C', value: 'C'},
        ];
    }

    get anzahlSchalterOptions() {
        return [
            {label: '1', value: '1'},
            {label: '2', value: '2'},
            {label: '3', value: '3'},
        ];
    }

    get variantOptions() {
        return [
            {label: 'X', value: 'X'},
            {label: 'XL', value: 'XL'}
        ];
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

    get showVariants() {
        return (this.oz === '79' && this.vertriebssegment === 'A' && this.anzahlSchalter === '1')
            || (this.oz === '79' && this.vertriebssegment === 'B' && this.anzahlSchalter === '1')
            || (this.oz === '79' && this.vertriebssegment === 'C' && this.anzahlSchalter === '1')
            || (this.oz === '76' && this.vertriebssegment === 'B' && this.anzahlSchalter === '1')
            || (this.oz === '76' && this.vertriebssegment === 'C' && this.anzahlSchalter === '1')
            || (this.oz === '95' && this.vertriebssegment === 'A' && this.anzahlSchalter === '1')
            || (this.oz === '95' && this.vertriebssegment === 'B' && this.anzahlSchalter === '1')
            || (this.oz === '95' && this.vertriebssegment === 'C' && this.anzahlSchalter === '1');
    }

    handleOptionChange(event) {

        let category = this.categories[event.detail.categoryIndex];

        let optionId = event.detail.optionId;

        let option = this.optionByIds.get(optionId);

        if (event.detail.isSelected) {
            this.selectedOptions.push(this.optionByIds.get(optionId));
            option.isSelected = true;
            if (option.product.Option__r.Lagerprodukt__c) {
                category.products.forEach(categoryOption => {

                    if (categoryOption.product.Id === optionId) {
                        categoryOption.isSelected = true;
                    }
                });
            }

        } else {
            this.deselectedOptions.push(this.optionByIds.get(optionId));
            option.isSelected = false;
            if (option.product.Option__r.Lagerprodukt__c) {
                category.products.forEach(categoryOption => {

                    if (categoryOption.product.Id === optionId) {
                        categoryOption.isSelected = false;
                    }
                });
            }
        }

        this.optionByIds = new Map(this.optionByIds);
        category.products = JSON.parse(JSON.stringify(category.products));
        this.saveOptionState();
    }

    saveOptionState() {
        this.showSpinner = true;

        saveOptionsState({
            accountId: this.account.Id,
            selectedOptionsString: JSON.stringify(this.selectedOptions),
            deselectedOptionsString: JSON.stringify(this.deselectedOptions),
            process: 'Neubestellung'
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

    get process() {
        return this.einrichtungsprozess.Prozess__c;
    }

    get noProcessDefined() {
        return this.einrichtungsprozess.Prozess__c === null
            || this.einrichtungsprozess.Prozess__c === undefined
            || this.einrichtungsprozess.Prozess__c === '';
    }
}