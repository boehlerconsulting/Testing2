/**
 *@author       Mats Böhler
 *@created      13.06.2020
 *
 *
 *@description  AnlagennummerTriggerHandlerTest
 *
 *
 *@changelog    13.06.2020 Mats Böhler  - Created
 *              
 * 
 */
@IsTest
private class AnlagennummerTriggerHandlerTest {
	
	@IsTest
	static void testAfterInsert () {
		
		Test.startTest();
		new AnlagennummerService().generate( '00000001', '00000350' );
		Test.stopTest();
		
		System.assertEquals( 350, [ SELECT Id FROM Anlagennummer__c ].size() );
		System.assertEquals( 350, [ SELECT Id FROM AnlagennummerHistorie__c ].size() );
	}
	
	@IsTest
	static void testBeforeUpdate () {
		
		new AnlagennummerService().generate( '00000001', '00000001' );
		
		Test.startTest();
		Anlagennummer__c anlagennummer = [ SELECT Id FROM Anlagennummer__c LIMIT 1];
		anlagennummer.Status__c = 'gesperrt';
		update anlagennummer;
		anlagennummer.Status__c = 'verfügbar';
		update anlagennummer;
		anlagennummer.Status__c = 'vergeben';
		update anlagennummer;
		Test.stopTest();
		
		System.assertEquals( 1, [ SELECT Id FROM Anlagennummer__c ].size() );
		System.assertEquals( 2, [ SELECT Id FROM AnlagennummerHistorie__c ].size() );
	}
}