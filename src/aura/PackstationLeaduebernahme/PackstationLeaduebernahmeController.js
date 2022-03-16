/**
 *@author       Mats Böhler
 *@created      27.11.2020
 *
 *
 *@description  PackstationLeaduebernahmeController.js
 *
 *
 *@changelog    27.11.2020 Mats Böhler - Created
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
                let toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    title: "Erfolg",
                    message: "Der Lead wurde erfolgreich an Sie übergeben.",
                    type: "success"
                });
                toastEvent.fire();

            } else {
                helper.handleErrors(
                    response.getError()
                );
            }
            component.set("v.showSpinner", false);
            $A.get("e.force:closeQuickAction").fire();
            $A.get('e.force:refreshView').fire();
        });
        $A.enqueueAction(action);

    },
});