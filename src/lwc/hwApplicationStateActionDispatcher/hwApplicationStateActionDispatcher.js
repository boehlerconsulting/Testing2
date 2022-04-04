/**
 * Created by oliverpreuschl on 2019-03-28.
 */

export default class HwApplicationStateActionDispatcher {

    io_Caller;

    constructor( po_Caller ) {
        this.io_Caller = po_Caller;
    }

    dispatch( po_ActionOrActionFunction ) {

        let lo_Action;
        let lo_ActionConfiguration;
        if ( typeof po_ActionOrActionFunction !== "function" ) {
            lo_Action              = { ...po_ActionOrActionFunction };
            lo_ActionConfiguration = {
                type:   "action",
                action: lo_Action
            };
        } else {
            lo_ActionConfiguration = {
                type:           "function",
                actionFunction: po_ActionOrActionFunction
            };
        }
        const le_Dispatch = new CustomEvent( "hwdispatch",
            {
                detail:   lo_ActionConfiguration,
                bubbles:  true,
                composed: true
            } );
        this.io_Caller.dispatchEvent( le_Dispatch, lo_Action );
    };

}