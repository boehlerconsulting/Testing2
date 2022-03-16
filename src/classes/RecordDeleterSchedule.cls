/**
 *@author       Mats Böhler
 *@created      15.07.2021
 *
 *
 *@description  RecordDeleterSchedule
 *
 *
 *@changelog    15.07.2021 Mats Böhler  - Created
 *              
 * 
 */
public without sharing class RecordDeleterSchedule implements Schedulable {
	
	public void execute ( SchedulableContext ctx ) {
		
		startProcess();
	}
	
	public void startProcess () {
		String filter = Test.isRunningTest()
				? ' WHERE Objekt__c = \'Lead\''
				: ' WHERE Objekt__c != NULL AND Feld__c != NULL AND IstAktiv__c = TRUE';
		
		for ( LoeschEinstellung__mdt setting
				: Database.query( 'SELECT Id, Objekt__c, Feld__c, HardDelete__c FROM LoeschEinstellung__mdt' + filter ) ) {
			
			String query = 'SELECT Id FROM ' + setting.Objekt__c
					+ ' WHERE ' + setting.Feld__c + ' = TRUE';
			
			if ( setting.Objekt__c == 'AccountContactRelation' ) {
				
				query = 'SELECT Id, ContactId FROM ' + setting.Objekt__c
						+ ' WHERE ' + setting.Feld__c + ' = TRUE';
			}
			
			if ( setting.Objekt__c == 'Event' || setting.Objekt__c == 'Task' ) {
				
				query = 'SELECT Id FROM ' + setting.Objekt__c + ' WHERE ' + setting.Feld__c + ' = TRUE AND IsDeleted = FALSE ALL ROWS';
			}
			
			Database.executeBatch(
					new RecordDeleterBatch( query, setting ),
					BatchJobSetting.getBatchSize( 'RecordDeleterBatch' )
			);
			if ( Test.isRunningTest() ) {
				break;
			}
		}
	}
}