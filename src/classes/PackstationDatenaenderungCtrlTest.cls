/**
 *@author       Mats Böhler
 *@created      22.07.2021
 *
 *
 *@description  PackstationDatenaenderungCtrlTest
 *
 *
 *@changelog    22.07.2021 Mats Böhler  - Created
 *              
 * 
 */
@IsTest
private class PackstationDatenaenderungCtrlTest {
	
	@IsTest
	static void testSendEmail () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			Lead lead = createPackstationLead();
			
			Test.startTest();
			PackstationDatenaenderungCtrl.sendEmail( lead.Id, JSON.serialize( lead ), JSON.serialize( lead ) );
			try {
				PackstationDatenaenderungCtrl.setNewPODID( lead );
			}
			catch ( Exception e ) {
			}
			try {
				PackstationDatenaenderungCtrl.sendEmail( lead.Id, JSON.serialize( '' ), JSON.serialize( lead ) );
			}
			catch ( Exception e ) {
			
			}
			Test.stopTest();
			
			System.assertEquals( 1, [ SELECT Id FROM EmailVersand__c ].size() );
		}
	}
	
	private static Lead createPackstationLead () {
		Lead lead = ( Lead ) TestFactory.createSObject(
				new Lead(
						RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName()
								.get( 'Packstation' ).getRecordTypeId(),
						PostalCode = '12345',
						ADM_Typ__c = 'Prototyp'
				),
				true
		);
		return lead;
	}
}