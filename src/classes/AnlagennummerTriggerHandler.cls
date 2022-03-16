/**
 *@author       Mats Böhler
 *@created      13.06.2020
 *
 *
 *@description  AnlagennummerTriggerHandler
 *
 *
 *@changelog    13.06.2020 Mats Böhler  - Created
 *              
 * 
 */
public without sharing class AnlagennummerTriggerHandler extends TriggerHandler {
	
	private List<Anlagennummer__c> newAnlagennummers = null;
	private Map<Id, Anlagennummer__c> newAnlagennummersMap = null;
	private Map<Id, Anlagennummer__c> oldAnlagennummersMap = null;
	private List<AnlagennummerHistorie__c> anlagennummerHistories = new List<AnlagennummerHistorie__c>();
	
	public AnlagennummerTriggerHandler () {
		
		this.newAnlagennummers = ( List<Anlagennummer__c> ) Trigger.new;
		this.newAnlagennummersMap = ( Map<Id, Anlagennummer__c> ) Trigger.newMap;
		this.oldAnlagennummersMap = ( Map<Id, Anlagennummer__c> ) Trigger.oldMap;
	}
	
	public override void afterInsert () {
		TriggerHandler.bypass( 'AnlagennummerTriggerHandler' );
		
		for ( Anlagennummer__c anlagennummer : newAnlagennummers ) {
			
			createHistoryEntryCreated( anlagennummer );
		}
		insertHistoryEntries();
		
		TriggerHandler.clearBypass( 'AnlagennummerTriggerHandler' );
	}
	
	public override void beforeUpdate () {
		TriggerHandler.bypass( 'AnlagennummerTriggerHandler' );
		
		for ( Anlagennummer__c anlagennummer : newAnlagennummers ) {
			if ( anlagennummer.Status__c == 'verfügbar'
					&& oldAnlagennummersMap.get( anlagennummer.Id ).Status__c == 'gesperrt' ) {
				
				createHistoryEntryIsAvailableAfterLock( anlagennummer );
			}
		}
		insertHistoryEntries();
		
		TriggerHandler.clearBypass( 'AnlagennummerTriggerHandler' );
	}
	
	private void createHistoryEntryIsAvailableAfterLock ( Anlagennummer__c anlagennummer ) {
		anlagennummerHistories.add(
				new AnlagennummerHistorie__c(
						Anlagennummer__c = anlagennummer.Id,
						Aktion__c = 'Entsperrt',
						Nachricht__c = 'Die Anlagennummer wurde entsperrt und ist wieder verfügbar.'
				)
		);
	}
	
	private void createHistoryEntryCreated ( Anlagennummer__c anlagennummer ) {
		anlagennummerHistories.add(
				new AnlagennummerHistorie__c(
						Anlagennummer__c = anlagennummer.Id,
						Aktion__c = 'Erstellt',
						Nachricht__c = 'Die Anlagennummer wurde erstellt.'
				)
		);
	}
	
	private void insertHistoryEntries () {
		insert anlagennummerHistories;
	}
}