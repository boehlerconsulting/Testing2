/**
 *@author       Mats Böhler
 *@created      20.10.2020
 *
 *
 *@description  VerkehrssicherungspflichtAnschrCtrlTest
 *
 *
 *@changelog    20.10.2020 Mats Böhler  - Created
 *              
 * 
 */
@IsTest
private class VerkehrssicherungspflichtAnschrCtrlTest {
	
	@IsTest
	static void testInit () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			Lead lead = createLead();
			createFileWithLink(
					lead.Id
			);
			
			Test.startTest();
			VerkehrssicherungspflichtAnschreibenCtrl ctrl = ( VerkehrssicherungspflichtAnschreibenCtrl )
					JSON.deserialize( VerkehrssicherungspflichtAnschreibenCtrl.init( lead.Id ), VerkehrssicherungspflichtAnschreibenCtrl.class ) ;
			Test.stopTest();
			
			System.assertEquals( 1, ctrl.contentDocumentIds.size() );
		}
	}
	
	@IsTest
	static void testCreatePresentation () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			Lead lead = createLead();
			Id documentId = createFileWithLink(
					lead.Id
			);
			
			Map<String, String> picturesByPage = new Map<String, String>();
			picturesByPage.put( '1', documentId );
			picturesByPage.put( '2', documentId );
			picturesByPage.put( '3', documentId );
			picturesByPage.put( '4', documentId );
			
			Test.startTest();
			VerkehrssicherungspflichtAnschreibenCtrl.createPresentation(
					lead.Id,
					picturesByPage,
					new List<Id>(),
					true,
					false,
					false,
					false,
					'',
					'' );
			Test.stopTest();
			
			System.assertEquals( 1, [
					SELECT
							Id
					FROM ContentDocumentLink
					WHERE LinkedEntityId = :lead.Id
					AND ContentDocument.Description = 'Vorbeauftragung CSG'
					LIMIT 1
			].size() );
		}
	}
	
	@IsTest
	static void testDeleteFiles () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			Lead lead = createLead();
			createFileWithLink(
					lead.Id
			);
			
			Test.startTest();
			VerkehrssicherungspflichtAnschreibenCtrl ctrl = ( VerkehrssicherungspflichtAnschreibenCtrl )
					JSON.deserialize( VerkehrssicherungspflichtAnschreibenCtrl.init( lead.Id ), VerkehrssicherungspflichtAnschreibenCtrl.class ) ;
			VerkehrssicherungspflichtAnschreibenCtrl.deleteFiles( ctrl.contentDocumentIds );
			Test.stopTest();
			
			System.assertEquals( 0, [
					SELECT
							Id
					FROM ContentDocumentLink
					WHERE LinkedEntityId = :lead.Id
			].size() );
		}
	}
	
	private static Id createFileWithLink ( String leadId ) {
		
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
		contentDocumentLink.LinkedEntityId = leadId;
		insert contentDocumentLink;
		return documentId;
	}
	
	private static Lead createLead () {
		
		Lead lead = ( Lead ) TestFactory.createSObject(
				new Lead(
						STOG_Gesellschaft__c = 'REWE',
						PostalCode = '64653',
						RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName()
								.get( 'Packstation' ).getRecordTypeId(),
						City = 'Berlin',
						Oeffentlicher_Zugang__c = 'Nein'
				
				),
				true
		);
		return lead;
	}
}