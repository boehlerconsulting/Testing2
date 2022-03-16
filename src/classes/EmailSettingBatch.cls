/**
 *@author       Mats Böhler
 *@created      01.12.2020
 *
 *
 *@description  EmailDispatcherBatch
 *
 *
 *@changelog    01.12.2020 Mats Böhler  - Created
 *              
 * 
 */
public without sharing class EmailSettingBatch implements Database.Batchable<SObject>, Database.RaisesPlatformEvents {
	
	private Map<Id, List<EmailSettingService.Request>> requestsByRecordIds = new Map<Id, List<EmailSettingService.Request>>();
	private String processName = '';
	private String sObjectName = '';
	
	public EmailSettingBatch ( Map<Id, List<EmailSettingService.Request>> requestsByRecordIds, String processName, String sObjectName ) {
		this.requestsByRecordIds = requestsByRecordIds;
		this.processName = processName;
		this.sObjectName = sObjectName;
	}
	
	public Database.QueryLocator start ( Database.BatchableContext bc ) {
		return EmailSettingQuery.getQueryLocator( requestsByRecordIds.keySet(), sObjectName );
	}
	
	public void execute ( Database.BatchableContext bc, List<SObject> sObjects ) {
		try {
			EmailSettingService.getInstance().requests = new List<EmailSettingService.Request>();
			for ( SObject sObj : sObjects ) {
				EmailSettingService.getInstance().requests.addAll( requestsByRecordIds.get( sObj.Id ) );
			}
			EmailSettingService.getInstance().createMessages().callEmailDispatcherService();
		}
		catch ( Exception e ) {
			new HW_ErrorLogging().logException( e, new Map<Id, SObject>( sObjects ).keySet(), processName );
		}
	}
	
	public void finish ( Database.BatchableContext bc ) {
		//Sonarqube -> does nothing
	}
}