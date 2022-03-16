/**
 *@author       Mats Böhler
 *@created      03.04.2019
 *@version      1.0
 *@since        45.0
 *
 *
 *@description  hwProgressIndicator
 *
 *
 *@changelog    03.04.2019 Mats Böhler - Created
 *
 *
 */

//LWC
import {LightningElement, api, track, wire} from "lwc";
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import { NavigationMixin } from 'lightning/navigation';

//Custom Javascript
import * as Logger from "c/hwLogger";
import {showSpinner, hideSpinner} from "c/hwSpinnerController";

import HwApplicationState from "c/hwApplicationState";
import HwApplicationStateActionDispatcher from "c/hwApplicationStateActionDispatcher";
import * as ActionCreator from "c/hwStammdatensammlerActionCreator";
import {reduce} from "c/hwStammdatensammlerReducer";

//Apex
import {refreshApex} from "@salesforce/apex";

export default class HW_ProgressIndicator extends NavigationMixin(LightningElement) {

    @api steps;
    @track activeStepIndex = 0;

    io_Dispatcher = new HwApplicationStateActionDispatcher(this);

    renderedCallback() {
        Logger.startBlock("hwProgressIndicator.renderedCallback")();

        this.calculateProgressValueWidth();

        Logger.endBlock()();
    }

    calculateProgressValueWidth() {
        Logger.startBlock("hwProgressIndicator.calculateProgressValueWidth")();

        let lv_ActiveStepIndex;
        for (let i = 0; i < this.steps.length; i++) {
            let lo_Step = this.steps[i];
            if (lo_Step.isActive || lo_Step.isDoneAndActive) {
                lv_ActiveStepIndex = i;
            }
        }
        if (!lv_ActiveStepIndex) {
            lv_ActiveStepIndex = 0;
        }
        this.activeStepIndex = lv_ActiveStepIndex;
        this.template.querySelector(".slds-progress-bar__value").style.width =
            `${100 / (this.steps.length - 1) * (lv_ActiveStepIndex)}%`;

        Logger.endBlock()();
    }

    handleChange(event) {
        Logger.startBlock("hwProgressIndicator.handleChange")();

        let lv_ActiveIndex = event.target.name ? event.target.name : event.target.alternativeText;

        if (lv_ActiveIndex !== undefined){

            this.io_Dispatcher.dispatch(
                ActionCreator.setSteps(
                    lv_ActiveIndex
                )
            );


        }

        Logger.endBlock()();
    }

    handlePrevious(event){
        this.io_Dispatcher.dispatch(
            ActionCreator.setSteps(
                this.activeStepIndex - 1
            )
        );
    }

    handleNext(event){
        this.io_Dispatcher.dispatch(
            ActionCreator.setSteps(
                this.activeStepIndex + 1
            )
        );
    }

    get showBackButton(){
        return this.activeStepIndex !== 0;
    }

    get showNextButton(){
        return this.activeStepIndex < this.steps.length - 1;
    }
}