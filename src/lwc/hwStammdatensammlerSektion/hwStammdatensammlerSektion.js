/**
 *@author       Mats Böhler
 *@created      01.04.2019
 *@version      1.0
 *@since        45.0
 *
 *
 *@description  hwStammdatensammlerSektion
 *
 *
 *@changelog    01.04.2019 Mats Böhler - Created
 *
 *
 */

import {LightningElement, track, api, wire} from 'lwc';
import * as Logger from "c/hwLogger";

export default class HW_StammdatensammlerSektion extends LightningElement {

    @api section;
    @api recordId;
    @api screenLocked;
    @api isFactsSent;
    @api screenIndex;
    @api sectionIndex;
    @api isExistingMaef;

    get hideSection(){
        return this.section.hide && !this.section.iv_HasOeffnungszeiten;
    }

    get isLocked(){
        return this.screenLocked || (this.screenIndex === 2 && this.sectionIndex === 0 && this.isFactsSent === true );
    }

    get isSapFactsSectionLocked(){
        return this.screenIndex === 2 && this.sectionIndex === 0 &&  this.isFactsSent === true && this.isExistingMaef === false;
    }
}