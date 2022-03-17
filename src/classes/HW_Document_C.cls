/**
 *@author       Karsten Maaß
 *@created      04.04.2019
 *@version      1.0
 *@since        45.0
 *
 *
 *@description  Controller from which documents can be created using Visualforce
 *
 *
 *@changelog    04.04.2019 Karsten Maaß - Created
 * 
 */
public without sharing class HW_Document_C {
	private enum eFormat {
		HTML, PDF, EXCEL, WORD, CSV, INI
	}
	eFormat iv_output = eFormat.HTML;
	private String iv_fileName;
	private ID iv_currentObjectId;
	private String iv_currentObjectType;
	private Map<String, Feld__mdt> im_documentFieldToFieldMap = new Map<String, Feld__mdt>();
	private Map<String, Feld__mdt> im_ContractDocumentFieldToFieldMap = new Map<String, Feld__mdt>();
	private Map<String, Object> im_fieldValues = new Map<String, Object>();
	private Map<String, List<Oeffnungszeiten__c>> im_OeffnungszeitensByKategorie = new Map<String, List<Oeffnungszeiten__c>>();
	private Id iv_talendUserId = [ SELECT Id FROM User WHERE IstSchnittstellenbenutzer__c = TRUE LIMIT 1 ].Id;
	private Contract contract;
	private Account account;
	private Account iv_tempMAEFaccount;
	private Account iv_oldMAEFaccount;
	private Contract iv_tempMAEFcontract;
	private String errorMessage = '';
	private PageReference currentPage = null;
	
	public HW_Document_C () {
		currentPage = ApexPages.currentPage();
		initialize();
	}
	
	public HW_Document_C ( PageReference page ) {
		currentPage = page;
		initialize();
	}
	
	private void initialize () {
		String lv_outputParam = currentPage.getParameters().get( 'output' );
		if ( String.isNotBlank( lv_outputParam ) ) {
			switch on lv_outputParam.toUpperCase() {
				when 'PDF' {
					iv_output = eFormat.PDF;
				}
				when 'EXCEL' {
					iv_output = eFormat.EXCEL;
				}
				when 'WORD' {
					iv_output = eFormat.WORD;
				}
				when 'CSV' {
					iv_output = eFormat.CSV;
				}
				when 'INI' {
					iv_output = eFormat.INI;
				}
				when else {
					//Sonarqube --> do nothing
				}
			}
		}
		iv_currentObjectId = String.escapeSingleQuotes( currentPage.getParameters().get( 'id' ) );
		onLoad();
	}
	
	private void onLoad () {
		if ( String.isNotBlank( iv_currentObjectId ) ) {
			iv_currentObjectType = iv_currentObjectId.getSobjectType().getDescribe().getName();
			if ( getDocumentDeveloperName() != 'FACTS_Beleg' ) {
				loadData();
			}
			if ( getDocumentDeveloperName() == 'FACTS_Beleg'
					|| getDocumentDeveloperName() == 'MAEF_Beleg'
					|| getDocumentDeveloperName() == 'Zusatzinfo_Material' ) {
				loadOeffnungszeiten( iv_currentObjectId );
			}
			if ( getDocumentDeveloperName() == 'FACTS_Beleg' ) {
				loadFACTS();
			}
		}
	}
	
	private String getCurrentPageName () {
		return currentPage.getUrl().replaceAll( '\\?.*', '' ).replaceAll( '/apex/', '' );
	}
	
	private Map<String, Feld__mdt> getFieldMapping ( String pv_SObjectName ) {
		if ( pv_SObjectName == 'Account' && !im_documentFieldToFieldMap.isEmpty() ) {
			return im_documentFieldToFieldMap;
		}
		else if ( pv_SObjectName == 'Contract' && !im_ContractDocumentFieldToFieldMap.isEmpty() ) {
			return im_ContractDocumentFieldToFieldMap;
		}
		List<Dokumenten_Feld_Mapping__mdt> ll_fieldMappingList = [
				SELECT
						DeveloperName,
						Feld__c
				FROM Dokumenten_Feld_Mapping__mdt
				WHERE Prozess__c = 'Stammdatensammler' AND
				Dokument__r.Visualforce_Page__c = :getCurrentPageName()
		];
		Map<ID, String> lm_fieldIdsAndNames = new Map<ID, String>();
		for ( Dokumenten_Feld_Mapping__mdt lv_fieldMapping : ll_fieldMappingList ) {
			lm_fieldIdsAndNames.put( lv_fieldMapping.Feld__c, lv_fieldMapping.DeveloperName );
		}
		List<Feld__mdt> ll_fieldList = [
				SELECT
						DeveloperName,
						Feldname__c,
						Objektname__c,
						Feldtyp__c,
						Textformat__c
				FROM Feld__mdt
				WHERE Prozess__c = 'Stammdatensammler' AND
				Id IN :lm_fieldIdsAndNames.keySet() AND Objektname__c = :pv_SObjectName
		];
		
		for ( Feld__mdt field : ll_fieldList ) {
			if ( pv_SObjectName == 'Account' ) {
				im_documentFieldToFieldMap.put( lm_fieldIdsAndNames.get( field.Id ), field );
			}
			else {
				im_ContractDocumentFieldToFieldMap.put( lm_fieldIdsAndNames.get( field.Id ), field );
			}
		}
		return pv_SObjectName == 'Account' ?
				im_documentFieldToFieldMap
				: im_ContractDocumentFieldToFieldMap;
	}
	
	private String buildQueryString ( String pv_SObjectName ) {
		if ( String.isBlank( pv_SObjectName ) )
			return '';
		
		String lv_Fields = 'Id,';
		Set<String> fieldNames = new Set<String>();
		for ( Feld__mdt lv_Field : getFieldMapping( pv_SObjectName ).values() ) {
			if ( lv_Field.Feldname__c != 'null' && String.isNotBlank( lv_Field.Feldname__c ) ) {
				fieldNames.add( lv_Field.Feldname__c );
			}
		}
		for ( String fieldName : fieldNames ) {
			lv_Fields += fieldName + ',';
		}
		lv_Fields = lv_Fields.removeEnd( ',' );
		
		String lv_IdField = pv_SObjectName == 'Account' ? 'Id' : 'AccountId';
		
		return 'SELECT ' + lv_Fields + ' FROM ' + pv_SObjectName + ' WHERE ' + lv_IdField + ' = :iv_currentObjectId';
	}
	
	private void loadData () {
		loadData( 'Account' );
		loadData( 'Contract' );
	}
	
	private void loadData ( String sObjectName ) {
		String lv_QueryString = buildQueryString( sObjectName );
		if ( String.isNotBlank( lv_QueryString ) ) {
			List<SObject> queryResults = Database.query( lv_QueryString );
			if ( queryResults != null && !queryResults.isEmpty() ) {
				mapDataToFieldNames( queryResults[ 0 ] );
			}
		}
	}
	
	private void mapDataToFieldNames ( SObject po_currentObject ) {
		String lv_SObjectName = String.valueOf( po_currentObject.Id.getSobjectType() );
		for ( String lv_documentFieldName : getFieldMapping( lv_SObjectName ).keySet() ) {
			Feld__mdt lo_Field = getFieldMapping( lv_SObjectName ).get( lv_documentFieldName );
			Object lv_fieldValue = '';
			
			if ( String.isNotBlank( lo_Field.Feldname__c ) ) {
				if ( po_currentObject.get( lo_Field.Feldname__c ) != null &&
						( lo_Field.Feldtyp__c == 'currency' || lo_Field.Feldtyp__c == 'number' ) ) {
					lv_fieldValue = Decimal.valueOf( String.valueOf( po_currentObject.get( lo_Field.Feldname__c ) ) ).format();
				}
				else {
					lv_fieldValue = po_currentObject.get( lo_Field.Feldname__c );
				}
				
				im_fieldValues.put( lv_documentFieldName, lv_fieldValue != null ? lv_fieldValue : '' );
			}
		}
	}
	
	public Map<String, Object> getFeld () {
		
		return im_fieldValues;
	}
	
	public String getContentType () {
		switch on iv_output {
			when EXCEL {
				return 'application/vnd.ms-excel#' + '\"' + getFileNameWithExtension() + '\"';
			}
			when WORD {
				return 'application/vnd.msword#' + '\"' + getFileNameWithExtension() + '\"';
			}
			when CSV {
				return 'text/csv#' + '\"' + getFileNameWithExtension() + '\"';
			}
			when INI {
				return 'text#' + '\"' + getFileNameWithExtension() + '\"';
			}
			when else {
				//Sonarqube --> do nothing
			}
		}
		return '';
	}
	
	public String getRenderAs () {
		switch on iv_output {
			when PDF {
				return 'PDF';
			}
			when HTML {
				return 'HTML';
			}
			when else {
				//Sonarqube --> do nothing
			}
		}
		return '';
	}
	
	private String getFileExtension () {
		switch on iv_output {
			when PDF {
				return '.pdf';
			}
			when EXCEL {
				return '.xls';
			}
			when WORD {
				return '.doc';
			}
			when CSV {
				return '.csv';
			}
			when INI {
				return '.ini';
			}
			when HTML {
				return '.html';
			}
			when else {
				//Sonarqube --> do nothing
			}
		}
		return '';
	}
	
	private String getFileNameWithExtension () {
		return FileNameReplacer.replace( getFileName() + getFileExtension() );
	}
	
	private String getDocumentDeveloperName () {
		if ( String.isBlank( iv_fileName ) ) {
			List<Dokument__mdt> ll_dokumente = [
					SELECT DeveloperName
					FROM Dokument__mdt
					WHERE Prozess__c = 'Stammdatensammler' AND Visualforce_Page__c = :getCurrentPageName()
					LIMIT 1
			];
			iv_fileName = ll_dokumente.isEmpty() ? getCurrentPageName() : ll_dokumente[ 0 ].DeveloperName;
		}
		
		return iv_fileName;
	}
	
	private String getFileName () {
		
		switch on getDocumentDeveloperName() {
			when 'Debitoren_beantragen' {
				return 'SAP 166 für ' + getAccount().Lead__r.Company;
			}
			when 'Kontraktpflege' {
				return 'SAP 165 Neuanlage für ' + getAccount().Lead__r.Company;
			}
			when 'FACTS_Beleg' {
				return 'FACTS Beleg für neue Filiale ' + getAccount().ASt_Name__c
						+ ' Eröffnung zum: ' + getAccount().Eroeffnungsdatum__c.format();
			}
			when 'MAEF_Beleg' {
				return getMaefTitle( false );
			}
			when 'MAEF_Beleg_Filiale_existiert' {
				return getMaefTitle( true );
			}
			when 'Vertragsdokument' {
				return getAccount().Debitor__c + '_Vertragsdokument für '
						+ getAccount().Lead__r.Company;
			}
			when 'Selbstauskunft' {
				return 'Partner Selbstauskunft für ' + getAccount().Lead__r.Company;
			}
			when 'Postbankanfrage' {
				return 'Postbankanfrage VL ' + getAccount().Lead__r.VL__r.Name + ' - ' + getAccount().ASt_Name__c;
			}
			when 'Zusatzinfo_Material' {
				return 'Matwi_Stamm_' + getAccount().ASt_Name__c;
			}
			when 'Einverstaendniserklaerung' {
				return 'Einverstaendniserklaerung_' + getAccount().ASt_Name__c;
			}
			when else {
				//Sonarqube --> do nothing
			}
		}
		return 'Dokument nicht definiert';
	}
	
	private String getMaefTitle ( Boolean isExistingMAEF ) {
		List<String> aenderungsgrunds = getAenderungsgrund( isExistingMAEF );
		return 'MAEF '
				+ getAccount().ShippingPostalCode
				+ ' '
				+ getAccount().ShippingCity
				+ ', '
				+ aenderungsgrunds[ 0 ]
				+ ' zum '
				+ aenderungsgrunds[ 1 ];
	}
	
	private List<String> getAenderungsgrund ( Boolean isExistingMAEF ) {
		List<String> aenderungsgrunds = new List<String>();
		if ( isExistingMAEF ) {
			getAenderungsgrundExistingMaef( aenderungsgrunds );
		}
		else {
			aenderungsgrunds.add( 'Eroeffnung' );
			aenderungsgrunds.add( getAccount().Eroeffnungsdatum__c.format() );
		}
		return aenderungsgrunds;
	}
	
	private List<String> getAenderungsgrundExistingMaef ( List<String> aenderungsgrunds ) {
		if ( getTempMAEFContract().ErsatzloseSchliessungMitAblaufDes__c != null ) {
			aenderungsgrunds.add( 'Ersatzlose Schliessung' );
			aenderungsgrunds.add( getTempMAEFContract().ErsatzloseSchliessungMitAblaufDes__c.format() );
		}
		else if ( getTempMAEFContract().MAEF_Voruebergehende_Schliessung_ab__c != null ) {
			aenderungsgrunds.add( 'Voruebergehende ganztaegige Schliessung' );
			aenderungsgrunds.add( getTempMAEFContract().MAEF_Voruebergehende_Schliessung_ab__c.format() );
		}
		else if ( getTempMAEFContract().AenderungDerOeffnungszeitenAb__c != null
				&& getTempMAEFContract().sonstigeAenderungAb__c != null ) {
			aenderungsgrunds.add( 'Aenderung der Oeffnungszeiten und Sonstiges' );
			aenderungsgrunds.add( getTempMAEFContract().AenderungDerOeffnungszeitenAb__c.format()
					+ ' und ' + getTempMAEFContract().sonstigeAenderungAb__c.format() );
		}
		else if ( getTempMAEFContract().AenderungDerOeffnungszeitenAb__c != null
				&& getTempMAEFContract().sonstigeAenderungAb__c == null ) {
			aenderungsgrunds.add( 'Aenderung der Oeffnungszeiten' );
			aenderungsgrunds.add( getTempMAEFContract().AenderungDerOeffnungszeitenAb__c.format() );
		}
		else if ( getTempMAEFContract().AenderungDerOeffnungszeitenAb__c == null
				&& getTempMAEFContract().sonstigeAenderungAb__c != null ) {
			aenderungsgrunds.add( 'Sonstiges' );
			aenderungsgrunds.add( getTempMAEFContract().sonstigeAenderungAb__c.format() );
		}
		else if ( getTempMAEFContract().DatumDerSchliessung__c != null
				&& getTempMAEFContract().DatumderEroeffnung__c != null ) {
			aenderungsgrunds.add( 'Schliessung und Eroeffnung' );
			aenderungsgrunds.add( getTempMAEFContract().DatumDerSchliessung__c.format()
					+ ' und ' + getTempMAEFContract().DatumderEroeffnung__c.format() );
		}
		else if ( getTempMAEFContract().DatumDerSchliessung__c == null
				&& getTempMAEFContract().DatumderEroeffnung__c != null ) {
			aenderungsgrunds.add( 'Eroeffnung' );
			aenderungsgrunds.add( getTempMAEFContract().DatumderEroeffnung__c.format() );
		}
		else if ( getTempMAEFContract().DatumDerSchliessung__c != null
				&& getTempMAEFContract().DatumderEroeffnung__c == null ) {
			aenderungsgrunds.add( 'Schliessung' );
			aenderungsgrunds.add( getTempMAEFContract().DatumDerSchliessung__c.format() );
		}
		else {
			aenderungsgrunds.add( 'Keine Aenderung' );
			aenderungsgrunds.add( Date.today().format() );
		}
		return aenderungsgrunds;
	}
	
	// Comments proof of concept
	/*
	public String getComments () {
		return
				'<div style=\'mso-element:comment-list\'>' +
						'<div style=\'mso-element:comment\'>' +
						'<xml>' +
						'<v:shapetype id="_x0000_t202" coordsize="21600,21600" o:spt="202" path="m,l,21600r21600,l21600,xe">' +
						'<v:stroke joinstyle="miter"/>' +
						'<v:path gradientshapeok="t" o:connecttype="rect"/>' +
						'</v:shapetype>' +
						'<v:shape id="_comment1" type="#_x0000_t202" ' +
						'style=\'width:96pt;height:55.5pt;z-index:1;visibility:hidden\' ' +
						'fillcolor="infoBackground [80]" o:insetmode="auto">' +
						'<v:textbox style=\'mso-direction-alt:auto\'/>' +
						'<x:ClientData ObjectType="Note">' +
						'<x:Row>10</x:Row>' +
						'<x:Column>21</x:Column>' +
						'</x:ClientData>' +
						'</v:shape>' +
						'</xml>' +
						'<div v:shape="_comment1" >' +
						'z.B. Telefonnummer,<br/> Kassennummer,<br/> Entsorgungszeiten,  etc.' +
						'</div>' +
						'</div>' +
						'</div>';
	}
	*/
	
	public String getSheetName () {
		String sheetName = 'Tabelle1';
		switch on getDocumentDeveloperName() {
			when 'Postbankanfrage' {
				sheetName = 'postbankinterne Prüfung';
			}
			when 'Debitoren_beantragen' {
				sheetName = 'SAP 166 für ' + getAccount().Lead__r.Company;
			}
			when 'MAEF_Beleg' {
				sheetName = 'Änderung Filialnetz';
			}
			when 'Zusatzinfo_Material' {
				sheetName = 'Tabelle1';
			}
			when 'Kontraktpflege' {
				sheetName = 'SAP 165 Neuanlage für ' + getAccount().Lead__r.Company;
			}
			when else {
				//Sonarqube --> do nothing
			}
		}
		/*maximum excel sheet name length*/
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
	
	public void controllerActions () {
		setTemporaryData();
	}
	
	public void saveExistingMAEF () {
		setTemporaryData();
		Account account = getAccount();
		account.Lead__c = null;
		saveDocument( new List<Id> {
				iv_currentObjectId,
				createEmailDelivery( account )
		} );
	}
	
	private void setTemporaryData () {
		if ( getAccount().MAEF_Zwischenspeicher__c != null ) {
			HW_Stammdatensammler_LC.HW_MaefWrapper hwMaefWrapper =
					(HW_Stammdatensammler_LC.HW_MaefWrapper) JSON.deserialize( getAccount().MAEF_Zwischenspeicher__c,
							HW_Stammdatensammler_LC.HW_MaefWrapper.class );
			
			this.iv_tempMAEFaccount = hwMaefWrapper.account;
			this.iv_tempMAEFcontract = hwMaefWrapper.contract;
			emptyRelevantTempValuesIfIsErsatzloseSchliessung();
		}
	}
	
	private void emptyRelevantTempValuesIfIsErsatzloseSchliessung () {
		if ( this.iv_tempMAEFcontract.ErsatzloseSchliessungMitAblaufDes__c != null ) {
			this.iv_tempMAEFaccount.ASt_Name__c = null;
			this.iv_tempMAEFaccount.Strasse__c = null;
			this.iv_tempMAEFaccount.Filiale_Hausnummer__c = null;
			this.iv_tempMAEFaccount.ShippingCity = null;
			this.iv_tempMAEFaccount.Ortsteil_Postanschrift__c = null;
			this.iv_tempMAEFaccount.ShippingPostalCode = null;
			this.iv_tempMAEFaccount.Phone = null;
			this.iv_tempMAEFaccount.Fax = null;
			this.iv_tempMAEFaccount.ASt_Nummer__c = null;
			this.iv_tempMAEFaccount.DPAG_Kostenstelle__c = null;
			this.iv_tempMAEFaccount.Debitor__c = null;
			this.iv_tempMAEFaccount.WaWi_Nummer__c = null;
			this.iv_tempMAEFaccount.Filialtyp_OZ__c = null;
			this.iv_tempMAEFaccount.Anzahl_Schalter__c = null;
			this.iv_tempMAEFaccount.Branche_FACTS__c = null;
			this.iv_tempMAEFaccount.Name = null;
			this.iv_tempMAEFaccount.Masterkasse_KKZ__c = null;
			this.iv_tempMAEFaccount.PostfachanlageCheckbox__c = null;
			this.iv_tempMAEFaccount.Postfach_Betreiber__c = null;
			this.iv_tempMAEFaccount.DHL_Express_Int__c = null;
			this.iv_tempMAEFaccount.Briefkasten__c = null;
			this.iv_tempMAEFaccount.ASt_ID__c = null;
			this.iv_tempMAEFaccount.Filial_ILN__c = null;
			
			this.iv_tempMAEFcontract.AStNrReferenzFilialeVerkaufsproduktespro__c = null;
			this.iv_tempMAEFcontract.RegelInterim__c = null;
			this.iv_tempMAEFcontract.AnredeMAEF__c = null;
			this.iv_tempMAEFcontract.SteuernummerPartner__c = null;
			this.iv_tempMAEFcontract.TagesstempelMAEF__c = null;
			this.iv_tempMAEFcontract.VerteilschlussPfSdg__c = null;
			this.iv_tempMAEFcontract.AnlagenTypPfSchrank__c = null;
			this.iv_tempMAEFcontract.AnzahlPfSchraenke__c = null;
			this.iv_tempMAEFcontract.PostfilialeDirektMAEF__c = null;
			this.iv_tempMAEFcontract.ErgaenzenderHinweisStandort__c = null;
			this.iv_tempMAEFcontract.AnzahlMitarbeiter__c = null;
		}
	}
	
	public void save () {
		onLoad();
		saveDocument();
	}
	
	public String getErrorMessage () {
		return errorMessage;
	}
	
	private void saveDocument () {
		Account lo_Account = loadAccount();
		if ( getCurrentPageName() == 'HW_Einverstaendniserklaerung' ) {
			saveDocument( new List<Id> {
					lo_Account.Id,
					lo_Account.Lead__c
			} );
		}
		else {
			saveDocument( new List<Id> {
					lo_Account.Id,
					lo_Account.Lead__c,
					createEmailDelivery( lo_Account )
			} );
		}
	}
	
	private ContentDocumentLink createContentDocumentLinkTalendUser ( Id contentDocumentId ) {
		ContentDocumentLink cdl = new ContentDocumentLink();
		cdl.ContentDocumentId = contentDocumentId;
		cdl.LinkedEntityId = iv_talendUserId;
		cdl.ShareType = 'V';
		cdl.Visibility = 'AllUsers';
		return cdl;
	}
	
	private Id createEmailDelivery ( Account account ) {
		if ( getDocumentDeveloperName() != 'Vertragsdokument' ) {
			EmailSettingService.Request request = new EmailSettingService.Request();
			request.recordId = account.Id;
			request.emailSettingName = getDocumentDeveloperName();
			request.leadId = account.Lead__c;
			request.accountId = account.Id;
			request.contractId = account.Contracts.size() > 0
					? account.Contracts[ 0 ].Id
					: null;
			EmailSettingService.getInstance().requests.add( request );
			List<EmailVersand__c> emailDeliveries
					= EmailSettingService.getInstance().createMessages().getEmailDispatcherServiceDeliveries();
			for ( EmailVersand__c emailVersand : emailDeliveries ) {
				if ( getDocumentDeveloperName() == 'MAEF_Beleg_Filiale_existiert' ) {
					emailVersand.Email_Betreff__c = getMaefTitle( true );
				}
			}
			insert emailDeliveries;
			return emailDeliveries[ 0 ].Id;
		}
		return null;
	}
	
	private Account loadAccount () {
		return [
				SELECT
						Id,
						Lead__c, (
						SELECT
								Id
						FROM Contracts
				)
				FROM Account
				WHERE Id = :iv_currentObjectId
		];
	}
	
	private void saveDocument ( List<Id> recordIds ) {
		// save Parameter entfernen, um die Seite erneut zu rendern und keine Rekursion zu bekommen
		PageReference lv_currentPage = currentPage;
		Map<String, String> lm_params = lv_currentPage.getParameters();
		lm_params.remove( 'save' );
		lv_currentPage.getParameters().putAll( lm_params );
		lv_currentPage = new PageReference( lv_currentPage.getURL() );
		// Vorgänger Versionen holen
		
		Set<ID> ls_contentDocumentIds = new Set<ID>();
		Id linkedEntityId = recordIds[ 0 ];
		List<ContentDocumentLink> ll_contentDocumentLinks = [
				SELECT ContentDocumentId
				FROM ContentDocumentLink
				WHERE LinkedEntityId = :linkedEntityId
		];
		for ( ContentDocumentLink lv_contentDocumentLink : ll_contentDocumentLinks )
			ls_contentDocumentIds.add( lv_contentDocumentLink.ContentDocumentId );
		
		List<ContentVersion> ll_contentVersions = [
				SELECT ContentDocumentId
				FROM ContentVersion
				WHERE ContentDocumentId in :ls_contentDocumentIds AND PathOnClient = :getFileNameWithExtension()
				LIMIT 1
		];
		
		// Neue Dateiversion anlegen
		ContentVersion cv = new ContentVersion();
		cv.Title = FileNameReplacer.replace( getFileName() );
		cv.PathOnClient = getFileNameWithExtension();
		cv.VersionData = iv_output == eFormat.INI ? getContentAsIni() : getContent( lv_currentPage );
		cv.ContentLocation = 'S';
		cv.ContentDocumentId = ll_contentVersions.isEmpty() ? null : ll_contentVersions[ 0 ].ContentDocumentId;
		insert cv;
		
		Id contentDocumentId = ll_contentVersions.isEmpty()
				? [
						SELECT
								ContentDocumentId
						FROM ContentVersion
						WHERE Id = :cv.Id
				].ContentDocumentId
				: ll_contentVersions[ 0 ].ContentDocumentId;
		
		List<ContentDocumentLink> contentDocumentLinks = new List<ContentDocumentLink>();
		for ( Id recordId : recordIds ) {
			if ( recordId != null ) {
				// Dokument an das Objekt hängen
				ContentDocumentLink cdl = new ContentDocumentLink();
				cdl.ContentDocumentId = contentDocumentId;
				cdl.LinkedEntityId = recordId;
				cdl.ShareType = 'I';
				cdl.Visibility = 'AllUsers';
				contentDocumentLinks.add( cdl );
			}
		}
		contentDocumentLinks.add( createContentDocumentLinkTalendUser( contentDocumentId ) );
		List<Database.SaveResult> saveResults = Database.insert( contentDocumentLinks, false );
		for ( Database.SaveResult saveResult : saveResults ) {
			if ( !saveResult.isSuccess()
					&& !saveResult.getErrors()[ 0 ].getMessage().toLowerCase().contains( 'already linked' )
					&& !saveResult.getErrors()[ 0 ].getMessage().toLowerCase().contains(
					'ist bereits mit der entität mit folgender id verknüpft' ) ) {
				Database.Error error = saveResult.getErrors()[ 0 ];
				throw new HW_DocumentException( error.getStatusCode() + ': ' + error.getMessage() );
			}
		}
	}
	
	public class HW_DocumentException extends Exception {
	}
	
	private Blob getContent ( PageReference po_Page ) {
		if ( Test.isRunningTest() ) {
			return Blob.valueOf( 'Test Content' );
		}
		
		return po_Page.getContent();
	}
	
	@TestVisible
	private Blob getContentAsIni () {
		if ( Test.isRunningTest() ) {
			return Blob.valueOf( 'Test INI Content' );
		}
		
		String source = currentPage.getContent()
				.toString()
				.substringAfter( '<div>' )
				.substringBefore( '<script>' )
				.remove( '<div>' )
				.remove( '</div>' )
				.unescapeHtml4();
		String urlEncoded = EncodingUtil.urlEncode( source, 'iso-8859-1' );
		String[] chars = urlEncoded.replaceAll( '\\+', ' ' ).split( '' );
		for ( Integer i = 0; i < chars.size(); i++ ) {
			if ( chars[ i ] == '%' ) {
				chars[ i ] = EncodingUtil.convertToHex( EncodingUtil.convertFromHex( chars[ i + 1 ] + chars[ i + 2 ] ) );
				chars.remove( i + 2 );
				chars.remove( i + 1 );
			}
			else {
				chars[ i ] = EncodingUtil.convertToHex( Blob.valueOf( chars[ i ] ) );
			}
		}
		Blob body = EncodingUtil.convertFromHex( String.join( chars, '' ) );
		return body;
	}
	
	private Id getLogoId ( String documentApiName ) {
		List<Document> docs = [ SELECT Name FROM Document WHERE DeveloperName = :documentApiName LIMIT 1 ];
		return docs.size() > 0 ? docs[ 0 ].Id : null;
	}
	
	public String getLogoZusatzinfoMaterial () {
		return getLogo( getLogoId( 'Logo_855x186' ), '5.66cm', '1.24cm' );
	}
	
	public String getLogoSelbstauskunft () {
		return getLogo( getLogoId( 'Logo_855x186' ), '5.49cm', '1.38cm' );
	}
	
	private String getOrgInstance () {
		return [ SELECT InstanceName FROM Organization ].InstanceName;
	}
	
	private String getLogo ( ID lv_documentId, String width, String height ) {
		if ( lv_documentId == null )
			return '';
		
		String url = 'https://c.' + getOrgInstance()
				+ '.content.force.com/servlet/servlet.ImageServer?id='
				+ lv_documentId + '&oid=' + System.UserInfo.getOrganizationId();
		
		if ( iv_output == eFormat.EXCEL ) {
			return
					'<v:rect xmlns:v=\"urn:schemas-microsoft-com:vml\" fill=\"true\" stroke=\"false\" style=\"width:'
							+ width + ';height:' + height + ';\">' +
							'<v:fill type=\"frame\" src=\"' + url + '\" />' +
							'</v:rect>';
		}
		else
				return '<img src=\"' + url + '\" style=\"width:' + width + '\"/>';
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
				ORDER BY Name ASC NULLS LAST
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
	
	public List<Oeffnungszeiten__c> getFilialoeffnungszeiten () {
		
		return im_OeffnungszeitensByKategorie.containsKey( 'Filialöffnungszeiten' )
				? im_OeffnungszeitensByKategorie.get( 'Filialöffnungszeiten' )
				: null;
	}
	
	public List<Oeffnungszeiten__c> getOeffnungszeitenHauptgeschaeft () {
		return im_OeffnungszeitensByKategorie.containsKey( 'Öffnungszeiten Hauptgeschäft' )
				? im_OeffnungszeitensByKategorie.get( 'Öffnungszeiten Hauptgeschäft' )
				: null;
	}
	
	public List<Oeffnungszeiten__c> getZugangszeitenSB () {
		return im_OeffnungszeitensByKategorie.containsKey( 'Zugangszeiten für SB' )
				? im_OeffnungszeitensByKategorie.get( 'Zugangszeiten für SB' )
				: null;
	}
	
	public List<Oeffnungszeiten__c> getSortierzeiten () {
		return im_OeffnungszeitensByKategorie.containsKey( 'Sortierzeiten' )
				? im_OeffnungszeitensByKategorie.get( 'Sortierzeiten' )
				: null;
	}
	
	public List<Oeffnungszeiten__c> getZugangszeiten () {
		return im_OeffnungszeitensByKategorie.containsKey( 'Zugangszeiten' )
				? im_OeffnungszeitensByKategorie.get( 'Zugangszeiten' )
				: null;
	}
	
	public List<Oeffnungszeiten__c> getAusgabezeiten () {
		return im_OeffnungszeitensByKategorie.containsKey( 'Ausgabezeiten' )
				? im_OeffnungszeitensByKategorie.get( 'Ausgabezeiten' )
				: null;
	}
	
	
	// ##################################################
	// FACTS Beleg
	// ##################################################
	
	private List<FACTSSektion> iv_sortedFACTS = new List<FACTSSektion>();
	
	public class FACTSFeld {
		private String Label;
		private Object Value;
		private String Feldtyp;
		
		public String getLabel () {
			return Label;
		}
		public Object getValue () {
			return Value;
		}
		public Object getFeldtyp () {
			return Feldtyp;
		}
	}
	
	public class FACTSSektion {
		private String Label;
		private List<FACTSFeld> Felder = new List<FACTSFeld>();
		
		public String getLabel () {
			return Label;
		}
		public List<FACTSFeld> getFelder () {
			return Felder;
		}
	}
	
	private void loadFACTS () {
		List<Sektion__mdt> lv_sections = [
				SELECT
						Titel__c,
						Nummerierung__c,
						DeveloperName
				FROM Sektion__mdt
				WHERE Prozess__c = 'Stammdatensammler'
				AND Fenster__r.DeveloperName = 'Erfassung_Daten_FACTS_Beleg'
				ORDER BY Nummerierung__c ASC
		];
		List<Feld__mdt> lv_fieldList = [
				SELECT
						Sektion__c,
						Label__c,
						Nummerierung__c,
						DeveloperName,
						Feldname__c,
						Objektname__c,
						Feldtyp__c, // diese werden für die Wertebeschaffung gebraucht siehe getFieldMapping -> ll_fieldList
						Textformat__c
				FROM Feld__mdt
				WHERE Prozess__c = 'Stammdatensammler'
				AND Sektion__c IN :lv_sections
				AND Nicht_relevant_fuer_FACTS_Dokument__c = FALSE
				ORDER BY Nummerierung__c ASC
		];
		
		Map<Id, List<FACTSFeld>> lv_FactsFieldsBySection = new Map<Id, List<FACTSFeld>>();
		
		Set<String> fieldName = new Set<String>();        // es dürfen keine doppelten Feldnamen im Query vorkommen
		for ( Feld__mdt lv_field : lv_fieldList ) {
			if ( fieldName.contains( lv_field.Objektname__c + lv_field.Feldname__c ) )
				continue;
			
			if ( lv_field.Objektname__c == 'Account' )
				im_documentFieldToFieldMap.put( lv_field.Objektname__c + lv_field.Feldname__c, lv_field );
			if ( lv_field.Objektname__c == 'Contract' )
				im_ContractDocumentFieldToFieldMap.put( lv_field.Objektname__c + lv_field.Feldname__c, lv_field );
		}
		
		loadData();
		
		for ( Feld__mdt lv_field : lv_fieldList ) {
			List<FACTSFeld> lv_sectionFields = lv_FactsFieldsBySection.get( lv_field.Sektion__c );
			if ( lv_sectionFields == null )
				lv_sectionFields = new List<FACTSFeld>();
			FACTSFeld lv_sectionfield = new FACTSFeld();
			lv_sectionfield.Label = lv_field.Label__c;
			lv_sectionfield.Feldtyp = lv_field.Feldtyp__c;
			lv_sectionfield.Value = getFeld().get( lv_field.Objektname__c + lv_field.Feldname__c );
			lv_sectionFields.add( lv_sectionfield );
			lv_FactsFieldsBySection.put( lv_field.Sektion__c, lv_sectionFields );
		}
		for ( Sektion__mdt section : lv_sections ) {
			if ( lv_FactsFieldsBySection.containsKey( section.Id ) ) {
				FACTSSektion facts = new FACTSSektion();
				facts.Label = section.Titel__c;
				facts.Felder = lv_FactsFieldsBySection.get( section.Id );
				iv_sortedFACTS.add( facts );
			}
			if ( section.DeveloperName == 'Oeffnungszeiten' ) {
				FACTSSektion facts = new FACTSSektion();
				facts.Label = section.Titel__c;
				facts.Felder = new List<FACTSFeld>();
				iv_sortedFACTS.add( facts );
			}
		}
	}
	
	public List<FACTSSektion> getFACTS () {
		return iv_sortedFACTS;
	}
	
	//MYPM-1191
	public String getAntragsart () {
		if ( getAccount().Lead__r.Filialnetzaenderung__r.Filiale_Filialpartner__r.Filialtyp_OZ__c == '82'
				|| getAccount().Lead__r.Filialnetzaenderung__r.Filiale_Filialpartner__r.Filialtyp_OZ__c == '84' ) {
			return 'Neuanlage';
		}
		return 'Änderung';
	}
	
	public Contract getContract () {
		if ( contract == null ) {
			contract = [
					SELECT
							Id,
							PostfachanlageVorhanden__c,
							AenderungAnKassenErforderlich__c,
							Filialtyp__c
					FROM Contract
					WHERE AccountId = :iv_currentObjectId
					LIMIT 1
			];
		}
		return contract;
	}
	
	public String getBereich () {
		User currentUser = CurrentUser.getInstance().getUser();
		return currentUser.Profile.Name.contains( 'myPM Vertrieb (V' )
				? currentUser.OrgE_DP__c
				: getAccount().GL__r.Name;
	}
	
	public String getStelle () {
		User currentUser = CurrentUser.getInstance().getUser();
		return currentUser.Profile.Name.contains( 'myPM Vertrieb (V' )
				? currentUser.OrgE_DP__c
				: 'ZG 3510';
	}
	
	public String getPostfilialeDirekt () {
		return getAccount().Postfilialnummer__c != null ? 'Ja' : '';
	}
	
	public Account getAccount () {
		if ( account == null ) {
			account = [
					SELECT
							Id,
							Name,
							ShippingPostalCode,
							ShippingCity,
							Eroeffnungsdatum__c,
							MAEF_Zwischenspeicher__c,
							Lead__c,
							Debitor__c,
							ASt_Name__c,
							Juristischer_Name_Gewerbeanmeldung__c,
							VL__c,
							GL__r.Name,
							Lead__r.Company,
							Lead__r.VL__r.Name,
							Lead__r.Filialnetzaenderung__r.Filiale_Filialpartner__r.Filialtyp_OZ__c,
							Postfilialnummer__c
					FROM Account
					WHERE Id = :iv_currentObjectId
					LIMIT 1
			];
		}
		return account;
	}
	
	public Account getOldMAEFAccount () {
		if ( iv_oldMAEFaccount == null ) {
			iv_oldMAEFaccount = [
					SELECT
							Name,
							Eroeffnungsdatum__c,
							Schliessung_zum__c,
							ASt_Name__c,
							ShippingStreet,
							Filiale_Hausnummer__c,
							ShippingCity,
							ShippingPostalCode,
							Ortsteil_Postanschrift__c,
							Phone,
							Fax,
							ASt_Nummer__c,
							DPAG_Kostenstelle__c,
							Debitor__c,
							WaWi_Nummer__c,
							Anzahl_Schalter_ZORA_Geraete__c,
							Branche_FACTS__c,
							Juristischer_Name_Gewerbeanmeldung_1__c,
							X1_Ansprechpartner_Anrede__c,
							Masterkasse_KKZ__c,
							Steuer_Nummer__c,
							PostfachanlageCheckbox__c,
							Betreiber__c,
							Paketausgabe__c,
							Briefausgabe__c,
							Postfilialnummer__c,
							DHL_Express_Int__c,
							ASt_ID__c,
							NumberOfEmployees,
							Filialtyp_OZ__c,
							Anzahl_Schalter__c,
							Briefkasten__c,
							Filial_ILN__c,
							Strasse__c,
							Postfach_Betreiber__c,
							Mo_vm_von__c,
							Mo_vm_bis__c,
							Mo_nm_von__c,
							Mo_nm_bis__c,
							Di_vm_von__c,
							Di_vm_bis__c,
							Di_nm_von__c,
							Di_nm_bis__c,
							Mi_vm_von__c,
							Mi_vm_bis__c,
							Mi_nm_von__c,
							Mi_nm_bis__c,
							Do_vm_von__c,
							Do_vm_bis__c,
							Do_nm_von__c,
							Do_nm_bis__c,
							Fr_vm_von__c,
							Fr_vm_bis__c,
							Fr_nm_von__c,
							Fr_nm_bis__c,
							Sa_vm_von__c,
							Sa_vm_bis__c,
							Sa_nm_von__c,
							Sa_nm_bis__c,
							So_vm_von__c,
							So_vm_bis__c,
							So_nm_von__c,
							So_nm_bis__c,
							Gz_Mo_vm_von__c,
							Gz_Mo_vm_bis__c,
							Gz_Mo_nm_von__c,
							Gz_Mo_nm_bis__c,
							Gz_Di_vm_von__c,
							Gz_Di_vm_bis__c,
							Gz_Di_nm_von__c,
							Gz_Di_nm_bis__c,
							Gz_Mi_vm_von__c,
							Gz_Mi_vm_bis__c,
							Gz_Mi_nm_von__c,
							Gz_Mi_nm_bis__c,
							Gz_Do_vm_von__c,
							Gz_Do_vm_bis__c,
							Gz_Do_nm_von__c,
							Gz_Do_nm_bis__c,
							Gz_Fr_vm_von__c,
							Gz_Fr_vm_bis__c,
							Gz_Fr_nm_von__c,
							Gz_Fr_nm_bis__c,
							Gz_Sa_vm_von__c,
							Gz_Sa_vm_bis__c,
							Gz_Sa_nm_von__c,
							Gz_Sa_nm_bis__c,
							Gz_So_vm_von__c,
							Gz_So_vm_bis__c,
							Gz_So_nm_von__c,
							Gz_So_nm_bis__c
					FROM Account
					WHERE Id = :iv_currentObjectId
					LIMIT 1
			];
		}
		return iv_oldMAEFaccount;
	}
	
	public Account getTempMAEFAccount () {
		return iv_tempMAEFaccount;
	}
	
	public Contract getTempMAEFContract () {
		return iv_tempMAEFcontract;
	}
}