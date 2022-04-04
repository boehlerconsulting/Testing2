/**
 * Created by oliverpreuschl on 2019-01-21.
 */

import { showSpinner, hideSpinner } from "c/hwSpinnerController";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

export default class HwApexRequest {

    io_Caller;
    if_Method;
    iv_MethodName;
    io_Parameters;
    io_Config = {
        iv_ShowSpinner:      true,
        iv_ShowErrorMessage: true,
        iv_ShowSuccessMessage: true,
        iv_SuccessMessage:   "Success"
    };
    iv_RequestNumber;

    constructor( po_Caller ) {
        this.io_Caller = po_Caller;
    }

    setMethod( pf_Method ) {
        this.if_Method = pf_Method;
        return this;
    }

    getMethod( ) {
        return this.if_Method;
    }

    setMethodName( pv_MethodName ) {
        this.iv_MethodName = pv_MethodName;
        return this;
    }

    setParameters( po_Parameters ) {
        this.io_Parameters = po_Parameters;
        return this;
    }

    setConfig( { showSpinner, showErrorMessage, showSuccessMessage, successMessage } ) {
        if ( showSpinner !== undefined && showSpinner !== null ) {
            this.io_Config.iv_ShowSpinner = showSpinner;
        }
        if ( showErrorMessage !== undefined && showErrorMessage !== null ) {
            this.io_Config.iv_ShowErrorMessage = showErrorMessage;
        }
        if ( showSuccessMessage !== undefined && showSuccessMessage !== null ) {
            this.io_Config.iv_ShowSuccessMessage = showSuccessMessage;
        }
        if ( successMessage !== undefined && successMessage !== null ) {
            this.io_Config.iv_SuccessMessage = successMessage;
        }
        return this;
    }

    execute() {
        var lo_Promise = new Promise(
            function ( pf_Resolve, pf_Reject ) {
                try {
                    if ( this.io_Config.iv_ShowSpinner ) {
                        showSpinner( this.io_Caller );
                    }
                    this.callApexMethod( pf_Resolve, pf_Reject );
                } catch ( e ) {
                    this.showError( e.message );
                    pf_Reject( e.message );
                }
            }.bind( this )
        );
        return lo_Promise;
    };

    callApexMethod( pf_Resolve, pf_Reject ) {
        this.if_Method( this.io_Parameters )
            .then( p_Result => {
                hideSpinner( this.io_Caller );
                this.showApexSuccess( this.io_Config.iv_SuccessMessage, p_Result );
                pf_Resolve( p_Result );
            } )
            .catch( po_Error => {
                hideSpinner( this.io_Caller );
                this.showApexError( po_Error );
                pf_Reject( po_Error );
            } );
    }

    showError( pv_ErrorMessage ) {
        if ( this.io_Config.iv_ShowErrorMessage ) {
            const le_Toast = new ShowToastEvent( {
                title:   "Error",
                message: pv_ErrorMessage,
                variant: "error"
            } );
            this.io_Caller.dispatchEvent( le_Toast );
        }
    }

    showApexError( po_Error ) {
        if ( this.io_Config.iv_ShowErrorMessage ) {
            const le_Toast = new ShowToastEvent( {
                title:   "Error",
                message: po_Error,
                variant: "error"
            } );
            this.io_Caller.dispatchEvent( le_Toast );
        }
    }

    showApexSuccess( pv_SuccessMessage, p_Data ) {
        if ( this.io_Config.iv_SuccessMessage && this.io_Config.iv_ShowSuccessMessage ) {
            const le_Toast = new ShowToastEvent( {
                title:   "Success",
                message: pv_SuccessMessage,
                variant: "success"
            } );
            this.io_Caller.dispatchEvent( le_Toast );
        }
    }

}