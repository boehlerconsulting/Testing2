/**
 *@author       Mats Böhler
 *@created      07.08.2020
 *
 *
 *@description  TaskWorker
 *
 *
 *@changelog    07.08.2020 Mats Böhler  - Created
 *              
 * 
 */
public without sharing class TaskWorker {
	
	private List<Task> newTasks = new List<Task>();
	private Map<Id, Task> existingTaskByIds = new Map<Id, Task>();
	
	private static TaskWorker instance = null;
	
	public static TaskWorker getInstance () {
		if ( instance == null ) {
			instance = new TaskWorker();
		}
		return instance;
	}
	
	public void add ( Task task ) {
		if ( task.Id == null ) {
			newTasks.add( task );
		}
		else {
			existingTaskByIds.put( task.Id, task );
		}
	}
	
	public Boolean exists ( Task task ) {
		return existingTaskByIds.containsKey( task.Id );
	}
	
	public Task get ( Task task ) {
		return existingTaskByIds.get( task.Id );
	}
	
	public void process ( Boolean useAsynchronousProcessing ) {
		List<Task> tasks = new List<Task>();
		tasks.addAll( newTasks );
		tasks.addAll( existingTaskByIds.values() );
		newTasks.clear();
		existingTaskByIds.clear();
		
		if ( useAsynchronousProcessing
				&& !tasks.isEmpty()
				&& !System.isQueueable()
				&& !System.isFuture()
				&& !System.isBatch()
				&& isEnqueueable() ) {
			
			System.enqueueJob(
					new TaskUpsertQueueable( 'TaskWorker', tasks )
			);
		}
		else {
			upsert tasks;
		}
	}
	
	private Boolean isEnqueueable () {
		return Limits.getLimitQueueableJobs() - Limits.getQueueableJobs() > 0;
	}
}