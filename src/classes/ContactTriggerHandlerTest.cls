/**
 *@author       Mats Böhler
 *@created      13.01.2021
 *
 *
 *@description  ContactTriggerHandlerTest
 *
 *
 *@changelog    13.01.2021 Mats Böhler  - Created
 *              
 * 
 */
@IsTest
private class ContactTriggerHandlerTest {
	
	@IsTest
	static void testBulk () {
		
		Test.startTest();
		List<Contact> contacts = createContacts( 1 );
		Test.stopTest();
		
		System.assertEquals( 1, [ SELECT Id FROM Contact ].size() );
	}
	
	private static List<Contact> createContacts ( Integer quantity ) {
		
		return ( List<Contact> ) TestFactory.createSObjectList(
				new Contact(
						RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName()
								.get( 'Interessent' ).getRecordTypeId()
				),
				quantity,
				true
		);
	}
}