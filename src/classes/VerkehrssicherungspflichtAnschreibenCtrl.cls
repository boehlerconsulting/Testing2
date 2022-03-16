/**
 *@author       Mats Böhler
 *@created      20.10.2020
 *
 *
 *@description  VerkehrssicherungspflichtAnschreibenCtrl
 *
 *
 *@changelog    20.10.2020 Mats Böhler  - Created
 *              
 * 
 */
public without sharing class VerkehrssicherungspflichtAnschreibenCtrl {
	
	@TestVisible
	private List<Id> contentDocumentIds = new List<Id>();
	private Boolean hasAccess = false;
	private Boolean hasMissingFields = false;
	private Lead lead = new Lead();
	
	@AuraEnabled
	public static void createPresentation (
			String leadId,
			Map<String, String> picturesByPage,
			List<Id> uploadedFileIds,
			Boolean isVollstaendig,
			Boolean isWerktags,
			Boolean isSonntags,
			Boolean isSonstiges,
			String angaben,
			String bemerkungen ) {
		
		try {
			new VorbeauftragungCSGCtrl()
					.generateUrl(
					leadId,
					picturesByPage,
					isVollstaendig,
					isWerktags,
					isSonntags,
					isSonstiges,
					angaben,
					bemerkungen )
					.renderPresentation()
					.savePresentation()
					.deleteTemporaryDocuments();
			
			deleteUploadedFiles( uploadedFileIds );
		}
		catch ( Exception e ) {
			throw new AuraHandledException( e.getMessage() );
		}
	}
	
	@AuraEnabled
	public static void deleteFiles ( List<Id> uploadedFileIds ) {
		try {
			deleteUploadedFiles( uploadedFileIds );
		}
		catch ( Exception e ) {
			throw new AuraHandledException( e.getMessage() );
		}
	}
	
	@AuraEnabled
	public static String init ( String leadId ) {
		VerkehrssicherungspflichtAnschreibenCtrl instance = new VerkehrssicherungspflichtAnschreibenCtrl();
		try {
			instance.contentDocumentIds = loadRelatedContentDocumentIds( leadId );
			instance.hasAccess = FeatureManagement.checkPermission( 'VertragserstellungPackstation' );
			instance.loadLead( leadId );
			
			if ( instance.lead.PostalCode == null ) {
				instance.hasMissingFields = true;
			}
		}
		catch ( Exception e ) {
			throw new AuraHandledException( e.getMessage() );
		}
		return JSON.serialize( instance );
	}
	
	private static void deleteUploadedFiles ( List<Id> uploadedFileIds ) {
		
		if ( !uploadedFileIds.isEmpty() ) {
			List<ContentDocument> contentDocuments = new List<ContentDocument>();
			for ( Id contentDocumentId : uploadedFileIds ) {
				contentDocuments.add(
						new ContentDocument(
								Id = contentDocumentId
						)
				);
			}
			delete contentDocuments;
			Database.emptyRecycleBin( contentDocuments );
		}
	}
	
	private void loadLead ( Id leadId ) {
		lead = [
				SELECT
						Id,
						PostalCode,
						PODID_Lookup__r.Wert__c,
						Akquisemodus__c,
						Oeffentlicher_Zugang__c
				FROM Lead
				WHERE Id = :leadId
		];
	}
	
	private static List<Id> loadRelatedContentDocumentIds ( String leadId ) {
		List<Id> contentDocumentIds = new List<Id>();
		Set<String> allowedFileExtensions = new Set<String>();
		allowedFileExtensions.add( 'jpeg' );
		allowedFileExtensions.add( 'jpg' );
		allowedFileExtensions.add( 'jpe' );
		allowedFileExtensions.add( 'tiff' );
		allowedFileExtensions.add( 'tif' );
		allowedFileExtensions.add( 'bmp' );
		allowedFileExtensions.add( 'gif' );
		allowedFileExtensions.add( 'png' );
		for ( ContentDocumentLink contentDocumentLink : [
				SELECT
						ContentDocumentId,
						ContentDocument.FileExtension
				FROM ContentDocumentLink
				WHERE LinkedEntityId = :leadId
				AND ContentDocument.FileExtension IN :allowedFileExtensions
		] ) {
			
			contentDocumentIds.add( contentDocumentLink.ContentDocumentId );
		}
		return contentDocumentIds;
	}
}