/**
 *@author       Mats Böhler
 *@created      10.02.2020
 *
 *
 *@description  HW_PriorizationHelpService_T
 *
 *
 *@changelog    10.02.2020 Mats Böhler  - Created
 *              
 * 
 */
@IsTest
private class HW_PriorizationHelpService_T {
	
	@IsTest
	static void testSetInitialValuesPriorizationHelp () {
		
		insertPriohilfeVerwaltung( 'Partnerkontaktpflege', 'Schlagworte' );
		Task task = insertTask();
		
		Test.startTest();
		Database.executeBatch( new HW_PriorizationHelpInitiator_BS (), 200 );
		task.initialisierePriorisierungshilfe__c = true;
		update task;
		Database.executeBatch( new HW_PriorizationHelpInitiator_BS (), 200 );
		Test.stopTest();
		
		System.assertEquals( 'Schlagworte', [ SELECT Id, PriohilfeAufgabenverwaltung__r.Schlagworte__c FROM Task LIMIT 1 ].PriohilfeAufgabenverwaltung__r.Schlagworte__c );
	}
	
	private static Task insertTask () {
		
		Account account = new Account(
				Name = 'Test',
				RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
						.get( 'Filiale_Dummy' ).getRecordTypeId()
		);
		insert account;
		
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
	
	private static PriohilfeVerwaltung__c insertPriohilfeVerwaltung ( String taskType, String schlagworte ) {
		PriohilfeVerwaltung__c priohilfeVerwaltung = new PriohilfeVerwaltung__c(
				AufgabenartGlobal__c = taskType,
				Schlagworte__c = schlagworte
		);
		insert priohilfeVerwaltung;
		return priohilfeVerwaltung;
	}
}