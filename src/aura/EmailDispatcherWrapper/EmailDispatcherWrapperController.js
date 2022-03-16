/**
 *@author       Mats Böhler
 *@created      16.05.2020
 *
 *
 *@description  EmailDispatcherWrapperController.js
 *
 *
 *@changelog    16.05.2020 Mats Böhler - Created
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
                component.set("v.isSent", instance.isSent);
                component.set("v.lead", instance.lead);
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
                component.set("v.isInitialized", true);
                
            } else {
                helper.handleErrors(
                    response.getError()
                );
                $A.get("e.force:closeQuickAction").fire();
            }
            component.set("v.showSpinner", false);
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

    handlePictureSelect: function (component, event, helper) {
        helper.setSelectedPicturesByPage(component, event.target.name, event.target.checked);
    },

    handleSendEmail: function (component, event, helper) {
        component.set("v.isSaving", true);
        var contentDocuments = component.get("v.contentDocuments");
        contentDocuments.forEach(file => {
            file.hidden = file.selected;
        });
        component.set("v.contentDocuments", contentDocuments);
        var action = component.get("c.sendEmail");
        component.set("v.showSpinner", true);
        action.setParams({
            "leadId": component.get("v.recordId"),
            "selectedFileIds": component.get("v.selectedFilesByPage")[1]
        });
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                let toastParams = {
                    title: "Erfolg",
                    message: "Der Emailversand wurde erfolgreich angestoßen.",
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
    },
});