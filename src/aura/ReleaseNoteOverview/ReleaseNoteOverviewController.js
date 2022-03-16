/**
 *@author       Mats Böhler
 *@created      18.11.2020
 *
 *
 *@description  ReleaseNoteOverviewController.js
 *
 *
 *@changelog    18.11.2020 Mats Böhler - Created
 *
 *
 */

({
    doInit: function (component, event, helper) {
        var action = component.get("c.init");

        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {

                component.set("v.releases", JSON.parse(response.getReturnValue()));
                component.set("v.showSpinner", false);
            } else {
                helper.handleErrors(
                    response.getError()
                );
            }
        });
        $A.enqueueAction(action);
    },
});