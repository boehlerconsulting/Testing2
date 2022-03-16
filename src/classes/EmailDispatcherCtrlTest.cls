/**
 *@author       Mats Böhler
 *@created      15.05.2020
 *
 *
 *@description  EmailDispatcherCtrlTest
 *
 *
 *@changelog    15.05.2020 Mats Böhler  - Created
 *              
 * 
 */
@IsTest
private class EmailDispatcherCtrlTest {
	
	@IsTest
	static void testLoadData () {
		
		Lead lead = createLead();
		Id contentDocumentId = createFile( lead.Id );
		
		Test.startTest();
		EmailDispatcherCtrl instance = ( EmailDispatcherCtrl )
				JSON.deserialize(
						EmailDispatcherCtrl.init( lead.Id ),
						EmailDispatcherCtrl.class
				);
		EmailDispatcherCtrl.deleteFiles( new List<Id> {
				contentDocumentId
		} );
		Test.stopTest();
		
		System.assertNotEquals( null, instance );
	}
	
	@IsTest
	static void testSendEmailFailure () {
		
		Lead lead = createLead();
		createFile( lead.Id );
		
		Test.startTest();
		try {
			EmailDispatcherCtrl.sendEmail( lead.Id,
					JSON.serialize(
							new EmailDispatcherService.Message()
					)
			);
		}
		catch ( Exception e ) {
			System.assert( e.getMessage().contains( 'Script-thrown exception' ) );
		}
		
		Test.stopTest();
	}
	
	@IsTest
	static void testSendEmailSuccess () {
		
		Lead lead = createLead();
		
		Test.startTest();
		EmailDispatcherCtrl.sendEmail( lead.Id, createFile( lead.Id ));
		Test.stopTest();
		
		System.assertEquals( 1, [
				SELECT
						Id
				FROM EmailVersand__c
		].size() );
	}

	private static Lead createLead () {
		Lead lead = ( Lead ) TestFactory.createSObject(
				new Lead(
						Oeffentlicher_Zugang__c = 'Nein'
				),
				true
		);
		return lead;
	}
	
	private static Id createFile ( Id linkedEntityId ) {
		ContentVersion contentVersion = new ContentVersion(
				Title = 'Test',
				PathOnClient = 'Test.jpg',
				VersionData = Blob.valueOf( 'Test Content Data' ),
				IsMajorVersion = true
		);
		insert contentVersion;
		
		Id contentDocumentId = [
				SELECT
						ContentDocumentId
				FROM ContentVersion
				WHERE Id = :contentVersion.Id
				LIMIT 1
		].ContentDocumentId;
		
		insert new ContentDocumentLink(
				ContentDocumentId = contentDocumentId,
				LinkedEntityId = linkedEntityId,
				ShareType = 'I',
				Visibility = 'AllUsers'
		);
		return contentDocumentId;
	}
}