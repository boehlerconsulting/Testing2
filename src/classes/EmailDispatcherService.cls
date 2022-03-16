/**
 *@author       Mats Böhler
 *@created      15.05.2020
 *
 *
 *@description  EmailDispatcherService
 *
 *
 *@changelog    15.05.2020 Mats Böhler  - Created
 *              
 * 
 */
public without sharing class EmailDispatcherService {
	
	private List<EmailDispatcherService.Message> messages = new List<EmailDispatcherService.Message>();
	private Map<EmailDispatcherService.Message, EmailVersand__c> emailDeliveryByMessages
			= new Map<EmailDispatcherService.Message, EmailVersand__c>();
	private Map<String, Id> emailTemplateIdByDeveloperName = new Map<String, Id>();
	private Id talendUserId;
	@TestVisible
	private static Boolean disableDeleteExistingContentDocumentLinks = false;
	
	public EmailDispatcherService ( List<EmailDispatcherService.Message> messages ) {
		this.messages = messages;
		loadEmailTemplateIdByDeveloperNames();
		loadTalendUserId();
	}
	
	public void sendEmail () {
		createEmailDeliveries();
		deleteExistingContentDocumentLinks();
		createContentDocumentLinks();
	}
	
	public List<EmailVersand__c> getEmailDeliveries () {
		List<EmailVersand__c> emailDeliveries = new List<EmailVersand__c>();
		for ( Message message : messages ) {
			SObject emailDelivery = addEmailDelivery( message );
			emailDeliveries.add(
					( EmailVersand__c ) emailDelivery
			);
		}
		return emailDeliveries;
	}
	
	private void createEmailDeliveries () {
		for ( Message message : messages ) {
			emailDeliveryByMessages.put( message, ( EmailVersand__c ) addEmailDelivery( message ) );
		}
		insert emailDeliveryByMessages.values();
	}
	
	private EmailVersand__c addEmailDelivery ( Message message ) {
		
		Messaging.SingleEmailMessage singleEmailMessage
				= Messaging.renderStoredEmailTemplate(
						getEmailTemplateId( message.emailTemplateDeveloperName ),
						UserInfo.getUserId(),
						message.emailTemplateRecordId );
		return new EmailVersand__c(
				Dokument__c = message.documentName,
				Status__c = 'offen',
				Email_von__c = message.fromAddresses,
				Email_an__c = message.toAddresses,
				Email_CC__c = message.ccAddresses,
				Lead__c = message.leadId,
				Account__c = message.accountId,
				Contract__c = message.contractId,
				Netzaenderung_FNAE__c = message.fnaeId,
				Email_Nachricht__c = singleEmailMessage.getHtmlBody() == null
						? singleEmailMessage.getPlainTextBody()
						: singleEmailMessage.getHtmlBody(),
				Email_Betreff__c = singleEmailMessage.getSubject(),
				Anhang__c = String.isNotEmpty( message.selectedFileIds )
		);
	}
	
	private void loadEmailTemplateIdByDeveloperNames () {
		Set<String> emailTemplateNames = new Set<String>();
		for ( Message message : messages ) {
			emailTemplateNames.add( message.emailTemplateDeveloperName );
		}
		for ( EmailTemplate emailTemplate : [
				SELECT
						Id,
						DeveloperName
				FROM EmailTemplate
				WHERE DeveloperName IN :emailTemplateNames
		] ) {
			
			emailTemplateIdByDeveloperName.put( emailTemplate.DeveloperName, emailTemplate.Id );
		}
	}
	
	private Id getEmailTemplateId ( String developerName ) {
		return emailTemplateIdByDeveloperName.get( developerName );
	}
	
	private void loadTalendUserId () {
		talendUserId = !Test.isRunningTest()
				? [
						SELECT
								Id
						FROM User
						WHERE IstSchnittstellenbenutzer__c = TRUE
						LIMIT 1
				].Id
				: null;
	}
	
	private void createContentDocumentLinks () {
		List<ContentDocumentLink> contentDocumentLinks = new List<ContentDocumentLink>();
		for ( Message message : emailDeliveryByMessages.keySet() ) {
			if ( String.isEmpty( message.selectedFileIds ) ) {
				continue;
			}
			for ( Id fileId : message.selectedFileIds.split( ',' ) ) {
				contentDocumentLinks.add(
						new ContentDocumentLink(
								ContentDocumentId = fileId,
								LinkedEntityId = emailDeliveryByMessages.get( message ).Id,
								ShareType = 'I',
								Visibility = 'AllUsers'
						)
				
				);
				contentDocumentLinks.add(
						new ContentDocumentLink(
								ContentDocumentId = fileId,
								LinkedEntityId = talendUserId,
								ShareType = 'V',
								Visibility = 'AllUsers'
						)
				);
			}
		}
		Database.insert( contentDocumentLinks, false );
	}
	
	private void deleteExistingContentDocumentLinks () {
		if ( disableDeleteExistingContentDocumentLinks ) {
			return;
		}
		List<ContentDocumentLink> contentDocumentLinks = new List<ContentDocumentLink>();
		List<ContentDocument> contentDocuments = new List<ContentDocument>();
		Set<Id> contentDocumentIds = new Set<Id>();
		for ( Message message : emailDeliveryByMessages.keySet() ) {
			if ( String.isEmpty( message.selectedFileIds ) ) {
				continue;
			}
			contentDocumentIds.addAll( ( List<Id> ) message.selectedFileIds.split( ',' ) );
		}
		List<Id> documentIds = new List<Id>( contentDocumentIds );
		if ( !documentIds.isEmpty() ) {
			for ( ContentDocumentLink contentDocumentLink : [
					SELECT
							Id,
							ContentDocument.Title,
							LinkedEntityId,
							ContentDocumentId
					FROM ContentDocumentLink
					WHERE ContentDocumentId IN :documentIds
			] ) {
				if ( contentDocumentLink.ContentDocument.Title.startsWith( '2a1' ) ) {
					if ( contentDocumentLink.LinkedEntityId == UserInfo.getUserId() ) {
						
						contentDocuments.add(
								new ContentDocument(
										Id = contentDocumentLink.ContentDocumentId,
										OwnerId = talendUserId
								)
						);
					}
					else {
						contentDocumentLinks.add( contentDocumentLink );
					}
				}
			}
		}
		update contentDocuments;
		deleteLinks( contentDocumentLinks );
	}
	
	private void deleteLinks ( List<ContentDocumentLink> contentDocumentLinks ) {
		if ( !contentDocumentLinks.isEmpty() ) {
			delete contentDocumentLinks;
			Database.emptyRecycleBin( contentDocumentLinks );
		}
	}
	
	public class Message {
		public String emailTemplateRecordId = '';
		public String selectedFileIds = '';
		public String fromAddresses = '';
		public String toAddresses = '';
		public String ccAddresses = '';
		public String emailTemplateDeveloperName = '';
		public String documentName = '';
		public String leadId = '';
		public String accountId = '';
		public String contractId = '';
		public String fnaeId = '';
	}
}