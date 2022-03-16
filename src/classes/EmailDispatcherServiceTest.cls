/**
 *@author       Mats Böhler
 *@created      15.05.2020
 *
 *
 *@description  EmailDispatcherServiceTest
 *
 *
 *@changelog    15.05.2020 Mats Böhler  - Created
 *              
 * 
 */
@IsTest
private class EmailDispatcherServiceTest {
	
	@IsTest
	static void testSendEmail () {
		
		Lead lead = createLead();
		
		Test.startTest();
		EmailDispatcherCtrl.sendEmail( lead.Id, createFile( lead.Id ));
		Test.stopTest();
		
		Id emailVersandId = [
				SELECT
						Id
				FROM EmailVersand__c
				LIMIT 1
		].Id;
		
		System.assertEquals( 1, [
				SELECT
						Id
				FROM EmailVersand__c
		].size() );
		
		System.assertEquals( 1, [
				SELECT
						Id
				FROM ContentDocumentLink
				WHERE LinkedEntityId = :emailVersandId
		].size() );
	}
	
	private static Lead createLead () {
		Lead lead = ( Lead ) TestFactory.createSObject(
				new Lead(
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