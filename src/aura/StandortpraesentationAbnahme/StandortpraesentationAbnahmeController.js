/**
 *@author       Mats Böhler
 *@created      07.10.2020
 *
 *
 *@description  StandortpraesentationAbnahmeController.js
 *
 *
 *@changelog    07.10.2020 Mats Böhler - Created
 *
 *
 */

({
    doInit: function (component) {

        var action = component.get("c.loadData");
        action.setParams({
            "recordId": component.get("v.recordId")
        });
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                let instance = JSON.parse(response.getReturnValue());
                component.set("v.lead", instance.lead);
                if (!instance.hasPermission) {
                    let toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "type": "warning",
                        "title": "Fehlende Berechtigung!",
                        "message": 'Die Funktion kann nur von Benutzern mit der Berechtigung "FreigabeStandortdokumentation" ' +
                            'ausgeführt werden. Bitte kontaktieren Sie Ihren Systemadministrator.'
                    });
                    toastEvent.fire();
                    $A.get("e.force:closeQuickAction").fire();
                } else {
                    component.set("v.isAllowed", instance.isAllowed);
                    component.set("v.alreadyApproved", instance.alreadyApproved);
                    if (instance.alreadyApproved) {
                        component.set("v.reasons", "Nach Abnahme der Standortdokumentation/In den Verhandlungen " +
                            "mit dem STOG sind Änderungen am Standort notwendig geworden, die eine erneute " +
                            "Standortdokumentation erfordern. Diese Änderungen sind: ");
                    }
                    component.set("v.isInitialized", true);
                    component.set("v.isLoading", false);
                }
            } else {
                let toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type": "error",
                    "title": "Error!",
                    "message": "Something went wrong."
                });
                toastEvent.fire();
            }
        });

        $A.enqueueAction(action);
    },

    handleClose: function () {
        $A.get("e.force:closeQuickAction").fire();
    },

    handleOnChangeFreigabe: function (component) {
        let value = component.find("select").get("v.value");
        component.set("v.showReasons", value === 'Nein, Nachbesserung erforderlich'
            || value === 'Nein, neue Standortaufnahme erforderlich'
            || value === 'Nachbesserung nach Abnahme');
        component.set("v.showSave", value !== '');
    },

    handleSave: function (component) {

        if (component.get("v.reasons") === ''
            && (component.find("select").get("v.value") === 'Nein, Nachbesserung erforderlich'
                || component.find("select").get("v.value") === 'Nein, neue Standortaufnahme erforderlich'
                || component.find("select").get("v.value") === 'Nachbesserung nach Abnahme')) {
            let toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "type": "error",
                "title": "Fehler!",
                "message": "Wenn die Standortdokumentation nicht freigegeben wird, dann müssen Gründe dafür angegeben werden."
            });
            toastEvent.fire();
        } else {

            var action = component.get("c.saveData");
            action.setParams({
                "recordId": component.get("v.recordId"),
                "freigabe": component.find("select").get("v.value"),
                "reasons": component.get("v.reasons")
            });
            action.setCallback(this, function (response) {
                var state = response.getState();
                if (state === "SUCCESS") {

                    let toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "type": "success",
                        "title": "Erfolg!",
                        "message": component.find("select").get("v.value") === 'Ja'
                            ? "Die Standortpräsentation wurde freigegeben."
                            : "Die Aufgabe über die Nachbesserung der Standortpräsentation wurde erstellt."
                    });
                    toastEvent.fire();
                    $A.get("e.force:closeQuickAction").fire();
                    $A.get('e.force:refreshView').fire();
                } else {
                    let errors = response.getError();
                    let message = 'Unknown error';
                    if (errors && Array.isArray(errors) && errors.length > 0) {
                        message = errors[0].message;
                    }

                    let toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "type": "error",
                        "title": "Error!",
                        "message": message
                    });
                    toastEvent.fire();
                }
            });

            $A.enqueueAction(action);
        }
    },
});