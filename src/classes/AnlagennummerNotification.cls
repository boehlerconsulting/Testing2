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
public without sharing class AnlagennummerNotification {
	
	public static void sendEmail () {
		if ( [
				SELECT
						Id
				FROM Anlagennummer__c
				WHERE Status__c = 'verfügbar'
		].size() < 15 ) {
			
			EmailEinstellung__mdt emailEinstellung = [
					SELECT
							Id,
							EmailVon__c,
							EmailAn__c,
							EmailCC__c,
							EmailTemplate__c
					FROM EmailEinstellung__mdt
					WHERE DeveloperName = 'AnlagennummernPackstation_MYPM_400'
					LIMIT 1
			];
			
			EmailTemplate emailTemplate = [
					SELECT
							Id
					FROM EmailTemplate
					WHERE DeveloperName = :emailEinstellung.EmailTemplate__c
					LIMIT 1
			];
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
			}
		}
	}
	
	private static Map<String, String> loadOrganizationWideEmailAddressIdsByEmail () {
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