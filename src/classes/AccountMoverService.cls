/**
 *@author       Mats Böhler
 *@created      13.07.2020
 *
 *
 *@description  AccountMoverService
 *
 *
 *@changelog    13.07.2020 Mats Böhler  - Created
 *              
 * 
 */
public without sharing class AccountMoverService {
	
	public enum Type {
		EROEFFNUNG,
		SCHLIESSUNG
	}
	
	private AccountMoverService.Type moverType = null;
	private Set<Id> accountIds = null;
	private String dateFieldName = '';
	private String taskDescription = '';
	private String metadataKey = '';
	private List<String> taskTypes = new List<String>();
	
	public AccountMoverService execute ( AccountMoverService.Type type ) {
		this.moverType = type;
		return this;
	}
	
	public AccountMoverService setAccountIds ( Set<Id> accountIds ) {
		this.accountIds = accountIds;
		return this;
	}
	
	public void moveTasks () {
		if (accountIds.isEmpty() || Trigger.isInsert ) {
			return;
		}
		if ( moverType == AccountMoverService.Type.EROEFFNUNG ) {
			dateFieldName = 'Eroeffnungsdatum__c';
			taskDescription = 'Verschiebung Eröffnung auf den {0}; Verschiebung um {1} Tage!';
			metadataKey = 'Eroeffnung';
		}
		else if ( moverType == AccountMoverService.Type.SCHLIESSUNG ) {
			dateFieldName = 'Schliessung_zum__c';
			taskDescription = 'Verschiebung Schließung auf den {0}; Verschiebung um {1} Tage!';
			metadataKey = 'Schliessung';
		}
		else{
			//Sonarqube --> do nothing
		}
		loadMetadata();
		TaskWorker uow = TaskWorker.getInstance();
		for ( Task task : [
				SELECT
						Id,
						AccountId,
						ActivityDate,
						Erledigung_bis_zum__c,
						Auftragnehmer__c,
						Aufgabenart__c,
						WhatId,
						Description
				FROM Task
				WHERE AccountId IN :accountIds
				AND Aufgabenart__c IN :taskTypes
				AND IsClosed = FALSE
		] ) {
			Task existingTask = uow.exists( task ) ? uow.get( task ) : task;
			Date oldDate = ( Date ) Trigger.oldMap.get( existingTask.AccountId ).get( dateFieldName );
			Date newDate = ( Date ) Trigger.newMap.get( existingTask.AccountId ).get( dateFieldName );
			Integer differenceInDays = oldDate.daysBetween( newDate );
			existingTask.ActivityDate = existingTask.ActivityDate.addDays( differenceInDays );
			existingTask.Erledigung_bis_zum__c = existingTask.Erledigung_bis_zum__c.addDays( differenceInDays );
			existingTask.Description = String.format(
					taskDescription,
					new List<Object> {
							String.valueOf( ( Date ) Trigger.newMap.get( existingTask.AccountId ).get( dateFieldName ) ),
							differenceInDays
					} ) + ' ' + task.Description;
			uow.add( existingTask );
		}
	}
	
	private void loadMetadata () {
		for ( AufgabenverschiebungEinstellung__mdt einstellung : [
				SELECT
						Id,
						Aufgabenart__c
				FROM AufgabenverschiebungEinstellung__mdt
				WHERE Typ__c = :metadataKey
		] ) {
			taskTypes.add( einstellung.Aufgabenart__c );
		}
	}
}