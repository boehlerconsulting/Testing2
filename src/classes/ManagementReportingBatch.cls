/**
 *@author       Mats Böhler
 *@created      23.11.2020
 *
 *
 *@description  ManagementReportingBatch
 *
 *
 *@changelog    23.11.2020 Mats Böhler  - Created
 *              
 * 
 */
public without sharing class ManagementReportingBatch implements Schedulable, Database.Batchable<SObject>, Database.RaisesPlatformEvents {

	public void execute ( SchedulableContext ctx ) {
		
		Database.executeBatch( new ManagementReportingBatch (), 1 );
	}
	
	public Database.QueryLocator start ( Database.BatchableContext bc ) {
		
		return Database.getQueryLocator( [
				SELECT
						Id
				FROM Lead
				WHERE RelevantFuerManagementReporting__c = TRUE
		] );
	}
	
	public void execute ( Database.BatchableContext bc, List<Lead> leads ) {
		try {
			TriggerHandler.bypass('LeadTriggerHandler');
			new ManagementReportingService().setClassification( new Map<Id, Lead>( leads ).keySet() );
			TriggerHandler.clearAllBypasses();
		}
		catch ( Exception e ) {
			new HW_ErrorLogging().logException( e, new Map<Id, Lead>( leads ).keySet(), 'Packstation - Klassifizierung Management Reporting' );
		}
	}
	
	public void finish ( Database.BatchableContext bc ) {
		//Sonarqube -> does nothing
	}
}