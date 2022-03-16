/**
 *@author       Mats Böhler
 *@created      21.09.2020
 *
 *
 *@description  MassenzuweisungFilialenWrapperController.js
 *
 *
 *@changelog    21.09.2020 Mats Böhler - Created
 *
 *
 */

({
    handleOnChanged: function(component, event) {
        component.find("unsaved").setUnsavedChanges(event.getParam("isChanged"));
    },
});