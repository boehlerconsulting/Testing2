/**
 * @author      Stefan Richter (stefan.richter@hundw.de)
 *              H+W CONSULT GmbH
 *              Bahnhofstr. 3
 *              21244 Buchholz i. d. Nordheide
 *              Germany
 *              https://www.hundw.de
 *
 * @description class for <insert-description-here>
 *
 * TIMELINE
 * 11.11.20      Stefan Richter  Initial release.
 **/
({
    handleShowModal: function(component) {
        var modalBody;

        $A.createComponent("c:VertragsErsteller_ConfirmationModal", {
                "lead": component.get("v.lead"),
                "mietzins": component.get("v.mietzins"),
                "strompauschale": component.get("v.strompauschale_eur")
            },
            function(content, status) {
                if (status === "SUCCESS") {
                    modalBody = content;
                    component.find('overlayLib').showCustomModal({
                        header: "Vertragserstellung bestätigen",
                        body: modalBody,
                        showCloseButton: true
                    })
                }
                else if (status === "INCOMPLETE") {
                    let toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "variant": "error",
                        "title": "Error",
                        "message": "Incomplete"
                    });
                }
                else if (status === "ERROR") {
                    let toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "variant": "error",
                        "title": "Error",
                        "message": "Error"
                    });
                }
                else{
                    //Sonarqube -> do nothing
                }
            });
    },
});