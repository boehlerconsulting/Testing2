/**
 *@author       Mats Böhler
 *@created      26.07.2021
 *
 *
 *@description  PackstationRueckgabeCtrlTest
 *
 *
 *@changelog    26.07.2021 Mats Böhler  - Created
 *              
 * 
 */
@IsTest
private class PackstationRueckgabeCtrlTest {
	
	@IsTest
	static void testSendEmail () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			Lead lead = createPackstationLead();
			
			Test.startTest();
			PackstationRueckgabeCtrl.sendEmail( lead.Id, 'Test' );
			Test.stopTest();
			
			System.assertEquals( 1, [ SELECT Id FROM EmailVersand__c ].size() );
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