/**
 *@author       Mats Böhler
 *@created      13.09.2021
 *
 *
 *@description  EnhancedRelatedListCtrlTest
 *
 *
 *@changelog    13.09.2021 Mats Böhler  - Created
 *              
 * 
 */
@IsTest
private class EnhancedRelatedListCtrlTest {
	
	@IsTest
	static void testInit () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			TriggerHandler.bypass( 'LeadTriggerHandler' );
			Lead lead = createPackstationLead();
			TriggerHandler.clearBypass( 'LeadTriggerHandler' );
			
			Test.startTest();
			EnhancedRelatedListCtrl.init( lead.Id );
			EnhancedRelatedListCtrl.init( lead.Id );
			try {
				EnhancedRelatedListCtrl.init( null );
			}
			catch ( Exception e ) {
			
			}
			Test.stopTest();
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