/**
 *@author       Mats Böhler
 *@created      30.06.2020
 *
 *
 *@description  PackstationAktivatorCtrlTest
 *
 *
 *@changelog    30.06.2020 Mats Böhler  - Created
 *              
 * 
 */
@IsTest
private class PackstationAktivatorCtrlTest {
	@IsTest
	static void testInit () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			Lead lead = createLead();
			
			Test.startTest();
			PackstationAktivatorCtrl.init( lead.Id );
			PackstationAktivatorCtrl.init( lead.Id );
			Test.stopTest();
			
			System.assertEquals( 'aktiv', [
					SELECT
							Id,
							Aktivitaetsstatus__c
					FROM Lead
					WHERE Id = :lead.Id
					LIMIT 1].Aktivitaetsstatus__c );
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