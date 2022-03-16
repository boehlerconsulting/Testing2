/**
 *@author       Mats Böhler
 *@created      13.08.2020
 *
 *
 *@description  FilialnetzaenderungTriggerHandler
 *
 *
 *@changelog    13.08.2020 Mats Böhler  - Created
 *              
 * 
 */
public without sharing class FilialnetzaenderungTriggerHandler extends TriggerHandler {
	
	private List<Filialnetzaenderung__c> newRecords;
	private Map<Id, Filialnetzaenderung__c> newRecordMap;
	private Map<Id, Filialnetzaenderung__c> oldRecordMap;
	private Set<Id> processedIds = new Set<Id>();
	private GlobaleEinstellung__mdt globalSetting = GlobaleEinstellung__mdt.getInstance( 'Global' );
	
	public FilialnetzaenderungTriggerHandler () {
		this.newRecords = ( List<Filialnetzaenderung__c> ) Trigger.new;
		this.newRecordMap = ( Map<Id, Filialnetzaenderung__c> ) Trigger.newMap;
		this.oldRecordMap = ( Map<Id, Filialnetzaenderung__c> ) Trigger.oldMap;
	}
	
	protected override void beforeInsert () {
		if ( FeatureManagement.checkPermission( 'ZusammenlegungLeadmanagement1' ) ) {
			for ( Filialnetzaenderung__c filialnetzaenderung : newRecords ) {
				filialnetzaenderung.AufbauzielPackstationAlt__c = filialnetzaenderung.AufbauzielPackstation__c;
			}
		}
	}
	
	protected override void afterInsert () {
		
		process();
	}
	
	protected override void beforeUpdate () {
		if ( FeatureManagement.checkPermission( 'ZusammenlegungLeadmanagement1' ) ) {
			for ( Filialnetzaenderung__c filialnetzaenderung : newRecords ) {
				if ( filialnetzaenderung.AufbauzielPackstationAlt__c == null
						|| filialnetzaenderung.AufbauzielPackstation__c != oldRecordMap.get( filialnetzaenderung.Id ).AufbauzielPackstation__c ) {
					filialnetzaenderung.AufbauzielPackstationAlt__c = oldRecordMap.get( filialnetzaenderung.Id ).AufbauzielPackstation__c;
				}
			}
		}
	}
	
	protected override void afterUpdate () {
		
		process();
	}
	
	private void process () {
		
		Set<Id> belowLimitIds = new Set<Id>();
		List<Filialnetzaenderung__c> aufbauzielPackstationIds = new List<Filialnetzaenderung__c>();
		List<Filialnetzaenderung__c> zielterminPostponedIds = new List<Filialnetzaenderung__c>();
		Map<Id, Filialnetzaenderung__c> zielTerminChangedIdsById = new Map<Id, Filialnetzaenderung__c>();
		
		for ( Filialnetzaenderung__c filialnetzaenderung : newRecords ) {
			
			if ( processedIds.contains( filialnetzaenderung.Id ) ) {
				continue;
			}
			if ( FeatureManagement.checkPermission( 'ZusammenlegungLeadmanagement1' ) &&
					( isAufbauzielPackstationNew( filialnetzaenderung )
							|| isAufbauzielPackstationChanged( filialnetzaenderung ) ) ) {
				
				aufbauzielPackstationIds.add( filialnetzaenderung );
			}
			else if ( isZielterminPostponed( filialnetzaenderung ) ) {
				
				zielterminPostponedIds.add( filialnetzaenderung );
			}
			else {
				//Sonarqube --> do nothing
			}
			if ( isTargetBelowLimit( filialnetzaenderung ) ) {
				
				belowLimitIds.add( filialnetzaenderung.Id );
			}
			if ( zielTerminChanged( filialnetzaenderung ) ) {
				zielTerminChangedIdsById.put( filialnetzaenderung.Id, filialnetzaenderung );
			}
			
			processedIds.add( filialnetzaenderung.Id );
		}
		processAkquiseauftraegeWithNotification( aufbauzielPackstationIds );
		processAkquiseauftraege( zielterminPostponedIds );
		deactivateLeads( belowLimitIds );
		updateErledigungstermineOnAkquiseauftraegen( zielTerminChangedIdsById );
		TaskWorker.getInstance().process( true );
	}
	
	private Boolean isAllowedToCreateAkquiseauftraege ( Filialnetzaenderung__c filialnetzaenderung ) {
		return Date.today().addDays( Integer.valueOf( globalSetting.AkquiseauftragPackstationAusloesewert__c ) )
				> filialnetzaenderung.Zieltermin__c;
	}
	
	private Boolean isZielterminPostponed ( Filialnetzaenderung__c filialnetzaenderung ) {
		return Trigger.isUpdate
				&& filialnetzaenderung.AufbauzielPackstation__c != null
				&& filialnetzaenderung.Zieltermin__c != null
				&& filialnetzaenderung.Zieltermin__c > oldRecordMap.get( filialnetzaenderung.Id ).Zieltermin__c
				&& filialnetzaenderung.Zieltermin__c != oldRecordMap.get( filialnetzaenderung.Id ).Zieltermin__c
				&& isAllowedToCreateAkquiseauftraege( filialnetzaenderung );
	}
	
	private Boolean zielTerminChanged ( Filialnetzaenderung__c filialnetzaenderung ) {
		return ( Trigger.isInsert && filialnetzaenderung.Zieltermin__c != null )
				|| ( Trigger.isUpdate
				&& filialnetzaenderung.Zieltermin__c != null
				&& filialnetzaenderung.Zieltermin__c != oldRecordMap.get( filialnetzaenderung.Id ).Zieltermin__c );
	}
	
	private Boolean isAufbauzielPackstationNew ( Filialnetzaenderung__c filialnetzaenderung ) {
		return Trigger.isInsert
				&& filialnetzaenderung.AufbauzielPackstation__c != null
				&& isAllowedToCreateAkquiseauftraege( filialnetzaenderung );
	}
	
	private Boolean isAufbauzielPackstationChanged ( Filialnetzaenderung__c filialnetzaenderung ) {
		return Trigger.isUpdate
				&& filialnetzaenderung.AufbauzielPackstation__c != null
				&& filialnetzaenderung.AufbauzielPackstation__c != oldRecordMap.get( filialnetzaenderung.Id ).AufbauzielPackstation__c
				&& isAllowedToCreateAkquiseauftraege( filialnetzaenderung );
	}
	
	private void processAkquiseauftraege ( List<Filialnetzaenderung__c> aufbauzielPackstationIds ) {
		if ( aufbauzielPackstationIds.isEmpty() ) {
			return;
		}
		Map<Id, List<Task>> openTasksByFilialnetzaenderungId = loadOpenTasksByFilialnetzaenderungId( aufbauzielPackstationIds );
		
		for ( Filialnetzaenderung__c filialnetzaenderung : aufbauzielPackstationIds ) {
			
			Integer numberOfOpenTasks = openTasksByFilialnetzaenderungId.containsKey( filialnetzaenderung.Id )
					? openTasksByFilialnetzaenderungId.get( filialnetzaenderung.Id ).size()
					: 0;
			if ( filialnetzaenderung.AufbauzielPackstation__c > numberOfOpenTasks ) {
				Integer numberOfNewAkquisen = ( Integer ) filialnetzaenderung.AufbauzielPackstation__c - ( Integer ) numberOfOpenTasks;
				
				for ( Integer i = 0; i < numberOfNewAkquisen; i++ ) {
					
					addAkquiseauftragPackstation( filialnetzaenderung );
				}
			}
		}
	}
	
	private void addAkquiseauftragPackstation ( Filialnetzaenderung__c filialnetzaenderung ) {
		TaskWorker.getInstance().add(
				new Task(
						Aufgabenart__c = 'Akquiseauftrag Packstation zu FNÄ',
						Auftraggeber__c = 'Vertriebsleiter',
						Auftragnehmer__c = 'Vertriebskoordinator VL',
						ActivityDate = Date.today(),
						Erledigung_bis_zum__c = Date.today().addDays( 90 ),
						Status = 'Nicht begonnen',
						Priority = 'Mittel',
						Filialnetzaenderung__c = filialnetzaenderung.Id,
						RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
								.get( 'AkquiseauftragPackstation' ).getRecordTypeId(),
						WhatId = filialnetzaenderung.VL_Filialvertrieb__c,
						NL_Brief__c = filialnetzaenderung.NL_Brief__c,
						OwnerId = filialnetzaenderung.NL_BriefKoordinator__c == null
								? UserInfo.getUserId()
								: filialnetzaenderung.NL_BriefKoordinator__c,
						Zieltermin__c = filialnetzaenderung.Zieltermin__c,
						ZielFachanzahl__c = 80
				)
		);
	}
	
	private void processAkquiseauftraegeWithNotification ( List<Filialnetzaenderung__c> aufbauzielPackstationIds ) {
		if ( aufbauzielPackstationIds.isEmpty() ) {
			return;
		}
		Map<Id, List<Task>> openTasksByFilialnetzaenderungId = loadOpenTasksByFilialnetzaenderungId( aufbauzielPackstationIds );
		Set<Id> filialnetzaenderungSendNotificationIds = new Set<Id>();
		
		for ( Filialnetzaenderung__c filialnetzaenderung : aufbauzielPackstationIds ) {
			Integer numberOfOpenTasks = openTasksByFilialnetzaenderungId.containsKey( filialnetzaenderung.Id )
					? openTasksByFilialnetzaenderungId.get( filialnetzaenderung.Id ).size()
					: 0;
			if ( filialnetzaenderung.AufbauzielPackstation__c > numberOfOpenTasks ) {
				Integer numberOfNewAkquisen = ( Integer ) filialnetzaenderung.AufbauzielPackstation__c - ( Integer ) numberOfOpenTasks;
				
				for ( Integer i = 0; i < numberOfNewAkquisen; i++ ) {
					
					addAkquiseauftragPackstation( filialnetzaenderung );
				}
			}
			else if ( filialnetzaenderung.AufbauzielPackstation__c < numberOfOpenTasks ) {
				filialnetzaenderungSendNotificationIds.add( filialnetzaenderung.Id );
				addRequest(filialnetzaenderung.Id, 'UeberzaehligeAkquisePackstation');
			}
			else {
				//Sonarqube --> do nothing
			}
		}
		sendEmails();
	}
	
	private Map<Id, List<Task>> loadOpenTasksByFilialnetzaenderungId ( List<Filialnetzaenderung__c> aufbauzielPackstationIds ) {
		Map<Id, List<Task>> openTasksByFilialnetzaenderungId = new Map<Id, List<Task>>();
		for ( Task task : [
				SELECT
						Id,
						Filialnetzaenderung__c
				FROM Task
				WHERE Filialnetzaenderung__c IN :aufbauzielPackstationIds
				AND IsClosed = FALSE
				AND Aufgabenart__c = 'Akquiseauftrag Packstation zu FNÄ'
		] ) {
			if ( openTasksByFilialnetzaenderungId.containsKey( task.Filialnetzaenderung__c ) ) {
				openTasksByFilialnetzaenderungId.get( task.Filialnetzaenderung__c ).add( task );
			}
			else {
				openTasksByFilialnetzaenderungId.put( task.Filialnetzaenderung__c, new List<Task> {
						task
				} );
			}
		}
		return openTasksByFilialnetzaenderungId;
	}
	
	private Boolean isTargetBelowLimit ( Filialnetzaenderung__c filialnetzaenderung ) {
		if ( Trigger.isInsert ) {
			return false;
		}
		return filialnetzaenderung.Faecher_Aufbauziel__c < filialnetzaenderung.FaecherAufbauzielSchwellenwert__c
				&& ( filialnetzaenderung.Faecher_Gesamtziel__c != oldRecordMap.get( filialnetzaenderung.Id ).Faecher_Gesamtziel__c
				|| filialnetzaenderung.Faecher_IST__c != oldRecordMap.get( filialnetzaenderung.Id ).Faecher_IST__c );
	}
	
	private void deactivateLeads ( Set<Id> filialnetzaenderungIds ) {
		if ( filialnetzaenderungIds.isEmpty() ) {
			return;
		}
		List<Lead> leads = new List<Lead>();
		for ( Lead lead : [
				SELECT
						Id
				FROM Lead
				WHERE Filialnetzaenderung__c IN :filialnetzaenderungIds
				AND RelevantFuerDeaktivierung__c = TRUE
				AND Aktivitaetsstatus__c != 'inaktiv durch Zentrale'
				AND Aktivitaetsstatus__c != 'inaktiv'
		] ) {
			lead.Aktivitaetsstatus__c = 'inaktiv durch Zentrale';
			leads.add( lead );
		}
		if ( !leads.isEmpty() ) {
			update leads;
		}
	}
	
	private void updateErledigungstermineOnAkquiseauftraegen ( Map<Id, Filialnetzaenderung__c> filialnetzaenderungs ) {
		if ( filialnetzaenderungs.values().isEmpty() ) {
			return;
		}
		TaskWorker uow = TaskWorker.getInstance();
		for ( Task task : [
				SELECT
						Id,
						Filialnetzaenderung__c
				FROM Task
				WHERE IsClosed = FALSE
				AND Filialnetzaenderung__c IN :filialnetzaenderungs.keySet()
				AND Aufgabenart__c = 'Akquiseauftrag Packstation zu FNÄ'
		] ) {
			Filialnetzaenderung__c filialnetzaenderung = filialnetzaenderungs.get( task.Filialnetzaenderung__c );
			Date newZielTermin = filialnetzaenderung.Zieltermin__c.addDays( -90 ) < Date.today()
					? Date.today()
					: filialnetzaenderung.Zieltermin__c.addDays( -90 );
			Task existingTask = uow.exists( task ) ? uow.get( task ) : task;
			existingTask.Erledigung_bis_zum__c = Date.today().addDays( 7 ) > newZielTermin ? Date.today().addDays( 7 ) : newZielTermin;
			uow.add( task );
		}
	}
	
	private void sendEmails(){
		EmailSettingService.getInstance().sendBulk();
	}
	
	private void addRequest ( String fnaeId, String emailSettingDeveloperName ) {
		EmailSettingService.Request request = new EmailSettingService.Request();
		request.recordId = fnaeId;
		request.emailSettingName = emailSettingDeveloperName;
		request.fnaeId = fnaeId;
		EmailSettingService.getInstance().requests.add( request );
	}
}