/**
 *@author       Mats Böhler
 *@created      22.03.2022
 *
 *
 *@description  DocumentCreatorCtrlTest
 *
 *
 *@changelog    22.03.2022 Mats Böhler  - Created
 *              
 * 
 */
@IsTest
private class DocumentCreatorCtrlTest {
	
	@IsTest
	static void testInitialize () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			Account account = (Account) TestFactory.createSObject(
					new Account(),
					true
			);
			ContentVersion contentVersion = createFileWithLink(
					account.Id
			);
			
			Test.startTest();
			DocumentCreatorCtrl.DocumentCreatorResponse instance = (DocumentCreatorCtrl.DocumentCreatorResponse)
					JSON.deserialize(
							DocumentCreatorCtrl.initialize(
									account.Id,
									'Id',
									'Postgesetz' ),
							DocumentCreatorCtrl.DocumentCreatorResponse.class
					);
			DocumentCreatorCtrl.save(
					EncodingUtil.base64Encode( contentVersion.VersionData ),
					account.Id,
					'Id',
					'Postgesetz',
					'Abforderung_BGP_aus_SDS_an_3600',
					'Test'
			);
			Test.stopTest();
			
			System.assertNotEquals( null, instance.encodedPdf );
		}
	}
	
	private static ContentVersion createFileWithLink ( String accountId ) {
		
		ContentVersion contentVersion = new ContentVersion();
		contentVersion.VersionData = Blob.valueOf( 'Test' );
		contentVersion.Title = 'Test';
		contentVersion.PathOnClient = 'Test.jpg';
		contentVersion.Index__c = 'Postgesetz';
		insert contentVersion;
		contentVersion = [
				SELECT
						ContentDocumentId,
						VersionData
				FROM ContentVersion
				WHERE Id = :contentVersion.Id
				LIMIT 1
		];
		ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
		contentDocumentLink.ContentDocumentId = contentVersion.ContentDocumentId;
		contentDocumentLink.ShareType = 'I';
		contentDocumentLink.Visibility = 'AllUsers';
		contentDocumentLink.LinkedEntityId = accountId;
		insert contentDocumentLink;
		return contentVersion;
	}
}