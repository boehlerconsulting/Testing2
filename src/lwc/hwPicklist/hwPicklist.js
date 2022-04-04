/**
 * Created by oliverpreuschl on 2019-03-26.
 */
import { LightningElement, api } from "lwc";

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

    get iv_InlineHelpText() {
        return this.fieldLevelHelp;
    }

    get iv_Required() {
        return this.required;
    }

    handleChange_Value( pe_ValueChange ) {
        this.value           = pe_ValueChange.detail.value;
        const le_ValueChange = new CustomEvent( "change", { detail: this.fieldName } );
        this.dispatchEvent( le_ValueChange );
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