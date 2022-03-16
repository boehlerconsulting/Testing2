/**
 *@author       Mats Böhler <mats.boehler@boehlerconsulting.com>
 *@created      06.12.2018
 *@version      1.0
 *@since        44.0
 *
 *
 *@description  Post_EreignisseUebersichtController.js
 *
 *
 *@changelog    06.12.2018 Mats Böhler <mats.boehler@boehlerconsulting.com> - Created
 *
 *
 */
({
    doInit : function(component, event, helper) {
        helper.initializeComponent(component);
    },

    onNewEvent: function (component, event, helper) {
        helper.handleShowModal(component);
    },

    handleTaskFilterChange: function (component) {
        let action = component.get('c.getFilterCriteria');
        action.setParams({
            accountId: component.get('v.recordId'),
            userType: component.get('v.userType'),
            filterValue: component.get('v.filterValue'),
            objectName: 'Event',
        });
        action.setCallback(this, function(response){
            let state = response.getState();
            if(state === 'SUCCESS'){
                var ctrl = JSON.parse(response.getReturnValue());
                component.set("v.ctrl",ctrl);
                component.set("v.filterCriteria", ctrl.filterCriteria);

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

    handleHistoryRedirect : function (component) {
        window.open('/007?id=' + component.get("v.recordId") + '&rlid=RelatedHistoryList&closed=1', '_parent');
    },

})