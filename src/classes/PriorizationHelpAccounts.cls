/**
 *@author       Mats Böhler
 *@created      30.03.2020
 *
 *
 *@description  PriorizationHelpAccount
 *
 *
 *@changelog    30.03.2020 Mats Böhler  - Created
 *              
 * 
 */
public with sharing class PriorizationHelpAccounts extends PriorizationHelpBase {
	
	@TestVisible
	private List<Filiale> filialen = new List<Filiale>();
	private Map<Id, List<Task>> tasksByAccountId = new Map<Id, List<Task>>();
	@TestVisible
	private List<SObject> data = new List<SObject>();
	
	public String load ( PriorizationHelpSetting setting ) {
		this.setting = setting;
		loadColumnDefinitions();
		createColumns();
		load();
		rank();
		return JSON.serialize( this );
	}
	
	private void load () {
		String version = 'ohne Akquise';
		String type = 'Account';
		String query = 'SELECT Id, Typc__c, KennzifferPrioritaet__c, Account.Id, Ampel__c' +
				' FROM Task' +
				' WHERE IsClosed = FALSE' +
				' AND TerminiertZum__c = NULL' +
				' AND PriohilfeAufgabenverwaltung__r.Version__c = :version' +
				' AND What.Type = :type' +
				' AND KennzifferPrioritaet__c != NULL';
		
		if ( setting.role == 'VM' ) {
			String userId = UserInfo.getUserId();
			query += ' AND OwnerId = :userId';
		}
		
		query = addNLBrief( query );
		
		for ( Task task : Database.query( query ) ) {
			
			if ( tasksByAccountId.containsKey( task.Account.Id ) ) {
				tasksByAccountId.get( task.Account.Id ).add( task );
			}
			else {
				tasksByAccountId.put( task.Account.Id, new List<Task> {
						task
				} );
			}
		}
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
	
	private void rank () {
		Set<Id> accountIds = tasksByAccountId.keySet();
		Map<Id, String> ampelFilialeByAccountId = setAmpelFilialeByAccountId();
		setting.fields = setting.fields.remove( ',Ampel__c' );
		
		if ( !setting.fields.contains( 'OwnerId' ) ) {
			setting.fields += ',OwnerId';
		}
		String query = 'SELECT ' + setting.fields + ' FROM Account WHERE Id IN :accountIds';
		
		for ( Account account : Database.query( query ) ) {
			
			Filiale filiale = new Filiale();
			filiale.account = account;
			filiale.tasks = tasksByAccountId.get( account.Id );
			filiale.highestPriority = -1000;
			filiale.numberOfCalls = 0;
			filiale.numberOfTasks = tasksByAccountId.get( account.Id ).size();
			filiale.ampel = ampelFilialeByAccountId.get( account.Id );
			
			for ( Task task : tasksByAccountId.get( account.Id ) ) {
				filiale.highestPriority = task.KennzifferPrioritaet__c > filiale.highestPriority
						? task.KennzifferPrioritaet__c
						: filiale.highestPriority;
				
				filiale.numberOfCalls = task.Typc__c == 'Besuch'
						? ++filiale.numberOfCalls
						: filiale.numberOfCalls;
			}
			
			filialen.add( filiale );
		}
		
		filialen.sort();
		Integer ranking = 0;
		List<Account> accounts = new List<Account>();
		for ( Filiale filiale : filialen ) {
			filiale.account.Nummerierung__c = ++ranking;
			accounts.add( filiale.account );
		}
		
		data = accounts;
	}
	
	private Map<Id, String> setAmpelFilialeByAccountId () {
		Map<Id, String> ampelFilialeByAccountId = new Map<Id, String>();
		for ( Id accountId : tasksByAccountId.keySet() ) {
			String ampel = getTrafficLight( 'green' );
			Boolean hasYellow = false;
			Boolean hasRed = false;
			for ( Task task : tasksByAccountId.get( accountId ) ) {
				hasYellow = containsValue( task, 'light_yellow' );
				hasRed = containsValue( task, 'light_red' );
			}
			if ( hasYellow ) {
				ampel = getTrafficLight( 'yellow' );
			}
			if ( hasRed ) {
				ampel = getTrafficLight( 'red' );
			}
			ampelFilialeByAccountId.put( accountId, ampel );
		}
		return ampelFilialeByAccountId;
	}
	
	private Boolean containsValue ( Task task, String value ) {
		return task.Ampel__c != null && task.Ampel__c.contains( value );
	}
	
	private class Filiale implements Comparable {
		
		public Account account { get; set; }
		public List<Task> tasks { get; set; }
		public Decimal highestPriority { get; set; }
		public Decimal numberOfCalls { get; set; }
		public Decimal numberOfTasks {
			get {
				return tasks.size();
			}
			set;
		}
		public String ampel { get; set; }
		
		public Integer compareTo ( Object obj ) {
			Filiale filiale = ( Filiale ) ( obj );
			if ( this.highestPriority > filiale.highestPriority ) {
				return -1;
			}
			if ( this.highestPriority == filiale.highestPriority ) {
				if ( this.numberOfCalls > filiale.numberOfCalls ) {
					return -1;
				}
				if ( this.numberOfCalls == filiale.numberOfCalls ) {
					if ( this.numberOfTasks > filiale.numberOfTasks ) {
						return -1;
					}
					if ( this.numberOfTasks == filiale.numberOfTasks ) {
						return this.account.Name.compareTo( filiale.account.Name );
					}
				}
			}
			return 1;
		}
	}
}