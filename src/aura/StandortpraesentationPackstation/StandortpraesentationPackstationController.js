/**
 *@author       Mats Böhler
 *@created      26.06.2020
 *
 *
 *@description  StandortpraesentationPackstationController.js
 *
 *
 *@changelog    26.06.2020 Mats Böhler - Created
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
                component.set("v.contentDocumentIds", response.getReturnValue());
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

    handleNext: function (component, event, helper) {

        var contentDocuments = component.get("v.contentDocuments");
        contentDocuments.forEach(file => {
            file.hidden = file.selected;
        });
        component.set("v.contentDocuments", contentDocuments);
        if (component.get("v.isPageOne") === true) {
            component.set("v.isPageOne", false);
            component.set("v.isPageTwo", true);
            return;
        }
        if (component.get("v.isPageTwo") === true) {
            component.set("v.isPageTwo", false);
            component.set("v.isPageThree", true);
            return;
        }
        if (component.get("v.isPageThree") === true) {
            component.set("v.isPageThree", false);
            component.set("v.isPageFour", true);
            return;
        }
        if (component.get("v.isPageFour") === true) {
            var action = component.get("c.createPresentation");
            component.set("v.showSpinner", true);
            action.setParams({
                "leadId": component.get("v.recordId"),
                "picturesByPage": component.get("v.selectedFilesByPage"),
                "uploadedFileIds": component.get("v.uploadedContentDocumentIds")
            });
            action.setCallback(this, function (response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    let toastParams = {
                        title: "Erfolg",
                        message: "Die Präsentation wurde erfolgreich generiert.",
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