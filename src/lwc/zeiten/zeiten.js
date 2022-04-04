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

import {api, LightningElement} from 'lwc';

export default class Zeiten extends LightningElement {

    @api recordId;

    @api title;
    @api iconName;
    @api sObjectName;

    @api titleColumnOne;
    @api titleColumnTwo;
    @api titleColumnThree;
    @api titleColumnFour;

    @api fieldNameOneOne;
    @api fieldNameOneTwo;
    @api fieldNameOneThree;
    @api fieldNameOneFour;

    @api fieldNameTwoOne;
    @api fieldNameTwoTwo;
    @api fieldNameTwoThree;
    @api fieldNameTwoFour;

    @api fieldNameThreeOne;
    @api fieldNameThreeTwo;
    @api fieldNameThreeThree;
    @api fieldNameThreeFour;

    @api fieldNameFourOne;
    @api fieldNameFourTwo;
    @api fieldNameFourThree;
    @api fieldNameFourFour;

    @api fieldNameFiveOne;
    @api fieldNameFiveTwo;
    @api fieldNameFiveThree;
    @api fieldNameFiveFour;

    @api fieldNameSixOne;
    @api fieldNameSixTwo;
    @api fieldNameSixThree;
    @api fieldNameSixFour;

    @api fieldNameSevenOne;
    @api fieldNameSevenTwo;
    @api fieldNameSevenThree;
    @api fieldNameSevenFour;
}