/**
 *@author       Mats Böhler
 *@created      01.05.2019
 *@version      1.0
 *@since        45.0
 *
 *
 *@description  hwOeffnungszeitenWochentag
 *
 *
 *@changelog    01.05.2019 Mats Böhler - Created
 *
 *
 */

import {LightningElement, track, api, wire} from 'lwc';

//Custom Javascript
import * as Logger from "c/hwLogger";
import {showSpinner, hideSpinner} from "c/hwSpinnerController";

import HwApplicationStateActionDispatcher from "c/hwApplicationStateActionDispatcher";
import * as ActionCreator from "c/hwStammdatensammlerActionCreator";
import {reduce} from "c/hwStammdatensammlerReducer";

export default class HW_OeffnungszeitenWochentag extends LightningElement {

    @api oeffnungszeitWochentag;
    @api fieldName;
    @api screenIndex;
    @api sectionIndex;
    @api index;
    @api categoryIndex;
    @api screenLocked;

    io_Dispatcher = new HwApplicationStateActionDispatcher(this);

    handleDataChange(event) {

        Logger.startBlock("hwOeffnungszeitenWochentag.handleDataChange")();

        let lv_FieldValue = event.target.value;
        let lv_CategoryIndex = event.target.name;
        let lv_Weekday = this.oeffnungszeitWochentag.Wochentag__c;


        this.io_Dispatcher.dispatch(
            ActionCreator.setOeffnungszeiten(
                this.screenIndex,
                this.sectionIndex,
                this.index,
                lv_CategoryIndex,
                lv_FieldValue,
                this.fieldName,
                lv_Weekday
            )
        );

        Logger.endBlock()();
    }

    get value(){
        return this.oeffnungszeitWochentag[this.fieldName];
    }

    get required(){
        return (
            this.oeffnungszeitWochentag.Wochentag__c === 'Montag'
            && this.oeffnungszeitWochentag.Kategorie__c === 'Filialöffnungszeiten'
        )
            ||
            (this.oeffnungszeitWochentag.Wochentag__c === 'Montag'
                && this.oeffnungszeitWochentag.Kategorie__c === 'Sortierzeiten'
                && (this.fieldName === 'vm_von__c' || this.fieldName === 'vm_bis__c' ) )
            ;
    }
}