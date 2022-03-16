/**
 *@author       Mats Böhler
 *@created      23.11.2021
 *
 *
 *@description  PackstationTriggerHandler
 *
 *
 *@changelog    23.11.2021 Mats Böhler  - Created
 *              
 * 
 */
public without sharing class PackstationTriggerHandler extends AccountBaseHandler {
	
	private List<Account> newRecords = new List<Account>();
	private Set<Id> accountIdsDeactivateLeads = new Set<Id>();
	
	public PackstationTriggerHandler ( List<Account> newRecords ) {
		this.newRecords = newRecords;
	}
	
	protected override void afterInsert () {
		if ( newRecords.isEmpty() ) {
			return;
		}
		processAfterInsert();
	}
	
	protected override void afterUpdate () {
		if ( newRecords.isEmpty() ) {
			return;
		}
		processAfterUpdate();
	}
	
	protected override void afterDelete () {
		if ( newRecords.isEmpty() ) {
			return;
		}
		processAfterDelete();
	}
	
	private void processAfterInsert () {
		for ( Account account : newRecords ) {
			processAccount( account );
		}
		deactivateKuendigungAbbauLeads();
		new PackstationDummyInitializer().create( handlerState.leadIdsPackstation );
		new PackstationService().createLeads( handlerState.accountIdsBestandsmassnahme );
	}
	
	private void processAfterUpdate () {
		for ( Account account : newRecords ) {
			processAccount( account );
			addRequestIfKuendigung( account );
			addRequestIfKuendigungZurueckgezogen( account );
		}
		updatePODIDs();
		deactivateKuendigungAbbauLeads();
		deactivateLeads( handlerState.leadIdsPackstation );
		new PackstationDummyInitializer().create( handlerState.leadIdsPackstation );
		new PackstationService().createLeads( handlerState.accountIdsBestandsmassnahme );
	}
	
	private void processAfterDelete () {
		handlerState.accountsByRemovedPODIDs = new Map<Id, List<Account>>();
		for ( Account account : newRecords ) {
			if ( account.PODID__c != null ) {
				if ( handlerState.accountsByRemovedPODIDs.containsKey( account.PODID__c ) ) {
					handlerState.accountsByRemovedPODIDs.get( account.PODID__c ).add( account );
				}
				else {
					handlerState.accountsByRemovedPODIDs.put( account.PODID__c, new List<Account> {
							account
					} );
				}
			}
		}
		updatePODIDs();
	}
	
	private void processAccount ( Account account ) {
		addRemovedPODID( account );
		addTasks( account );
		if ( isKuendigungZurueckgezogen( account ) ) {
			accountIdsDeactivateLeads.add( account.Id );
		}
		if ( isUpdateFromDummyToPackstation( account ) ) {
			handlerState.leadIdsPackstation.add( account.Lead__c );
		}
		if ( isBestandsmassnahme( account ) ) {
			handlerState.accountIdsBestandsmassnahme.add( account.Id );
		}
	}
	
	private void updatePODIDs () {
		if ( handlerState.accountsByRemovedPODIDs.isEmpty() ) {
			return;
		}
		Set<Id> existingReferences = new Set<Id>();
		for ( Lead lead : [
				SELECT
						Id,
						PODID_Lookup__c
				FROM Lead
				WHERE PODID_Lookup__c IN :handlerState.accountsByRemovedPODIDs.keySet()
		] ) {
			existingReferences.add( lead.PODID_Lookup__c );
		}
		for ( Account account : [
				SELECT
						Id,
						PODID__c
				FROM Account
				WHERE PODID__c IN :handlerState.accountsByRemovedPODIDs.keySet()
		] ) {
			existingReferences.add( account.PODID__c );
		}
		List<PODID__c> podids = new List<PODID__c>();
		for ( PODID__c podId : [
				SELECT
						Id,
						Anmerkung__c,
						Wert__c
				FROM PODID__c
				WHERE Id IN :handlerState.accountsByRemovedPODIDs.keySet()
		] ) {
			for ( Account account : handlerState.accountsByRemovedPODIDs.get( podId.Id ) ) {
				if ( !existingReferences.contains( podId.Id ) ) {
					podId.Status__c = 'Gelöscht';
				}
				if ( podId.Anmerkung__c == null ) {
					podId.Anmerkung__c = '';
				}
				podId.Anmerkung__c += '\n' + Date.today().format() + ': PODID "' + podId.Wert__c + '" wurde aus dem Account "'
						+ account.Name + '" (' + account.Id + ') entfernt.';
			}
			podids.add( podId );
		}
		update podids;
	}
	
	private void addTasks ( Account account ) {
		if ( isTaskKuendigungsrueckgewinnung( account ) ) {
			addTaskKuendigungsrueckgewinnung( account );
		}
		if ( isTaskEntlastungPackstation( account ) ) {
			addTaskEntlastungPackstation( account );
		}
		if ( isTaskFormatwechsel( account ) ) {
			addTaskFormatwechsel( account );
		}
	}
	
	private void addRemovedPODID ( Account account ) {
		if ( Trigger.isUpdate && account.PODID__c == null
				&& oldAccountMap.get( account.Id ).PODID__c != null ) {
			Account oldAccount = oldAccountMap.get( account.Id );
			if ( handlerState.accountsByRemovedPODIDs.containsKey( oldAccount.PODID__c ) ) {
				handlerState.accountsByRemovedPODIDs.get( oldAccount.PODID__c ).add( oldAccount );
			}
			else {
				handlerState.accountsByRemovedPODIDs.put( oldAccount.PODID__c, new List<Account> {
						oldAccount
				} );
			}
		}
	}
	
	private void addTaskKuendigungsrueckgewinnung ( Account account ) {
		TaskWorker uow = TaskWorker.getInstance();
		uow.add(
				new Task(
						WhatId = account.Id,
						Aufgabenart__c = 'Kündigungsrückgewinnung Pack-/Poststation',
						Auftraggeber__c = 'Regionale Vertriebsunterstützung',
						Auftragnehmer__c = 'Vertriebsmanager',
						ActivityDate = Date.today(),
						Erledigung_bis_zum__c = Date.today().addDays( 7 ),
						Priority = 'Mittel',
						Status = 'Nicht begonnen',
						Typc__c = 'Call',
						RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
								.get( 'AkquiseauftragPackstation' ).getRecordTypeId(),
						Filialnetzaenderung__c = account.Filialnetzaenderung__c
				)
		);
	}
	
	private void addTaskEntlastungPackstation ( Account account ) {
		TaskWorker uow = TaskWorker.getInstance();
		uow.add(
				new Task(
						WhatId = account.Id,
						Aufgabenart__c = 'Akquiseauftrag Entlastung Packstation',
						ZielFachanzahl__c = account.Ziel_Fachanzahl__c,
						Auftraggeber__c = 'Vertriebsgebietsleiter',
						Auftragnehmer__c = 'Vertriebsmanager',
						ActivityDate = Date.today(),
						Erledigung_bis_zum__c = Date.today().addDays( 84 ),
						Priority = 'Mittel',
						Status = 'Nicht begonnen',
						Typc__c = 'Besuch',
						RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
								.get( 'AkquiseauftragPackstation' ).getRecordTypeId(),
						Filialnetzaenderung__c = account.Filialnetzaenderung__c,
						Description = 'Ziel-Fachanzahl: ' + account.Ziel_Fachanzahl__c.format() + '\r\n'
								+ 'Ziel-Format: ' + account.Ziel_Format__c + '\r\n'
								+ 'Hinweis Bestandsmaßnahme: ' + account.Hinweis_Bestandsmassnahme__c + '\r\n'
				)
		);
	}
	
	private void addTaskFormatwechsel ( Account account ) {
		TaskWorker uow = TaskWorker.getInstance();
		uow.add(
				new Task(
						WhatId = account.Id,
						Aufgabenart__c = 'Formatwechsel (Pack-/Poststation)',
						ZielFachanzahl__c = account.Ziel_Fachanzahl__c,
						Auftraggeber__c = '1L3 Netzmanagement',
						Auftragnehmer__c = 'Vertriebsmanager',
						ActivityDate = Date.today(),
						Erledigung_bis_zum__c = Date.today().addDays( 28 ),
						Priority = 'Mittel',
						Status = 'Nicht begonnen',
						Typc__c = 'Besuch',
						RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
								.get( 'AkquiseauftragPackstation' ).getRecordTypeId(),
						Filialnetzaenderung__c = account.Filialnetzaenderung__c,
						Description = 'Ziel-Fachanzahl: ' + account.Ziel_Fachanzahl__c.format() + '\r\n'
								+ 'Ziel-Format: ' + account.Ziel_Format__c + '\r\n'
								+ 'Hinweis Bestandsmaßnahme: ' + account.Hinweis_Bestandsmassnahme__c + '\r\n'
				)
		);
	}
	
	private Boolean isTaskKuendigungsrueckgewinnung ( Account account ) {
		return Trigger.isUpdate
				&& account.Bestandsmassnahme__c == 'Kündigung'
				&& account.Rueckgewinnung_erforderlich__c
				&& account.Akquisemodus__c != 'Standortaufnahme vor Ort; Danach Übergabe an rVU'
				&& isChanged( account.Id, 'Bestandsmassnahme__c' );
	}
	
	private Boolean isTaskEntlastungPackstation ( Account account ) {
		return Trigger.isUpdate
				&& account.Bestandsmassnahme__c == 'Entlastung (Erweiterung / Austausch)'
				&& account.Akquisemodus__c != 'Standortaufnahme vor Ort; Danach Übergabe an rVU'
				&& isChanged( account.Id, 'Bestandsmassnahme__c' );
	}
	
	private Boolean isTaskFormatwechsel ( Account account ) {
		return Trigger.isUpdate
				&& account.Bestandsmassnahme__c == 'Formatwechsel (Pack-/Poststation)'
				&& account.Akquisemodus__c != 'Standortaufnahme vor Ort; Danach Übergabe an rVU'
				&& isChanged( account.Id, 'Bestandsmassnahme__c' );
	}
	
	private Boolean isKuendigungZurueckgezogen ( Account account ) {
		return Trigger.isUpdate
				&& account.Kuendigung_durch__c == 'Kündigung zurückgezogen'
				&& isChanged( account.Id, 'Kuendigung_durch__c' );
	}
	
	private Boolean isUpdateFromDummyToPackstation ( Account account ) {
		return Trigger.isUpdate
				&& isChanged( account.Id, 'RecordTypeId' )
				&& account.Lead__c != null;
	}
	
	private Boolean isBestandsmassnahme ( Account account ) {
		return Trigger.isUpdate
				&& account.Bestandsmassnahme__c != null
				&& isChanged( account.Id, 'Bestandsmassnahme__c' );
	}
	
	private void deactivateKuendigungAbbauLeads () {
		if ( accountIdsDeactivateLeads.isEmpty() ) {
			return;
		}
		List<Lead> leads = new List<Lead>();
		for ( Lead lead : [
				SELECT
						Id,
						ist_disponiert__c
				FROM Lead
				WHERE Filiale_Filialpartner__c IN :accountIdsDeactivateLeads
				AND ( Aktivitaetsstatus__c = 'aktiv' OR Aktivitaetsstatus__c = 'aktiv durch Zentrale' )
				AND Bestandsmassnahme__c = 'Kündigung - Abbau'
		] ) {
			
			lead.Abbau_geplant_Datum__c = null;
			lead.Aktivitaetsstatus__c = 'inaktiv';
			lead.Bewertung_VM__c = 'Absage DHL - Sonstiges (Grund in Freitext)';
			lead.Bewertung_VM_vom__c = Date.today();
			lead.Hinweis_AO__c = 'Kündigung wurde zurückgezogen';
			if ( lead.ist_disponiert__c ) {
				lead.STO_disponiert__c = null;
				lead.Meldewelle__c = null;
				lead.Abbau_geplant_Datum__c = null;
				lead.Beauftragung_Genehmigung_Elektro__c = null;
				lead.Elektro_fertiggestellt__c = null;
				lead.Beauftragung_Tiefbau__c = null;
				lead.Tiefbau_fertiggestellt__c = null;
				lead.Baucheck_erfolgt_Datum__c = null;
				lead.Aufbaufaehig_ab_Datum__c = null;
				lead.ist_disponiert__c = false;
			}
			leads.add( lead );
		}
		update leads;
		
		List<Task> tasks = new List<Task>();
		for ( Task task : [
				SELECT Id
				FROM Task
				WHERE WhatId IN :accountIdsDeactivateLeads
				AND Aufgabenart__c = 'Kündigungsrückgewinnung Pack-/Poststation'
				AND Status != 'Zurückgezogen (Nur AG)'
				AND IsClosed = FALSE
		] ) {
			task.Status = 'Zurückgezogen (Nur AG)';
			tasks.add( task );
		}
		update tasks;
	}
	
	private void deactivateLeads ( Set<Id> leadIdsPackstation ) {
		if ( leadIdsPackstation.isEmpty() ) {
			return;
		}
		List<Lead> leads = new List<Lead>();
		for ( Id leadId : leadIdsPackstation ) {
			leads.add(
					new Lead(
							Id = leadId,
							Aktivitaetsstatus__c = 'inaktiv'
					)
			);
		}
		update leads;
	}
	
	private void addRequest ( Account account, String emailSettingDeveloperName ) {
		EmailSettingService.Request request = new EmailSettingService.Request();
		request.recordId = account.Id;
		request.emailSettingName = emailSettingDeveloperName;
		request.accountId = account.Id;
		EmailSettingService.getInstance().requests.add( request );
	}
	
	private void addRequestIfKuendigung ( Account account ) {
		if ( isKuendigung( account )
				&& !isKuendigung( oldAccountMap.get( account.Id ) ) ) {
			addRequest( account, 'Kuendigung_Packstation_Info_an_VL' );
		}
	}
	
	private void addRequestIfKuendigungZurueckgezogen ( Account account ) {
		if ( isKuendigungZurueckgezogen( account ) ) {
			addRequest( account, 'Kuendigung_zurueckgezogen' );
		}
	}
	
	private Boolean isKuendigung ( Account account ) {
		return account.Bestandsmassnahme__c == 'Kündigung'
				&& account.Akquisemodus__c != 'Standortaufnahme vor Ort; Danach Übergabe an rVU';
	}
}