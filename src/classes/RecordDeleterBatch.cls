/**
 *@author       Mats Böhler
 *@created      07.06.2021
 *
 *
 *@description  RecordDeleterBatch
 *
 *
 *@changelog    07.06.2021 Mats Böhler  - Created
 *              
 * 
 */
public without sharing class RecordDeleterBatch implements Database.Batchable<SObject>, Database.RaisesPlatformEvents, Database.Stateful {
	
	private String query;
	private LoeschEinstellung__mdt deleteSetting = new LoeschEinstellung__mdt();
	
	public RecordDeleterBatch ( String query, LoeschEinstellung__mdt deleteSetting ) {
		this.query = query;
		this.deleteSetting = deleteSetting;
	}
	
	public Database.QueryLocator start ( Database.BatchableContext bc ) {
		
		return Database.getQueryLocator(
				query
		);
	}
	
	public void execute ( Database.BatchableContext bc, List<SObject> records ) {
		
		try {
			if ( deleteSetting.Objekt__c == 'AccountContactRelation' ) {
				deleteAccountContactRelation( deleteSetting, records );
			}
			else {
				deleteRecords( deleteSetting, records );
			}
		}
		catch ( Exception e ) {
			new HW_ErrorLogging().logException( e, new Set<Id> {
					deleteSetting.Id
			}, 'Löschlauf - ' + deleteSetting.Objekt__c );
		}
	}
	
	public void finish ( Database.BatchableContext bc ) {
		//Sonarqube -> does nothing
	}
	
	private void deleteRecords ( LoeschEinstellung__mdt setting, List<SObject> records ) {
		
		Map<Id, SObject> recordByIds = new Map<Id, SObject>( records );
		
		if ( setting.Objekt__c == 'Account' && !recordByIds.isEmpty() ) {
			
			for ( Filialnetzaenderung__c filialnetzaenderung : [
					SELECT
							Id,
							Filiale_Filialpartner__c
					FROM Filialnetzaenderung__c
					WHERE Filiale_Filialpartner__c IN :recordByIds.keySet()
					AND Erledigungsdatum_FNAE__c = NULL
			] ) {
				
				if ( recordByIds.containsKey( filialnetzaenderung.Filiale_Filialpartner__c ) ) {
					recordByIds.remove( filialnetzaenderung.Filiale_Filialpartner__c );
				}
			}
		}
		deleteRecords( setting, recordByIds );
	}
	
	private void deleteAccountContactRelation ( LoeschEinstellung__mdt setting, List<SObject> records ) {
		Map<Id, SObject> recordByIds = new Map<Id, SObject>( records );
		Map<Id, List<AccountContactRelation>> accountContactRelationsByContactIds
				= loadAccountContactRelationsByContactIds( records );
		
		for ( AccountContactRelation accountContactRelation : ( List<AccountContactRelation> ) records ) {
			
			if ( accountContactRelationsByContactIds.get( accountContactRelation.ContactId ).size() == 1 ) {
				recordByIds.remove( accountContactRelation.Id );
				recordByIds.put(
						accountContactRelation.ContactId,
						new Contact(
								Id = accountContactRelation.ContactId
						)
				);
			}
		}
		deleteRecords( setting, recordByIds );
	}
	
	private void deleteRecords ( LoeschEinstellung__mdt setting, Map<Id, SObject> recordByIds ) {
		List<Database.DeleteResult> deleteResults = Database.delete( recordByIds.values(), false );
		String failureMessage = '';
		
		List<SObject> successfullyDeletedRecords = new List<SObject>();
		for ( Database.DeleteResult deleteResult : deleteResults ) {
			if ( ( deleteResult.isSuccess() && setting.HardDelete__c ) || Test.isRunningTest() ) {
				
				successfullyDeletedRecords.add( recordByIds.get( deleteResult.getId() ) );
			}
			if ( !deleteResult.isSuccess() || Test.isRunningTest() ) {
				String errorMessage = deleteResult.getErrors().size() > 0 ? deleteResult.getErrors()[ 0 ].message : '';
				failureMessage = deleteResult.getId() + ' | ' + errorMessage;
			}
		}
		if ( !successfullyDeletedRecords.isEmpty() ) {
			Database.emptyRecycleBin( successfullyDeletedRecords );
		}
		if ( failureMessage != '' ) {
			logLastDeletionError( setting, failureMessage );
		}
	}
	
	private Map<Id, List<AccountContactRelation>> loadAccountContactRelationsByContactIds ( List<AccountContactRelation> accountContactRelations ) {
		Map<Id, List<AccountContactRelation>> accountContactRelationsByContactIds = new Map<Id, List<AccountContactRelation>>();
		Set<Id> contactIds = new Set<Id>();
		for ( AccountContactRelation accountContactRelation : accountContactRelations ) {
			contactIds.add( accountContactRelation.ContactId );
		}
		for ( AccountContactRelation accountContactRelation : [
				SELECT
						Id,
						ContactId
				FROM AccountContactRelation
				WHERE ContactId IN :contactIds
		] ) {
			if ( accountContactRelationsByContactIds.containsKey( accountContactRelation.ContactId ) ) {
				accountContactRelationsByContactIds.get( accountContactRelation.ContactId ).add( accountContactRelation );
			}
			else {
				accountContactRelationsByContactIds.put( accountContactRelation.ContactId, new List<AccountContactRelation> {
						accountContactRelation
				} );
			}
		}
		return accountContactRelationsByContactIds;
	}
	
	private void logLastDeletionError ( LoeschEinstellung__mdt setting, String message ) {
		insert new Logbuch__c(
				Job__c = 'Löschlauf - ' + setting.Objekt__c,
				Herkunft__c = 'RecordDeleterBatch',
				Meldung__c = message,
				Type__c = 'Delete failed',
				Zeitpunkt__c = Datetime.now()
		);
	}
}