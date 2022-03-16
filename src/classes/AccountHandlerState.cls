/**
 *@author       Mats Böhler
 *@created      23.11.2021
 *
 *
 *@description  AccountHandlerState
 *
 *
 *@changelog    23.11.2021 Mats Böhler  - Created
 *              
 * 
 */
public without sharing class AccountHandlerState {
	
	public Set<Id> terminatedFilialenIds = new Set<Id>();
	public Set<Id> terminatedFilalenIdsExcludingDPS = new Set<Id>();
	public Set<Id> terminatedDPSInterimFilialenIds = new Set<Id>();
	public Set<Id> terminatedFilialenClassicIds = new Set<Id>();
	public Set<Id> terminatedOZ95OrDPS79Ids = new Set<Id>();
	public Set<Id> terminatedDPSInterimFilialenIdsSameDate = new Set<Id>();
	public Set<Id> terminatedDPSInterimFilialenIdsChangedDate = new Set<Id>();
	public Set<Id> createdFilialenIds = new Set<Id>();
	public Set<Id> newPartnerFilialeExcludingDPSIds = new Set<Id>();
	public Set<Id> newPartnerFilialeDPSIds = new Set<Id>();
	public Set<Id> dhlPaketshopTOOMIds = new Set<Id>();
	public Set<Id> dhlPaketshopREWEIds = new Set<Id>();
	public Set<Id> dhlPaketshopIds = new Set<Id>();
	public Set<Id> conversion95To79Or76Ids = new Set<Id>();
	public Set<Id> conversion79Or76To95Ids = new Set<Id>();
	public Set<Id> conversion95To84Ids = new Set<Id>();
	public Set<Id> conversion84To95Ids = new Set<Id>();
	public Set<Id> conversion84To79Or76Ids = new Set<Id>();
	public Set<Id> conversion79Or76To84Ids = new Set<Id>();
	public Set<Id> oz95Ids = new Set<Id>();
	public Set<Id> oz76Ids = new Set<Id>();
	public Set<Id> laufendeFilialenIds = new Set<Id>();
	public Set<Id> accountIdsLaufenderBetriebNoPops = new Set<Id>();
	public Set<Id> accountIdsEroeffnungChanged = new Set<Id>();
	public Set<Id> accountIdsSchliessungChanged = new Set<Id>();
	public Set<Id> accountIdsSchliessungBiggerEroeffnungChanged = new Set<Id>();
	public Set<Id> accountIdsSchliessungEqualsEroeffnungChanged = new Set<Id>();
	public Set<Id> accountIdsSchliessungRemovedChanged = new Set<Id>();
	public Set<Id> accountIdsOwnerChanged = new Set<Id>();
	public Set<Id> accountIdsVertragsbetreuendeEinheitChanged = new Set<Id>();
	public Set<Id> accountIdsSendEmailsZORA3600 = new Set<Id>();
	public Set<Id> accountIdsEroeffnungDPS = new Set<Id>();
	public Set<Id> accountIdsWerbemedienFACTS = new Set<Id>();
	public Set<Id> accountIdsAreYouHappyCall = new Set<Id>();
	public Set<Id> leadIdsPackstation = new Set<Id>();
	public Set<Id> accountIdsBestandsmassnahme = new Set<Id>();
	public Set<Id> accountIdsLaufenderBetriebPartnerjubilaeum = new Set<Id>();
	public Map<Id, List<Account>> accountsByRemovedPODIDs = new Map<Id, List<Account>>();
	public Map<String, String> accountIdByDebitor = new Map<String, String>();
	
	private static AccountHandlerState instance = null;
	
	public static AccountHandlerState getInstance () {
		if ( instance == null ) {
			instance = new AccountHandlerState();
		}
		return instance;
	}
	
	public void resetSets () {
		terminatedFilialenIds = new Set<Id>();
		terminatedFilalenIdsExcludingDPS = new Set<Id>();
		terminatedDPSInterimFilialenIds = new Set<Id>();
		terminatedFilialenClassicIds = new Set<Id>();
		terminatedOZ95OrDPS79Ids = new Set<Id>();
		terminatedDPSInterimFilialenIdsSameDate = new Set<Id>();
		terminatedDPSInterimFilialenIdsChangedDate = new Set<Id>();
		createdFilialenIds = new Set<Id>();
		newPartnerFilialeExcludingDPSIds = new Set<Id>();
		newPartnerFilialeDPSIds = new Set<Id>();
		dhlPaketshopTOOMIds = new Set<Id>();
		dhlPaketshopREWEIds = new Set<Id>();
		dhlPaketshopIds = new Set<Id>();
		conversion95To79Or76Ids = new Set<Id>();
		conversion79Or76To95Ids = new Set<Id>();
		conversion95To84Ids = new Set<Id>();
		conversion84To95Ids = new Set<Id>();
		conversion84To79Or76Ids = new Set<Id>();
		conversion79Or76To84Ids = new Set<Id>();
		oz95Ids = new Set<Id>();
		oz76Ids = new Set<Id>();
		laufendeFilialenIds = new Set<Id>();
		accountIdsLaufenderBetriebNoPops = new Set<Id>();
		accountIdsLaufenderBetriebPartnerjubilaeum = new Set<Id>();
		accountIdsEroeffnungChanged = new Set<Id>();
		accountIdsSchliessungChanged = new Set<Id>();
		accountIdsSchliessungBiggerEroeffnungChanged = new Set<Id>();
		accountIdsSchliessungEqualsEroeffnungChanged = new Set<Id>();
		accountIdsSchliessungRemovedChanged = new Set<Id>();
		accountIdsOwnerChanged = new Set<Id>();
		accountIdsVertragsbetreuendeEinheitChanged = new Set<Id>();
		accountIdsSendEmailsZORA3600 = new Set<Id>();
		accountIdsEroeffnungDPS = new Set<Id>();
		accountIdsWerbemedienFACTS = new Set<Id>();
		accountIdsAreYouHappyCall = new Set<Id>();
		accountsByRemovedPODIDs = new Map<Id, List<Account>>();
		leadIdsPackstation = new Set<Id>();
		accountIdsBestandsmassnahme = new Set<Id>();
		accountIdByDebitor = new Map<String, String>();
	}
}