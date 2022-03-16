/**
 *@author       Mats Böhler
 *@created      11.10.2019
 *@version      1.0
 *@since        45.0
 *
 *
 *@description  HW_Priorisierungshilfe_LCT
 *
 *
 *@changelog    11.10.2019 Mats Böhler  - Created
 *              
 * 
 */
@IsTest
private class HW_Priorisierungshilfe_LCT {
	
	@IsTest
	static void testLoadDataTasks () {
		
		setupTestData( 'ohne Akquise' );
		
		TestFactoryDefaults.FilterCriteria filterCriteria = new TestFactoryDefaults.FilterCriteria(
				false,
				1,
				null,
				'Task',
				'ohne Akquise',
				'KennzifferPrioritaet__c',
				'desc',
				'offen',
				''
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
	static void testLoadDataTasksMitAkquise () {
		
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
				''
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
	static void testLoadDataAccounts () {
		
		setupTestData( 'ohne Akquise' );
		setupTestData( 'ohne Akquise' );
		
		TestFactoryDefaults.FilterCriteria filterCriteria = new TestFactoryDefaults.FilterCriteria(
				null,
				'Account'
		);
		
		Test.startTest();
		PriorizationHelpAccounts instance =
				( PriorizationHelpAccounts )
						JSON.deserialize(
								HW_Priorisierungshilfe_LC.loadData(
										JSON.serialize( filterCriteria )
								),
								PriorizationHelpAccounts.class
						) ;
		Test.stopTest();
		
		System.assertNotEquals( null, instance.columns );
		System.assertNotEquals( null, instance.filialen );
	}
	
	@IsTest
	static void testLoadDataTermin () {
		
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
	
	@IsTest
	static void testCloseTasks () {
		
		Task task = setupTestData( 'ohne Akquise' );
		
		TestFactoryDefaults.FilterCriteria filterCriteria = new TestFactoryDefaults.FilterCriteria(
				false,
				1,
				null,
				'Task',
				'ohne Akquise',
				'KennzifferPrioritaet__c',
				'desc',
				'offen',
				''
		);
		filterCriteria.selectedTaskIds = task.Id;
		filterCriteria.changedTaskIds = task.Id;
		
		Test.startTest();
		task.Typc__c = 'Besuch';
		HW_Priorisierungshilfe_LC.closeTasks(
				JSON.serialize( filterCriteria ),
				JSON.serialize( new List<Task> {
						task
				} )
		);
		Test.stopTest();
		
		System.assertEquals( 1, [ SELECT Id FROM Task WHERE Status = 'Erledigt' ].size() );
	}
	
	@IsTest
	static void testCloseTasksOnlyChanged () {
		
		Task task = setupTestData( 'ohne Akquise' );
		
		TestFactoryDefaults.FilterCriteria filterCriteria = new TestFactoryDefaults.FilterCriteria(
				false,
				1,
				null,
				'Task',
				'ohne Akquise',
				'KennzifferPrioritaet__c',
				'desc',
				'offen',
				''
		);
		filterCriteria.selectedTaskIds = '';
		filterCriteria.changedTaskIds = task.Id;
		
		Test.startTest();
		task.Typc__c = 'Besuch';
		HW_Priorisierungshilfe_LC.closeTasks(
				JSON.serialize( filterCriteria ),
				JSON.serialize( new List<Task> {
						task
				} )
		);
		Test.stopTest();
		
		System.assertEquals( 0, [ SELECT Id FROM Task WHERE Status = 'Erledigt' ].size() );
	}
	
	@IsTest
	static void testSaveTasks () {
		
		Task task = setupTestData( 'ohne Akquise' );
		
		TestFactoryDefaults.FilterCriteria filterCriteria = new TestFactoryDefaults.FilterCriteria(
				false,
				1,
				null,
				'Task',
				'ohne Akquise',
				'KennzifferPrioritaet__c',
				'desc',
				'offen',
				''
		);
		
		Test.startTest();
		task.Typc__c = 'Besuch';
		HW_Priorisierungshilfe_LC.saveTasks(
				JSON.serialize( filterCriteria ),
				JSON.serialize( new List<Task> {
						task
				} ),
				task.Id
		);
		Test.stopTest();
		
		System.assertEquals( 1, [ SELECT Id FROM Task WHERE Typc__c = 'Besuch' ].size() );
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
				Verfallsdatum__c = Date.today().addDays( 28 ),
				Status = 'Nicht begonnen',
				Aufgabenart__c = 'Partnerkontaktpflege',
				RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
						.get( 'Aufgaben_ZG_Vertrieb' ).getRecordTypeId(),
				Erledigung_bis_zum__c = Date.today().addDays( 14 ),
				WhatId = account.Id
		);
		insert task;
		return task;
	}
}