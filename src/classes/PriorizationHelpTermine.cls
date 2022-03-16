/**
 *@author       Mats Böhler
 *@created      30.03.2020
 *
 *
 *@description  PriorizationHelpTermine
 *
 *
 *@changelog    30.03.2020 Mats Böhler  - Created
 *              
 * 
 */
public with sharing class PriorizationHelpTermine extends PriorizationHelpBase {
	
	@TestVisible
	private List<Termin> termine = new List<Termin>();
	private Map<String, Termin>terminByAccountIdAndDateAndVersion = new Map<String, Termin>();
	
	public String load ( PriorizationHelpSetting setting ) {
		this.setting = setting;
		loadColumnDefinitions();
		createColumns();
		load();
		return JSON.serialize( this );
	}
	
	private void load () {
		
		for ( Task task : query() ) {
			
			initialize( task );
		}
		
		for ( Termin termin : terminByAccountIdAndDateAndVersion.values() ) {
			termin.task.Typc__c = termin.task.Typc__c.removeEnd( ', ' );
		}
		termine = terminByAccountIdAndDateAndVersion.values();
	}
	
	private void initialize ( Task task ) {
		String key = String.valueOf( task.WhatId )
				+ String.valueOf( task.TerminiertZum__c )
				+ task.PriohilfeAufgabenverwaltung__r.Version__c;
		
		if ( terminByAccountIdAndDateAndVersion.containsKey( key ) ) {
			initializeExisting( task, key );
		}
		else {
			initializeNew( task, key );
		}
	}
	
	private void initializeExisting ( Task task, String key ) {
		Termin termin = terminByAccountIdAndDateAndVersion.get( key );
		if ( task.Typc__c != null ) {
			if ( termin.task.Typc__c != '' ) {
				termin.task.Typc__c = termin.task.Typc__c.contains( task.Typc__c )
						? termin.task.Typc__c
						: termin.task.Typc__c + ', ' + task.Typc__c;
			}
			else {
				termin.task.Typc__c = task.Typc__c;
			}
		}
	}
	
	private void initializeNew ( Task task, String key ) {
		Termin termin = new Termin();
		termin.task = task;
		termin.ampel = '';
		
		if ( termin.task.Typc__c == null ) {
			termin.task.Typc__c = '';
		}
		
		if ( Date.today() < task.TerminiertZum__c.addDays( -1 ) ) {
			
			termin.ampel = getTrafficLight( 'green' );
		}
		else if ( Date.today() == task.TerminiertZum__c
				|| Date.today() == task.TerminiertZum__c.addDays( -1 ) ) {
			
			termin.ampel = getTrafficLight( 'yellow' );
		}
		else if ( Date.today() > task.TerminiertZum__c ) {
			
			termin.ampel = getTrafficLight( 'red' );
		}
		else {
			//Sonarqube --> do nothing
		}
		terminByAccountIdAndDateAndVersion.put( key, termin );
	}
	
	private List<Task> query () {
		addRequiredTermineFields();
		setting.version = 'ohne Akquise';
		String version = setting.version;
		String query = 'SELECT '
				+ setting.fields
				+ ' FROM Task'
				+ ' WHERE IsClosed = FALSE AND TerminiertZum__c != NULL '
				+ 'AND PriohilfeAufgabenverwaltung__r.Version__c != NULL '
				+ 'AND PriohilfeAufgabenverwaltung__r.Version__c = :version' ;
		
		if ( setting.role == 'VM' ) {
			String userId = UserInfo.getUserId();
			query += ' AND OwnerId = :userId';
		}
		query = addNLBrief( query );
		query += ' ORDER BY ' + setting.sortBy
				+ ' ' + setting.sortDirection + ', Typc__c asc NULLS LAST';
		
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
	
	private void addRequiredTermineFields () {
		List<String> requiredFields = new List<String> {
				'PriohilfeAufgabenverwaltung__r.Dokumentationspflicht__c',
				'Id',
				'PriohilfeAufgabenverwaltung__r.Version__c'
		};
		for ( String requiredField : requiredFields ) {
			addFieldIfMissing( requiredField );
		}
	}
	
	private class Termin {
		public Task task { get; set; }
		public String ampel { get; set; }
	}
}