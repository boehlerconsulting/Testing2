/**
 *@author       Mats Böhler
 *@created      18.11.2020
 *
 *
 *@description  ReleaseNoteOverviewCtrlTest
 *
 *
 *@changelog    18.11.2020 Mats Böhler  - Created
 *              
 * 
 */
@IsTest
private class ReleaseNoteOverviewCtrlTest {
	
	@IsTest
	static void testInit () {
		
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			Meldung__c release = createRelease();
			Id contentDocumentId = createFileWithLink( release.Id );
			
			Test.startTest();
			List<ReleaseNoteOverviewCtrl.Release> releases = ( List<ReleaseNoteOverviewCtrl.Release> )
					JSON.deserialize( ReleaseNoteOverviewCtrl.init(), List<ReleaseNoteOverviewCtrl.Release>.class );
			Test.stopTest();
			
			System.assertEquals( contentDocumentId, releases[ 0 ].contentDocumentIds[ 0 ] );
		}
	}
	
	private static Meldung__c createRelease () {
		Meldung__c release = new Meldung__c(
				RecordTypeId = Schema.SObjectType.Meldung__c.getRecordTypeInfosByDeveloperName()
						.get( 'ReleaseNote' ).getRecordTypeId(),
				Titel__c = 'Titel',
				Beschreibung__c = 'Beschreibung',
				IstAktuelleMeldung__c = true
		);
		insert release;
		return release;
	}
	
	private static Id createFileWithLink ( String linkedEntityId ) {
		
		ContentVersion contentVersion = new ContentVersion();
		contentVersion.VersionData = Blob.valueOf( 'Test' );
		contentVersion.Title = 'Test';
		contentVersion.PathOnClient = 'Test.jpg';
		insert contentVersion;
		Id documentId = [
				SELECT
						ContentDocumentId
				FROM ContentVersion
				WHERE Id = :contentVersion.Id
				LIMIT 1
		].ContentDocumentId;
		ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
		contentDocumentLink.ContentDocumentId = documentId;
		contentDocumentLink.ShareType = 'I';
		contentDocumentLink.Visibility = 'AllUsers';
		contentDocumentLink.LinkedEntityId = linkedEntityId;
		insert contentDocumentLink;
		return documentId;
	}
}