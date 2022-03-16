/**
 *@author       Mats Böhler
 *@created      26.06.2021
 *
 *
 *@description  zeiten
 *
 *
 *@changelog    26.06.2021 Mats Böhler - Created
 *
 *
 */

import {api, LightningElement, track, wire} from 'lwc';

export default class Zeiten extends LightningElement {

    @api recordId;

    @api title;
    @api iconName;
    @api sObjectName;

    @api titleColumnOne;
    @api titleColumnTwo;
    @api titleColumnThree;
    @api titleColumnFour;

    @api fieldName_1_1;
    @api fieldName_1_2;
    @api fieldName_1_3;
    @api fieldName_1_4;

    @api fieldName_2_1;
    @api fieldName_2_2;
    @api fieldName_2_3;
    @api fieldName_2_4;

    @api fieldName_3_1;
    @api fieldName_3_2;
    @api fieldName_3_3;
    @api fieldName_3_4;

    @api fieldName_4_1;
    @api fieldName_4_2;
    @api fieldName_4_3;
    @api fieldName_4_4;

    @api fieldName_5_1;
    @api fieldName_5_2;
    @api fieldName_5_3;
    @api fieldName_5_4;

    @api fieldName_6_1;
    @api fieldName_6_2;
    @api fieldName_6_3;
    @api fieldName_6_4;

    @api fieldName_7_1;
    @api fieldName_7_2;
    @api fieldName_7_3;
    @api fieldName_7_4;
}