/**
 *@author       Mats Böhler
 *@created      14.09.2021
 *
 *
 *@description  NewAccountContactRelationRecordCtrlTest
 *
 *
 *@changelog    14.09.2021 Mats Böhler  - Created
 *              
 * 
 */
@IsTest
private class NewAccountContactRelationRecordCtrlTest {
	
	@IsTest
	static void testInit () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			TriggerHandler.bypass( 'LeadTriggerHandler' );
			Lead lead = createPackstationLead();
			TriggerHandler.clearBypass( 'LeadTriggerHandler' );
			
			Test.startTest();
			lead = EnhancedRelatedListCtrl.init( lead.Id );
			NewAccountContactRelationRecordCtrl.createNewContactWithAccountContactRelation(
					JSON.serialize( new Contact( LastName = 'Test' ) ),
					lead.Packstation__c,
					new List<String>{'Vertragspartner'}
			);
			Contact contact = new Contact(
					LastName = 'Testing',
					AccountId = lead.Packstation__c,
					RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName()
					.get( 'Packstation' ).getRecordTypeId()
			);
			insert contact;
			NewAccountContactRelationRecordCtrl.searchContacts( 'Testing', new List<Id>() );
			Lead lead2 = createPackstationLead();
			lead2 = EnhancedRelatedListCtrl.init( lead2.Id );
			NewAccountContactRelationRecordCtrl.createNewAccountContactRelation(
					contact.Id,
					lead2.Packstation__c,
					new List<String>()
			);
			Test.stopTest();
			System.assertEquals( 2, [
					SELECT
							Id
					FROM Account
					WHERE RecordType.DeveloperName = 'Packstation_Dummy'
			].size() );
		}
	}
	
	private static Lead createPackstationLead () {
		Lead lead = ( Lead ) TestFactory.createSObject(
				new Lead(
						RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName()
								.get( 'Packstation' ).getRecordTypeId(),
						PostalCode = '12345'
				),
				true
		);
		return lead;
	}
}