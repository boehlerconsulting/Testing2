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
 * 06.01.21      Stefan Richter  Initial release.
 **/
@IsTest
private class AnschreibenCSGCtrlTest {
    @IsTest
    static void testAnschreibenCSGCtrl() {

        User u = TestUser.create( TestUser.UserType.ADMIN );
        u.OrgE_DP__c = 'Extern';
        update u;

        System.runAs(u) {

            OrgE_DP__c orge = new OrgE_DP__c(Leiter__c = u.Id, Koordinator__c = u.Id, OrgE_DP_Name__c = 'Extern', Name = 'Extern');
            orge.RecordTypeId = Schema.SObjectType.OrgE_DP__c.getRecordTypeInfosByDeveloperName().get('NL_Brief').getRecordTypeId();
            insert orge;

            Account acco = (Account) TestFactory.createSObject(
                    new Account(
                            Name = 'Ada',
                            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
                                    .get('Filialpartner').getRecordTypeId()
                    ),
                    true
            );

            Filialnetzaenderung__c fnae = (Filialnetzaenderung__c) TestFactory.createSObject(
                    new Filialnetzaenderung__c(
                            Filiale_Filialpartner__c = acco.Id,
                            Schliessung_avisiert_fuer__c = Date.today()+5,
                            RecordTypeId = Schema.SObjectType.Filialnetzaenderung__c.getRecordTypeInfosByDeveloperName()
                                    .get('Filiale').getRecordTypeId(),
                            NL_Brief__c = orge.Id
                    ),
                    true
            );

	        TriggerHandler.bypass('LeadTriggerHandler');
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
                            Filialnetzaenderung__c = fnae.Id,
                            Fachmodule__c = 3
                    ),
                    true
            );
	        TriggerHandler.clearBypass('LeadTriggerHandler');
	        
            Test.startTest();

            ApexPages.currentPage().getParameters().put('id', lead.id);
            AnschreibenCSGCtrl acsgController = new AnschreibenCSGCtrl();
            acsgController.dmlExecHook();

            lead = acsgController.getCurrentLead();

            System.assert(lead != null);

            Test.stopTest();
        }
    }

    @IsTest
    static void testSaveAnschreibenCSG () {
        User u = TestUser.create( TestUser.UserType.ADMIN );
        u.OrgE_DP__c = 'TESTVL';
        update u;

        System.runAs(u) {

            OrgE_DP__c orgEDP = (OrgE_DP__c) TestFactory.createSObject(
                    new OrgE_DP__c(
                            Name = 'TESTVL'
                    ),
                    true);

            Id accountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
                    .get('OrgE_Dummy').getRecordTypeId();

            Account account = (Account) TestFactory.createSObject(
                    new Account(
                            Name = 'TESTVL',
                            RecordTypeId = accountRecordTypeId
                    ),
                    true);


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
                            Fachmodule__c = 3,
                            VL__c = account.Id
                    ),
                    true
            );

            Test.startTest();
            AnschreibenCSGCtrl.saveAnschreibenCSG(lead.Id);
            Test.stopTest();
        }

    }
}