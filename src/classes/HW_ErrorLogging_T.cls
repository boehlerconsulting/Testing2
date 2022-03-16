/**
 *@author       Mats Böhler
 *@created      19.09.2019
 *@version      1.0
 *@since        45.0
 *
 *
 *@description  HW_ErrorLogging_T
 *
 *
 *@changelog    19.09.2019 Mats Böhler  - Created
 *              
 * 
 */
@IsTest
private class HW_ErrorLogging_T {
	
	@IsTest
	static void testBatchErrorLogging () {
		
		List<BatchApexErrorEvent> batchApexErrorEvents = createApexErrorEvents();
		
		Test.startTest();
		EventBus.publish( batchApexErrorEvents[ 0 ] );
		Test.getEventBus().deliver();
		Test.stopTest();
		
		for ( Logbuch__c errorLog : [
				SELECT
						Id,
						Herkunft__c,
						Job__c,
						Meldung__c,
						Type__c,
						Zeitpunkt__c
				FROM Logbuch__c
		] ) {
			
			System.assertEquals( null, errorLog.Herkunft__c );
			System.assertEquals( 'Batch Apex', errorLog.Job__c );
			System.assertEquals( 'StackTrace | Message | JobScope', errorLog.Meldung__c );
			System.assertEquals( 'ExceptionType', errorLog.Type__c );
		}
		
		System.assertEquals( 1, [
				SELECT
						Id
				FROM Logbuch__c
		].size() );
	}
	
	private static List<BatchApexErrorEvent> createApexErrorEvents () {
		List<BatchApexErrorEvent> batchApexErrorEvents = new List<BatchApexErrorEvent>();
		batchApexErrorEvents.add( new BatchApexErrorEvent(
				StackTrace = 'StackTrace',
				Message = 'Message',
				ExceptionType = 'ExceptionType',
				JobScope = 'JobScope'
		) );
		return batchApexErrorEvents;
	}
}