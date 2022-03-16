/**
 *@author       Mats Böhler
 *@created      04.01.2022
 *
 *
 *@description  ErstellungVspCtrlTest
 *
 *
 *@changelog    04.01.2022 Mats Böhler  - Created
 *              
 * 
 */
@IsTest
private class ErstellungVspCtrlTest {
	
	@IsTest
	static void testInitialize () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			PODID__c podid = new PODID__c(
					Name = '64653111',
					Wert__c = '64653111',
					Ort__c = 'Lorsch'
			);
			insert podid;
			
			Lead lead = createLead();
			ContentVersion contentVersion = createFileWithLink(
					lead.Id
			);
			
			Test.startTest();
			ErstellungVspCtrl instance = ( ErstellungVspCtrl )
					JSON.deserialize( ErstellungVspCtrl.initialize( lead.Id ), ErstellungVspCtrl.class );
			ErstellungVspCtrl.validateImageSize( contentVersion.ContentDocumentId );
			ErstellungVspCtrl.create( contentVersion.ContentDocumentId, JSON.serialize( lead ) );
			ErstellungVspCtrl.save( EncodingUtil.base64Encode( contentVersion.VersionData ), JSON.serialize( lead ) );
			Test.stopTest();
			
			System.assertNotEquals( null, instance.data );
		}
	}
	
	private static ContentVersion createFileWithLink ( String leadId ) {
		
		ContentVersion contentVersion = new ContentVersion();
		contentVersion.VersionData = Blob.valueOf( 'Test' );
		contentVersion.Title = 'Test';
		contentVersion.PathOnClient = 'Test.jpg';
		contentVersion.Index__c = 'VSP';
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
		contentDocumentLink.LinkedEntityId = leadId;
		insert contentDocumentLink;
		return contentVersion;
	}
	
	private static Lead createLead () {
		
		Lead lead = ( Lead ) TestFactory.createSObject(
				new Lead(
						STOG_Gesellschaft__c = 'REWE',
						PostalCode = '64653',
						RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName()
								.get( 'Packstation' ).getRecordTypeId(),
						City = 'Lorsch'
				
				),
				true
		);
		return lead;
	}
}