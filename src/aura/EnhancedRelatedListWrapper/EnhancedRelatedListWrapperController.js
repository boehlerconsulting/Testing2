/**
 *@author       Mats Böhler
 *@created      13.09.2021
 *
 *
 *@description  EnhancedRelatedListWrapperController.js
 *
 *
 *@changelog    13.09.2021 Mats Böhler - Created
 *
 *
 */

({
    doInit: function(component, event, helper) {
       helper.init(component, event, helper);
    },

    handleMessage: function(component) {
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
            "recordId": component.get("v.recordId"),
            "slideDevName": "detail"
        });
        navEvt.fire();
    },
});