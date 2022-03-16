/**
 *@author       Mats Böhler
 *@created      04.11.2020
 *
 *
 *@description  ReleaseNotesHelper.js
 *
 *
 *@changelog    04.11.2020 Mats Böhler - Created
 *
 *
 */

({
    subscribe: function (component, event, helper) {
        // Get the empApi component.
        const empApi = component.find('empApi');
        // Get the channel from the attribute.
        const channel = component.get('v.channel');
        // Subscription option to get only new events.
        const replayId = -1;
        // Callback function to be passed in the subscribe call.
        // After an event is received, this callback prints the event
        // payload to the console. A helper method displays the message
        // in the console app.
        const callback = function (message) {

            helper.onReceiveNotification(component, message);
        };
        // Subscribe to the channel and save the returned subscription object.
        empApi.subscribe(channel, replayId, $A.getCallback(callback)).then($A.getCallback(function (newSubscription) {

            component.set('v.subscription', newSubscription);
        }));
    },

    onReceiveNotification: function (component) {
        var action = component.get("c.init");

        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var instance = JSON.parse(response.getReturnValue());

                var modalBody;
                var modalFooter;
                $A.createComponents([
                        ["c:ReleaseNote", {
                            richText: instance.meldung.Beschreibung__c
                        }],
                        ["c:ReleaseNoteFooter", {

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

            } else {
                helper.handleErrors(
                    response.getError()
                );
            }
        });
        $A.enqueueAction(action);
    },

    handleErrors: function (errors) {
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
});