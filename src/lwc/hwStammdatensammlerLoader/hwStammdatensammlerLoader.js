/**
 * @author      Stefan Richter (stefan.richter@hundw.de)
 *              H+W CONSULT GmbH
 *              Bahnhofstr. 3
 *              21244 Buchholz i. d. Nordheide
 *              Germany
 *              https://www.hundw.de
 *
 * @description class for <insert-description-here>
 *
 * TIMELINE
 * 17.02.21      Stefan Richter  Initial release.
 **/
import {api, LightningElement, track} from 'lwc';
import isSDSInitialized from '@salesforce/apex/HW_Stammdatensammler_LC.isSDSInitialized';
import {ShowToastEvent} from "lightning/platformShowToastEvent";


export default class HwStammdatensammlerLoader extends LightningElement {
    @api recordId;
    @api isExistingMAEF = false;
    @api isSdsInitialized = false;
    @api isFirstLoad = false;

    @track iv_ButtonName = 'Prozess starten';

    connectedCallback() {
        isSDSInitialized({
            recordId: this.recordId
        })
            .then(result => {
                this.isSdsInitialized = result;
            })
            .catch(p_Error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: "Error initializing container component. Please contact your system administrator.",
                        message: p_Error,
                        variant: "error"
                    })
                );
            });
    }

    initProcess() {
        this.isFirstLoad = true;
        this.isSdsInitialized = true;
    }


}