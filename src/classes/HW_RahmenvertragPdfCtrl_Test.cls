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
 * 26.10.20      Stefan Richter  Initial release.
 **/
@IsTest
private class HW_RahmenvertragPdfCtrl_Test {
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
        ApexPages.StandardController stdLead = new ApexPages.StandardController(lead);
        HW_RahmenvertragPdfCtrl  rvControl = new HW_RahmenvertragPdfCtrl();

        rvControl.dmlExecHook();

        Test.stopTest();
    }

    
}