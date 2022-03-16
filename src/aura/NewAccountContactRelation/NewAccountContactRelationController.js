/**
 *@author       Mats Böhler
 *@created      08.09.2021
 *
 *
 *@description  NewAccountContactRelationController.js
 *
 *
 *@changelog    08.09.2021 Mats Böhler - Created
 *
 *
 */

({
    refreshView: function () {

        $A.get('e.force:refreshView').fire();
    },
});