/**
 *@author       Mats Böhler
 *@created      13.10.2021
 *
 *
 *@description  TaskMaker
 *
 *
 *@changelog    13.10.2021 Mats Böhler  - Created
 *              
 * 
 */
public without sharing class TaskMaker {
	
	private static final Id AKQUISE_RT = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
			.get( 'Akquiseauftrag' ).getRecordTypeId();
	
	private Map<Id, Filialnetzaenderung__c> filialnetzaenderungsById = new Map<Id, Filialnetzaenderung__c>();
	
	public void copyValuesToFNAE ( Task task ) {
		if ( task.Filialnetzaenderung__c == null ) {
			return;
		}
		Filialnetzaenderung__c filialnetzaenderung =
				filialnetzaenderungsById.containsKey( task.Filialnetzaenderung__c )
						? filialnetzaenderungsById.get( task.Filialnetzaenderung__c )
						: new Filialnetzaenderung__c();
		if ( isDefault( task ) ) {
			filialnetzaenderung.Id = task.Filialnetzaenderung__c;
			filialnetzaenderung.Akquise_beauftragt_am__c = task.CreatedDate.date();
			if ( task.IsClosed && task.Aufgabenart__c != 'Akquiseauftrag Poststation' ) {
				filialnetzaenderung.Akquise_erledigt_am__c = task.Erledigt_am__c;
			}
			filialnetzaenderung.Status_Akquise__c = task.Status;
			filialnetzaenderung.Status_Anmerkung_Akquise__c = task.Status_Anmerkung__c;
			filialnetzaenderung.moegliche_Paketausgabemenge__c = task.Teilweise_Ausgabeverlagerung_Menge__c;
			filialnetzaenderungsById.put( task.Filialnetzaenderung__c,
					filialnetzaenderung
			);
		}
		else if ( isImmo( task ) ) {
			filialnetzaenderung.Id = task.Filialnetzaenderung__c;
			filialnetzaenderung.Immosuche_Sachstand__c = task.Erledigungsvermerk__c;
			filialnetzaenderung.Immosuche_Status_Anmerkung__c = task.Status_Anmerkung__c;
			filialnetzaenderung.Immosuche_Status__c = task.Status;
			filialnetzaenderung.Immosuche_beauftragt_am__c = task.CreatedDate.date();
			filialnetzaenderung.Immosuche_erledigt_am__c = task.Erledigt_am__c;
			filialnetzaenderungsById.put( task.Filialnetzaenderung__c,
					filialnetzaenderung
			);
		}
		else if ( task.Aufgabenart__c == 'Vorbereitung Filialumzug'
				&& TaskEvaluator.isChanged( task, 'Status' ) ) {
			filialnetzaenderung.Id = task.Filialnetzaenderung__c;
			filialnetzaenderung.Akquise_beauftragt_am__c = task.CreatedDate.date();
			filialnetzaenderung.Akquise_erledigt_am__c = task.Erledigt_am__c;
			filialnetzaenderung.Status_Akquise__c = task.Status;
			filialnetzaenderungsById.put( task.Filialnetzaenderung__c,
					filialnetzaenderung
			);
		}
		else if ( isPersonal( task ) ) {
			filialnetzaenderung.Id = task.Filialnetzaenderung__c;
			filialnetzaenderung.Personalsuche_Sachstand__c = task.Erledigungsvermerk__c;
			filialnetzaenderung.Personalsuche_Status_Anmerkung__c = task.Status_Anmerkung__c;
			filialnetzaenderung.Personalsuche_Status__c = task.Status;
			filialnetzaenderung.Personalsuche_beauftragt_am__c = task.CreatedDate.date();
			filialnetzaenderung.Personalsuche_erledigt_am__c = task.Erledigt_am__c;
			filialnetzaenderungsById.put( task.Filialnetzaenderung__c,
					filialnetzaenderung
			);
		}
		else if ( task.Aufgabenart__c == 'Vergütungsberechnung' ) {
			filialnetzaenderung.Id = task.Filialnetzaenderung__c;
			filialnetzaenderung.Referenz_Id_VerA__c = task.Referenz_ID_Fachseitensystem__c;
			filialnetzaenderung.Verguetungsberechnung_gueltig_bis__c = task.Erledigung_bis_zum__c;
			filialnetzaenderung.Verguetungsberechnung_vom__c = task.CreatedDate.date();
			filialnetzaenderungsById.put( task.Filialnetzaenderung__c,
					filialnetzaenderung
			);
		}
		else if ( task.Aufgabenart__c == 'DHL Paketshop Kündigungsrückgewinnung'
				&& task.Status == 'Erfolgreich' ) {
			filialnetzaenderung.Id = task.Filialnetzaenderung__c;
			filialnetzaenderung.Grund__c = 'Kündigung zurückgezogen';
			filialnetzaenderungsById.put( task.Filialnetzaenderung__c,
					filialnetzaenderung
			);
		}
		else {
			//Sonarqube --> do nothing
		}
	}
	
	public void updateFnaes () {
		update filialnetzaenderungsById.values();
	}
	
	private Boolean isDefault ( Task task ) {
		return ( task.RecordTypeId == AKQUISE_RT
				&& (
				TaskEvaluator.isChanged( task, 'Status' )
						|| TaskEvaluator.isChanged( task, 'Status_Anmerkung__c' ) ) )
				|| (
				task.RecordTypeId == AKQUISE_RT
						&& TaskEvaluator.isChanged( task, 'Filialnetzaenderung__c' ) );
	}
	
	private Boolean isImmo ( Task task ) {
		return task.Aufgabenart__c == 'DP Shop Immobiliensuche'
				&& (
				TaskEvaluator.isChanged( task, 'Status' )
						|| TaskEvaluator.isChanged( task, 'Erledigungsvermerk__c' )
						|| TaskEvaluator.isChanged( task, 'Status_Anmerkung__c' ) );
	}
	
	private Boolean isPersonal ( Task task ) {
		return task.Aufgabenart__c == 'DP Shop Personalgewinnung'
				&& (
				TaskEvaluator.isChanged( task, 'Status' )
						|| TaskEvaluator.isChanged( task, 'Erledigungsvermerk__c' )
						|| TaskEvaluator.isChanged( task, 'Status_Anmerkung__c' ) );
	}
}