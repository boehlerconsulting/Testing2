/**
 *@author       Mats Böhler
 *@created      21.07.2021
 *
 *
 *@description  StornierungNachDispoCtrl
 *
 *
 *@changelog    21.07.2021 Mats Böhler  - Created
 *              
 * 
 */
public with sharing class StornierungNachDispoCtrl {
	
	@AuraEnabled
	public static void sendEmail ( String leadId, String stornogrund ) {
		Savepoint savepoint = Database.setSavepoint();
		try {
			LeadTriggerHandler.disableValidations = true;
			saveStornogrund( leadId, stornogrund );
			dispatch( leadId );
			resetFields( leadId );
		}
		catch ( Exception e ) {
			Database.rollback( savepoint );
			throw new AuraHandledException( e.getMessage() );
		}
	}
	
	private static void saveStornogrund ( Id leadId, String stornogrund ) {
		update new Lead(
				Id = leadId,
				Stornierungsgrund__c = stornogrund
		);
	}
	
	private static void dispatch ( Id leadId ) {
		String sammelpostfach = [
				SELECT
						Id,
						VL__r.GL__r.EMail__c
				FROM Lead
				WHERE Id = :leadId
				LIMIT 1
		].VL__r.GL__r.EMail__c;
		EmailSettingService.Request request = new EmailSettingService.Request();
		request.recordId = leadId;
		request.emailSettingName = 'StornierungNachDispo';
		request.additionalAddresses = sammelpostfach;
		request.leadId = leadId;
		EmailSettingService.getInstance().requests.add( request );
		EmailSettingService.getInstance().createMessages().callEmailDispatcherService();
	}
	
	private static void resetFields ( Id leadId ) {
		
		update new Lead(
				Id = leadId,
				Stornierungsgrund__c = null,
				Aufbaufaehig_ab_Datum__c = null,
				Baucheck_erfolgt_Datum__c = null,
				Meldewelle__c = null,
				STO_disponiert__c = null,
				AufstelldatumADM__c = null
		);
	}
}