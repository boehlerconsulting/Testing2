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
 * 23.11.20      Stefan Richter  Initial release.
 **/
({
    sendMail: function (component, event, helper) {
        component.set("v.isLoading", true);
        var action = component.get("c.sendMail");
        action.setParams({
            jsonLead: JSON.stringify(component.get("v.lead")),
            sp: component.get("v.strompauschale"),
            mk: component.get("v.mietzins")
        });
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.isLoading", false);
            } else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    let toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        type: "error",
                        title: "Error",
                        message: errors[0].message
                    });
                    toastEvent.fire();
                    component.set("v.isLoading", false);
                    component.find("overlayLib").notifyClose();
                }
            } else {
                let toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    type: "error",
                    title: "Error",
                    message: "Something went wrong."
                });
                toastEvent.fire();
                component.set("v.isLoading", false);
                component.find("overlayLib").notifyClose();

            }
        });

        $A.enqueueAction(action);
    },

    generateSinglePdf: function (component) {
        component.set("v.isLoading", true);
        let action = component.get("c.generateSinglePdf");
        action.setParams({
            jsonLead: JSON.stringify(component.get("v.lead")),
            sp: component.get("v.strompauschale"),
            mk: component.get("v.mietzins")
        });
        action.setCallback(this, function (response) {
            let state = response.getState();
            if (state === "SUCCESS") {
                var downloadPdf = response.getReturnValue();

                component.set("v.isLoading", false);
                var lead = component.get("v.lead");
                let toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type": "success",
                    "title": "Einzelvertrag erzeugt",
                    "mode": "sticky",

                    "message":
                        "Zum Lead " +
                        lead.Company +
                        " " +
                        lead.Street +
                        " " +
                        lead.PostalCode +
                        " wurde ein Einzelvertrag auf Basis <Einzelvertrag> erzeugt!." +
                        "Bitte prüfen Sie die Übereinstimmung mit dem im Lead hinterlegtem Wert. " +
                        "Ein Prüfbeleg wird an die Timeline im Lead angefügt."
                });

                toastEvent.fire();

                var fileName = '2a1_' + lead.City + '_' + lead.Street + '_' + lead.Company + '.pdf';
                var bas64file = 'data:application/octet-stream;base64,' + downloadPdf;

                component.set("v.pdfFileName", fileName);
                component.set("v.downloadPdf", bas64file);
                component.set("v.isPdfRendered", true);

                $A.get("e.force:closeQuickAction").fire();

            } else if (state === "INCOMPLETE") {
                let toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    variant: "error",
                    title: "Error",
                    message: "Incomplete"
                });
            } else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    let toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        variant: "error",
                        title: "Error",
                        message: errors[0].message
                    });
                } else {
                    let toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        variant: "error",
                        title: "Error",
                        message: "Error"
                    });
                }
            } else {
                //Sonarqube -> do nothing
            }
        });
        $A.enqueueAction(action);
    },
});