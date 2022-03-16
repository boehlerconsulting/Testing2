/**
 *@author       Mats Böhler
 *@created      30.06.2020
 *
 *
 *@description  PackstationAktivatorController.js
 *
 *
 *@changelog    30.06.2020 Mats Böhler - Created
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
                let activated = response.getReturnValue();
                if(activated === true || activated === 'true'){
                    let toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        title: "Erfolg",
                        message: "Der Lead wurde aktiviert.",
                        type: "success"
                    });
                    toastEvent.fire();
                }
                else{
                    let toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        title: "Erfolg",
                        message: "Der Lead wurde deaktiviert.",
                        type: "success"
                    });
                    toastEvent.fire();
                }

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