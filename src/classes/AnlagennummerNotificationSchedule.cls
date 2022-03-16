/**
 *@author       Mats Böhler
 *@created      16.06.2020
 *
 *
 *@description  AnlagennummerSchedule
 *              MYPM-402 Meldung Anlagennummern an Anlagenbuchhaltung
 *
 *@changelog    16.06.2020 Mats Böhler  - Created
 *              
 * 
 */
public without sharing class AnlagennummerNotificationSchedule implements Schedulable {
	
	@TestVisible
	private static Boolean testException = false;
	
	public void execute ( SchedulableContext ctx ) {
		
		try {
			new AnlagennummerNotificationService().sendEmailNotificationToAnlagenbuchhaltung();
			if ( testException && Test.isRunningTest() ) {
				throw new AnlagennummerNotificationScheduleException( 'Testing Exception' );
			}
		}
		catch ( Exception e ) {
			new HW_ErrorLogging().logException(
					e,
					new Set<Id>(),
					'MYPM-402 Meldung Anlagennummern an Anlagenbuchhaltung'
			);
		}
	}
	
	private class AnlagennummerNotificationScheduleException extends Exception {
	
	}
}