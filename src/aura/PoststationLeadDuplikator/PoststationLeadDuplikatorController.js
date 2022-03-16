/**
 *@author       Mats Böhler
 *@created      02.02.2021
 *
 *
 *@description  PoststationLeadDuplikatorController.js
 *
 *
 *@changelog    02.02.2021 Mats Böhler - Created
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
                var navEvt = $A.get("e.force:navigateToSObject");
                navEvt.setParams({
                    "recordId": response.getReturnValue(),
                    "slideDevName": "detail"
                });
                navEvt.fire();
                let toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    title: "Erfolg",
                    message: "Der Lead wurde erfolgreich dupliziert.",
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