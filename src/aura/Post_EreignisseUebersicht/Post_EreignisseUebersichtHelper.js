/**
 *@author       Mats Böhler <mats.boehler@boehlerconsulting.com>
 *@created      06.12.2018
 *@version      1.0
 *@since        44.0
 *
 *
 *@description  Post_EreignisseUebersichtHelper.js
 *
 *
 *@changelog    06.12.2018 Mats Böhler <mats.boehler@boehlerconsulting.com> - Created
 *
 *
 */
({
    handleShowModal: function(component) {
        var modalBody;
        $A.createComponent("c:Post_NeuesEreignisModal",
            {
                "accountId": component.get("v.recordId"),

            },
            function(content, status) {
                if (status === "SUCCESS") {
                    modalBody = content;
                    component.find('overlayLib').showCustomModal({
                        header: "Neues Ereignis - Datensatztyp",
                        body: modalBody,
                        showCloseButton: true
                    })
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
    },

    initializeComponent: function(component) {
        component.set('v.showSpinner', true);
        let action = component.get('c.initialize');
        action.setParams({
            accountId: component.get('v.recordId'),
            userType: component.get('v.userType'),
            objectName: 'Event',
        });
        action.setCallback(this, function(response){
            let state = response.getState();
            if(state === 'SUCCESS'){

                var ctrl = JSON.parse(response.getReturnValue());
                component.set("v.ctrl",ctrl);
                component.set("v.filterValue",ctrl.filterValue);
                $A.createComponent("c:Post_DynamicTable",
                    {
                        "SObjectName": "Event",
                        "FieldNames": component.getReference("v.ctrl.fieldsToQuery"),
                        "MatchCriteria": component.getReference("v.ctrl.filterCriteria"),
                        "ReferenceFields": component.getReference("v.ctrl.referenceFields"),
                        "OverrideFieldType": component.getReference("v.ctrl.overrideFieldType"),
                        "FieldLabels": component.getReference("v.ctrl.fieldLabels"),
                        "accountId": component.getReference("v.recordId"),
                        "userType": component.getReference("v.userType"),
                        "filterValue": component.getReference("v.filterValue")
                    },
                    function (content, status) {
                        if (status === "SUCCESS") {
                            var body = component.get("v.body");
                            body.push(content);
                            component.set("v.body", body);
                            component.set('v.showSpinner', false);
                        }
                    });

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

})