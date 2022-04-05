/**
 * Created by oliverpreuschl on 2019-03-28.
 */
export default class HwApplicationState {

    //Instance Properties------------------------------------------------------------------------
    caller;
    currentAction;
    currentActionSource;
    historicizeState;
    maxStates;
    sourceActionStateHistory = [];
    currentStateIndex        = -1;
    reduce;

    //Lifecycle Hooks---------------------------------------------------------------------------
    constructor( caller,
        reduce,
        { historicizeState, maxStates } = {
            historicizeState: false,
            maxStates:        10000
        } ) {

        this.caller           = caller;
        this.reduce           = reduce;
        this.historicizeState = historicizeState;
        this.maxStates        = maxStates;
        if ( this.historicizeState === undefined || this.historicizeState === null ) {
            this.historicizeState = false;
        }
        if ( !this.maxStates ) {
            this.maxStates = 10000;
        }

        this.addCurrentSourceActionStateToHistory();
        caller.addEventListener( "hwdispatch", this.handleEvent_HwDispatch.bind( this ) );
    }

    //Instance Methods-------------------------------------------------------------------------
    getCurrentStateClone() {
        return { ...this.caller.state };
    }

    addCurrentSourceActionStateToHistory() {
        if ( this.currentStateIndex < this.maxStates ) {
            this.setCurrentStateIndex( this.currentStateIndex + 1 );
        }
        this.cleanupFutureStates();
        this.sourceActionStateHistory.push( {
            source: this.currentActionSource,
            action: this.currentAction,
            state:  this.caller.state
        } );
        this.cleanupSavedStates();
    }

    setCurrentStateIndex( stateIndex ) {
        this.currentStateIndex = stateIndex;
    }

    cleanupSavedStates() {
        if ( ( this.maxStates !== -1 ) && ( this.sourceActionStateHistory.length > this.maxStates ) ) {
            this.deleteEarliestSavedState();
        }
    }

    cleanupFutureStates() {
        if ( this.sourceActionStateHistory.length > ( this.currentStateIndex + 1 ) ) {
            const numberOfDeprectedFutureStates = this.sourceActionStateHistory.length - ( this.currentStateIndex );
            for ( let i = 1; i <= numberOfDeprectedFutureStates; i++ ) {
                this.deleteLatestSavedState();
            }
        }
    }

    deleteEarliestSavedState() {
        this.sourceActionStateHistory.shift();
    }

    deleteLatestSavedState() {
        this.sourceActionStateHistory.pop();
    }

    //Event Handlers---------------------------------------------------------------------------
    handleEvent_HwDispatch( dispatch ) {
        const srcElement          = dispatch.path ? dispatch.path[ 0 ].localName : null;
        const currentState        = this.getCurrentStateClone();
        const actionConfiguration = dispatch.detail;

        let actionSkipped = false;
        if ( actionConfiguration.type === "action" ) {
            this.reduce( currentState, actionConfiguration.action, this.caller );
        } else if ( actionConfiguration.type === "function" ) {
            const action = actionConfiguration.actionFunction( currentState );
            if ( action ) {
                this.reduce( currentState, action, this.caller );
            } else {
                actionSkipped = true;
            }
        }

        if ( !actionSkipped ) {
            this.caller.state     = currentState;
            this.currentAction       = actionConfiguration.action;
            this.currentActionSource = srcElement;
            if ( this.historicizeState ) {
                this.addCurrentSourceActionStateToHistory();
            }
        }
    }
}