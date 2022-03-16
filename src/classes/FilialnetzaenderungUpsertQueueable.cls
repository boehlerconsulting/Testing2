/**
 *@author       Mats Böhler
 *@created      10.08.2020
 *
 *
 *@description  FilialnetzaenderungUpsertQueueable
 *
 *
 *@changelog    10.08.2020 Mats Böhler  - Created
 *              
 * 
 */
public without sharing class FilialnetzaenderungUpsertQueueable implements Queueable{
	
	private List<Filialnetzaenderung__c> filialnetzaenderungs = null;
	private List<Logbuch__c> logbuches = new List<Logbuch__c>();
	private String jobName;
	
	public FilialnetzaenderungUpsertQueueable ( String jobName, List<Filialnetzaenderung__c> filialnetzaenderungs ) {
		this.filialnetzaenderungs = filialnetzaenderungs;
		this.jobName = jobName;
	}
	
	public void execute ( QueueableContext context ) {
		List<Database.UpsertResult> upsertResults = Database.upsert( filialnetzaenderungs, false );
		for ( Integer i = 0; i < upsertResults.size(); i++ ) {
			
			Database.UpsertResult result = upsertResults[ i ];
			Filialnetzaenderung__c filialnetzaenderung = filialnetzaenderungs[ i ];
			if ( !result.isSuccess() ) {
				logException( result, filialnetzaenderung );
			}
		}
		try {
			insert logbuches;
		}
		catch ( Exception e ) {
			new HW_ErrorLogging().logException ( e, new Set<Id>(), 'Logging Failure in: FilialnetzaenderungUpsertQueueable' );
		}
	}
	
	private void logException ( Database.UpsertResult result, Filialnetzaenderung__c filialnetzaenderung ) {
		String meldung = '';
		for ( Database.Error error : result.getErrors() ) {
			meldung = error.getStatusCode() + ' | ' + error.getMessage() + ' ***';
		}
		logbuches.add(
				new Logbuch__c(
						Job__c = jobName,
						Herkunft__c = 'Filialnetzänderung ID: ' + filialnetzaenderung.Id,
						Meldung__c = meldung,
						Type__c = 'Filialnetzänderung ID: ' + filialnetzaenderung.Id,
						Zeitpunkt__c = Datetime.now()
				)
		);
	}
}