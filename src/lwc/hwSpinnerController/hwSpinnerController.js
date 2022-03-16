/**
 * Created by oliverpreuschl on 2019-02-26.
 */

import * as Logger from "c/hwLogger";

const showSpinner = ( po_Caller ) => {
    Logger.startFrameworkBlock( "Hw_SpinnerController.showSpinner" )();

    const lc_Spinner = po_Caller.template.querySelector( "c-hw-spinner" );
    if ( lc_Spinner !== undefined && lc_Spinner !== null ) {
        lc_Spinner.showSpinner();
    } else {
        Logger.logFrameworkEvent( "showSpinner" )();
        po_Caller.dispatchEvent( new CustomEvent( "hwshowspinner",
            {
                bubbles:  true,
                composed: true
            } ) );
    }

    Logger.endFrameworkBlock()();
};

const hideSpinner = ( po_Caller ) => {
    Logger.startFrameworkBlock( "Hw_SpinnerController.hideSpinner" )();

    const lc_Spinner = po_Caller.template.querySelector( "c-hw-spinner" );
    if ( lc_Spinner !== undefined && lc_Spinner !== null ) {
        lc_Spinner.hideSpinner();
    } else {
        Logger.logFrameworkEvent( "hideSpinner" )();
        po_Caller.dispatchEvent( new CustomEvent( "hwhidespinner",
            {
                bubbles:  true,
                composed: true
            } ) );
    }

    Logger.endFrameworkBlock()();
};

export {
    showSpinner,
    hideSpinner
};