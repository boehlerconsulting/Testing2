/**
 *@author       Mats Böhler
 *@created      28.03.2020
 *
 *
 *@description  PriorizationHelpTasks
 *
 *
 *@changelog    28.03.2020 Mats Böhler  - Created
 *              
 * 
 */
public with sharing class PriorizationHelpTasks extends PriorizationHelpBase {
	
	@TestVisible
	private List<Aufgabe> aufgaben = new List<Aufgabe>();
	private List<Schema.PicklistEntry> erledigungstypPicklistValues = new List<Schema.PicklistEntry>();
	
	public String load ( PriorizationHelpSetting setting ) {
		this.setting = setting;
		loadAmpelKonfigurations();
		loadTaskColumnDefinitions();
		createColumns();
		loadTasks();
		erledigungstypPicklistValues = getPicklistFieldValues( 'Task', 'Typc__c' );
		return JSON.serialize( this );
	}
	
	@TestVisible
	private void loadAmpelKonfigurations () {
		for ( PriohilfeAmpelKonfiguration__mdt ampelKonfiguration : [
				SELECT
						DeveloperName,
						Startwert__c,
						Endwert__c
				FROM PriohilfeAmpelKonfiguration__mdt
		] ) {
			ampelKonfigurationsByName.put( ampelKonfiguration.DeveloperName, ampelKonfiguration );
		}
	}
	
	private void loadTaskColumnDefinitions () {
		String status = setting.aufgabenstatusValue == 'Nicht begonnen'
				? 'offen'
				: setting.aufgabenstatusValue;
		columnDefinitions = [
				SELECT
						Id,
						LabelSpalte__c,
						Feldlabel__c,
						Feldname__c,
						Feldtyp__c,
						Sortierbar__c,
						Nummerierung__c
				FROM PriohilfeUebersicht__mdt
				WHERE Objekt__c = :setting.sObjectType
				AND Rolle__c = :setting.role
				AND Herkunft__c = :setting.origin
				AND Aufgabenstatus__c = :status
				AND Version__c = :setting.version
				ORDER BY Nummerierung__c ASC NULLS LAST
		];
	}
	
	private void loadTasks () {
		
		for ( Task task : load() ) {
			Aufgabe aufgabe = new Aufgabe();
			aufgabe.task = task;
			aufgabe.ampel = task.Ampel__c;
			if ( setting.version == 'mit Akquise' ) {
				aufgabe.ampel = getAmpelValue( task );
			}
			aufgaben.add( aufgabe );
		}
	}
	
	private void addRequiredFields () {
		List<String> requiredFields = new List<String> {
				'PriohilfeAufgabenverwaltung__r.Dokumentationspflicht__c',
				'Dringlichkeit__c',
				'Aufgabenart__c',
				'PriohilfeAufgabenverwaltung__r.AmpelAktiviert__c',
				'Ampel__c'
		};
		for ( String requiredField : requiredFields ) {
			addFieldIfMissing( requiredField );
		}
	}
	
	private String getCurrentUserOrg () {
		String currentUserOrge = [ SELECT Id, OrgE_DP__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1 ].OrgE_DP__c;
		currentUserOrge = currentUserOrge != null && currentUserOrge.length() > 8 ? currentUserOrge.substring( 8 ) : currentUserOrge;
		return currentUserOrge;
	}
	
	private List<Task> load () {
		
		addRequiredFields();
		String version = setting.version;
		String query = 'SELECT '
				+ setting.fields
				+ ' FROM ' + setting.sObjectType
				+ ' WHERE PriohilfeAufgabenverwaltung__r.Version__c = :version';
		
		/* MYPM-1085 */
		String currentUserOrge = getCurrentUserOrg();
		query += ' AND ( (Recordtype.DeveloperName = \'AkquiseauftragPackstation\' ' +
				'AND VG__c = :currentUserOrge ) OR  Recordtype.DeveloperName != \'AkquiseauftragPackstation\' )';
		
		if ( setting.zeige == 'Filiale' ) {
			query += ' AND Recordtype.DeveloperName != \'AkquiseauftragPackstation\'';
		}
		if ( setting.zeige == 'Packstation' ) {
			query += ' AND Recordtype.DeveloperName = \'AkquiseauftragPackstation\'';
		}
		if ( setting.isClosed ) {
			Date startDate = Date.today().addMonths( -setting.months );
			query += ' AND IsClosed = ' + setting.isClosed + ' AND Erledigt_am__c >= :startDate AND Erledigt_am__c <= TODAY';
		}
		else {
			query += ' AND IsClosed = ' + setting.isClosed;
		}
		if ( setting.aufgabenstatusValue == 'Nicht begonnen' ) {
			String status = setting.aufgabenstatusValue;
			query += ' AND Status = :status';
		}
		if ( setting.recordId != null ) {
			String recordId = setting.recordId;
			query += ' AND WhatId = :recordId';
		}
		if ( setting.isTerminNotTerminiert ) {
			query += ' AND TerminiertZum__c = NULL ' +
					'AND ( Auftragnehmer__c = \'Vertriebsleiter\' ' +
					'OR Auftragnehmer__c = \'Vertriebskoordinator VGL\' ' +
					'OR Auftragnehmer__c = \'Vertriebsmanager\' )';
		}
		else {
			if ( setting.isScheduled ) {
				query += ' AND TerminiertZum__c != NULL';
			}
			if ( setting.terminZum != null ) {
				Date terminiertZum = setting.terminZum;
				query += ' AND TerminiertZum__c = :terminiertZum';
			}
		}
		if ( setting.isFiliale ) {
			query += ' AND TerminiertZum__c = NULL';
		}
		query = addNLBrief( query );
		query = addRoleSpecificCriteria( query );
		if ( setting.terminZum != null ) {
			query += ' ORDER BY Typc__c asc, KennzifferPrioritaet__c desc NULLS LAST';
		}
		else {
			query += ' ORDER BY ' + setting.sortBy + ' ' + setting.sortDirection + ' NULLS LAST';
		}
		String userId = UserInfo.getUserId();
		String orgE = setting.vertriebsmanager.OrgE_DP__c;
		return Database.query( query );
	}
	
	private String addNLBrief ( String query ) {
		if ( String.isNotEmpty( setting.nlBrief ) ) {
			query += ' AND (';
			if ( !setting.nlBrief.contains( ',' ) ) {
				query += addWhereClauses( setting.nlBrief );
			}
			else {
				Integer i = 0;
				for ( String filter : setting.nlBrief.split( ',' ) ) {
					if ( i != 0 ) {
						query += 'OR ';
					}
					if ( String.isNotEmpty( filter ) ) {
						query += addWhereClauses( filter );
					}
					i++;
				}
			}
			query += ') ';
		}
		return query;
	}
	
	private String addWhereClauses ( String filter ) {
		String whereClause = ' NL_Brief__c LIKE \'%' + filter + '%\' ';
		return whereClause;
	}
	
	private String addRoleSpecificCriteria ( String query ) {
		if ( setting.role == 'VM' ) {
			String userId = UserInfo.getUserId();
			String orgE = setting.vertriebsmanager.OrgE_DP__c;
			query += setting.isFiliale
					? ' AND (OwnerId = :userId OR Owner_OrgE_DP__c = :orgE )'
					: ' AND OwnerId = :userId';
		}
		return query;
	}
	
	@TestVisible
	private String getAmpelValue ( Task task ) {
		if ( !task.PriohilfeAufgabenverwaltung__r.AmpelAktiviert__c ) {
			return '';
		}
		else if ( task.Aufgabenart__c == 'Akquiseauftrag Filiale + Detail' ) {
			return getTrafficLightValue( task, 'AkquiseauftragFiliale' );
		}
		else if ( task.Aufgabenart__c == 'Akquiseauftrag DHL Paketshop + Detail' ) {
			return getTrafficLightValue( task, 'AkquiseauftragPaketshop' );
		}
		else if ( task.Aufgabenart__c == 'Akquiseauftrag Entlastung Packstation' ) {
			return getTrafficLightValue( task, 'EntlastungPackstation' );
		}
		else if ( task.Aufgabenart__c == 'Akquiseauftrag Packstation zu FNÄ' ) {
			return getTrafficLightValue( task, 'PackstationZuFNAE' );
		}
		else if ( task.Aufgabenart__c == 'Akquiseauftrag Packstation - Priorisierte Bearbeitung' ) {
			return getTrafficLightValue( task, 'PriorisierteBearbeitung' );
		}
		else if ( task.Aufgabenart__c == 'Standortaufnahme durchführen' ) {
			return getTrafficLightValue( task, 'Standortaufnahme' );
		}
		return getTrafficLightValue( task, '' );
	}
	
	@TestVisible
	private String getTrafficLightValue ( Task task, String configurationName ) {
		if ( task.Dringlichkeit__c <= ampelKonfigurationsByName.get( configurationName + 'Gruen' ).Endwert__c ) {
			return getTrafficLight( 'green' );
		}
		if ( task.Dringlichkeit__c <= ampelKonfigurationsByName.get( configurationName + 'Gelb' ).Endwert__c ) {
			return getTrafficLight( 'yellow' );
		}
		if ( task.Dringlichkeit__c <= ampelKonfigurationsByName.get( configurationName + 'Rot' ).Endwert__c ) {
			return getTrafficLight( 'red' );
		}
		return '';
	}
	
	private List<Schema.PicklistEntry> getPicklistFieldValues ( String objectName, String pickListFieldName ) {
		SObjectType objectType = Schema.getGlobalDescribe().get( objectName );
		return objectType.getDescribe()
				.fields.getMap()
				.get( pickListFieldName )
				.getDescribe().getPicklistValues();
	}
	
	private class Aufgabe {
		public Task task { get; set; }
		public String ampel { get; set; }
	}
}