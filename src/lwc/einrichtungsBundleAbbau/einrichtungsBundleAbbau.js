/**
 *@author       Mats Böhler
 *@created      14.04.2021
 *
 *
 *@description  einrichtungsBundleAbbau
 *
 *
 *@changelog    14.04.2021 Mats Böhler - Created
 *
 *
 */

import {LightningElement, api, track, wire} from "lwc";
import {NavigationMixin} from "lightning/navigation";
import {ShowToastEvent} from "lightning/platformShowToastEvent";

export default class EinrichtungsBundleAbbau extends NavigationMixin(LightningElement) {

    @api categoryIndex;
    @api options;
    @api optionByIds;
    @api isEinrichtungskoordinator = false;
    @api initialSelectionById;
    @api isTopLevel = false;
    @api isAbbauZusatz = false;
    @api account;
    @api categoryTitle;
    @api process;
    @track showBundleConfiguration = false;
    @track showAdditionalInformation = false;
    @track selectedOption;

    handleOpenOption(event) {

        window.open('/' + event.target.name.product[this.idField], '_blank');
    }

    get idField(){
        return this.isAbbauZusatz ? 'Id' : 'Produktoption__c';
    }

    get isSchliessung(){
        return this.process === 'Filialschließung';
    }

    openFilePreview(event) {

        let fileId = event.target.name.pictureId;
        this[NavigationMixin.Navigate]({
            type: 'standard__namedPage',
            attributes: {
                pageName: 'filePreview'
            },
            state: {
                recordIds: fileId,
                selectedRecordId: fileId
            }
        })
    }

    closeModal() {

        this.showBundleConfiguration = false;
    }

    closeAdditionalInformation() {

        this.showAdditionalInformation = false;
    }

    handleShowConfiguration(event) {
        this.selectedOption = event.target.name;
        this.showBundleConfiguration = true;
    }

    handleShowAdditionalInformation(event) {
        this.selectedOption = event.target.name;
        this.showAdditionalInformation = true;
    }

    handleOptionChange(event) {

        this.dispatchEvent(
            new CustomEvent('selected', {
                detail: {
                    categoryIndex: this.categoryIndex,
                    optionId: event.detail.optionId
                        ? event.detail.optionId
                        : event.target.name.product.Id,
                    isSelected: event.detail.isSelected
                        ? event.detail.isSelected
                        : event.target.checked
                }
            })
        );
    }

    handleChange(event) {

        this.dispatchEvent(
            new CustomEvent('changed', {
                detail: {
                    optionId: event.detail.optionId,
                    value: event.detail.value,
                    fieldName: event.detail.fieldName
                }
            })
        );
    }

    get trueBoolean(){
        return true;
    }
}