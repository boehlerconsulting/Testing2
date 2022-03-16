/**
 *@author       Mats Böhler
 *@created      07.12.2021
 *
 *
 *@description  BeauftragungTvMCtrl
 *
 *
 *@changelog    07.12.2021 Mats Böhler  - Created
 *              
 * 
 */
public with sharing class BeauftragungTvMCtrl {
	
	@TestVisible
	private List<SObject> data = new List<SObject>();
	private String recordId = '';
	@TestVisible
	private List<Id> contentDocumentIds = new List<Id>();
	private Lead lead = new Lead();
	private Decimal miete;
	private Decimal strom;
	private String vertragsanpassungen;
	private String sonstiges;
	private String fileIds;
	private SchwellenwerteVertragserstellung__mdt schwellenwerteVertragserstellung;
	
	@AuraEnabled
	public static String initialize ( String leadId ) {
		BeauftragungTvMCtrl instance = new BeauftragungTvMCtrl();
		try {
			instance.recordId = leadId;
			instance.loadRelatedContentDocumentIds( leadId );
			instance.loadLead();
			instance.loadSchwellenwerte();
			return JSON.serialize( instance );
		}
		catch ( Exception e ) {
			throw new AuraHandledException( e.getMessage() );
		}
	}
	
	@AuraEnabled
	public static void sendEmail ( Id leadId, String miete, String strom, String vertragsanpassungen, String sonstiges, String fileIds ) {
		Savepoint savepoint = Database.setSavepoint();
		BeauftragungTvMCtrl instance = new BeauftragungTvMCtrl();
		try {
			instance.recordId = leadId;
			instance.miete = miete == null || miete == '' ? null : Decimal.valueOf( miete );
			instance.strom = strom == null || strom == '' ? null : Decimal.valueOf( strom );
			instance.vertragsanpassungen = vertragsanpassungen;
			instance.sonstiges = sonstiges;
			instance.fileIds = fileIds;
			instance.loadLead();
			instance.processEmail();
		}
		catch ( Exception e ) {
			Database.rollback( savepoint );
			throw new AuraHandledException( e.getMessage() );
		}
	}
	
	private void processEmail () {
		loadSchwellenwerte();
		EmailSettingService.Request request = new EmailSettingService.Request();
		request.recordId = lead.Id;
		request.emailSettingName = 'Beauftragung_TVM';
		request.leadId = lead.Id;
		request.documentName = 'Beauftragung TVM';
		EmailSettingService.getInstance().requests.add( request );
		List<EmailVersand__c> emailDeliveries
				= EmailSettingService.getInstance().createMessages().getEmailDispatcherServiceDeliveries();
		for ( EmailVersand__c emailVersand : emailDeliveries ) {
			if ( miete > schwellenwerteVertragserstellung.MieteInEuro__c
					|| strom > schwellenwerteVertragserstellung.StrompreisInCent__c ) {
				emailVersand.Email_an__c = lead.VL__r.GL__r.Leiter__r.Email;
			}
			if ( lead.Akquisemodus__c == 'Standortaufnahme vor Ort; Danach Übergabe an rVU' ) {
				emailVersand.Email_von__c = lead.VL__r.GL__r.RVU_Team__r.EMail__c;
			}
			if ( lead.PODID_Lookup__c != null ) {
				emailVersand.Email_Betreff__c += ', PODID ' + lead.PODID_Lookup__r.Wert__c;
			}
			emailVersand.Email_Nachricht__c = getNachricht(emailVersand.Email_Nachricht__c);
		}
		insert emailDeliveries;
		createContentDocumentLinks( emailDeliveries[0].Id );
		TriggerHandler.bypass( 'LeadTriggerHandler' );
		update new Lead(
				Id = lead.Id,
				LeadAnTVMUebergebenDatum__c = Date.today()
		);
		TriggerHandler.clearAllBypasses();
	}
	
	private void loadSchwellenwerte () {
		schwellenwerteVertragserstellung = [
				SELECT
						Id,
						StrompreisInCent__c,
						MieteInEuro__c
				FROM SchwellenwerteVertragserstellung__mdt
				LIMIT 1
		];
	}
	
	private void createContentDocumentLinks ( Id deliveryId ) {
		List<ContentDocumentLink> contentDocumentLinks = new List<ContentDocumentLink>();
		for ( String fileId : fileIds.split( ',' ) ) {
			contentDocumentLinks.add(
					new ContentDocumentLink(
							ContentDocumentId = fileId,
							LinkedEntityId = deliveryId,
							ShareType = 'I',
							Visibility = 'AllUsers'
					)
			
			);
			contentDocumentLinks.add(
					new ContentDocumentLink(
							ContentDocumentId = fileId,
							LinkedEntityId = InterfaceUser.getInstance().getId(),
							ShareType = 'V',
							Visibility = 'AllUsers'
					)
			);
		}
		Database.insert( contentDocumentLinks, false );
	}
	
	private String getNachricht ( String nachricht ) {
		nachricht = nachricht.replace( '{Miethoehe}', CurrencyFormatter.format( miete, '€' ) );
		nachricht = nachricht.replace( '{Stromkosten}', CurrencyFormatter.format( strom, '¢' ) );
		nachricht = nachricht.replace( '{Vertragsanpassungen}', returnEmptyIfNull( vertragsanpassungen ).replace( '\n', '<br/>' ) );
		nachricht = nachricht.replace( '{Sonstiges}', returnEmptyIfNull( sonstiges ).replace( '\n', '<br/>' ) );
		
		if ( strom > schwellenwerteVertragserstellung.StrompreisInCent__c
				|| miete > schwellenwerteVertragserstellung.MieteInEuro__c ) {
			
			if ( lead.Akquisemodus__c == 'Standortaufnahme vor Ort; Danach Übergabe an rVU' ) {
				nachricht += '<br/><p>Bei den Mietkosten / Stromkosten wurde der Schwellenwert überschritten. ' +
						'Da es sich um einen Lead im Akquisemodus „Standortaufnahme vor Ort; ' +
						'Danach Übergabe an rVU“ handelt, stimmen Sie die Freigabe bitte intern ab.</p>';
			}
			else {
				nachricht += '<br/><p>Sie erhalten dieses Mail wegen Schwellenwert Überschreitungen zur Freigabe. ' +
						'Sollten Sie mit den Werten einverstanden sein, leiten Sie das Mail bitte an ' +
						'<a href="mailto:Vertragsmanagement4400@deutschepost.de">Vertragsmanagement4400@deutschepost.de</a> weiter.</p><br/>' +
						'<p>Wenn nicht, besprechen Sie bitte die weiteren Schritte mit Ihrer/Ihrem Vertriebsmanager*in.</p>';
			}
		}
		return nachricht;
	}
	
	private String returnEmptyIfNull ( String value ) {
		return value == null ? '' : value;
	}
	
	private void loadLead () {
		lead = [
				SELECT
						Id,
						Stromanschluss__c,
						VL__r.GL__r.EMail__c,
						Akquisemodus__c,
						VL__r.GL__r.RVU_Team__r.EMail__c,
						VL__r.GL__r.Leiter__r.Email,
						PostalCode,
						City,
						Company,
						PODID_Lookup__r.Wert__c,
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
		] ) {
			
			contentDocumentIds.add( contentDocumentLink.ContentDocumentId );
			data.add( contentDocumentLink );
		}
	}
}