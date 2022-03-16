/**
 *@author       Mats Böhler
 *@created      13.10.2021
 *
 *
 *@description  TaskEvaluator
 *
 *
 *@changelog    13.10.2021 Mats Böhler  - Created
 *              
 * 
 */
public without sharing class TaskEvaluator {
	
	public static Boolean isChanged ( Task task, String field ) {
		if ( Trigger.isInsert ) {
			return true;
		}
		return task.get( field ) != getOldTasks().get( task.Id ).get( field );
	}
	
	private static Map<Id, Task> getOldTasks(){
		return ( Map<Id, Task> ) Trigger.oldMap;
	}
}