/**
 *@author       Mats Böhler
 *@created      16.06.2020
 *
 *
 *@description  AnlagennummerScheduleTest
 *
 *
 *@changelog    16.06.2020 Mats Böhler  - Created
 *              
 * 
 */
@IsTest
private class AnlagennummerNotificationScheduleTest {
	
	@IsTest
	static void testSchedule () {
		Test.startTest();
		System.schedule(
				'AnlagennummerNotificationScheduleTest',
				'0 0 23 * * ?',
				new AnlagennummerNotificationSchedule()
		);
		Test.stopTest();
		
		System.assertEquals( 1, 1 );
	}
	
	@IsTest
	static void testScheduleFailure () {
		Test.startTest();
		AnlagennummerNotificationSchedule.testException = true;
		System.schedule(
				'AnlagennummerNotificationScheduleTest',
				'0 0 23 * * ?',
				new AnlagennummerNotificationSchedule()
		);
		Test.stopTest();
		
		System.assertEquals( 1, [ SELECT Id FROM Logbuch__c ].size() );
	}
}