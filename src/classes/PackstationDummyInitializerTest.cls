/**
 *@author       Mats Böhler
 *@created      13.09.2021
 *
 *
 *@description  PackstationDummyInitializerTest
 *
 *
 *@changelog    13.09.2021 Mats Böhler  - Created
 *              
 * 
 */
@IsTest
private class PackstationDummyInitializerTest {
	
	@IsTest
	static void testCreate () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			TriggerHandler.bypass( 'LeadTriggerHandler' );
			Lead lead = createPackstationLead();
			TriggerHandler.clearBypass( 'LeadTriggerHandler' );
			
			Test.startTest();
			new PackstationDummyInitializer().create( new Set<Id> {
					lead.Id
			} );
			new PackstationDummyInitializer().create( new Set<Id> {
					lead.Id
			} );
			new PackstationDummyInitializer().cloneAccountContactRelations( new Set<Id> {
					lead.Id
			} );
			System.assertEquals( 1, [
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