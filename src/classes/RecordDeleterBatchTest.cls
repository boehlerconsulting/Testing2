/**
 *@author       Mats Böhler
 *@created      07.06.2021
 *
 *
 *@description  RecordDeleterBatchTest
 *
 *
 *@changelog    07.06.2021 Mats Böhler  - Created
 *              
 * 
 */
@IsTest
private class RecordDeleterBatchTest {
	
	@IsTest
	static void testDeletion () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			createLeads( 1 );
			
			Test.startTest();
			new RecordDeleterSchedule().startProcess();
			Test.stopTest();
			
			System.assertEquals( 0, [ SELECT Id FROM Lead ].size() );
		}
	}
	
	@IsTest
	static void testDeletionAccountContactRelation () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			Account account = ( Account ) TestFactory.createSObject(
					new Account(
							RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
									.get( 'Packstation_Dummy' ).getRecordTypeId()
					),
					true
			);
			
			Contact contact = ( Contact ) TestFactory.createSObject(
					new Contact(
							RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName()
									.get( 'Interessent' ).getRecordTypeId(),
							AccountId = account.Id
					),
					true
			);
			
			Account secondAccount = ( Account ) TestFactory.createSObject(
					new Account(
							RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
									.get( 'Packstation_Dummy' ).getRecordTypeId()
					),
					true
			);
			
			insert new AccountContactRelation(
					AccountId = secondAccount.Id,
					ContactId = contact.Id,
					Roles = 'Löschen'
			);
			
			Contact secondContact = ( Contact ) TestFactory.createSObject(
					new Contact(
							RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName()
									.get( 'Interessent' ).getRecordTypeId(),
							AccountId = account.Id
					),
					true
			);
			
			AccountContactRelation accountContactRelation = [
					SELECT
							Id
					FROM AccountContactRelation
					WHERE ContactId = :secondContact.Id
					AND AccountId = :account.Id
					LIMIT 1
			];
			
			accountContactRelation.Roles = 'Löschen';
			update accountContactRelation;
			
			Test.startTest();
			Database.executeBatch( new RecordDeleterBatch(
					'SELECT Id, ContactId FROM AccountContactRelation WHERE Loeschen__c = TRUE',
			[
					SELECT
							Id,
							Objekt__c,
							Feld__c,
							HardDelete__c
					FROM LoeschEinstellung__mdt
					WHERE Objekt__c = 'AccountContactRelation'
					LIMIT 1
			] ) );
			Test.stopTest();
			
			System.assertEquals( 1, [ SELECT Id FROM Contact ].size() );
			System.assertEquals( 1, [ SELECT Id FROM AccountContactRelation ].size() );
		}
	}
	
	@IsTest
	static void testSchedule () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			Test.startTest();
			System.schedule( 'RecordDeleterBatchTest', '0 0 * * * ?', new RecordDeleterSchedule() );
			Test.stopTest();
		}
	}
	
	private static List<Lead> createLeads ( Integer quantity ) {
		
		return ( List<Lead> ) TestFactory.createSObjectList(
				new Lead(
						Loeschkennzeichen__c = true
				),
				quantity,
				true
		);
	}
	
	private static List<Contact> createContacts ( Integer quantity, Account account ) {
		
		return ( List<Contact> ) TestFactory.createSObjectList(
				new Contact(
						RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName()
								.get( 'Interessent' ).getRecordTypeId(),
						AccountId = account.Id
				),
				quantity,
				true
		);
	}


}