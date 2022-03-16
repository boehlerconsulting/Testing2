/**
 *@author       Mats Böhler
 *@created      02.11.2020
 *
 *
 *@description  OnepagerServiceTest
 *
 *
 *@changelog    02.11.2020 Mats Böhler  - Created
 *              
 * 
 */
@IsTest
private class OnepagerServiceTest {
	
	@IsTest
	static void testNewRecord () {
		
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			createOnepagerFile( 'UnitTestDoNotDelete' );
			
			Test.startTest();
			Lead lead = createPackstationLead( 'UnitTestDoNotDelete' );
			Test.stopTest();
			
			System.assertEquals( 1, [
					SELECT
							Id
					FROM ContentDocumentLink
					WHERE LinkedEntityId = :lead.Id
					AND ContentDocument.Title = 'UnitTestDoNotDelete'
			].size() );
		}
	}
	
	@IsTest
	static void testNewRecordInvalidValue () {
		
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			createOnepagerFile( 'UnitTestDoNotDelete' );
			
			Test.startTest();
			try {
				Lead lead = createPackstationLead( 'InvalidValue' );
			}
			catch ( Exception e ) {
			}
			Test.stopTest();
		}
	}
	
	@IsTest
	static void testExistingRecordNoOnepager () {
		
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			createOnepagerFile( 'UnitTestDoNotDelete' );
			Lead lead = createPackstationLead( '' );
			
			Test.startTest();
			LeadTriggerHandler.processedIds = new Set<Id>();
			lead.NameDesOnepagers__c = 'UnitTestDoNotDelete';
			update lead;
			Test.stopTest();
			
			System.assertEquals( 1, [
					SELECT
							Id
					FROM ContentDocumentLink
					WHERE LinkedEntityId = :lead.Id
					AND ContentDocument.Title = 'UnitTestDoNotDelete'
			].size() );
		}
	}
	
	@IsTest
	static void testExistingRecordExistingOnepagerChanged () {
		
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			createOnepagerFile( 'UnitTestDoNotDelete' );
			createOnepagerFile( 'UnitTestDoNotDelete2' );
			Lead lead = createPackstationLead( 'UnitTestDoNotDelete' );
			
			Test.startTest();
			LeadTriggerHandler.processedIds = new Set<Id>();
			lead.NameDesOnepagers__c = 'UnitTestDoNotDelete2';
			update lead;
			Test.stopTest();
			
			System.assertEquals( 0, [
					SELECT
							Id
					FROM ContentDocumentLink
					WHERE LinkedEntityId = :lead.Id
					AND ContentDocument.Title = 'UnitTestDoNotDelete'
			].size() );
			System.assertEquals( 1, [
					SELECT
							Id
					FROM ContentDocumentLink
					WHERE LinkedEntityId = :lead.Id
					AND ContentDocument.Title = 'UnitTestDoNotDelete2'
			].size() );
		}
	}
	
	@IsTest
	static void testExistingRecordExistingOnepagerDeleted () {
		
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			createOnepagerFile( 'UnitTestDoNotDelete' );
			Lead lead = createPackstationLead( 'UnitTestDoNotDelete' );
			
			System.assertEquals( 1, [
					SELECT
							Id
					FROM ContentDocumentLink
					WHERE LinkedEntityId = :lead.Id
					AND ContentDocument.Title = 'UnitTestDoNotDelete'
			].size() );
			
			Test.startTest();
			LeadTriggerHandler.processedIds = new Set<Id>();
			lead.NameDesOnepagers__c = '';
			update lead;
			Test.stopTest();
			
			System.assertEquals( 0, [
					SELECT
							Id
					FROM ContentDocumentLink
					WHERE LinkedEntityId = :lead.Id
					AND ContentDocument.Title = 'UnitTestDoNotDelete'
			].size() );
		}
	}
	
	private static Lead createPackstationLead ( String onepagerName ) {
		Lead lead = ( Lead ) TestFactory.createSObject(
				new Lead(
						RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName()
								.get( 'Packstation' ).getRecordTypeId(),
						PostalCode = '12345',
						NameDesOnepagers__c = onepagerName
				),
				true
		);
		return lead;
	}
	
	private static void createOnepagerFile ( String title ) {
		ContentVersion contentVersion = new ContentVersion(
				Title = title,
				PathOnClient = 'Test.jpg',
				VersionData = Blob.valueOf( 'Test Content Data' ),
				Onepager__c = true,
				Index__c = 'Onepager'
		);
		insert contentVersion;
	}
}