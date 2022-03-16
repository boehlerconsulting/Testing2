/**
 *@author       Mats Böhler
 *@created      02.02.2021
 *
 *
 *@description  PoststationLeadDuplikatorHelper.js
 *
 *
 *@changelog    02.02.2021 Mats Böhler - Created
 *
 *
 */

({
    handleErrors : function(errors) {
        // Configure error toast
        let toastParams = {
            title: "Fehler",
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
});