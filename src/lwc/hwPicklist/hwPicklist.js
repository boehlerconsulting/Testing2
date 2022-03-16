/**
 * Created by oliverpreuschl on 2019-03-26.
 */

//Salesforce
import { LightningElement, api, track, wire } from "lwc";

//Custom Javascript
import * as Logger from "c/hwLogger";

//Lightning UI Adapters
import { getObjectInfo, getPicklistValues } from "lightning/uiObjectInfoApi";


export default class HwPicklist extends LightningElement {

    //---Public Properties-------------------------------------------------------------------------
    @api name;
    @api label;
    @api placeholder;
    @api sObjectName;
    @api fieldName;
    @api recordTypeId     = null;
    @api value;
    @api loadDefaultValue = false;
    @api dropdownAlignment;
    @api messageWhenValueMissing;
    @api variant;
    @api disabled;
    @api readOnly;
    @api required         = null;
    @api fieldLevelHelp   = null;
    @api io_PicklistValues;


    renderedCallback() {
        Logger.startBlock("hwPicklist.renderedCallback")();

        Logger.endBlock()();

    }

    //Private Properties-------------------------------------------------------------------------
    /*iv_DefaultValueLoaded = false;*/


    //Wired Properties-------------------------------------------------------------------------
    /*@wire( getObjectInfo, { objectApiName: "$sObjectName" } ) io_SObjectInfo;

    @wire( getPicklistValues,
        {
            recordTypeId: "$iv_RecordTypeId",
            fieldApiName: "$iv_FieldIdentifier"
        } )
    onWire_getPicklistValues( { error, data } ) {
        Logger.startFrameworkBlock( "HwPicklist.onWire_getPicklistValues" )();

        if ( data ) {
            this.io_PicklistValues = data;
            if ( this.defaultValueNeedsToBeSet() ) {
                this.setDefaultPicklistValue();
                this.iv_DefaultValueLoaded = true;
            }
        } else {
            Logger.logFrameworkError( error );
        }

        Logger.endFrameworkBlock()();
    }*/


    //Getters-------------------------------------------------------------------------

    /*get iv_FieldIdentifier() {
        Logger.startFrameworkBlock( "HwPicklist.iv_FieldIdentifier" )();
        Logger.endFrameworkBlock()();

        return this.sObjectName + "." + this.fieldName;
    }*/

    /*get iv_RecordTypeId() {
        Logger.startFrameworkBlock( "HwPicklist.iv_RecordTypeId" )();

        let lv_RecordTypeId;
        if ( this.recordTypeId ) {
            lv_RecordTypeId = this.recordTypeId;
        } else if ( this.io_SObjectInfo && this.io_SObjectInfo.defaultRecordTypeId ) {
            lv_RecordTypeId = this.io_SObjectInfo.defaultRecordTypeId;
        } else {
            lv_RecordTypeId = "012000000000000AAA";
        }
        Logger.logFramework( lv_RecordTypeId )();

        Logger.endFrameworkBlock()();

        return lv_RecordTypeId;
    }*/

    get iv_InlineHelpText() {
        /*Logger.startFrameworkBlock( "HwPicklist.iv_InlineHelpText" )();

        let lv_InlineHelpText = null;
        if ( this.io_SObjectInfo && this.io_SObjectInfo.data && this.io_SObjectInfo.data.fields && this.io_SObjectInfo.data.fields[ this.fieldName ] ) {
            lv_InlineHelpText = this.io_SObjectInfo.data.fields[ this.fieldName ].inlineHelpText;
        }
        Logger.logFramework( "lv_InlineHelpText", { data: lv_InlineHelpText } )();

        Logger.endFrameworkBlock()();

        if (this.fieldLevelHelp){
            lv_InlineHelpText = this.fieldLevelHelp;
        }*/

        return this.fieldLevelHelp;
    }

    get iv_Required() {
        /*Logger.startFrameworkBlock( "HwPicklist.iv_Required" )();

        let lv_Required;
        if ( this.io_SObjectInfo && this.io_SObjectInfo.data && this.io_SObjectInfo.data.fields && this.io_SObjectInfo.data.fields[ this.fieldName ] ) {
            lv_Required = this.io_SObjectInfo.data.fields[ this.fieldName ].required;
        }
        Logger.logFramework( "lv_Required", lv_Required )();

        Logger.endFrameworkBlock()();

        if (this.required){
            lv_Required = this.required;
        }*/

        return this.required;
    }


    //Instance Methods------------------------------------------------------------------------

    dispatchChangeEvent() {
        LoggingHelper.startBlock( "hwPicklist.dispatchChangeEvent" )();

        const le_ValueChange = new CustomEvent( "change", { detail: this.fieldName } );
        this.dispatchEvent( le_ValueChange );

        LoggingHelper.endBlock()();
    }

    /*defaultValueNeedsToBeSet() {
        return this.loadDefaultValue && !this.iv_DefaultValueLoaded && ( this.value === undefined );
    }

    setDefaultPicklistValue() {
        if ( this.io_PicklistValues.defaultValue ) {
            Logger.logFramework( "DefaultValue: ", { data: this.io_PicklistValues.defaultValue } )();
            this.value           = this.io_PicklistValues.defaultValue.value;
            const le_ValueChange = new CustomEvent( "change", { detail: this.fieldName } );
            this.dispatchEvent( le_ValueChange );
        } else {
            Logger.log( "No DefaultValue found" )();
        }
    }*/


    //Event Handlers-------------------------------------------------------------------------

    handleChange_Value( pe_ValueChange ) {
        Logger.startFrameworkBlock( "HwPicklist.handleChange_Value" )();

        this.value           = pe_ValueChange.detail.value;
        const le_ValueChange = new CustomEvent( "change", { detail: this.fieldName } );
        this.dispatchEvent( le_ValueChange );

        Logger.endFrameworkBlock()();
    }


    //API Methods-------------------------------------------------------------------------

    @api
    focus() {
        this.template.querySelector( "lightning-combobox" ).focus();
    }

    @api
    blur() {
        this.template.querySelector( "lightning-combobox" ).blur();
    }

    @api
    checkValidity() {
        return this.template.querySelector( "lightning-combobox" ).checkValidity();
    }

    @api
    reportValidity() {
        return this.template.querySelector( "lightning-combobox" ).reportValidity();
    }

    @api
    setCustomValidity( pv_Message ) {
        this.template.querySelector( "lightning-combobox" ).setCustomValidity( pv_Message );
    }

    @api
    showHelpMessageIfInvalid() {
        this.template.querySelector( "lightning-combobox" ).showHelpMessageIfInvalid();
    }


}