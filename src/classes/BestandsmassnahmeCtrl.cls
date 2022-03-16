/**
 *@author       Mats Böhler
 *@created      30.08.2021
 *
 *
 *@description  BestandsmassnahmeCtrl
 *
 *
 *@changelog    30.08.2021 Mats Böhler  - Created
 *              
 * 
 */
public with sharing class BestandsmassnahmeCtrl {
	
	@AuraEnabled
	public static void createLead ( String accountId, String accountString ) {
		Savepoint savepoint = Database.setSavepoint();
		try {
			updateAccount( accountId, accountString );
		}
		catch ( Exception e ) {
			Database.rollback( savepoint );
			throw new AuraHandledException( e.getMessage() );
		}
	}
	
	@AuraEnabled
	public static void saveAccount ( String accountId, String accountString ) {
		Savepoint savepoint = Database.setSavepoint();
		try {
			updateAccount( accountId, accountString );
			updateTasks( accountId );
		}
		catch ( Exception e ) {
			Database.rollback( savepoint );
			throw new AuraHandledException( e.getMessage() );
		}
	}
	
	private static Account updateAccount ( String accountId, String accountString ) {
		Account account = ( Account ) JSON.deserialize( accountString, Account.class );
		account.Id = accountId;
		update account;
		return account;
	}
	
	private static void updateTasks ( String accountId ) {
		List<Task> tasks = new List<Task>();
		for ( Task task : [
				SELECT Id
				FROM Task
				WHERE WhatId = :accountId
				AND Aufgabenart__c = 'Kündigungsrückgewinnung Pack-/Poststation'
				AND Status != 'Zurückgezogen (Nur AG)'
				AND IsClosed = FALSE
		] ) {
			task.Status = 'Zurückgezogen (Nur AG)';
			tasks.add( task );
		}
		update tasks;
	}
}