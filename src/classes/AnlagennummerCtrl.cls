/**
 *@author       Mats Böhler
 *@created      13.06.2020
 *
 *
 *@description  AnlagennummerCtrl
 *
 *
 *@changelog    13.06.2020 Mats Böhler  - Created
 *              
 * 
 */
public without sharing class AnlagennummerCtrl {
	
	private final static Integer MAX_RECORDS = 200;
	
	@AuraEnabled
	public static String generate ( String startNumber, String endNumber ) {
		
		try {
			if ( String.isEmpty( startNumber ) || String.isEmpty( endNumber ) ) {
				return startNumber;
			}
			startNumber = chunkGeneration( startNumber, endNumber );
		}
		catch ( Exception e ) {
			
			throw new AuraHandledException( e.getMessage() );
		}
		return startNumber;
	}
	
	private static String chunkGeneration ( String startNumber, String endNumber ) {
		Integer totalRecords = Integer.valueOf( endNumber ) - Integer.valueOf( startNumber );
		if ( totalRecords <= MAX_RECORDS ) {
			new AnlagennummerService().generate( startNumber, endNumber );
		}
		Integer newStartNumber;
		if ( totalRecords > MAX_RECORDS ) {
			String newEndNumber = String.valueOf( Integer.valueOf( startNumber ) + MAX_RECORDS );
			while ( newEndNumber.length() < 8 ) {
				newEndNumber = '0' + newEndNumber;
			}
			new AnlagennummerService().generate( startNumber, newEndNumber );
			newStartNumber = Integer.valueOf( startNumber ) + MAX_RECORDS + 1;
			startNumber = String.valueOf( newStartNumber );
			while ( startNumber.length() < 8 ) {
				startNumber = '0' + startNumber;
			}
		}
		return startNumber;
	}
}