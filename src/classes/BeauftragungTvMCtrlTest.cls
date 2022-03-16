/**
 *@author       Mats Böhler
 *@created      07.12.2021
 *
 *
 *@description  BeauftragungTvMCtrlTest
 *
 *
 *@changelog    07.12.2021 Mats Böhler  - Created
 *              
 * 
 */
@IsTest
private class BeauftragungTvMCtrlTest {
	
	@IsTest
	static void testInitialize () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			Lead lead = createLead();
			createFileWithLink(
					lead.Id
			);
			
			Test.startTest();
			BeauftragungTvMCtrl instance = ( BeauftragungTvMCtrl )
					JSON.deserialize( BeauftragungTvMCtrl.initialize( lead.Id ), BeauftragungTvMCtrl.class );
			Test.stopTest();
			
			System.assertNotEquals( null, instance.data );
		}
	}
	
	@IsTest
	static void testSendEmail () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			Lead lead = createLead();
			Id documentId = createFileWithLink(
					lead.Id
			);
			
			Test.startTest();
			BeauftragungTvMCtrl.sendEmail( lead.Id, '5', '5', '', '', documentId );
			Test.stopTest();
			
			System.assertEquals( 1, [ SELECT Id FROM EmailVersand__c WHERE Dokument__c = 'Beauftragung TVM' ].size() );
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
								.get( 'Packstation' ).getRecordTypeId()
				
				),
				true
		);
		return lead;
	}
}