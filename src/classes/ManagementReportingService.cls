/**
 *@author       Mats Böhler
 *@created      16.11.2020
 *
 *
 *@description  ManagementReporting
 *
 *
 *@changelog    16.11.2020 Mats Böhler  - Created
 *              
 * 
 */
public without sharing class ManagementReportingService {
	
	private List<Lead> leads = new List<Lead>();
	private Map<String, ManagementReportingEinstellung__mdt> settingByClassifications = new Map<String, ManagementReportingEinstellung__mdt>();
	
	public void setClassification ( Set<Id> leadIds ) {
		loadLeads( leadIds );
		loadSettings();
		
		for ( Lead lead : leads ) {
			setZentrale( lead );
			setAussenOrganisation( lead );
			setStandortdoku( lead );
			setBaufreigabe( lead );
			setVertrag( lead );
			setRest( lead );
		}
		update leads;
	}
	
	private void setZentrale ( Lead lead ) {
		if ( isOhneBewertungZentrale( lead ) ) {
			lead.KlassifizierungManagementReporting__c = 'Ohne Bewertung (Zentrale)';
		}
		if ( isUngeeignetZentrale( lead ) ) {
			
			lead.KlassifizierungManagementReporting__c = 'Ungeeignet (Zentrale)';
		}
		if ( isGeeignetZentrale( lead ) ) {
			
			lead.KlassifizierungManagementReporting__c = 'Geeignet (Zentrale)';
		}
		if ( isGeeignetZentraleOhneBewertungAO( lead ) ) {
			
			lead.KlassifizierungManagementReporting__c = 'Geeignet (Zentrale), ohne Bewertung (AO)';
		}
	}
	
	private void setAussenOrganisation ( Lead lead ) {
		if ( isUngeeignetAO( lead ) ) {
			
			lead.KlassifizierungManagementReporting__c = 'Ungeeignet (AO)';
		}
		if ( isGeeignetAO( lead ) ) {
			
			lead.KlassifizierungManagementReporting__c = 'Geeignet (AO)';
		}
		if ( isGeeignetAOMitStandortdoku( lead ) ) {
			
			lead.KlassifizierungManagementReporting__c = 'Geeignet (AO) mit erstellter Standortdoku';
		}
		if ( isGeeignetAOOhneStandortdoku( lead ) ) {
			
			lead.KlassifizierungManagementReporting__c = 'Geeignet (AO) ohne Standortdoku';
		}
	}
	
	private void setStandortdoku ( Lead lead ) {
		if ( isStandortdokuWartetAufFreigabe( lead ) ) {
			
			lead.KlassifizierungManagementReporting__c = 'Standortdoku wartet auf Freigabe (rVU)';
		}
		if ( isStandortdokuInNachbesserung( lead ) ) {
			
			lead.KlassifizierungManagementReporting__c = 'Standortdoku in Nachbesserung (rVU/VM)';
		}
		if ( isStandortdokuFreigegeben( lead ) ) {
			
			lead.KlassifizierungManagementReporting__c = 'Standortdoku freigegeben (rVU)';
		}
		if ( isStandortdokuFreigegebenSTOG( lead ) ) {
			
			lead.KlassifizierungManagementReporting__c = 'Standortdoku freigegeben (STOG)';
		}
		if ( isStandortdokuAbgelehnt( lead ) ) {
			
			lead.KlassifizierungManagementReporting__c = 'Standortdoku abgelehnt (STOG)';
		}
		if ( isStandortdokuInWarteschleife( lead ) ) {
			
			lead.KlassifizierungManagementReporting__c = 'Standortdoku in Warteschleife (STOG)';
		}
	}
	
	private void setBaufreigabe ( Lead lead ) {
		if ( isBaufreigabeInPruefung( lead ) ) {
			
			lead.KlassifizierungManagementReporting__c = 'Baufreigabe in Prüfung';
		}
		if ( isBaufreigabeVorhanden( lead ) ) {
			
			lead.KlassifizierungManagementReporting__c = 'Baufreigabe vorhanden';
		}
		if ( isBaufreigabeAbgelehnt( lead ) ) {
			
			lead.KlassifizierungManagementReporting__c = 'Baufreigabe abgelehnt';
		}
		if ( isBaupruefungOffen( lead ) ) {
			
			lead.KlassifizierungManagementReporting__c = 'Freigabe STOG vorhanden, Bauprüfung offen';
		}
	}
	
	private void setVertrag ( Lead lead ) {
		if ( isVertragAbgelehnt( lead ) ) {
			
			lead.KlassifizierungManagementReporting__c = 'Vertrag abgelehnt (STOG/VP)';
		}
		if ( isVertragUnterzeichnet( lead ) ) {
			
			lead.KlassifizierungManagementReporting__c = 'Vertrag unterzeichnet (STOG/VP)';
		}
		if ( isVertragWartetAufFreigabe( lead ) ) {
			
			lead.KlassifizierungManagementReporting__c = 'Vertrag wartet auf Freigabe (STOG/VP)';
		}
		if ( isVertragNochNichtVersendet( lead ) ) {
			
			lead.KlassifizierungManagementReporting__c = 'Baufreigabe vorhanden, Vertrag noch nicht versendet';
		}
		if ( isVertragUnterzeichnetDPAG( lead ) ) {
			
			lead.KlassifizierungManagementReporting__c = 'Vertrag unterzeichnet (DPAG)';
		}
		if ( isVertragWartetAufUnterzeichnungDPAG( lead ) ) {
			
			lead.KlassifizierungManagementReporting__c = 'Vertrag wartet auf Unterzeichnung (DPAG)';
		}
	}
	
	private void setRest ( Lead lead ) {
		if ( isUebergebenAnTeamBauen( lead ) ) {
			
			lead.KlassifizierungManagementReporting__c = 'Übergeben an Team Bauen';
		}
		if ( isBaucheckErfolgreich( lead ) ) {
			
			lead.KlassifizierungManagementReporting__c = 'Bau-Check erfolgreich';
		}
		if ( isUebergebenAnTeamLogistik( lead ) ) {
			
			lead.KlassifizierungManagementReporting__c = 'Übergeben an Team Logistik';
		}
		if ( isPackstationAufgebaut( lead ) ) {
			
			lead.KlassifizierungManagementReporting__c = 'Packstation aufgebaut';
		}
		if ( isPackstationInBetrieb( lead ) ) {
			
			lead.KlassifizierungManagementReporting__c = 'Packstation in Betrieb';
		}
	}
	
	private void loadLeads ( Set<Id> leadIds ) {
		leads = [
				SELECT
						Id,
						go_live__c,
						AufstelldatumADM__c,
						Aufbaufaehig_ab_Datum__c,
						Baucheck_erfolgt_Datum__c,
						STO_disponiert__c,
						Vertrag_versandt__c,
						Ergebnis_weit_Bauordnungsrechtl_Pruefung__c,
						Ergebnis_Bauordnungsrechtliche_Pruefung__c,
						Vertrag_unterschrieben__c,
						Freigabe_STOG__c,
						DokumentationVersandtDatum__c,
						DokumentationDurchRTFreigebenDatum__c,
						DokumentationErstelltDatum__c,
						NachbesserungAngefordert__c,
						Bewertung_VM__c,
						Bewertung_Zentrale__c,
						Bewertung_Zentrale_vom__c,
						Bewertung_VM_vom__c,
						Bauordnungsrechtliche_Pruefung__c,
						Weitere_Bauord_rechtl_Pruefung__c,
						Zustimmung_Ablehnung_zum_Vertrag_Datum__c,
						Freigabe_STOG_Datum__c,
						Ergebnis_Bauord_rechtl_Pruefung_Datum__c,
						Ergebnis_weit_Bau_rechtl_Pruef_Datum__c,
						VertragVonVLUnterschriebenAm__c,
						ist_disponiert__c
				FROM Lead
				WHERE Id IN :leadIds
				AND RecordType.DeveloperName = 'Packstation'
		];
	}
	
	private void loadSettings () {
		for ( ManagementReportingEinstellung__mdt setting : [
				SELECT
						Id,
						Klassifizierung__c,
						Feld__c,
						Tage__c
				FROM ManagementReportingEinstellung__mdt
		] ) {
			
			settingByClassifications.put( setting.Klassifizierung__c, setting );
		}
	}
	
	private Boolean isOhneBewertungZentrale ( Lead lead ) {
		return lead.Bewertung_Zentrale__c == null;
	}
	
	private Boolean isUngeeignetZentrale ( Lead lead ) {
		return lead.Bewertung_Zentrale__c == 'Nicht geeignet, zu geringes Potenzial'
				|| lead.Bewertung_Zentrale__c == 'Nicht geeignet, zu nah an Bestand'
				|| lead.Bewertung_Zentrale__c == 'Durch Zentrale STOG abgelehnt'
				|| lead.Bewertung_Zentrale__c == 'Geeignet, kein Bedarf'
				|| lead.Bewertung_Zentrale__c == 'in Klärung Weiden'
				|| lead.Bewertung_Zentrale__c == 'In Klärung bei SPM';
	}
	
	private Boolean isGeeignetZentrale ( Lead lead ) {
		return lead.Bewertung_Zentrale__c == 'Vorläufige Freigabe'
				|| lead.Bewertung_Zentrale__c == 'Geeignet'
				|| lead.Bewertung_Zentrale__c == 'Geeignet - Priorisierte Bearbeitung'
				|| lead.Bewertung_Zentrale__c == 'Geeignet - nur als Poststation'
				|| lead.Bewertung_Zentrale__c == 'Geeignet - Hotlead';
	}
	
	private Boolean isGeeignetZentraleOhneBewertungAO ( Lead lead ) {
		return ( lead.Bewertung_Zentrale__c == 'Vorläufige Freigabe'
				|| lead.Bewertung_Zentrale__c == 'Geeignet'
				|| lead.Bewertung_Zentrale__c == 'Geeignet - Priorisierte Bearbeitung'
				|| lead.Bewertung_Zentrale__c == 'Geeignet - nur als Poststation'
				|| lead.Bewertung_Zentrale__c == 'Geeignet - Hotlead' )
				&& lead.Bewertung_VM__c == null
				&& ( Date ) lead.get( settingByClassifications.get( 'Geeignet (Zentrale), ohne Bewertung (AO)' ).Feld__c )
				<= Date.today().addDays( -Integer.valueOf( settingByClassifications.get( 'Geeignet (Zentrale), ohne Bewertung (AO)' ).Tage__c ) );
	}
	
	private Boolean isUngeeignetAO ( Lead lead ) {
		return ( lead.Bewertung_Zentrale__c == 'Vorläufige Freigabe'
				|| lead.Bewertung_Zentrale__c == 'Geeignet'
				|| lead.Bewertung_Zentrale__c == 'Geeignet - Priorisierte Bearbeitung'
				|| lead.Bewertung_Zentrale__c == 'Geeignet - nur als Poststation'
				|| lead.Bewertung_Zentrale__c == 'Geeignet - Hotlead' )
				&& ( lead.Bewertung_VM__c == 'Absage DHL - kein Mikro-STO'
				|| lead.Bewertung_VM__c == 'Absage DHL - kein Potenzial'
				|| lead.Bewertung_VM__c == 'Absage DHL - Nähe zu anderer LPS (Entfernung < 150m)'
				|| lead.Bewertung_VM__c == 'Absage DHL - Sonstiges (Grund in Freitext)'
				|| lead.Bewertung_VM__c == 'Packstation vorhanden'
				|| lead.Bewertung_VM__c == 'Wettbewerber Shop vorhanden'
				|| lead.Bewertung_VM__c == 'Wettbewerber Locker vorhanden'
				|| lead.Bewertung_VM__c == 'Dublette'
				|| lead.Bewertung_VM__c == 'Absage durch STOG - Kein Interesse' );
	}
	
	private Boolean isGeeignetAO ( Lead lead ) {
		return ( lead.Bewertung_VM__c == 'Geeignet (noch nicht in Bearbeitung)'
				|| returnEmptyIfNull( lead.Bewertung_VM__c ).contains( 'Potenzial 202' )
				|| lead.Bewertung_VM__c == 'Geeignet (in Bearbeitung)' )
				&& ( lead.Bewertung_Zentrale__c == 'Vorläufige Freigabe'
				|| lead.Bewertung_Zentrale__c == 'Geeignet'
				|| lead.Bewertung_Zentrale__c == 'Geeignet - Priorisierte Bearbeitung'
				|| lead.Bewertung_Zentrale__c == 'Geeignet - nur als Poststation'
				|| lead.Bewertung_Zentrale__c == 'Geeignet - Hotlead' );
	}
	
	private Boolean isGeeignetAOMitStandortdoku ( Lead lead ) {
		return ( lead.Bewertung_VM__c == 'Geeignet (noch nicht in Bearbeitung)'
				|| returnEmptyIfNull( lead.Bewertung_VM__c ).contains( 'Potenzial 202' )
				|| lead.Bewertung_VM__c == 'Geeignet (in Bearbeitung)' )
				&& lead.DokumentationErstelltDatum__c != null;
	}
	
	private Boolean isGeeignetAOOhneStandortdoku ( Lead lead ) {
		return ( lead.Bewertung_VM__c == 'Geeignet (noch nicht in Bearbeitung)'
				|| returnEmptyIfNull( lead.Bewertung_VM__c ).contains( 'Potenzial 202' )
				|| lead.Bewertung_VM__c == 'Geeignet (in Bearbeitung)' )
				&& lead.DokumentationErstelltDatum__c == null
				&& ( Date ) lead.get( settingByClassifications.get( 'Geeignet (AO) ohne Standortdoku' ).Feld__c )
				<= Date.today().addDays( -Integer.valueOf( settingByClassifications.get( 'Geeignet (AO) ohne Standortdoku' ).Tage__c ) );
	}
	
	private Boolean isStandortdokuWartetAufFreigabe ( Lead lead ) {
		return ( lead.Bewertung_VM__c == 'Geeignet (noch nicht in Bearbeitung)'
				|| returnEmptyIfNull( lead.Bewertung_VM__c ).contains( 'Potenzial 202' )
				|| lead.Bewertung_VM__c == 'Geeignet (in Bearbeitung)' )
				&& lead.DokumentationErstelltDatum__c != null
				&& lead.DokumentationDurchRTFreigebenDatum__c == null
				&& !lead.NachbesserungAngefordert__c
				&& ( Date ) lead.get( settingByClassifications.get( 'Standortdoku wartet auf Freigabe (rVU)' ).Feld__c )
				<= Date.today().addDays( -Integer.valueOf( settingByClassifications.get( 'Standortdoku wartet auf Freigabe (rVU)' ).Tage__c ) );
	}
	
	private Boolean isStandortdokuInNachbesserung ( Lead lead ) {
		return lead.DokumentationErstelltDatum__c != null
				&& lead.DokumentationDurchRTFreigebenDatum__c == null
				&& lead.NachbesserungAngefordert__c;
	}
	
	private Boolean isStandortdokuFreigegeben ( Lead lead ) {
		return ( lead.Bewertung_VM__c == 'Geeignet (noch nicht in Bearbeitung)'
				|| returnEmptyIfNull( lead.Bewertung_VM__c ).contains( 'Potenzial 202' )
				|| lead.Bewertung_VM__c == 'Geeignet (in Bearbeitung)' )
				&& lead.DokumentationErstelltDatum__c != null
				&& lead.DokumentationDurchRTFreigebenDatum__c != null;
	}
	
	private Boolean isStandortdokuFreigegebenSTOG ( Lead lead ) {
		return lead.DokumentationDurchRTFreigebenDatum__c != null
				&& lead.Freigabe_STOG__c == 'Ja';
	}
	
	private Boolean isStandortdokuAbgelehnt ( Lead lead ) {
		return lead.DokumentationDurchRTFreigebenDatum__c != null
				&& ( lead.Freigabe_STOG__c == 'Nein - keine Freigabe STOG'
				|| lead.Freigabe_STOG__c == 'Nein - keine rechtzeitige Rückmeldung STOG'
				|| lead.Freigabe_STOG__c == 'Nein - Marktumbau <4Jahre'
				|| lead.Freigabe_STOG__c == 'Nein - keine Vermieterfreigabe' );
	}
	
	private Boolean isStandortdokuInWarteschleife ( Lead lead ) {
		return lead.Freigabe_STOG__c == 'Offen - Doku in Nachbesserung'
				|| lead.Freigabe_STOG__c == 'Offen - Zusage STOG ja; Eigentümerzustimmung offen';
	}
	
	private Boolean isBaufreigabeVorhanden ( Lead lead ) {
		return ( lead.Freigabe_STOG__c == 'Ja'
				|| lead.Freigabe_STOG__c == 'Offen - Doku in Nachbesserung'
				|| lead.Freigabe_STOG__c == null
				|| lead.Freigabe_STOG__c == 'Offen - Zusage STOG ja; Eigentümerzustimmung offen' )
				&& ( lead.Ergebnis_weit_Bauordnungsrechtl_Pruefung__c == 'Genehmigt'
				|| ( lead.Ergebnis_Bauordnungsrechtliche_Pruefung__c == 'Baugenehmigungsfrei, Amt'
				|| lead.Ergebnis_Bauordnungsrechtliche_Pruefung__c == 'Genehmigt'
				|| lead.Ergebnis_Bauordnungsrechtliche_Pruefung__c == 'Baugenehmigungsfrei, Netzmanager' ) );
	}
	
	private Boolean isBaufreigabeAbgelehnt ( Lead lead ) {
		return ( lead.Freigabe_STOG__c == 'Ja'
				|| lead.Freigabe_STOG__c == 'Offen - Doku in Nachbesserung'
				|| lead.Freigabe_STOG__c == null
				|| lead.Freigabe_STOG__c == 'Offen - Zusage STOG ja; Eigentümerzustimmung offen' )
				&& ( ( lead.Ergebnis_Bauordnungsrechtliche_Pruefung__c == 'Nicht baugenehmigungsfrei, Anfrage abgelehnt, Amt'
				|| lead.Ergebnis_Bauordnungsrechtliche_Pruefung__c == 'Nicht genehmigt' )
				|| lead.Ergebnis_weit_Bauordnungsrechtl_Pruefung__c == 'Nicht genehmigt' );
	}
	
	private Boolean isBaufreigabeInPruefung ( Lead lead ) {
		return ( lead.Freigabe_STOG__c == 'Ja'
				|| lead.Freigabe_STOG__c == 'Offen - Doku in Nachbesserung'
				|| lead.Freigabe_STOG__c == null
				|| lead.Freigabe_STOG__c == 'Offen - Zusage STOG ja; Eigentümerzustimmung offen' )
				&& lead.Bauordnungsrechtliche_Pruefung__c != null
				&& ( ( lead.Ergebnis_Bauordnungsrechtliche_Pruefung__c == null
				|| lead.Ergebnis_Bauordnungsrechtliche_Pruefung__c == 'Nicht baugenehmigungsfrei, Amt' )
				|| lead.Ergebnis_weit_Bauordnungsrechtl_Pruefung__c == null );
	}
	
	private Boolean isBaupruefungOffen ( Lead lead ) {
		return lead.DokumentationDurchRTFreigebenDatum__c != null
				&& lead.Freigabe_STOG__c == 'Ja'
				&& lead.Bauordnungsrechtliche_Pruefung__c == null
				&& ( Date ) lead.get( settingByClassifications.get( 'Freigabe STOG vorhanden, Bauprüfung offen' ).Feld__c )
				<= Date.today().addDays( -Integer.valueOf( settingByClassifications.get( 'Freigabe STOG vorhanden, Bauprüfung offen' ).Tage__c ) );
	}
	
	private Boolean isVertragAbgelehnt ( Lead lead ) {
		return lead.Vertrag_unterschrieben__c == 'Nein';
	}
	
	private Boolean isVertragUnterzeichnet ( Lead lead ) {
		return lead.Vertrag_unterschrieben__c == 'Ja'
				&& ( lead.Ergebnis_weit_Bauordnungsrechtl_Pruefung__c == 'Genehmigt'
				|| ( lead.Ergebnis_Bauordnungsrechtliche_Pruefung__c == 'Baugenehmigungsfrei, Amt'
				|| lead.Ergebnis_Bauordnungsrechtliche_Pruefung__c == 'Baugenehmigungsfrei, Netzmanager'
				|| lead.Ergebnis_Bauordnungsrechtliche_Pruefung__c == 'Genehmigt' ) );
	}
	
	private Boolean isVertragWartetAufFreigabe ( Lead lead ) {
		return lead.Vertrag_unterschrieben__c == null
				&& lead.Vertrag_versandt__c != null
				&& ( lead.Ergebnis_weit_Bauordnungsrechtl_Pruefung__c == 'Genehmigt'
				|| ( lead.Ergebnis_Bauordnungsrechtliche_Pruefung__c == 'Baugenehmigungsfrei, Amt'
				|| lead.Ergebnis_Bauordnungsrechtliche_Pruefung__c == 'Baugenehmigungsfrei, Netzmanager'
				|| lead.Ergebnis_Bauordnungsrechtliche_Pruefung__c == 'Genehmigt' ) );
	}
	
	private Boolean isVertragNochNichtVersendet ( Lead lead ) {
		return lead.Vertrag_versandt__c == null
				&& ( lead.Freigabe_STOG__c == 'Ja'
				|| lead.Freigabe_STOG__c == 'Offen - Doku in Nachbesserung'
				|| lead.Freigabe_STOG__c == null
				|| lead.Freigabe_STOG__c == 'Offen - Zusage STOG ja; Eigentümerzustimmung offen' )
				&& ( ( ( lead.Ergebnis_Bauordnungsrechtliche_Pruefung__c == 'Baugenehmigungsfrei, Amt'
				|| lead.Ergebnis_Bauordnungsrechtliche_Pruefung__c == 'Baugenehmigungsfrei, Netzmanager'
				|| lead.Ergebnis_Bauordnungsrechtliche_Pruefung__c == 'Genehmigt' )
				&& ( Date ) lead.get( settingByClassifications.get( 'Baufreigabe vorhanden, Vertrag noch nicht versendet_1' ).Feld__c )
				<= Date.today().addDays( -Integer.valueOf(
						settingByClassifications.get( 'Baufreigabe vorhanden, Vertrag noch nicht versendet_1' ).Tage__c ) ) )
				|| ( lead.Ergebnis_weit_Bauordnungsrechtl_Pruefung__c == 'Genehmigt'
				&& ( Date ) lead.get( settingByClassifications.get( 'Baufreigabe vorhanden, Vertrag noch nicht versendet_2' ).Feld__c )
				<= Date.today().addDays( -Integer.valueOf(
						settingByClassifications.get( 'Baufreigabe vorhanden, Vertrag noch nicht versendet_2' ).Tage__c ) ) ) );
	}
	
	private Boolean isVertragUnterzeichnetDPAG ( Lead lead ) {
		return lead.Vertrag_unterschrieben__c == 'Ja'
				&& lead.VertragVonVLUnterschriebenAm__c != null;
	}
	
	private Boolean isVertragWartetAufUnterzeichnungDPAG ( Lead lead ) {
		return lead.Vertrag_unterschrieben__c == 'Ja'
				&& lead.VertragVonVLUnterschriebenAm__c == null
				&& ( Date ) lead.get( settingByClassifications.get( 'Vertrag wartet auf Unterzeichnung (DPAG)' ).Feld__c )
				<= Date.today().addDays( -Integer.valueOf( settingByClassifications.get( 'Vertrag wartet auf Unterzeichnung (DPAG)' ).Tage__c ) );
	}
	
	private Boolean isUebergebenAnTeamBauen ( Lead lead ) {
		return lead.STO_disponiert__c != null;
	}
	
	private Boolean isBaucheckErfolgreich ( Lead lead ) {
		return lead.Baucheck_erfolgt_Datum__c != null
				&& lead.STO_disponiert__c != null;
	}
	
	private Boolean isUebergebenAnTeamLogistik ( Lead lead ) {
		return lead.Aufbaufaehig_ab_Datum__c != null
				&& lead.STO_disponiert__c != null
				&& lead.Baucheck_erfolgt_Datum__c != null
				&& lead.ist_disponiert__c;
	}
	
	private Boolean isPackstationAufgebaut ( Lead lead ) {
		return lead.AufstelldatumADM__c <= Date.today();
	}
	
	private Boolean isPackstationInBetrieb ( Lead lead ) {
		return lead.go_live__c <= Date.today();
	}
	
	private String returnEmptyIfNull ( String value ) {
		return value == null ? '' : value;
	}
}