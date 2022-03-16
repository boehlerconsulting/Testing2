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
 * 03.03.21      Stefan Richter  Initial release.
 **/
({
    handleErrors : function(errors) {
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

    /***
     * @description send the lead id to the controller an calls pdf generation method
     * @param component the current component
     * @param helper the related helper
     */
    saveAnschreibenCSG : function(component,helper) {
        var action = component.get("c.saveAnschreibenCSG");
        action.setParams({
            "leadId": component.get("v.recordId")
        });
        action.setCallback(this, function (response) {

            var state = response.getState();

            if (state === "SUCCESS") {
                window.open('/' + component.get("v.recordId"), '_Self');
            } else {
                component.set("v.error",response.getError());
                helper.handleErrors(
                    response.getError()
                );
            }
        });

        $A.enqueueAction(action);
    }
});