/**
 *@author       Mats Böhler
 *@created      17.11.2020
 *
 *
 *@description  StoerungenController.js
 *
 *
 *@changelog    17.11.2020 Mats Böhler - Created
 *
 *
 */

({
    doInit: function (component, event, helper) {

        component.set('v.subscription', null);
        component.set('v.notifications', []);
        // Get empApi component.
        const empApi = component.find('empApi');
        // Define an error handler function that prints the error to the console.
        const errorHandler = function (message) {
            console.error('Received error ', JSON.stringify(message));
        };
        // Register empApi error listener and pass in the error handler function.
        empApi.onError($A.getCallback(errorHandler));
        helper.subscribe(component, event, helper);

        var action = component.get("c.init");

        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var instance = JSON.parse(response.getReturnValue());

                if (instance.showMeldung) {

                    var modalBody;
                    var modalFooter;
                    $A.createComponents([
                            ["c:Stoerung", {
                                richText: instance.meldung.Beschreibung__c
                            }],
                            ["c:StoerungFooter", {

                            }]
                        ],
                        function (contents, status) {
                            if (status === "SUCCESS") {
                                modalBody = contents[0];
                                modalFooter = contents[1];
                                component.find('overlayLib').showCustomModal({
                                    header: instance.meldung.Titel__c,
                                    body: modalBody,
                                    footer: modalFooter,
                                    showCloseButton: false,
                                    cssClass: "slds-modal_medium"
                                })
                            }
                        });
                }

            } else {
                helper.handleErrors(
                    response.getError()
                );
            }
        });
        $A.enqueueAction(action);
    },
});