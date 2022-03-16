/**
 * Created by oliverpreuschl on 2019-01-21.
 */

var LoggingLevel = Object.freeze( {
    DEBUG:   10,
    WARNING: 20,
    ERROR:   30,
    NONE:    40
} );

var DataLoggingLevel = Object.freeze( {
    ON:  1,
    OFF: 2
} );

var FrameworkLoggingLevel = Object.freeze( {
    ON:  1,
    OFF: 2
} );

var LogType = Object.freeze( {
    Standard:    11,
    Success:     12,
    ApexSuccess: 13,
    ApexRequest: 14,
    Event:       15,
    Warning:     21,
    Error:       31,
    ApexError:   32
} );

const sv_Settings = {
    sv_LoggingLevel:          LoggingLevel.DEBUG,
    sv_DataLoggingLevel:      DataLoggingLevel.ON,
    sv_FrameworkLoggingLevel: FrameworkLoggingLevel.OFF
};

const setLoggingLevel = ( pv_LoggingLevel, pv_DataLogginLevel = DataLoggingLevel.ON, pv_FrameworkLoggingLevel = FrameworkLoggingLevel.OFF ) => {
    sv_Settings.sv_LoggingLevel          = pv_LoggingLevel;
    sv_Settings.sv_DataLoggingLevel      = pv_DataLogginLevel;
    sv_Settings.sv_FrameworkLoggingLevel = pv_FrameworkLoggingLevel;
};

const getLogFormat = ( pv_LogType, pv_AdditionalStatusMessage ) => {
    var lo_Format = {
        Status: "",
        Style:  ""
    };
    if ( pv_LogType == LogType.Success ) {
        lo_Format.Status = "Success";
        lo_Format.Style  = "color: white; background-color: green; padding: 2px 6px; border-radius: 2px;";
    } else if ( pv_LogType == LogType.ApexSuccess ) {
        lo_Format.Status = "Apex-Success";
        lo_Format.Style  = "color: white; background-color: green; padding: 2px 6px; border-radius: 2px;";
    } else if ( pv_LogType == LogType.ApexRequest ) {
        lo_Format.Status = "Apex-Request";
        lo_Format.Style  = "color: white; background-color: RoyalBlue; padding: 2px 6px; border-radius: 2px;";
    } else if ( pv_LogType == LogType.Event ) {
        lo_Format.Status = "Event";
        lo_Format.Style  = "color: white; background-color: Purple; padding: 2px 6px; border-radius: 2px;";
    } else if ( pv_LogType == LogType.Warning ) {
        lo_Format.Status = "Warning";
        lo_Format.Style  = "color: white; background-color: DarkOrange; padding: 2px 6px; border-radius: 2px;";
    } else if ( pv_LogType == LogType.Error ) {
        lo_Format.Status = "Error";
        lo_Format.Style  = "color: white; background-color: FireBrick; padding: 2px 6px; border-radius: 2px;";
    } else if ( pv_LogType == LogType.ApexError ) {
        lo_Format.Status = "Apex-Error";
        lo_Format.Style  = "color: white; background-color: FireBrick; padding: 2px 6px; border-radius: 2px;";
    } else {
        lo_Format.Status = "";
        lo_Format.Style  = "color: white; background-color: SlateGray; padding: 2px 6px; border-radius: 2px;";
    }
    if ( pv_AdditionalStatusMessage !== null && pv_AdditionalStatusMessage !== undefined && pv_AdditionalStatusMessage !== "" ) {
        lo_Format.Status += " - " + pv_AdditionalStatusMessage;
    }
    return lo_Format;
};

const startBlock = ( pv_BlockName, { isFrameworkLogging } = { isFrameworkLogging: null } ) => {
    var lf_Return = () => {
    };
    if ( !isFrameworkLogging || sv_Settings.sv_FrameworkLoggingLevel === FrameworkLoggingLevel.ON ) {
        if ( sv_Settings.sv_LoggingLevel < 40 ) {
            const lo_Params = [ console, "%cMethod", "color: white; background-color: SlateGray; padding: 2px 6px; border-radius: 2px;  font-size: 10px", pv_BlockName ];
            lf_Return       = Function.prototype.bind.apply( console.group, lo_Params );
        }
    }
    return lf_Return;
};

const startFrameworkBlock = ( pv_BlockName ) => {
    return startBlock( pv_BlockName, { isFrameworkLogging: true } );
};

const endBlock = ( { isFrameworkLogging } = { isFrameworkLogging: null } ) => {
    var lf_Return = () => {
    };
    if ( !isFrameworkLogging || sv_Settings.sv_FrameworkLoggingLevel === FrameworkLoggingLevel.ON ) {
        if ( sv_Settings.sv_LoggingLevel < 40 ) {
            const lo_Params = [ console ];
            lf_Return       = Function.prototype.bind.apply( console.groupEnd, lo_Params );
        }
    }
    return lf_Return;
};

const endFrameworkBlock = () => {
    return endBlock( { isFrameworkLogging: true } );
};

const log = ( pv_Message                                            = "",
    { data, statusMessage, logType, isFrameworkLogging } = {
        data:                null,
        statusMessage:      null,
        logType:            LogType.Standard,
        isFrameworkLogging: null
    } ) => {
    var lf_Return = () => {
    };
    if ( !logType ) {
        logType = LogType.Standard;
    }
    if ( !isFrameworkLogging || sv_Settings.sv_FrameworkLoggingLevel === FrameworkLoggingLevel.ON ) {
        if ( logType >= sv_Settings.sv_LoggingLevel ) {
            var lo_Params;
            const lo_Format = getLogFormat( logType, statusMessage );
            if ( sv_Settings.sv_DataLoggingLevel === DataLoggingLevel.ON ) {
                if ( data !== null && data !== undefined && data !== "" ) {
                    lo_Params = [ console, "%c" + lo_Format.Status, lo_Format.Style, pv_Message + ": ", data ];
                } else {
                    lo_Params = [ console, "%c" + lo_Format.Status, lo_Format.Style, pv_Message ];
                }
            } else {
                lo_Params = [ console, "%c" + lo_Format.Status, lo_Format.Style, pv_Message + ": --data omitted--" ];
            }
            lf_Return = Function.prototype.bind.apply( console.log, lo_Params );
        }
    }
    return lf_Return;
};

const logFramework = ( pv_Message            = "",
    { data, statusMessage, logType } = {
        data:           null,
        statusMessage: null,
        logType:       LogType.Standard
    } ) => {
    return log( pv_Message,
        {
            data,
            statusMessage,
            logType,
            isFrameworkLogging: true
        } );
};

const logSuccess = ( pv_Message                         = "",
    { data, statusMessage, isFrameworkLogging } = {
        data:                null,
        statusMessage:      null,
        isFrameworkLogging: null
    } ) => {
    return log( pv_Message,
        {
            data,
            statusMessage,
            logType: LogType.Success,
            isFrameworkLogging
        } );
};

const logApexSuccess = ( pv_Message                     = "",
    { data, statusMessage, isFrameworkLogging } = {
        data:                null,
        statusMessage:      null,
        isFrameworkLogging: null
    } ) => {
    return log( pv_Message,
        {
            data,
            statusMessage,
            logType: LogType.ApexSuccess,
            isFrameworkLogging
        } );
};

const logApexRequest = ( pv_Message                     = "",
    { data, statusMessage, isFrameworkLogging } = {
        data:                null,
        statusMessage:      null,
        isFrameworkLogging: null
    } ) => {
    return log( pv_Message,
        {
            data,
            statusMessage,
            logType: LogType.ApexRequest,
            isFrameworkLogging
        } );
};

const logEvent = ( pv_Message                           = "",
    { data, statusMessage, isFrameworkLogging } = {
        data:                null,
        statusMessage:      null,
        isFrameworkLogging: null
    } ) => {
    return log( pv_Message,
        {
            data,
            statusMessage,
            logType: LogType.Event,
            isFrameworkLogging
        } );
};

const logFrameworkEvent = ( pv_Message = "",
    { data, statusMessage }       = {
        data:           null,
        statusMessage: null
    } ) => {
    return logEvent( pv_Message,
        {
            data,
            statusMessage,
            isFrameworkLogging: true
        } );
};

const logWarning = ( pv_Message                         = "",
    { data, statusMessage, isFrameworkLogging } = {
        data:                null,
        statusMessage:      null,
        isFrameworkLogging: null
    } ) => {
    return log( pv_Message,
        {
            data,
            statusMessage,
            logType: LogType.Warning,
            isFrameworkLogging
        } );
};

const logError = ( pv_Message                           = "",
    { data, statusMessage, isFrameworkLogging } = {
        data:                null,
        statusMessage:      null,
        isFrameworkLogging: null
    } ) => {
    return log( pv_Message,
        {
            data,
            statusMessage,
            logType: LogType.Error,
            isFrameworkLogging
        } );
};

const logFrameworkError = ( pv_Message                  = "",
    { data, statusMessage, isFrameworkLogging } = {
        data:           null,
        statusMessage: null
    } ) => {
    return log( pv_Message,
        {
            data,
            statusMessage,
            logType:            LogType.Error,
            isFrameworkLogging: true
        } );
};

const logApexError = ( pv_Message                       = "",
    { data, statusMessage, isFrameworkLogging } = {
        data:                null,
        statusMessage:      null,
        isFrameworkLogging: null
    } ) => {
    return log( pv_Message,
        {
            data,
            statusMessage,
            logType: LogType.ApexError,
            isFrameworkLogging
        } );
};

export {
    LogType,
    setLoggingLevel,
    startBlock,
    startFrameworkBlock,
    endBlock,
    endFrameworkBlock,
    log,
    logFramework,
    logSuccess,
    logApexSuccess,
    logApexRequest,
    logEvent,
    logFrameworkEvent,
    logWarning,
    logError,
    logFrameworkError,
    logApexError
};