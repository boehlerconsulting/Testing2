/**
 *@author       Mats Böhler
 *@created      13.09.2021
 *
 *
 *@description  PackstationDummyInitializer
 *
 *
 *@changelog    13.09.2021 Mats Böhler  - Created
 *              
 * 
 */
public without sharing class PackstationDummyInitializer {
	
	private static String RECORD_TYPE_ID = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
			.get( 'Packstation_Dummy' ).getRecordTypeId();
	
	private Set<Id> leadIds = new Set<Id>();
	private Map<Id, Account> accountByLeadIds = new Map<Id, Account>();
	private Map<String, String> profileNameByUserIds = new Map<String, String>();
	private List<Account> existingAccounts = new List<Account>();
	
	public void create ( Set<Id> leadIds ) {
		if ( leadIds.isEmpty() ) {
			return;
		}
		this.leadIds = leadIds;
		loadProfileNameByUserIds();
		for ( Lead lead : loadLeads() ) {
			if ( lead.Packstation__c == null ) {
				addPackstationDummy( lead );
			}
			else {
				updateAccountFields( lead, new Account( Id = lead.Packstation__c ) );
			}
		}
		update existingAccounts;
		setDummyIdOnLeads();
	}
	
	public void cloneAccountContactRelations ( Set<Id> leadIds ) {
		this.leadIds = leadIds;
		Set<Id> accountIds = new Set<Id>();
		for ( Lead lead : [
				SELECT
						Id,
						Filiale_Filialpartner__c,
						Packstation__c
				FROM Lead
				WHERE Id IN :leadIds
				AND Filiale_Filialpartner__c != NULL
				AND Packstation__c != NULL
		] ) {
			accountIds.add( lead.Filiale_Filialpartner__c );
		}
		Map<Id, List<AccountContactRelation>> accountContactRelationsByAccountIds = new Map<Id, List<AccountContactRelation>>();
		for ( AccountContactRelation accountContactRelation : [
				SELECT
						Id,
						AccountId,
						ContactId,
						Roles
				FROM AccountContactRelation
				WHERE AccountId IN :accountIds
		] ) {
			if ( accountContactRelationsByAccountIds.containsKey( accountContactRelation.AccountId ) ) {
				accountContactRelationsByAccountIds.get( accountContactRelation.AccountId ).add( accountContactRelation );
			}
			else {
				accountContactRelationsByAccountIds.put( accountContactRelation.AccountId, new List<AccountContactRelation> {
						accountContactRelation
				} );
			}
		}
		List<AccountContactRelation> clonedAccountContactRelations = new List<AccountContactRelation>();
		for ( Lead lead : [
				SELECT
						Id,
						Filiale_Filialpartner__c,
						Packstation__c
				FROM Lead
				WHERE Id IN :leadIds
				AND Filiale_Filialpartner__c != NULL
				AND Packstation__c != NULL
		] ) {
			if ( accountContactRelationsByAccountIds.containsKey( lead.Filiale_Filialpartner__c ) ) {
				for ( AccountContactRelation accountContactRelation : accountContactRelationsByAccountIds.get( lead.Filiale_Filialpartner__c ) ) {
					AccountContactRelation clonedAccountContactRelation = new AccountContactRelation(
							AccountId = lead.Packstation__c,
							ContactId = accountContactRelation.ContactId,
							Roles = accountContactRelation.Roles
					);
					clonedAccountContactRelations.add( clonedAccountContactRelation );
				}
			}
		}
		insert clonedAccountContactRelations;
	}
	
	private void updateAccountFields ( Lead lead, Account account ) {
		account = setAccountFields( lead, account );
		existingAccounts.add( account );
	}
	
	private void setDummyIdOnLeads () {
		if ( accountByLeadIds.isEmpty() ) {
			return;
		}
		insert accountByLeadIds.values();
		List<Lead> leads = new List<Lead>();
		for ( Id leadId : accountByLeadIds.keySet() ) {
			leads.add(
					new Lead(
							Id = leadId,
							Packstation__c = accountByLeadIds.get( leadId ).Id
					)
			);
		}
		TriggerHandler.bypass( 'LeadTriggerHandler' );
		update leads;
		TriggerHandler.clearAllBypasses();
	}
	
	private void addPackstationDummy ( Lead lead ) {
		Account account = new Account();
		account = setAccountFields( lead, account );
		account.RecordTypeId = RECORD_TYPE_ID;
		accountByLeadIds.put( lead.Id, account );
	}
	
	private Account setAccountFields ( Lead lead, Account account ) {
		String ownerId = profileNameByUserIds.get( UserInfo.getUserId() ).contains( 'myPM Vertrieb (' )
				? lead.OwnerId
				: lead.Filialnetzaenderung__r.NL_BriefKoordinator__c;
		if ( ownerId == null ) {
			ownerId = lead.OwnerId;
		}
		account.Name = 'Packstation '
				+ lead.PODID_Lookup__r.Short_ID__c
				+ ', '
				+ lead.PostalCode
				+ ' '
				+ lead.City;
		account.OwnerId = ownerId;
		account.PODID__c = lead.PODID_Lookup__c;
		account.ASt_Name__c = lead.PODID_Lookup__r.Wert__c;
		account.GL__c = lead.VL__r.GL__c;
		account.NL_Brief_Lookup__c = lead.Filialnetzaenderung__r.NL_Brief__c;
		account.NL_Brief__c = lead.Filialnetzaenderung__r.NL_Brief__r.Name;
		account.Lead__c = lead.Id;
		account.ADM_Hersteller__c = lead.ADM_Hersteller__c;
		account.ADM_Typ__c = lead.ADM_Typ__c;
		account.Akquisemodus__c = lead.Akquisemodus__c;
		account.Betreiber__c = lead.Strategischer_Partner__c;
		account.VertragspartnerId__c = lead.Strategischer_PartnerID__c;
		account.DPAG_Kostenstelle__c = lead.Kostenstelle__c;
		account.Filial_ILN__c = lead.STOG_Interne_ID__c;
		account.Filialnetzaenderung__c = lead.Filialnetzaenderung__c;
		account.Inbetriebnahme_Datum__c = lead.go_live__c;
		account.Oeffentlicher_Zugang__c = lead.Oeffentlicher_Zugang__c == 'Ja';
		account.Phone = lead.Phone;
		account.ShippingCity = lead.City;
		account.ShippingPostalCode = lead.PostalCode;
		account.ShippingStreet = lead.Street;
		account.Unterlagen_zur_Freigabe_einreichen_bei__c = lead.UnterlagenZurFreigabeEinreichenBei__c;
		account.Zuordnung_zu_Rahmenvertrag__c = lead.ZuordnungZuRahmenvertrag__c;
		return account;
	}
	
	private List<Lead> loadLeads () {
		return [
				SELECT
						Id,
						PODID_Lookup__c,
						PODID_Lookup__r.Short_ID__c,
						PODID_Lookup__r.Wert__c,
						VL__r.GL__c,
						Filialnetzaenderung__r.NL_Brief__c,
						Filialnetzaenderung__r.NL_Brief__r.Name,
						Filialnetzaenderung__r.NL_BriefKoordinator__c,
						Company,
						OwnerId,
						ADM_Hersteller__c,
						ADM_Typ__c,
						Akquisemodus__c,
						Strategischer_Partner__c,
						Strategischer_PartnerID__c,
						Kostenstelle__c,
						STOG_Interne_ID__c,
						Filialnetzaenderung__c,
						go_live__c,
						Email,
						LastName,
						FirstName,
						City,
						PostalCode,
						Oeffentlicher_Zugang__c,
						Phone,
						Street,
						UnterlagenZurFreigabeEinreichenBei__c,
						ZuordnungZuRahmenvertrag__c,
						Packstation__c
				FROM Lead
				WHERE Id IN :leadIds
		];
	}
	
	private void loadProfileNameByUserIds () {
		Set<String> userIds = new Set<String>();
		userIds.add( UserInfo.getUserId() );
		for ( User user : [
				SELECT
						Id,
						Profile.Name
				FROM User
				WHERE Id IN :userIds
		] ) {
			profileNameByUserIds.put( user.Id, user.Profile.Name );
		}
	}
}