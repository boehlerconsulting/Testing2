/**
 *@author       Mats Böhler
 *@created      28.04.2021
 *
 *
 *@description  EinrichtungsprozessBaseCtrl
 *
 *
 *@changelog    28.04.2021 Mats Böhler  - Created
 *              
 * 
 */
public with sharing virtual class EinrichtungsprozessBaseCtrl {
	
	@TestVisible
	protected Id recordId;
	protected Account account;
	@TestVisible
	protected Einrichtungsprozess__c process = null;
	protected Map<Id, List<Sektion__mdt>> sectionByScreenIds = new Map<Id, List<Sektion__mdt>>();
	protected Map<Id, List<Feld__mdt>> fieldsBySectionIds = new Map<Id, List<Feld__mdt>>();
	protected Map<Id, Fenster__mdt> fensterByIds = new Map<Id, Fenster__mdt>();
	protected List<Screen> screens = new List<Screen>();
	protected List<Step> steps = new List<Step>();
	protected Boolean isErsatzZusatz = false;
	protected Boolean isErsatz = false;
	protected Boolean isAbbau = false;
	protected Boolean hasPermission = FeatureManagement.checkPermission( 'SchreibrechteEinrichtungsprozess' );
	
	@AuraEnabled
	public static void saveFieldValue ( Id recordId, String fieldName, String dataType, String value ) {
		
		try {
			SObject sobj = recordId.getSobjectType().newSObject( recordId );
			if ( dataType == 'number' ) {
				
				sobj.put( fieldName, value == null || value.isWhitespace() ? null : Decimal.valueOf( value ) );
			}
			else if ( dataType == 'date' ) {
				
				sobj.put( fieldName, value == null || value.isWhitespace() ? null : Date.valueOf( value ) );
			}
			else if ( dataType == 'time' ) {
				sobj.put( fieldName, value == null || value.isWhitespace()
						? null
						: Time.newInstance( Integer.valueOf( value.split( ':' )[ 0 ] ) //hour
								, Integer.valueOf( value.split( ':' )[ 1 ] ) //min
								, 0                                //sec
								, 0 ) );
			}
			else {
				sobj.put( fieldName, value );
			}
			
			update sobj;
		}
		catch ( Exception e ) {
			
			throw new AuraHandledException( e.getMessage() );
		}
	}
	
	@AuraEnabled
	public static void resetFilialausstattung ( String accountId, String einrichtungsprozessId ) {
		Savepoint savepoint = Database.setSavepoint();
		try {
			List<Filialausstattung__c> filialausstattungs = [
					SELECT
							Id
					FROM Filialausstattung__c
					WHERE Filiale__c = :accountId
			];
			if ( !filialausstattungs.isEmpty() ) {
				delete filialausstattungs;
				Database.emptyRecycleBin( filialausstattungs );
				update new Einrichtungsprozess__c(
						Id = einrichtungsprozessId,
						initialisiert__c = false
				);
			}
		}
		catch ( Exception e ) {
			Database.rollback( savepoint );
			throw new AuraHandledException( e.getMessage() );
		}
	}
	
	protected List<Section> buildSections ( Fenster__mdt fenster ) {
		List<Section> sections = new List<Section>();
		for ( Sektion__mdt sektion : sectionByScreenIds.containsKey( fenster.Id )
				? sectionByScreenIds.get( fenster.Id )
				: new List<Sektion__mdt>() ) {
			sections.add(
					new Section(
							sektion.Titel__c,
							fieldsBySectionIds.containsKey( sektion.Id )
									? fieldsBySectionIds.get( sektion.Id )
									: new List<Feld__mdt>()
					)
			);
		}
		return sections;
	}
	
	protected void loadData () {
		Set<String> accountFields = new Set<String>();
		Set<String> einrichtungsprozessFields = new Set<String>();
		for ( Id sectionId : fieldsBySectionIds.keySet() ) {
			for ( Feld__mdt field : fieldsBySectionIds.get( sectionId ) ) {
				
				if ( field.Objektname__c == 'Account' ) {
					accountFields.add( field.Feldname__c );
				}
				if ( field.Objektname__c == 'Einrichtungsprozess__c' ) {
					einrichtungsprozessFields.add( field.Feldname__c );
				}
			}
		}
		accountFields.add( 'Anzahl_Schalter__c' );
		accountFields.add( 'RecordTypeId' );
		accountFields.add( 'RecordType.DeveloperName' );
		accountFields.add( 'FehlendeFactsOez__c' );
		loadRecord( 'Account', accountFields );
		loadRecord( 'Einrichtungsprozess__c', einrichtungsprozessFields );
		if ( accountFields.contains( 'AnzahlSchalter__c' ) ) {
			initializeAnzahlSchalter();
		}
		if ( account.Anzahl_Schalter__c != 0
				&& account.Anzahl_Schalter__c != null ) {
			account.AnzahlSchalter__c = account.Anzahl_Schalter__c;
		}
	}
	
	private void initializeAnzahlSchalter () {
		TriggerHandler.bypass( 'AccountTriggerHandler' );
		if ( account.AnzahlSchalter__c == null
				&& account.Anzahl_Schalter__c != null
				&& account.Anzahl_Schalter__c != 0 ) {
			account.AnzahlSchalter__c = account.Anzahl_Schalter__c;
			update account;
		}
		else if ( account.AnzahlSchalter__c == null ) {
			account.AnzahlSchalter__c = 1;
			update account;
		}
		else {
			//Sonarqube --> do nothing
		}
		TriggerHandler.clearBypass( 'AccountTriggerHandler' );
	}
	
	protected String getFieldsAsString ( Set<String> fieldSet ) {
		String fields = '';
		for ( String fieldName : fieldSet ) {
			fields += fieldName + ',';
		}
		fields = fields.removeEnd( ',' );
		return fields;
	}
	
	private void loadRecord ( String objectName, Set<String> fieldSet ) {
		
		String fields = getFieldsAsString( fieldSet );
		
		if ( objectName == 'Account' ) {
			initializeAccount( fields );
		}
		else if ( objectName == 'Einrichtungsprozess__c' ) {
			initializeEroeffnungsprozess( fields );
		}
		else {
			//Sonarqube --> do nothing
		}
	}
	
	protected virtual void initializeAccount ( String fields ) {
		
		account = loadAccount( fields );
	}
	
	protected void setEroeffnungsprozess ( String fields ) {
		
		List<Einrichtungsprozess__c> einrichtungsprozesses = loadEroeffnungsprozess( fields );
		process = ( einrichtungsprozesses.size() == 1 ) ? einrichtungsprozesses.get( 0 ) : null;
		if ( process == null ) {
			process = new Einrichtungsprozess__c(
					Filiale__c = recordId,
					IndexAktivesFenster__c = 0,
					Anfahrt_mit_LKW_moeglich__c = 'LKW bis 12t',
					Anfahrt_LWK_moeglich__c = 'LKW bis 12t',
					BA_Bohrfreigaben_erteilt__c = 'Ja'
			);
			insert process;
			process = loadEroeffnungsprozess( fields )[ 0 ];
		}
	}
	
	protected void setPhoneNumberVertriebsmanager () {
		if ( process.VertriebsmanagerTelefon__c != null && process.VertriebsmanagerMobil__c == null ) {
			process.VertriebsmanagerTelefon2__c = process.VertriebsmanagerTelefon__c;
		}
		else if ( process.VertriebsmanagerTelefon__c != null && process.VertriebsmanagerMobil__c != null ) {
			process.VertriebsmanagerTelefon2__c = process.VertriebsmanagerTelefon__c + ' oder ' + process.VertriebsmanagerMobil__c;
		}
		else if ( process.VertriebsmanagerTelefon__c == null && process.VertriebsmanagerMobil__c != null ) {
			process.VertriebsmanagerTelefon2__c = process.VertriebsmanagerMobil__c;
		}
		else {
			//Sonarqube -> do nothing
		}
	}
	
	protected void setPhoneNumberRegionalerVertriebssteuerer () {
		if ( process.RegionalerVertriebssteuererTelefon__c != null && process.RegionalerVertriebssteuererMobil__c == null ) {
			process.RegionalerVertriebssteuererTelefon2__c = process.RegionalerVertriebssteuererTelefon__c;
		}
		else if ( process.RegionalerVertriebssteuererTelefon__c != null && process.RegionalerVertriebssteuererMobil__c != null ) {
			process.RegionalerVertriebssteuererTelefon2__c =
					process.RegionalerVertriebssteuererTelefon__c + ' oder ' + process.RegionalerVertriebssteuererMobil__c;
		}
		else if ( process.RegionalerVertriebssteuererTelefon__c == null && process.RegionalerVertriebssteuererMobil__c != null ) {
			process.RegionalerVertriebssteuererTelefon2__c = process.RegionalerVertriebssteuererMobil__c;
		}
		else {
			//Sonarqube -> do nothing
		}
	}
	
	protected virtual void initializeEroeffnungsprozess ( String fields ) {
		setEroeffnungsprozess( fields );
		setPhoneNumberVertriebsmanager();
		setPhoneNumberRegionalerVertriebssteuerer();
		
		process.PostanschriftStrasse__c = process.PostanschriftStrasse__c == null
				? process.Filiale__r.ShippingStreet
				: process.PostanschriftStrasse__c;
		process.Postanschrift_Ort__c = process.Postanschrift_Ort__c == null
				? process.Filiale__r.ShippingCity
				: process.Postanschrift_Ort__c;
		process.Postanschrift_PLZ__c = process.Postanschrift_PLZ__c == null
				? process.Filiale__r.ShippingPostalCode
				: process.Postanschrift_PLZ__c;
		process.E_Mail_Adresse__c = process.E_Mail_Adresse__c == null
				? process.Filiale__r.Owner.Email
				: process.E_Mail_Adresse__c;
		if ( account.Filialtyp_OZ__c == '82' ) {
			process.Geschaeftsvorfall__c = 'Zusatz-/Ersatzbeschaffung';
		}
		update process;
	}
	
	protected Account loadAccount ( String fields ) {
		String accountId = recordId;
		String query = 'SELECT Id,'
				+ 'Mo_vm_von__c,' +
				'Mo_vm_bis__c,' +
				'Mo_nm_von__c,' +
				'Mo_nm_bis__c,' +
				'Di_vm_von__c,' +
				'Di_vm_bis__c,' +
				'Di_nm_von__c,' +
				'Di_nm_bis__c,' +
				'Mi_vm_von__c,' +
				'Mi_vm_bis__c,' +
				'Mi_nm_von__c,' +
				'Mi_nm_bis__c,' +
				'Do_vm_von__c,' +
				'Do_vm_bis__c,' +
				'Do_nm_von__c,' +
				'Do_nm_bis__c,' +
				'Fr_vm_von__c,' +
				'Fr_vm_bis__c,' +
				'Fr_nm_von__c,' +
				'Fr_nm_bis__c,' +
				'Sa_vm_von__c,' +
				'Sa_vm_bis__c,' +
				'Sa_nm_von__c,' +
				'Sa_nm_bis__c,' +
				'So_vm_von__c,' +
				'So_vm_bis__c,' +
				'So_nm_von__c,' +
				'So_nm_bis__c,' +
				'Mobil__c,' +
				'Filialtyp_OZ__c,' +
				'Vorgaengerfiliale__r.ShippingStreet,' +
				'Vorgaengerfiliale__r.ShippingPostalCode,' +
				'Vorgaengerfiliale__r.ShippingCity,' +
				'Vorgaengerfiliale__r.ASt_Name__c,' +
				'Vorgaengerfiliale__c,' +
				'Schliessung_zum__c,' +
				'Filialart__c,' +
				fields +
				' FROM Account ' +
				'WHERE Id = :accountId LIMIT 1';
		
		return Database.query( query );
	}
	
	protected List<Einrichtungsprozess__c> loadEroeffnungsprozess ( String fields ) {
		
		String accountId = recordId;
		String query = 'SELECT Id,'
				+ 'Filiale__c,' +
				+'Filiale__r.RecordTypeId,' +
				+'Filiale__r.FehlendeFactsOez__c,' +
				'Dokumentenversion__c,' +
				'IndexAktivesFenster__c,' +
				'VertriebsmanagerTelefon__c,' +
				'VertriebsmanagerMobil__c,' +
				'RegionalerVertriebssteuererTelefon__c,' +
				'RegionalerVertriebssteuererMobil__c,' +
				'Filiale__r.Owner.Email,' +
				'Filiale__r.ShippingStreet,' +
				'Filiale__r.ShippingCity,' +
				'Filiale__r.ShippingPostalCode,' +
				'Filiale__r.NL_Brief_Lookup__r.Aussenstellen_Ma__r.Name,' +
				'Filiale__r.NL_Brief_Lookup__r.Aussenstellen_Ma__r.Email,' +
				'Filiale__r.NL_Brief_Lookup__r.Aussenstellen_Ma__r.Phone,' +
				'Filiale__r.NL_Brief_Lookup__r.Aussenstellen_Ma__r.MobilePhone,' +
				'Variante__c,' +
				'Prozess__c,' +
				'VorgaengerfilialeExistiert__c,' +
				'AusstattungUebernahmeVorgaenger__c,' +
				'AbweichendeKostenstelle__c,' +
				'LieferantentextZusatz__c,' +
				'ProzessAbbau__c,' +
				'Kommentar_VM__c,' +
				'BegruendungNeubestellung__c,' +
				fields +
				' FROM Einrichtungsprozess__c ' +
				'WHERE Filiale__c = :accountId LIMIT 1';
		
		return Database.query( query );
	}
	
	protected virtual void initializeFieldMetadata () {
		for ( Feld__mdt feld : [
				SELECT
						Id,
						Nummerierung__c,
						Sektion__c,
						Objektname__c,
						Feldname__c,
						Feldtyp__c,
						ist_Formelfeld__c,
						Schreibschutz__c,
						Erforderlich__c,
						Ausblenden__c,
						Hilfetext__c,
						Spalte__c,
						Label__c,
						Maximale_Laenge__c,
						Bild__c
				FROM Feld__mdt
				WHERE Prozess__c = 'Einrichtungsprozess'
				AND Sektion__r.Fenster__r.DeveloperName != 'AuftragVerEntsorgungBriefPaket'
				ORDER BY Nummerierung__c ASC NULLS LAST
		] ) {
			
			if ( fieldsBySectionIds.containsKey( feld.Sektion__c ) ) {
				fieldsBySectionIds.get( feld.Sektion__c ).add( feld );
			}
			else {
				fieldsBySectionIds.put( feld.Sektion__c, new List<Feld__mdt> {
						feld
				} );
			}
		}
	}
	
	protected virtual void initializeSectionMetadata () {
		for ( Sektion__mdt sektion : [
				SELECT
						Id,
						Titel__c,
						Fenster__c,
						Nummerierung__c
				FROM Sektion__mdt
				WHERE Prozess__c = 'Einrichtungsprozess'
				AND Fenster__r.DeveloperName != 'AuftragVerEntsorgungBriefPaket'
				ORDER BY Nummerierung__c ASC NULLS LAST
		] ) {
			
			if ( sectionByScreenIds.containsKey( sektion.Fenster__c ) ) {
				sectionByScreenIds.get( sektion.Fenster__c ).add( sektion );
			}
			else {
				sectionByScreenIds.put( sektion.Fenster__c, new List<Sektion__mdt> {
						sektion
				} );
			}
		}
	}
	
	protected virtual void initializeScreenMetadata () {
		fensterByIds = new Map<Id, Fenster__mdt>( [
				SELECT
						Id,
						Titel__c,
						Nummerierung__c, (
						SELECT
								Id,
								Nummerierung__c,
								Titel__c,
								Dokument__r.Visualforce_Page__c,
								Datentyp__c,
								ist_Vorschau__c
						FROM Schaltflaechen__r
						ORDER BY Nummerierung__c ASC NULLS LAST
				)
				FROM Fenster__mdt
				WHERE Prozess__c = 'Einrichtungsprozess'
				AND DeveloperName != 'AuftragVerEntsorgungBriefPaket'
				ORDER BY Nummerierung__c ASC NULLS LAST
		] );
	}
	
	protected virtual void buildScreens () {
		for ( Fenster__mdt fenster : fensterByIds.values() ) {
			screens.add(
					new Screen(
							fenster.Titel__c,
							buildSections( fenster ),
							fenster.Id
					)
			);
			steps.add(
					new Step(
							fenster.Titel__c,
							'open',
							fenster.Id,
							false
					)
			);
		}
		if ( isErsatzZusatz ) {
			screens.add(
					new Screen(
							'Bestellung Filialausstattung - ' + getErsatzValue(),
							new List<Section>(),
							null
					)
			);
			steps.add(
					new Step(
							'Bestellung Filialausstattung - ' + getErsatzValue(),
							'open',
							null,
							false
					)
			);
		}
		else if ( isAbbau ) {
			screens.add(
					new Screen(
							'Abbau Filialausstattung',
							new List<Section>(),
							null
					)
			);
			steps.add(
					new Step(
							'Abbau Filialausstattung',
							'open',
							null,
							false
					)
			);
		}
		else {
			screens.add(
					new Screen(
							'Bestellung Filialausstattung - Übernahme aus Vorgängerfiliale',
							new List<Section>(),
							null
					)
			);
			steps.add(
					new Step(
							'Bestellung Filialausstattung - Übernahme aus Vorgängerfiliale',
							'open',
							null,
							false
					)
			);
			screens.add(
					new Screen(
							'Bestellung Filialausstattung - Neubestellung',
							new List<Section>(),
							null
					)
			);
			steps.add(
					new Step(
							'Bestellung Filialausstattung - Neubestellung',
							'open',
							null,
							false
					)
			);
		}
	}
	
	private String getErsatzValue () {
		return isErsatz ? 'Ersatz' : 'Zusatz';
	}
	
	public class Screen {
		private String title;
		private Id key;
		private List<Section> sections;
		
		public Screen ( String title, List<Section> sections, Id key ) {
			this.title = title;
			this.sections = sections;
			this.key = key;
		}
	}
	
	public class Section {
		private String title;
		private List<Field> fields;
		
		public Section ( String title, List<Feld__mdt> fields ) {
			this.title = title;
			List<Field> feldWrappers = new List<Field>();
			if ( fields != null ) {
				for ( Feld__mdt feld : fields ) {
					feldWrappers.add( new Field( feld ) );
				}
				feldWrappers.sort();
			}
			this.fields = feldWrappers;
		}
	}
	
	public class Field implements Comparable {
		
		public Decimal numbering { get; set; }
		public Boolean isFormula { get; set; }
		public Boolean isReadOnly { get; set; }
		public Boolean isRequired { get; set; }
		public Boolean isHidden { get; set; }
		public String fieldName { get; set; }
		public String fieldType { get; set; }
		public String helptext { get; set; }
		public String objectName { get; set; }
		public String column { get; set; }
		public String label { get; set; }
		public String value { get; set; }
		public String pictureId { get; set; }
		public Decimal maximumLength { get; set; }
		public List<PicklistValueEntry> picklistValues { get; set; }
		
		public Field ( Feld__mdt field ) {
			this.numbering = field.Nummerierung__c;
			this.isFormula = field.ist_Formelfeld__c;
			this.isReadOnly = field.Schreibschutz__c;
			this.isRequired = field.Erforderlich__c;
			this.isHidden = field.Ausblenden__c;
			this.fieldName = field.Feldname__c;
			this.fieldType = field.Feldtyp__c;
			this.helptext = field.Hilfetext__c;
			this.objectName = field.Objektname__c;
			this.column = field.Spalte__c;
			this.label = field.Label__c;
			this.maximumLength = field.Maximale_Laenge__c;
			this.pictureId = field.Bild__c;
			if ( field.Feldtyp__c == 'picklist' ) {
				this.picklistValues = getPicklistFieldValues( field.Objektname__c, field.Feldname__c, field.Erforderlich__c );
			}
		}
		
		public Integer compareTo ( Object obj ) {
			Field field = ( Field ) ( obj );
			
			if ( this.numbering > field.numbering ) {
				return 1;
			}
			
			if ( this.numbering == field.numbering ) {
				return 0;
			}
			
			return -1;
		}
		
		private List<PicklistValueEntry> getPicklistFieldValues ( String objectName, String pickListFieldName, Boolean isRequired ) {
			SObjectType objectType = Schema.getGlobalDescribe().get( objectName );
			List<PicklistValueEntry> picklistValueEntries = new List<PicklistValueEntry>();
			if ( !isRequired ) {
				picklistValueEntries.add( new PicklistValueEntry( '', '' ) );
			}
			for ( Schema.PicklistEntry picklistValue : objectType.getDescribe()
					.fields.getMap()
					.get( pickListFieldName )
					.getDescribe().getPicklistValues() ) {
				picklistValueEntries.add(
						new PicklistValueEntry( picklistValue.getLabel(), picklistValue.getValue() )
				);
			}
			return picklistValueEntries;
		}
	}
	
	public class PicklistValueEntry {
		private String label;
		private String value;
		
		public PicklistValueEntry ( String label, String value ) {
			this.label = label;
			this.value = value;
		}
	}
	
	public class Step {
		
		private String label;
		private String status;
		private String value;
		private Id key;
		private Boolean isLocked;
		
		public Step ( String label, String status, Id key, Boolean isLocked ) {
			this.label = label;
			this.value = label;
			this.status = status;
			this.key = key;
			this.isLocked = isLocked;
		}
	}
}