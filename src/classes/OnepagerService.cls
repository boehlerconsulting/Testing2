/**
 *@author       Mats Böhler
 *@created      02.11.2020
 *
 *
 *@description  OnepagerService
 *
 *
 *@changelog    02.11.2020 Mats Böhler  - Created
 *              
 * 
 */
public without sharing class OnepagerService implements Queueable {
	
	private Map<Id, SObject> newRecordsMap = null;
	private Map<Id, SObject> oldRecordsMap = null;
	private Map<String, String> contentDocumentIdByTitles = new Map<String, String>();
	private Map<String, ContentDocumentLink> contentDocumentLinkByContentDocumentIdAndRecordId = new Map<String, ContentDocumentLink>();
	@TestVisible
	private List<ContentDocumentLink> linksForDeletion = new List<ContentDocumentLink>();
	private List<ContentDocumentLink> contentDocumentLinks = new List<ContentDocumentLink>();
	private Set<String> contentDocumentNames = new Set<String>();
	private String sObjName = '';
	private String fieldName = '';
	private List<Logbuch__c> logbuches = new List<Logbuch__c>();
	
	public OnepagerService ( Map<Id, SObject> newRecordsMap ) {
		this.newRecordsMap = newRecordsMap;
		this.oldRecordsMap = Trigger.oldMap;
	}
	
	public void execute ( QueueableContext context ) {
		executeDML();
	}
	
	private void executeDML () {
		insertFiles();
		deleteExistingFiles();
		try {
			insert logbuches;
		}
		catch ( Exception e ) {
			new HW_ErrorLogging().logException ( e, new Set<Id>(), 'Logging Failure in: OnepagerService' );
		}
	}
	
	public void execute () {
		if ( newRecordsMap == null ) {
			return;
		}
		loadSettings();
		loadExistingOnepagerLinks();
		for ( SObject sobj : newRecordsMap.values() ) {
			if ( isValidOnepagerValue( sobj ) ) {
				createOnepagerLinksForNewRecord( sobj );
				createOnepagerLinksForExistingRecord( sobj );
			}
			else {
				throw new OnepagerServiceException( 'Wert ist nicht in der Custom Metadata Onepager Definition ' +
						'enthalten: ' + ( String ) sobj.get( fieldName ) );
			}
		}
		if ( Test.isRunningTest() ) {
			executeDML();
		}
		else {
			System.enqueueJob( this );
		}
	}
	
	private void insertFiles () {
		if ( contentDocumentLinks.isEmpty() ) {
			return;
		}
		List<Database.SaveResult> upsertResults = Database.insert( contentDocumentLinks, false );
		for ( Integer i = 0; i < upsertResults.size(); i++ ) {
			
			Database.SaveResult result = upsertResults[ i ];
			ContentDocumentLink link = contentDocumentLinks[ i ];
			if ( !result.isSuccess() ) {
				logException( result, link );
			}
		}
	}
	
	@TestVisible
	private void deleteExistingFiles () {
		if ( linksForDeletion.isEmpty() ) {
			return ;
		}
		List<Database.DeleteResult> deleteResults = Database.delete( linksForDeletion, false );
		for ( Integer i = 0; i < deleteResults.size(); i++ ) {
			
			Database.DeleteResult result = deleteResults[ i ];
			ContentDocumentLink link = linksForDeletion[ i ];
			if ( !result.isSuccess() ) {
				logException( result, link );
			}
		}
		Database.emptyRecycleBin( linksForDeletion );
	}
	
	private Boolean isValidOnepagerValue ( SObject sobj ) {
		return contentDocumentNames.contains( ( String ) sobj.get( fieldName ) )
				|| ( String ) sobj.get( fieldName ) == null;
	}
	
	private void createOnepagerLinksForNewRecord ( SObject sobj ) {
		if ( sobj.get( fieldName ) != null
				&& oldRecordsMap == null
				&& contentDocumentIdByTitles.containsKey( ( String ) sobj.get( fieldName ) ) ) {
			addNewContentDocumentLink( sobj );
		}
	}
	
	private void createOnepagerLinksForExistingRecord ( SObject sobj ) {
		if ( oldRecordsMap != null
				&& oldRecordsMap.get( sobj.Id ).get( fieldName ) != sobj.get( fieldName ) ) {
			
			if ( contentDocumentIdByTitles.containsKey( ( String ) sobj.get( fieldName ) ) ) {
				addNewContentDocumentLink( sobj );
			}
			String key = ( String ) contentDocumentIdByTitles.get(
					( String ) oldRecordsMap.get( sobj.Id ).get( fieldName )
			) + sobj.Id ;
			if ( contentDocumentLinkByContentDocumentIdAndRecordId.containsKey( key ) ) {
				linksForDeletion.add( contentDocumentLinkByContentDocumentIdAndRecordId.get( key ) );
			}
		}
	}
	
	private void addNewContentDocumentLink ( SObject sobj ) {
		contentDocumentLinks.add(
				new ContentDocumentLink(
						LinkedEntityId = sobj.Id,
						ContentDocumentId = ( Id ) contentDocumentIdByTitles.get( ( String ) sobj.get( fieldName ) ),
						ShareType = 'V',
						Visibility = 'AllUsers'
				)
		);
	}
	
	private void loadExistingOnepagerLinks () {
		for ( ContentDocument contentDocument : [
				SELECT
						Id, (
						SELECT
								Id,
								LinkedEntityId,
								ContentDocumentId
						FROM ContentDocumentLinks
						WHERE LinkedEntityId IN :newRecordsMap.keySet()
				), (
						SELECT
								Id
						FROM ContentVersions
						WHERE Onepager__c = TRUE
						AND IsLatest = TRUE
						AND Title IN :contentDocumentNames
						AND Index__c = 'Onepager'
				)
				FROM ContentDocument
				WHERE Id IN :contentDocumentIdByTitles.values()
		] ) {
			
			if ( contentDocument.ContentDocumentLinks.size() > 0 && contentDocument.ContentVersions.size() > 0 ) {
				for ( ContentDocumentLink link : contentDocument.ContentDocumentLinks ) {
					contentDocumentLinkByContentDocumentIdAndRecordId.put(
							String.valueOf( link.ContentDocumentId ) + String.valueOf( link.LinkedEntityId ), link );
				}
			}
		}
	}
	
	private void loadSettings () {
		sObjName = newRecordsMap.values()[ 0 ].getSObjectType().getDescribe().getName();
		for ( OnepagerDefinition__mdt setting : [
				SELECT
						Id,
						Objekt__c,
						Feld__c,
						NameDokument__c
				FROM OnepagerDefinition__mdt
				WHERE Objekt__c = :sObjName
		] ) {
			fieldName = setting.Feld__c;
			contentDocumentNames.add( setting.NameDokument__c );
		}
		contentDocumentNames.remove( null );
		for ( ContentVersion contentVersion : [
				SELECT
						Id,
						Title,
						ContentDocumentId
				FROM ContentVersion
				WHERE Onepager__c = TRUE
				AND IsLatest = TRUE
				AND Title IN :contentDocumentNames
				AND Index__c = 'Onepager'
		] ) {
			
			contentDocumentIdByTitles.put( contentVersion.Title, contentVersion.ContentDocumentId );
		}
	}
	
	public class OnepagerServiceException extends Exception {
	
	}
	
	@TestVisible
	private void logException ( Database.SaveResult result, ContentDocumentLink link ) {
		String meldung = '';
		for ( Database.Error error : result.getErrors() ) {
			meldung = error.getStatusCode() + ' | ' + error.getMessage() + ' ***';
		}
		logbuches.add(
				new Logbuch__c(
						Job__c = 'OnepagerService',
						Herkunft__c = 'LeadId: ' + link.LinkedEntityId,
						Meldung__c = meldung,
						Zeitpunkt__c = Datetime.now()
				)
		);
	}
	
	@TestVisible
	private void logException ( Database.DeleteResult result, ContentDocumentLink link ) {
		String meldung = '';
		for ( Database.Error error : result.getErrors() ) {
			meldung = error.getStatusCode() + ' | ' + error.getMessage() + ' ***';
		}
		logbuches.add(
				new Logbuch__c(
						Job__c = 'OnepagerService',
						Herkunft__c = 'LeadId: ' + link.LinkedEntityId,
						Meldung__c = meldung,
						Zeitpunkt__c = Datetime.now()
				)
		);
	}
}