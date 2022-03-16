/**
 *@author       Mats Böhler
 *@created      10.08.2020
 *
 *
 *@description  TriggerService
 *
 *
 *@changelog    10.08.2020 Mats Böhler  - Created
 *              
 * 
 */
public without sharing class TriggerService {
	
	private static Map<String, TriggerEinstellung__mdt> triggerSettingByName = new Map<String, TriggerEinstellung__mdt>();
	
	public static TriggerEinstellung__mdt getSetting ( String name ) {
		loadSettings();
		return triggerSettingByName.get( name );
	}
	
	public static Boolean isActive ( String name ) {
		loadSettings();
		return triggerSettingByName.get( name ).Aktiv__c;
	}
	
	public static Boolean processAsynchronously ( String name ) {
		loadSettings();
		return triggerSettingByName.get( name ).AsynchroneVerarbeitung__c;
	}
	
	private static void loadSettings () {
		if ( TriggerService.triggerSettingByName.isEmpty() ) {
			for ( TriggerEinstellung__mdt triggerSetting : [
					SELECT
							Id,
							DeveloperName,
							Aktiv__c,
							AsynchroneVerarbeitung__c
					FROM TriggerEinstellung__mdt
			] ) {
				
				TriggerService.triggerSettingByName.put( triggerSetting.DeveloperName, triggerSetting );
			}
		}
	}
}