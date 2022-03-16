/**
 *@author       Mats Böhler
 *@created      21.07.2021
 *
 *
 *@description  StornierungVorDispoCtrl
 *
 *
 *@changelog    21.07.2021 Mats Böhler  - Created
 *              
 * 
 */
public with sharing class StornierungVorDispoCtrl {
	
	@AuraEnabled
	public static void sendEmail ( String leadId ) {
		Savepoint savepoint = Database.setSavepoint();
		try {
			LeadTriggerHandler.disableValidations = true;
			dispatch( leadId );
			resetFields( leadId );
		}
		catch ( Exception e ) {
			Database.rollback( savepoint );
			throw new AuraHandledException( e.getMessage() );
		}
	}
	
	private static void dispatch ( Id leadId ) {
		EmailSettingService.Request request = new EmailSettingService.Request();
		request.recordId = leadId;
		request.emailSettingName = 'StornierungVorDispo';
		request.leadId = leadId;
		EmailSettingService.getInstance().requests.add( request );
		EmailSettingService.getInstance().createMessages().callEmailDispatcherService();
	}
	
	private static void resetFields ( Id leadId ) {
		
		update new Lead(
				Id = leadId,
				Aufbaufaehig_ab_Datum__c = null,
				Baucheck_erfolgt_Datum__c = null,
				Meldewelle__c = null,
				STO_disponiert__c = null );
	}
}