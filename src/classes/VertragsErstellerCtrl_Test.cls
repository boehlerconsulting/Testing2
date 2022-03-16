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
 * 12.11.20      Stefan Richter  Initial release.
 **/
@IsTest
private class VertragsErstellerCtrl_Test {
    @IsTest
    static void test_loadData() {
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
        VertragsErstellerCtrl instance = ( VertragsErstellerCtrl )
                JSON.deserialize(
                        VertragsErstellerCtrl.loadData( lead.Id ),
                        VertragsErstellerCtrl.class
                );
        System.assertEquals('PSK',instance.lead.ADM_Typ__c);
        System.assertEquals(4,instance.lead.Summe_aller_Module__c);
        Test.stopTest();
    }

    @IsTest
    static void test_saveData() {
        User u = TestUser.create( TestUser.UserType.ADMIN );
        u.OrgE_DP__c = 'Extern';
        update u;

        System.runAs(u) {

            OrgE_DP__c orge = new OrgE_DP__c(Leiter__c = u.Id, OrgE_DP_Name__c = 'Extern');
            insert orge;

            Lead lead = (Lead) TestFactory.createSObject(
                    new Lead(
                            RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName()
                                    .get('Packstation').getRecordTypeId(),
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
	        EmailDispatcherService.disableDeleteExistingContentDocumentLinks = true;

            Test.startTest();
            String jLead = JSON.serialize(lead);

            VertragsErstellerCtrl.saveData('' + jLead, 'frame');
            lead = [SELECT Id, VertragErstelltAm__c FROM Lead WHERE Id = :lead.Id];
            Event ts = [SELECT Id FROM Event WHERE Subject = 'Rahmenvertrag erstellt'].get(0);
            System.assertNotEquals(null, ts);
            System.assertEquals(Date.today(),lead.VertragErstelltAm__c);

            VertragsErstellerCtrl.saveData('' + jLead, 'single');
            lead = [SELECT Id, VertragErstelltAm__c FROM Lead WHERE Id = :lead.Id];
            ts = [SELECT Id FROM Event WHERE Subject = 'Einzelvertrag erstellt'].get(0);
            System.assertNotEquals(null, ts);
            System.assertEquals(Date.today(),lead.VertragErstelltAm__c);

            VertragsErstellerCtrl.sendMail ('' + jLead, '11', '22');
            lead = [SELECT Id, VertragErstelltAm__c FROM Lead WHERE Id = :lead.Id];
            ts = [SELECT Id  FROM Event WHERE Subject = 'Einzelvertrag erstellt'].get(0);
            System.assertNotEquals(null, ts);
            System.assertEquals(Date.today(),lead.VertragErstelltAm__c);

            String bas64pdf = VertragsErstellerCtrl.generateSinglePdf('' + jLead, '12', '15');
            System.assertNotEquals(null, bas64pdf);
            Test.stopTest();
        }
    }
}