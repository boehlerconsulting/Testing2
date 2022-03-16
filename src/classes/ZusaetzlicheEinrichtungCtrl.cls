/**
 * @author      Stefan Richter (stefan.richter@hundw.de)
 *              H+W CONSULT GmbH
 *              Bahnhofstr. 3
 *              21244 Buchholz i. d. Nordheide
 *              Germany
 *              https://www.hundw.de
 *
 * @description class for <insert-description-here>
 *
 * TIMELINE
 * 28.09.21      Stefan Richter  Initial release.
 **/
public with sharing class ZusaetzlicheEinrichtungCtrl {
	
	@AuraEnabled
	public static String init () {
		Task task = new Task(
				ActivityDate = Date.today(),
				Erledigung_bis_zum__c = Date.today().addDays( 140 )
		);
		return JSON.serialize( task );
	}
	
	@AuraEnabled
	public static void createTask ( Id fnaeId, String jsonTaskRecord ) {
		
		Task taskRecord = ( Task ) JSON.deserialize( jsonTaskRecord, Task.class );
		
		taskRecord.RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
				.get( 'AkquiseauftragPackstation' ).getRecordTypeId();
		
		Filialnetzaenderung__c fnae = [
				SELECT Filiale_Filialpartner__c,
						Filiale_Filialpartner__r.GL__r.RVU_Team__r.Name
				FROM Filialnetzaenderung__c
				WHERE Id = :fnaeId
		];
		taskRecord.Auftragnehmer__c = 'Vertriebskoordinator VGL';
		taskRecord.Auftraggeber__c = '1L3 Netzmanagement';
		taskRecord.Filialnetzaenderung__c = fnaeId;
		taskRecord.WhatId = fnae.Filiale_Filialpartner__c;
		taskRecord.Type = 'Besuch';
		taskRecord.Typc__c = 'Besuch';
		
		TaskWorker uow = TaskWorker.getInstance();
		uow.add( taskRecord );
		uow.process( false );
	}
}