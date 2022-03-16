/**
 *@author       Mats Böhler
 *@created      06.01.2022
 *
 *
 *@description  PageUtilityController.js
 *
 *
 *@changelog    06.01.2022 Mats Böhler - Created
 *
 *
 */

({

    handleFilePreview: function (component, message) {
        setTimeout(function(){
            if (message != null && message.getParam("contentDocumentId") != null) {
                var nagigateLightning = component.find('navigate');
                var pageReference = {
                    type: 'standard__namedPage',
                    attributes: {
                        pageName: 'filePreview',
                    },
                    state: {
                        recordIds: message.getParam("contentDocumentId"),
                        selectedRecordId: message.getParam("contentDocumentId")
                    }
                };
                nagigateLightning.navigate(pageReference);
            }
        }, 1000);
    },

    handleRefresh: function () {
        $A.get('e.force:refreshView').fire();
    },
});