/**
 * Created by oliverpreuschl on 2019-02-26.
 */

import { LightningElement, api, track } from "lwc";

export default class HwSpinner extends LightningElement {

    @api size    = "medium";
    @api variant = "base";

    @track iv_ShowSpinner;

    iv_SpinnerCounter = 0;


    @api
    init( po_Caller ) {
        po_Caller.addEventListener( "hwshowspinner", this.handleHwShowSpinner.bind( this ) );
        po_Caller.addEventListener( "hwhidespinner", this.handleHwHideSpinner.bind( this ) );
    }

    handleHwShowSpinner() {
        this.showSpinner();
    }

    handleHwHideSpinner() {
        this.hideSpinner();
    }

    @api
    showSpinner() {
        this.iv_SpinnerCounter++;
        this.calculateVisibility();
    }

    @api
    hideSpinner() {
        if ( this.iv_SpinnerCounter > 0 ) {
            this.iv_SpinnerCounter--;
            this.calculateVisibility();
        }
    }

    calculateVisibility() {
        this.iv_ShowSpinner = this.iv_SpinnerCounter > 0;
    }
}