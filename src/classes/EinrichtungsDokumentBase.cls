/**
 *@author       Mats Böhler
 *@created      28.04.2021
 *
 *
 *@description  EinrichtungsDokumentBase
 *
 *
 *@changelog    28.04.2021 Mats Böhler  - Created
 *              
 * 
 */
public with sharing virtual class EinrichtungsDokumentBase {
	
	protected String QUERY_FIELDS = 'Id,' +
			'Name,' +
			'Produktoption__c,' +
			'Produktbuendel__c,' +
			'Produktoption__r.Nummerierung__c,' +
			'Produkt__r.Lagerprodukt__c,' +
			'Produkt__r.Family,' +
			'Produkt__r.Description,' +
			'Produkt__r.Zusatzinformationen__c,' +
			'Produkt__r.GetBotKategorie__c,' +
			'Produkt__r.ProductCode,' +
			'Produkt__r.Lieferant__c,' +
			'Produkt__r.Name,' +
			'Menge__c,' +
			'Menge_Abbau__c,' +
			'Menge_Wiedereinsatzfaehig__c,' +
			'BestandVorgaengerfiliale__c,' +
			'ErsatzFuer__r.Name,' +
			'Produktbuendeloption__c';
	
	protected Einrichtungsprozess__c einrichtungsprozess = null;
	protected PageReference currentPage = null;
	protected String process = '';
	protected Id talendUserId = InterfaceUser.getInstance().getId();
	protected Map<String, List<Filialausstattung__c>> produktoptionenByCategories = new Map<String, List<Filialausstattung__c>>();
	protected Map<String, Filialausstattung__c> productOptionByOptionId = new Map<String, Filialausstattung__c>();
	
	public List<Category> categories { get; set; }
	
	public virtual Einrichtungsprozess__c getRecord () {
		return einrichtungsprozess;
	}
	
	public virtual Date getTermin () {
		return einrichtungsprozess.Filiale__r.Eroeffnungsdatum__c == null
				? Date.today()
				: einrichtungsprozess.Filiale__r.Eroeffnungsdatum__c.addDays( -7 );
	}
	
	public virtual String getWunschlieferuhrzeit () {
		if ( einrichtungsprozess.Wunschlieferuhrzeit__c == null ) {
			return '';
		}
		String minutes = String.valueOf( einrichtungsprozess.Wunschlieferuhrzeit__c.minute() ) == '0'
				&& String.valueOf( einrichtungsprozess.Wunschlieferuhrzeit__c.minute() ).length() == 1
				? String.valueOf( einrichtungsprozess.Wunschlieferuhrzeit__c.minute() ) + '0'
				: String.valueOf( einrichtungsprozess.Wunschlieferuhrzeit__c.minute() );
		return einrichtungsprozess.Wunschlieferuhrzeit__c != null
				? einrichtungsprozess.Wunschlieferuhrzeit__c.hour()
						+ ':'
						+ minutes + ' Uhr'
				: '';
	}
	
	public void saveAsFile ( List<Id> recordIds ) {
		saveDocument( recordIds );
	}
	
	public virtual String getSheetName () {
		String sheetName = 'Tabelle1';
		sheetName = sheetName.left( 31 );
		return
				'<!--[if gte mso 9]>' +
						'<xml>' +
						'<x:ExcelWorkbook>' +
						'<x:ExcelWorksheets>' +
						'<x:ExcelWorksheet>' +
						'<x:Name>' + sheetName + '</x:Name>' +
						'<x:WorksheetOptions>' +
						'<x:ProtectContents>False</x:ProtectContents>' +
						'<x:ProtectObjects>False</x:ProtectObjects>' +
						'<x:ProtectScenarios>False</x:ProtectScenarios>' +
						'</x:WorksheetOptions>' +
						'</x:ExcelWorksheet>' +
						'</x:ExcelWorksheets>' +
						'</x:ExcelWorkbook>' +
						'</xml>' +
						'<![endif]-->';
	}
	
	public virtual String getContentType () {
		return 'application/vnd.ms-excel#' + '\"' + getFileNameWithExtension() + '\"';
	}
	
	protected virtual String getFileNameWithExtension () {
		return FileNameReplacer.replace( getFileName() + getFileExtension() );
	}
	
	@TestVisible
	protected virtual String getFileName () {
		return '_'
				+ einrichtungsprozess.Filiale__r.ASt_Name__c;
	}
	
	protected virtual String getFileExtension () {
		return '.xls';
	}
	
	@TestVisible
	protected virtual void initialize () {
		loadData();
	}
	
	protected void loadData () {
		einrichtungsprozess = [
				SELECT
						Filiale__r.Name,
						Filiale__r.Branche_FACTS__c,
						Filiale__r.Mo_vm_von__c,
						Filiale__r.Mo_vm_bis__c,
						Filiale__r.Mo_nm_von__c,
						Filiale__r.Mo_nm_bis__c,
						Filiale__r.Di_vm_von__c,
						Filiale__r.Di_vm_bis__c,
						Filiale__r.Di_nm_von__c,
						Filiale__r.Di_nm_bis__c,
						Filiale__r.Mi_vm_von__c,
						Filiale__r.Mi_vm_bis__c,
						Filiale__r.Mi_nm_von__c,
						Filiale__r.Mi_nm_bis__c,
						Filiale__r.Do_vm_von__c,
						Filiale__r.Do_vm_bis__c,
						Filiale__r.Do_nm_von__c,
						Filiale__r.Do_nm_bis__c,
						Filiale__r.Fr_vm_von__c,
						Filiale__r.Fr_vm_bis__c,
						Filiale__r.Fr_nm_von__c,
						Filiale__r.Fr_nm_bis__c,
						Filiale__r.Sa_vm_von__c,
						Filiale__r.Sa_vm_bis__c,
						Filiale__r.Sa_nm_von__c,
						Filiale__r.Sa_nm_bis__c,
						Filiale__r.So_vm_von__c,
						Filiale__r.So_vm_bis__c,
						Filiale__r.So_nm_von__c,
						Filiale__r.So_nm_bis__c,
						Filiale__r.Briefausgabe__c,
						Filiale__r.Paketausgabe__c,
						Filiale__r.Kapazitaet_Paketannahme__c,
						Filiale__r.Kapazitaet_Paketausgabe__c,
						Anfahrt_mit_LKW_moeglich__c,
						Filiale_im_Einkaufszentrum__c,
						Etage_der_Postfiliale_ggf_Lage__c,
						Fussgaengerzone__c,
						EinschraenkungenFussgaengerzone__c,
						Halteverbote__c,
						EinschraenkungenHalteverbote__c,
						Markttage__c,
						EinschraenkungenMarkttage__c,
						RampeVorhanden__c,
						HubladebuehneErforderlich__c,
						WeitereBesonderheiten__c,
						GenehmigungenErforderlich__c,
						ErforderlicheGenehmigungen__c,
						StufenVorhanden__c,
						AnzahlStufen__c,
						AnlieferungUeberAufzug__c,
						AngabeMasseTragkraftUndZugaenglichkeit__c,
						PaketrollbehaelterEinsatzMoeglich__c,
						AnzahlStellmoeglichkeiten__c,
						BriefbehaelterwagenEinsatzMoeglich__c,
						AnzahlBriefbehaelterwagen__c,
						Paketrollbehaelter__c,
						Briefbehaelterwagen__c,
						BriefbehaelterGroesse1__c,
						BriefbehaelterGroesse2__c,
						BriefbehaelterGroesse3__c,
						PostanschriftStrasse__c,
						Postanschrift_PLZ__c,
						Postanschrift_Ort__c,
						E_Mail_Adresse__c,
						Filiale__r.NL_Brief__c,
						SchleuseVorhanden__c,
						TransportDurchKundenbereich__c,
						Deckel__c,
						Eingriffschuetzer__c,
						Trennwaende__c,
						TrennwaendeBriefbehaelterwagen__c,
						Id,
						Filiale__c,
						Filiale__r.ASt_ID__c,
						Filiale__r.ASt_Nummer__c,
						Filiale__r.ASt_Name__c,
						Filiale__r.Filialtyp_OZ__c,
						Filiale__r.Vertriebssegment__c,
						Filiale__r.AnzahlSchalter__c,
						Filiale__r.ASt_Id_Vorgaengerfiliale__c,
						Filiale__r.ShippingCity,
						Filiale__r.ShippingPostalCode,
						Filiale__r.ShippingStreet,
						Filiale__r.Debitor__c,
						Filiale__r.Eroeffnungsdatum__c,
						Geschaeftsvorfall__c,
						Wunschliefertermin__c,
						Wunschlieferuhrzeit__c,
						LieferantentextZusatz__c,
						AbweichendeKostenstelle__c,
						Filiale__r.GL_Name__c,
						Filiale__r.Owner.Name,
						Filiale__r.Owner.Phone,
						Filiale__r.Owner.MobilePhone,
						Filiale__r.Owner.Email,
						Filiale__r.GL__r.Koordinator__r.Name,
						Filiale__r.GL__r.Koordinator__r.Phone,
						Filiale__r.GL__r.Koordinator__r.MobilePhone,
						Filiale__r.GL__r.Koordinator__r.Email,
						Filiale__r.NL_Brief_Lookup__r.Koordinator__r.Name,
						Filiale__r.NL_Brief_Lookup__r.Koordinator__r.Phone,
						Filiale__r.NL_Brief_Lookup__r.Koordinator__r.MobilePhone,
						Filiale__r.NL_Brief_Lookup__r.Koordinator__r.Email,
						Einrichtungskoordinator_Name__c,
						Einrichtungskoordinator_Telefon__c,
						Einrichtungskoordinator_E_Mail__c,
						Filiale__r.Phone,
						Filiale__r.Kontaktperson_Vertragspartner__c,
						Filiale__r.Telefon_Vertragspartner__c,
						Filiale__r.Mobil__c,
						Filiale__r.E_Mail_Vertragspartner__c,
						Ansprechpartner_fuer_Einrichtung_Name__c,
						Ansprechpartner_fuer_Einrichtung_Telefo__c,
						Ansprechpartner_fuer_Einrichtung_E_Mail__c,
						Aussenstelle__c,
						Filiale__r.Aussenkennzeichnung__c,
						Ladengeschaeft_bereits_am_Netz__c,
						Montag__c,
						Dienstag__c,
						Mittwoch__c,
						Donnerstag__c,
						Freitag__c,
						Abweichende_Lieferanschrift__c,
						Lieferanschrift__c,
						Anfahrt_LWK_moeglich__c,
						BA_Filiale_im_Einkaufszentrum__c,
						BA_Etage_der_Postfiliale_ggf_Lage__c,
						BA_Fu_g_ngerzone__c,
						BA_Einschr_nkungen_Fu_g_ngerzone__c,
						BA_Halteverbote__c,
						BA_Einschr_nkungen_Halteverbote__c,
						BA_Markttage__c,
						BA_Einschr_nkungen_Markttage__c,
						BA_Rampe_vorhanden__c,
						BA_Hubladeb_hne_erforderlich__c,
						BA_WeitereBesonderheiten__c,
						BA_Genehmigungen_erforderlich__c,
						BA_Erforderliche_Genehmigungen__c,
						BA_Stufen_vorhanden__c,
						BA_AnzahlStufen__c,
						BA_Anlieferung_ber_Aufzug__c,
						BA_Angabe_Ma_e_Tragkraft_und_Zug_nglich__c,
						BA_Anzahl_der_zu_durchfahrenden_T_ren__c,
						BA_Geringste_T_rbreite_zur_Anlieferung_F__c,
						BA_Geringste_Gangbreite_zur_Anlieferung__c,
						BA_Geringste_Raumh_he_am_M_belstandort__c,
						BA_Besonderheiten_zum_Fu_boden__c,
						BA_Montageh_he_der_Au_enkennzeichnung_i__c,
						BA_Besonderheiten_Fassade_z_B_D_mmung__c,
						BA_Bohrfreigaben_erteilt__c,
						BA_Befestigung_Wertschutzschrank__c,
						Filiale__r.Schliessung_zum__c,
						Lagerstandort__c,
						Filiale__r.RecordTypeId,
						Filiale__r.FehlendeFactsOez__c
				FROM Einrichtungsprozess__c
				WHERE Id = :currentPage.getParameters().get( 'id' )
				LIMIT 1
		];
	}
	
	protected void saveDocument ( List<Id> recordIds ) {
		// Vorgänger Versionen holen
		Set<Id> contentDocumentIds = new Set<Id>();
		Id linkedEntityId = recordIds[ 0 ];
		List<ContentDocumentLink> contentDocumentLinks = [
				SELECT ContentDocumentId
				FROM ContentDocumentLink
				WHERE LinkedEntityId = :linkedEntityId
		];
		for ( ContentDocumentLink contentDocumentLink : contentDocumentLinks ) {
			contentDocumentIds.add( contentDocumentLink.ContentDocumentId );
		}
		
		List<ContentVersion> contentVersions = [
				SELECT ContentDocumentId
				FROM ContentVersion
				WHERE ContentDocumentId IN :contentDocumentIds
				AND PathOnClient = :getFileNameWithExtension()
				LIMIT 1
		];
		
		// Neue Dateiversion anlegen
		ContentVersion contentVersion = new ContentVersion();
		contentVersion.Title = FileNameReplacer.replace( getFileName() );
		contentVersion.PathOnClient = getFileNameWithExtension();
		contentVersion.VersionData = getContent( currentPage );
		contentVersion.ContentLocation = 'S';
		contentVersion.ContentDocumentId = contentVersions.isEmpty() ? null : contentVersions[ 0 ].ContentDocumentId;
		insert contentVersion;
		
		Id contentDocumentId = contentVersions.isEmpty()
				? [
						SELECT
								ContentDocumentId
						FROM ContentVersion
						WHERE Id = :contentVersion.Id
				].ContentDocumentId
				: contentVersions[ 0 ].ContentDocumentId;
		
		contentDocumentLinks = new List<ContentDocumentLink>();
		for ( Id recordId : recordIds ) {
			if ( recordId != null ) {
				// Dokument an das Objekt hängen
				ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
				contentDocumentLink.ContentDocumentId = contentDocumentId;
				contentDocumentLink.LinkedEntityId = recordId;
				contentDocumentLink.ShareType = 'I';
				contentDocumentLink.Visibility = 'AllUsers';
				contentDocumentLinks.add( contentDocumentLink );
			}
		}
		contentDocumentLinks.add( createContentDocumentLinkTalendUser( contentDocumentId ) );
		List<Database.SaveResult> saveResults = Database.insert( contentDocumentLinks, false );
		for ( Database.SaveResult saveResult : saveResults ) {
			if ( !saveResult.isSuccess()
					&& !saveResult.getErrors()[ 0 ].getMessage().toLowerCase().contains( 'already linked' )
					&& !saveResult.getErrors()[ 0 ].getMessage().toLowerCase().contains( 'ist bereits mit der entität mit folgender id verknüpft' ) ) {
				Database.Error error = saveResult.getErrors()[ 0 ];
				throw new EinrichtungsDokumentBaseException( error.getStatusCode() + ': ' + error.getMessage() );
			}
		}
	}
	
	private Blob getContent ( PageReference po_Page ) {
		if ( Test.isRunningTest() ) {
			return Blob.valueOf( 'Test Content' );
		}
		return po_Page.getContent();
	}
	
	private ContentDocumentLink createContentDocumentLinkTalendUser ( Id contentDocumentId ) {
		ContentDocumentLink cdl = new ContentDocumentLink();
		cdl.ContentDocumentId = contentDocumentId;
		cdl.LinkedEntityId = talendUserId;
		cdl.ShareType = 'V';
		cdl.Visibility = 'AllUsers';
		return cdl;
	}
	
	protected void addOption ( Filialausstattung__c option ) {
		if ( produktoptionenByCategories.containsKey( option.Produkt__r.Family ) ) {
			produktoptionenByCategories.get( option.Produkt__r.Family ).add( option );
		}
		else {
			produktoptionenByCategories.put( option.Produkt__r.Family, new List<Filialausstattung__c> {
					option
			} );
		}
		productOptionByOptionId.put( option.Produktoption__c, option );
	}
	
	protected List<Filialausstattung__c> loadFirstLevelProducts ( String query ) {
		Id accountId = einrichtungsprozess.Filiale__c;
		return Database.query( query );
	}
	
	public class EinrichtungsDokumentBaseException extends Exception {
	}
	
	public class Category {
		public String title { get; set; }
		public List<Option> products { get; set; }
		
		public Category ( String title ) {
			this.title = title;
			this.products = new List<Option>();
		}
	}
	
	public class Option {
		
		public Filialausstattung__c product { get; set; }
		public Decimal price { get; set; }
		public Boolean hasOptions { get; set; }
		public List<Option> options { get; set; }
		
		public Option ( Filialausstattung__c product ) {
			
			this.product = product;
			this.price = price;
			this.options = new List<Option>();
			this.hasOptions = false;
		}
		
		public Option ( Filialausstattung__c product, Decimal price ) {
			
			this.product = product;
			this.price = price;
			this.options = new List<Option>();
			this.hasOptions = false;
		}
	}
}