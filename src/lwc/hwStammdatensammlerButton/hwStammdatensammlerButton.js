/**
 *@author       Mats Böhler
 *@created      22.04.2019
 *@version      1.0
 *@since        45.0
 *
 *
 *@description  hwStammdatensammlerButton
 *
 *
 *@changelog    22.04.2019 Mats Böhler - Created
 *
 *
 */

//LWC
import {LightningElement, api, track} from "lwc";
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import {NavigationMixin} from 'lightning/navigation';
import validateAstId from '@salesforce/apex/HW_Stammdatensammler_LC.validateAstId';
import getDocumentUrl from '@salesforce/apex/HW_Stammdatensammler_LC.getDocumentUrl';
import saveDocument from '@salesforce/apex/HW_Stammdatensammler_LC.saveDocument';
import HwApplicationStateActionDispatcher from "c/hwApplicationStateActionDispatcher";
import * as ActionCreator from "c/hwStammdatensammlerActionCreator";

export default class HW_StammdatensammlerButton extends NavigationMixin(LightningElement) {

    @api button;
    @api recordId;
    @api screenLocked;
    @api screen;
    @api isExistingMaef;
    @track isLoading = false;

    io_Dispatcher = new HwApplicationStateActionDispatcher(this);

    setStepDone() {
        this.io_Dispatcher.dispatch(
            ActionCreator.setStepDone(
                this.screen.position
            )
        );
    }

    handleDocumentCreation() {
        let lo_Button = this.button;
        if (!this.showSpinner && !this.isLoading) {

            if (lo_Button.iv_VisualforceName === 'HW_MAEF') {

                validateAstId({
                    recordId: this.recordId
                })
                    .then(result => {

                        if (result === '') {
                            this.generateDocuments();
                        } else {
                            this.dispatchEvent(
                                new ShowToastEvent({
                                    title: 'Fehler!',
                                    message: `Die Ast-ID "${result}" existiert bereits. Bitte korrigieren Sie die Eingabe.`,
                                    variant: 'error',
                                    mode: 'sticky'
                                }));
                        }
                    })
                    .catch(error => {

                        const evt = new ShowToastEvent({
                            title: error.statusText,
                            message: error.body.message,
                            variant: 'error',
                            mode: 'sticky'
                        });
                        this.dispatchEvent(evt);
                    });
            } else {
                this.generateDocuments();
            }
        }
    }

    generateDocuments() {
        this.isLoading = true;
        let lo_Button = this.button;
        if (lo_Button.iv_isPreview) {

            getDocumentUrl({
                recordId: this.recordId,
                visualforceName: lo_Button.iv_VisualforceName,
                dataType: lo_Button.iv_DataType,
                isLaufenderBetrieb: this.isExistingMaef
            })
                .then(url => {
                    window.open(url, '_blank');
                    this.isLoading = false;
                })
                .catch(error => {

                    const evt = new ShowToastEvent({
                        title: error.statusText,
                        message: error.body.message,
                        variant: 'error',
                        mode: 'sticky'
                    });
                    this.dispatchEvent(evt);
                });
            this.isLoading = false;
        } else {

            saveDocument({
                recordId: this.recordId,
                visualforceName: lo_Button.iv_VisualforceName,
                dataType: lo_Button.iv_DataType,
                isLaufenderBetrieb: this.isExistingMaef
            })
                .then(url => {
                    this.io_Dispatcher.dispatch(
                        ActionCreator.setButtonDisable(
                            lo_Button
                        )
                    );
                    const evt = new ShowToastEvent({
                        title: 'Erfolg!',
                        message: 'Das Dokument wurde erfolgreich generiert.',
                        variant: 'success'
                    });
                    this.dispatchEvent(evt);
                    this.isLoading = false;
                })
                .catch(error => {

                    const evt = new ShowToastEvent({
                        title: error.statusText,
                        message: error.body.message,
                        variant: 'error',
                        mode: 'sticky'
                    });
                    this.dispatchEvent(evt);
                    this.isLoading = false;
                });
        }

    }

    get hideButton() {
        return this.button.isHidden;
    }

    get disableButton() {
        if (this.isExistingMaef){
            return this.button.isDisabled || this.disabled;
        }
        else{
            return this.button.isDisabled || this.screenLocked;
        }
    }

    get showSpinner() {

        return this.button.showSpinner || this.isLoading;
    }

    get isZuverlaessigkeitspruefung() {
        return this.button.iv_VisualforceName === 'HW_Zuverlaessigkeitspruefung';
    }
}