/**
 *@author       Mats Böhler
 *@created      24.06.2020
 *
 *
 *@description  StandortpraesentationPackstationCtrl
 *
 *
 *@changelog    24.06.2020 Mats Böhler  - Created
 *              
 * 
 */
public without sharing class StandortpraesentationPackstationCtrl {
	
	private Lead lead = null;
	private Id leadId = null;
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
	
	public void controllerAction () {
		extractParameters( ApexPages.currentPage() );
		createDocumentsFromContentDocuments();
		buildDocumentLinks();
		init();
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
	
	public String getLink () {
		return Url.getSalesforceBaseUrl().toExternalForm() + '/' + lead.Id ;
	}
	
	public String getVL () {
		return lead.VL__r.Name == null
				? ''
				: lead.VL__r.Name.remove( 'Packstation Regionalteam ' );
	}
	
	public String getPostLogo () {
		return getLogo( 'Packstation_Logo_Deutschepost_DHL' );
	}
	
	public String getPackstationLogo () {
		return getLogo( 'Packstation_Logo_Packstation' );
	}
	
	public StandortpraesentationPackstationCtrl generateUrl ( String leadId, Map<String, String> picturesByPage ) {
		this.picturesByPage = picturesByPage;
		pageUrl = '/apex/StandortpraesentationPackstation?id=' + leadId;
		for ( String page : picturesByPage.keySet() ) {
			addPageOneParameters( page );
			addPageTwoParameters( page );
			addPageThreeParameters( page );
			addPageFourParameters( page );
		}
		return this;
	}
	
	public StandortpraesentationPackstationCtrl renderPresentation () {
		PageReference page = new PageReference( pageUrl );
		presentationContent = Test.isRunningTest() ? Blob.valueOf( 'Test' ) : page.getContent();
		extractParameters( page );
		init();
		return this;
	}
	
	public StandortpraesentationPackstationCtrl savePresentation () {

		String title = '1-3_' + lead.PostalCode + '_' + lead.City + '_' + lead.Street + '_' + Date.today().format();
		String description = 'Standortpräsentation Packstation';
		
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
	
	private void addPageTwoParameters ( String page ) {
		if ( page == '2' ) {
			Integer i = 9;
			for ( String contentDocumentId : picturesByPage.get( page ).split( ',' ) ) {
				pageUrl += '&pic' + String.valueOf( i ) + '=' + contentDocumentId;
				i++;
			}
		}
	}
	
	private void addPageThreeParameters ( String page ) {
		if ( page == '3' ) {
			Integer i = 11;
			for ( String contentDocumentId : picturesByPage.get( page ).split( ',' ) ) {
				pageUrl += '&pic' + String.valueOf( i ) + '=' + contentDocumentId;
				i++;
			}
		}
	}
	
	private void addPageFourParameters ( String page ) {
		if ( page == '4' ) {
			Integer i = 13;
			for ( String contentDocumentId : picturesByPage.get( page ).split( ',' ) ) {
				pageUrl += '&pic' + String.valueOf( i ) + '=' + contentDocumentId;
				i++;
			}
		}
	}
	
	private void buildDocumentLinks () {
		for ( Integer i = 1; i <= 13; i++ ) {
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
		for ( Integer i = 1; i <= 13; i++ ) {
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
						Company
				FROM Lead
				WHERE Id = :leadId
				LIMIT 1
		] : lead;
	
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