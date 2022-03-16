/**
 *@author       Mats Böhler
 *@created      10.09.2020
 *
 *
 *@description  FilialeToTaskSyncerScheduleBatch
 *
 *
 *@changelog    10.09.2020 Mats Böhler  - Created
 *              
 * 
 */
public without sharing class FilialeToTaskSyncerScheduleBatch implements Schedulable, Database.Batchable<SObject>, Database.RaisesPlatformEvents {
	
	/*
	
	Execute as anonymous code for scheduling
	Would execute daily at 1pm with below code
	
	System.schedule('FilialeToTaskSyncerScheduleBatch', '0 0 13 * * ? *', new FilialeToTaskSyncerScheduleBatch());

	*/
	
	public void execute ( SchedulableContext ctx ) {
		
		Database.executeBatch( new FilialeToTaskSyncerScheduleBatch (), 200 );
	}
	
	public Database.QueryLocator start ( Database.BatchableContext bc ) {
		
		return Database.getQueryLocator( [
				SELECT
						Id,
						AccountId
				FROM Task
				WHERE CreatedDate = LAST_N_DAYS:7
				AND ( NL_Brief__c = NULL OR NL_Brief__c = 'n.a.' OR ( NOT NL_Brief__c LIKE 'NL%'))
				AND AccountId != NULL
				AND CreatedDate > 2021-02-11T00:00:00.000Z
		] );
	}
	
	public void execute ( Database.BatchableContext bc, List<Task> tasks ) {
		try {
			syncFilialInfosToTasks( tasks );
			update tasks;
		}
		catch ( Exception e ) {
			new HW_ErrorLogging().logException(
					e,
					new Map<Id, Task>( tasks ).keySet(),
					'MYPM-653 Erweiterung PrioHilfe - Filterung Niederlassung'
			);
		}
	}
	
	public void finish ( Database.BatchableContext bc ) {
		//Sonarqube -> does nothing
	}
	
	private void syncFilialInfosToTasks ( List<Task> tasks ) {
		Map<Id, Account> accountsById = loadAccountsById( tasks );
		for ( Task task : tasks ) {
			Account account = accountsById.get( task.AccountId );
			task.ASt_Nummer__c = account.ASt_Nummer__c;
			task.Ast_Id__c = account.ASt_ID__c;
			task.Ast_Name__c = account.ASt_Name__c;
			task.Debitor__c = account.Debitor__c;
			task.Filialart_OZ__c = account.Filialart__c + '/' + account.Filialtyp_OZ__c;
			task.Strasse_Filialanschrift__c = account.ShippingStreet;
			task.Telefon__c = account.Phone;
			task.VG__c = account.GL_Name__c;
			task.Vertriebssegment_Filiale__c = account.Vertriebssegment__c;
			task.NL_Brief__c = account.NL_Brief_Lookup__r.Name == null
					? 'n.a.'
					: account.NL_Brief_Lookup__r.Name.startsWith( 'NL' )
							? account.NL_Brief_Lookup__r.Name
							: 'NL ' + account.NL_Brief_Lookup__r.Name;
			task.Kundenrelevanz_Klasse__c = account.Kundenrelevanz_Klasse__c;
		}
	}
	
	private Map<Id, Account> loadAccountsById ( List<Task> tasks ) {
		Set<String> accountIds = new Set<String>();
		for ( Task task : tasks ) {
			accountIds.add( task.AccountId );
		}
		accountIds.remove( null );
		
		return new Map<Id, Account>( [
				SELECT
						Id,
						ASt_Nummer__c,
						ASt_ID__c,
						ASt_Name__c,
						Debitor__c,
						Filialart__c,
						Filialtyp_OZ__c,
						ShippingStreet,
						Phone,
						GL_Name__c,
						Vertriebssegment__c,
						NL_Brief_Lookup__r.Name,
						Kundenrelevanz_Klasse__c
				FROM Account
				WHERE Id IN :accountIds
		] );
	}
}