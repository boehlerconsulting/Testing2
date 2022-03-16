/**
 *@author       Mats Böhler
 *@created      20.10.2020
 *
 *
 *@description  VerkehrssicherungspflichtAnschreibenController.js
 *
 *
 *@changelog    20.10.2020 Mats Böhler - Created
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
                let instance = JSON.parse(response.getReturnValue());
                if (!instance.hasAccess) {
                    $A.get("e.force:closeQuickAction").fire();
                    let toastParams = {
                        title: "Fehler",
                        message: "Sie haben nicht die Berechtigung diese Funktionalität auszuführen.",
                        type: "error"
                    };
                    let toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams(toastParams);
                    toastEvent.fire();
                    component.set("v.showSpinner", false);
                } else {
                    component.set("v.contentDocumentIds", instance.contentDocumentIds);
                    component.set("v.hasAccess", instance.hasAccess);
                    component.set("v.hasMissingFields", instance.hasMissingFields);
                    var contentDocumentIds = component.get("v.contentDocumentIds");
                    var selectedByDocumentId = component.get("v.selectedByDocumentId");
                    var contentDocuments = component.get("v.contentDocuments");
                    contentDocumentIds.forEach(documentId => {
                        selectedByDocumentId[documentId] = false;
                        contentDocuments.push(
                            {
                                id: documentId,
                                hidden: false,
                                selected: false
                            }
                        );
                    });
                    component.set("v.selectedByDocumentId", selectedByDocumentId);
                    component.set("v.contentDocuments", contentDocuments);
                    component.set("v.showSpinner", false);
                }
            } else {
                helper.handleErrors(
                    response.getError()
                );
                component.set("v.showSpinner", false);
            }
        });
        $A.enqueueAction(action);

    },

    handleClose: function (component, event, helper) {
        var action = component.get("c.deleteFiles");
        action.setParams({
            "uploadedFileIds": component.get("v.uploadedContentDocumentIds")
        });
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.showSpinner", false);
                $A.get("e.force:closeQuickAction").fire();
            } else {
                helper.handleErrors(
                    response.getError()
                );
                component.set("v.showSpinner", false);
            }
        });
        $A.enqueueAction(action);
    },

    handleUploadFinished: function (component, event, helper) {
        var uploadedFiles = event.getParam("files");
        var contentDocumentIds = component.get("v.contentDocumentIds");
        var uploadedContentDocumentIds = component.get("v.uploadedContentDocumentIds");
        var contentDocuments = component.get("v.contentDocuments");
        var selectedByDocumentId = component.get("v.selectedByDocumentId");

        uploadedFiles.forEach(file => {
            contentDocumentIds.push(file.documentId);
            uploadedContentDocumentIds.push(file.documentId);
            contentDocuments.push(
                {
                    id: file.documentId,
                    hidden: false,
                    selected: true
                }
            );
            selectedByDocumentId[file.documentId] = true;
            helper.setSelectedPicturesByPage(component, file.documentId, true);
        });
        component.set("v.contentDocumentIds", contentDocumentIds);
        component.set("v.contentDocuments", contentDocuments);
        component.set("v.selectedByDocumentId", selectedByDocumentId);
        component.set("v.uploadedContentDocumentIds", uploadedContentDocumentIds);
    },

    handleCheckboxChange: function (component) {
        if (component.get("v.isVollstaendig") === true) {
            component.set("v.isWerktags", false);
            component.set("v.isSonntag", false);
            component.set("v.isSonstiges", false);
            component.set("v.angaben", "");
        }
        else if (component.get("v.isWerktags") === true
            || component.get("v.isSonntag") === true
            || component.get("v.isSonstiges") === true) {

            component.set("v.isVollstaendig", false);
        }
        else{
            //Sonarqube -> do nothing
        }
        if (component.get("v.isSonstiges") === false) {

            component.set("v.angaben", "");
        }
    },

    handleNext: function (component, event, helper) {

        if (component.get("v.isPageZero") === true) {
            component.set("v.isPageZero", false);
            component.set("v.isPageOne", true);
        } else {
            var contentDocuments = component.get("v.contentDocuments");
            contentDocuments.forEach(file => {
                file.hidden = file.selected;
            });
            component.set("v.contentDocuments", contentDocuments);
            var action = component.get("c.createPresentation");
            component.set("v.showSpinner", true);
            action.setParams({
                "leadId": component.get("v.recordId"),
                "picturesByPage": component.get("v.selectedFilesByPage"),
                "isVollstaendig": component.get("v.isVollstaendig"),
                "isWerktags": component.get("v.isWerktags"),
                "isSonntags": component.get("v.isSonntag"),
                "isSonstiges": component.get("v.isSonstiges"),
                "angaben": component.get("v.angaben"),
                "bemerkungen": component.get("v.bemerkungen"),
                "uploadedFileIds": component.get("v.uploadedContentDocumentIds")
            });
            action.setCallback(this, function (response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    let toastParams = {
                        title: "Erfolg",
                        message: "Das Anschreiben wurde erfolgreich generiert.",
                        type: "success"
                    };
                    let toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams(toastParams);
                    toastEvent.fire();
                    $A.get("e.force:closeQuickAction").fire();
                    $A.get('e.force:refreshView').fire();
                    component.set("v.showSpinner", false);
                } else {
                    helper.handleErrors(
                        response.getError()
                    );
                    component.set("v.showSpinner", false);
                }
            });
            $A.enqueueAction(action);
        }
    },

    handlePictureSelect: function (component, event, helper) {
        helper.setSelectedPicturesByPage(component, event.target.name, event.target.checked);
    },
});