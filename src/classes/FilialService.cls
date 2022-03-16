/**
 *@author       Mats Böhler
 *@created      06.04.2020
 *
 *
 *@description  AccountTerminationService
 *              MYPM-92
 *              Testclasses: FilialTerminationTest,FilialCreationTest
 *
 *
 *@changelog    06.04.2020 Mats Böhler  - Created
 *              
 * 
 */
public without sharing class FilialService {
	
	private Set<Id> accountIds = new Set<Id>();
	private Map<Id, Account> accountsById = new Map<Id, Account>();
	private List<Task> tasks = new List<Task>();
	private Map<String, List<AufgabenanlageFiliale__mdt>> taskSettingsByProcessAndCriteria
			= new Map<String, List<AufgabenanlageFiliale__mdt>>();
	private List<AufgabenanlageFiliale__mdt> activeSetting = null;
	private Map<Id, Account> oldAccountMap;
	private String process = null;
	private String criteria = '';
	
	private static FilialService instance = null;
	
	public static FilialService getInstance () {
		if ( instance == null ) {
			instance = new FilialService();
			instance.loadTaskSettings();
		}
		instance.oldAccountMap = ( Map<Id, Account> ) Trigger.oldMap;
		return instance;
	}
	
	private void loadTaskSettings () {
		for ( AufgabenanlageFiliale__mdt taskSetting : [
				SELECT
						Id,
						Prozess__c,
						Kriterium__c,
						Prioritaet__c,
						Status__c,
						NurFaelligkeitsdatum__c,
						Aufgabenart__c,
						Auftraggeber__c,
						Auftragnehmer__c,
						Beschreibung__c,
						ErledigungBisZum__c,
						Datensatztyp__c,
						Typ__c
				FROM AufgabenanlageFiliale__mdt
		] ) {
			
			if ( taskSettingsByProcessAndCriteria.containsKey( taskSetting.Prozess__c + taskSetting.Kriterium__c ) ) {
				taskSettingsByProcessAndCriteria.get( taskSetting.Prozess__c + taskSetting.Kriterium__c ).add( taskSetting );
			}
			else {
				taskSettingsByProcessAndCriteria.put(
						taskSetting.Prozess__c + taskSetting.Kriterium__c,
						new List<AufgabenanlageFiliale__mdt> {
								taskSetting
						} );
			}
		}
	}
	
	public FilialService setProcess ( String process ) {
		this.process = process;
		return this;
	}
	
	public FilialService loadAccounts ( Set<Id> accountIds ) {
		this.accountIds = accountIds;
		loadAccounts();
		return this;
	}
	
	public FilialService createTasksFor ( String criteria, Set<Id> accountIds ) {
		this.criteria = criteria;
		activeSetting = taskSettingsByProcessAndCriteria.containsKey( process + criteria )
				? taskSettingsByProcessAndCriteria.get( process + criteria )
				: null;
		if ( activeSetting == null ) {
			return this;
		}
		
		if ( this.accountIds == null ) {
			loadAccounts( accountIds );
		}
		
		for ( Id accountId : accountIds ) {
			createTasks( accountId );
		}
		return this;
	}
	
	public FilialService createTasksForNewDPSFiliale ( Set<Id> accountIds ) {
		
		for ( Id accountId : accountIds ) {
			tasks.add(
					new Task(
							Status = 'Nicht begonnen',
							ActivityDate = accountsById.get( accountId ).Eroeffnungsdatum__c.addDays( -49 ),
							Aufgabenart__c = 'DP Shop Abstimmung Einrichtung & Werbemittel',
							Auftraggeber__c = 'Vertriebsmanager',
							Auftragnehmer__c = '3920/30 Aussenstelle',
							Erledigung_bis_zum__c = accountsById.get( accountId ).Eroeffnungsdatum__c.addDays( -42 ),
							RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
									.get( 'A_Aufgaben_automatische_Anlage' ).getRecordTypeId(),
							Typc__c = 'Intern',
							Type = 'Intern',
							WhatId = accountId
					)
			) ;
		}
		return this;
	}
	
	public FilialService createTasksForWerbemedienFACTS ( Set<Id> accountIds ) {
		
		for ( Id accountId : accountIds ) {
			Date eroeffnungsdatum = accountsById.get( accountId ).Eroeffnungsdatum__c;
			String eroeffnungsdatumFormatted = eroeffnungsdatum == null
					? null
					: eroeffnungsdatum.format();
			tasks.add(
					new Task(
							Status = 'Nicht begonnen',
							ActivityDate = accountsById.get( accountId ).Eroeffnungsdatum__c,
							Aufgabenart__c = 'Werbemedienpflege in FACTS',
							Auftraggeber__c = '1T1 Field Sales',
							Auftragnehmer__c = 'Vertriebsmanager',
							Erledigung_bis_zum__c = eroeffnungsdatum == null
									? null
									: eroeffnungsdatum.addDays( 2 ),
							RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
									.get( 'A_Aufgaben_automatische_Anlage' ).getRecordTypeId(),
							Typc__c = 'Intern',
							Type = 'Intern',
							WhatId = accountId,
							Description = 'Eröffnungsdatum/Umzugsdatum: '
									+ eroeffnungsdatumFormatted
									+ ': Überprüfung und ggf. Korrektur der in Facts hinterlegten Werbemedien. ' +
									'Bei DP Shop Filialen initiale Pflege der Werbemedien in Facts.'
					)
			) ;
		}
		return this;
	}
	
	public FilialService createTasksForAreYouHappyCall ( Set<Id> accountIds ) {
		
		for ( Id accountId : accountIds ) {
			Date eroeffnungsdatum = accountsById.get( accountId ).Eroeffnungsdatum__c;
			String eroeffnungsdatumFormatted = eroeffnungsdatum == null
					? null
					: eroeffnungsdatum.format();
			tasks.add(
					new Task(
							Status = 'Nicht begonnen',
							ActivityDate = eroeffnungsdatum == null
									? null
									: eroeffnungsdatum.addDays( 21 ),
							Aufgabenart__c = 'DHL Paketshop AreYouHappy-Call',
							Auftraggeber__c = '5640 Team DHL Paketshop',
							Auftragnehmer__c = 'interServ Team DHL Paketshop',
							Erledigung_bis_zum__c = eroeffnungsdatum == null
									? null
									: eroeffnungsdatum.addDays( 28 ),
							RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
									.get( 'A_Aufgaben_automatische_Anlage' ).getRecordTypeId(),
							Typc__c = 'Telefonat (Outbound)',
							WhatId = accountId,
							Priority = 'Hoch',
							Description = 'EÖ: '
									+ eroeffnungsdatumFormatted
									+ '; Bitte kontaktieren Sie den neuen Paketshop erstmalig im Rahmen unserer ' +
									'AYH-Calls und führen diesen gem. Gesprächsleitfaden durch.'
					)
			) ;
		}
		return this;
	}
	
	private void createTasks ( Id accountId ) {
		for ( AufgabenanlageFiliale__mdt taskDefinition : activeSetting ) {
			tasks.add(
					new Task(
							Priority = taskDefinition.Prioritaet__c,
							Status = taskDefinition.Status__c,
							ActivityDate = getActivityDate( accountId, taskDefinition ),
							Aufgabenart__c = taskDefinition.Aufgabenart__c,
							Auftraggeber__c = taskDefinition.Auftraggeber__c,
							Auftragnehmer__c = taskDefinition.Auftragnehmer__c == '3920/30 Außenstelle'
									? taskDefinition.Auftragnehmer__c.replace( 'ß', 'ss' )
									: taskDefinition.Auftragnehmer__c,
							Description = getDescription( accountId, taskDefinition ),
							Erledigung_bis_zum__c = getDueDate( accountId, taskDefinition ),
							RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
									.get( taskDefinition.Datensatztyp__c ).getRecordTypeId(),
							Typc__c = taskDefinition.Typ__c,
							Type = taskDefinition.Typ__c,
							WhatId = taskDefinition.Prozess__c == 'Neuanlage'
									&& taskDefinition.Kriterium__c == '95 -> 84 Formatänderung'
									&& taskDefinition.Aufgabenart__c == 'Bargeldentsorgung beauftragen'
									? accountsById.get( accountId ).Vorgaengerfiliale__c
									: accountsById.get( accountId ).Id
					)
			) ;
		}
	}
	
	private Date getActivityDate ( Id accountId, AufgabenanlageFiliale__mdt taskDefinition ) {
		Date activityDate = taskDefinition.NurFaelligkeitsdatum__c.contains( '{!TODAY}' )
				? Date.today()
				: ( Date ) accountsById.get( accountId ).get(
						taskDefinition.NurFaelligkeitsdatum__c.substringAfter( '{!Account.' ).substringBefore( '}' )
				);
		activityDate = activityDate == null
				? null
				: activityDate.addDays( Integer.valueOf( taskDefinition.NurFaelligkeitsdatum__c.deleteWhitespace().substringAfter( '}' ) ) );
		if ( taskDefinition.Kriterium__c == '95 -> 79,76 Formatänderung'
				&& taskDefinition.Aufgabenart__c == 'Vorbereitung Up-/Downgrade Filialeinrichtung (Formatwechsel)' ) {
			activityDate = activityDate < Date.today() ? activityDate : Date.today();
		}
		if ( taskDefinition.Kriterium__c == '79/76 -> 95 Formatänderung'
				&& taskDefinition.Aufgabenart__c == 'Vorbereitung Up-/Downgrade Filialeinrichtung (Formatwechsel)' ) {
			activityDate = activityDate < Date.today() ? activityDate : Date.today();
		}
		if ( taskDefinition.Kriterium__c == '84 -> 79/76 Formatänderung'
				&& taskDefinition.Aufgabenart__c == 'Vorbereitung Up-/Downgrade Filialeinrichtung (Formatwechsel)' ) {
			activityDate = activityDate < Date.today() ? activityDate : Date.today();
		}
		return activityDate;
	}
	
	private Date getDueDate ( Id accountId, AufgabenanlageFiliale__mdt taskDefinition ) {
		Date activityDate = taskDefinition.ErledigungBisZum__c.contains( '{!TODAY}' )
				? Date.today()
				: ( Date ) accountsById.get( accountId ).get(
						taskDefinition.ErledigungBisZum__c.substringAfter( '{!Account.' ).substringBefore( '}' )
				);
		activityDate = activityDate == null
				? null
				: activityDate.addDays( Integer.valueOf( taskDefinition.ErledigungBisZum__c.deleteWhitespace().substringAfter( '}' ) ) );
		if ( taskDefinition.Kriterium__c == '95 -> 84 Formatänderung'
				&& taskDefinition.Aufgabenart__c == 'Vorbereitung Up-/Downgrade Filialeinrichtung (Formatwechsel)' ) {
			activityDate = activityDate < Date.today() ? activityDate : Date.today();
		}
		if ( taskDefinition.Kriterium__c == '84 -> 95 Formatänderung'
				&& taskDefinition.Aufgabenart__c == 'Vorbereitung Up-/Downgrade Filialeinrichtung (Formatwechsel)' ) {
			activityDate = activityDate < Date.today() ? activityDate : Date.today();
		}
		if ( taskDefinition.Kriterium__c == '79/76 -> 84 Formatänderung'
				&& taskDefinition.Aufgabenart__c == 'Vorbereitung Up-/Downgrade Filialeinrichtung (Formatwechsel)' ) {
			activityDate = activityDate < Date.today() ? activityDate : Date.today();
		}
		return activityDate;
	}
	
	private String getDescription ( Id accountId, AufgabenanlageFiliale__mdt taskDefinition ) {
		String description = taskDefinition.Beschreibung__c;
		description = description.contains( '{!OldAccount.Schliessung_zum__c}' )
				? oldAccountMap.get( accountId ).get(
						description.substringAfter( '{!OldAccount.' )
								.substringBefore( '}' ) ) == null
						? description
						: description.replace( '{!OldAccount.Schliessung_zum__c}',
								String.valueOf(
										oldAccountMap.get( accountId ).get(
												description.substringAfter( '{!OldAccount.' )
														.substringBefore( '}' ) ) )
										.remove( ' 00:00:00' )
						)
				: description;
		description = description.contains( '{!Account.Schliessung_zum__c}' )
				? description.replace( '{!Account.Schliessung_zum__c}',
						String.valueOf(
								accountsById.get( accountId ).get(
										description.substringAfter( '{!Account.' )
												.substringBefore( '}' ) ) )
								.remove( ' 00:00:00' )
				)
				: description;
		description = description.contains( '{!Account.Eroeffnungsdatum__c}' )
				? description.replace( '{!Account.Eroeffnungsdatum__c}',
						String.valueOf(
								accountsById.get( accountId ).get(
										description.substringAfter( '{!Account.' )
												.substringBefore( '}' ) ) )
								.remove( ' 00:00:00' )
				)
				: description;
		
		description = description.contains( '{!Account.WaWi_Nummer__c}' )
				&& accountsById.get( accountId ).WaWi_Nummer__c != null
				? description.replace( '{!Account.WaWi_Nummer__c}',
						( String )
								accountsById.get( accountId ).get(
										description.substringAfter( '{!Account.' )
												.substringBefore( '}' ) )
				)
				: description;
		description = description.contains( '{!Account.EOE_Datum_Partnerjubilaeum__c}' )
				&& accountsById.get( accountId ).EOE_Datum_Partnerjubilaeum__c != null
				? description.replace( '{!Account.EOE_Datum_Partnerjubilaeum__c}', String.valueOf( ( Date )
						accountsById.get( accountId ).get(
								description.substringAfter( '{!Account.' )
										.substringBefore( '}' ) ) )
				
				)
				: description;
		return description;
	}
	
	public FilialService insertTasks () {
		if ( !tasks.isEmpty()
				&& !System.isQueueable()
				&& !System.isFuture()
				&& !System.isBatch()
				&& isEnqueueable()
				&& TriggerService.processAsynchronously( 'Post_AccountTrigger' ) ) {
			System.enqueueJob( new TaskUpsertQueueable( process + ' -> ' + criteria, tasks ) );
		}
		else {
			upsert tasks;
		}
		tasks.clear();
		return this;
	}
	
	private void loadAccounts () {
		accountsById = new Map<Id, Account>( [
				SELECT
						Id,
						Schliessung_zum__c,
						Eroeffnungsdatum__c,
						WaWi_Nummer__c,
						Vorgaengerfiliale__c,
						EOE_Datum_Partnerjubilaeum__c
				FROM Account
				WHERE Id IN :accountIds
		] );
	}
	
	private Boolean isEnqueueable () {
		return Limits.getLimitQueueableJobs() - Limits.getQueueableJobs() > 0;
	}
}