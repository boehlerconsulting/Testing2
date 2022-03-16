/**
 *@author       Mats Böhler
 *@created      10.02.2020
 *
 *
 *@description  HW_PriorizationHelpService
 *
 *
 *@changelog    10.02.2020 Mats Böhler  - Created
 *              
 * 
 */
public without sharing class HW_PriorizationHelpService {
	
	private List<Task> tasks;
	private Map<Id, PriohilfeAufgabenverwaltung__c> priohilfeAufgabenverwaltungsById = new Map<Id, PriohilfeAufgabenverwaltung__c>();
	
	public void initialize ( Set<Id> taskIds ) {
		if ( taskIds.isEmpty() ) {
			return;
		}
		loadTasks( taskIds );
		Map<String, PriohilfeVerwaltung__c> priohilfeVerwaltungsByTaskType = loadTaskTypeRecords();
		loadPriohilfeAufgabenverwaltungs();
		for ( Task task : tasks ) {
			if ( String.isNotBlank( task.Aufgabenart__c ) && priohilfeVerwaltungsByTaskType.containsKey( task.Aufgabenart__c ) ) {
				PriohilfeVerwaltung__c priohilfeVerwaltung = priohilfeVerwaltungsByTaskType.get( task.Aufgabenart__c );
				if ( task.PriohilfeAufgabenverwaltung__c == null ) {
					priohilfeAufgabenverwaltungsById.put( task.Id,
							new PriohilfeAufgabenverwaltung__c(
									KennzifferWichtigkeit__c = priohilfeVerwaltung.KennzifferWichtigkeit__c,
									Aufgabenkategorie__c = priohilfeVerwaltung.Aufgabenkategorie__c,
									Bezugsbene__c = priohilfeVerwaltung.Bezugsbene__c,
									Steigung__c = priohilfeVerwaltung.Steigung__c,
									MinMaxWert__c = priohilfeVerwaltung.MinMaxWert__c,
									Startzeitpunkt__c = priohilfeVerwaltung.Startzeitpunkt__c,
									Schlagworte__c = priohilfeVerwaltung.Schlagworte__c,
									AmpelAktiviert__c = priohilfeVerwaltung.AmpelAktiviert__c,
									Dokumentationspflicht__c = priohilfeVerwaltung.Dokumentationspflicht__c,
									Version__c = priohilfeVerwaltung.Version__c
							)
					);
				}
				else if ( priohilfeAufgabenverwaltungsById.containsKey( task.PriohilfeAufgabenverwaltung__c ) ) {
					PriohilfeAufgabenverwaltung__c priohilfeAufgabenverwaltung = priohilfeAufgabenverwaltungsById.get( task.PriohilfeAufgabenverwaltung__c );
					priohilfeAufgabenverwaltung.KennzifferWichtigkeit__c = priohilfeVerwaltung.KennzifferWichtigkeit__c;
					priohilfeAufgabenverwaltung.Aufgabenkategorie__c = priohilfeVerwaltung.Aufgabenkategorie__c;
					priohilfeAufgabenverwaltung.Bezugsbene__c = priohilfeVerwaltung.Bezugsbene__c;
					priohilfeAufgabenverwaltung.Steigung__c = priohilfeVerwaltung.Steigung__c;
					priohilfeAufgabenverwaltung.MinMaxWert__c = priohilfeVerwaltung.MinMaxWert__c;
					priohilfeAufgabenverwaltung.Startzeitpunkt__c = priohilfeVerwaltung.Startzeitpunkt__c;
					priohilfeAufgabenverwaltung.Schlagworte__c = priohilfeVerwaltung.Schlagworte__c;
					priohilfeAufgabenverwaltung.AmpelAktiviert__c = priohilfeVerwaltung.AmpelAktiviert__c;
					priohilfeAufgabenverwaltung.Dokumentationspflicht__c = priohilfeVerwaltung.Dokumentationspflicht__c;
					priohilfeAufgabenverwaltung.Version__c = priohilfeVerwaltung.Version__c;
				}
				else{
					//Sonarqube --> do nothing
				}
			}
		}
		upsert priohilfeAufgabenverwaltungsById.values();
		for ( Task task : tasks ) {
			if ( priohilfeAufgabenverwaltungsById.containsKey( task.Id ) ) {
				
				task.PriohilfeAufgabenverwaltung__c = priohilfeAufgabenverwaltungsById.get( task.Id ).Id;
			}
			task.initialisierePriorisierungshilfe__c = false;
		}
		updateTasks();
	}
	
	private void updateTasks () {
		TriggerHandler.bypass( 'HW_TaskTriggerHandler' );
		List<Database.SaveResult> saveResults = Database.update( tasks, false );
		TriggerHandler.clearBypass( 'HW_TaskTriggerHandler' );
		String errors = '';
		for ( Database.SaveResult saveResult : saveResults ) {
			if ( !saveResult.isSuccess() ) {
				for ( Database.Error err : saveResult.getErrors() ) {
					errors += err.getStatusCode() + ': ' + err.getMessage() + ' | ';
				}
			}
		}
		if ( String.isNotEmpty( errors ) ) {
			throw new HW_PriorizationHelpServiceException( errors );
		}
	}
	
	private void loadPriohilfeAufgabenverwaltungs () {
		Set<Id> priohilfeAufgabenverwaltungIds = new Set<Id>();
		for ( Task task : tasks ) {
			priohilfeAufgabenverwaltungIds.add( task.PriohilfeAufgabenverwaltung__c );
		}
		priohilfeAufgabenverwaltungIds.remove( null );
		priohilfeAufgabenverwaltungsById = new Map<Id, PriohilfeAufgabenverwaltung__c>( [
				SELECT
						Id
				FROM PriohilfeAufgabenverwaltung__c
				WHERE Id IN:priohilfeAufgabenverwaltungIds
		] );
	}
	
	private void loadTasks ( Set<Id> taskIds ) {
		tasks = [
				SELECT
						Id,
						Aufgabenart__c,
						PriohilfeAufgabenverwaltung__c
				FROM Task
				WHERE Id IN :taskIds
		];
	}
	
	private Map<String, PriohilfeVerwaltung__c> loadTaskTypeRecords () {
		Set<String> taskTypes = new Set<String>();
		for ( Task task : tasks ) {
			taskTypes.add( task.Aufgabenart__c );
		}
		taskTypes.remove( null );
		Map<String, PriohilfeVerwaltung__c> priohilfeVerwaltungsByTaskType = new Map<String, PriohilfeVerwaltung__c>();
		for ( PriohilfeVerwaltung__c priohilfeVerwaltung : [
				SELECT
						Id,
						Aufgabenart__c,
						KennzifferWichtigkeit__c,
						Aufgabenkategorie__c,
						Bezugsbene__c,
						Steigung__c,
						MinMaxWert__c,
						Startzeitpunkt__c,
						Schlagworte__c,
						AmpelAktiviert__c,
						Dokumentationspflicht__c,
						Version__c
				FROM PriohilfeVerwaltung__c
				WHERE Aufgabenart__c IN :taskTypes
		] ) {
			
			priohilfeVerwaltungsByTaskType.put( priohilfeVerwaltung.Aufgabenart__c, priohilfeVerwaltung );
		}
		return priohilfeVerwaltungsByTaskType;
	}
	
	public class HW_PriorizationHelpServiceException extends Exception {
	}
}