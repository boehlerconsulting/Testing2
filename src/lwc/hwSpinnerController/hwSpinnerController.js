/**
 * Created by oliverpreuschl on 2019-02-26.
 */

const showSpinner = ( po_Caller ) => {
    const lc_Spinner = po_Caller.template.querySelector( "c-hw-spinner" );
    if ( lc_Spinner !== undefined && lc_Spinner !== null ) {
        lc_Spinner.showSpinner();
    } else {
        po_Caller.dispatchEvent( new CustomEvent( "hwshowspinner",
            {
                bubbles:  true,
                composed: true
            } ) );
    }
};

const hideSpinner = ( po_Caller ) => {
    const lc_Spinner = po_Caller.template.querySelector( "c-hw-spinner" );
    if ( lc_Spinner !== undefined && lc_Spinner !== null ) {
        lc_Spinner.hideSpinner();
    } else {
        po_Caller.dispatchEvent( new CustomEvent( "hwhidespinner",
            {
                bubbles:  true,
                composed: true
            } ) );
    }
};

export {
    showSpinner,
    hideSpinner
};