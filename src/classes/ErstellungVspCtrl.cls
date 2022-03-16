/**
 *@author       Mats Böhler
 *@created      04.01.2022
 *
 *
 *@description  ErstellungVspCtrl
 *
 *
 *@changelog    04.01.2022 Mats Böhler  - Created
 *              
 * 
 */
public with sharing class ErstellungVspCtrl {
	
	private static final Integer MAX_SIZE = 2100000;
	
	@TestVisible
	private List<SObject> data = new List<SObject>();
	private String recordId = '';
	@TestVisible
	private List<Id> contentDocumentIds = new List<Id>();
	private Lead lead = new Lead();
	private String encodedPdf;
	private String encodedImage;
	private User currentUser;
	private AnschriftCSG__mdt csgAddress;
	private Boolean isPng = false;
	private String contentDocumentId;
	
	@AuraEnabled
	public static String initialize ( String leadId ) {
		ErstellungVspCtrl instance = new ErstellungVspCtrl();
		try {
			instance.recordId = leadId;
			instance.loadRelatedContentDocumentIds( leadId );
			instance.loadLead();
			instance.loadUser();
			instance.loadCsgAddress();
			return JSON.serialize( instance );
		}
		catch ( Exception e ) {
			throw new AuraHandledException( e.getMessage() );
		}
	}
	
	@AuraEnabled
	public static void validateImageSize ( String contentDocumentId ) {
		ContentDocument contentDocument = [ SELECT Id, ContentSize FROM ContentDocument WHERE Id = :contentDocumentId LIMIT 1 ];
		if ( contentDocument.ContentSize > MAX_SIZE ) {
			delete contentDocument;
			Database.emptyRecycleBin( contentDocument );
			throw new AuraHandledException( 'Das Bild darf nicht größer als 2 MB sein.' );
		}
	}
	
	@AuraEnabled
	public static String create ( String selectedContentDocumentId, String leadString ) {
		Savepoint savepoint = Database.setSavepoint();
		ErstellungVspCtrl instance = new ErstellungVspCtrl();
		try {
			instance.lead = ( Lead ) JSON.deserialize( leadString, Lead.class );
			instance.recordId = instance.lead.Id;
			instance.evaluatePodId();
			instance.loadLead();
			instance.loadPdf();
			instance.loadImage( selectedContentDocumentId );
		}
		catch ( Exception e ) {
			Database.rollback( savepoint );
			throw new AuraHandledException( e.getMessage() );
		}
		return JSON.serialize( instance );
	}
	
	@AuraEnabled
	public static String save ( String data, String leadString ) {
		Savepoint savepoint = Database.setSavepoint();
		ErstellungVspCtrl instance = new ErstellungVspCtrl();
		try {
			instance.lead = ( Lead ) JSON.deserialize( leadString, Lead.class );
			instance.saveFile( data );
		}
		catch ( Exception e ) {
			Database.rollback( savepoint );
			throw new AuraHandledException( e.getMessage() );
		}
		return instance.contentDocumentId;
	}
	
	private void evaluatePodId () {
		if ( lead.Akquisemodus__c != 'Standortaufnahme vor Ort; Danach Übergabe an rVU'
				&& lead.PODID_Lookup__c == null ) {
			generatePodId();
		}
	}
	
	private void generatePodId () {
		Map<Id, PODID__c> podIdByLeadIds = new PodIdService().generate( new Set<Id> {
				lead.Id
		} );
		if ( podIdByLeadIds.containsKey( lead.Id ) ) {
			update new Lead(
					Id = lead.Id,
					PODID_Lookup__c = podIdByLeadIds.get( lead.Id ).Id
			);
		}
		else {
			throw new PodIdCtrl.PodIdCtrlException( Label.POIDsVerbraucht );
		}
	}
	
	private String getFileName () {
		return '2a6_' + lead.PODID_Lookup__r.Wert__c + '_' + lead.City + '_' + lead.Street + '_VSP';
	}
	
	private String getFileNameWithExtension () {
		return getFileName() + '.pdf';
	}
	
	private void saveFile ( String data ) {
		Set<Id> existingContentDocumentIds = new Set<Id>();
		Id linkedEntityId = lead.Id;
		List<ContentDocumentLink> existingContentDocumentLinks = [
				SELECT ContentDocumentId
				FROM ContentDocumentLink
				WHERE LinkedEntityId = :linkedEntityId
		];
		for ( ContentDocumentLink contentDocumentLink : existingContentDocumentLinks ) {
			existingContentDocumentIds.add( contentDocumentLink.ContentDocumentId );
		}
		
		List<ContentVersion> existingConentVersions = [
				SELECT ContentDocumentId
				FROM ContentVersion
				WHERE ContentDocumentId IN :existingContentDocumentIds
				AND PathOnClient = :getFileNameWithExtension()
				AND IsLatest = TRUE
				LIMIT 1
		];
		
		ContentVersion newContentVersion = new ContentVersion(
				Title = FileNameReplacer.replace( getFileName() ),
				PathOnClient = getFileNameWithExtension(),
				VersionData = EncodingUtil.base64Decode( data ),
				ContentLocation = 'S',
				ContentDocumentId = existingConentVersions.isEmpty() ? null : existingConentVersions[ 0 ].ContentDocumentId
		);
		insert newContentVersion;
		
		contentDocumentId = existingConentVersions.isEmpty()
				? [
						SELECT
								ContentDocumentId
						FROM ContentVersion
						WHERE Id = :newContentVersion.Id
				].ContentDocumentId
				: existingConentVersions[ 0 ].ContentDocumentId;
		
		List<ContentDocumentLink> contentDocumentLinks = new List<ContentDocumentLink>();
		ContentDocumentLink newContentDocumentLink = new ContentDocumentLink(
				ContentDocumentId = contentDocumentId,
				LinkedEntityId = lead.Id,
				ShareType = 'I',
				Visibility = 'AllUsers'
		);
		contentDocumentLinks.add( newContentDocumentLink );
		
		List<Database.SaveResult> saveResults = Database.insert( contentDocumentLinks, false );
		for ( Database.SaveResult saveResult : saveResults ) {
			if ( !saveResult.isSuccess()
					&& !saveResult.getErrors()[ 0 ].getMessage().toLowerCase().contains( 'already linked' )
					&& !saveResult.getErrors()[ 0 ].getMessage().toLowerCase().contains(
					'ist bereits mit der entität mit folgender id verknüpft' ) ) {
				Database.Error error = saveResult.getErrors()[ 0 ];
				throw new DmlException( error.getStatusCode() + ': ' + error.getMessage() );
			}
		}
	}
	
	private void loadPdf () {
		ContentVersion contentVersion = [
				SELECT
						Id,
						VersionData
				FROM ContentVersion
				WHERE IsLatest = TRUE
				AND Index__c = 'VSP'
				LIMIT 1
		];
		encodedPdf = EncodingUtil.base64Encode( contentVersion.VersionData );
	}
	
	private void loadImage ( String selectedContentDocumentId ) {
		ContentVersion contentVersion = [
				SELECT
						Id,
						VersionData,
						FileExtension
				FROM ContentVersion
				WHERE IsLatest = TRUE
				AND ContentDocumentId = :selectedContentDocumentId
				LIMIT 1
		];
		encodedImage = EncodingUtil.base64Encode( contentVersion.VersionData );
		isPng = contentVersion.FileExtension == 'png';
	}
	
	private void loadUser () {
		currentUser = [
				SELECT
						Id,
						City,
						Name
				FROM User
				WHERE Id = :UserInfo.getUserId()
				LIMIT 1
		];
	}
	
	private void loadCsgAddress () {
		for ( AnschriftCSG__mdt anschriftCSG : [
				SELECT
						Strasse__c,
						Postleitzahl__c,
						Ort__c,
						Leitregionen__c
				FROM AnschriftCSG__mdt
		] ) {
			if ( lead.PostalCode != null
					&& anschriftCSG.Leitregionen__c.contains( lead.PostalCode.left( 2 ) ) ) {
				
				csgAddress = anschriftCSG;
			}
		}
	}
	
	private void loadLead () {
		lead = [
				SELECT
						Id,
						Stromanschluss__c,
						City,
						Street,
						Akquisemodus__c,
						PODID_Lookup__c,
						PODID_Lookup__r.Wert__c,
						PODID_Lookup__r.Short_ID__c,
						PostalCode,
						FirstName,
						LastName,
						Phone,
						MobilePhone,
						Fax,
						Email,
						VL__r.Name,
						VL__r.GL__r.RVU_Team__r.Name,
						Address,
						Name
				FROM Lead
				WHERE Id = :recordId
				LIMIT 1
		];
	}
	
	private void loadRelatedContentDocumentIds ( String leadId ) {
		for ( ContentDocumentLink contentDocumentLink : [
				SELECT
						ContentDocumentId,
						ContentDocument.FileExtension,
						ContentDocument.Title
				FROM ContentDocumentLink
				WHERE LinkedEntityId = :leadId
				AND ContentDocument.ContentSize < :MAX_SIZE
				AND ( ContentDocument.FileExtension = 'jpg'
				OR ContentDocument.FileExtension = 'jpeg'
				OR ContentDocument.FileExtension = 'png' )
		] ) {
			
			contentDocumentIds.add( contentDocumentLink.ContentDocumentId );
			data.add( contentDocumentLink );
		}
	}
}