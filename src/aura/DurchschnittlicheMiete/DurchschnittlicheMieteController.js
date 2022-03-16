/**
 *@author       Mats Böhler
 *@created      11.11.2020
 *
 *
 *@description  DurchschnittlicheMieteController.js
 *
 *
 *@changelog    11.11.2020 Mats Böhler - Created
 *
 *
 */

({
    doInit: function (component, event, helper) {

        var action = component.get("c.init");
        action.setParams({
            "leadId": component.get("v.recordId")
        });
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.miete", response.getReturnValue());
                if (response.getReturnValue() === null) {
                    component.set("v.message", 'Es konnte kein Betrag ermittelt werden. Bitte wenden Sie sich an das SPM.');
                }
                component.set("v.showSpinner", false);
            } else {
                helper.handleErrors(
                    response.getError()
                );
                component.set("v.showSpinner", false);
            }
        });
        $A.enqueueAction(action);

    },

    handleClose: function () {
        $A.get("e.force:closeQuickAction").fire();
    },
});