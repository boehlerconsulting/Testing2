/**
 *@author       Mats Böhler
 *@created      15.06.2020
 *
 *
 *@description  MeldungAnlagennummerCtrlTest
 *
 *
 *@changelog    15.06.2020 Mats Böhler  - Created
 *              
 * 
 */
@IsTest
private class AnlagennummerMeldungCtrlTest {
	
	@IsTest
	static void testMeldung () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			Lead lead = createPackstationLead();
			new AnlagennummerService().generate( '00000000', '00000001' );
			lead.STO_disponiert__c = Date.today();
			update lead;
			
			Test.startTest();
			AnlagennummerMeldungCtrl controller = AnlagennummerMeldungCtrl.getInstance();
			Test.stopTest();
			
			System.assertEquals( 1, controller.meldungWrappers.size() );
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