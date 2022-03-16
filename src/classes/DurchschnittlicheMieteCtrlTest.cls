/**
 *@author       Mats Böhler
 *@created      11.11.2020
 *
 *
 *@description  DurchschnittlicheMieteCtrlTest
 *
 *
 *@changelog    11.11.2020 Mats Böhler  - Created
 *              
 * 
 */
@IsTest
private class DurchschnittlicheMieteCtrlTest {
	
	@IsTest
	static void testInit () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			Lead lead = createLead();
			
			Test.startTest();
			Decimal miete = DurchschnittlicheMieteCtrl.init( lead.Id );
			Test.stopTest();
			
			System.assertEquals( null, miete );
		}
	}
	
	@IsTest
	static void testInitFailure () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			Test.startTest();
			try {
				DurchschnittlicheMieteCtrl.init( null );
			}
			catch ( Exception e ) {
				System.assertEquals( 'Script-thrown exception', e.getMessage() );
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