/**
 *@author       Mats Böhler
 *@created      13.06.2020
 *
 *
 *@description  AnlagennummerNotification
 *
 *
 *@changelog    13.06.2020 Mats Böhler  - Created
 *              
 * 
 */
public without sharing class AnlagennummerNotificationService {
	
	private Blob fileContent;
	private String fileName;
	
	public void sendEmailNotificationToAnlagenbuchhaltung () {
		fileContent = Test.isRunningTest() ? Blob.valueOf( 'Test' ) : Page.AnlagennummerMeldung.getContent();
		AnlagennummerMeldungCtrl controller = AnlagennummerMeldungCtrl.getInstance();
		if ( controller.meldungWrappers.isEmpty() ) {
			sendEmptyEmail();
		}
		else {
			sendEmail();
			archiveFile();
		}
		addHistory();
		saveLastNotificationDate();
	}
	
	private void addHistory () {
		upsert AnlagennummerMeldungCtrl.getInstance().anlagennummerHistories;
	}
	
	private void sendEmptyEmail () {
		EmailEinstellung__mdt emailEinstellung
				= getEmailSetting( 'LeermeldungAnlagenbuchhaltung_MYPM_402' );
		
		EmailTemplate emailTemplate = getEmailTemplate( emailEinstellung.EmailTemplate__c );
		
		Messaging.reserveSingleEmailCapacity( 1 );
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		mail.setSenderDisplayName( emailEinstellung.EmailVon__c );
		mail.setToAddresses( emailEinstellung.EmailAn__c.split( ';' ) );
		mail.setCcAddresses( emailEinstellung.EmailCC__c.split( ';' ) );
		mail.setReplyTo( emailEinstellung.EmailVon__c );
		mail.setTemplateId( emailTemplate.Id );
		mail.setTargetObjectId( UserInfo.getUserId() );
		mail.setSaveAsActivity( false );
		if ( !Test.isRunningTest() ) {
			Messaging.sendEmail( new Messaging.SingleEmailMessage[] {
					mail
			} );
		}
	}
	
	private void sendEmail () {
		EmailEinstellung__mdt emailEinstellung
				= getEmailSetting( 'MeldungAnlagenbuchhaltung_MYPM_402' );
		
		EmailTemplate emailTemplate = getEmailTemplate( emailEinstellung.EmailTemplate__c );
		Map<String, String> organizationWideEmailAddressIdsByEmail = loadOrganizationWideEmailAddressIdsByEmail();
		Messaging.reserveSingleEmailCapacity( 1 );
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		if ( organizationWideEmailAddressIdsByEmail.containsKey( emailEinstellung.EmailVon__c ) ) {
			mail.setOrgWideEmailAddressId(
					organizationWideEmailAddressIdsByEmail.get( emailEinstellung.EmailVon__c )
			);
		}
		else {
			mail.setSenderDisplayName( emailEinstellung.EmailVon__c );
			mail.setReplyTo( emailEinstellung.EmailVon__c );
		}
		mail.setToAddresses( emailEinstellung.EmailAn__c.split( ';' ) );
		mail.setCcAddresses( emailEinstellung.EmailCC__c.split( ';' ) );
		mail.setTemplateId( emailTemplate.Id );
		mail.setTargetObjectId( UserInfo.getUserId() );
		mail.setSaveAsActivity( false );
		
		Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();
		fileName = emailEinstellung.Dateiname__c + Datetime.now().format( 'YYYY-MM-dd' ) + '.xls';
		attach.setFileName( fileName );
		attach.setBody( fileContent );
		mail.setFileAttachments( new List<Messaging.EmailFileAttachment> {
				attach
		} );
		if ( !Test.isRunningTest() ) {
			Messaging.sendEmail( new Messaging.SingleEmailMessage[] {
					mail
			} );
		}
	}
	
	private void saveLastNotificationDate () {
		AnlagennummerLetzteMeldung__c lastNotification = AnlagennummerLetzteMeldung__c.getOrgDefaults();
		lastNotification.LetzteMeldungErfolgtAm__c = Datetime.now();
		update lastNotification;
	}
	
	private void archiveFile () {
		ContentVersion contentVersion = new ContentVersion();
		contentVersion.VersionData = fileContent;
		contentVersion.Title = fileName.removeEnd( '.xls' );
		contentVersion.PathOnClient = fileName;
		insert contentVersion;
		
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
		contentDocumentLink.LinkedEntityId = Test.isRunningTest() ? [
				SELECT
						Id
				FROM ContentWorkspace
				LIMIT 1
		].Id : [
				SELECT
						Id
				FROM ContentWorkspace
				WHERE Name = 'Archiv'
				LIMIT 1
		].Id;
		if ( !Test.isRunningTest() ) {
			insert contentDocumentLink;
		}
	}
	
	public void sendEmailNotificationAboutRemainingNumbers () {
		AnlagennummerEinstellung__mdt setting = [
				SELECT
						MindestmengeVorhandeneNummern__c,
						VersendeEmailWennLetzeMeldungAelter__c
				FROM AnlagennummerEinstellung__mdt
				WHERE DeveloperName = 'Default'
		];
		AnlagennummerLetzteMeldung__c lastNotification = AnlagennummerLetzteMeldung__c.getOrgDefaults();
		if ( [
				SELECT
						Id
				FROM Anlagennummer__c
				WHERE Status__c = 'verfügbar'
		].size() < setting.MindestmengeVorhandeneNummern__c
				&& ( lastNotification.LetzteMailVerbleibendeNummernVersendetAm__c <= Date.today().addDays( -Integer.valueOf( setting.VersendeEmailWennLetzeMeldungAelter__c ) )
				|| lastNotification.LetzteMailVerbleibendeNummernVersendetAm__c == null ) ) {
			
			EmailEinstellung__mdt emailEinstellung
					= getEmailSetting( 'AnlagennummernPackstation_MYPM_400' );
			
			EmailTemplate emailTemplate = getEmailTemplate( emailEinstellung.EmailTemplate__c );
			Map<String, String> organizationWideEmailAddressIdsByEmail = loadOrganizationWideEmailAddressIdsByEmail();
			Messaging.reserveSingleEmailCapacity( 1 );
			Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
			if ( organizationWideEmailAddressIdsByEmail.containsKey( emailEinstellung.EmailVon__c ) ) {
				mail.setOrgWideEmailAddressId(
						organizationWideEmailAddressIdsByEmail.get( emailEinstellung.EmailVon__c )
				);
			}
			else {
				mail.setSenderDisplayName( emailEinstellung.EmailVon__c );
				mail.setReplyTo( emailEinstellung.EmailVon__c );
			}
			mail.setToAddresses( emailEinstellung.EmailAn__c.split( ';' ) );
			mail.setCcAddresses( emailEinstellung.EmailCC__c.split( ';' ) );
			mail.setTemplateId( emailTemplate.Id );
			mail.setTargetObjectId( UserInfo.getUserId() );
			mail.setSaveAsActivity( false );
			if ( !Test.isRunningTest() ) {
				Messaging.sendEmail( new Messaging.SingleEmailMessage[] {
						mail
				} );
				lastNotification.LetzteMailVerbleibendeNummernVersendetAm__c = Date.today();
				update lastNotification;
			}
		}
	}
	
	private EmailEinstellung__mdt getEmailSetting ( String developerName ) {
		return [
				SELECT
						Id,
						EmailVon__c,
						EmailAn__c,
						EmailCC__c,
						EmailTemplate__c,
						Dateiname__c
				FROM EmailEinstellung__mdt
				WHERE DeveloperName = :developerName
				LIMIT 1
		];
	}
	
	private EmailTemplate getEmailTemplate ( String developerName ) {
		return [
				SELECT
						Id
				FROM EmailTemplate
				WHERE DeveloperName = :developerName
				LIMIT 1
		];
	}
	
	private Map<String, String> loadOrganizationWideEmailAddressIdsByEmail () {
		Map<String, String> organizationWideEmailAddressIdsByEmail = new Map<String, String>();
		for ( OrgWideEmailAddress orgWideEmailAddress : [
				SELECT
						Id,
						Address
				FROM OrgWideEmailAddress
		] ) {
			organizationWideEmailAddressIdsByEmail.put( orgWideEmailAddress.Address, orgWideEmailAddress.Id );
		}
		return organizationWideEmailAddressIdsByEmail;
	}
}