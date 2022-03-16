/**
 *@author       Mats Böhler
 *@created      27.11.2020
 *
 *
 *@description  PackstationLeaduebernahmeCtrlTest
 *
 *
 *@changelog    27.11.2020 Mats Böhler  - Created
 *              
 * 
 */
@IsTest
private class PackstationLeaduebernahmeCtrlTest {
	
	@IsTest
	static void testInit () {
		System.runAs( TestUser.create( TestUser.UserType.AO ) ) {
			Lead lead = createLead();
			
			Test.startTest();
			PackstationLeaduebernahmeCtrl.init( lead.Id );
			Test.stopTest();
			
			System.assertEquals( UserInfo.getUserId(), [
					SELECT
							OwnerId
					FROM Lead
					WHERE Id = :lead.Id
					LIMIT 1
			].OwnerId );
		}
	}
	
	@IsTest
	static void testInitNoPermission () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			Lead lead = createLead();
			
			Test.startTest();
			try {
				PackstationLeaduebernahmeCtrl.init( lead.Id );
			}
			catch ( Exception e ) {
				System.assert( e.getMessage().contains( 'Script-thrown exception' ) );
			}
			Test.stopTest();
		}
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