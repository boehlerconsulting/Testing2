/**
 *@author       Mats Böhler
 *@created      04.12.2020
 *
 *
 *@description  EmailDispatcherWrapperHelper.js
 *
 *
 *@changelog    04.12.2020 Mats Böhler - Created
 *
 *
 */

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

    setSelectedPicturesByPage : function(component, documentId, checked) {
        var selectedByDocumentId = component.get("v.selectedByDocumentId");
        selectedByDocumentId[documentId] = checked;
        component.set("v.selectedByDocumentId", selectedByDocumentId);
        var numberOfSelectedFilesByPage = component.get("v.numberOfSelectedFilesByPage");
        var selectedFilesByPage = component.get("v.selectedFilesByPage");

        if (component.get("v.isPageOne") === true) {
            if (selectedByDocumentId[documentId] === true) {
                numberOfSelectedFilesByPage[1] = numberOfSelectedFilesByPage[1] + 1;
                selectedFilesByPage[1] = selectedFilesByPage[1] + documentId + ',';
            } else {
                numberOfSelectedFilesByPage[1] = numberOfSelectedFilesByPage[1] - 1;
                selectedFilesByPage[1] = selectedFilesByPage[1].replace(documentId + ',', '');
            }
        }
        var contentDocuments = component.get("v.contentDocuments");
        contentDocuments.forEach(file => {
            if (file.id === documentId){
                file.selected = checked;
            }
        });
        component.set("v.contentDocuments", contentDocuments);
        component.set("v.numberOfSelectedFilesByPage", numberOfSelectedFilesByPage);
        component.set("v.selectedFilesByPage", selectedFilesByPage);
    }
});