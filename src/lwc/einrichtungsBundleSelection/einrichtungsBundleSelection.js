/**
 *@author       Mats Böhler
 *@created      18.03.2021
 *
 *
 *@description  einrichtungsBundleSelection
 *
 *
 *@changelog    18.03.2021 Mats Böhler - Created
 *
 *
 */

import {LightningElement, api, track, wire} from "lwc";
import {NavigationMixin} from "lightning/navigation";

export default class EinrichtungsBundleSelection extends NavigationMixin(LightningElement) {

    @api option;
    @api optionByIds;
    @api isLager = false;
    @api isAbbau = false;

    get selected() {
        return this.optionByIds.get(this.option.product.Id).isSelected;
    }

    get disabled() {
        if (this.isAbbau) {
            return this.optionByIds.get(this.option.product.Id).isSelectionDisabled;
        }
        return this.optionByIds.get(this.option.product.Id).isSelectionDisabled
            || (this.optionByIds.get(this.option.product.Id).product.Option__r.Lagerprodukt__c
                && !this.isLager);
    }

    handleChange(event) {

        this.dispatchEvent(
            new CustomEvent('selected', {
                detail: {
                    optionId: this.option.product.Id,
                    isSelected: event.target.checked
                }
            })
        );
    }
}