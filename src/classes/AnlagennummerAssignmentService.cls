/**
 *@author       Mats Böhler
 *@created      13.06.2020
 *
 *
 *@description  AnlagennummerAssignmentService
 *
 *
 *@changelog    13.06.2020 Mats Böhler  - Created
 *              
 * 
 */
public without sharing class AnlagennummerAssignmentService {
	
	private List<Lead> leads = new List<Lead>();
	private Map<String, Anlagennummer__c> availableAnlagennummerByName = new Map<String, Anlagennummer__c>();
	private Set<String> existingManualAnlagennummers = new Set<String>();
	
	public List<Lead> assign ( List<Lead> leads ) {
		this.leads = leads;
		loadAvailableAnlagennummern();
		loadManualAnlagennummers();
		List<Anlagennummer__c> assignedAnlagennummers = new List<Anlagennummer__c>();
		List<AnlagennummerHistorie__c> anlagennummerHistories = new List<AnlagennummerHistorie__c>();
		for ( Lead lead : leads ) {
			if ( availableAnlagennummerByName.values().size() > 0 ) {
				Anlagennummer__c availableAnlagennummer = availableAnlagennummerByName.values().get( 0 );
				lead.Anlagennummer__c = availableAnlagennummer.Id;
				lead.AnlagennummerDuplikatscheck__c = availableAnlagennummer.Id;
				availableAnlagennummer.Status__c = 'vergeben';
				assignedAnlagennummers.add( availableAnlagennummer );
				availableAnlagennummerByName.values().remove( 0 );
				
				anlagennummerHistories.add(
						new AnlagennummerHistorie__c(
								Anlagennummer__c = availableAnlagennummer.Id,
								Aktion__c = 'Zugewiesen',
								Nachricht__c = 'Die Anlagennummer wurde zugewiesen.',
								Lead__c = lead.Id
						)
				);
			}
			else {
				
				lead.Anlagennummer__c.addError( 'Keine Anlagennummern verfügbar. Anlagennummern sind im Zulauf.' );
			}
		}
		update assignedAnlagennummers;
		insert anlagennummerHistories;
		notify();
		return leads;
	}
	
	@Future
	private static void notify () {
		try {
			new AnlagennummerNotificationService().sendEmailNotificationAboutRemainingNumbers();
		}
		catch ( Exception e ) {
			new HW_ErrorLogging().logException(
					e,
					new Set<Id>(),
					'AnlagennummerService().sendEmailNotificationAboutRemainingNumbers() - MYPM-140'
			);
		}
	}
	
	private void loadAvailableAnlagennummern () {
		Integer maxRecords = leads.size() + 200;
		for ( Anlagennummer__c anlagennummer : [
				SELECT
						Id,
						Name
				FROM Anlagennummer__c
				WHERE Status__c = 'verfügbar'
				ORDER BY Name ASC NULLS LAST
				LIMIT :maxRecords
		] ) {
			
			availableAnlagennummerByName.put( anlagennummer.Name, anlagennummer );
		}
	}
	
	private void loadManualAnlagennummers () {
		Set<String> anlagennummers = new Set<String>();
		for ( Anlagennummer__c anlagennummer : availableAnlagennummerByName.values() ) {
			anlagennummers.add( anlagennummer.Name );
		}
		for ( Lead lead : [
				SELECT
						Id,
						Anlagenummer__c
				FROM Lead
				WHERE Anlagenummer__c IN :anlagennummers
		] ) {
			existingManualAnlagennummers.add( lead.Anlagenummer__c );
		}
		for ( String nummer : existingManualAnlagennummers ) {
			if ( availableAnlagennummerByName.containsKey( nummer ) ) {
				availableAnlagennummerByName.remove( nummer );
			}
		}
	}
}