/**
 *@author       Mats Böhler
 *@created      24.06.2020
 *
 *
 *@description  StandortpraesentationPackstationCtrlTest
 *
 *
 *@changelog    24.06.2020 Mats Böhler  - Created
 *              
 * 
 */
@IsTest
private class StandortpraesentationPackstationCtrlTest {
	
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
			StandortpraesentationPackstationAuraCtrl.createPresentation( lead.Id, picturesByPage, new List<Id>() );
			Test.stopTest();
			
			System.assertEquals( 1, [
					SELECT
							Id
					FROM ContentDocumentLink
					WHERE LinkedEntityId = :lead.Id
					AND ContentDocument.Description = 'Standortpräsentation Packstation'
					LIMIT 1
			].size() );
		}
	}
	
	@IsTest
	static void testVisualforce () {
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
			PageReference pageRef = new PageReference( '/apex/StandortpraesentationPackstation?id=' + lead.Id + '&pic1=' + documentId );
			Test.setCurrentPage( pageRef );
			StandortpraesentationPackstationCtrl ctrl = new StandortpraesentationPackstationCtrl();
			ctrl.controllerAction();
			ctrl.getPostLogo();
			ctrl.getLead();
			ctrl.getLink();
			ctrl.getPackstationLogo();
			ctrl.getPicture();
			ctrl.getPictureExists();
			Test.stopTest();
			
			System.assertNotEquals( null, ctrl.getLead() );
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