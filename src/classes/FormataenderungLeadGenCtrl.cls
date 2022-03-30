/**
 * @author      Stefan Richter (stefan.richter@hundw.de)
 *              H+W CONSULT GmbH
 *              Bahnhofstr. 3
 *              21244 Buchholz i. d. Nordheide
 *              Germany
 *              https://www.hundw.de
 *
 * @description class for <insert-description-here>
 *
 * TIMELINE
 * 31.03.21      Stefan Richter  Initial release.
 **/
public with sharing class FormataenderungLeadGenCtrl {
	
	@AuraEnabled
	public static Id generateLead ( Id fnaeId ) {
		try {
			
			Id leadId;
			
			Filialnetzaenderung__c fnae = HW_SharedVertragsUtils.getFnae( fnaeId );
			
			String errors = FormataenderungLeadGenCtrl.canGenerateLead( fnae );
			
			errors = FormataenderungLeadGenCtrl.hasExistingLead( fnae, errors );
			
			if ( String.isEmpty( errors ) ) {
				
				if ( fnae != null ) {
					
					Filialnetzaenderung__c fnaeComplete =
							( Filialnetzaenderung__c ) HW_SharedVertragsUtils.queryAllFields(
									'Filialnetzaenderung__c',
									fnaeId,
									'Id'
							);
					
					if ( fnaeComplete.Filiale_Filialpartner__c != null ) {
						
						Account filialpartnerComplete =
								( Account ) HW_SharedVertragsUtils.queryAllFields(
										'Account',
										fnaeComplete.Filiale_Filialpartner__c,
										'Id',
										'GL__r.Leiter__r.Name,GL__r.Name,Betreiber__r.Name'
								);
						Contract partnerContractComplete =
								( Contract ) HW_SharedVertragsUtils.queryAllFields(
										'Contract',
										fnaeComplete.Filiale_Filialpartner__c,
										'AccountId'
								);
						
						leadId = createLeadForFnae( fnae, filialpartnerComplete );
						
						//INIT SDS
						HW_Stammdatensammler_LC po_Ctrl = new HW_Stammdatensammler_LC();
						po_Ctrl.callInitializeStammdatensammler( leadId );
						
						//MYPM-1129
						prefillSDS( leadId, filialpartnerComplete, fnaeComplete, partnerContractComplete );
					}
				}
			}
			else {
				NoAccessException naEx = new NoAccessException();
				if ( errors.contains( 'HASLEAD' ) ) {
					naEx.setMessage( 'Es existiert schon ein Lead für die Formatänderung. ' +
							'Wenn Sie neu mit der Erfassung beginnen möchten, wenden Sie ' +
							'sich bitte an das Supportpostfach myPM@deutschepost.de ' +
							'mit der Angabe der FNAE.' );
				}
				else {
					naEx.setMessage( 'Bedingungen für die Lead- Generierung sind nicht erfüllt. Bitte prüfen Sie die Felder: ' + errors );
				}
				throw naEx;
			}
			
			return leadId;
		
		}
		catch ( Exception e ) {
			throw new AuraHandledException( 'Lead konnte nicht erstellt werden. ' + e.getMessage() );
		}
	}
	
	private static void prefillSDS (
			Id leadId,
			Account filialpartnerComplete,
			Filialnetzaenderung__c fnaeComplete,
			Contract partnerContractComplete ) {
		
		Contract contr = [
				SELECT Id,
						Name,
						Filialtyp__c,
						Lead__r.Filialnetzaenderung__c
				FROM Contract
				WHERE Lead__c = :leadId
		];
		
		//MYPM-1129 do partwise preselection here
		if ( contr.Lead__r.Filialnetzaenderung__c != null ) {
			
			mapFnaeContractFields( contr, filialpartnerComplete, fnaeComplete, partnerContractComplete );
		
		}
	}
	
	private static void setAusgabeBrief ( Filialnetzaenderung__c fnaeComplete, Contract contr ) {
		if ( !String.isEmpty( fnaeComplete.Auftrag_Briefausgabe__c ) ) {
			if ( fnaeComplete.Auftrag_Briefausgabe__c.equals( 'mit Briefausgabe' ) ) {
				contr.Ausgabe_Brief__c = 'Ja';
			}
			
			if ( fnaeComplete.Auftrag_Briefausgabe__c.equals( 'ohne Briefausgabe' ) ) {
				contr.Ausgabe_Brief__c = 'Nein';
			}
			
			if ( fnaeComplete.Auftrag_Briefausgabe__c.equals( 'wie bisher' )
					&& fnaeComplete.Briefausgabe__c == true ) {
				contr.Ausgabe_Brief__c = 'Ja';
			}
			else {
				contr.Ausgabe_Brief__c = 'Nein';
			}
		}
	}
	
	private static void mapFnaeContractFields (
			Contract contr,
			Account filialpartnerComplete,
			Filialnetzaenderung__c fnaeComplete,
			Contract partnerContractComplete ) {
		
		contr.Formataenderung__c = true;
		setFromAccount( contr, filialpartnerComplete, fnaeComplete );
		setFromContract( contr, partnerContractComplete );
		
		if ( fnaeComplete.Wunschformat__c == 'Partner-Filiale (OZ 79)' ) {
			contr.Filialtyp__c = '79';
			contr.Annahme_Express_Inter__c = 'Ja';
		}
		
		if ( fnaeComplete.Wunschformat__c == 'Partner-Filiale (OZ 84)' ) {
			contr.Filialtyp__c = '84';
			contr.Annahme_Express_Inter__c = 'Nein';
		}
		
		if ( fnaeComplete.Wunschformat__c == 'Partner-Filiale (OZ 95)' ) {
			contr.Filialtyp__c = '95';
			contr.Annahme_Express_Inter__c = 'Ja';
		}
		
		
		contr.X2_Unterzeichner_Berechtigung__c = 'i. A.';
		contr.Nachtragsvereinbarung_ab__c = fnaeComplete.Schliessung_avisiert_fuer__c;
		
		contr.Verkauf_Brief__c = 'Ja';
		contr.Annahme_Brief__c = 'Ja';
		setAusgabeBrief( fnaeComplete, contr );
		
		if ( !String.isEmpty( fnaeComplete.mit_Postfachanlage__c )
				&& fnaeComplete.mit_Postfachanlage__c.equals( 'mit Postfach' ) ) {
			contr.Postfach__c = 'Ja';
		}
		else {
			contr.Postfach__c = 'Nein';
			contr.BezeichnungderPFA__c = '-';
			contr.PLZderPFA__c = '-';
		}
		
		contr.Verkauf_Paket__c = 'Ja';
		contr.Annahme_Paket__c = 'Ja';
		contr.Verkauf_Express__c = 'Ja';
		contr.Annahme_Express_National__c = 'Ja';
		
		contr.TerminderAenderung__c = fnaeComplete.Schliessung_avisiert_fuer__c;
		contr.ArtderAenderung__c = 'Neueinrichtung mit vorheriger Schließung einer Filiale';
		
		contr.SchliessungsgrundderzuschlFiliale__c = 'Umwandlung';
		contr.FluktuationsgrundderzuschlFiliale__c = 'KEINE FLUKTUATION!!!';
		
		contr.Anschriftstyp__c = 'Standardanschriftentyp ist "Korrespondenz"';
		
		contr.LeistungsfelderPBS__c = 'Nein';
		contr.AnnahmeServicePRIO__c = 'Ja';
		contr.Aenderungsgrund__c = 'Betreiberwechsel';
		contr.FilialeamgleichenStandort__c = 'Ja';
		contr.Betreiber__c = 'Partner Filiale';
		contr.PostfilialeDirekt__c = 'Ja';
		contr.Zustellabrechnungsart__c = 'keine Zuordnung';
		contr.Anlieferungssteuerung__c = 'Nein';
		contr.AnzderneuenKassen__c = 1;
		contr.KassenartderneuenKasse__c = 'ZORA-Kasse';
		contr.ErstelldatumMAEF__c = Date.today();
		contr.EinrichtungMOPS__c = 'Nein';
		contr.RegelInterim__c = 'Regel';
		contr.GrundausstattungFormblaetter__c = 'Ja';
		contr.LieferungzusaetzlFormblaetter__c = 'Nein';
		contr.InterimsfilialeaufangemieteterFlaeche__c = 'Nein';
		
		contr.DatumAntragstellung1__c = Date.today();
		contr.BMA_ohne_Betreuung__c = 'Nein';
		
		contr.SchliessungsdatumVorgaengerfiliale__c = fnaeComplete.Schliessung_avisiert_fuer__c;
		contr.EroeffnungsgrunddereroeffnendenFiliale__c = 'Sonstiges';
		
		update contr;
	}
	
	private static String getValue ( SObject filialpartnerComplete, String fieldName ) {
		return filialpartnerComplete.get( fieldName ) != null ? 'Ja' : 'Nein';
	}
	
	private static void setFromAccount ( Contract contr, Account filialpartnerComplete, Filialnetzaenderung__c fnaeComplete ) {
		if ( filialpartnerComplete == null ) {
			return;
		}
		contr.Kette1__c = filialpartnerComplete.Kette__c != null ? filialpartnerComplete.Kette__c : null;
		contr.Anz_Datenendgeraet_ZORA__c = filialpartnerComplete.Anzahl_Schalter__c;
		contr.Name = filialpartnerComplete.ASt_Name__c;
		contr.ShippingStreet = filialpartnerComplete.ShippingStreet;
		contr.ShippingPostalCode = filialpartnerComplete.ShippingPostalCode;
		contr.ShippingCity = filialpartnerComplete.ShippingCity;
		contr.X1_Unterzeichner_Name__c = filialpartnerComplete.GL__r.Leiter__r.Name;
		contr.Strasse_Korrespondenzanschrift__c = filialpartnerComplete.Strasse__c;
		contr.StrassederschliessendeFiliale__c = filialpartnerComplete.Strasse__c;
		contr.PLZderschliessendeFiliale__c = filialpartnerComplete.ShippingPostalCode;
		contr.OrtderschliessendeFiliale__c = filialpartnerComplete.ShippingCity;
		contr.DebitorderschliessendeFiliale__c = filialpartnerComplete.Debitor__c;
		contr.AStNrderschliessendeFiliale__c = filialpartnerComplete.ASt_Nummer__c;
		contr.WaWiKundennrderschliessendeFiliale__c = filialpartnerComplete.WaWi_Nummer__c;
		contr.PostfachderschliessendeFiliale__c = filialpartnerComplete.PostfachanlageCheckbox__c ? 'Ja' : 'Nein';
		contr.PostfachBetreiberderschliessFiliale__c = filialpartnerComplete.Postfach_Betreiber__c;
		contr.AusgabePaketderschliessendeFiliale__c = getValue( filialpartnerComplete, 'Paketausgabe__c' );
		contr.AusgabeBriefderschliessendeFiliale__c = getValue( filialpartnerComplete, 'Briefausgabe__c' );
		contr.PostfilialeDirektderschliessFiliale__c = getValue( filialpartnerComplete, 'Postfilialnummer__c' );
		contr.BriefkastenvorhandenschliessFiliale__c = getValue( filialpartnerComplete, 'Briefkasten__c' );
		contr.KundennummerExpressschliessendeFiliale__c = filialpartnerComplete.DHL_Express_Int__c;
		contr.PoPSvomVorgaengeruebernehmen__c = filialpartnerComplete.PoPS_Kunde_aktiviert__c == true ? 'Ja' : 'Nein';
		contr.Strasse_Korrespondenzanschrift__c = filialpartnerComplete.Strasse__c;
		contr.BezeichnungNameGeschaeftslokal__c = filialpartnerComplete.Aussenkennzeichnung__c;
		
		if ( filialpartnerComplete.Paketausgabe__c == true ) {
			contr.Ausgabe_Express__c = 'Ja';
		}
		else {
			contr.Ausgabe_Express__c = 'Nein';
		}
		
		if ( filialpartnerComplete.Wartepunktsaeule_Stk__c != null
				&& filialpartnerComplete.Wartepunktsaeule_Stk__c > 0 ) {
			contr.Vertragsanbahnung__c = 'Ja';
			contr.Kontaktanbahnung__c = 'Ja';
			contr.Werbung_Sampling__c = 'Ja';
		}
		else {
			contr.Vertragsanbahnung__c = 'Nein';
			contr.Kontaktanbahnung__c = 'Nein';
			contr.Werbung_Sampling__c = 'Nein';
		}
		contr.PostfachanlageVorhanden__c = fnaeComplete.mit_Postfachanlage__c == 'mit Postfach';
		setContractFields( contr, filialpartnerComplete );
	}
	
	private static void setContractFields ( Contract contr, Account filialpartnerComplete ) {
		contr.Hausnummer_Korrespondenzanschrift__c = filialpartnerComplete.Filiale_Hausnummer__c;
		contr.Land_PLZ_Ort_Korrespondenzanschrift__c = 'Deutschland '
				+ filialpartnerComplete.ShippingPostalcode + ' '
				+ filialpartnerComplete.ShippingCity;
		contr.BMA__c = filialpartnerComplete.Briefmarkenautomat__c != null
				? Decimal.valueOf( filialpartnerComplete.Briefmarkenautomat__c )
				: null;
		contr.GAA__c = filialpartnerComplete.Anzahl_GAA__c;
		contr.KAD__c = filialpartnerComplete.Anzahl_KAD__c;
		contr.Anz_BBA__c = filialpartnerComplete.Anzahl_BBA__c;
		contr.BMA_mit_Betreuung__c = filialpartnerComplete.Briefmarkenautomat__c != null
				? ( Decimal.valueOf( filialpartnerComplete.Briefmarkenautomat__c ) > 0 ? 'Ja' : 'Nein' )
				: null;
		contr.Anz_Kassenlade_zeitverzoegert__c = filialpartnerComplete.Anzahl_Schalter__c;
		contr.Anz_Wartepunktsaule__c = filialpartnerComplete.Wartepunktsaeule_Stk__c;
		contr.Anz_Wertgelass__c = filialpartnerComplete.Anzahl_Schalter__c;
		contr.AstIDderzuschlFiliale__c = filialpartnerComplete.ASt_ID__c;
		contr.MengeKapazitaetPaketausgabe__c = filialpartnerComplete.Kapazitaet_Paketausgabe__c != null
				? Decimal.valueOf( filialpartnerComplete.Kapazitaet_Paketausgabe__c )
				: null;
		contr.MengeKapazitaetPaketannahme__c = filialpartnerComplete.Kapazitaet_Paketannahme__c != null
				? Decimal.valueOf( filialpartnerComplete.Kapazitaet_Paketannahme__c )
				: null;
		contr.HausnummerderschliessendeFiliale__c = filialpartnerComplete.Filiale_Hausnummer__c;
		contr.VertragsbetreuendeEinheit__c = filialpartnerComplete.GL__r.Name;
		contr.BriefkastenamStandort__c = filialpartnerComplete.Briefkasten__c;
		
		if ( filialpartnerComplete.Filialtyp_OZ__c.equals( '84' ) ) {
			contr.FiltypOZderschliessendeFiliale__c = '84 Partner-Filiale';
		}
		
		if ( filialpartnerComplete.Filialtyp_OZ__c.equals( '79' ) ) {
			contr.FiltypOZderschliessendeFiliale__c = '79 Partner-Filiale o. FDL';
		}
		
		if ( filialpartnerComplete.Filialtyp_OZ__c.equals( '95' ) ) {
			contr.FiltypOZderschliessendeFiliale__c = '95 Partner-Filiale';
		}
	}
	
	private static void setFromContract ( Contract contr, Contract partnerContractComplete ) {
		if ( partnerContractComplete == null ) {
			return;
		}
		contr.Paketbox__c = partnerContractComplete.Paketbox__c;
		contr.Kundenbildschirm__c = partnerContractComplete.Kundenbildschirm__c;
		contr.Anz_Paketbox__c = partnerContractComplete.Anz_Paketbox__c;
		contr.X1_Sonstiger_Kundenautomat_Anzahl__c = partnerContractComplete.X1_Sonstiger_Kundenautomat_Anzahl__c;
		contr.X1_Sonstiger_Kundenautomat_Name__c = partnerContractComplete.X1_Sonstiger_Kundenautomat_Name__c;
		contr.X2_Sonstiger_Kundenautomat_Anzahl__c = partnerContractComplete.X2_Sonstiger_Kundenautomat_Anzahl__c;
		contr.X2_Sonstiger_Kundenautomat_Name__c = partnerContractComplete.X2_Sonstiger_Kundenautomat_Name__c;
		contr.Gefahrenmeldeanlage_GMA__c = partnerContractComplete.Gefahrenmeldeanlage_GMA__c;
		contr.Anz_GMA__c = partnerContractComplete.Anz_GMA__c;
		contr.Sicherheitsbehaeltnis__c = partnerContractComplete.Sicherheitsbehaeltnis__c;
		contr.Anz_Sicherheitsbehaeltnis__c = partnerContractComplete.Anz_Sicherheitsbehaeltnis__c;
		contr.Zusatzterminal__c = partnerContractComplete.Zusatzterminal__c;
		contr.FilialILN1__c = partnerContractComplete.FilialILN1__c != null ? partnerContractComplete.FilialILN1__c : '';
		contr.Branche2__c = partnerContractComplete.Branche2__c;
		contr.Branche3__c = partnerContractComplete.Branche3__c;
		contr.ErweiterteFilialinformationen__c = partnerContractComplete.ErweiterteFilialinformationen__c;
		contr.Immobiliengeber__c = partnerContractComplete.Immobiliengeber__c;
		contr.Lieferant1__c = partnerContractComplete.Lieferant1__c;
		contr.Lieferant2__c = partnerContractComplete.Lieferant2__c;
		contr.Franchisegeber__c = partnerContractComplete.Franchisegeber__c;
		contr.Gesellschafter1__c = partnerContractComplete.Gesellschafter1__c;
		contr.Gesellschafter2__c = partnerContractComplete.Gesellschafter2__c;
		contr.Vermittler__c = partnerContractComplete.Vermittler__c;
		contr.EinrichtungsliniegrThekenfront__c = partnerContractComplete.EinrichtungsliniegrThekenfront__c;
		contr.EinrichtungsliniegelbeThekenfront__c = partnerContractComplete.EinrichtungsliniegelbeThekenfront__c;
		contr.MarkenschauplakatDINA2__c = partnerContractComplete.MarkenschauplakatDINA2__c;
		contr.AnzDINA2einseitigKundenraum__c = partnerContractComplete.AnzDINA2einseitigKundenraum__c;
		contr.AnzDINA2zweiseitigKundenraum__c = partnerContractComplete.AnzDINA2zweiseitigKundenraum__c;
		contr.AnzDINA1einseitigKundenraum__c = partnerContractComplete.AnzDINA1einseitigKundenraum__c;
		contr.AnzDINA1zweiseitigKundenraum__c = partnerContractComplete.AnzDINA1zweiseitigKundenraum__c;
		contr.AnzBackOfficePlakatsenkrecht__c = partnerContractComplete.AnzBackOfficePlakatsenkrecht__c;
		contr.AnzBackOffPlakatGrSwaag__c = partnerContractComplete.AnzBackOffPlakatGrSwaag__c;
		contr.AnzBackOffPlakatGrMwaag__c = partnerContractComplete.AnzBackOffPlakatGrMwaag__c;
		contr.AnzBackOffPlakatGrLwaag__c = partnerContractComplete.AnzBackOffPlakatGrLwaag__c;
		contr.AnzBockstaenderDINA2Vorderseite__c = partnerContractComplete.AnzBockstaenderDINA2Vorderseite__c;
		contr.AnzBockstaenderDINA2Rueckseite__c = partnerContractComplete.AnzBockstaenderDINA2Rueckseite__c;
		contr.AnzAufkleberProdukteIPreise__c = partnerContractComplete.AnzAufkleberProdukteIPreise__c;
		contr.AnzPflichtProdnatlIintnatl__c = partnerContractComplete.AnzPflichtProdnatlIintnatl__c;
		contr.AnzPflichtProdnatlInatl__c = partnerContractComplete.AnzPflichtProdnatlInatl__c;
		contr.AnzMarkenband__c = partnerContractComplete.AnzMarkenband__c;
		contr.AnzAngebotstafel__c = partnerContractComplete.AnzAngebotstafel__c;
		contr.AnzDHLBote__c = partnerContractComplete.AnzDHLBote__c;
		contr.AnzPostZustellerin__c = partnerContractComplete.AnzPostZustellerin__c;
		contr.AnzThekenaufkleber__c = partnerContractComplete.AnzThekenaufkleber__c;
		contr.AnzBroschuerenschuette16er__c = partnerContractComplete.AnzBroschuerenschuette16er__c;
		contr.AnzBroschuerenschuette8er__c = partnerContractComplete.AnzBroschuerenschuette8er__c;
		contr.AnzHandzettelschuetteDinA4__c = partnerContractComplete.AnzHandzettelschuetteDinA4__c;
		contr.Anz3erFlyerschuettequer__c = partnerContractComplete.Anz3erFlyerschuettequer__c;
		contr.AnzBodenaufstellerklein__c = partnerContractComplete.AnzBodenaufstellerklein__c;
		contr.AnzPlakatBodenaufstellerklein1__c = partnerContractComplete.AnzPlakatBodenaufstellerklein1__c;
		contr.AnzPlakatBodenaufstellerklein__c = partnerContractComplete.AnzPlakatBodenaufstellerklein__c;
		contr.AnzPlakatLAufsteller__c = partnerContractComplete.AnzPlakatLAufsteller__c;
		contr.AnzThekenFrontdisplayeValue__c = partnerContractComplete.AnzThekenFrontdisplayeValue__c;
		contr.AnzWarenregalOZ84__c = partnerContractComplete.AnzWarenregalOZ84__c;
		contr.AnzDiskretionsstelePacksets__c = partnerContractComplete.AnzDiskretionsstelePacksets__c;
		contr.Anz_Verkaufsdisplay__c = partnerContractComplete.Anz_Verkaufsdisplay__c;
		contr.BezeichnungderPFA__c = partnerContractComplete.BezeichnungderPFA__c;
		contr.PLZderPFA__c = partnerContractComplete.PLZderPFA__c;
		contr.AusgabebenPostfachSendungen__c = partnerContractComplete.AusgabebenPostfachSendungen__c;
		contr.AusgabepostlagernderSendungen__c = partnerContractComplete.AusgabepostlagernderSendungen__c;
		contr.BereitstSchluesselSendungsaustausch__c = partnerContractComplete.BereitstSchluesselSendungsaustausch__c;
		contr.bergabeortEntsorgungBriefIPaketsdg__c = partnerContractComplete.bergabeortEntsorgungBriefIPaketsdg__c;
		contr.bergabepunktbenBriefsendungen__c = partnerContractComplete.bergabepunktbenBriefsendungen__c;
		contr.bergabepunktbenPaketsendungen__c = partnerContractComplete.bergabepunktbenPaketsendungen__c;
		contr.bergabepunktPostfachsendungen__c = partnerContractComplete.bergabepunktPostfachsendungen__c;
		contr.GeschaeftsbereichPaket__c = partnerContractComplete.GeschaeftsbereichPaket__c;
		contr.ZustellbasisPaket__c = partnerContractComplete.ZustellbasisPaket__c;
		contr.GeschaeftskundenFiliale__c = partnerContractComplete.GeschaeftskundenFiliale__c;
		contr.BehindertengerechterZugangzurFiliale__c = partnerContractComplete.BehindertengerechterZugangzurFiliale__c;
		contr.Kundentelefonvorhanden__c = partnerContractComplete.Kundentelefonvorhanden__c;
		contr.LagedesStandortes__c = partnerContractComplete.LagedesStandortes__c;
		contr.ArtdesParkplatzes__c = partnerContractComplete.ArtdesParkplatzes__c;
		contr.LagedesParkplatz__c = partnerContractComplete.LagedesParkplatz__c;
		contr.AnzentgeltfreierParkplaetze__c = partnerContractComplete.AnzentgeltfreierParkplaetze__c;
		contr.AnzentgeltpflichtigerParkplaetze__c = partnerContractComplete.AnzentgeltpflichtigerParkplaetze__c;
		contr.EntgeltfreieParkplaetze__c = partnerContractComplete.EntgeltfreieParkplaetze__c;
		contr.Schrankevorhanden__c = partnerContractComplete.Schrankevorhanden__c;
		contr.Tagesstempel1__c = partnerContractComplete.Tagesstempel1__c;
		contr.Postfachschrank__c = partnerContractComplete.Postfachschrank__c;
		contr.PartnerILN__c = partnerContractComplete.PartnerILN__c;
		contr.FilialILN__c = partnerContractComplete.FilialILN__c;
		contr.ErgHinweiszumStandort__c = partnerContractComplete.ErgHinweiszumStandort__c;
		contr.SonstigeInformationen__c = partnerContractComplete.SonstigeInformationen__c;
	}
	
	private static Id createLeadForFnae ( Filialnetzaenderung__c fnae, Account filialpartnerComplete ) {
		try {
			
			Date today = Date.today();
			
			Lead ld = new Lead(
					Formataenderung__c = true,
					Filialnetzaenderung__c = fnae.Id,
					RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get( 'Kaltakquise' ).getRecordTypeId(),
					Status = 'Vertragsverhandlung',
					Email = filialpartnerComplete.E_Mail_Vertragspartner__c,
					Phone = filialpartnerComplete.Phone,
					Name_Ansprechpartner__c = filialpartnerComplete.Betreiber__c,
					Weitere_Telefonnummer__c = filialpartnerComplete.Telefon_Vertragspartner__c,
					Company = filialpartnerComplete.Name,
					FirstName = filialpartnerComplete.X1_Ansprechpartner_Vorname__c,
					VL__c = HW_SharedVertragsUtils.getUserOrgeDpDummyAccountId( fnae.VGL__c ),
					City = filialpartnerComplete.ShippingCity,
					Street = filialpartnerComplete.ShippingStreet,
					PostalCode = filialpartnerComplete.ShippingPostalCode,
					Country = filialpartnerComplete.ShippingCountry,
					Interesse_an__c = 'Partner-Filiale',
					Bewerbung_vom__c = today,
					LeadSource = 'VL',
					Bewertung_3500__c = 'Zur Bewertung freigegeben',
					Bewertung_Zentrale__c = 'Sofortiger Ersatz für',
					Bewertung_Zentrale_vom__c = today,
					Erstkontakt__c = today,
					Unternehmen_aus_bevorzugter_Branche__c = 'Ja',
					Erscheinungsbild_in_Ordnung__c = 'Ja',
					Warenbestand_in_Ordnung__c = 'Ja',
					OEZ_Urlaubsvertretung__c = 'Ja',
					Persoenliche_Eignung__c = 'Ja',
					Zustimmung_zur_Bonitaetspruefung__c = 'Ja',
					Bewertung_VM__c = 'Geeignet',
					Bewertung_VM_vom__c = today,
					Erledigungsdatum_Interessent__c = today,
					Hausnummer__c = filialpartnerComplete.Filiale_Hausnummer__c,
					Ortsteil__c = filialpartnerComplete.Ortsteil_Postanschrift__c,
					Fax = filialpartnerComplete.Fax,
					Rechtsform__c = filialpartnerComplete.Rechtsform__c,
					JuristischerName__c = filialpartnerComplete.Juristischer_Name_Gewerbeanmeldung__c
			);
			
			if ( filialpartnerComplete.Lead_Vorname__c != null && filialpartnerComplete.Lead_Nachname__c != null ) {
				ld.FirstName = filialpartnerComplete.Lead_Vorname__c;
				ld.LastName = filialpartnerComplete.Lead_Nachname__c;
			}
			else {
				ld.FirstName = '';
				ld.LastName = filialpartnerComplete.Name;
			}
			
			
			insert ld;
			return ld.Id;
		
		}
		catch ( Exception ex ) {
			throw ex;
		}
	}

	public static String canGenerateLead ( Filialnetzaenderung__c fnae ) {
		
		String errorFields = '';
		
		if ( fnae.Filiale_Filialpartner__c != null
				&& ( ( fnae.Filiale_Filialpartner__r.Filialtyp_OZ__c == '82' && fnae.Filiale_Filialpartner__r.Filialart__c == 'DHL-Paketshop' )
				|| fnae.Filiale_Filialpartner__r.Filialtyp_OZ__c == '84'
				|| fnae.Filiale_Filialpartner__r.Filialtyp_OZ__c == '79'
				|| fnae.Filiale_Filialpartner__r.Filialtyp_OZ__c == '95' ) ) {
			//all good
		}
		else {
			errorFields = errorFields + 'Filialart/-typ-OZ, ';
		}
		
		if ( fnae.Grund__c != 'Formatänderung' ) {
			errorFields = errorFields + 'Änderungsgrund, ';
		}
		
		if ( fnae.Erledigungsdatum_FNAE__c != null ) {
			errorFields = errorFields + 'Erledigungsdatum FNÄ, ';
		}
		
		if ( fnae.Netzentscheidung__c == 'Formatänderung genehmigt'
				|| fnae.Netzentscheidung__c == 'Upgrade OZ 82 in Partner-Filiale OZ 79'
				|| fnae.Netzentscheidung__c == 'Upgrade OZ 82 in Partner-Filiale OZ 84' ) {
			//all good
		}
		else {
			errorFields = errorFields + 'Netzentscheidung, ';
		}
		
		errorFields = !String.isEmpty( errorFields ) ? errorFields.removeEnd( ', ' ).trim() : errorFields;
		
		return errorFields;
	}
	
	public static String hasExistingLead ( Filialnetzaenderung__c fnae, String errors ) {
		List<Lead> existingLeads = [ SELECT Id FROM Lead WHERE Filialnetzaenderung__c = :fnae.Id AND Formataenderung__c = true LIMIT 1 ];
		if ( existingLeads != null && !existingLeads.isEmpty() ) {
			errors = errors + 'HASLEAD';
		}
		
		return errors;
	}

}