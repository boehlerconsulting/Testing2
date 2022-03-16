/**
 *@author       Mats Böhler
 *@created      24.05.2021
 *
 *
 *@description  EinrichtungsprozessZusatzWrapperController.js
 *
 *
 *@changelog    24.05.2021 Mats Böhler - Created
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