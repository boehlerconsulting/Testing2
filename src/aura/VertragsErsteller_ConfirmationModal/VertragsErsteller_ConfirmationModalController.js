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
 * 11.11.20      Stefan Richter  Initial release.
 **/
({
    closeModal: function(component) {
        component.find("overlayLib").notifyClose();
    },
    redirectToContractPdf: function(component, event, helper) {
        var sendAsMail = component.get("v.sendAsMail");

        if(sendAsMail) {
            helper.sendMail(component, event, helper);
        }

        helper.generateSinglePdf(component, event, helper);
    },
    gotoObject: function(component) {
        var navEvent = $A.get("e.force:navigateToSObject");
        navEvent.setParams({
            recordId: component.get("v.lead").Id,
            slideDevName: "detail"
        });
        navEvent.fire();
    }
});