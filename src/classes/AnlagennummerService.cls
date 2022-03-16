/**
 *@author       Mats Böhler
 *@created      16.06.2020
 *
 *
 *@description  AnlagennummerService
 *
 *
 *@changelog    16.06.2020 Mats Böhler  - Created
 *              
 * 
 */
public without sharing class AnlagennummerService {
	
	private String startNumber;
	private String endNumber;
	private Set<String> existingManualAnlagennummers = new Set<String>();
	private Set<String> existingAnlagennummers = new Set<String>();
	private Map<String, Anlagennummer__c> anlagennummerByName = new Map<String, Anlagennummer__c>();
	private Map<String, Anlagennummer__c> lockedAnlagennummerByName = new Map<String, Anlagennummer__c>();
	private Set<String> newAnlagennummers = new Set<String>();
	
	public void generate ( String startNumber, String endNumber ) {
		this.startNumber = startNumber;
		this.endNumber = endNumber;
		if ( String.isEmpty( startNumber ) || String.isEmpty( endNumber ) ) {
			return;
		}
		validate();
		create();
	}
	
	private void validate () {
		
		if ( startNumber.length() != 8 ) {
			throw new AnlagennummerServiceException( 'Die Startnummer muss exakt 8 Stellen besitzen!' );
		}
		
		if ( endNumber.length() != 8 ) {
			throw new AnlagennummerServiceException( 'Die Endnummer muss exakt 8 Stellen besitzen!' );
		}
		
		if ( Integer.valueOf( endNumber ) < Integer.valueOf( startNumber ) ) {
			throw new AnlagennummerServiceException( 'Die Endnummer muss größer als die Startnummer sein!' );
		}
	}
	
	private void create () {
		for ( Integer i = Integer.valueOf( startNumber ); i <= Integer.valueOf( endNumber ); i++ ) {
			String anlagennummer = String.valueOf( i );
			while ( anlagennummer.length() < 8 ) {
				anlagennummer = '0' + anlagennummer;
			}
			anlagennummerByName.put(
					anlagennummer,
					new Anlagennummer__c(
							Id = lockedAnlagennummerByName.containsKey( anlagennummer )
									? lockedAnlagennummerByName.get( anlagennummer ).Id
									: null,
							Name = anlagennummer,
							Status__c = 'verfügbar'
					)
			);
			newAnlagennummers.add( anlagennummer );
		}
		if ( newAnlagennummers.isEmpty() ) {
			return;
		}
		removeDuplicates();
		for ( Anlagennummer__c anlagennummer : anlagennummerByName.values() ) {
			anlagennummer.Id = lockedAnlagennummerByName.containsKey( anlagennummer.Name )
					? lockedAnlagennummerByName.get( anlagennummer.Name ).Id
					: null;
		}
		upsert anlagennummerByName.values();
	}
	
	private void removeDuplicates () {
		loadExistingAnlagennummers( newAnlagennummers );
		loadExistingManualAnlagennummers( newAnlagennummers );
		for ( String name : anlagennummerByName.keySet() ) {
			if ( existingAnlagennummers.contains( name ) || existingManualAnlagennummers.contains( name ) ) {
				anlagennummerByName.remove( name );
			}
		}
	}
	
	private void loadExistingManualAnlagennummers ( Set<String> newAnlagennummers ) {
		for ( Lead lead : [
				SELECT
						Id,
						Anlagenummer__c
				FROM Lead
				WHERE Anlagenummer__c IN :newAnlagennummers
		] ) {
			
			existingManualAnlagennummers.add( lead.Anlagenummer__c );
		}
	}
	
	private void loadExistingAnlagennummers ( Set<String> newAnlagennummers ) {
		for ( Anlagennummer__c anlagennummer : [
				SELECT
						Id,
						Name,
						Status__c
				FROM Anlagennummer__c
				WHERE Name IN :newAnlagennummers
		] ) {
			if ( anlagennummer.Status__c == 'gesperrt' ) {
				lockedAnlagennummerByName.put( anlagennummer.Name, anlagennummer );
			}
			else {
				existingAnlagennummers.add( anlagennummer.Name );
			}
		}
	}
	
	public class AnlagennummerServiceException extends Exception {
	}
}