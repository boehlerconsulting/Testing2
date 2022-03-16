/**
 *@author       Mats Böhler
 *@created      12.09.2019
 *@version      1.0
 *@since        45.0
 *
 *
 *@description  HW_PriohilfeVerwaltungTriggerHandler_T
 *
 *
 *@changelog    12.09.2019 Mats Böhler  - Created
 *              
 * 
 */
@IsTest
private class HW_PriohilfeVerwaltungTriggerHandler_T {
	
	@IsTest
	static void testMatchTaskTypePositive () {
		
		Test.startTest();
		insertPriohilfeVerwaltung( 'Auslistung FDL' );
		Test.stopTest();
		
		PriohilfeVerwaltung__c priohilfeVerwaltung = [
				SELECT
						Id,
						Aufgabenart__c
				FROM PriohilfeVerwaltung__c
				LIMIT 1
		];
		
		System.assertEquals( 'Auslistung FDL', priohilfeVerwaltung.Aufgabenart__c );
	}
	
	@IsTest
	static void testMatchTaskTypeDuplicate () {
		
		Test.startTest();
		insertPriohilfeVerwaltung( 'Auslistung FDL' );
		try {
			insertPriohilfeVerwaltung( 'Auslistung FDL' );
		}
		catch ( Exception e ) {
			System.assertEquals( 'System.DmlException', e.getTypeName() );
		}
		
		Test.stopTest();
	}
	
	@IsTest
	static void testMatchTaskTypeNegative () {
		
		Test.startTest();
		try {
			insertPriohilfeVerwaltung( 'TEST' );
		}
		catch ( Exception e ) {
			System.assertEquals( 'System.DmlException', e.getTypeName() );
		}
		
		Test.stopTest();
	}
	
	private static PriohilfeVerwaltung__c insertPriohilfeVerwaltung ( String taskType ) {
		PriohilfeVerwaltung__c priohilfeVerwaltung = new PriohilfeVerwaltung__c(
				AufgabenartGlobal__c = taskType,
				Aufgabenart__c = taskType
		);
		insert priohilfeVerwaltung;
		return priohilfeVerwaltung;
	}
}