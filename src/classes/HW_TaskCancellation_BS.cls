/**
 *@author       Mats Böhler
 *@created      19.09.2019
 *@version      1.0
 *@since        45.0
 *
 *
 *@description  HW_TaskCancellation_BS
 *
 *
 *@changelog    19.09.2019 Mats Böhler  - Created
 *              
 * 
 */
public without sharing class HW_TaskCancellation_BS implements Schedulable, Database.Batchable<SObject>, Database.RaisesPlatformEvents {
	
	public void execute ( SchedulableContext ctx ) {
		
		Database.executeBatch( new HW_TaskCancellation_BS (), 200 );
	}
	
	public Database.QueryLocator start ( Database.BatchableContext bc ) {
		
		return Database.getQueryLocator( [
				SELECT
						Id
				FROM Task
				WHERE IsClosed = FALSE
				AND Verfallsdatum__c <= TODAY
		] );
	}
	
	public void execute ( Database.BatchableContext bc, List<Task> tasks ) {
		
		cancelTasks( tasks );
	}
	
	public void finish ( Database.BatchableContext bc ) {
		//Sonarqube -> does nothing
	}
	
	private void cancelTasks ( List<Task> tasks ) {
		for ( Task task : tasks ) {
			task.Erledigungsvermerk__c = Label.TaskErledigungsvermerk;
			task.Status = Label.TaskStatus;
		}
		update tasks;
	}
}