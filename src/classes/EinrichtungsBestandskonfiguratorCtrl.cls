/**
 *@author       Mats Böhler
 *@created      11.03.2021
 *
 *
 *@description  EinrichtungsBestandskonfiguratorCtrl
 *
 *
 *@changelog    11.03.2021 Mats Böhler  - Created
 *              
 * 
 */
public without sharing class EinrichtungsBestandskonfiguratorCtrl {
	
	@AuraEnabled
	public static String saveProcessState ( String accountId, String einrichtungsprozessId, String previousExists, String zeigeBundles ) {
		String process = '';
		try {

			process = zeigeBundles == 'Ja' ? 'Vorgängerfiliale' : 'Neubestellung';
			update new Einrichtungsprozess__c(
					Id = einrichtungsprozessId,
					VorgaengerfilialeExistiert__c = previousExists,
					AusstattungUebernahmeVorgaenger__c = zeigeBundles,
					Prozess__c = process
			);
			List<Filialausstattung__c> filialausstattungs = [
					SELECT
							Id
					FROM Filialausstattung__c
					WHERE Filiale__c = :accountId
					AND BestandVorgaengerfiliale__c = TRUE
			];
			if ( !filialausstattungs.isEmpty() ) {
				delete filialausstattungs;
				Database.emptyRecycleBin( filialausstattungs );
			}
		}
		catch ( Exception e ) {
			
			throw new AuraHandledException( e.getMessage() );
		}
		
		return process;
	}
}