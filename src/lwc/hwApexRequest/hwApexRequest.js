/**
 * Created by oliverpreuschl on 2019-01-21.
 */

import {hideSpinner, showSpinner} from "c/hwSpinnerController";
import {ShowToastEvent} from "lightning/platformShowToastEvent";

export default class HwApexRequest {

    caller;
    method;
    methodName;
    parameters;
    config = {
        showSpinner: true,
        showErrorMessage: true,
        showSuccessMessage: true,
        successMessage: "Success"
    };

    constructor(caller) {
        this.caller = caller;
    }

    setMethod(method) {
        this.method = method;
        return this;
    }

    getMethod() {
        return this.method;
    }

    setMethodName(methodName) {
        this.methodName = methodName;
        return this;
    }

    setParameters(parameters) {
        this.parameters = parameters;
        return this;
    }

    setConfig({showSpinner, showErrorMessage, showSuccessMessage, successMessage}) {
        if (showSpinner !== undefined && showSpinner !== null) {
            this.config.showSpinner = showSpinner;
        }
        if (showErrorMessage !== undefined && showErrorMessage !== null) {
            this.config.showErrorMessage = showErrorMessage;
        }
        if (showSuccessMessage !== undefined && showSuccessMessage !== null) {
            this.config.showSuccessMessage = showSuccessMessage;
        }
        if (successMessage !== undefined && successMessage !== null) {
            this.config.successMessage = successMessage;
        }
        return this;
    }

    execute() {
        return new Promise(
            function (resolve, reject) {
                try {
                    if (this.config.showSpinner) {
                        showSpinner(this.caller);
                    }
                    this.callApexMethod(resolve, reject);
                } catch (e) {
                    this.showError(e.message);
                    reject(e.message);
                }
            }.bind(this)
        );
    }

    callApexMethod(resolve, reject) {
        this.method(this.parameters)
            .then(result => {
                hideSpinner(this.caller);
                this.showApexSuccess(this.config.successMessage, result);
                resolve(result);
            })
            .catch(error => {
                hideSpinner(this.caller);
                this.showApexError(error);
                reject(error);
            });
    }

    showError(errorMessage) {
        if (this.config.showErrorMessage) {
            this.caller.dispatchEvent(new ShowToastEvent({
                title: "Error",
                message: errorMessage,
                variant: "error"
            }));
        }
    }

    showApexError(error) {
        if (this.config.showErrorMessage) {
            this.caller.dispatchEvent(new ShowToastEvent({
                title: "Error",
                message: error,
                variant: "error"
            }));
        }
    }

    showApexSuccess(successMessage) {
        if (this.config.successMessage && this.config.showSuccessMessage) {
            this.caller.dispatchEvent(new ShowToastEvent({
                title: "Success",
                message: successMessage,
                variant: "success"
            }));
        }
    }
}