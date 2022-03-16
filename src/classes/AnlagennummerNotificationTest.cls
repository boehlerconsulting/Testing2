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
private class AnlagennummerNotificationTest {
	
	@IsTest
	static void testNotification () {
		
		Test.startTest();
		AnlagennummerNotification.sendEmail();
		Test.stopTest();
		
		System.assertEquals( 0, [ SELECT Id FROM Anlagennummer__c ].size() );
	}
}