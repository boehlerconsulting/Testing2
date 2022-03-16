/**
 *@author       Mats Böhler
 *@created      29.06.2020
 *
 *
 *@description  StandortpraesentationPackstationAuraCtrl
 *
 *
 *@changelog    29.06.2020 Mats Böhler  - Created
 *              
 * 
 */
public without sharing class StandortpraesentationPackstationAuraCtrl {
	
	@AuraEnabled
	public static void createPresentation ( String leadId, Map<String, String> picturesByPage, List<Id> uploadedFileIds ) {
		try {
			new StandortpraesentationPackstationCtrl()
					.generateUrl( leadId, picturesByPage )
					.renderPresentation()
					.savePresentation()
					.deleteTemporaryDocuments();
			
			deleteUploadedFiles( uploadedFileIds );
			Lead existingLead = [
					SELECT
							Id,
							DokumentationErstelltDatum__c
					FROM Lead
					WHERE Id = :leadId
			];
			update new Lead(
					Id = leadId,
					DokumentationErstelltDatum__c = existingLead.DokumentationErstelltDatum__c == null
							? Date.today()
							: existingLead.DokumentationErstelltDatum__c,
					DokumentationErstellt__c = Date.today(),
					DokumentationDurchRTFreigebenDatum__c = null
			);
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
	public static List<Id> init ( String leadId ) {
		List<Id> contentDocumentIds = new List<Id>();
		try {
			contentDocumentIds = loadRelatedContentDocumentIds( leadId );
		}
		catch ( Exception e ) {
			throw new AuraHandledException( e.getMessage() );
		}
		return contentDocumentIds;
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