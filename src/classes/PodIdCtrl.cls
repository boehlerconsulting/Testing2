/**
 *@author       Mats Böhler
 *@created      04.08.2021
 *
 *
 *@description  PodIdCtrl
 *
 *
 *@changelog    04.08.2021 Mats Böhler  - Created
 *              
 * 
 */
public with sharing class PodIdCtrl {
	
	@AuraEnabled
	public static void init ( Id leadId ) {
		
		try {
			Lead lead = getLead( leadId );
			if ( lead.PODID_Lookup__c != null ) {
				throw new PodIdCtrlException( Label.PODIDsGesetzt );
			}
			Map<Id, PODID__c> podIdByLeadIds = new PodIdService().generate( new Set<Id> {
					leadId
			} );
			if ( podIdByLeadIds.containsKey( leadId ) ) {
				update new Lead(
						Id = leadId,
						PODID_Lookup__c = podIdByLeadIds.get( leadId ).Id
				);
			}
			else {
				throw new PodIdCtrlException( Label.POIDsVerbraucht );
			}
		}
		catch ( Exception e ) {
			throw new AuraHandledException( e.getMessage() );
		}
	}
	
	@AuraEnabled
	public static void deleteId ( Id podId ) {
		
		try {
			erasePodIds( podId );
		}
		catch ( Exception e ) {
			throw new AuraHandledException( e.getMessage() );
		}
	}
	
	private static void erasePodIds ( Id podId ) {
		List<Lead> leads = new List<Lead>();
		for ( Lead lead : [
				SELECT
						Id
				FROM Lead
				WHERE PODID_Lookup__c = :podId
		] ) {
			lead.PODID_Lookup__c = null;
			leads.add( lead );
		}
		update leads;
		
		List<Account> accounts = new List<Account>();
		for ( Account account : [
				SELECT
						Id
				FROM Account
				WHERE PODID__c = :podId
		] ) {
			account.PODID__c = null;
			accounts.add( account );
		}
		update accounts;
	}
	
	private static Lead getLead ( String leadId ) {
		return [
				SELECT
						Id,
						PODID_Lookup__c
				FROM Lead
				WHERE Id = :leadId
				LIMIT 1
		];
	}
	
	public class PodIdCtrlException extends Exception {
	
	}
}