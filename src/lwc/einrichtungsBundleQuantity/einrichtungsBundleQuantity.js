/**
 *@author       Mats Böhler
 *@created      11.03.2021
 *
 *
 *@description  einrichtungsBundleQuantity
 *
 *
 *@changelog    11.03.2021 Mats Böhler - Created
 *
 *
 */

import {LightningElement, api, track, wire} from "lwc";
import {NavigationMixin} from "lightning/navigation";

export default class EinrichtungsBundleQuantity extends NavigationMixin(LightningElement) {

    @api option;
    @api optionByIds;
    @api isLager = false;
    @api isAbbau = false;
    @api isAbbauWiedereinsatzfaehig = false;
    @api maxValue = 99;
    @api minValue = 1;
    @api isDisabled = false;

    get showQuantity() {
        return this.optionByIds.get(this.option.product.Id).isSelected;
    }

    get quantity() {
        if (this.isAbbau) {
            return this.optionByIds.get(this.option.product.Id).quantityAbbau;
        } else if (this.isAbbauWiedereinsatzfaehig) {
            return this.optionByIds.get(this.option.product.Id).quantityWiedereinsatzfaehig;
        } else {
            return this.optionByIds.get(this.option.product.Id).quantity;
        }
    }

    get disabled() {
        if (this.isDisabled){
            return true;
        }
        else if (this.isAbbauWiedereinsatzfaehig || this.isAbbau){
            return this.optionByIds.get(this.option.product.Id).quantityDisabled;
        }else{
            return this.optionByIds.get(this.option.product.Id).quantityDisabled
                || (this.optionByIds.get(this.option.product.Id).product.Option__r.Lagerprodukt__c
                    && !this.isLager);
        }
    }

    handleChange(event) {

        let isValid = this.validateInput(event);

        if (isValid) {
            this.dispatchEvent(
                new CustomEvent('changed', {
                    detail: {
                        optionId: this.option.product.Id,
                        value: event.target.value,
                        fieldName: this.fieldName
                    }
                })
            );
        }
    }

    get fieldName(){
        if (this.isAbbau) {
            return 'quantityAbbau';
        } else if (this.isAbbauWiedereinsatzfaehig) {
            return 'quantityWiedereinsatzfaehig'
        } else {
            'quantity'
        }
    }

    validateInput(event) {
        let inputComponent = event.target;
        if (inputComponent.value === null || inputComponent.value === '' || inputComponent.value === undefined) {
            inputComponent.setCustomValidity("Ungültige Eingabe.");
        } else {
            inputComponent.setCustomValidity("");
        }
        let isValid = inputComponent.checkValidity();
        inputComponent.reportValidity();
        return isValid;
    }

    get maximumValue(){
        if (this.isAbbauWiedereinsatzfaehig){
            return this.optionByIds.get(this.option.product.Id).quantityAbbau;
        }
        else{
            return this.maxValue;
        }
    }
}