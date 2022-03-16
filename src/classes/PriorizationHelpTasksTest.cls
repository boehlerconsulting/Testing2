/**
 *@author       Mats Böhler
 *@created      30.03.2020
 *
 *
 *@description  PriorizationHelpTasksTest
 *
 *
 *@changelog    30.03.2020 Mats Böhler  - Created
 *              
 * 
 */
@IsTest
private class PriorizationHelpTasksTest {
	@IsTest
	static void testOhneAkquise () {
		
		setupTestData( 'ohne Akquise' );
		
		TestFactoryDefaults.FilterCriteria filterCriteria = new TestFactoryDefaults.FilterCriteria(
				false,
				1,
				null,
				'Task',
				'ohne Akquise',
				'KennzifferPrioritaet__c',
				'desc',
				'Nicht begonnen',
				'NL Freiburg'
		);
		
		Test.startTest();
		PriorizationHelpTasks instance =
				( PriorizationHelpTasks )
						JSON.deserialize(
								HW_Priorisierungshilfe_LC.loadData(
										JSON.serialize( filterCriteria )
								),
								PriorizationHelpTasks.class
						) ;
		Test.stopTest();
		
		System.assertNotEquals( null, instance.columns );
		System.assertNotEquals( null, instance.aufgaben );
	
	}
	
	@IsTest
	static void testMitAkquise () {
		
		setupTestData( 'mit Akquise' );
		
		TestFactoryDefaults.FilterCriteria filterCriteria = new TestFactoryDefaults.FilterCriteria(
				false,
				1,
				null,
				'Task',
				'mit Akquise',
				'KennzifferPrioritaet__c',
				'desc',
				'offen',
				'NL Freiburg'
		);
		
		Test.startTest();
		PriorizationHelpTasks instance =
				( PriorizationHelpTasks )
						JSON.deserialize(
								HW_Priorisierungshilfe_LC.loadData(
										JSON.serialize( filterCriteria )
								),
								PriorizationHelpTasks.class
						) ;
		Test.stopTest();
		
		System.assertNotEquals( null, instance.columns );
		System.assertNotEquals( null, instance.aufgaben );
	
	}
	
	@IsTest
	static void testClosed () {
		
		setupTestData( 'mit Akquise' );
		
		TestFactoryDefaults.FilterCriteria filterCriteria = new TestFactoryDefaults.FilterCriteria(
				false,
				1,
				null,
				'Task',
				'mit Akquise',
				'KennzifferPrioritaet__c',
				'desc',
				'geschlossen',
				'NL Freiburg'
		);
		
		Test.startTest();
		PriorizationHelpTasks instance =
				( PriorizationHelpTasks )
						JSON.deserialize(
								HW_Priorisierungshilfe_LC.loadData(
										JSON.serialize( filterCriteria )
								),
								PriorizationHelpTasks.class
						) ;
		Test.stopTest();
		
		System.assertNotEquals( null, instance.columns );
		System.assertNotEquals( null, instance.aufgaben );
	
	}
	
	@IsTest
	static void testAmpelValue () {
		
		Task task = setupTestData( 'mit Akquise' );
		
		Test.startTest();
		PriorizationHelpTasks instance = new PriorizationHelpTasks();
		instance.loadAmpelKonfigurations();
		instance.getAmpelValue(task);
		task.Aufgabenart__c = 'Akquiseauftrag DHL Paketshop + Detail';
		instance.getAmpelValue(task);
		task.Aufgabenart__c = 'Akquiseauftrag Filiale + Detail';
		instance.getAmpelValue(task);
		Test.stopTest();

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
						Version__c = version,
						AmpelAktiviert__c = true
				),
				'TestFactoryDefaults.PriohilfeAufgabenverwaltungDefaults',
				true
		);
		
		Task akquise = new Task(
				TerminiertZum__c = Date.today().addDays( 13 ),
				Status = 'Nicht begonnen',
				Aufgabenart__c = 'Partnerkontaktpflege',
				RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
						.get( 'Aufgaben_ZG_Vertrieb' ).getRecordTypeId(),
				WhatId = account.Id,
				PriohilfeAufgabenverwaltung__c = verwaltung.Id,
				Typc__c = 'Sonstiges',
				NL_Brief__c = 'NL Freiburg'
		);
		insert akquise;
		
		Task task = new Task(
				TerminiertZum__c = Date.today().addDays( 13 ),
				Status = 'Nicht begonnen',
				Aufgabenart__c = 'Partnerkontaktpflege',
				RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
						.get( 'Aufgaben_ZG_Vertrieb' ).getRecordTypeId(),
				WhatId = account.Id,
				PriohilfeAufgabenverwaltung__c = verwaltung.Id,
				Typc__c = 'Sonstiges',
				NL_Brief__c = 'NL Freiburg'
		);
		insert task;
		return task;
	}
}