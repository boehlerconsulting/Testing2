/**
 *@author       Mats Böhler
 *@created      22.07.2021
 *
 *
 *@description  PackstationDatenaenderungCtrl
 *
 *
 *@changelog    22.07.2021 Mats Böhler  - Created
 *              
 * 
 */
public with sharing class PackstationDatenaenderungCtrl {
	
	@AuraEnabled
	public static void sendEmail ( Id leadId, String oldLeadState, String newLeadState ) {
		Savepoint savepoint = Database.setSavepoint();
		try {
			LeadTriggerHandler.disableValidations = true;
			Lead newLead = ( Lead ) JSON.deserialize( newLeadState, Lead.class );
			newLead.Id = leadId;
			update newLead;
			Lead oldLead = ( Lead ) JSON.deserialize( oldLeadState, Lead.class );
			newLead = [
					SELECT
							Id,
							ADM_Typ__c,
							PODID_Lookup__c,
							ist_disponiert__c,
							VL__r.GL__r.EMail__c
					FROM Lead
					WHERE Id = :leadId
					LIMIT 1
			];
			evaluatePODID( newLead, oldLead );
			dispatch( newLead, oldLead );
		}
		catch ( Exception e ) {
			Database.rollback( savepoint );
			throw new AuraHandledException( e.getMessage() );
		}
	}
	
	private static void evaluatePODID ( Lead lead, Lead oldLead ) {
		
		if ( oldLead.ADM_Typ__c == 'Poststation'
				&& oldLead.ADM_Typ__c != lead.ADM_Typ__c ) {
			
			setNewPODID( lead );
		}
		if ( oldLead.ADM_Typ__c == 'Prototyp'
				&& oldLead.ADM_Typ__c != lead.ADM_Typ__c ) {
			
			setNewPODID( lead );
		}
		if ( lead.ADM_Typ__c == 'Prototyp'
				&& oldLead.ADM_Typ__c != lead.ADM_Typ__c ) {
			
			setNewPODID( lead );
		}
		if ( lead.ADM_Typ__c == 'Poststation'
				&& oldLead.ADM_Typ__c != lead.ADM_Typ__c ) {
			
			setNewPODID( lead );
		}
	}
	
	@TestVisible
	private static void setNewPODID ( Lead lead ) {
		update new Lead(
				Id = lead.Id,
				PODID_Lookup__c = null
		);
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
	
	private static void dispatch ( Lead newLead, Lead oldLead ) {
		EmailSettingService.Request request = new EmailSettingService.Request();
		request.recordId = oldLead.Id;
		request.emailSettingName = newLead.ist_disponiert__c
				? 'PackstationDatenaenderungNachDispo'
				: 'PackstationDatenaenderung';
		request.additionalAddresses = newLead.ist_disponiert__c
				? ''
				: newLead.VL__r.GL__r.EMail__c;
		request.leadId = oldLead.Id;
		EmailSettingService.getInstance().requests.add( request );
		List<EmailVersand__c> emailDeliveries =
				EmailSettingService.getInstance().createMessages().getEmailDispatcherServiceDeliveries();
		
		for ( EmailVersand__c emailVersand : emailDeliveries ) {
			
			emailVersand.Email_Nachricht__c = emailVersand.Email_Nachricht__c
					.replace( 'Download_LTE_Messung_MBit__c', returnEmptyIfNull( oldLead.Download_LTE_Messung_MBit__c ) )
					.replace( 'Upload_LTE_Messung_MBit__c', returnEmptyIfNull( oldLead.Upload_LTE_Messung_MBit__c ) )
					.replace( 'Kostenstelle__c', returnEmptyIfNull( oldLead.Kostenstelle__c ) )
					.replace( 'ADM_Typ__c', returnEmptyIfNull( oldLead.ADM_Typ__c ) )
					.replace( 'ADM_Hersteller__c', returnEmptyIfNull( oldLead.ADM_Hersteller__c ) )
					.replace( 'Fundament__c', returnEmptyIfNull( oldLead.Fundament__c ) )
					.replace( 'Aufbauform__c', returnEmptyIfNull( oldLead.Aufbauform__c ) )
					.replace( 'Fachmodule__c', returnEmptyIfNull( oldLead.Fachmodule__c ) )
					.replace( 'Unterbrechung__c', returnEmptyIfNull( oldLead.Unterbrechung__c ) )
					.replace( 'Steuermodule__c', returnEmptyIfNull( oldLead.Steuermodule__c ) )
					.replace( 'Eckmodule__c', returnEmptyIfNull( oldLead.Eckmodule__c ) )
					.replace( 'Summe_aller_Module__c', returnEmptyIfNull( oldLead.Summe_aller_Module__c ) )
					.replace( 'Anmerkungen_zum_Bau__c', returnEmptyIfNull( oldLead.Anmerkungen_zum_Bau__c ) )
					.replace( 'Bemerkungen_zur_Dispo__c', returnEmptyIfNull( oldLead.Bemerkungen_zur_Dispo__c ) )
					.replace( 'null', '' );
		}
		insert emailDeliveries;
	}
	
	private static String returnEmptyIfNull ( String value ) {
		return value == null ? '' : value;
	}
	
	private static String returnEmptyIfNull ( Decimal value ) {
		if ( value == null ) {
			return '';
		}
		return String.valueOf( value );
	}
}