/**
 *@author       Mats Böhler
 *@created      19.09.2019
 *@version      1.0
 *@since        45.0
 *
 *
 *@description  HW_ErrorLogging
 *
 *
 *@changelog    19.09.2019 Mats Böhler  - Created
 *              
 * 
 */
public without sharing class HW_ErrorLogging {
	
	private static final String BATCH_APEX = 'Batch Apex';
	
	public void logBatchException ( List<BatchApexErrorEvent> batchApexErrorEvents ) {
		
		Set<Id> asyncApexJobIds = new Set<Id>();
		for ( BatchApexErrorEvent batchApexErrorEvent : batchApexErrorEvents ) {
			asyncApexJobIds.add( batchApexErrorEvent.AsyncApexJobId );
		}
		
		Map<Id, AsyncApexJob> jobs = new Map<Id, AsyncApexJob>(
		[
				SELECT
						Id,
						ApexClass.Name
				FROM AsyncApexJob
				WHERE Id IN :asyncApexJobIds
		]
		);
		
		List<Logbuch__c> errorLoggings = new List<Logbuch__c>();
		for ( BatchApexErrorEvent batchApexErrorEvent : batchApexErrorEvents ) {
			errorLoggings.add(
					new Logbuch__c(
							Herkunft__c = jobs.containsKey( batchApexErrorEvent.AsyncApexJobId )
									? jobs.get( batchApexErrorEvent.AsyncApexJobId ).ApexClass.Name
									: '',
							Job__c = BATCH_APEX,
							Meldung__c = batchApexErrorEvent.StackTrace
									+ ' | ' + batchApexErrorEvent.Message
									+ ' | ' + batchApexErrorEvent.JobScope,
							Type__c = batchApexErrorEvent.ExceptionType,
							Zeitpunkt__c = Datetime.now()
					)
			);
		}
		insert errorLoggings;
	}
	
	public void logException ( Exception ex, Set<Id> scopeIds, String jobName ) {
		String className = ex.getStackTraceString().substringBefore( '\n' ).substringAfter( '.' ).substringBefore( '.' );
		String jobScope = '';
		for ( Id scopeId : scopeIds ) {
			jobScope += scopeId + ', \n';
		}
		insert new Logbuch__c(
				Job__c = jobName,
				Herkunft__c = className,
				Meldung__c = ex.getStackTraceString()
						+ ' | ' + ex.getMessage()
						+ ' | ' + jobScope,
				Type__c = ex.getTypeName(),
				Zeitpunkt__c = Datetime.now()
		);
	}
}