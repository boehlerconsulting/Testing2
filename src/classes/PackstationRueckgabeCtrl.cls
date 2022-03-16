/**
 *@author       Mats Böhler
 *@created      26.07.2021
 *
 *
 *@description  PackstationRueckgabeCtrl
 *
 *
 *@changelog    26.07.2021 Mats Böhler  - Created
 *              
 * 
 */
public with sharing class PackstationRueckgabeCtrl {
	
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
		EmailSettingService.Request request = new EmailSettingService.Request();
		request.recordId = leadId;
		request.emailSettingName = 'PackstationRueckgabe';
		request.leadId = leadId;
		EmailSettingService.getInstance().requests.add( request );
		EmailSettingService.getInstance().createMessages().callEmailDispatcherService();
	}
	
	private static void resetFields ( Id leadId ) {
		
		update new Lead(
				Id = leadId,
				Stornierungsgrund__c = null,
				Meldewelle__c = null,
				STO_disponiert__c = null
		);
	}
}