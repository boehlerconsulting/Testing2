/**
 *@author       Mats Böhler
 *@created      02.02.2021
 *
 *
 *@description  PoststationLeadDuplikatorCtrlTest
 *
 *
 *@changelog    02.02.2021 Mats Böhler  - Created
 *              
 * 
 */
@IsTest
private class PoststationLeadDuplikatorCtrlTest {
	
	@IsTest
	static void testInit () {
		Lead lead = setupTestData();
		
		Test.startTest();
		Id duplicatedLeadId = PoststationLeadDuplikatorCtrl.init( lead.Id );
		Test.stopTest();
		
		System.assertNotEquals( null, duplicatedLeadId );
	}
	
	private static Lead setupTestData () {
		Filialnetzaenderung__c filialnetzaenderung = new Filialnetzaenderung__c(
				RecordTypeId = Schema.SObjectType.Filialnetzaenderung__c.getRecordTypeInfosByDeveloperName()
						.get( 'Filiale' ).getRecordTypeId(),
				Neuer_Standort_PLZ__c = '11111',
				Filiale_Filialpartner__c = createOrgE().Id,
				Schliessung_avisiert_fuer__c = Date.today()
		);
		insert filialnetzaenderung;

		TriggerHandler.bypass('LeadTriggerHandler');
		Lead lead = ( Lead ) TestFactory.createSObject(
				new Lead(
						RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName()
								.get( 'Packstation' ).getRecordTypeId(),
						PostalCode = '12345',
						Filialnetzaenderung__c = filialnetzaenderung.Id
				),
				true
		);
		TriggerHandler.clearBypass('LeadTriggerHandler');
		return lead;
	}
	
	private static Account createOrgE () {
		PLZ_zu_VGL__c plzZuVGL = new PLZ_zu_VGL__c(
				Name = 'Test',
				PLZ_5_stellig__c = '12345',
				VGL25_OZ__c = '0815',
				VGL25_Name__c = 'Filiale 1'
		);
		insert plzZuVGL;
		OrgE_DP__c LO_OrgE = new OrgE_DP__c(
				Name = 'Gebiet 1',
				GL_OZ__c = 'GL0815',
				Koordinator__c = UserInfo.getUserId()
		);
		insert( LO_OrgE );
		Account LO_Filiale = new Account(
				Name = 'Filiale 1',
				ASt_ID__c = '12345',
				GL__c = LO_OrgE.Id,
				RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
						.get( 'OrgE_Dummy' ).getRecordTypeId()
		);
		insert LO_Filiale;
		return LO_Filiale;
	}
}