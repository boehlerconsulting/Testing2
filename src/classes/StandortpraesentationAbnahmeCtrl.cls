/**
 *@author       Mats Böhler
 *@created      07.10.2020
 *
 *
 *@description  StandortpraesentationAbnahmeCtrl
 *
 *
 *@changelog    07.10.2020 Mats Böhler  - Created
 *              
 * 
 */
public without sharing class StandortpraesentationAbnahmeCtrl {
	
	private String recordId = '';
	private Boolean isAllowed = false;
	private Boolean alreadyApproved = false;
	private Boolean hasPermission = false;
	@TestVisible
	private Lead lead = new Lead();
	
	@AuraEnabled
	public static String loadData ( String recordId ) {
		StandortpraesentationAbnahmeCtrl instance = new StandortpraesentationAbnahmeCtrl();
		try {
			instance.recordId = recordId;
			instance.loadLead();
			instance.setIsAllowed();
			instance.setAlreadyApproved();
			instance.hasPermission = FeatureManagement.checkPermission( 'FreigabeStandortdokumentation' );
		}
		catch ( Exception e ) {
			throw new AuraHandledException( e.getMessage() );
		}
		return JSON.serialize( instance );
	}
	
	@AuraEnabled
	public static void saveData ( String recordId, String freigabe, String reasons ) {
		
		try {
			if ( freigabe == 'Ja' ) {
				update new Lead (
						Id = recordId,
						DokumentationDurchRTFreigebenDatum__c = Date.today()
				);
			}
			else if ( freigabe == 'Nachbesserung nach Abnahme' ) {
				
				addTask(
						recordId,
						reasons,
						'Vertriebskoordinator VGL',
						Date.today().addDays( 7 )
				);
			}
			else if ( freigabe == 'Nein, Nachbesserung erforderlich' ) {
				
				addTask(
						recordId,
						'Bitte passen Sie die Standortdokumentation an. Gründe: ' + reasons,
						'Inhaber des Leads',
						Date.today().addDays( 7 )
				);
			}
			else if ( freigabe == 'Nein, neue Standortaufnahme erforderlich' ) {
				
				addTask(
						recordId,
						'Bitte führen Sie eine neue Standortaufnahme durch. Gründe: ' + reasons,
						'Inhaber des Leads',
						Date.today().addDays( 14 )
				);
			}
			else{
				//Sonarqube --> do nothing
			}
		}
		catch ( Exception e ) {
			throw new AuraHandledException( e.getMessage() );
		}
	}
	
	private static void addTask ( Id leadId, String description, String auftragnehmer, Date erledigungBisZum ) {
		update new Lead (
				Id = leadId,
				NachbesserungAngefordert__c = true,
				DokumentationDurchRTFreigebenDatum__c = null
		);
		Lead existingLead = [
				SELECT
						Id,
						Filialnetzaenderung__c
				FROM Lead
				WHERE Id = :leadId
				LIMIT 1
		];
		insert new Task(
				Description = description,
				Aufgabenart__c = 'Standortdokumentation nachbessern',
				Auftraggeber__c = 'Regionale Vertriebsunterstützung',
				Auftragnehmer__c = auftragnehmer,
				ActivityDate = Date.today(),
				Erledigung_bis_zum__c = erledigungBisZum,
				Priority = 'Mittel',
				Status = 'Nicht begonnen',
				WhoId = leadId,
				RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
						.get( 'AkquiseauftragPackstation' ).getRecordTypeId(),
				Typc__c = 'Intern',
				Filialnetzaenderung__c = existingLead.Filialnetzaenderung__c
		);
	}
	
	private void loadLead () {
		lead = [
				SELECT
						Id,
						DokumentationErstelltDatum__c,
						DokumentationDurchRTFreigebenDatum__c
				FROM Lead
				WHERE Id = :recordId
		];
	}
	
	private void setIsAllowed () {
		isAllowed = lead.DokumentationErstelltDatum__c != null;
	}
	
	private void setAlreadyApproved () {
		alreadyApproved = lead.DokumentationDurchRTFreigebenDatum__c != null;
	}
}