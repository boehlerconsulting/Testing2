/**
 *@author       Mats Böhler
 *@created      01.12.2020
 *
 *
 *@description  BatchJobSetting
 *
 *
 *@changelog    01.12.2020 Mats Böhler  - Created
 *              
 * 
 */
public without sharing class BatchJobSetting {
	
	public static Integer getDefaultBatchSize () {
		return ( Integer ) [
				SELECT
						BatchSize__c
				FROM BatchJobEinstellung__mdt
				WHERE DeveloperName = 'Default'
				LIMIT 1
		].BatchSize__c;
	}
	
	public static Integer getBatchSize (String developerName) {
		return ( Integer ) [
				SELECT
						BatchSize__c
				FROM BatchJobEinstellung__mdt
				WHERE DeveloperName = :developerName
				LIMIT 1
		].BatchSize__c;
	}
}