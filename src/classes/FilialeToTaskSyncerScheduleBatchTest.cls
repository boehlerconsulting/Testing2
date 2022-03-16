/**
 *@author       Mats Böhler
 *@created      10.09.2020
 *
 *
 *@description  FilialeToTaskSyncerScheduleBatchTest
 *
 *
 *@changelog    10.09.2020 Mats Böhler  - Created
 *              
 * 
 */
@IsTest
private class FilialeToTaskSyncerScheduleBatchTest {
	
	@IsTest
	static void testBatch () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			Account account = createAccount();
			Task createdTask = ( Task ) TestFactory.createSObject(
					new Task(
							Aufgabenart__c = 'DHL Paketshop Kündigungsrückgewinnung',
							WhatId = account.Id
					),
					true
			);
			createdTask = [ SELECT Id, Telefon__c FROM Task WHERE Id = :createdTask.Id LIMIT 1 ];
			
			System.assertEquals( '0815', createdTask.Telefon__c );
			
			createdTask.Telefon__c = null;
			update createdTask;
			
			createdTask = [ SELECT Id, Telefon__c FROM Task WHERE Id = :createdTask.Id LIMIT 1 ];
			
			System.assertEquals( null, createdTask.Telefon__c );
			
			Test.startTest();
			Database.executeBatch( new FilialeToTaskSyncerScheduleBatch (), 200 );
			Test.stopTest();
			
			createdTask = [ SELECT Id, Telefon__c FROM Task WHERE Id = :createdTask.Id LIMIT 1 ];
			
			System.assertEquals( '0815', createdTask.Telefon__c );
		}
	}
	
	@IsTest
	static void testSchedule () {
		
		Test.startTest();
		System.schedule('FilialeToTaskSyncerScheduleBatchTest', '0 0 13 * * ? *', new FilialeToTaskSyncerScheduleBatch());
		Test.stopTest();
	}
	
	private static Account createAccount () {
		
		Account account = ( Account ) TestFactory.createSObject(
				new Account(
						Phone = '0815'
				),
				true
		);
		return account;
	}
}