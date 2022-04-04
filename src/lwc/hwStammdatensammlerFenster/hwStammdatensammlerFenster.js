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
import {LightningElement, api} from "lwc";
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
        this.io_Dispatcher.dispatch(
            ActionCreator.setWarningFalse(
                'First'
            )
        );
    }

    handleSecondWarningClose(){
        this.io_Dispatcher.dispatch(
            ActionCreator.setWarningFalse(
                'Second'
            )
        );
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
        return !this.isMAEFOnly && (this.screen.isLocked || this.isFactsLocked);
    }

    get isFactsLocked(){
        return this.isFactsSent && (this.index === 0 || this.index === 1 || this.index === 3  );
    }

    get isMAEFOnly(){
        return this.isExistingMaef === true;
    }
}