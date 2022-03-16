/**
 *@author       Mats Böhler
 *@created      06.08.2020
 *
 *
 *@description  TaskUpsertQueueableTest
 *
 *
 *@changelog    06.08.2020 Mats Böhler  - Created
 *              
 * 
 */
@IsTest
private class TaskUpsertQueueableTest {
	
	@IsTest
	static void testSuccess () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			Account account = createAccount();
			
			Test.startTest();
			System.enqueueJob(
					new TaskUpsertQueueable(
							'Test',
							new List<Task> {
									createTask( 'Vertriebsmanager', account.Id )
							}
					)
			);
			Test.stopTest();
			
			System.assertEquals( 1, [ SELECT Id FROM Task WHERE AccountId = :account.Id ].size() );
		}
	}
	
	@IsTest
	static void testFailure () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			Account account = createAccount();
			Task task = createTask( 'Vertriebsmanager', account.Id );
			task.Aufgabenart__c = 'Individuelle Aufgabe (Sonstiges)';
			insert task;
			
			Test.startTest();
			task.OwnerId = null;
			System.enqueueJob(
					new TaskUpsertQueueable(
							'Test',
							new List<Task> {
									task
							}
					)
			);
			Test.stopTest();
			
			
			Logbuch__c logbuch = [
					SELECT
							Id,
							Job__c,
							Herkunft__c,
							Meldung__c,
							Type__c,
							Zeitpunkt__c
					FROM Logbuch__c
					LIMIT 1
			];
			System.assertEquals( 'Test', logbuch.Job__c );
			System.assertEquals( 'AccountId: ' + account.Id, logbuch.Herkunft__c );
			System.assert( logbuch.Meldung__c.contains('Zugeordnet zu ID: Inhaber kann nicht leer sein') );
			System.assertEquals( 'Aufgabenart: Individuelle Aufgabe (Sonstiges)', logbuch.Type__c );
		}
	}
	
	private static Task createTask ( String auftragnehmer, Id whatID ) {
		
		Task task = ( Task ) TestFactory.createSObject(
				new Task(
						Auftragnehmer__c = auftragnehmer,
						WhatId = whatID
				),
				false
		);
		return task;
	}
	
	private static Account createAccount () {
		
		Account account = ( Account ) TestFactory.createSObject(
				new Account(
				
				),
				true
		);
		return account;
	}
}