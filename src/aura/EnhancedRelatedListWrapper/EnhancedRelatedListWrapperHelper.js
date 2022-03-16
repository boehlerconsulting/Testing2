/**
 *@author       Mats Böhler
 *@created      13.09.2021
 *
 *
 *@description  EnhancedRelatedListWrapperHelper.js
 *
 *
 *@changelog    13.09.2021 Mats Böhler - Created
 *
 *
 */

({
    handleErrors: function (errors) {
        // Configure error toast
        let toastParams = {
            title: "Error",
            message: "Ein unerwarteter Fehler ist aufgetreten.", // Default error message
            type: "error"
        };
        // Pass the error message if any
        if (errors && Array.isArray(errors) && errors.length > 0) {
            toastParams.message = errors[0].message;
        }
        // Fire error toast
        let toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams(toastParams);
        toastEvent.fire();
    },

    init: function (component, event, helper) {
        var action = component.get("c.init");
        action.setParams({
            "leadId": component.get("v.recordId")
        });
        action.setCallback(this, function (response) {

            var state = response.getState();

            if (state === "SUCCESS") {
                component.set('v.lead', response.getReturnValue());
                component.set("v.dummyAccountExists", true);
            } else {
                component.set("v.error", response.getError());
                helper.handleErrors(
                    response.getError()
                );
            }
        });
        $A.enqueueAction(action);
    }
});