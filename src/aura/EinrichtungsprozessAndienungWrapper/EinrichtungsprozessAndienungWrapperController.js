/**
 *@author       Mats Böhler
 *@created      22.03.2021
 *
 *
 *@description  EinrichtungsprozessAndienungWrapperController.js
 *
 *
 *@changelog    22.03.2021 Mats Böhler - Created
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