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
 * 24.11.20      Stefan Richter  Initial release.
 **/
@IsTest
private class HW_EinzelvertragPdfCtrl_Test {
    @IsTest
    static void testHW_RahmenvertragPdfCtrl() {

        Lead lead = ( Lead ) TestFactory.createSObject(
                new Lead(
                        RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName()
                                .get( 'Packstation' ).getRecordTypeId(),
                        Email = 'test@test.de',
                        FirstName = 'firstName',
                        LastName = 'lastName',
                        Company = 'Company',
                        ADM_Typ__c = 'PSK',
                        ZuordnungZuRahmenvertrag__c = 'Aldi Nord',
                        Solarpanel__c = 'Nein',
                        Steuermodule__c = '1',
                        Fachmodule__c = 3
                ),
                true
        );

        Test.startTest();

        ApexPages.currentPage().getParameters().put('id',lead.id);
        ApexPages.currentPage().getParameters().put('sp','12');
        ApexPages.currentPage().getParameters().put('mk','10');
        HW_EinzelvertragPdfCtrl evControl = new HW_EinzelvertragPdfCtrl();

        lead = evControl.getCurrentLead();
        System.assertEquals(4, lead.Summe_aller_Module__c);
        System.assertEquals('PM DPI Rhein-Main Team PM Commercial',evControl.getBezeichnung());
        System.assertEquals('Saalburgallee 19',evControl.getStrasse());
        System.assertEquals('60385',evControl.getPostleitzahl());
        System.assertEquals('Frankfurt', evControl.getOrt());
        //System.assertEquals(12,evControl.getStromverbrauch());

        Test.stopTest();
    }
}