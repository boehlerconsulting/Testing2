/**
 *@author       Mats Böhler
 *@created      16.06.2020
 *
 *
 *@description  AnlagennummerServiceTest
 *
 *
 *@changelog    16.06.2020 Mats Böhler  - Created
 *              
 * 
 */
@IsTest
private class AnlagennummerServiceTest {
	@IsTest
	static void testGenerationSuccess () {
		
		Test.startTest();
		new AnlagennummerService().generate( '00000000', '00000001' );
		List<Anlagennummer__c> anlagennummers = [ SELECT Id FROM Anlagennummer__c ];
		for ( Anlagennummer__c anlagennummer : anlagennummers ) {
			anlagennummer.Status__c = 'gesperrt';
		}
		update anlagennummers;
		new AnlagennummerService().generate( '00000000', '00000001' );
		Test.stopTest();
		
		System.assertEquals( 2, [ SELECT Id FROM Anlagennummer__c ].size() );
	}
	
	@IsTest
	static void testGenerationFailure () {
		
		Test.startTest();
		new AnlagennummerService().generate( '', '' );
		try {
			new AnlagennummerService().generate( '0000000', '00000001' );
		}
		catch ( Exception e ) {
			System.assert( e.getMessage().contains( 'Die Startnummer muss exakt 8 Stellen besitzen!' ) );
		}
		try {
			new AnlagennummerService().generate( '00000000', '0000000' );
		}
		catch ( Exception e ) {
			System.assert( e.getMessage().contains( 'Die Endnummer muss exakt 8 Stellen besitzen!' ) );
		}
		try {
			new AnlagennummerService().generate( '00000001', '00000000' );
		}
		catch ( Exception e ) {
			System.assert( e.getMessage().contains( 'Die Endnummer muss größer als die Startnummer sein!' ) );
		}
		Test.stopTest();
	}
}