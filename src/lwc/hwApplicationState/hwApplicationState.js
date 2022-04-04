/**
 * Created by oliverpreuschl on 2019-03-28.
 */
export default class HwApplicationState {

    //Instance Properties------------------------------------------------------------------------
    io_Caller;
    io_CurrentAction;
    iv_CurrentActionSource;
    iv_HistoricizeState;
    iv_MaxStates;
    il_SourceActionStateHistory = [];
    iv_CurrentStateIndex        = -1;
    if_Reduce;


    //Lifecycle Hooks---------------------------------------------------------------------------
    constructor( po_Caller,
        pf_reduce,
        { historicizeState, maxStates } = {
            historicizeState: false,
            maxStates:        10000
        } ) {

        this.io_Caller           = po_Caller;
        this.if_Reduce           = pf_reduce;
        this.iv_HistoricizeState = historicizeState;
        this.iv_MaxStates        = maxStates;
        if ( this.iv_HistoricizeState === undefined || this.iv_HistoricizeState === null ) {
            this.iv_HistoricizeState = false;
        }
        if ( !this.iv_MaxStates ) {
            this.iv_MaxStates = 10000;
        }

        this.addCurrentSourceActionStateToHistory();
        po_Caller.addEventListener( "hwdispatch", this.handleEvent_HwDispatch.bind( this ) );
    }


    //Instance Methods-------------------------------------------------------------------------
    getCurrentStateClone() {
        return { ...this.io_Caller.io_State };
    }

    addCurrentSourceActionStateToHistory() {
        if ( this.iv_CurrentStateIndex < this.iv_MaxStates ) {
            this.setCurrentStateIndex( this.iv_CurrentStateIndex + 1 );
        }
        this.cleanupFutureStates();
        this.il_SourceActionStateHistory.push( {
            source: this.iv_CurrentActionSource,
            action: this.io_CurrentAction,
            state:  this.io_Caller.io_State
        } );
        this.cleanupSavedStates();
    }

    setCurrentStateIndex( pv_StateIndex ) {
        this.iv_CurrentStateIndex = pv_StateIndex;
    }

    cleanupSavedStates() {
        if ( ( this.iv_MaxStates !== -1 ) && ( this.il_SourceActionStateHistory.length > this.iv_MaxStates ) ) {
            this.deleteEarliestSavedState();
        }
    }

    cleanupFutureStates() {
        if ( this.il_SourceActionStateHistory.length > ( this.iv_CurrentStateIndex + 1 ) ) {
            const lv_NumberOfDeprectedFutureStates = this.il_SourceActionStateHistory.length - ( this.iv_CurrentStateIndex );
            for ( let i = 1; i <= lv_NumberOfDeprectedFutureStates; i++ ) {
                this.deleteLatestSavedState();
            }
        }
    }

    deleteEarliestSavedState() {
        this.il_SourceActionStateHistory.shift();
    }

    deleteLatestSavedState() {
        this.il_SourceActionStateHistory.pop();
    }

    getNumberOfSavedStates() {
        return this.il_SourceActionStateHistory.length;
    }

    getCurrentStateIndex() {
        return this.iv_CurrentStateIndex;
    }

    isPreviousStateAvailable() {
        return ( this.iv_CurrentStateIndex > 0 );
    }

    isNextStateAvailable() {
        return ( this.iv_CurrentStateIndex < ( this.getNumberOfSavedStates() - 1 ) );
    }

    switchToPreviousState() {
        if ( this.iv_CurrentStateIndex > 0 ) {
            this.setCurrentStateIndex( this.iv_CurrentStateIndex - 1 );
        }
        this.loadStateFromHistory( this.iv_CurrentStateIndex );
    }

    switchToNextState() {
        if ( this.iv_CurrentStateIndex < ( this.getNumberOfSavedStates() - 1 ) ) {
            this.setCurrentStateIndex( this.iv_CurrentStateIndex + 1 );
        }
        this.loadStateFromHistory( this.iv_CurrentStateIndex );
    }

    loadStateFromHistory(  ) {
        this.iv_CurrentActionSource = this.il_SourceActionStateHistory[ this.iv_CurrentStateIndex ].source;
        this.io_CurrentAction       = this.il_SourceActionStateHistory[ this.iv_CurrentStateIndex ].action;
        this.io_Caller.io_State     = this.il_SourceActionStateHistory[ this.iv_CurrentStateIndex ].state;
    }


    //Event Handlers---------------------------------------------------------------------------
    handleEvent_HwDispatch( pe_Dispatch ) {
        const lv_SrcElement          = pe_Dispatch.path ? pe_Dispatch.path[ 0 ].localName : null;
        const lo_CurrentState        = this.getCurrentStateClone();
        const lo_ActionConfiguration = pe_Dispatch.detail;

        let lv_ActionSkipped = false;
        if ( lo_ActionConfiguration.type === "action" ) {
            this.if_Reduce( lo_CurrentState, lo_ActionConfiguration.action, this.io_Caller );
        } else if ( lo_ActionConfiguration.type === "function" ) {
            const lo_Action = lo_ActionConfiguration.actionFunction( lo_CurrentState );
            if ( lo_Action ) {
                this.if_Reduce( lo_CurrentState, lo_Action, this.io_Caller );
            } else {
                lv_ActionSkipped = true;
            }
        }

        if ( !lv_ActionSkipped ) {
            this.io_Caller.io_State     = lo_CurrentState;
            this.io_CurrentAction       = lo_ActionConfiguration.action;
            this.iv_CurrentActionSource = lv_SrcElement;
            if ( this.iv_HistoricizeState ) {
                this.addCurrentSourceActionStateToHistory();
            }
        }
    }
}