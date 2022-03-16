/**
 *@author       Mats Böhler
 *@created      01.07.2021
 *
 *
 *@description  aktivitaetsDetailFeld
 *
 *
 *@changelog    01.07.2021 Mats Böhler - Created
 *
 *
 */

import {LightningElement, wire, track, api} from 'lwc';

export default class AktivitaetsDetailFeld extends LightningElement {

    @api field;

    get isDate(){
        return this.field.Feldart__c === 'Datum';
    }

    get isCurrency(){
        return this.field.Feldart__c === 'Euro/Cent';
    }

    get isCheckbox(){
        return this.field.Feldart__c === 'Kontrollkästchen';
    }

    get isText(){
        return this.field.Feldart__c === 'Text';
    }

    get isNumber(){
        return this.field.Feldart__c === 'Zahl';
    }
}