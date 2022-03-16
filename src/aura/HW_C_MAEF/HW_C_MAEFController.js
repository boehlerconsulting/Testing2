/**
 *@author       Mats Böhler
 *@created      18.08.2021
 *
 *
 *@description  HW_C_MAEFController.js
 *
 *
 *@changelog    18.08.2021 Mats Böhler - Created
 *
 *
 */

({
    closeModal: function () {

        $A.get("e.force:closeQuickAction").fire();
    },
    refreshView: function () {

        $A.get('e.force:refreshView').fire();
    },
});