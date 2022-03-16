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
private class HW_SharedVertragsUtils_Test {
    @IsTest
    static void getPartner() {
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

        StrategischerPartner__mdt partner = HW_SharedVertragsUtils.getStrategischePartner(lead);
        Stromverbrauch__mdt sv = HW_SharedVertragsUtils.getStromverbrauch(lead);
        lead = HW_SharedVertragsUtils.getLead(lead.Id);

        System.assertEquals(null,partner);
        System.assertNotEquals(null,sv);
        System.assertNotEquals(null,lead);

        System.assertEquals(4,lead.Summe_aller_Module__c);

        Test.stopTest();
    }

    @IsTest
    static void getOrgE_DP() {
        User u = TestUser.create( TestUser.UserType.ADMIN );
        u.OrgE_DP__c = 'Extern';
        update u;

        System.runAs(u) {

            OrgE_DP__c orge = new OrgE_DP__c(Leiter__c = u.Id, Koordinator__c = u.Id, OrgE_DP_Name__c = 'Extern');
            insert orge;

            System.assertEquals('Extern',HW_SharedVertragsUtils.getOrgE_DP(u.Id).OrgE_DP_Name__c);
        }
    }

    @IsTest
    static void testCanGenAnschreiben() {
        User u = TestUser.create( TestUser.UserType.ADMIN );
        u.OrgE_DP__c = 'TESTVL';
        update u;

        System.runAs(u) {


            OrgE_DP__c orgEDP = ( OrgE_DP__c ) TestFactory.createSObject(
                    new OrgE_DP__c(
                            Name = 'TESTVL'
                    ),
                    true);

            Id accountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
                    .get('OrgE_Dummy').getRecordTypeId();

            Account account = ( Account ) TestFactory.createSObject(
                    new Account(
                            Name = 'TESTVL',
                            RecordTypeId = accountRecordTypeId
                    ),
                    true);


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
                            Fachmodule__c = 3,
                            VL__c = account.Id
                    ),
                    true
            );

            Test.startTest();
            Boolean caGen = HW_SharedVertragsUtils.canGenAnschreibenCSG(lead.Id);
            System.assertEquals(true, caGen);
            Test.stopTest();
        }
    }

    @IsTest
    static void testQueryAllFields() {

        Account filialPartner = ( Account ) TestFactory.createSObject(
                new Account (
                        Name = 'Chuck Berry',
                        Filialtyp_OZ__c = '82',
                        ShippingCity = 'Bonn',
                        ShippingStreet ='BonBon',
                        ShippingPostalCode = '05643',
                        RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('OrgE Dummy').getRecordTypeId()
                ),
                true
        );

        Test.startTest();

        filialPartner = (Account) HW_SharedVertragsUtils.queryAllFields('Account',filialPartner.Id,'Id');

        System.assertEquals('Bonn', filialPartner.ShippingCity);

        filialPartner = (Account) HW_SharedVertragsUtils.queryAllFields('Account',filialPartner.Id,'Id','RecordType.DeveloperName');

        System.assertEquals('OrgE_Dummy', filialPartner.RecordType.DeveloperName);

        Test.stopTest();
    }

    @IsTest
    static void testGetUserOrgeDpDummyAccountId() {

        System.assertEquals(null, HW_SharedVertragsUtils.getUserOrgeDpDummyAccountId('Hamburg'));
    }
}