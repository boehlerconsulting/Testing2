/**
 *@author       Mats Böhler
 *@created      02.08.2021
 *
 *
 *@description  PodIdService
 *
 *
 *@changelog    02.08.2021 Mats Böhler  - Created
 *              
 * 
 */
public without sharing class PodIdService {
	
	private Map<Id, PODID__c> podIdByLeadIds = new Map<Id, PODID__c>();
	private List<Lead> leads = new List<Lead>();
	private Map<String, String> highestShortIdByPostalCodePoststation = new Map<String, String>();
	private Map<String, String> highestShortIdByPostalCodeOeffentlicherZugang = new Map<String, String>();
	private Map<String, String> highestShortIdByPostalCodePrototyp = new Map<String, String>();
	private Map<String, String> highestShortIdByPostalCodeOne = new Map<String, String>();
	private Map<String, List<String>> shortIdsByPostalCodes = new Map<String, List<String>>();
	private Map<String, List<String>> shortIdsByCities = new Map<String, List<String>>();
	private Map<String, Set<String>> shortIdsByLeitregions = new Map<String, Set<String>>();
	private List<Lead> leadsLueckenfueller = new List<Lead>();
	private List<Lead> leadsLeitregion = new List<Lead>();
	
	public Map<Id, PODID__c> generate ( Set<Id> leadIds ) {
		loadLeads( leadIds );
		loadExistingNumbers();
		searchNumberBasedOnHighestTaken();
		searchNumberBasedOnGaps();
		searchNumberBasedOnLeitregionValidation();
		insert podIdByLeadIds.values();
		return podIdByLeadIds;
	}
	
	private void loadExistingNumbers () {
		Set<String> postalCodes = new Set<String>();
		Set<String> cities = new Set<String>();
		Set<String> leitregions = new Set<String>();
		for ( Lead lead : leads ) {
			
			postalCodes.add( lead.PostalCode );
			cities.add( lead.City );
			leitregions.add( lead.PostalCode.left( 2 ) );
		}
		for ( PODID__c podId : [
				SELECT
						Id,
						Wert__c,
						Leitregion__c,
						PLZ__c,
						Short_ID__c,
						Ort__c
				FROM PODID__c
				WHERE PLZ__c IN :postalCodes
				OR Ort__c IN :cities
				OR Leitregion__c IN :leitregions
				ORDER BY PLZ__c ASC, Short_ID__c ASC
		] ) {
			
			populateSearchMaps( podId );
		}
	}
	
	private void searchNumberBasedOnHighestTaken () {
		
		for ( Lead lead : leads ) {
			if ( lead.ADM_Typ__c == 'Poststation' ) {
				search(
						lead,
						701,
						799,
						highestShortIdByPostalCodePoststation
				);
			}
			else if ( lead.Oeffentlicher_Zugang__c == 'Nein'
					&& lead.ADM_Typ__c != 'Poststation'
					&& lead.ADM_Typ__c != 'Prototyp' ) {
				search(
						lead,
						801,
						899,
						highestShortIdByPostalCodeOeffentlicherZugang
				);
			}
			else if ( lead.ADM_Typ__c == 'Prototyp' ) {
				search(
						lead,
						901,
						999,
						highestShortIdByPostalCodePrototyp
				);
			}
			else {
				Integer firstDigit = highestShortIdByPostalCodeOne.containsKey( lead.PostalCode )
						? Integer.valueOf( highestShortIdByPostalCodeOne.get( lead.PostalCode ).left( 1 ) )
						: 1;
				Integer startNumber = Integer.valueOf( String.valueOf( firstDigit ) + '01' ) ;
				search(
						lead,
						startNumber,
						699,
						highestShortIdByPostalCodeOne
				);
			}
		}
	}
	
	private void searchNumberBasedOnGaps () {
		for ( Lead lead : leadsLueckenfueller ) {
			if ( lead.ADM_Typ__c == 'Poststation' ) {
				search(
						lead,
						701,
						799
				);
			}
			else if ( lead.Oeffentlicher_Zugang__c == 'Nein'
					&& lead.ADM_Typ__c != 'Poststation'
					&& lead.ADM_Typ__c != 'Prototyp' ) {
				search(
						lead,
						801,
						899
				);
			}
			else if ( lead.ADM_Typ__c == 'Prototyp' ) {
				search(
						lead,
						901,
						999
				);
			}
			else {
				search(
						lead,
						101,
						699
				);
			}
		}
	}
	
	private void searchNumberBasedOnLeitregionValidation () {
		for ( Lead lead : leadsLeitregion ) {
			if ( lead.ADM_Typ__c == 'Poststation' ) {
				searchBasedOnLeitregion(
						lead,
						701,
						799
				);
			}
			else if ( lead.Oeffentlicher_Zugang__c == 'Nein'
					&& lead.ADM_Typ__c != 'Poststation'
					&& lead.ADM_Typ__c != 'Prototyp' ) {
				searchBasedOnLeitregion(
						lead,
						801,
						899
				);
			}
			else if ( lead.ADM_Typ__c == 'Prototyp' ) {
				searchBasedOnLeitregion(
						lead,
						901,
						999
				);
			}
			else {
				searchBasedOnLeitregion(
						lead,
						101,
						699
				);
			}
		}
	}
	
	private void populateSearchMaps ( PODID__c podId ) {
		if ( podId.Short_ID__c.startsWith( '7' ) ) {
			highestShortIdByPostalCodePoststation.put( podId.PLZ__c, podId.Short_ID__c );
		}
		else if ( podId.Short_ID__c.startsWith( '8' ) ) {
			highestShortIdByPostalCodeOeffentlicherZugang.put( podId.PLZ__c, podId.Short_ID__c );
		}
		else if ( podId.Short_ID__c.startsWith( '9' ) ) {
			highestShortIdByPostalCodePrototyp.put( podId.PLZ__c, podId.Short_ID__c );
		}
		else {
			highestShortIdByPostalCodeOne.put( podId.PLZ__c, podId.Short_ID__c );
		}
		if ( shortIdsByPostalCodes.containsKey( podId.PLZ__c ) ) {
			shortIdsByPostalCodes.get( podId.PLZ__c ).add( podId.Short_ID__c );
		}
		else {
			shortIdsByPostalCodes.put( podId.PLZ__c, new List<String> {
					podId.Short_ID__c
			} );
		}
		if ( shortIdsByCities.containsKey( podId.Ort__c ) ) {
			shortIdsByCities.get( podId.Ort__c ).add( podId.Short_ID__c );
		}
		else {
			shortIdsByCities.put( podId.Ort__c, new List<String> {
					podId.Short_ID__c
			} );
		}
		if ( shortIdsByLeitregions.containsKey( podId.Leitregion__c ) ) {
			shortIdsByLeitregions.get( podId.Leitregion__c ).add( podId.Short_ID__c );
		}
		else {
			shortIdsByLeitregions.put( podId.Leitregion__c, new Set<String> {
					podId.Short_ID__c
			} );
		}
	}
	
	private void search ( Lead lead, Integer startNumber, Integer endNumber, Map<String, String> highestShortIdByPostalCode ) {
		String podId = null;
		String nextShortId = '';
		if ( highestShortIdByPostalCode.containsKey( lead.PostalCode ) ) {
			String highestShortId = highestShortIdByPostalCode.get( lead.PostalCode );
			nextShortId = highestShortId.right( 1 ) == '9'
					? String.valueOf( Integer.valueOf( highestShortId ) + 2 )
					: String.valueOf( Integer.valueOf( highestShortId ) + 1 );
			if ( nextShortId.startsWith( '3' ) ) {
				nextShortId = String.valueOf( Integer.valueOf( nextShortId ) + 100 );
			}
			while ( shortIdExistsInCity( lead.City, nextShortId ) ) {
				
				nextShortId = String.valueOf( Integer.valueOf( nextShortId ) + 1 );
			}
			if ( Integer.valueOf( nextShortId ) <= endNumber ) {
				podId = lead.PostalCode + nextShortId;
				highestShortIdByPostalCode.put( lead.PostalCode, podId );
				addPODID( lead, podId );
			}
		}
		else {
			nextShortId = String.valueOf( startNumber );
			while ( shortIdExistsInCity( lead.City, nextShortId ) ) {
				
				nextShortId = String.valueOf( Integer.valueOf( nextShortId ) + 1 );
			}
			podId = lead.PostalCode + nextShortId;
			highestShortIdByPostalCode.put( lead.PostalCode, podId );
			addPODID( lead, podId );
		}
		if ( podId == null ) {
			leadsLueckenfueller.add( lead );
		}
	}
	
	private void search ( Lead lead, Integer startNumber, Integer endNumber ) {
		String podId = null;
		String nextShortId = '';
		
		if ( !shortIdsByPostalCodes.containsKey( lead.PostalCode ) ) {
			return;
		}
		List<String> shortIdsInUse = shortIdsByPostalCodes.get( lead.PostalCode );
		for ( Integer i = startNumber; i <= endNumber; i++ ) {
			
			if ( !shortIdsInUse.contains( String.valueOf( i ) )
					&& String.valueOf( i ).right( 1 ) != '0'
					&& String.valueOf( i ).left( 1 ) != '3'
					&& !shortIdExistsInCity( lead.City, String.valueOf( i ) ) ) {
				
				nextShortId = String.valueOf( i );
				break;
			}
		}
		if ( nextShortId == '' ) {
			leadsLeitregion.add( lead );
		}
		else {
			podId = lead.PostalCode + nextShortId;
			addPODID( lead, podId );
		}
	}
	
	private void searchBasedOnLeitregion ( Lead lead, Integer startNumber, Integer endNumber ) {
		String podId = null;
		String nextShortId = '';
		
		if ( !shortIdsByPostalCodes.containsKey( lead.PostalCode ) ) {
			return;
		}
		List<String> shortIdsInUse = shortIdsByPostalCodes.get( lead.PostalCode );
		
		for ( Integer i = startNumber; i <= endNumber; i++ ) {
			
			if ( !shortIdsInUse.contains( String.valueOf( i ) )
					&& String.valueOf( i ).right( 1 ) != '0'
					&& String.valueOf( i ).left( 1 ) != '3'
					&& !shortIdExistsInLeitregion( lead.PostalCode.left( 2 ), String.valueOf( i ) ) ) {
				
				nextShortId = String.valueOf( i );
				break;
			}
		}
		if ( nextShortId == '' ) {
			sendAdminEmail( lead.Id );
		}
		else {
			podId = lead.PostalCode + nextShortId;
			addPODID( lead, podId );
		}
	}
	
	private void addPODID ( Lead lead, String podId ) {
		String nextShortId = podId.right( 3 );
		podIdByLeadIds.put( lead.Id,
				new PODID__c(
						Name = podId,
						Wert__c = podId,
						Status__c = 'Vergeben',
						Ort__c = lead.City
				)
		);
		if ( shortIdsByPostalCodes.containsKey( lead.PostalCode ) ) {
			shortIdsByPostalCodes.get( lead.PostalCode ).add( nextShortId );
		}
		else {
			shortIdsByPostalCodes.put( lead.PostalCode, new List<String> {
					nextShortId
			} );
		}
		if ( shortIdsByCities.containsKey( lead.City ) ) {
			shortIdsByCities.get( lead.City ).add( nextShortId );
		}
		else {
			shortIdsByCities.put( lead.City, new List<String> {
					nextShortId
			} );
		}
		if ( shortIdsByLeitregions.containsKey( lead.PostalCode.left( 2 ) ) ) {
			shortIdsByLeitregions.get( lead.PostalCode.left( 2 ) ).add( nextShortId );
		}
		else {
			shortIdsByLeitregions.put( lead.PostalCode.left( 2 ), new Set<String> {
					nextShortId
			} );
		}
	}
	
	public void sendAdminEmail ( Id leadId ) {
		EmailEinstellung__mdt emailEinstellung = [
				SELECT
						Id,
						EmailVon__c,
						EmailAn__c,
						EmailCC__c,
						EmailTemplate__c
				FROM EmailEinstellung__mdt
				WHERE DeveloperName = 'PODIDsVerbraucht'
				LIMIT 1
		];
		
		EmailTemplate emailTemplate = [
				SELECT
						Id
				FROM EmailTemplate
				WHERE DeveloperName = :emailEinstellung.EmailTemplate__c
				LIMIT 1
		];
		Messaging.reserveSingleEmailCapacity( 1 );
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		mail.setSenderDisplayName( UserInfo.getUserEmail() );
		mail.setReplyTo( UserInfo.getUserEmail() );
		mail.setToAddresses( emailEinstellung.EmailAn__c.split( ';' ) );
		mail.setTemplateId( emailTemplate.Id );
		mail.setTargetObjectId( UserInfo.getUserId() );
		mail.setWhatId( leadId );
		mail.setSaveAsActivity( false );
		if ( !Test.isRunningTest() ) {
			Messaging.sendEmail( new Messaging.SingleEmailMessage[] {
					mail
			} );
		}
	}
	
	private void loadLeads ( Set<Id> leadIds ) {
		leads = [
				SELECT
						Id,
						PostalCode,
						ADM_Typ__c,
						Oeffentlicher_Zugang__c,
						City
				FROM Lead
				WHERE Id IN :leadIds
				AND PostalCode != NULL
				AND PODID_Lookup__c = NULL
				AND City != NULL
		];
	}
	
	private Boolean shortIdExistsInCity ( String city, String shortId ) {
		if ( !shortIdsByCities.containsKey( city ) ) {
			return false;
		}
		return shortIdsByCities.get( city ).contains( shortId );
	}
	
	private Boolean shortIdExistsInLeitregion ( String leitregion, String shortId ) {
		if ( !shortIdsByLeitregions.containsKey( leitregion ) ) {
			return false;
		}
		return shortIdsByLeitregions.get( leitregion ).contains( shortId );
	}
}