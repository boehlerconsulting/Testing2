/**
 *@author       Mats Böhler <mats.boehler@boehlerconsulting.com>
 *@created      06.12.2018
 *@version      1.0
 *@since        44.0
 *
 *
 *@description  Post_NeuesEreignisModalController.js
 *
 *
 *@changelog    06.12.2018 Mats Böhler <mats.boehler@boehlerconsulting.com> - Created
 *
 *
 */
({
    fetchListOfRecordTypes: function(component) {

        var action = component.get("c.fetchRecordTypeValues");
        action.setParams({
            objectName: 'Event',
        });
        action.setCallback(this, function(response) {

            let state = response.getState();
            if(state === 'SUCCESS'){
                component.set("v.lstOfRecordType", response.getReturnValue());
                component.find("selectedId").set("v.value", component.get("v.lstOfRecordType")[0]);
            }
            else if (state === "INCOMPLETE") {
                component.find('notifLib').showToast({
                    "variant": "error",
                    "title": "Error",
                    "message": "Incomplete"
                });
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    component.find('notifLib').showToast({
                        "variant": "error",
                        "title": "Error",
                        "message": errors[0].message
                    });
                } else {
                    component.find('notifLib').showToast({
                        "variant": "error",
                        "title": "Error",
                        "message": "Error"
                    });
                }
            }
            else{
                //Sonarqube -> do nothing
            }
        });
        $A.enqueueAction(action);
    },

    createRecord: function(component) {

        var action = component.get("c.getRecordTypeIds");
        var recordTypeLabel = component.find("selectedId").get("v.value");
        let accountId = component.get("v.accountId");
        action.setParams({
            recordTypeLabel: recordTypeLabel,
            objectName: 'Event',
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var createRecordEvent = $A.get("e.force:createRecord");
                var RecTypeID  = response.getReturnValue();
                createRecordEvent.setParams({
                    "entityApiName": 'Event',
                    "recordTypeId": RecTypeID,
                    "defaultFieldValues": {
                        'WhatId' : accountId,
                    },
                    "panelOnDestroyCallback": function() {
                        var navEvt = $A.get("e.force:navigateToSObject");
                        navEvt.setParams({
                            "recordId": accountId,
                            "slideDevName": "detail"
                        });
                        navEvt.fire();
                    }
                });
                createRecordEvent.fire();
                component.find("overlayLib").notifyClose();
            }
            else if (state === "INCOMPLETE") {
                component.find('notifLib').showToast({
                    "variant": "error",
                    "title": "Error",
                    "message": "Incomplete"
                });
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    component.find('notifLib').showToast({
                        "variant": "error",
                        "title": "Error",
                        "message": errors[0].message
                    });
                } else {
                    component.find('notifLib').showToast({
                        "variant": "error",
                        "title": "Error",
                        "message": "Error"
                    });
                }
            }
            else{
                //Sonarqube -> do nothing
            }
        });
        $A.enqueueAction(action);
    },

    closeModal: function(component) {
        component.find("overlayLib").notifyClose();
    },
})