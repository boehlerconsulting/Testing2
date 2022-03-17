/**
 *@author       Mats Böhler
 *@created      16.05.2020
 *
 *
 *@description  EmailVersandTriggerHandler
 *
 *
 *@changelog    16.05.2020 Mats Böhler  - Created
 *              13.08.2020 Sabrina Wortmann - Added methods for SDS
 * 
 */
public without sharing class EmailVersandTriggerHandler extends TriggerHandler {
	
	private List<EmailVersand__c> newEmails = null;
	private Map<Id, EmailVersand__c> newEmailsMap = null;
	private Map<Id, EmailVersand__c> oldEmailsMap = null;
	private Map<Id, Lead> leadsByIds = new Map<Id, Lead>();
	private List<EmailVersand__c> leadEmailVersands = new List<EmailVersand__c>();
	private List<EmailVersand__c> accountEmailVersands = new List<EmailVersand__c>();
	private List<EmailVersand__c> vertragEmailVersands = new List<EmailVersand__c>();
	private List<EmailVersand__c> fnaeEmailVersands = new List<EmailVersand__c>();
	
	public EmailVersandTriggerHandler () {
		
		this.newEmails = ( List<EmailVersand__c> ) Trigger.new;
		this.newEmailsMap = ( Map<Id, EmailVersand__c> ) Trigger.newMap;
		this.oldEmailsMap = ( Map<Id, EmailVersand__c> ) Trigger.oldMap;
	}
	
	public override void beforeInsert () {
		
		for ( EmailVersand__c emailVersand : newEmails ) {
			if ( emailVersand.Email_an__c == null && emailVersand.Email_CC__c == null ) {
				emailVersand.Status__c = 'Nicht notwendig';
			}
		}
	}
	
	public override void beforeUpdate () {
		
		createEmailHistory();
	}
	
	private void sortEmails () {
		leadEmailVersands = new List<EmailVersand__c>();
		accountEmailVersands = new List<EmailVersand__c>();
		vertragEmailVersands = new List<EmailVersand__c>();
		fnaeEmailVersands = new List<EmailVersand__c>();

		for ( EmailVersand__c emailVersand : newEmails ) {
			sortEmail(emailVersand);
		}
	}
	
	private void sortEmail(EmailVersand__c emailVersand){
		if ( emailVersand.Status__c == 'versendet'
				&& emailVersand.Status__c != oldEmailsMap.get( emailVersand.Id ).Status__c ) {
			
			if ( emailVersand.Dokument__c == 'Packstation - Mietvertrag'
					|| emailVersand.Dokument__c == 'Packstation - Einzelvertrag' ) {
				vertragEmailVersands.add( emailVersand );
			}
			if ( emailVersand.Lead__c != null ) {
				leadEmailVersands.add( emailVersand );
			}
			if ( emailVersand.Account__c != null ) {
				accountEmailVersands.add( emailVersand );
			}
			if (emailVersand.Netzaenderung_FNAE__c != null ) {
				fnaeEmailVersands.add(emailVersand);
			}
		}
	}
	
	private void createEmailHistory () {
		sortEmails();
		if ( !vertragEmailVersands.isEmpty() ) {
			deleteContractFiles( vertragEmailVersands );
		}
		
		if ( !leadEmailVersands.isEmpty() ) {
			leadsByIds = loadLeadsByIds();
			Map<Id, EmailMessage> emailMessagesByEmailVersandId = createLeadEmailMessages( leadEmailVersands );
			if ( emailMessagesByEmailVersandId.values().isEmpty() ) {
				return;
			}
			addLeadEmailMessageRelations(
					emailMessagesByEmailVersandId,
					loadContentDocumentLinksByLinkedEntityId( newEmailsMap.keySet() )
			);
		}
		if ( !accountEmailVersands.isEmpty() ) {
			Map<Id, EmailMessage> emailMessagesByEmailVersandId = createEmailMessages( accountEmailVersands, 'Account__c' );
			if ( emailMessagesByEmailVersandId.values().isEmpty() ) {
				return;
			}
			addEmailMessageRelations(
					emailMessagesByEmailVersandId,
					loadContentDocumentLinksByLinkedEntityId( newEmailsMap.keySet() )
			);
		}
		if ( !fnaeEmailVersands.isEmpty() ) {
			Map<Id, EmailMessage> emailMessagesByEmailVersandId = createEmailMessages( fnaeEmailVersands, 'Netzaenderung_FNAE__c' );
			if ( emailMessagesByEmailVersandId.values().isEmpty() ) {
				return;
			}
			addEmailMessageRelations(
					emailMessagesByEmailVersandId,
					loadContentDocumentLinksByLinkedEntityId( newEmailsMap.keySet() )
			);
		}
	}
	
	private void deleteContractFiles ( List<EmailVersand__c> emailVersands ) {
		Map<Id, ContentDocument> contentDocumentByIds = new Map<Id, ContentDocument>();
		for ( ContentDocumentLink contentDocumentLink : [
				SELECT
						Id,
						ContentDocument.Title,
						LinkedEntityId,
						ContentDocumentId
				FROM ContentDocumentLink
				WHERE LinkedEntityId IN :new Map<Id, EmailVersand__c>( emailVersands ).keySet()
		] ) {
			if ( contentDocumentLink.ContentDocument.Title.startsWith( '2a1' ) ) {
				contentDocumentByIds.put(
						contentDocumentLink.ContentDocumentId,
						new ContentDocument(
								Id = contentDocumentLink.ContentDocumentId
						)
				);
			}
		}
		if ( !contentDocumentByIds.values().isEmpty() ) {
			delete contentDocumentByIds.values();
			Database.emptyRecycleBin( contentDocumentByIds.values() );
		}
	}
	
	private void addLeadEmailMessageRelations (
			Map<Id, EmailMessage> emailMessagesByEmailVersandId,
			Map<Id, List<ContentDocumentLink>> contentDocumentLinksByLinkedEntityId ) {
		
		List<ContentDocumentLink> contentDocumentLinks = new List<ContentDocumentLink>();
		List<EmailMessageRelation> emailMessageRelations = new List<EmailMessageRelation>();
		
		for ( Id emailVersandId : emailMessagesByEmailVersandId.keySet() ) {
			Id emailMessageId = emailMessagesByEmailVersandId.get( emailVersandId ).Id;
			
			if ( contentDocumentLinksByLinkedEntityId.containsKey( emailVersandId ) ) {
				for ( ContentDocumentLink existingContentDocumentLink : contentDocumentLinksByLinkedEntityId.get( emailVersandId ) ) {
					contentDocumentLinks.add(
							new ContentDocumentLink(
									ContentDocumentId = existingContentDocumentLink.ContentDocumentId,
									LinkedEntityId = emailMessageId,
									ShareType = 'V',
									Visibility = 'AllUsers'
							)
					
					);
				}
			}
			if ( !leadsByIds.isEmpty() ) {
				emailMessageRelations.add(
						new EmailMessageRelation(
								EmailMessageId = emailMessageId,
								RelationId = newEmailsMap.get( emailVersandId ).Lead__c,
								RelationType = 'OtherAddress'
						)
				);
			}
		
		}
		insert contentDocumentLinks;
		insert emailMessageRelations;
	}
	
	private void addEmailMessageRelations (
			Map<Id, EmailMessage> emailMessagesByEmailVersandId,
			Map<Id, List<ContentDocumentLink>> contentDocumentLinksByLinkedEntityId ) {
		
		List<ContentDocumentLink> contentDocumentLinks = new List<ContentDocumentLink>();
		List<EmailMessageRelation> emailMessageRelations = new List<EmailMessageRelation>();
		
		for ( Id emailVersandId : emailMessagesByEmailVersandId.keySet() ) {
			Id emailMessageId = emailMessagesByEmailVersandId.get( emailVersandId ).Id;
			
			if ( contentDocumentLinksByLinkedEntityId.containsKey( emailVersandId ) ) {
				for ( ContentDocumentLink existingContentDocumentLink : contentDocumentLinksByLinkedEntityId.get( emailVersandId ) ) {
					
					contentDocumentLinks.add(
							new ContentDocumentLink(
									ContentDocumentId = existingContentDocumentLink.ContentDocumentId,
									LinkedEntityId = emailMessageId,
									ShareType = 'V',
									Visibility = 'AllUsers'
							)
					
					);
				}
			}
		}
		insert contentDocumentLinks;
		insert emailMessageRelations;
	}
	
	private Map<Id, EmailMessage> createLeadEmailMessages ( List<EmailVersand__c> emailVersands ) {
		Map<Id, EmailMessage> emailMessagesByEmailVersandId = new Map<Id, EmailMessage>();
		List<Lead> leads = new List<Lead>();
		Set<Id> emailVersandIds = new Set<Id>();
		for ( EmailVersand__c email : emailVersands ) {
			emailMessagesByEmailVersandId.put(
					email.Id,
					new EmailMessage(
							Status = '3',
							Subject = email.Email_Betreff__c,
							HtmlBody = getHtmlBody( email ),
							ToAddress = email.Email_an__c,
							CcAddress = email.Email_CC__c,
							FromAddress = email.Email_von__c
					)
			);
			if ( email.Dokument__c == 'Packstation - Mietvertrag' ) {
				leads.add(
						new Lead(
								Id = email.Lead__c,
								EMailStatus__c = leadsByIds.get( email.Lead__c ).EMailStatus__c == null
										? 'E-Mail versendet'
										: leadsByIds.get( email.Lead__c ).EMailStatus__c + ';E-Mail versendet'
						)
				);
			}
			if ( email.Dokument__c == 'Beauftragung TVM' ) {
				emailVersandIds.add( email.Id );
			}
		}
		update leads;
		insert emailMessagesByEmailVersandId.values();
		deleteExistingContentDocumentLinks( emailVersandIds );
		return emailMessagesByEmailVersandId;
	}
	
	private void deleteExistingContentDocumentLinks ( Set<Id> emailVersandIds ) {
		if ( emailVersandIds.isEmpty() ) {
			return ;
		}
		List<ContentDocumentLink> contentDocumentLinks = [ SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId IN :emailVersandIds ];
		if ( !contentDocumentLinks.isEmpty() ) {
			delete contentDocumentLinks;
			Database.emptyRecycleBin( contentDocumentLinks );
		}
	}
	
	private String getHtmlBody ( EmailVersand__c emailVersand ) {
		return emailVersand.Dokument__c == 'Beauftragung TVM'
				? '<p>Diese E-Mail wird aus datenschutzrechtlichen ' +
						'Gründen ohne Anlagen und Inhalte in myPM hinterlegt.</p>'
				: emailVersand.Email_Nachricht__c;
	}
	
	private Map<Id, EmailMessage> createEmailMessages ( List<EmailVersand__c> emailVersands, String relationFieldName ) {
		Map<Id, EmailMessage> emailMessagesByEmailVersandId = new Map<Id, EmailMessage>();
		for ( EmailVersand__c email : emailVersands ) {
			emailMessagesByEmailVersandId.put(
					email.Id,
					new EmailMessage(
							Status = '3',
							Subject = email.Email_Betreff__c,
							HtmlBody = email.Email_Nachricht__c,
							ToAddress = email.Email_an__c,
							CcAddress = email.Email_CC__c,
							FromAddress = email.Email_von__c,
							RelatedToId = (Id) email.get(relationFieldName)
					)
			);
		}
		insert emailMessagesByEmailVersandId.values();
		return emailMessagesByEmailVersandId;
	}
	
	private Map<Id, List<ContentDocumentLink>> loadContentDocumentLinksByLinkedEntityId ( Set<Id> recordIds ) {
		Map<Id, List<ContentDocumentLink>> contentDocumentLinksByRecordId = new Map<Id, List<ContentDocumentLink>>();
		for ( ContentDocumentLink contentDocumentLink : [
				SELECT
						Id,
						LinkedEntityId,
						ContentDocument.Title,
						ContentDocument.FileExtension,
						ContentDocument.LastModifiedDate,
						ContentDocumentId
				FROM ContentDocumentLink
				WHERE LinkedEntityId IN :recordIds
		] ) {
			if ( contentDocumentLinksByRecordId.containsKey( contentDocumentLink.LinkedEntityId ) ) {
				contentDocumentLinksByRecordId.get( contentDocumentLink.LinkedEntityId ).add( contentDocumentLink );
			}
			else {
				contentDocumentLinksByRecordId.put( contentDocumentLink.LinkedEntityId, new List<ContentDocumentLink> {
						contentDocumentLink
				} );
			}
		}
		return contentDocumentLinksByRecordId;
	}
	
	private Map<Id, Lead> loadLeadsByIds () {
		Set<Id> leadIds = new Set<Id>();
		for ( EmailVersand__c emailVersand : newEmailsMap.values() ) {
			leadIds.add( emailVersand.Lead__c );
		}
		return new Map<Id, Lead>( [
				SELECT
						Id,
						EMailStatus__c
				FROM Lead
				WHERE Id IN :leadIds
		] );
	}
}