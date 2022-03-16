/**
 *@author       Mats Böhler
 *@created      13.10.2021
 *
 *
 *@description  TaskDescription
 *
 *
 *@changelog    13.10.2021 Mats Böhler  - Created
 *              
 * 
 */
public without sharing class TaskDefiner {
	
	private Map<String, AufgabenStandardbeschreibungen__mdt> standardDescriptionByTaskType
			= new Map<String, AufgabenStandardbeschreibungen__mdt>();
	private Map<Id, Account> accountsById = new Map<Id, Account>();
	
	public TaskDefiner ( Map<String, AufgabenStandardbeschreibungen__mdt> standardDescriptionByTaskType, Map<Id, Account> accountsById ) {
		this.standardDescriptionByTaskType = standardDescriptionByTaskType;
		this.accountsById = accountsById;
	}
	
	public void setDescription ( Task task ) {
		String existingDescription = returnEmptyIfNull( task.Description );
		if ( isDefault( task ) ) {
			task.Description = existingDescription + '\r\n' + '\r\n' +
					+'Standardaufgabenbeschreibung:' + '\r\n'
					+ standardDescriptionByTaskType.get( task.Aufgabenart__c ).Standardbeschreibung__c;
		}
		else if ( isKapa( task ) ) {
			
			Account account = accountsById.get( task.WhatId );
			task.Description = existingDescription + '\r\n' + '\r\n' +
					+'Standardaufgabenbeschreibung:' + '\r\n'
					+ String.format( 'Aktuell Ausgabe benachrichtigter Pakete: {0}\n ' +
					'Aktuell hinterlegte Kapazität Paketannahme: {1}\n ' +
					'Aktuell hinterlegte Kapazität Paketausgabe (ben. Sendungen): {2}\n ' +
					'Wenn sich die Kapazitäten nicht geändert haben, kann die Aufgabe ohne Bearbeitung des ' +
					'Aufgabendetails und ohne Angaben erledigt werden!\n ' +
					'Gesprächsleitfaden: https://mypm.my.salesforce.com/sfc/#version?selectedDocumentId=0691p000008WSsM',
					new List<String> {
							account.Paketausgabe__c ? 'JA' : 'NEIN',
							account.Kapazitaet_Paketannahme__c,
							account.Kapazitaet_Paketausgabe__c
					} );
		}
		else if ( Trigger.isInsert
				&& task.Aufgabenart__c == 'Nachfass: Kontakt nach (angezeigter/vermuteter) Filialschließung + Detail'
				&& String.isBlank( task.Description ) ) {
			
			setNachfass( task );
		}
		else if ( Trigger.isInsert
				&& task.Aufgabenart__c == 'Kontaktaufnahme aufgrund Coronavirus + Detail'
				&& String.isBlank( task.Description ) ) {
			
			task.Description = existingDescription + '\r\n'
					+ 'Standardaufgabenbeschreibung:' + '\r\n'
					+ 'Aufgrund der aktuellen Lage wurde entschieden, alle Partner und Paketshops via ' +
					'Outboundcall anzurufen. Bitte in diesem Call den Partner auf seine Rechte und ' +
					'Pflichten hinweisen, den Partner beruhigen und zur weiteren Öffnung motivieren. ' +
					'Wenn Öffnungszeiten geändert werden oder Filialen schließen bitte den VP auf die ' +
					'entsprechenden Prozesse hinweisen (HDF, Partnerportal).';
		}
		else {
			//Sonarqube --> do nothing
		}
	}
	
	private void setNachfass ( Task task ) {
		String existingDescription = returnEmptyIfNull( task.Description );
		if ( task.Auftraggeber__c == '1T1 Field Sales'
				|| task.Auftraggeber__c == 'Vertriebsmanager'
				|| task.Auftraggeber__c == 'Vertriebskoordinator'
				|| task.Auftraggeber__c == 'Vertriebsleiter' ) {
			
			task.Description = existingDescription + '\r\n' + '\r\n' +
					+'Standardaufgabenbeschreibung:' + '\r\n'
					+ 'Die ZORA-Daten lassen eine temporäre Filialschließung vermuten. ' +
					'Bitte Kontakt mit dem Partner aufnehmen und die Sachlage klären. Sollte die Filiale/der ' +
					'Paketshop tatsächlich geschlossen sein bitte zur Wiedereröffnung bewegen.';
		}
		else if ( task.Auftraggeber__c != '1T1 Field Sales'
				&& task.Auftraggeber__c != 'Vertriebsmanager'
				&& task.Auftraggeber__c != 'Vertriebskoordinator'
				&& task.Auftraggeber__c != 'Vertriebsleiter'
				&& task.Filialart_OZ__c == 'DHL-Paketshop/82' ) {
			
			task.Description = existingDescription + '\r\n' + '\r\n' +
					+'Standardaufgabenbeschreibung:' + '\r\n'
					+ 'Der Paketshop hat eine Schließung angezeigt (HDF). Bitte mit dem Partner Kontakt ' +
					'aufnehmen und zur Wiedereröffnung bewegen. Bleibt der Paketshop geöffnet, im Feld ' +
					'Status-Anmerkung "Maßnahme erfolgreich umgesetzt" auswählen. Evtl. vorübergehend ' +
					'geänderte Öffnungszeiten sind beim HDF telefonisch anzuzeigen.';
		}
		else if ( task.Auftraggeber__c != '1T1 Field Sales'
				&& task.Auftraggeber__c != 'Vertriebsmanager'
				&& task.Auftraggeber__c != 'Vertriebskoordinator'
				&& task.Auftraggeber__c != 'Vertriebsleiter'
				&& task.Filialart_OZ__c != 'DHL-Paketshop/82' ) {
			
			task.Description = existingDescription + '\r\n' + '\r\n' +
					+'Standardaufgabenbeschreibung:' + '\r\n'
					+ 'Die Filiale hat eine Schließung angezeigt (Partnerportal). Bitte mit dem Partner ' +
					'Kontakt aufnehmen und zur Wiedereröffnung bewegen. Bleibt die Filiale geöffnet, im Feld ' +
					'Status-Anmerkung "Maßnahme erfolgreich umgesetzt" auswählen. Evtl. ' +
					'vorübergehend geänderte Öffnungszeiten sind über das Partnerportal anzuzeigen.';
		}
		else {
			//Sonarqube --> do nothing
		}
	}
	
	private Boolean isDefault ( Task task ) {
		return Trigger.isInsert
				&& task.Aufgabenart__c != 'Kapazitätsabfrage Paketausgabe und -annahme + Detail'
				&& standardDescriptionByTaskType.containsKey( task.Aufgabenart__c );
	}
	
	private Boolean isKapa ( Task task ) {
		return Trigger.isInsert
				&& task.Aufgabenart__c == 'Kapazitätsabfrage Paketausgabe und -annahme + Detail'
				&& String.isBlank( task.Description )
				&& accountsById.containsKey( task.WhatId );
	}
	
	private String returnEmptyIfNull ( String text ) {
		return text == null ? '' : text;
	}
}