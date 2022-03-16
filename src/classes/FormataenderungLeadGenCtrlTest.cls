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
 * 31.03.21      Stefan Richter  Initial release.
 **/
@IsTest
private class FormataenderungLeadGenCtrlTest {

    @IsTest
    static void canGenerateLead() {

        User u = TestUser.create( TestUser.UserType.ADMIN );
        u.OrgE_DP__c = '2007 VL Berlin';
        update u;


        System.runAs(u) {

            OrgE_DP__c orge = (OrgE_DP__c) TestFactory.createSObject(
                    new OrgE_DP__c (
                            Name = 'Berlin',
                            OrgE_DP_Name__c = 'Berlin'
                    ),
                    true
            );

            Account filialPartner = (Account) TestFactory.createSObject(
                    new Account (
                            Name = 'Berlin',
                            Filialtyp_OZ__c = '82',
                            ShippingCity = 'Berlin',
                            ShippingStreet = 'Berlin',
                            ShippingPostalCode = '05643',
                            GL__c = orge.Id,
                            GL_Name__c = 'Berlin',
                            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('OrgE Dummy').getRecordTypeId()
                    ),
                    true
            );

            Contract partnerContract = (Contract) TestFactory.createSObject(
                    new Contract (
                            Name = 'Berlin',
                            AccountId = filialPartner.Id
                    ),
                    true
            );

            Filialnetzaenderung__c fnae = (Filialnetzaenderung__c) TestFactory.createSObject(
                    new Filialnetzaenderung__c(
                            Filiale_Filialpartner__c = filialPartner.Id,
                            Grund__c = 'Formatänderung',
                            Netzentscheidung__c = 'Upgrade OZ 82 in Partner-Filiale OZ 84',
                            Schliessung_avisiert_fuer__c = Date.today() + 30,
                            Wunschformat__c = 'Partner-Filiale (OZ 84)'
                    ),
                    true
            );

            Id leadId;

            Test.startTest();

            leadId = FormataenderungLeadGenCtrl.generateLead(fnae.Id);

            Test.stopTest();

            System.assertNotEquals(null, leadId);
            System.assertNotEquals(null, [SELECT Id FROM Lead WHERE Id = :leadId]);
        }
    }

    @IsTest
    static void hasGenLeadPermission() {

        Account filialPartner = ( Account ) TestFactory.createSObject(
                new Account (
                        Name = 'Chuck Berry',
                        Filialtyp_OZ__c = '82'
                ),
                true
        );

        Filialnetzaenderung__c fnae = ( Filialnetzaenderung__c ) TestFactory.createSObject(
                new Filialnetzaenderung__c(
                        Filiale_Filialpartner__c = filialPartner.Id,
                        Grund__c = 'Formatänderung',
                        Netzentscheidung__c = 'Upgrade OZ 82 in Partner-Filiale OZ 84',
                        Schliessung_avisiert_fuer__c = Date.today()+30,
                        Wunschformat__c = 'Partner-Filiale (OZ 84)'
                ),
                true
        );

        String canGen;

        Test.startTest();

        fnae = HW_SharedVertragsUtils.getFnae(fnae.Id);
        canGen = FormataenderungLeadGenCtrl.canGenerateLead(fnae);

        Test.stopTest();

        System.assertEquals('',canGen);
    }

    @IsTest
    static void testHasExistingLead() {
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

        Filialnetzaenderung__c fnae = ( Filialnetzaenderung__c ) TestFactory.createSObject(
                new Filialnetzaenderung__c(
                        Filiale_Filialpartner__c = filialPartner.Id,
                        Grund__c = 'Formatänderung',
                        Netzentscheidung__c = 'Upgrade OZ 82 in Partner-Filiale OZ 84',
                        Schliessung_avisiert_fuer__c = Date.today()+30,
                        Wunschformat__c = 'Partner-Filiale (OZ 84)'

                ),
                true
        );

        Test.startTest();
        System.assertNotEquals('HASLEAD',FormataenderungLeadGenCtrl.hasExistingLead(fnae,''));
        System.assertEquals('',FormataenderungLeadGenCtrl.hasExistingLead(fnae,''));
        Test.stopTest();
    }
}