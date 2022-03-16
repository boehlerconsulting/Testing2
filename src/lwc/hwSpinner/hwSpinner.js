/**
 * Created by oliverpreuschl on 2019-02-26.
 */

import { LightningElement, api, track } from "lwc";
import * as Logger from "c/hwLogger";

export default class HwSpinner extends LightningElement {

    @api size    = "medium";
    @api variant = "base";

    @track iv_ShowSpinner;

    iv_SpinnerCounter = 0;


    @api
    init( po_Caller ) {
        Logger.startFrameworkBlock( "HwSpinner.init" )();

        po_Caller.addEventListener( "hwshowspinner", this.handleHwShowSpinner.bind( this ) );
        po_Caller.addEventListener( "hwhidespinner", this.handleHwHideSpinner.bind( this ) );

        Logger.endFrameworkBlock()();
    }

    handleHwShowSpinner() {
        Logger.startFrameworkBlock( "HwSpinner.handleHwShowSpinner" )();

        this.showSpinner();

        Logger.endFrameworkBlock()();
    }

    handleHwHideSpinner() {
        Logger.startFrameworkBlock( "HwSpinner.handleHwHideSpinner" )();

        this.hideSpinner();

        Logger.endFrameworkBlock()();
    }

    @api
    showSpinner() {
        Logger.startFrameworkBlock( "HwSpinner.showSpinner" )();

        this.iv_SpinnerCounter++;
        this.calculateVisibility();

        Logger.endFrameworkBlock()();
    }

    @api
    hideSpinner() {
        Logger.startFrameworkBlock( "HwSpinner.hideSpinner" )();

        if ( this.iv_SpinnerCounter > 0 ) {
            this.iv_SpinnerCounter--;
            this.calculateVisibility();
        }

        Logger.endFrameworkBlock()();
    }

    calculateVisibility() {
        Logger.startFrameworkBlock( "HwSpinner.calculateVisibility" )();

        if ( this.iv_SpinnerCounter > 0 ) {
            this.iv_ShowSpinner = true;
        } else {
            this.iv_ShowSpinner = false;
        }
        Logger.logFramework( "SpinnerCounter: " + this.iv_SpinnerCounter )();

        Logger.endFrameworkBlock()();
    }

}