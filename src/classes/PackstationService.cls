/**
 *@author       Mats Böhler
 *@created      30.08.2021
 *
 *
 *@description  PackstationService
 *
 *
 *@changelog    30.08.2021 Mats Böhler  - Created
 *              
 * 
 */
public with sharing class PackstationService {
	
	private static final String PACKSTATION_RT = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName()
			.get( 'Packstation' ).getRecordTypeId();
	
	private List<Account> accounts = new List<Account>();
	private List<Lead> leads = new List<Lead>();
	private Map<Id, List<Lead>> leadsByAccountIds = new Map<Id, List<Lead>>();
	private Map<Id, List<Lead>> abbauLeadsByAufbauLeadIds = new Map<Id, List<Lead>>();
	private Set<Id> leadIdsDummyPackstation = new Set<Id>();
	
	public Map<Id, List<Lead>> createLeads ( Set<Id> accountIds ) {
		if (accountIds.isEmpty() ) {
			return leadsByAccountIds;
		}
		loadAccounts( accountIds );
		
		for ( Account account : accounts ) {
			
			switch on account.Bestandsmassnahme__c {
				when 'Entlastung (Erweiterung / Austausch)' {
					createLeadEntlastung( account );
				}
				when 'Formatwechsel (Pack-/Poststation)' {
					createLeadFormatwechsel( account );
				}
				when 'Automatentausch' {
					createLeadAutomatentausch( account );
				}
				when 'Abbau' {
					createLeadAbbau( account );
				}
				when 'Kündigung' {
					createLeadKuendigung( account );
				}
				when else {
					//Sonarqube --> do nothing
				}
			}
		}
		List<Lead> newLeads = new List<Lead>();
		for ( Id accountId : leadsByAccountIds.keySet() ) {
			newLeads.addAll( leadsByAccountIds.get( accountId ) );
		}
		insert newLeads;
		TriggerHandler.bypass( 'LeadTriggerHandler' );
		List<Lead> connectedLeads = new List<Lead>();
		for ( Id accountId : leadsByAccountIds.keySet() ) {
			List<Lead> leads = leadsByAccountIds.get( accountId );
			if ( leads.size() > 1 ) {
				Lead leadAufbau = leads[ 0 ];
				Lead leadAbbau = leads[ 1 ];
				leadAufbau.VerknuepfterLead__c = leadAbbau.Id;
				leadAbbau.VerknuepfterLead__c = leadAufbau.Id;
				connectedLeads.add( leadAbbau );
				connectedLeads.add( leadAufbau );
			}
		}
		update connectedLeads;
		TriggerHandler.clearBypass( 'LeadTriggerHandler' );
		for ( Lead lead : newLeads ) {
			if ( lead.Bestandsmassnahme__c == 'Formatwechsel (Pack-/Poststation) - Aufbau' ) {
				leadIdsDummyPackstation.add( lead.Id );
			}
		}
		if ( !leadIdsDummyPackstation.isEmpty() ) {
			PackstationDummyInitializer packstationDummyInitializer = new PackstationDummyInitializer();
			packstationDummyInitializer.create( leadIdsDummyPackstation );
			packstationDummyInitializer.cloneAccountContactRelations( leadIdsDummyPackstation );
		}
		return leadsByAccountIds;
	}
	
	public Map<Id, List<Lead>> createAbbauLeads ( Set<Id> leadIds ) {
		
		loadLeads( leadIds );
		
		for ( Lead lead : leads ) {
			
			switch on lead.Bestandsmassnahme__c {
				when 'Entlastung - Aufbau' {
					createLeadEntlastungAbbau( lead );
				}
				when 'Formatwechsel (Pack-/Poststation) - Aufbau' {
					createLeadFormatwechselAbbau( lead );
				}
				when else {
					//Sonarqube --> do nothing
				}
			}
		}
		List<Lead> newAbbauLeads = new List<Lead>();
		for ( Id aufbauLeadId : abbauLeadsByAufbauLeadIds.keySet() ) {
			newAbbauLeads.addAll( abbauLeadsByAufbauLeadIds.get( aufbauLeadId ) );
		}
		insert newAbbauLeads;
		TriggerHandler.bypass( 'LeadTriggerHandler' );
		List<Lead> connectedLeads = new List<Lead>();
		for ( Lead lead : leads ) {
			lead.VerknuepfterLead__c = abbauLeadsByAufbauLeadIds.get( lead.Id )[ 0 ].Id;
			connectedLeads.add( lead );
		}
		update connectedLeads;
		TriggerHandler.clearBypass( 'LeadTriggerHandler' );
		return abbauLeadsByAufbauLeadIds;
	}
	
	private void createLeadEntlastung ( Account account ) {
		Lead lead = getDefaultLead( account );
		lead.Bestandsmassnahme__c = 'Entlastung - Aufbau';
		lead.Bewertung_Zentrale__c = 'Geeignet';
		lead.Bewertung_Zentrale_vom__c = Date.today();
		lead.Aktion_am_STO__c = 'Aufbau';
		lead.Packstation__c = account.Id;
		lead.PODID_Lookup__c = account.PODID__c;
		leadsByAccountIds.put( account.Id, new List<Lead> {
				lead
		} );
	}
	
	private void createLeadEntlastungAbbau ( Lead lead ) {
		Lead abbauLead = getDefaultAbbauLead( lead );
		abbauLead.Bestandsmassnahme__c = 'Entlastung - Abbau';
		abbauLead.Bewertung_Zentrale__c = 'Geeignet';
		abbauLead.Bewertung_Zentrale_vom__c = Date.today();
		abbauLead.Aktion_am_STO__c = 'Abbau';
		abbauLead.VerknuepfterLead__c = lead.Id;
		abbauLead.Packstation__c = lead.Filiale_Filialpartner__c;
		abbauLead.PODID_Lookup__c = lead.Filiale_Filialpartner__r.PODID__c;
		setAbbauFields( abbauLead, lead );
		abbauLeadsByAufbauLeadIds.put( lead.Id, new List<Lead> {
				abbauLead
		} );
	}
	
	private void setAbbauFields ( Lead abbauLead, Lead lead ) {
		abbauLead.PODID_Lookup__c = lead.Filiale_Filialpartner__r.PODID__c;
		abbauLead.ADM_Typ__c = lead.Filiale_Filialpartner__r.Lead__r.ADM_Typ__c;
		abbauLead.ADM_Hersteller__c = lead.Filiale_Filialpartner__r.Lead__r.ADM_Hersteller__c;
		abbauLead.Anlagennummer__c = lead.Filiale_Filialpartner__r.Lead__r.Anlagennummer__c;
		abbauLead.Aufbauform__c = lead.Filiale_Filialpartner__r.Lead__r.Aufbauform__c;
		abbauLead.Fundament__c = lead.Filiale_Filialpartner__r.Lead__r.Fundament__c;
		abbauLead.In_Outdoor__c = lead.Filiale_Filialpartner__r.Lead__r.In_Outdoor__c;
		abbauLead.Fachmodule__c = lead.Filiale_Filialpartner__r.Lead__r.Fachmodule__c;
		abbauLead.Steuermodule__c = lead.Filiale_Filialpartner__r.Lead__r.Steuermodule__c;
		abbauLead.Eckmodule__c = lead.Filiale_Filialpartner__r.Lead__r.Eckmodule__c;
		abbauLead.Unterbrechung__c = lead.Filiale_Filialpartner__r.Lead__r.Unterbrechung__c;
		abbauLead.STOG_Kategorie_Matchcode__c = lead.Filiale_Filialpartner__r.Lead__r.STOG_Kategorie_Matchcode__c;
		abbauLead.Anlagenummer__c = lead.Filiale_Filialpartner__r.Lead__r.Anlagenummer__c;
	}
	
	private void setAbbauFields ( Lead abbauLead, Account account ) {
		abbauLead.PODID_Lookup__c = account.PODID__c;
		abbauLead.ADM_Typ__c = account.Lead__r.ADM_Typ__c;
		abbauLead.ADM_Hersteller__c = account.Lead__r.ADM_Hersteller__c;
		abbauLead.Anlagennummer__c = account.Lead__r.Anlagennummer__c;
		abbauLead.Aufbauform__c = account.Lead__r.Aufbauform__c;
		abbauLead.Fundament__c = account.Lead__r.Fundament__c;
		abbauLead.In_Outdoor__c = account.Lead__r.In_Outdoor__c;
		abbauLead.Fachmodule__c = account.Lead__r.Fachmodule__c;
		abbauLead.Steuermodule__c = account.Lead__r.Steuermodule__c;
		abbauLead.Eckmodule__c = account.Lead__r.Eckmodule__c;
		abbauLead.Unterbrechung__c = account.Lead__r.Unterbrechung__c;
		abbauLead.STOG_Kategorie_Matchcode__c = account.Lead__r.STOG_Kategorie_Matchcode__c;
		abbauLead.Anlagenummer__c = account.Lead__r.Anlagenummer__c;
	}
	
	private void createLeadFormatwechsel ( Account account ) {
		Lead lead = getDefaultLead( account );
		lead.Bestandsmassnahme__c = 'Formatwechsel (Pack-/Poststation) - Aufbau';
		if ( account.Ziel_Format__c == 'Packstation' ) {
			lead.Bewertung_Zentrale__c = 'Geeignet';
		}
		else if ( account.Ziel_Format__c == 'Poststation' ) {
			lead.Bewertung_Zentrale__c = 'Geeignet – nur als Poststation';
		}
		else {
			//Sonarqube --> do nothing
		}
		lead.Bewertung_Zentrale_vom__c = Date.today();
		lead.Aktion_am_STO__c = 'Aufbau (Austausch)';
		leadsByAccountIds.put( account.Id, new List<Lead> {
				lead
		} );
	}
	
	private void createLeadFormatwechselAbbau ( Lead lead ) {
		Lead abbauLead = getDefaultAbbauLead( lead );
		abbauLead.Bestandsmassnahme__c = 'Formatwechsel (Pack-/Poststation) - Abbau';
		abbauLead.Bewertung_Zentrale__c = 'Geeignet';
		abbauLead.Bewertung_Zentrale_vom__c = Date.today();
		abbauLead.Aktion_am_STO__c = 'Abbau (Austausch)';
		abbauLead.VerknuepfterLead__c = lead.Id;
		abbauLead.Packstation__c = lead.Filiale_Filialpartner__c;
		abbauLead.PODID_Lookup__c = lead.Filiale_Filialpartner__r.PODID__c;
		setAbbauFields( abbauLead, lead );
		abbauLeadsByAufbauLeadIds.put( lead.Id, new List<Lead> {
				abbauLead
		} );
	}
	
	private void createLeadAutomatentausch ( Account account ) {
		Lead lead = getDefaultLead( account );
		lead.Bestandsmassnahme__c = 'Automatentausch - Aufbau';
		lead.Aktion_am_STO__c = 'Aufbau (Austausch)';
		lead.Packstation__c = account.Id;
		lead.PODID_Lookup__c = account.PODID__c;
		leadsByAccountIds.put( account.Id, new List<Lead> {
				lead
		} );
		Lead secondLead = getDefaultLead( account );
		secondLead.Bestandsmassnahme__c = 'Automatentausch - Abbau';
		secondLead.Aktion_am_STO__c = 'Abbau (Austausch)';
		secondLead.Packstation__c = account.Id;
		secondLead.PODID_Lookup__c = account.PODID__c;
		setAbbauFields( secondLead, account );
		leadsByAccountIds.get( account.Id ).add( secondLead );
	}
	
	private void createLeadAbbau ( Account account ) {
		Lead lead = getDefaultLead( account );
		lead.Bestandsmassnahme__c = 'Abbau';
		lead.Bewertung_Zentrale__c = 'Geeignet';
		lead.Bewertung_Zentrale_vom__c = Date.today();
		lead.Aktion_am_STO__c = 'Abbau';
		lead.Packstation__c = account.Id;
		lead.PODID_Lookup__c = account.PODID__c;
		setAbbauFields( lead, account );
		leadsByAccountIds.put( account.Id, new List<Lead> {
				lead
		} );
	}
	
	private void createLeadKuendigung ( Account account ) {
		Lead lead = getDefaultLead( account );
		lead.Bestandsmassnahme__c = 'Kündigung - Abbau';
		lead.Bewertung_Zentrale__c = 'Geeignet';
		lead.Bewertung_Zentrale_vom__c = Date.today();
		lead.Aktion_am_STO__c = 'Abbau';
		lead.Packstation__c = account.Id;
		lead.PODID_Lookup__c = account.PODID__c;
		setAbbauFields( lead, account );
		leadsByAccountIds.put( account.Id, new List<Lead> {
				lead
		} );
	}
	
	private Lead getDefaultLead ( Account account ) {
		return new Lead(
				RecordTypeId = PACKSTATION_RT,
				Bestandsmassnahme__c = account.Bestandsmassnahme__c,
				Bestandsmassnahme_Datum__c = Date.today(),
				VL__c = account.Lead__r.VL__c,
				Filialnetzaenderung__c = account.Filialnetzaenderung__c,
				Filiale_Filialpartner__c = account.Id,
				Aktivitaetsstatus__c = 'aktiv durch Zentrale',
				FirstName = account.Lead__r.FirstName,
				LastName = account.Lead__r.LastName == null ? 'Nicht definiert' : account.Lead__r.LastName,
				Phone = account.Lead__r.Phone,
				Company = account.Lead__r.Company == null ? 'Nicht definiert' : account.Lead__r.Company,
				Email = account.Lead__r.Email,
				Street = account.ShippingStreet,
				PostalCode = account.ShippingPostalCode,
				City = account.ShippingCity,
				ZusaetzlichZuInformierenEMail__c = account.Lead__r.ZusaetzlichZuInformierenEMail__c,
				STOG_Gesellschaft__c = account.Lead__r.STOG_Gesellschaft__c,
				STOG_Interne_ID__c = account.Filial_ILN__c,
				Parkplatz_vorhanden__c = account.Lead__r.Parkplatz_vorhanden__c,
				Strategischer_Partner__c = account.Betreiber__c,
				Akquisemodus__c = account.Akquisemodus__c,
				ZuordnungZuRahmenvertrag__c = account.Zuordnung_zu_Rahmenvertrag__c,
				UnterlagenZurFreigabeEinreichenBei__c = account.Unterlagen_zur_Freigabe_einreichen_bei__c,
				HinweisSPM__c = account.Lead__r.HinweisSPM__c,
				Ziel_Fachanzahl__c = account.Ziel_Fachanzahl__c,
				Urspruenglicher_Lead__c = account.Lead__c,
				OwnerId = account.OwnerId,
				NameDesOnepagers__c = account.Lead__r.Name_des_OnePagers_Formel__c,
				Potenzial__c = account.Lead__r.Potenzial__c,
				Hinweis_Bestandsmassnahme__c = account.Hinweis_Bestandsmassnahme__c,
				LeadSource = 'DP AG',
				STO_Art__c = 'Bestand'
		);
	}
	
	private Lead getDefaultAbbauLead ( Lead lead ) {
		return new Lead(
				RecordTypeId = PACKSTATION_RT,
				Bestandsmassnahme__c = lead.Bestandsmassnahme__c,
				Bestandsmassnahme_Datum__c = Date.today(),
				VL__c = lead.Filiale_Filialpartner__r.Lead__r.VL__c,
				Filialnetzaenderung__c = lead.Filiale_Filialpartner__r.Filialnetzaenderung__c,
				Filiale_Filialpartner__c = lead.Filiale_Filialpartner__c,
				Aktivitaetsstatus__c = 'aktiv durch Zentrale',
				FirstName = lead.Filiale_Filialpartner__r.Lead__r.FirstName,
				LastName = lead.Filiale_Filialpartner__r.Lead__r.LastName,
				Phone = lead.Filiale_Filialpartner__r.Lead__r.Phone,
				Company = lead.Filiale_Filialpartner__r.Lead__r.Company,
				Email = lead.Filiale_Filialpartner__r.Lead__r.Email,
				Street = lead.Filiale_Filialpartner__r.ShippingStreet,
				PostalCode = lead.Filiale_Filialpartner__r.ShippingPostalCode,
				City = lead.Filiale_Filialpartner__r.ShippingCity,
				ZusaetzlichZuInformierenEMail__c = lead.Filiale_Filialpartner__r.Lead__r.ZusaetzlichZuInformierenEMail__c,
				STOG_Gesellschaft__c = lead.Filiale_Filialpartner__r.Lead__r.STOG_Gesellschaft__c,
				STOG_Interne_ID__c = lead.Filiale_Filialpartner__r.Filial_ILN__c,
				Parkplatz_vorhanden__c = lead.Filiale_Filialpartner__r.Lead__r.Parkplatz_vorhanden__c,
				Strategischer_Partner__c = lead.Filiale_Filialpartner__r.Betreiber__c,
				Akquisemodus__c = lead.Filiale_Filialpartner__r.Akquisemodus__c,
				ZuordnungZuRahmenvertrag__c = lead.Filiale_Filialpartner__r.Zuordnung_zu_Rahmenvertrag__c,
				UnterlagenZurFreigabeEinreichenBei__c = lead.Filiale_Filialpartner__r.Unterlagen_zur_Freigabe_einreichen_bei__c,
				HinweisSPM__c = lead.Filiale_Filialpartner__r.Lead__r.HinweisSPM__c,
				Ziel_Fachanzahl__c = lead.Filiale_Filialpartner__r.Ziel_Fachanzahl__c,
				Urspruenglicher_Lead__c = lead.Filiale_Filialpartner__r.Lead__c,
				OwnerId = lead.Filiale_Filialpartner__r.OwnerId == null ? lead.OwnerId : lead.Filiale_Filialpartner__r.OwnerId,
				NameDesOnepagers__c = lead.Filiale_Filialpartner__r.Lead__r.Name_des_OnePagers_Formel__c,
				Potenzial__c = lead.Filiale_Filialpartner__r.Lead__r.Potenzial__c,
				Hinweis_Bestandsmassnahme__c = lead.Filiale_Filialpartner__r.Hinweis_Bestandsmassnahme__c,
				LeadSource = 'DP AG',
				STO_Art__c = 'Bestand'
		);
	}
	
	private void loadAccounts ( Set<Id> accountIds ) {
		accounts = [
				SELECT
						Id,
						Bestandsmassnahme__c,
						Bestandsmassnahme_Datum__c,
						GL__c,
						Filialnetzaenderung__c,
						Lead__r.Aktivitaetsstatus__c,
						Lead__r.FirstName,
						Lead__r.LastName,
						Lead__r.Phone,
						Lead__r.Company,
						Lead__r.Email,
						ShippingStreet,
						ShippingPostalCode,
						ShippingCity,
						Lead__r.ZusaetzlichZuInformierenEMail__c,
						Lead__r.STOG_Gesellschaft__c,
						Filial_ILN__c,
						Lead__r.Parkplatz_vorhanden__c,
						Betreiber__c,
						Akquisemodus__c,
						Zuordnung_zu_Rahmenvertrag__c,
						Unterlagen_zur_Freigabe_einreichen_bei__c,
						Lead__r.HinweisSPM__c,
						Ziel_Fachanzahl__c,
						Lead__c,
						OwnerId,
						Lead__r.Name_des_OnePagers_Formel__c,
						Lead__r.VL__c,
						Lead__r.Hinweis_Zentrale__c,
						Lead__r.Potenzial__c,
						Hinweis_Bestandsmassnahme__c,
						Ziel_Format__c,
						PODID__c,
						Lead__r.ADM_Typ__c,
						Lead__r.ADM_Hersteller__c,
						Lead__r.Anlagennummer__c,
						Lead__r.Aufbauform__c,
						Lead__r.Fundament__c,
						Lead__r.In_Outdoor__c,
						Lead__r.Fachmodule__c,
						Lead__r.Steuermodule__c,
						Lead__r.Eckmodule__c,
						Lead__r.Unterbrechung__c,
						Lead__r.STOG_Kategorie_Matchcode__c,
						Lead__r.Anlagenummer__c
				FROM Account
				WHERE Id IN :accountIds
		];
	}
	
	private void loadLeads ( Set<Id> leadIds ) {
		leads = [
				SELECT
						Id,
						Filiale_Filialpartner__c,
						Filiale_Filialpartner__r.Bestandsmassnahme__c,
						Filiale_Filialpartner__r.Bestandsmassnahme_Datum__c,
						Filiale_Filialpartner__r.GL__c,
						Filiale_Filialpartner__r.Filialnetzaenderung__c,
						Filiale_Filialpartner__r.Lead__r.Aktivitaetsstatus__c,
						Filiale_Filialpartner__r.Lead__r.FirstName,
						Filiale_Filialpartner__r.Lead__r.LastName,
						Filiale_Filialpartner__r.Lead__r.Phone,
						Filiale_Filialpartner__r.Lead__r.Company,
						Filiale_Filialpartner__r.Lead__r.Email,
						Filiale_Filialpartner__r.ShippingStreet,
						Filiale_Filialpartner__r.ShippingPostalCode,
						Filiale_Filialpartner__r.ShippingCity,
						Filiale_Filialpartner__r.Lead__r.ZusaetzlichZuInformierenEMail__c,
						Filiale_Filialpartner__r.Lead__r.STOG_Gesellschaft__c,
						Filiale_Filialpartner__r.Filial_ILN__c,
						Filiale_Filialpartner__r.Lead__r.Parkplatz_vorhanden__c,
						Filiale_Filialpartner__r.Betreiber__c,
						Filiale_Filialpartner__r.Akquisemodus__c,
						Filiale_Filialpartner__r.Zuordnung_zu_Rahmenvertrag__c,
						Filiale_Filialpartner__r.Unterlagen_zur_Freigabe_einreichen_bei__c,
						Filiale_Filialpartner__r.Lead__r.HinweisSPM__c,
						Filiale_Filialpartner__r.Ziel_Fachanzahl__c,
						Filiale_Filialpartner__r.Lead__c,
						Filiale_Filialpartner__r.OwnerId,
						Filiale_Filialpartner__r.Lead__r.Name_des_OnePagers_Formel__c,
						Filiale_Filialpartner__r.Lead__r.VL__c,
						Filiale_Filialpartner__r.Lead__r.Hinweis_Zentrale__c,
						Filiale_Filialpartner__r.Lead__r.Potenzial__c,
						Filiale_Filialpartner__r.Hinweis_Bestandsmassnahme__c,
						Filiale_Filialpartner__r.Ziel_Format__c,
						Bestandsmassnahme__c,
						Akquisemodus__c,
						OwnerId,
						Filiale_Filialpartner__r.PODID__c,
						Filiale_Filialpartner__r.Lead__r.ADM_Typ__c,
						Filiale_Filialpartner__r.Lead__r.ADM_Hersteller__c,
						Filiale_Filialpartner__r.Lead__r.Anlagennummer__c,
						Filiale_Filialpartner__r.Lead__r.Aufbauform__c,
						Filiale_Filialpartner__r.Lead__r.Fundament__c,
						Filiale_Filialpartner__r.Lead__r.In_Outdoor__c,
						Filiale_Filialpartner__r.Lead__r.Fachmodule__c,
						Filiale_Filialpartner__r.Lead__r.Steuermodule__c,
						Filiale_Filialpartner__r.Lead__r.Eckmodule__c,
						Filiale_Filialpartner__r.Lead__r.Unterbrechung__c,
						Filiale_Filialpartner__r.Lead__r.STOG_Kategorie_Matchcode__c,
						Filiale_Filialpartner__r.Lead__r.Anlagenummer__c,
						PODID_Lookup__c
				FROM Lead
				WHERE Id IN :leadIds
		];
	}
}