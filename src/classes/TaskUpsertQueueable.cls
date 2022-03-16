/**
 *@author       Mats Böhler
 *@created      06.08.2020
 *
 *
 *@description  SObjectUpsertQueueable
 *
 *
 *@changelog    06.08.2020 Mats Böhler  - Created
 *              
 * 
 */
public without sharing class TaskUpsertQueueable implements Queueable {
	
	private List<Task> tasks = null;
	private List<Logbuch__c> logbuches = new List<Logbuch__c>();
	private String jobName;
	
	public TaskUpsertQueueable ( String jobName, List<Task> tasks ) {
		this.tasks = tasks;
		this.jobName = jobName;
	}
	
	public void execute ( QueueableContext context ) {
		List<Database.UpsertResult> upsertResults = Database.upsert( tasks, false );
		for ( Integer i = 0; i < upsertResults.size(); i++ ) {
			
			Database.UpsertResult result = upsertResults[ i ];
			Task task = tasks[ i ];
			if ( !result.isSuccess() ) {
				logException( result, task );
			}
		}
		try {
			insert logbuches;
		}
		catch ( Exception e ) {
			new HW_ErrorLogging().logException ( e, new Set<Id>(), 'Logging Failure in: TaskUpsertQueueable' );
		}
	}
	
	private void logException ( Database.UpsertResult result, Task task ) {
		String meldung = '';
		for ( Database.Error error : result.getErrors() ) {
			meldung = error.getStatusCode() + ' | ' + error.getMessage() + ' ***';
		}
		logbuches.add(
				new Logbuch__c(
						Job__c = jobName,
						Herkunft__c = 'AccountId: ' + task.WhatId,
						Meldung__c = meldung,
						Type__c = 'Aufgabenart: ' + task.Aufgabenart__c,
						Zeitpunkt__c = Datetime.now()
				)
		);
	}
}