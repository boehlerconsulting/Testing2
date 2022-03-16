/**
 * HW_Stammdatensammler_LC
 *
 *
 * @changelog    04.03.2019 Mats Böhler - Created
 *
 * @author Mats Böhler
@created      04.03.2019
@version      1.0
@since        45.0
 */
public without sharing class HW_Stammdatensammler_LC {
	
	private static Boolean isFormataenderungAutoGen = false;
	
	private State io_State = new State();
	private Id iv_RecordId;
	private String iv_SObjectName;
	private Boolean lv_FirstDataLoad;
	private Boolean isExistingMAEF = false;
	private Map<Id, List<Sektion__mdt>> im_SectionsByScreenId;
	private Map<Id, List<Feld__mdt>> im_FieldsBySectionId;
	private List<Stammdatensammler__c> il_ProgressStates;
	private Map<String, List<Oeffnungszeiten__c>> im_OeffnungszeitensByKategorie = new Map<String, List<Oeffnungszeiten__c>>();
	private Map<String, List<DokumentPflichtfeld__mdt>> pflichtfelderByDocumentVisualforceName
			= new Map<String, List<DokumentPflichtfeld__mdt>>();
	private Map<String, List<DokumentPflichtdokument__mdt>> pflichtdokumenteByDocumentVisualforceName
			= new Map<String, List<DokumentPflichtdokument__mdt>>();
	private Map<String, DokumentPflichtfeld__mdt> pflichtfeldByDeveloperName = new Map<String, DokumentPflichtfeld__mdt>();
	private Lead lead = new Lead();
	
	@AuraEnabled
	public static String loadData ( Id recordId, Boolean isExistingMAEF ) {
		HW_Stammdatensammler_LC po_Ctrl = new HW_Stammdatensammler_LC();
		po_Ctrl.lv_FirstDataLoad = false;
		po_Ctrl.isExistingMAEF = isExistingMAEF;
		po_Ctrl.iv_RecordId = recordId;
		
		if ( po_Ctrl.isExistingMAEF ) {
			po_Ctrl.initializeExistingMAEF( recordId );
		}
		else {
			po_Ctrl.initializeStammdatensammler( recordId );
		}
		return po_Ctrl.lv_FirstDataLoad ? null : JSON.serialize( po_Ctrl.io_State );
	}
	
	@AuraEnabled
	public static void saveDocument ( String recordId, String visualforceName, String dataType ) {
		Savepoint savepoint = Database.setSavepoint();
		try {
			PageReference pageReference = getPage( visualforceName );
			pageReference.getParameters().put( 'id', recordId );
			pageReference.getParameters().put( 'output', dataType );
			new HW_Document_C( pageReference ).save();
			if ( visualforceName == 'HW_FACTS_Stammdatenbeleg' ) {
				PageReference einverstaendniserklaerung = getPage( 'HW_Einverstaendniserklaerung' );
				einverstaendniserklaerung.getParameters().put( 'id', recordId );
				einverstaendniserklaerung.getParameters().put( 'output', 'PDF' );
				new HW_Document_C( einverstaendniserklaerung ).save();
			}
			if ( visualforceName == 'HW_MAEF' ) {
				PageReference zusatzinfoMaterial = getPage( 'HW_Zusatzinfo_Material' );
				zusatzinfoMaterial.getParameters().put( 'id', recordId );
				zusatzinfoMaterial.getParameters().put( 'output', 'excel' );
				new HW_Document_C( zusatzinfoMaterial ).save();
			}
		}
		catch ( Exception e ) {
			Database.rollback( savepoint );
			throw new AuraHandledException( e.getMessage() );
		}
	}
	
	@AuraEnabled(Cacheable=true)
	public static String getDocumentUrl ( String recordId, String visualforceName, String dataType ) {
		PageReference pageReference = getPage( visualforceName );
		pageReference.getParameters().put( 'id', recordId );
		pageReference.getParameters().put( 'output', dataType );
		return pageReference.getUrl();
	}
	
	@AuraEnabled
	public static Boolean resetFirstRunHelper ( String contractString ) {
		Contract con = ( Contract ) JSON.deserialize( contractString, Contract.class );
		//MYPM-1130
		con.SDS_Helper_FirstRun__c = false;
		update con;
		return con.SDS_Helper_FirstRun__c;
	}
	
	private static PageReference getPage ( String visualforceName ) {
		PageReference pageReference = null;
		switch on visualforceName {
			when 'HW_Einverstaendniserklaerung' {
				pageReference = Page.HW_Einverstaendniserklaerung;
			}
			when 'HW_FACTS_Stammdatenbeleg' {
				pageReference = Page.HW_FACTS_Stammdatenbeleg;
			}
			when 'HW_MAEF' {
				pageReference = Page.HW_MAEF;
			}
			when 'HW_MAEF_Filiale_existiert' {
				pageReference = Page.HW_MAEF_Filiale_existiert;
			}
			when 'HW_Postbankanfrage' {
				pageReference = Page.HW_Postbankanfrage;
			}
			when 'HW_SAP_Debitoren_beantragen' {
				pageReference = Page.HW_SAP_Debitoren_beantragen;
			}
			when 'HW_SAP_Neuanlage' {
				pageReference = Page.HW_SAP_Neuanlage;
			}
			when 'HW_Selbstauskunft' {
				pageReference = Page.HW_Selbstauskunft;
			}
			when 'HW_Vertragsdokument' {
				pageReference = Page.HW_Vertragsdokument;
			}
			when 'HW_Zusatzinfo_Material_ALT' {
				pageReference = Page.HW_Zusatzinfo_Material_ALT;
			}
			when 'HW_Zusatzinfo_Material' {
				pageReference = Page.HW_Zusatzinfo_Material;
			}
			when 'HW_Zusatzinfo_Material_Filiale_existiert' {
				pageReference = Page.HW_Zusatzinfo_Material_Filiale_existiert;
			}
			when 'HW_Zuverlaessigkeitspruefung' {
				pageReference = Page.HW_Zuverlaessigkeitspruefung;
			}
			when else {
				//Sonarqube --> do nothing
			}
		}
		return pageReference;
	}
	
	@AuraEnabled
	public static String getMAEFUrl ( Boolean isPreview, String accountString, String contractString ) {
		HW_MaefWrapper wrapper = new HW_MaefWrapper();
		wrapper.account = ( Account ) JSON.deserialize( accountString, Account.class );
		wrapper.contract = ( Contract ) JSON.deserialize( contractString, Contract.class );
		update new Account(
				Id = wrapper.account.Id,
				MAEF_Zwischenspeicher__c = JSON.serialize( wrapper )
		);
		PageReference pageReference = Page.HW_MAEF_Filiale_existiert;
		pageReference.getParameters().put( 'id', wrapper.account.Id );
		pageReference.getParameters().put( 'output', 'excel' );
		if ( isPreview ) {
			return pageReference.getUrl();
		}
		else {
			new HW_Document_C( pageReference ).saveExistingMAEF();
			return pageReference.getUrl();
		}
	}
	
	private void initializeExistingMAEF ( Id recordId ) {
		OrgE_DP__c lo_OrgE_DP = null;
		iv_RecordId = recordId;
		iv_SObjectName = String.valueOf( recordId.getSobjectType() );
		buildScreens();
		io_State.io_SObject = loadAccount( lo_OrgE_DP );
		io_State.io_Contract = loadContract();
	}
	
	/**
	 * MYPM-1130 used from HwStammdatensammlerLoader
	 *
	 * @param recordId the lead id from lwc flexipage
	 *
	 * @return true if the sds was allready initialized
	 **/
	@AuraEnabled
	public static Boolean isSDSInitialized ( Id recordId ) {
		Lead lo_Lead = loadLead( recordId );
		if ( lo_Lead.SDS_initialisiert__c ) {
			return true;
		}
		return false;
	}
	
	//init from outside
	public void callInitializeStammdatensammler ( Id pv_RecordId ) {
		this.lv_FirstDataLoad = true;
		this.initializeStammdatensammler( pv_RecordId );
	}
	
	private void initializeStammdatensammler ( Id pv_RecordId ) {
		
		OrgE_DP__c lo_OrgE_DP = null;
		if ( String.valueOf( pv_RecordId.getSobjectType() ) == 'Lead' ) {
			lead = loadLead( pv_RecordId );
			if ( !lead.SDS_initialisiert__c ) {
				lv_FirstDataLoad = true;
				if ( lead.VL__c == null ) {
					List<OrgE_DP__c> ll_OrgEDPS = [
							SELECT
									Id,
									Werksnummer_Debitor_I__c,
									OrgE_DP_Name__c
							FROM OrgE_DP__c
							WHERE OrgE_Koordinator__c = :[
									SELECT
											Id,
											OrgE_DP__c
									FROM User
									WHERE Id = :UserInfo.getUserId()
							].OrgE_DP__c
					];
					lo_OrgE_DP = ( ll_OrgEDPS.size() == 1 ) ? ll_OrgEDPS.get( 0 ) : null;
				}
				
				lead.SDS_initialisiert__c = true;
				update lead;
			}
		}
		
		iv_RecordId = pv_RecordId;
		iv_SObjectName = String.valueOf( pv_RecordId.getSobjectType() );
		setIsFormataenderung();
		buildScreens();
		io_State.io_SObject = loadAccount( lo_OrgE_DP );
		loadProgressStates();
		if ( il_ProgressStates.size() == 0 ) {
			insertProgressStates();
		}
		buildSteps();
		setOeffnungszeiten();
		io_State.io_Contract = loadContract();
	}
	
	private void setIsFormataenderung () {
		if ( iv_SObjectName == 'Lead' ) {
			HW_Stammdatensammler_LC.isFormataenderungAutoGen = lead.Formataenderung__c;
		}
		else {
			HW_Stammdatensammler_LC.isFormataenderungAutoGen = [
					SELECT
							Id,
							Lead__r.Formataenderung__c
					FROM Account
					WHERE Id = :iv_RecordId
					LIMIT 1
			].Lead__r.Formataenderung__c;
		}
	}
	
	private static Lead loadLead ( Id pv_LeadId ) {
		return [
				SELECT
						Id,
						Formataenderung__c,
						SDS_initialisiert__c,
						VL__c,
						VL__r.GL__r.Werksnummer_Debitor_I__c
				FROM Lead
				WHERE Id = :pv_LeadId
		];
	}
	
	@AuraEnabled
	public static void saveSteps ( String pv_Steps ) {
		
		List<Step> ll_Steps = ( List<Step> ) JSON.deserialize( pv_Steps, List<Step>.class );
		List<Stammdatensammler__c> ll_ProgressSteps = new List<Stammdatensammler__c>();
		
		for ( Step lo_Step : ll_Steps ) {
			ll_ProgressSteps.add(
					new Stammdatensammler__c(
							Id = lo_Step.iv_Id,
							Status__c = lo_Step.iv_Status,
							Gesperrt__c = lo_Step.iv_IsLocked
					)
			);
		}
		
		update ll_ProgressSteps;
	}
	
	@AuraEnabled
	public static String saveSObject (
			String po_SObject,
			List<String> pl_FormulaFieldNamesSObject,
			List<String> pl_FormulaFieldNamesContract,
			Id pv_AccountId ) {
		SObject sobj = ( SObject ) JSON.deserialize( po_SObject, SObject.class );
		update sobj;
		if ( sobj.Id.getSobjectType().getDescribe().getName() == 'Account'
				&& ( String ) sobj.get( 'ASt_ID__c' ) != ( String ) sobj.get( 'ASt_ID_SDS__c' ) ) {
			
			updateAstID( pv_AccountId, ( String ) sobj.get( 'ASt_ID_SDS__c' ) );
		}
		return reloadFormulaFields( pv_AccountId, pl_FormulaFieldNamesSObject, pl_FormulaFieldNamesContract );
	}
	
	private static void updateAstID ( Id accountId, String value ) {
		TriggerHandler.bypass( 'AccountTriggerHandler' );
		Database.update(
				new Account(
						Id = accountId,
						ASt_ID__c = value ),
				false
		);
		TriggerHandler.clearBypass( 'AccountTriggerHandler' );
	}
	
	@AuraEnabled
	public static String validateAstId ( Id recordId ) {
		Account account = [
				SELECT
						Id,
						ASt_ID__c,
						ASt_ID_SDS__c
				FROM Account
				WHERE Id = :recordId OR Lead__c = :recordId
				LIMIT 1
		];
		return account.ASt_ID__c == account.ASt_ID_SDS__c ? '' : account.ASt_ID_SDS__c;
	}
	
	@AuraEnabled
	public static void saveOeffnungszeiten ( String po_SObjects ) {
		List<Oeffnungszeiten__c> lo_Oeffnungszeiten =
				( List<Oeffnungszeiten__c> ) JSON.deserialize( po_SObjects, List<Oeffnungszeiten__c>.class );
		update lo_Oeffnungszeiten;
	}
	
	private static String reloadFormulaFields (
			Id pv_RecordId,
			List<String> pl_FormulaFieldNamesSObject,
			List<String> pl_FormulaFieldNamesContract ) {
		
		State lo_State = new State();
		
		if ( pl_FormulaFieldNamesSObject.size() > 0 ) {
			String lv_SObjectFields = '';
			Set<String> ls_FormulaFieldNamesSObject = new Set<String>();
			ls_FormulaFieldNamesSObject.addAll( pl_FormulaFieldNamesSObject );
			for ( String lv_FieldName : ls_FormulaFieldNamesSObject ) {
				lv_SObjectFields += lv_FieldName + ',';
			}
			lv_SObjectFields = lv_SObjectFields.removeEnd( ',' );
			
			String lv_SObjectQuery = 'SELECT ' + lv_SObjectFields
					+ ' FROM Account WHERE Id = \'' + pv_RecordId + '\' LIMIT 1';
			lo_State.io_SObject = ( Account ) Database.query( lv_SObjectQuery )[ 0 ];
		}
		
		if ( pl_FormulaFieldNamesContract.size() > 0 ) {
			String lv_ContractFields = '';
			Set<String> ls_FormulaFieldNamesContract = new Set<String>();
			ls_FormulaFieldNamesContract.addAll( pl_FormulaFieldNamesContract );
			List<String> fieldNames = new List<String>( Contract.getSObjectType().getDescribe().fields.getMap().keySet() );
			for ( String lv_FieldName : fieldNames ) {
				lv_ContractFields += lv_FieldName + ',';
			
			}
			lv_ContractFields = lv_ContractFields.removeEnd( ',' );
			
			String lv_RelatedObject = 'AccountId';
			String lv_ContractQuery = 'SELECT ' + lv_ContractFields
					+ ' FROM Contract WHERE '
					+ lv_RelatedObject + ' = \''
					+ pv_RecordId + '\' ORDER BY CreatedDate DESC NULLS LAST';
			
			lo_State.io_Contract = ( Contract ) Database.query( lv_ContractQuery )[ 0 ];
		}
		
		return JSON.serialize(
				lo_State
		);
	}
	
	private List<Fenster__mdt> loadFensters () {
		return [
				SELECT
						Id,
						Titel__c,
						Ist_Filialfenster__c,
						Nummerierung__c, (
						SELECT
								Id,
								Nummerierung__c,
								Titel__c,
								Dokument__r.Visualforce_Page__c,
								Datentyp__c,
								ist_Vorschau__c
						FROM Schaltflaechen__r
						WHERE Prozess__c = 'Stammdatensammler'
						ORDER BY Nummerierung__c ASC NULLS LAST
				)
				FROM Fenster__mdt
				WHERE Prozess__c = 'Stammdatensammler' AND Ist_Existierende_MAEF__c = :isExistingMAEF
				ORDER BY Nummerierung__c ASC NULLS LAST
		];
	}
	
	private static List<Sektion__mdt> loadSektionen () {
		return [
				SELECT
						Nummerierung__c,
						Id,
						Fenster__c,
						Titel__c
				FROM Sektion__mdt
				WHERE Prozess__c = 'Stammdatensammler'
				ORDER BY Nummerierung__c ASC NULLS LAST
		];
	}
	
	private void loadPflichtfelderByDocument () {
		String process = isFormataenderungAutoGen ? 'Formataenderung' : 'Stammdatensammler';
		for ( DokumentPflichtfeld__mdt dokumentPflichtfeld : [
				SELECT
						Dokument__r.Visualforce_Page__c,
						Prozess__c,
						Feld__r.DeveloperName,
						Feld__r.Objektname__c,
						Feld__r.Feldname__c,
						Feld__r.Ausblenden__c,
						Feld__r.Feldtyp__c,
						Feld__r.ist_Formelfeld__c
				FROM DokumentPflichtfeld__mdt
				WHERE Prozess__c = :process
		] ) {
			pflichtfeldByDeveloperName.put( dokumentPflichtfeld.Feld__r.DeveloperName, dokumentPflichtfeld );
			if ( pflichtfelderByDocumentVisualforceName.containsKey( dokumentPflichtfeld.Dokument__r.Visualforce_Page__c ) ) {
				pflichtfelderByDocumentVisualforceName.get( dokumentPflichtfeld.Dokument__r.Visualforce_Page__c ).add( dokumentPflichtfeld );
			}
			else {
				pflichtfelderByDocumentVisualforceName.put( dokumentPflichtfeld.Dokument__r.Visualforce_Page__c, new List<DokumentPflichtfeld__mdt> {
						dokumentPflichtfeld
				} );
			}
		}
	}
	
	private void loadPflichtdokumenteByDocument () {
		String process = isFormataenderungAutoGen ? 'Formataenderung' : 'Stammdatensammler';
		for ( DokumentPflichtdokument__mdt dokumentPflichtdokument : [
				SELECT
						Dokument__r.Visualforce_Page__c,
						Prozess__c,
						Pflichtdokument__r.Visualforce_Page__c
				FROM DokumentPflichtdokument__mdt
				WHERE Prozess__c = :process
		] ) {
			if ( pflichtdokumenteByDocumentVisualforceName.containsKey( dokumentPflichtdokument.Dokument__r.Visualforce_Page__c ) ) {
				pflichtdokumenteByDocumentVisualforceName.get( dokumentPflichtdokument.Dokument__r.Visualforce_Page__c ).add( dokumentPflichtdokument );
			}
			else {
				pflichtdokumenteByDocumentVisualforceName.put( dokumentPflichtdokument.Dokument__r.Visualforce_Page__c, new List<DokumentPflichtdokument__mdt> {
						dokumentPflichtdokument
				} );
			}
		}
	}
	
	private void loadFields () {
		
		for ( Feld__mdt lv_Field : [
				SELECT
						Nummerierung__c,
						Id,
						Erforderlich__c,
						Schreibschutz__c,
						Sektion__c,
						Feldname__c,
						Feldtyp__c,
						ist_Formelfeld__c,
						Hilfetext__c,
						Label__c,
						Maximale_Laenge__c,
						Objektname__c,
						Spalte__c,
						Validierung_Fehlermeldung__c,
						Validierung_Regex__c,
						Validierung_Methode__c,
						OZ_95__c,
						OZ_84__c,
						OZ_79__c,
						Abweichender_RE_und_EKP_bekannt__c,
						Abweichender_RE_und_EKP_unbekannt__c,
						Abweichender_ZR_und_EKP_bekannt__c,
						Abweichender_ZR_und_EKP_unbekannt__c,
						Postfachanlage_vorhanden__c,
						Aenderung_an_Kasse_erforderlich__c,
						VorgaengerfilialeVorhanden__c,
						Ausblenden__c,
						DeveloperName
				
				FROM Feld__mdt
				WHERE Prozess__c = 'Stammdatensammler'
				AND Feldname__c != NULL
				AND ( Objektname__c = 'Account'
				OR Objektname__c = 'Contract')
				ORDER BY Nummerierung__c ASC NULLS LAST
		] ) {
			lv_Field.Erforderlich__c = pflichtfeldByDeveloperName.containsKey( lv_Field.DeveloperName );
			if ( im_FieldsBySectionId.containsKey( lv_Field.Sektion__c ) ) {
				im_FieldsBySectionId.get( lv_Field.Sektion__c ).add( lv_Field );
			}
			else {
				im_FieldsBySectionId.put( lv_Field.Sektion__c, new List<Feld__mdt> {
						lv_Field
				} );
			}
		}
	}
	
	private String buildQueryString ( String pv_FilterField ) {
		Set<String> ls_FieldNames = new Set<String>();
		for ( Id lv_Key : im_SectionsByScreenId.keySet() ) {
			for ( Sektion__mdt lo_Section : im_SectionsByScreenId.get( lv_Key ) ) {
				if ( im_FieldsBySectionId.containsKey( lo_Section.Id ) ) {
					for ( Feld__mdt lo_Field : im_FieldsBySectionId.get( lo_Section.Id ) ) {
						if ( lo_Field.Objektname__c == 'Account' ) {
							ls_FieldNames.add( lo_Field.Feldname__c );
						}
					}
				}
			}
		}
		ls_FieldNames.add( 'Id' );
		ls_FieldNames.add( 'Zeige_Hinweis_Gewerbeschein__c' );
		ls_FieldNames.add( 'Zeige_Hinweis_Polizeiliches_Fuhrungszeug__c' );
		ls_FieldNames.add( 'Postbankanfrage_versendet__c' );
		ls_FieldNames.add( 'Selbstauskunft_versendet__c' );
		ls_FieldNames.add( 'Debitoranfrage_versendet__c' );
		ls_FieldNames.add( 'RecordType.DeveloperName' );
		ls_FieldNames.add( 'Lead__r.Formataenderung__c' );
		ls_FieldNames.remove( null );
		return 'SELECT ' + getFields( ls_FieldNames ) + ' FROM Account WHERE '
				+ pv_FilterField + ' = \'' + iv_RecordId + '\'';
	}
	
	private String getFields ( Set<String> ls_FieldNames ) {
		String lv_Fields = '';
		for ( String lv_FieldName : ls_FieldNames ) {
			lv_Fields += lv_FieldName + ',';
		}
		lv_Fields = lv_Fields.removeEnd( ',' );
		return lv_Fields;
	}
	
	private Contract loadContract () {
		Contract lo_Contract = null;
		
		String lv_RelatedObject = 'AccountId';
		Map<String, Schema.SObjectField> fieldMap = Contract.SObjectType.getDescribe().fields.getMap();
		
		Set<String> fieldNames = fieldMap.keySet();
		List<String> fields = new List<String>();
		fields.addAll( fieldNames );
		
		String lv_Query = 'SELECT ' + String.join( fields, ',' )
				+ ' FROM Contract ' +
				'WHERE ' + lv_RelatedObject + ' = \'' + io_State.io_SObject.Id + '\' ' +
				'ORDER BY CreatedDate DESC NULLS LAST';
		List<Contract> ll_Contracts = Database.query( lv_Query );
		if ( ll_Contracts.size() > 0 ) {
			lo_Contract = ll_Contracts[ 0 ];
			update lo_Contract;
		}
		
		if ( lo_Contract == null ) {
			lo_Contract = new Contract(
					Name = 'Vertrag SDS',
					Lead__c = isExistingMAEF ? null : iv_RecordId,
					AccountId = io_State.io_SObject.Id,
					StartDate = Date.today(),
					SDS_Helper_FirstRun__c = true,
					ContractTerm = 48,
					RecordTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByDeveloperName()
							.get( 'Partnerfiliale_Vertrag' ).getRecordTypeId()
			);
			insert lo_Contract;
		}
		lo_Contract = ( Contract ) Database.query( lv_Query )[ 0 ];
		return lo_Contract;
	}
	
	private void loadSectionInfo () {
		for ( Sektion__mdt lv_Sektion : loadSektionen() ) {
			
			if ( im_SectionsByScreenId.containsKey( lv_Sektion.Fenster__c ) ) {
				
				im_SectionsByScreenId.get( lv_Sektion.Fenster__c ).add( lv_Sektion );
			}
			else {
				im_SectionsByScreenId.put( lv_Sektion.Fenster__c, new List<Sektion__mdt> {
						lv_Sektion
				} );
			}
		}
	}
	
	private void buildScreens () {
		im_SectionsByScreenId = new Map<Id, List<Sektion__mdt>>();
		im_FieldsBySectionId = new Map<Id, List<Feld__mdt>>();
		pflichtfelderByDocumentVisualforceName = new Map<String, List<DokumentPflichtfeld__mdt>>();
		pflichtfeldByDeveloperName = new Map<String, DokumentPflichtfeld__mdt>();
		loadPflichtfelderByDocument();
		loadPflichtdokumenteByDocument();
		loadFields();
		loadSectionInfo();
		io_State.il_Screens = new List<Screen>();
		
		for ( Fenster__mdt lv_Fenster : this.loadFensters() ) {
			if ( im_SectionsByScreenId.containsKey( lv_Fenster.Id ) ) {
				
				List<Section> ll_Sections = new List<Section>();
				for ( Sektion__mdt lo_Section : im_SectionsByScreenId.get( lv_Fenster.Id ) ) {
					
					
					ll_Sections.add(
							new Section(
									lo_Section.Titel__c,
									im_FieldsBySectionId.containsKey( lo_Section.Id ) ? im_FieldsBySectionId.get( lo_Section.Id ) : null
							)
					);
				}
				
				Screen lo_Screen = new Screen(
						lv_Fenster.Titel__c,
						ll_Sections,
						lv_Fenster.Id,
						lv_Fenster.Ist_Filialfenster__c
				);
				buildButtons( lv_Fenster, lo_Screen );
				io_State.il_Screens.add(
						lo_Screen
				);
			}
		}
	}
	
	private void buildButtons ( Fenster__mdt lv_Fenster, Screen lo_Screen ) {
		for ( Schaltflaeche__mdt lo_Button : lv_Fenster.Schaltflaechen__r ) {
			if ( lo_Button.ist_Vorschau__c ) {
				lo_Screen.buttons.add(
						new Button(
								lo_Button
						)
				);
			}
			else {
				lo_Screen.buttons.add(
						new Button(
								lo_Button,
								pflichtfelderByDocumentVisualforceName.containsKey( lo_Button.Dokument__r.Visualforce_Page__c )
										? pflichtfelderByDocumentVisualforceName.get( lo_Button.Dokument__r.Visualforce_Page__c )
										: new List<DokumentPflichtfeld__mdt>(),
								pflichtdokumenteByDocumentVisualforceName.containsKey( lo_Button.Dokument__r.Visualforce_Page__c )
										? pflichtdokumenteByDocumentVisualforceName.get( lo_Button.Dokument__r.Visualforce_Page__c )
										: new List<DokumentPflichtdokument__mdt>()
						)
				);
			}
		}
	}
	
	private void loadProgressStates () {
		
		il_ProgressStates = [
				SELECT
						Id,
						Name,
						Lead__c,
						Account__c,
						Status__c,
						Gesperrt__c
				FROM Stammdatensammler__c
				WHERE Lead__c = :iv_RecordId
				OR Account__c = :iv_RecordId
				ORDER BY Nummerierung__c ASC NULLS LAST
		];
	}
	
	private void insertProgressStates () {
		Integer i = 1;
		for ( Screen screen : io_State.il_Screens ) {
			il_ProgressStates.add(
					new Stammdatensammler__c(
							Name = screen.title,
							Lead__c = iv_RecordId,
							Account__c = io_State.io_SObject.Id,
							Status__c = screen.title == 'Erfassung Grunddaten' ? 'active' : 'open',
							Nummerierung__c = i
					)
			);
			i++;
		}
		insert il_ProgressStates;
	}
	
	private void buildSteps () {
		
		for ( Stammdatensammler__c lv_ProgressState : il_ProgressStates ) {
			io_State.il_Steps.add(
					new Step(
							lv_ProgressState.Name,
							lv_ProgressState.Status__c,
							lv_ProgressState.Id,
							lv_ProgressState.Gesperrt__c
					)
			);
		}
	}
	
	private Account loadAccount ( OrgE_DP__c lo_OrgE_DP ) {
		Account lo_Account = new Account();
		if ( iv_SObjectName == 'Account' ) {
			lo_Account = ( Account ) Database.query( buildQueryString( 'Id' ) )[ 0 ];
			loadOeffnungszeiten( lo_Account.Id );
		}
		else if ( iv_SObjectName == 'Lead' ) {
			if ( accountExists() ) {
				lo_Account = ( Account ) Database.query( buildQueryString( 'Lead__c' ) )[ 0 ];
				loadOeffnungszeiten( lo_Account.Id );
			}
			else {
				setupNewDummyAccount( lo_Account, lo_OrgE_DP );
			}
		}
		else {
			//Sonarqube --> do nothing
		}
		return lo_Account;
	}
	
	private void setupNewDummyAccount ( Account lo_Account, OrgE_DP__c lo_OrgE_DP ) {
		Lead lo_Lead = [
				SELECT
						Id,
						VL__r.GL__c,
						VL__r.GL__r.OrgE_DP_Name__c,
						Company,
						Industry,
						Email,
						Fax,
						OwnerId,
						Street,
						PostalCode,
						City,
						Country,
						MobilePhone,
						Phone,
						Title,
						VL__c,
						Website,
						Name,
						Branche__c,
						Salutation,
						LastName,
						FirstName,
						Hausnummer__c,
						Weitere_Telefonnummer__c,
						VL__r.Werksnummer_Debitor_I__c,
						VL__r.GL__r.Werksnummer_Debitor_I__c,
						Abweichend_Hausnummer__c,
						Abweichend_Ort__c,
						Abweichend_PLZ__c,
						Abweichend_Strasse__c,
						//MYPM-1129:
						Filialnetzaenderung__c,
						Filialnetzaenderung__r.Filiale_Filialpartner__c,
						Formataenderung__c
				FROM Lead
				WHERE Id = :iv_RecordId
				LIMIT 1
		];
		
		lo_Account.E_Mail_Vertragspartner__c = lo_Lead.Email;
		lo_Account.Fax = lo_Lead.Fax;
		lo_Account.Fax_Vertragspartner__c = lo_Lead.Fax;
		lo_Account.Name = lo_Lead.Company;
		lo_Account.OwnerId = lo_Lead.OwnerId;
		lo_Account.X1_Ansprechpartner_Anrede__c = lo_Lead.Salutation;
		lo_Account.X1_Ansprechpartner_Name__c = lo_Lead.LastName;
		lo_Account.X1_Ansprechpartner_Vorname__c = lo_Lead.FirstName;
		lo_Account.ShippingStreet = getStrasse( lo_Lead.Street );
		lo_Account.Filiale_Hausnummer__c = getHausnummer( lo_Lead.Street );
		lo_Account.ShippingPostalCode = lo_Lead.PostalCode;
		lo_Account.ShippingCity = lo_Lead.City;
		lo_Account.Mobil__c = lo_Lead.Weitere_Telefonnummer__c;
		lo_Account.Telefon_Vertragspartner__c = lo_Lead.Phone;
		lo_Account.Phone = lo_Lead.Phone;
		lo_Account.Titel__c = lo_Lead.Title;
		lo_Account.Website = lo_Lead.Website;
		lo_Account.Lead__c = lo_Lead.Id;
		lo_Account.Branche__c = lo_Lead.Branche__c;
		lo_Account.Betriebsstatus__c = 'vorFACTS-Anlage';
		lo_Account.GL__c = lo_OrgE_DP == null ? lo_Lead.VL__r.GL__c : lo_OrgE_DP.Id;
		lo_Account.GL_Name__c = lo_OrgE_DP == null ? lo_Lead.VL__r.GL__r.OrgE_DP_Name__c : lo_OrgE_DP.OrgE_DP_Name__c;
		lo_Account.Werksnummer_Debitor_I__c = lo_OrgE_DP == null
				? lo_Lead.VL__r.GL__r.Werksnummer_Debitor_I__c
				: lo_OrgE_DP.Werksnummer_Debitor_I__c;
		lo_Account.Strasse_inkl_Hausnummer__c = lo_Lead.Abweichend_Strasse__c; //@straße und
		lo_Account.Hausnummer__c = lo_Lead.Abweichend_Hausnummer__c;
		lo_Account.PLZ__c = lo_Lead.Abweichend_PLZ__c;
		lo_Account.Ort__c = lo_Lead.Abweichend_Ort__c;
		lo_Account.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
				.get( 'Filiale_Dummy' ).getRecordTypeId();
		
		//MYPM-1129 do partwise preselection here
		if ( lo_Lead.Formataenderung__c == true ) {
			
			Filialnetzaenderung__c fnaeComplete =
					( Filialnetzaenderung__c ) HW_SharedVertragsUtils.queryAllFields(
							'Filialnetzaenderung__c',
							lo_Lead.Filialnetzaenderung__c,
							'Id'
					);
			
			if ( fnaeComplete.Filiale_Filialpartner__c != null ) {
				
				Account filialpartnerComplete =
						( Account ) HW_SharedVertragsUtils.queryAllFields(
								'Account',
								fnaeComplete.Filiale_Filialpartner__c,
								'Id'
						);
				
				mapFieldsFormataenderung( lo_Account, filialpartnerComplete, fnaeComplete );
			}
		}
		
		insert lo_Account;
		
		
		//MYPM-1188 Oefnungszeiten
		if ( lo_Lead.Formataenderung__c == true ) {
			cloneFromAccount( lo_Lead.Filialnetzaenderung__r.Filiale_Filialpartner__c, lo_Account.Id );
		}
		else {
			createOeffnungszeiten( lo_Account.Id );
		}
	
	}
	
	private static void mapFieldsFormataenderung ( Account lo_Account, Account filialpartnerComplete, Filialnetzaenderung__c fnaeComplete ) {
		//MYPM-1129
		lo_Account.Anzahl_Schalter__c = filialpartnerComplete.Anzahl_Schalter__c;
		lo_Account.Anzahl_Schalter_ZORA_Geraete__c = String.valueOf( filialpartnerComplete.Anzahl_Schalter__c );
		lo_Account.Eroeffnungsdatum__c = fnaeComplete.Schliessung_avisiert_fuer__c;
		lo_Account.Schliessung_zum__c = fnaeComplete.Schliessung_avisiert_fuer__c;
		lo_Account.ASt_Name__c = filialpartnerComplete.ASt_Name__c;
		lo_Account.Ortsteil_Postanschrift__c = filialpartnerComplete.Ortsteil_Postanschrift__c;
		lo_Account.Filiale_Hausnummer__c = filialpartnerComplete.Filiale_Hausnummer__c;
		lo_Account.Phone = filialpartnerComplete.Telefon__c;
		lo_Account.Fax = filialpartnerComplete.Fax;
		lo_Account.Vertriebssegment_SDS__c = filialpartnerComplete.Vertriebssegment__c;
		lo_Account.Juristischer_Name_Gewerbeanmeldung_1__c = filialpartnerComplete.Juristischer_Name_Gewerbeanmeldung_1__c;
		lo_Account.Juristischer_Name_Gewerbeanmeldung_2__c = filialpartnerComplete.Juristischer_Name_Gewerbeanmeldung_2__c;
		lo_Account.Juristischer_Name_Gewerbeanmeldung_3__c = filialpartnerComplete.Juristischer_Name_Gewerbeanmeldung_3__c;
		lo_Account.X1_Ansprechpartner_Vorname__c = filialpartnerComplete.X1_Ansprechpartner_Vorname__c;
		lo_Account.X1_Ansprechpartner_Anrede__c = filialpartnerComplete.X1_Ansprechpartner_Anrede__c;
		lo_Account.X1_Ansprechpartner_Name__c = filialpartnerComplete.X1_Ansprechpartner_Name__c;
		lo_Account.X2_Ansprechpartner_Vorname__c = filialpartnerComplete.X2_Ansprechpartner_Vorname__c;
		lo_Account.X2_Ansprechpartner_Anrede__c = filialpartnerComplete.X2_Ansprechpartner_Anrede__c;
		lo_Account.X2_Ansprechpartner_Name__c = filialpartnerComplete.X2_Ansprechpartner_Name__c;
		lo_Account.Strasse__c = filialpartnerComplete.Strasse__c;
		lo_Account.Hausnummer__c = filialpartnerComplete.Hausnummer__c;
		lo_Account.PLZ__c = filialpartnerComplete.PLZ__c;
		lo_Account.Ort__c = filialpartnerComplete.Ort__c;
		lo_Account.E_Mail_Vertragspartner__c = filialpartnerComplete.E_Mail_Vertragspartner__c;
		lo_Account.Mobil__c = filialpartnerComplete.Mobil__c;
		lo_Account.Geb_Datum__c = filialpartnerComplete.Geb_Datum__c;
		lo_Account.Branche__c = filialpartnerComplete.Branche_FACTS__c;
		lo_Account.Alter_des_Gewerbebetriebes_Jahre__c = filialpartnerComplete.Alter_des_Gewerbebetriebes_Jahre__c;
		lo_Account.Dauer_Beziehung_Deutschen_Post_Jahre__c = filialpartnerComplete.Dauer_Beziehung_Deutschen_Post_Jahre__c;
		
		if ( !String.isEmpty( filialpartnerComplete.Filialtyp_OZ__c ) && !String.isEmpty( fnaeComplete.Wunschformat__c ) ) {
			lo_Account.Debitor__c =
					( filialpartnerComplete.Filialtyp_OZ__c.contains( '79' ) || filialpartnerComplete.Filialtyp_OZ__c.contains( '95' ) )
							&& ( fnaeComplete.Wunschformat__c.contains( '79' ) || fnaeComplete.Wunschformat__c.contains( '95' ) )
							? filialpartnerComplete.Debitor__c
							: '';
		}
		
		//MYPM-1185
		lo_Account.Datum_Auftragsstellung__c = Date.today();
		
		if ( !String.isEmpty( filialpartnerComplete.Debitor_abw_Rechnungsempfaenger__c ) ) {
			lo_Account.Debitor_abw_Rechnungsempfaenger__c = filialpartnerComplete.Debitor_abw_Rechnungsempfaenger__c ;
			lo_Account.Filialstandort_abw_Rechnungsempfaenger__c = 'ja, EKP-Nr. siehe nachfolgende Zeile';
			lo_Account.Debitor_II_abw_Rechungsempfaenger__c = filialpartnerComplete.Debitor_abw_Rechnungsempfaenger__c;
		}
		
		if ( !String.isEmpty( filialpartnerComplete.Debitor_abw_Zahlungsregulierer__c ) ) {
			lo_Account.Debitor_abw_Zahlungsregulierer__c = filialpartnerComplete.Debitor_abw_Zahlungsregulierer__c ;
			lo_Account.Filialstandort_abw_Zahlungsregulierer__c = 'ja, EKP-Nr. siehe nachfolgende Zeile';
			lo_Account.Debitor_III_abw_Zahlungsregulierer__c = filialpartnerComplete.Debitor_abw_Zahlungsregulierer__c;
		}
		
		lo_Account.Umsatzsteuer_IdNr__c = filialpartnerComplete.Umsatzsteuer_IdNr__c;
		lo_Account.Steuer_Nummer__c = filialpartnerComplete.Steuer_Nummer__c;
		
		lo_Account.X08a_Bankdaten_01_IBAN__c = filialpartnerComplete.X08a_Bankdaten_01_IBAN__c;
		lo_Account.X08a_Bankdaten_01_BIC__c = filialpartnerComplete.X08a_Bankdaten_01_BIC__c;
		lo_Account.X08a_Bankdaten_01_Name_der_Bank__c = filialpartnerComplete.X08a_Bankdaten_01_Name_der_Bank__c;
		lo_Account.X08b_Bankdaten_02_IBAN__c = filialpartnerComplete.X08b_Bankdaten_02_IBAN__c;
		lo_Account.X08b_Bankdaten_02_BIC__c = filialpartnerComplete.X08b_Bankdaten_02_BIC__c;
		lo_Account.X08b_Bankdaten_02_Name_der_Bank__c = filialpartnerComplete.X08b_Bankdaten_02_Name_der_Bank__c;
		
		lo_Account.Umsatzsteuerpflicht_Debitor_I_FSO__c = filialpartnerComplete.Umsatzsteuerpflicht_Debitor_I_FSO__c;
		lo_Account.Werksnummer_Debitor_I__c = filialpartnerComplete.Werksnummer_Debitor_I__c;
		lo_Account.Sonstige_Mitteilung__c = filialpartnerComplete.Sonstige_Mitteilung__c;
		
		//MYPM-1187
		if ( String.isBlank( filialpartnerComplete.abw_Rechnungsempfaenger_SAP_Id__c ) ) {
			lo_Account.Debitor_II_abw_Rechungsempfaenger__c = filialpartnerComplete.Debitor_abw_Rechnungsempfaenger__c;
		}
		else {
			lo_Account.Debitor_II_abw_Rechungsempfaenger__c = filialpartnerComplete.abw_Rechnungsempfaenger_SAP_Id__c;
		}
		
		if ( !fnaeComplete.Wunschformat__c.contains( '84' ) ) {
			lo_Account.DHL_Express_Int__c = filialpartnerComplete.DHL_Express_Int__c;
		}
		
		//MYPM-1189
		lo_Account.Interim__c = 'Nein';
		
		//MYPM-1362
		lo_Account.Strasse_inkl_Hausnummer__c = filialpartnerComplete.Strasse_inkl_Hausnummer__c;
		lo_Account.EOE_Datum_Partnerjubilaeum__c = filialpartnerComplete.EOE_Datum_Partnerjubilaeum__c;
		lo_Account.Rechtsform__c = filialpartnerComplete.Rechtsform__c;
		lo_Account.Vertragsbetreuende_Einheit__c = filialpartnerComplete.GL__c;
	}
	
	private String getHausnummer ( String source ) {
		if ( source == null ) {
			return null;
		}
		String[] chars = source.split( '' );
		String hausnummer;
		for ( Integer i = 0; i < chars.size(); i++ ) {
			if ( chars[ i ].isNumeric() ) {
				hausnummer = source.substring( i );
				break;
			}
		}
		return hausnummer;
	}
	
	private String getStrasse ( String source ) {
		if ( source == null ) {
			return null;
		}
		String[] chars = source.split( '' );
		String strasse;
		for ( Integer i = 0; i < chars.size(); i++ ) {
			if ( chars[ i ].isNumeric() ) {
				strasse = source.substring( 0, i - 1 );
				break;
			}
		}
		return strasse;
	}
	
	private void loadOeffnungszeiten ( Id pv_AccountId ) {
		
		for ( Oeffnungszeiten__c io_Oeffnungszeiten : [
				SELECT
						Name,
						Id,
						Kategorie__c,
						Wochentag__c,
						vm_von__c,
						vm_bis__c,
						nm_von__c,
						nm_bis__c,
						Account__c
				FROM Oeffnungszeiten__c
				WHERE Account__c = :pv_AccountId
				ORDER BY Name DESC NULLS LAST
		] ) {
			
			if ( im_OeffnungszeitensByKategorie.containsKey( io_Oeffnungszeiten.Kategorie__c ) ) {
				im_OeffnungszeitensByKategorie.get( io_Oeffnungszeiten.Kategorie__c ).add( io_Oeffnungszeiten );
			}
			else {
				im_OeffnungszeitensByKategorie.put( io_Oeffnungszeiten.Kategorie__c, new List<Oeffnungszeiten__c> {
						io_Oeffnungszeiten
				} );
			}
		}
	}
	
	private void cloneFromAccount ( Id orignAccountId, Id newAccountId ) {
		
		List<String> categories = new List<String>();
		
		for ( PicklistEntry io_KategorieEntry : Oeffnungszeiten__c.Kategorie__c.getDescribe().getPicklistValues() ) {
			categories.add( io_KategorieEntry.getValue() );
		}
		
		Map<String, List<Oeffnungszeiten__c>> vl_Oeffnungszeitens = OeffnungszeitService.createDefinitions( orignAccountId, categories );
		
		List<Oeffnungszeiten__c> allOefs = new List<Oeffnungszeiten__c>();
		
		for ( String cat : vl_Oeffnungszeitens.keySet() ) {
			for ( Oeffnungszeiten__c oeffnungszeiten : vl_Oeffnungszeitens.get( cat ) ) {
				oeffnungszeiten.Account__c = newAccountId;
				allOefs.add( oeffnungszeiten );
			}
		}
		
		insert allOefs;
		
		categorizeOeffnungszeiten( allOefs );
	}
	
	private void createOeffnungszeiten ( Id pv_AccountId ) {
		List<Oeffnungszeiten__c> vl_Oeffnungszeitens = new List<Oeffnungszeiten__c>();
		for ( PicklistEntry io_KategorieEntry : Oeffnungszeiten__c.Kategorie__c.getDescribe().getPicklistValues() ) {
			
			for ( PicklistEntry io_WochentagEntry : Oeffnungszeiten__c.Wochentag__c.getDescribe().getPicklistValues() ) {
				
				if ( io_KategorieEntry.getValue() == 'Filialöffnungszeiten' && io_WochentagEntry.getValue() == 'Montag' ) {
					vl_Oeffnungszeitens.add(
							new Oeffnungszeiten__c(
									Account__c = pv_AccountId,
									Kategorie__c = io_KategorieEntry.getValue(),
									Wochentag__c = io_WochentagEntry.getValue(),
									vm_von__c = '',
									vm_bis__c = '',
									nm_von__c = '',
									nm_bis__c = ''
							)
					);
				}
				else if ( io_KategorieEntry.getValue() == 'Sortierzeiten' && io_WochentagEntry.getValue() == 'Montag' ) {
					vl_Oeffnungszeitens.add(
							new Oeffnungszeiten__c(
									Account__c = pv_AccountId,
									Kategorie__c = io_KategorieEntry.getValue(),
									Wochentag__c = io_WochentagEntry.getValue(),
									vm_von__c = '',
									vm_bis__c = '',
									nm_von__c = '-',
									nm_bis__c = '-'
							)
					);
				}
				else if ( io_KategorieEntry.getValue() == 'Sortierzeiten'
						&& ( io_WochentagEntry.getValue() == 'Dienstag'
						|| io_WochentagEntry.getValue() == 'Mittwoch'
						|| io_WochentagEntry.getValue() == 'Donnerstag'
						|| io_WochentagEntry.getValue() == 'Freitag'
						|| io_WochentagEntry.getValue() == 'Samstag' ) ) {
					
					vl_Oeffnungszeitens.add(
							new Oeffnungszeiten__c(
									Account__c = pv_AccountId,
									Kategorie__c = io_KategorieEntry.getValue(),
									Wochentag__c = io_WochentagEntry.getValue(),
									vm_von__c = '00:00',
									vm_bis__c = '00:00',
									nm_von__c = '-',
									nm_bis__c = '-'
							)
					);
				}
				else {
					vl_Oeffnungszeitens.add(
							new Oeffnungszeiten__c(
									Account__c = pv_AccountId,
									Kategorie__c = io_KategorieEntry.getValue(),
									Wochentag__c = io_WochentagEntry.getValue(),
									vm_von__c = '-',
									vm_bis__c = '-',
									nm_von__c = '-',
									nm_bis__c = '-'
							)
					);
				
				}
			}
		}
		insert vl_Oeffnungszeitens;
		
		categorizeOeffnungszeiten( vl_Oeffnungszeitens );
	}
	
	private void categorizeOeffnungszeiten ( List<Oeffnungszeiten__c> catList ) {
		for ( Oeffnungszeiten__c io_Oeffnungszeiten : catList ) {
			
			if ( im_OeffnungszeitensByKategorie.containsKey( io_Oeffnungszeiten.Kategorie__c ) ) {
				im_OeffnungszeitensByKategorie.get( io_Oeffnungszeiten.Kategorie__c ).add( io_Oeffnungszeiten );
			}
			else {
				im_OeffnungszeitensByKategorie.put( io_Oeffnungszeiten.Kategorie__c, new List<Oeffnungszeiten__c> {
						io_Oeffnungszeiten
				} );
			}
		}
	}
	
	private void setOeffnungszeiten () {
		
		for ( Screen screen : io_State.il_Screens ) {
			
			for ( Section section : screen.sections ) {
				if ( section.iv_Title == 'Veränderungsmeldung zu Postfachanlagen (PfA)' ) {
					
					section.il_Oeffnungszeits.add(
							new Oeffnungszeit(
									im_OeffnungszeitensByKategorie.get( 'Sortierzeiten' )
							)
					);
					section.il_Oeffnungszeits.add(
							new Oeffnungszeit(
									im_OeffnungszeitensByKategorie.get( 'Zugangszeiten' )
							)
					);
					section.il_Oeffnungszeits.add(
							new Oeffnungszeit(
									im_OeffnungszeitensByKategorie.get( 'Ausgabezeiten' )
							)
					);
					
					section.iv_HasOeffnungszeiten = true;
				
				}
				else if ( section.iv_Title == 'Öffnungszeiten' ) {
					section.il_Oeffnungszeits.add(
							new Oeffnungszeit(
									im_OeffnungszeitensByKategorie.get( 'Filialöffnungszeiten' )
							)
					);
					section.il_Oeffnungszeits.add(
							new Oeffnungszeit(
									im_OeffnungszeitensByKategorie.get( 'Öffnungszeiten Hauptgeschäft' )
							)
					);
					section.il_Oeffnungszeits.add(
							new Oeffnungszeit(
									im_OeffnungszeitensByKategorie.get( 'Zugangszeiten für SB' )
							)
					);
					
					section.iv_HasOeffnungszeiten = true;
				}
				else {
					//Sonarqube --> do nothing
				}
			}
		}
	}
	
	private Boolean accountExists () {
		return [ SELECT Id FROM Account WHERE Lead__c = :iv_RecordId ].size() > 0;
	}
	
	@TestVisible
	private class State {
		
		private Account io_SObject;
		private SObject io_Contract;
		private List<Screen> il_Screens;
		@TestVisible
		private List<Step> il_Steps;
		
		public State () {
			this.il_Screens = new List<Screen>();
			this.il_Steps = new List<Step>();
		}
	}
	@TestVisible
	private class Screen {
		private String title;
		private Boolean isActive;
		private Boolean isAccount;
		private Id key;
		private List<Section> sections;
		private List<Button> buttons;
		private List<String> activeSections;
		
		public Screen ( String title, List<Section> sections, Id key, Boolean pv_IsAccountScreen ) {
			this.title = title;
			this.isActive = false;
			this.sections = sections;
			this.activeSections = new List<String>();
			this.key = key;
			this.buttons = new List<Button>();
			this.isAccount = pv_IsAccountScreen;
		}
	}
	
	@TestVisible
	private class Section {
		private String iv_Title;
		private List<Field> il_Fields;
		public List<Oeffnungszeit> il_Oeffnungszeits;
		public Boolean iv_HasOeffnungszeiten = false;
		
		public Section ( String pv_Title, List<Feld__mdt> pl_Fields ) {
			this.iv_Title = pv_Title;
			List<Field> feldWrappers = new List<Field>();
			if ( pl_Fields != null ) {
				for ( Feld__mdt feld : pl_Fields ) {
					feldWrappers.add( new Field( feld ) );
				}
				feldWrappers.sort();
			}
			this.il_Fields = feldWrappers;
			this.il_Oeffnungszeits = new List<Oeffnungszeit>();
		}
	}
	
	@TestVisible
	private class Step {
		
		private String iv_Label;
		private String iv_Status;
		private String iv_Value;
		private Id iv_Id;
		private Boolean iv_IsLocked;
		
		public Step ( String pv_Label, String pv_Status, Id pv_Id, Boolean pv_IsLocked ) {
			this.iv_Label = pv_Label;
			this.iv_Value = pv_Label;
			this.iv_Status = pv_Status;
			this.iv_Id = pv_Id;
			this.iv_IsLocked = pv_IsLocked;
		}
	}
	@TestVisible
	private class Button {
		private String iv_Label;
		private String iv_BaseUrl;
		private String iv_DataType;
		private String iv_VisualforceName;
		private Boolean iv_isPreview;
		private List<DokumentPflichtfeld__mdt> pflichtfelder = new List<DokumentPflichtfeld__mdt>();
		private List<DokumentPflichtdokument__mdt> pflichtdokumente = new List<DokumentPflichtdokument__mdt>();
		
		public Button ( Schaltflaeche__mdt pv_Button ) {
			this.iv_Label = pv_Button.Titel__c;
			this.iv_BaseUrl = Url.getSalesforceBaseUrl().toExternalForm();
			this.iv_DataType = pv_Button.Datentyp__c;
			this.iv_VisualforceName = pv_Button.Dokument__r.Visualforce_Page__c;
			this.iv_isPreview = pv_Button.ist_Vorschau__c;
		}
		
		public Button ( Schaltflaeche__mdt pv_Button,
				List<DokumentPflichtfeld__mdt> pflichtfelder,
				List<DokumentPflichtdokument__mdt> pflichtdokumente ) {
			this.iv_Label = pv_Button.Titel__c;
			this.iv_BaseUrl = Url.getSalesforceBaseUrl().toExternalForm();
			this.iv_DataType = pv_Button.Datentyp__c;
			this.iv_VisualforceName = pv_Button.Dokument__r.Visualforce_Page__c;
			this.iv_isPreview = pv_Button.ist_Vorschau__c;
			this.pflichtfelder = pflichtfelder;
			this.pflichtdokumente = pflichtdokumente;
		}
	}
	
	@TestVisible
	private class Oeffnungszeit {
		private String iv_Kategorie;
		private List<Oeffnungszeiten__c> pl_Oeffnungszeitens;
		
		public Oeffnungszeit ( List<Oeffnungszeiten__c> pl_Oeffnungszeitens ) {
			this.iv_Kategorie = pl_Oeffnungszeitens[ 0 ].Kategorie__c;
			pl_Oeffnungszeitens.sort();
			this.pl_Oeffnungszeitens = pl_Oeffnungszeitens;
		}
	}
	
	private class Field implements Comparable {
		
		public Decimal Nummerierung { get; set; }
		public Boolean Abweichender_RE_und_EKP_bekannt { get; set; }
		public Boolean Abweichender_RE_und_EKP_unbekannt { get; set; }
		public Boolean Abweichender_ZR_und_EKP_bekannt { get; set; }
		public Boolean Abweichender_ZR_und_EKP_unbekannt { get; set; }
		public Boolean Aenderung_an_Kasse_erforderlich { get; set; }
		public Boolean VorgaengerfilialeVorhanden { get; set; }
		public Boolean ist_Formelfeld { get; set; }
		public Boolean OZ_79 { get; set; }
		public Boolean OZ_84 { get; set; }
		public Boolean OZ_95 { get; set; }
		public Boolean Postfachanlage_vorhanden { get; set; }
		public Boolean Schreibschutz { get; set; }
		public Boolean Erforderlich { get; set; }
		public Boolean Ausblenden { get; set; }
		public String Feldname { get; set; }
		public String Feldtyp { get; set; }
		public String Hilfetext { get; set; }
		public String Objektname { get; set; }
		public String Spalte { get; set; }
		public String Validierung_Fehlermeldung { get; set; }
		public String Validierung_Methode { get; set; }
		public String Validierung_Regex { get; set; }
		public String Label { get; set; }
		public Decimal Maximale_Laenge { get; set; }
		public List<PicklistValueEntry> picklistValues { get; set; }
		
		public Field ( Feld__mdt field ) {
			this.Nummerierung = field.Nummerierung__c;
			this.Abweichender_RE_und_EKP_bekannt = field.Abweichender_RE_und_EKP_bekannt__c;
			this.Abweichender_RE_und_EKP_unbekannt = field.Abweichender_RE_und_EKP_unbekannt__c;
			this.Abweichender_ZR_und_EKP_bekannt = field.Abweichender_ZR_und_EKP_bekannt__c;
			this.Abweichender_ZR_und_EKP_unbekannt = field.Abweichender_ZR_und_EKP_unbekannt__c;
			this.Aenderung_an_Kasse_erforderlich = field.Aenderung_an_Kasse_erforderlich__c;
			this.VorgaengerfilialeVorhanden = field.VorgaengerfilialeVorhanden__c;
			this.ist_Formelfeld = field.ist_Formelfeld__c;
			this.OZ_79 = field.OZ_79__c;
			this.OZ_84 = field.OZ_84__c;
			this.OZ_95 = field.OZ_95__c;
			this.Postfachanlage_vorhanden = field.Postfachanlage_vorhanden__c;
			this.Schreibschutz = field.Schreibschutz__c;
			this.Erforderlich = field.Erforderlich__c;
			this.Ausblenden = field.Ausblenden__c;
			this.Feldname = field.Feldname__c;
			this.Feldtyp = field.Feldtyp__c;
			this.Hilfetext = field.Hilfetext__c;
			this.Objektname = field.Objektname__c;
			this.Spalte = field.Spalte__c;
			this.Validierung_Fehlermeldung = field.Validierung_Fehlermeldung__c;
			this.Validierung_Methode = field.Validierung_Methode__c;
			this.Validierung_Regex = field.Validierung_Regex__c;
			this.Label = field.Label__c;
			this.Maximale_Laenge = field.Maximale_Laenge__c;
			if ( field.Feldtyp__c == 'picklist' ) {
				this.picklistValues = getPicklistFieldValues( field.Objektname__c, field.Feldname__c, field.Erforderlich__c );
			}
		}
		
		public Integer compareTo ( Object obj ) {
			Field field = ( Field ) ( obj );
			
			if ( this.Nummerierung > field.Nummerierung ) {
				return 1;
			}
			
			if ( this.Nummerierung == field.Nummerierung ) {
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
	
	public class HW_MaefWrapper {
		public Account account;
		public Contract contract;
	}
	
	private class PicklistValueEntry {
		private String label;
		private String value;
		
		public PicklistValueEntry ( String label, String value ) {
			this.label = label;
			this.value = value;
		}
	}
}