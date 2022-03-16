/**
 *@author       Mats Böhler
 *@created      01.04.2019
 *@version      1.0
 *@since        45.0
 *
 *
 *@description  hwStammdatensammlerFenster
 *
 *
 *@changelog    01.04.2019 Mats Böhler - Created
 *
 *
 */

//LWC
import {LightningElement, api, track, wire} from "lwc";
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import {getRecord, getFieldValue, updateRecord} from "lightning/uiRecordApi";

//Custom Javascript
import * as Logger from "c/hwLogger";
import {showSpinner, hideSpinner} from "c/hwSpinnerController";

import HwApplicationStateActionDispatcher from "c/hwApplicationStateActionDispatcher";
import * as ActionCreator from "c/hwStammdatensammlerActionCreator";

export default class HW_StammdatensammlerFenster extends LightningElement {

    @api screen;
    @api recordId;
    @api isFiliale95;
    @api index;
    @api isFactsSent;
    @api isVorgaengerfilialePresent;
    @api isExistingMaef;
    @api maefUrl;
    @api isFormataenderung;

    io_Dispatcher = new HwApplicationStateActionDispatcher(this);

    handleFirstWarningClose(){
        Logger.startBlock("hwStammdatensammlerFenster.handleFirstWarningClose")();

        this.io_Dispatcher.dispatch(
            ActionCreator.setWarningFalse(
                'First'
            )
        );

        Logger.endBlock()();
    }

    handleSecondWarningClose(){
        Logger.startBlock("hwStammdatensammlerFenster.handleSecondWarningClose")();

        this.io_Dispatcher.dispatch(
            ActionCreator.setWarningFalse(
                'Second'
            )
        );

        Logger.endBlock()();
    }

    //Expand or Collapse All actions
    handleOpenAll() {
        this.io_Dispatcher.dispatch(
            ActionCreator.setActiveSectionsAll(
                ''+this.screen.key
            )
        );
    }

    handleCollapseAll() {
        this.io_Dispatcher.dispatch(
            ActionCreator.setActiveSectionsEmpty(
                ''+this.screen.key
            )
        );
    }

    get isLocked(){
        return this.screen.isLocked || this.isFactsLocked;
    }

    get isFactsLocked(){
        return this.isFactsSent && (this.index === 0 || this.index === 1 || this.index === 3  );
    }

    get isMAEFOnly(){
        return this.isExistingMaef === true;
    }
}