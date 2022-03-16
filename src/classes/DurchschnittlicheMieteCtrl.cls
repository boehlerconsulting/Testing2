/**
 *@author       Mats Böhler
 *@created      11.11.2020
 *
 *
 *@description  DurchschnittlicheMieteCtrl
 *
 *
 *@changelog    11.11.2020 Mats Böhler  - Created
 *              
 * 
 */
public without sharing class DurchschnittlicheMieteCtrl {
	
	@AuraEnabled
	public static Decimal init ( String leadId ) {
		Decimal durchschnittlicheMiete = null;
		Decimal anzahlModule = 12;
		try {
			Lead lead = [
					SELECT
							Id,
							ZuordnungZuRahmenvertrag__c
					FROM Lead
					WHERE Id = :leadId
					LIMIT 1
			];
			List<StrategischerPartner__mdt> strategischerPartners = [
					SELECT
							Id,
							MietkostensatzInEuro__c,
							Referenzwert__c,
							ArtDerMiete__c
					FROM StrategischerPartner__mdt
					WHERE DeveloperName = :lead.ZuordnungZuRahmenvertrag__c
					AND Referenzwert__c = TRUE
			];
			if ( strategischerPartners.size() == 1 ) {
				StrategischerPartner__mdt rahmenvertrag = strategischerPartners[ 0 ];
				if ( rahmenvertrag.ArtDerMiete__c == 'Spanne' || rahmenvertrag.ArtDerMiete__c == 'Pauschal' ) {
					durchschnittlicheMiete = returnZeroIfNull( rahmenvertrag.MietkostensatzInEuro__c );
				}
				else {
					durchschnittlicheMiete = anzahlModule * returnZeroIfNull( rahmenvertrag.MietkostensatzInEuro__c );
				}
			}
		}
		catch ( Exception e ) {
			throw new AuraHandledException( e.getMessage() );
		}
		return durchschnittlicheMiete;
	}
	
	private static Decimal returnZeroIfNull ( Decimal value ) {
		return value == null ? 0 : value;
	}
}