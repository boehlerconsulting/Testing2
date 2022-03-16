/**
 * @author      Stefan Richter (stefan.richter@hundw.de)
 *              H+W CONSULT GmbH
 *              Bahnhofstr. 3
 *              21244 Buchholz i. d. Nordheide
 *              Germany
 *              https://www.hundw.de
 *
 * @description class for <insert-description-here>
 *
 * TIMELINE
 * 31.03.21      Stefan Richter  Initial release.
 **/
({
    /**
     * @description
     * @param errors
     */
    handleErrors: function (errors) {
        // Configure error toast
        let toastParams = {
            title: "Error",
            message: "Ein unerwarteter Fehler ist aufgetreten.", // Default error message
            type: "error",
            mode: "sticky"
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

    generateLead: function (component, helper) {
        var action = component.get("c.generateLead");
        action.setParams({
            "fnaeId": component.get("v.recordId")
        });
        action.setCallback(this, function (response) {

            var state = response.getState();

            if (state === "SUCCESS") {
                component.set("v.showSpinner", false);
                window.open('/' + response.getReturnValue(), '_blank');
                component.set("v.showSpinner", false);
                window.location.reload();
            } else {
                component.set("v.showSpinner", false);
                component.set("v.error", response.getError());
                helper.handleErrors(
                    response.getError()
                );
                $A.get("e.force:closeQuickAction").fire();
            }
        });

        $A.enqueueAction(action);
    }
});