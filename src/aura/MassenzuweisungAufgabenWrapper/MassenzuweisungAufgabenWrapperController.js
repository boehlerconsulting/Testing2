/**
 *@author       Mats Böhler
 *@created      18.09.2020
 *
 *
 *@description  MassenzuweisungAufgabenWrapperController.js
 *
 *
 *@changelog    18.09.2020 Mats Böhler - Created
 *
 *
 */

({
    handleOnChanged: function(component, event) {
        component.find("unsaved").setUnsavedChanges(event.getParam("isChanged"));
    },
});