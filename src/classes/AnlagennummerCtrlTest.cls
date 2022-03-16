/**
 *@author       Mats Böhler
 *@created      13.06.2020
 *
 *
 *@description  AnlagennummerCtrlTest
 *
 *
 *@changelog    13.06.2020 Mats Böhler  - Created
 *              
 * 
 */
@IsTest
private class AnlagennummerCtrlTest {
	
	@IsTest
	static void testGeneration () {
		
		Test.startTest();
		AnlagennummerCtrl.generate( '00000001', '00000050' );
		Test.stopTest();
		
		System.assertEquals( 50, [ SELECT Id FROM Anlagennummer__c ].size() );
	}
	
	@IsTest
	static void testGenerationChunking () {
		
		Test.startTest();
		AnlagennummerCtrl.generate( '00000001', '00000400' );
		Test.stopTest();
		
		System.assertEquals( 201, [ SELECT Id FROM Anlagennummer__c ].size() );
	}
	
	@IsTest
	static void testValidation () {
		
		Test.startTest();
		try {
			AnlagennummerCtrl.generate( '0', '00000000' );
		}
		catch ( Exception e ) {
			System.assert( e.getMessage().contains( 'Script-thrown exception' ) );
		}
		Test.stopTest();
	}
}