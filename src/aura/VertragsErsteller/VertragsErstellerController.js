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
 * 28.10.20      Stefan Richter Initial release.
 **/
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
                component.set("v.stromverbrauch_cnt", instance.verbrauch.Stromverbrauch__c);

                if (!instance.hasPermission) {
                    let toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "type": "warning",
                        "title": "Fehlende Berechtigung!",
                        "message": 'Die Funktion kann nur von Benutzern mit der Berechtigung "VertragErstellen" ' +
                            'ausgeführt werden. Bitte kontaktieren Sie Ihren Systemadministrator.'
                    });
                    toastEvent.fire();
                    $A.get("e.force:closeQuickAction").fire();
                } else {
                    component.set("v.isLoading", false);
                    if (instance.lead.ZuordnungZuRahmenvertrag__c === "Einzelvertrag") {

                        var msgStart = 'Bitte prüfen Sie das folgende Pflichtfelder gefüllt sind: \n';
                        var msgFields = '';

                        var fieldMissing = false;

                        if (!instance.lead.ADM_Typ__c) {
                            msgFields += '· ADM Typ\n';
                            fieldMissing = true;
                        }
                        if (!instance.lead.Stromanschluss__c) {
                            msgFields += '· Stromanschluss\n';
                            fieldMissing = true;
                        }
                        if (!instance.lead.ADM_Hersteller__c) {
                            msgFields += '· ADM Hersteller\n';
                            fieldMissing = true;
                        }
                        if (!instance.lead.Screening__c) {
                            msgFields += '· Denied Party Screening (Datum)\n';
                            fieldMissing = true;
                        }
                        if (!instance.lead.Summe_aller_Module__c > 0) {
                            msgFields += '· Summe aller Module\n';
                            fieldMissing = true;
                        }
                        if (!instance.lead.DokumentationDurchRTFreigebenDatum__c) {
                            msgFields += '· Dokumentation von rVU freigeben (Datum)\n';
                            fieldMissing = true;
                        }
                        if (!instance.lead.Company) {
                            msgFields += '· Firma\n';
                            fieldMissing = true;
                        }
                        if (!instance.lead.Street) {
                            msgFields += '· Straße\n';
                            fieldMissing = true;
                        }
                        if (!instance.lead.PostalCode) {
                            msgFields += '· Postleitzahl\n';
                            fieldMissing = true;
                        }
                        if (!instance.lead.City) {
                            msgFields += '· Stadt\n';
                            fieldMissing = true;
                        }
                        if (!instance.lead.Bank__c) {
                            msgFields += '· Bank\n';
                            fieldMissing = true;
                        }
                        if (!instance.lead.IBAN__c) {
                            msgFields += '· IBAN\n';
                            fieldMissing = true;
                        }
                        if (!instance.lead.BIC__c) {
                            msgFields += '· BIC\n';
                            fieldMissing = true;
                        }
                        if (!instance.lead.Uebergabetermin__c) {
                            msgFields += '· Übergabetermin\n';
                            fieldMissing = true;
                        }
                        if (!instance.lead.ZuordnungZuRahmenvertrag__c) {
                            msgFields += '· Zuordnung zu Rahmenvertrag\n';
                            fieldMissing = true;
                        }
                        if (instance.lead.Bewertung_Zentrale__c !== "Geeignet"
                            && instance.lead.Bewertung_Zentrale__c !== "Geeignet - Priorisierte Bearbeitung"
                            && instance.lead.Bewertung_Zentrale__c !== "Geeignet - nur als Poststation"
                            && instance.lead.Bewertung_Zentrale__c !== "Geeignet - Hotlead") {
                            msgFields += '· Bewertung Zentrale\n';
                            fieldMissing = true;
                        }
                        if (fieldMissing===true) {
                            let toastEvent = $A.get("e.force:showToast");
                            toastEvent.setParams({
                                "type": "warning",
                                "title": "Bitte Werte prüfen!",
                                "mode": "sticky",
                                "message": msgStart + msgFields
                            });
                            toastEvent.fire();
                            $A.get("e.force:closeQuickAction").fire();
                        } else {
                            component.set("v.contractType", "single");
                            component.set("v.isInitialized", true);
                        }
                    } else {
                        if (instance.partner !== undefined && instance.partner !== null) {
                            component.set("v.contractType", "frame");
                        } else {
                            component.set("v.contractType", "none");
                        }
                    }
                }
            } else {
                let toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type": "error",
                    "title": "Error",
                    "message": "Something went wrong"
                });
                toastEvent.fire();
            }
        });

        $A.enqueueAction(action);

    },

    handleClose: function () {
        $A.get("e.force:closeQuickAction").fire();
    },

    createContract: function (component, event, helper) {
        if (component.get("v.mietkosten_eur") > 0 && component.get("v.strompreis_cnt") >= 0) {
            var verbrauch = component.get("v.stromverbrauch_cnt");
            if (verbrauch===undefined || verbrauch ===null) {
                var lead = component.get("v.lead");
                $A.get("e.force:closeQuickAction").fire();
                let toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type": "warning",
                    "mode": "sticky",
                    "title": "Verbrauchswert für hinterlegten ADM-Typ nicht gefunden",
                    "message": "Es kann kein Verbrauchswert für den ausgewählten Automatentypen (" + lead.ADM_Typ__c + ") " +
                        "ermittelt werden. Bitte wenden Sie sich mit diesem konkreten Fall an Ihre*n VL."
                });
                toastEvent.fire();
            } else {
                helper.handleShowModal(component, event, helper);
            }
        } else {
            let toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "type": "warning",
                "title": "Fehler",
                "message": "Die Felder müssen gefüllt sein!"
            });
            toastEvent.fire();
        }
    },

    changeMietkosten: function (component) {
        var m_thres = component.get("v.mietpreis_threshold");

        var m = component.get("v.mietkosten_eur");

        var mz = m * component.get("v.lead.Summe_aller_Module__c");

        component.set("v.mietzins", mz);
    },

    changeStrompreis: function (component) {
        var s_preis = component.get("v.strompreis_cnt");
        var s_verbrauch = component.get("v.stromverbrauch_cnt");

        var s_pauschale = (s_verbrauch * s_preis) / 100;

        component.set("v.strompauschale_eur", s_pauschale);
    }
});