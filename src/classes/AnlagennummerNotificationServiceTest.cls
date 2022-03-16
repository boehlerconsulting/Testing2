/**
 *@author       Mats Böhler
 *@created      13.06.2020
 *
 *
 *@description  AnlagennummerNotificationTest
 *
 *
 *@changelog    13.06.2020 Mats Böhler  - Created
 *              
 * 
 */
@IsTest
private class AnlagennummerNotificationServiceTest {
	
	@IsTest
	static void testNotificationRemainingNumbers () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			Test.startTest();
			new AnlagennummerNotificationService().sendEmailNotificationAboutRemainingNumbers();
			Test.stopTest();
			
			System.assertEquals( 0, [ SELECT Id FROM Anlagennummer__c ].size() );
		}
	}
	
	@IsTest
	static void testEmptyNotificationAnlagenbuchhaltung () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			Test.startTest();
			new AnlagennummerNotificationService().sendEmailNotificationToAnlagenbuchhaltung();
			Test.stopTest();
			
			System.assertEquals( 0, [ SELECT Id FROM Anlagennummer__c ].size() );
		}
	}
	
	@IsTest
	static void testNotificationAnlagenbuchhaltung () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			Lead lead = createPackstationLead();
			new AnlagennummerService().generate( '00000000', '00000001' );
			lead.STO_disponiert__c = Date.today();
			update lead;
			
			Test.startTest();
			new AnlagennummerNotificationService().sendEmailNotificationToAnlagenbuchhaltung();
			Test.stopTest();
			
			System.assertEquals( 1, [ SELECT Id FROM AnlagennummerHistorie__c WHERE Aktion__c = 'Gemeldet' ].size() );
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