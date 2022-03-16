/**
 *@author       Mats Böhler
 *@created      18.11.2020
 *
 *
 *@description  ReleaseNoteOverviewCtrl
 *
 *
 *@changelog    18.11.2020 Mats Böhler  - Created
 *              
 * 
 */
public without sharing class ReleaseNoteOverviewCtrl {
	
	private static final String RELEASE_NOTE_RT = Schema.SObjectType.Meldung__c.getRecordTypeInfosByDeveloperName()
			.get( 'ReleaseNote' ).getRecordTypeId();
	
	private List<Release> releases = new List<Release>();
	
	@AuraEnabled
	public static String init () {
		ReleaseNoteOverviewCtrl instance = new ReleaseNoteOverviewCtrl();
		try {
			instance.loadReleases();
		}
		catch ( Exception e ) {
			throw new AuraHandledException( e.getMessage() );
		}
		return JSON.serialize( instance.releases );
	}
	
	private void loadReleases () {
		Map<Id, Meldung__c> meldungsByIds = new Map<Id, Meldung__c>( [
				SELECT
						Id,
						Beschreibung__c,
						Titel__c
				FROM Meldung__c
				WHERE RecordTypeId = :RELEASE_NOTE_RT
				ORDER BY IstAktuelleMeldung__c DESC, CreatedDate DESC NULLS LAST
		] );
		
		Map<Id, List<Id>> contentDocumentIdsByLinkedEntityId = new Map<Id, List<Id>>();
		if ( !meldungsByIds.keySet().isEmpty() ) {
			for ( ContentDocumentLink contentDocumentLink : [
					SELECT
							Id,
							ContentDocumentId,
							LinkedEntityId
					FROM ContentDocumentLink
					WHERE LinkedEntityId IN :meldungsByIds.keySet()
			] ) {
				
				if ( contentDocumentIdsByLinkedEntityId.containsKey( contentDocumentLink.LinkedEntityId ) ) {
					contentDocumentIdsByLinkedEntityId.get( contentDocumentLink.LinkedEntityId ).add( contentDocumentLink.ContentDocumentId );
				}
				else {
					contentDocumentIdsByLinkedEntityId.put( contentDocumentLink.LinkedEntityId, new List<Id> {
							contentDocumentLink.ContentDocumentId
					} );
				}
			}
		}
		for ( Meldung__c meldung : meldungsByIds.values() ) {
			Release release = new Release();
			release.title = meldung.Titel__c;
			release.description = meldung.Beschreibung__c;
			release.contentDocumentIds = contentDocumentIdsByLinkedEntityId.containsKey( meldung.Id )
					? contentDocumentIdsByLinkedEntityId.get( meldung.Id )
					: new List<Id>();
			releases.add( release );
		}
	}
	
	@TestVisible
	private class Release {
		public String title;
		public String description;
		public List<Id> contentDocumentIds;
	}
}