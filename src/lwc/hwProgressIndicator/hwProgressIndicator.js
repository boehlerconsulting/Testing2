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
import {LightningElement, api, track} from "lwc";
import { NavigationMixin } from 'lightning/navigation';
import HwApplicationStateActionDispatcher from "c/hwApplicationStateActionDispatcher";
import * as ActionCreator from "c/hwStammdatensammlerActionCreator";

export default class HW_ProgressIndicator extends NavigationMixin(LightningElement) {

    @api steps;
    @track activeStepIndex = 0;

    io_Dispatcher = new HwApplicationStateActionDispatcher(this);

    renderedCallback() {
        this.calculateProgressValueWidth();
    }

    calculateProgressValueWidth() {
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
    }

    handleChange(event) {
        let lv_ActiveIndex = event.target.name ? event.target.name : event.target.alternativeText;
        if (lv_ActiveIndex !== undefined){
            this.io_Dispatcher.dispatch(
                ActionCreator.setSteps(
                    lv_ActiveIndex
                )
            );
        }
    }

    handlePrevious(){
        this.io_Dispatcher.dispatch(
            ActionCreator.setSteps(
                this.activeStepIndex - 1
            )
        );
    }

    handleNext(){
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