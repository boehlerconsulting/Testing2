/**
 *@author       Mats Böhler
 *@created      19.09.2019
 *@version      1.0
 *@since        45.0
 *
 *
 *@description  HW_TaskCancellation_BST
 *
 *
 *@changelog    19.09.2019 Mats Böhler  - Created
 *              
 * 
 */
@IsTest
private class HW_TaskCancellation_BST {
	
	@IsTest
	static void testTaskCancellation () {
		
		insertOverdueTask();
		
		Test.startTest();
		Database.executeBatch( new HW_TaskCancellation_BS (), 200 );
		Test.stopTest();
		
		Task task = [
				SELECT
						Id,
						Erledigungsvermerk__c,
						Status
				FROM Task
				LIMIT 1
		];
		
		System.assertEquals( Label.TaskErledigungsvermerk, task.Erledigungsvermerk__c );
		System.assertEquals( Label.TaskStatus, task.Status );
	}
	
	@IsTest
	static void testSchedule () {
		Test.startTest();
		System.schedule( 'HW_TaskCancellation_BS_TEST', '0 0 3 * * ?', new HW_TaskCancellation_BS() );
		Test.stopTest();
	}
	
	private static void insertOverdueTask () {
		
		Account account = new Account(
				Name = 'Test',
				RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
						.get( 'Filiale_Dummy' ).getRecordTypeId()
		);
		insert account;
		
		insert new Task(
				Verfallsdatum__c = Date.today().addDays( -1 ),
				Status = 'Nicht begonnen',
				Aufgabenart__c = 'Partnerkontaktpflege',
				RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
						.get( 'Aufgaben_ZG_Vertrieb' ).getRecordTypeId(),
				Erledigung_bis_zum__c = Date.today(),
				WhatId = account.Id
		);
	}
}