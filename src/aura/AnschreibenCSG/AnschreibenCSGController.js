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
 * 03.03.21      Stefan Richter  Initial release.
 **/
({
    doInit: function (component, event, helper) {
        //MYPM-708
        helper.saveAnschreibenCSG(component, helper);
    }
});