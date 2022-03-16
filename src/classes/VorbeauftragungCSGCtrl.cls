/**
 *@author       Mats Böhler
 *@created      20.10.2020
 *
 *
 *@description  VorbeauftragungCSGCtrl
 *
 *
 *@changelog    20.10.2020 Mats Böhler  - Created
 *              
 * 
 */
public without sharing class VorbeauftragungCSGCtrl {
	
	private Lead lead = null;
	private Id leadId = null;
	private AnschriftCSG__mdt anschriftCSG = new AnschriftCSG__mdt();
	private Map<String, String> contentDocumentIdByParameterName = new Map<String, String>();
	private Map<String, String> parameterNameByContentDocumentId = new Map<String, String>();
	private Blob presentationContent = null;
	private String folderId = '';
	private String pageUrl = '';
	private Map<String, String> documentIdByDeveloperName = new Map<String, String>();
	private Map<String, Document> documentByParameterName = new Map<String, Document>();
	private Map<String, String> pictureUrlByParameterName = new Map<String, String>();
	private Map<String, Boolean> pictureExistsByParameterName = new Map<String, Boolean>();
	private Map<String, String> picturesByPage = new Map<String, String>();
	public String angaben = '';
	public String bemerkungen = '';
	public Boolean isVollstaendig = false;
	public Boolean isWerktags = false;
	public Boolean isSonntags = false;
	public Boolean isSonstiges = false;
	
	public void controllerAction () {
		extractParameters( ApexPages.currentPage() );
		createDocumentsFromContentDocuments();
		buildDocumentLinks();
		init();
	}
	
	public String getAngaben () {
		return angaben;
	}
	
	public String getBemerkungen () {
		return bemerkungen;
	}
	
	public Boolean getVollstaendig () {
		return isVollstaendig;
	}
	
	public Boolean getWerktags () {
		return isWerktags;
	}
	
	public Boolean getSonntags () {
		return isSonntags;
	}
	
	public Boolean getSonstiges () {
		return isSonstiges;
	}
	
	public Map<String, String> getPicture () {
		return pictureUrlByParameterName;
	}
	
	public Map<String, Boolean> getPictureExists () {
		return pictureExistsByParameterName;
	}
	
	public Lead getLead () {
		return lead;
	}
	
	public String getBezeichnung(){
		return anschriftCSG.Bezeichnung__c;
	}
	
	public String getStrasse(){
		return anschriftCSG.Strasse__c;
	}
	
	public String getPostleitzahl(){
		return anschriftCSG.Postleitzahl__c;
	}
	
	public String getOrt(){
		return anschriftCSG.Ort__c;
	}
	
	public String getLink () {
		return Url.getSalesforceBaseUrl().toExternalForm() + '/' + lead.Id ;
	}
	
	public String getVL () {
		User currentUser = [ SELECT Id, OrgE_DP__c FROM User WHERE Id = :UserInfo.getUserId() ];
		return currentUser.OrgE_DP__c.length() > 8 ? currentUser.OrgE_DP__c.substring( 8 ) : currentUser.OrgE_DP__c;
	}
	
	public String getPostLogo () {
		return getLogo( 'Packstation_Logo_Deutschepost_DHL' );
	}
	
	public String getPackstationLogo () {
		return getLogo( 'Packstation_Logo_Packstation' );
	}
	
	public VorbeauftragungCSGCtrl generateUrl (
			String leadId,
			Map<String, String> picturesByPage,
			Boolean isVollstaendig,
			Boolean isWerktags,
			Boolean isSonntags,
			Boolean isSonstiges,
			String angaben,
			String bemerkungen ) {
		this.picturesByPage = picturesByPage;
		pageUrl = '/apex/VorbeauftragungCSG?id=' + leadId;
		for ( String page : picturesByPage.keySet() ) {
			addPageOneParameters( page );
		}
		pageUrl += '&isVollstaendig=' + isVollstaendig;
		pageUrl += '&isWerktags=' + isWerktags;
		pageUrl += '&isSonntags=' + isSonntags;
		pageUrl += '&isSonstiges=' + isSonstiges;
		pageUrl += '&angaben=' + angaben;
		pageUrl += '&bemerkungen=' + bemerkungen;
		return this;
	}
	
	public VorbeauftragungCSGCtrl renderPresentation () {
		
		PageReference page = new PageReference( pageUrl );
		presentationContent = Test.isRunningTest() ? Blob.valueOf( 'Test' ) : page.getContent();
		extractParameters( page );
		init();
		return this;
	}
	
	public VorbeauftragungCSGCtrl savePresentation () {
		String title = '2a6_' + lead.PODID_Lookup__r.Wert__c + '_' + lead.City + '_' + lead.Street + '_' + lead.Company;
		if ( !String.isEmpty( lead.STOG_Gesellschaft__c ) ) {
			title += '-' + lead.STOG_Gesellschaft__c + '_VSP';
		}
		else {
			title += '_VSP';
		}
		String description = 'Vorbeauftragung CSG';
		
		List<ContentDocumentLink> contentDocumentLinks = [
				SELECT
						ContentDocumentId
				FROM ContentDocumentLink
				WHERE LinkedEntityId = :leadId
				AND ContentDocument.Description = :description
				LIMIT 1
		];
		Id contentDocumentId = ( contentDocumentLinks.size() == 1 ) ? contentDocumentLinks.get( 0 ).ContentDocumentId : null;
		
		ContentVersion contentVersion = new ContentVersion();
		contentVersion.ContentDocumentId = contentDocumentId != null ? contentDocumentId : null;
		contentVersion.VersionData = presentationContent;
		contentVersion.Title = title;
		contentVersion.Description = description;
		contentVersion.PathOnClient = title + '.pdf';
		insert contentVersion;
		
		if ( contentDocumentId == null ) {
			ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
			contentDocumentLink.ContentDocumentId = [
					SELECT
							ContentDocumentId
					FROM ContentVersion
					WHERE Id = :contentVersion.Id
					LIMIT 1
			].ContentDocumentId;
			contentDocumentLink.ShareType = 'I';
			contentDocumentLink.Visibility = 'AllUsers';
			contentDocumentLink.LinkedEntityId = leadId;
			insert contentDocumentLink;
		}
		
		return this;
	}
	
	public void deleteTemporaryDocuments () {
		List<Document> documents = [
				SELECT
						Id
				FROM Document
				WHERE FolderId = :getFolderId()
				AND Name = 'Temp'
		];
		if ( !documents.isEmpty() ) {
			delete documents;
			Database.emptyRecycleBin( documents );
		}
	}
	
	private void addPageOneParameters ( String page ) {
		if ( page == '1' ) {
			Integer i = 1;
			for ( String contentDocumentId : picturesByPage.get( page ).split( ',' ) ) {
				pageUrl += '&pic' + String.valueOf( i ) + '=' + contentDocumentId;
				i++;
			}
		}
	}
	
	private void buildDocumentLinks () {
		for ( Integer i = 1; i <= 12; i++ ) {
			String parameterName = 'pic' + String.valueOf( i );
			pictureUrlByParameterName.put(
					parameterName,
					documentByParameterName.containsKey( parameterName )
							? generateDocumentUrl( documentByParameterName.get( parameterName ).Id )
							: ''
			);
			pictureExistsByParameterName.put(
					parameterName,
					documentByParameterName.containsKey( parameterName )
			);
		}
	}
	
	private String generateDocumentUrl ( String documentId ) {
		return Url.getSalesforceBaseUrl().toExternalForm().replace( 'visualforce.com', 'documentforce.com' )
				+ '/servlet/servlet.ImageServer?id='
				+ documentId
				+ '&oid='
				+ UserInfo.getOrganizationId();
	}
	
	private void extractParameters ( PageReference page ) {
		leadId = page.getParameters().get( 'id' );
		isVollstaendig = page.getParameters().get( 'isVollstaendig' ) == 'true';
		isWerktags = page.getParameters().get( 'isWerktags' ) == 'true';
		isSonntags = page.getParameters().get( 'isSonntags' ) == 'true';
		isSonstiges = page.getParameters().get( 'isSonstiges' ) == 'true';
		angaben = page.getParameters().get( 'angaben' );
		bemerkungen = page.getParameters().get( 'bemerkungen' );
		for ( Integer i = 1; i <= 12; i++ ) {
			String parameterName = 'pic' + String.valueOf( i );
			String contentDocumentId = page.getParameters().get( parameterName );
			if ( String.isNotBlank( contentDocumentId ) ) {
				contentDocumentIdByParameterName.put(
						parameterName,
						contentDocumentId
				);
				parameterNameByContentDocumentId.put(
						contentDocumentId,
						parameterName
				);
			}
		}
	}
	
	private void createDocumentsFromContentDocuments () {
		
		for ( ContentVersion contentVersion : [
				SELECT
						Id,
						VersionData,
						FileExtension,
						ContentDocumentId
				FROM ContentVersion
				WHERE ContentDocumentId IN :contentDocumentIdByParameterName.values()
				AND IsLatest = TRUE
		] ) {
			String parameterName = parameterNameByContentDocumentId.containsKey( contentVersion.ContentDocumentId )
					? parameterNameByContentDocumentId.get( contentVersion.ContentDocumentId )
					: '';
			if ( parameterName == '' ) {
				continue;
			}
			documentByParameterName.put(
					parameterName,
					new Document(
							Name = 'Temp',
							Description = contentVersion.ContentDocumentId,
							Body = contentVersion.VersionData,
							IsPublic = true,
							FolderId = getFolderId(),
							Type = contentVersion.FileExtension
					)
			);
		}
		insert documentByParameterName.values();
	}
	
	private void init () {
		
		loadLogos();
		
		lead = lead == null ? [
				SELECT
						Id,
						City,
						PostalCode,
						Street,
						PODID_Lookup__r.Wert__c,
						VL__r.Name,
						Company,
						FirstName,
						LastName,
						Phone,
						MobilePhone,
						Fax,
						Email,
						Salutation,
						Strategischer_Partner__c,
						Strategischer_Partner__r.Name,
						Strategischer_Partner__r.BillingCity,
						Strategischer_Partner__r.BillingStreet,
						Strategischer_Partner__r.BillingPostalCode,
						STOG_Gesellschaft__c,
						ADM_Typ__c,
						ADM_Hersteller__c
				FROM Lead
				WHERE Id = :leadId
				LIMIT 1
		] : lead;
		
		for ( AnschriftCSG__mdt anschrift : [
				SELECT
						Id,
						Region__c,
						Strasse__c,
						Postleitzahl__c,
						Ort__c,
						Bezeichnung__c,
						EmailAdresse__c,
						TeamManager__c,
						TeamManagerEmailAdresse__c,
						Leitregionen__c
				FROM AnschriftCSG__mdt
		] ) {
			if ( lead.PostalCode != null
					&& anschrift.Leitregionen__c.contains( lead.PostalCode.left( 2 ) ) ) {
				
				anschriftCSG = anschrift;
			}
		}
	}
	
	private void loadLogos () {
		if ( !documentIdByDeveloperName.isEmpty() ) {
			return;
		}
		for ( Document document : [
				SELECT
						Id,
						DeveloperName
				FROM Document
				WHERE FolderId = :getFolderId()
		] ) {
			
			documentIdByDeveloperName.put( document.DeveloperName, document.Id );
		}
	}
	
	private String getLogo ( String documentName ) {
		return Url.getSalesforceBaseUrl().toExternalForm().replace( 'visualforce.com', 'documentforce.com' )
				+ '/servlet/servlet.ImageServer?id='
				+ documentIdByDeveloperName.get( documentName )
				+ '&oid='
				+ UserInfo.getOrganizationId();
	}
	
	private String getFolderId () {
		if ( folderId == '' ) {
			folderId = [
					SELECT
							Id
					FROM Folder
					WHERE DeveloperName = 'Packstation_Standortpraesentation'
					LIMIT 1
			].Id;
		}
		return folderId;
	}
}