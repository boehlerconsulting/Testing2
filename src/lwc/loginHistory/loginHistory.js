/**
 *@author       Mats Böhler
 *@created      10.02.2022
 *
 *
 *@description  loginHistory
 *
 *
 *@changelog    10.02.2022 Mats Böhler - Created
 *
 *
 */

import {LightningElement} from 'lwc';
import loadData from '@salesforce/apex/LoginHistoryCtrl.loadData';
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import {reduceErrors} from 'c/errorHandler';

export default class LoginHistory extends LightningElement {

    showSpinner = true;
    instance;

    connectedCallback() {
        this.loadData();
    }

    loadData() {
        loadData({})
            .then(result => {
                this.instance = JSON.parse(result);
                this.showSpinner = false;
            })
            .catch(error => {
                this.error = error;
                const evt = new ShowToastEvent({
                    title: 'Error',
                    message: reduceErrors(error)[0],
                    variant: 'error',
                    mode: 'sticky'
                });
                this.dispatchEvent(evt);
                this.showSpinner = false;
            });
    }
}