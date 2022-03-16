/**
 *@author       Mats Böhler
 *@created      10.02.2020
 *
 *
 *@description  HW_PriorizationHelpInitiator_BS
 *
 *
 *@changelog    10.02.2020 Mats Böhler  - Created
 *              
 * 
 */
public without sharing class HW_PriorizationHelpInitiator_BS implements Schedulable, Database.Batchable<SObject>, Database.RaisesPlatformEvents {
	
	/*
	
	Execute as anonymous code for scheduling
	
	System.schedule('HW_PriorizationHelpInitiator_BS0', '0 0 * * * ?', new HW_PriorizationHelpInitiator_BS());
	System.schedule('HW_PriorizationHelpInitiator_BS05', '0 5 * * * ?', new HW_PriorizationHelpInitiator_BS());
	System.schedule('HW_PriorizationHelpInitiator_BS10', '0 10 * * * ?', new HW_PriorizationHelpInitiator_BS());
	System.schedule('HW_PriorizationHelpInitiator_BS15', '0 15 * * * ?', new HW_PriorizationHelpInitiator_BS());
	System.schedule('HW_PriorizationHelpInitiator_BS20', '0 20 * * * ?', new HW_PriorizationHelpInitiator_BS());
	System.schedule('HW_PriorizationHelpInitiator_BS25', '0 25 * * * ?', new HW_PriorizationHelpInitiator_BS());
	System.schedule('HW_PriorizationHelpInitiator_BS30', '0 30 * * * ?', new HW_PriorizationHelpInitiator_BS());
	System.schedule('HW_PriorizationHelpInitiator_BS35', '0 35 * * * ?', new HW_PriorizationHelpInitiator_BS());
	System.schedule('HW_PriorizationHelpInitiator_BS40', '0 40 * * * ?', new HW_PriorizationHelpInitiator_BS());
	System.schedule('HW_PriorizationHelpInitiator_BS45', '0 45 * * * ?', new HW_PriorizationHelpInitiator_BS());
	System.schedule('HW_PriorizationHelpInitiator_BS50', '0 50 * * * ?', new HW_PriorizationHelpInitiator_BS());
	System.schedule('HW_PriorizationHelpInitiator_BS55', '0 55 * * * ?', new HW_PriorizationHelpInitiator_BS());
	*/

	public void execute ( SchedulableContext ctx ) {
		
		Database.executeBatch( new HW_PriorizationHelpInitiator_BS (), 200 );
	}
	
	public Database.QueryLocator start ( Database.BatchableContext bc ) {
		
		return Database.getQueryLocator( [
				SELECT
						Id
				FROM Task
				WHERE initialisierePriorisierungshilfe__c = TRUE
		] );
	}
	
	public void execute ( Database.BatchableContext bc, List<Task> tasks ) {
		try {
			new HW_PriorizationHelpService().initialize( new Map<Id, Task>( tasks ).keySet() );
		}
		catch ( Exception e ) {
			new HW_ErrorLogging().logException(
					e,
					new Map<Id, Task>( tasks ).keySet(),
					'Initialisierung Priorisierungshilfe'
			);
		}
	}
	
	public void finish ( Database.BatchableContext bc ) {
		//Sonarqube -> does nothing
	}
}