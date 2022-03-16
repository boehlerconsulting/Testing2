/**
 *@author       Mats Böhler
 *@created      10.05.2021
 *
 *
 *@description  NameFieldLimiterTest
 *
 *
 *@changelog    10.05.2021 Mats Böhler  - Created
 *              
 * 
 */
@IsTest
private class NameFieldLimiterTest {
	
	@IsTest
	static void testGetValue () {
		
		Test.startTest();
		NameFieldLimiter.getValue('test');
		String limitedValue = NameFieldLimiter.getValue( '12345678901234567890123456789012345678901234567890123456789012345678901234567890test' );
		Test.stopTest();
		
		System.assertEquals('12345678901234567890123456789012345678901234567890123456789012345678901234567...', limitedValue);
	}
}