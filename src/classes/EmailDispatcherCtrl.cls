/**
 *@author       Mats Böhler
 *@created      15.05.2020
 *
 *
 *@description  EmailDispatcherCtrl
 *
 *
 *@changelog    15.05.2020 Mats Böhler  - Created
 *              
 * 
 */
public without sharing class EmailDispatcherCtrl {
	
	@TestVisible
	private List<SObject> data = new List<SObject>();
	private String recordId = '';
	private Boolean isSent = false;
	@TestVisible
	private List<Id> contentDocumentIds = new List<Id>();
	private Lead lead = new Lead();
	@TestVisible
	private static Boolean setPODID = false;
	
	@AuraEnabled
	public static String init ( String leadId ) {
		EmailDispatcherCtrl instance = new EmailDispatcherCtrl();
		try {
			instance.recordId = leadId;
			instance.contentDocumentIds = loadRelatedContentDocumentIds( leadId );
			instance.loadLead();
			if ( instance.lead.Oeffentlicher_Zugang__c == null ) {
				throw new EmailDispatcherCtrlException( 'Bitte pflegen Sie das Feld "Öffentlicher Zugang".' );
			}
			if ( instance.lead.PODID_Lookup__r.Wert__c == null
					&& instance.lead.Akquisemodus__c != 'Standortaufnahme vor Ort; Danach Übergabe an rVU'
					&& instance.lead.Oeffentlicher_Zugang__c != null
					&& ( CurrentUser.getInstance().getUser().Profile.Name.contains( 'myPM Vertrieb (V' )
					|| CurrentUser.getInstance().getUser().Profile.Name.contains( 'myPM Packstation Vertrieb' )
					|| setPODID ) ) {
				
				Map<Id, PODID__c> podIdByLeadIds = new PodIdService().generate( new Set<Id> {
						leadId
				} );
				if ( podIdByLeadIds.containsKey( leadId ) ) {
					update new Lead(
							Id = leadId,
							PODID_Lookup__c = podIdByLeadIds.get( leadId ).Id
					);
				}
				else {
					throw new EmailDispatcherCtrlException( Label.POIDsVerbraucht );
				}
			}
			if ( instance.lead.EMailStatus__c != null ) {
				instance.isSent = instance.lead.EMailStatus__c.contains( 'Vorbeauftragung CSG angestoßen' );
			}
		}
		catch ( Exception e ) {
			throw new AuraHandledException( e.getMessage() );
		}
		return JSON.serialize( instance );
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
	public static void sendEmail ( Id leadId, String selectedFileIds ) {
		EmailDispatcherCtrl instance = new EmailDispatcherCtrl();
		Savepoint savepoint = Database.setSavepoint();
		try {
			instance.recordId = leadId;
			instance.loadLead();
			update new Lead(
					Id = leadId,
					Beauftragung_CSG__c = Date.today(),
					EMailStatus__c = 'Vorbeauftragung CSG angestoßen'
			);
			EmailSettingService.Request request = new EmailSettingService.Request();
			request.recordId = leadId;
			request.emailSettingName = Test.isRunningTest()
					? 'Vorbeauftragung_CSG_Berlin'
					: instance.getRegionFilter( instance.lead.VL__r.Name );
			request.leadId = leadId;
			request.selectedFileIds = selectedFileIds;
			request.documentName = 'Packstation - Mietvertrag';
			EmailSettingService.getInstance().requests.add(request);
			EmailSettingService.getInstance().createMessages().callEmailDispatcherService();
		}
		catch ( Exception e ) {
			Database.rollback( savepoint );
			throw new AuraHandledException( e.getMessage() );
		}
	}
	
	/**
	 * @description deletes all content documents for the given id list
	 * @param uploadedFileIds list if contentDocument ids for deletion
	 **/
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
	
	private String getRegionFilter ( String vlName ) {
		return 'Vorbeauftragung_CSG_' + vlName.replace( 'ü', 'ue' ).replace( 'ä', 'ae' ).replace( 'ö', 'oe' );
	}
	
	private void loadLead () {
		lead = [
				SELECT
						Id,
						Owner.Email,
						EMailStatus__c,
						VL__r.Name,
						Name,
						Vertrag_unterschrieben__c,
						Beauftragung_CSG__c,
						Oeffentlicher_Zugang__c,
						PODID_Lookup__r.Wert__c,
						Akquisemodus__c
				FROM Lead
				WHERE Id = :recordId
				LIMIT 1
		];
	}
	
	private static List<Id> loadRelatedContentDocumentIds ( String leadId ) {
		List<Id> contentDocumentIds = new List<Id>();
		
		for ( ContentDocumentLink contentDocumentLink : [
				SELECT
						ContentDocumentId,
						ContentDocument.FileExtension
				FROM ContentDocumentLink
				WHERE LinkedEntityId = :leadId
		] ) {
			
			contentDocumentIds.add( contentDocumentLink.ContentDocumentId );
		}
		return contentDocumentIds;
	}
	
	public class EmailDispatcherCtrlException extends Exception {
	
	}
}