/**
 *@author       Mats Böhler
 *@created      05.04.2021
 *
 *
 *@description  einrichtungsKonfiguratorErsatz
 *
 *
 *@changelog    05.04.2021 Mats Böhler - Created
 *
 *
 */

import {LightningElement, api, track, wire} from "lwc";
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import init from '@salesforce/apex/EinrichtungsKonfiguratorErsatzCtrl.init';
import initZusatz from '@salesforce/apex/EinrichtungsKonfiguratorZusatzCtrl.init';
import saveOptionsState from '@salesforce/apex/EinrichtungsKonfiguratorErsatzCtrl.saveOptionsState';
import saveOptionsStateZusatz from '@salesforce/apex/EinrichtungsKonfiguratorZusatzCtrl.saveOptionsState';
import saveOptionQuantity from '@salesforce/apex/EinrichtungsKonfiguratorErsatzCtrl.saveOptionQuantity';
import saveOptionQuantityZusatz from '@salesforce/apex/EinrichtungsKonfiguratorZusatzCtrl.saveOptionQuantity';
import {NavigationMixin} from 'lightning/navigation';

export default class EinrichtungsKonfiguratorErsatz extends NavigationMixin(LightningElement) {

    @api account;
    @api einrichtungsprozess;
    @api isZusatz = false;
    @api isErsatz = false;
    @track showSpinner = false;
    @track isInitialized = false;
    @track oz;
    @track vertriebssegment;
    @track anzahlSchalter;
    @track variant = '';
    @track categories = [];
    @track activeSections = [];
    @track optionByIds;
    selectedOptions = [];
    deselectedOptions = [];
    @track isEinrichtungskoordinator = false;
    @track initialSelectionById = new Map();

    connectedCallback() {
        this.oz = this.account.Filialtyp_OZ__c;
        this.vertriebssegment = this.account.Vertriebssegment__c;
        this.anzahlSchalter = this.account.AnzahlSchalter__c === 0 ? null : this.account.AnzahlSchalter__c.toString();
        this.variant = this.einrichtungsprozess.Variante__c;
        if (this.showVariants && this.variant !== 'XL' && this.variant !== 'X') {
            this.variant = 'X';
        }
        if (this.isErsatz) {
            this.init();
        } else {
            this.initZusatz();
        }
    }

    init() {
        this.showSpinner = true;
        init({
            oz: this.oz,
            vertriebssegment: this.vertriebssegment,
            anzahlSchalter: this.anzahlSchalter,
            variant: this.variant,
            accountId: this.account.Id
        })
            .then(result => {
                let response = JSON.parse(result);
                this.categories = response.categories;
                this.optionByIds = new Map(Object.entries(response.optionByIds));
                this.isEinrichtungskoordinator = response.isEinrichtungskoordinator;
                this.initialSelectionById = new Map();
                this.categories.forEach(kategorie => {
                    kategorie.products.forEach(option => {
                        if (option.replacementId) {
                            this.initialSelectionById.set(option.product.Id, [
                                {
                                    id: option.replacementId,
                                    sObjectType: 'Product2',
                                    icon: 'standard:product',
                                    title: option.replacementTitle,
                                    subtitle: option.replacementSubtitle
                                }
                            ]);
                        }
                    });
                });
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
            oz: this.oz,
            vertriebssegment: this.vertriebssegment,
            anzahlSchalter: this.anzahlSchalter,
            variant: this.variant,
            accountId: this.account.Id
        })
            .then(result => {
                let response = JSON.parse(result);
                this.categories = response.categories;
                this.categories.forEach(kategorie => {
                    kategorie.products = this.sortData(kategorie.products, 'name', 'asc');
                });
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

    sortData(data, fieldname, direction) {
        // serialize the data before calling sort function
        let parseData = JSON.parse(JSON.stringify(data));
        // Return the value stored in the field
        let keyValue = (a) => {
            let value = a[fieldname] ? a[fieldname].toString().toUpperCase() : a[fieldname];
            if (fieldname.includes('.') && a[fieldname.split('.')[0]]  ) {
                value = a[fieldname.split('.')[0]][fieldname.split('.')[1]];
            }
            return value;
        };

        // cheking reverse direction
        let isReverse = direction === 'asc' ? 1 : -1;

        // sorting data
        parseData.sort((x, y) => {
            x = keyValue(x) ? keyValue(x) : ''; // handling null values
            y = keyValue(y) ? keyValue(y) : '';

            // sorting values based on direction
            return isReverse * ((x > y) - (y > x));
        });

        // set the sorted data to data table data
        return parseData;
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
        if (this.isErsatz) {
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
        } else {
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
        }
    }

    handleChange(event) {

        this.showSpinner = true;

        let optionId = event.detail.optionId;
        let quantity = event.detail.value;
        let option = this.optionByIds.get(optionId);
        option.quantity = parseInt(quantity);
        this.setQuantityOnChildren(option);
        this.optionByIds = new Map(this.optionByIds);


        if (this.isErsatz) {
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
        } else {
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
        }
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
}