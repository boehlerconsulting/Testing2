/**
 *@author       Mats Böhler
 *@created      13.06.2020
 *
 *
 *@description  AnlagennummerAssignmentServiceTest
 *
 *
 *@changelog    13.06.2020 Mats Böhler  - Created
 *              
 * 
 */
@IsTest
private class AnlagennummerAssignmentServiceTest {
	
	@IsTest
	static void testAssignment () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			Lead lead = createPackstationLead();
			
			Test.startTest();
			new AnlagennummerService().generate( '00000000', '00000001' );
			System.assertEquals( 2, [ SELECT Id FROM Anlagennummer__c WHERE Status__c = 'verfügbar' ].size() );
			lead.STO_disponiert__c = Date.today();
			update lead;
			Test.stopTest();
			
			System.assertEquals( '00000000', [
					SELECT
							Id,
							Anlagennummer__r.Name
					FROM Lead
					WHERE Id = :lead.Id
			].Anlagennummer__r.Name );
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