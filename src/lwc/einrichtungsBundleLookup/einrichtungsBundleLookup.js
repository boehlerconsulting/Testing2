/**
 *@author       Mats Böhler
 *@created      06.04.2021
 *
 *
 *@description  einrichtungsBundleLookup
 *
 *
 *@changelog    06.04.2021 Mats Böhler - Created
 *
 *
 */

import {LightningElement, api, track, wire} from "lwc";
import {NavigationMixin} from "lightning/navigation";
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import searchProducts from '@salesforce/apex/EinrichtungsKonfiguratorErsatzCtrl.searchProducts';
import saveReplacement from '@salesforce/apex/EinrichtungsKonfiguratorErsatzCtrl.saveReplacement';

export default class EinrichtungsBundleLookup extends NavigationMixin(LightningElement) {

    @api option;
    @api optionByIds;
    @api initialSelectionById;
    @api isLager = false;
    @api account;
    @api categoryTitle;
    @api notifyViaAlerts = false;

    get show() {
        return this.optionByIds.get(this.option.product.Id).isSelected;
    }

    get initialSelection() {

        return this.initialSelectionById ? this.initialSelectionById.get(this.option.product.Id) : [];
    }

    errors = [];

    handleSearch(event) {

        event.detail.categoryTitle = this.categoryTitle;

        searchProducts(event.detail)
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


        saveReplacement({
            accountId: this.account.Id,
            optionId: this.option.product.Id,
            productId: selection.length !== 0 ? selection[0].id : null
        })
            .then(result => {
                //sonarqube -> do nothing
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
    }

    notifyUser(title, message, variant) {
        const toastEvent = new ShowToastEvent({title, message, variant});
        this.dispatchEvent(toastEvent);
    }

    get hasInitialSelection() {
        return this.initialSelectionById ? this.initialSelectionById.has(this.option.product.Id) : false;
    }
}