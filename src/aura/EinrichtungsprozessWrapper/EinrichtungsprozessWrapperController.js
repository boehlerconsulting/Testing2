/**
 *@author       Mats Böhler
 *@created      08.02.2021
 *
 *
 *@description  EinrichtungsprozessWrapperController.js
 *
 *
 *@changelog    08.02.2021 Mats Böhler - Created
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