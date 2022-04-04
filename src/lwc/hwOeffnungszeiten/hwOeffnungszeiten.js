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

import {LightningElement, api} from 'lwc';

export default class HW_Oeffnungszeiten extends LightningElement {

    @api oeffnungszeit;
    @api recordId;
    @api screenIndex;
    @api sectionIndex;
    @api index;
    @api screenLocked;


}