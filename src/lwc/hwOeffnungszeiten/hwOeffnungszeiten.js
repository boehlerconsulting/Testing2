/**
 *@author       Mats Böhler
 *@created      30.04.2019
 *@version      1.0
 *@since        45.0
 *
 *
 *@description  hwOeffnungszeiten
 *
 *
 *@changelog    30.04.2019 Mats Böhler - Created
 *
 *
 */

import {LightningElement, track, api, wire} from 'lwc';

//Custom Javascript
import * as Logger from "c/hwLogger";
import * as FieldInputValidator from "c/hwFieldInputValidator";
import {showSpinner, hideSpinner} from "c/hwSpinnerController";

import HwApplicationStateActionDispatcher from "c/hwApplicationStateActionDispatcher";
import * as ActionCreator from "c/hwStammdatensammlerActionCreator";
import {reduce} from "c/hwStammdatensammlerReducer";

export default class HW_Oeffnungszeiten extends LightningElement {

    @api oeffnungszeit;
    @api recordId;
    @api screenIndex;
    @api sectionIndex;
    @api index;
    @api screenLocked;


}