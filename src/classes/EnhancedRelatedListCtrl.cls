/**
 *@author       Mats Böhler
 *@created      13.09.2021
 *
 *
 *@description  EnhancedRelatedListCtrl
 *
 *
 *@changelog    13.09.2021 Mats Böhler  - Created
 *              
 * 
 */
public with sharing class EnhancedRelatedListCtrl {
	
	@AuraEnabled
	public static Lead init ( String leadId ) {
		
		try {
			Lead lead = getLead( leadId );
			if ( lead.Packstation__c == null ) {
				new PackstationDummyInitializer().create( new Set<Id> {
						lead.Id
				} );
				return getLead( leadId );
			}
			else {
				return lead;
			}
		}
		catch ( Exception e ) {
			throw new AuraHandledException( e.getMessage() );
		}
	}
	
	private static Lead getLead ( Id leadId ) {
		return [
				SELECT
						Id,
						Packstation__c
				FROM Lead
				WHERE Id = :leadId
				LIMIT 1
		];
	}
}