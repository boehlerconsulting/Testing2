/**
 *@author       Mats Böhler
 *@created      01.04.2021
 *
 *
 *@description  einrichtungsprozessNachbesserung
 *
 *
 *@changelog    01.04.2021 Mats Böhler - Created
 *
 *
 */

import {LightningElement, api, track, wire} from "lwc";
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import triggerNachbesserung from '@salesforce/apex/EinrichtungsprozessCtrl.triggerNachbesserung';
import triggerNachbesserungErsatz from '@salesforce/apex/EinrichtungsprozessCtrl.triggerNachbesserungErsatz';
import triggerNachbesserungZusatz from '@salesforce/apex/EinrichtungsprozessCtrl.triggerNachbesserungZusatz';
import triggerNachbesserungAbbau from '@salesforce/apex/EinrichtungsprozessCtrl.triggerNachbesserungAbbau';
import {NavigationMixin} from 'lightning/navigation';

export default class EinrichtungsprozessNachbesserung extends NavigationMixin(LightningElement) {

    @api accountId;
    @api einrichtungsprozessId;
    @api isErsatz = false;
    @api isZusatz = false;
    @api isErsatzZusatz = false;
    @api isAbbau = false;
    @track beschreibungNachbesserung = '';
    @track isSaving = false;
    @track showSpinner = false;

    @track showNachbesserung = false;

    handleShowNachbesserung() {

        this.showNachbesserung = true;
    }

    closeNachbesserung() {

        this.showNachbesserung = false;
    }

    handleNachbesserungChange(event) {
        this.beschreibungNachbesserung = event.target.value;
    }

    handleNachbesserungClick() {

        if (this.beschreibungNachbesserung === '') {
            const evt = new ShowToastEvent({
                title: 'Fehler!',
                message: 'Bitte geben Sie eine Beschreibung für die Nachbesserung ein.',
                variant: 'error'
            });
            this.dispatchEvent(evt);
            return;
        }

        this.isSaving = true;
        this.showSpinner = true;

        if (this.isErsatzZusatz && this.isErsatz) {
            triggerNachbesserungErsatz({
                accountId: this.accountId,
                einrichtungsprozessId: this.einrichtungsprozessId,
                beschreibung: this.beschreibungNachbesserung
            })
                .then(result => {

                    this.nachbesserungProcesses()
                })
                .catch(error => {
                    this.dispatchErrorToast(error);
                });
        } else if (this.isErsatzZusatz && this.isZusatz) {
            triggerNachbesserungZusatz({
                accountId: this.accountId,
                einrichtungsprozessId: this.einrichtungsprozessId,
                beschreibung: this.beschreibungNachbesserung
            })
                .then(result => {

                    this.nachbesserungProcesses()
                })
                .catch(error => {
                    this.dispatchErrorToast(error);
                });
        } else if (this.isAbbau) {
            triggerNachbesserungAbbau({
                accountId: this.accountId,
                einrichtungsprozessId: this.einrichtungsprozessId,
                beschreibung: this.beschreibungNachbesserung
            })
                .then(result => {

                    this.nachbesserungProcesses()
                })
                .catch(error => {
                    this.dispatchErrorToast(error);
                });
        } else {
            triggerNachbesserung({
                accountId: this.accountId,
                einrichtungsprozessId: this.einrichtungsprozessId,
                beschreibung: this.beschreibungNachbesserung
            })
                .then(result => {

                    this.nachbesserungProcesses()
                })
                .catch(error => {
                    this.dispatchErrorToast(error);
                });
        }
    }

    nachbesserungProcesses() {
        const evt = new ShowToastEvent({
            title: 'Erfolg!',
            message: 'Der Vertriebsmanager wurde zur Nachbesserung aufgefordert.',
            variant: 'success'
        });
        this.dispatchEvent(evt);
        this.dispatchEvent(
            new CustomEvent('refresh')
        );
        this.isSaving = false;
        this.showSpinner = false;
        this.showNachbesserung = false;
    }

    dispatchErrorToast(error) {

        const evt = new ShowToastEvent({
            title: error.statusText ? error.statusText : 'Error',
            message: error.body ? error.body.message : 'Something went wrong.',
            variant: 'error',
            mode: 'sticky'
        });
        this.dispatchEvent(evt);
        this.showSpinner = false;
        this.isSaving = false;
    }
}