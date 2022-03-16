/**
 *@author       Mats Böhler
 *@created      25.09.2019
 *@version      1.0
 *@since        45.0
 *
 *
 *@description  HW_Priorisierungshilfe_LC
 *              DPSA-878
 *              DPSA-904
 *              DPSA-918
 *
 *@changelog    25.09.2019 Mats Böhler  - Created
 *              
 * 
 */
public with sharing class HW_Priorisierungshilfe_LC {
	
	private PriorizationHelpSetting setting = new PriorizationHelpSetting();
	private String responseJSON = '';
	
	@AuraEnabled
	public static String loadData ( String filterCriteria ) {
		HW_Priorisierungshilfe_LC instance = new HW_Priorisierungshilfe_LC();
		instance.setting.setInstanceVariables( filterCriteria );
		
		switch on instance.setting.sObjectType {
			when 'Task' {
				
				instance.responseJSON = new PriorizationHelpTasks().load( instance.setting );
			}
			when 'Account' {
				
				instance.responseJSON = new PriorizationHelpAccounts().load( instance.setting );
			
			}
			when 'Termin' {
				
				instance.responseJSON = new PriorizationHelpTermine().load( instance.setting );
			}
			when else {
				instance.responseJSON = null;
			}
		}
		return instance.responseJSON;
	}
	
	@AuraEnabled
	public static String closeTasks ( String filterCriteria, String tasksString ) {
		
		try {
			update closedTasks( filterCriteria, tasksString );
		}
		catch ( Exception e ) {
			
			throw new AuraHandledException( e.getMessage() );
		}
		return loadData( filterCriteria );
	}
	
	@AuraEnabled
	public static String saveTasks ( String filterCriteria, String tasksString, String changedTasks ) {
		
		List<Task> tasks = ( List<Task> ) JSON.deserialize( tasksString, List<Task>.class ) ;
		List<Task> tasksToBeSaved = new List<Task>();
		for ( Task task : tasks ) {
			if ( changedTasks.contains( task.Id ) ) {
				tasksToBeSaved.add( task );
			}
		}
		try {
			update tasksToBeSaved;
		}
		catch ( Exception e ) {
			
			throw new AuraHandledException( e.getMessage() );
		}
		return loadData( filterCriteria );
	}
	
	private static List<Task> closedTasks ( String filterCriteria, String tasksString ) {
		Map<String, Object> filterCriteriaByName =
				( Map<String, Object> )
						JSON.deserializeUntyped( filterCriteria );
		String selectedTasks = ( String ) filterCriteriaByName.get( 'selectedTaskIds' );
		String changedTasks = ( String ) filterCriteriaByName.get( 'changedTaskIds' );
		List<Task> tasks = ( List<Task> ) JSON.deserialize( tasksString, List<Task>.class ) ;
		List<Task> tasksToBeSaved = new List<Task>();
		for ( Task task : tasks ) {
			if ( selectedTasks.contains( task.Id ) ) {
				task.Status = 'Erledigt';
				tasksToBeSaved.add( task );
			}
			else if ( changedTasks.contains( task.Id ) ) {
				tasksToBeSaved.add( task );
			}
			else{
				//Sonarqube --> do nothing
			}
		}
		return tasks;
	}
}