/**
 *@author       Mats Böhler
 *@created      17.11.2020
 *
 *
 *@description  StoerungController.js
 *
 *
 *@changelog    17.11.2020 Mats Böhler - Created
 *
 *
 */

({
    handleClose: function (component) {
        component.find("overlayLib").notifyClose();
    },

    handleDoNotShowAgain: function (component, event, helper) {
        var action = component.get("c.doNotShowAgain");

        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                component.find("overlayLib").notifyClose();
            } else {
                helper.handleErrors(
                    response.getError()
                );
            }
        });
        $A.enqueueAction(action);
    },
});