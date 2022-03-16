/**
 *@author       Mats Böhler
 *@created      30.03.2020
 *
 *
 *@description  PriorizationHelpTermineTest
 *
 *
 *@changelog    30.03.2020 Mats Böhler  - Created
 *              
 * 
 */
@IsTest
private class PriorizationHelpTermineTest {
	@IsTest
	static void testLoad () {
		
		setupTestData( 'ohne Akquise' );
		
		TestFactoryDefaults.FilterCriteria filterCriteria = new TestFactoryDefaults.FilterCriteria(
				false,
				1,
				null,
				'Termin',
				'ohne Akquise',
				'KennzifferPrioritaet__c',
				'desc',
				'offen',
				''
		);
		
		Test.startTest();
		PriorizationHelpTermine instance =
				( PriorizationHelpTermine )
						JSON.deserialize(
								HW_Priorisierungshilfe_LC.loadData(
										JSON.serialize( filterCriteria )
								),
								PriorizationHelpTermine.class
						) ;
		Test.stopTest();
		
		System.assertNotEquals( null, instance.columns );
		System.assertNotEquals( null, instance.termine );
		
	}
	
	private static Task setupTestData ( String version ) {
		
		Account account = new Account(
				Name = 'Test',
				RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
						.get( 'Filiale_Dummy' ).getRecordTypeId()
		);
		insert account;
		
		PriohilfeAufgabenverwaltung__c verwaltung = ( PriohilfeAufgabenverwaltung__c ) TestFactory.createSObject(
				new PriohilfeAufgabenverwaltung__c(
						Version__c = version
				),
				'TestFactoryDefaults.PriohilfeAufgabenverwaltungDefaults',
				true
		);
		
		Task task = new Task(
				TerminiertZum__c = Date.today().addDays( 13 ),
				Status = 'Nicht begonnen',
				Aufgabenart__c = 'Partnerkontaktpflege',
				RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
						.get( 'Aufgaben_ZG_Vertrieb' ).getRecordTypeId(),
				WhatId = account.Id,
				PriohilfeAufgabenverwaltung__c = verwaltung.Id,
				Typc__c = 'Sonstiges'
		);
		insert task;

		Task existingTask = new Task(
				TerminiertZum__c = Date.today().addDays( 13 ),
				Status = 'Nicht begonnen',
				Aufgabenart__c = 'Partnerkontaktpflege',
				RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
						.get( 'Aufgaben_ZG_Vertrieb' ).getRecordTypeId(),
				WhatId = account.Id,
				PriohilfeAufgabenverwaltung__c = verwaltung.Id,
				Typc__c = 'Sonstiges'
		);
		insert existingTask;
		return task;
	}
}