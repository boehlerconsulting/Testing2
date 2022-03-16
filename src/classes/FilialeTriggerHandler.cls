/**
 *@author       Mats Böhler
 *@created      23.11.2021
 *
 *
 *@description  FilialTriggerHandler
 *
 *
 *@changelog    23.11.2021 Mats Böhler  - Created
 *              
 * 
 */
public without sharing class FilialeTriggerHandler extends AccountBaseHandler {
	
	private List<Account> newRecords = new List<Account>();
	private static Boolean partnerJubilaeumSetDuringThisExecutionContext = false;
	
	public FilialeTriggerHandler ( List<Account> newRecords ) {
		this.newRecords = newRecords;
	}
	
	protected override void beforeInsert () {
		if ( newRecords.isEmpty() ) {
			return;
		}
		processBeforeInsert();
	}
	
	protected override void afterInsert () {
		if ( newRecords.isEmpty() ) {
			return;
		}
		processAfterInsert();
	}
	
	protected override void beforeUpdate () {
		if ( newRecords.isEmpty() ) {
			return;
		}
		processBeforeUpdate();
	}
	
	protected override void afterUpdate () {
		if ( newRecords.isEmpty() ) {
			return;
		}
		processAfterUpdate();
	}
	
	private void processBeforeInsert () {
		for ( Account account : newRecords ) {
			account.PostfachanlageCheckbox__c = account.Postfachanlage__c == 'true';
			setVertragsbetreuendeEinheit( account );
			setKundenrelevanzklasse( account );
		}
	}
	
	private void processAfterInsert () {
		for ( Account account : newRecords ) {
			processAccount( account );
		}
		sendEmailsZora3600( handlerState.accountIdsSendEmailsZORA3600 );
		setNewVertragsbetreuendeEinheitForVertragspartner( handlerState.accountIdsVertragsbetreuendeEinheitChanged );
	}
	
	private void processBeforeUpdate () {
		loadAccountsWithRelatedInformation();
		for ( Account account : newRecords ) {
			trackVertriebsleitungChanged( account );
			setVertragsbetreuendeEinheit( account );
			setKundenrelevanzklasse( account );
			setSDSAstID( account );
			account.PostfachanlageCheckbox__c = account.Postfachanlage__c == 'true';
			if ( isPartnerJubilaeum( account ) ) {
				account.Jahr_letzte_Anlage_Partnerjubilaeum__c = Date.today().year();
				partnerJubilaeumSetDuringThisExecutionContext = true;
			}
			if ( isConversion95To79Or76( account )
					|| isConversion79Or76To95( account )
					|| isConversion95To84( account )
					|| isConversion84To95( account )
					|| isConversion84To79Or76( account )
					|| isConversion79Or76To84( account ) ) {
				
				account.EOE_Datum_Partnerjubilaeum__c
						= accountsWithRelatedInformationById.get( account.Id ).Vorgaengerfiliale__r.EOE_Datum_Partnerjubilaeum__c;
			}
		}
	}
	
	private void processAfterUpdate () {
		for ( Account account : newRecords ) {
			processAccount( account );
		}
		sendEmailsZora3600( handlerState.accountIdsSendEmailsZORA3600 );
		setNewVertragsbetreuendeEinheitForVertragspartner( handlerState.accountIdsVertragsbetreuendeEinheitChanged );
	}
	
	private void processAccount ( Account account ) {
		trackIsDebitorAdded( account );
		addSchliessung( account );
		addNeueroeffnung( account );
		addCreatedFilialen( account );
		if ( isPartnerJubilaeum( account ) ) {
			handlerState.accountIdsLaufenderBetriebPartnerjubilaeum.add( account.Id );
			handlerState.laufendeFilialenIds.add( account.Id );
		}
		if ( sendEmailZora3600( account ) ) {
			handlerState.accountIdsSendEmailsZORA3600.add( account.Id );
		}
		
		if ( isEroeffnungChanged( account ) ) {
			handlerState.accountIdsEroeffnungChanged.add( account.Id );
		}
		if ( isSchliessungChanged( account ) ) {
			handlerState.accountIdsSchliessungChanged.add( account.Id );
		}
		if ( isFilialinhaberwechsel( account ) ) {
			handlerState.accountIdsOwnerChanged.add( account.Id );
		}
		if ( isSchliessungBiggerEroeffnung( account ) ) {
			handlerState.accountIdsSchliessungBiggerEroeffnungChanged.add( account.Id );
		}
		else if ( isSchliessungEqualEroeffnung( account ) ) {
			handlerState.accountIdsSchliessungEqualsEroeffnungChanged.add( account.Id );
		}
		else if ( isSchliessungRemoved( account ) ) {
			handlerState.accountIdsSchliessungRemovedChanged.add( account.Id );
		}
		else {
			//Sonarqube --> do nothing
		}
		if ( isVertragsbetreuendeEinheitChanged( account ) ) {
			handlerState.accountIdsVertragsbetreuendeEinheitChanged.add( account.Id );
		}
	}
	
	private void addCreatedFilialen ( Account account ) {
		if ( isNewDPSFiliale( account )
				&& !isNewDPSFiliale( oldAccountMap?.get( account.Id ) ) ) {
			
			handlerState.accountIdsEroeffnungDPS.add( account.Id );
			handlerState.createdFilialenIds.add( account.Id );
		}
		if ( isNewPartnerFilialeExcludingDPS( account ) ) {
			handlerState.newPartnerFilialeExcludingDPSIds.add( account.Id );
			handlerState.createdFilialenIds.add( account.Id );
			addDebitor( account );
		}
		else if ( isNewPartnerFilialeDPS( account ) ) {
			handlerState.newPartnerFilialeDPSIds.add( account.Id );
			handlerState.createdFilialenIds.add( account.Id );
			addDebitor( account );
		}
		else if ( isConversion95To79Or76( account ) ) {
			handlerState.conversion95To79Or76Ids.add( account.Id );
			handlerState.createdFilialenIds.add( account.Id );
			addDebitor( account );
		}
		else if ( isConversion79Or76To95( account ) ) {
			handlerState.conversion79Or76To95Ids.add( account.Id );
			handlerState.createdFilialenIds.add( account.Id );
			addDebitor( account );
		}
		else if ( isConversion95To84( account ) ) {
			handlerState.conversion95To84Ids.add( account.Id );
			handlerState.createdFilialenIds.add( account.Id );
			addDebitor( account );
		}
		else if ( isConversion84To95( account ) ) {
			handlerState.conversion84To95Ids.add( account.Id );
			handlerState.createdFilialenIds.add( account.Id );
			addDebitor( account );
		}
		else if ( isConversion84To79Or76( account ) ) {
			handlerState.conversion84To79Or76Ids.add( account.Id );
			handlerState.createdFilialenIds.add( account.Id );
			addDebitor( account );
		}
		else if ( isConversion79Or76To84( account ) ) {
			handlerState.conversion79Or76To84Ids.add( account.Id );
			handlerState.createdFilialenIds.add( account.Id );
			addDebitor( account );
		}
		else {
			//Sonarqube --> do nothing
		}
	}
	
	private Boolean isPartnerJubilaeum ( Account account ) {
		return account.Betriebsstatus__c != 'geschlossen'
				&& account.EOE_Datum_Partnerjubilaeum__c != null
				&& ( account.Jahr_letzte_Anlage_Partnerjubilaeum__c == null
				|| account.Jahr_letzte_Anlage_Partnerjubilaeum__c != Date.today().year()
				|| partnerJubilaeumSetDuringThisExecutionContext )
				&& ( ( account.EOE_Datum_Partnerjubilaeum__c.addYears( 15 ).addDays( -56 ) <= Date.today()
				&& account.EOE_Datum_Partnerjubilaeum__c.addYears( 15 ).addDays( -53 ) >= Date.today() )
				|| ( account.EOE_Datum_Partnerjubilaeum__c.addYears( 20 ).addDays( -56 ) <= Date.today()
				&& account.EOE_Datum_Partnerjubilaeum__c.addYears( 20 ).addDays( -53 ) >= Date.today() )
				|| ( account.EOE_Datum_Partnerjubilaeum__c.addYears( 25 ).addDays( -56 ) <= Date.today()
				&& account.EOE_Datum_Partnerjubilaeum__c.addYears( 25 ).addDays( -53 ) >= Date.today() ) );
	}
	
	private Boolean isNewDPSFiliale ( Account account ) {
		return account?.Filialart__c != null
				&& account?.Filialart__c.startsWith( 'DPS-Interimslösung' )
				&& account?.Filialtyp_OZ__c != '78'
				&& account?.NL_Brief_Lookup__c != null;
	}
	
	private Boolean isNewPartnerFilialeExcludingDPS ( Account account ) {
		return ( account.Vorgaengerfiliale_Name__c == 'nicht vorhanden'
				|| returnEmptyIfNull( account.Netzentscheidung_Vorgaengerfiliale__c ).startsWith( 'Folgeakquisition' )
				|| account.Netzentscheidung_Vorgaengerfiliale__c == null
				|| account.Filialtyp_OZ_Vorgaengerfiliale__c == '82' )
				&& !returnEmptyIfNull( account.Filialart__c ).startsWith( 'DPS' )
				&& account.NL_Brief_Lookup__c != null
				&& (
				isChanged( account.Id, 'NL_Brief_Lookup__c' )
						|| isChanged( account.Id, 'RecordTypeId' ) )
				&& account.Eroeffnungsdatum__c > Date.newInstance( 2016, 4, 25 );
	}
	
	private Boolean isNewPartnerFilialeDPS ( Account account ) {
		return returnEmptyIfNull( account.Filialart__c ).contains( 'DPS' )
				&& account.NL_Brief_Lookup__c != null
				&& (
				isChanged( account.Id, 'NL_Brief_Lookup__c' )
						|| isChanged( account.Id, 'RecordTypeId' ) )
				&& account.Eroeffnungsdatum__c > Date.newInstance( 2016, 4, 25 );
	}
	
	private Boolean isConversion79Or76To84 ( Account account ) {
		return account.Netzentscheidung_Vorgaengerfiliale__c == 'Formatänderung genehmigt'
				&& ( account.Filialtyp_OZ_Vorgaengerfiliale__c == '79'
				|| account.Filialtyp_OZ_Vorgaengerfiliale__c == '76' )
				&& account.Filialtyp_OZ__c == '84'
				&& !returnEmptyIfNull( account.Filialart__c ).startsWith( 'DPS' )
				&& account.NL_Brief_Lookup__c != null
				&& (
				isChanged( account.Id, 'NL_Brief_Lookup__c' )
						|| isChanged( account.Id, 'RecordTypeId' ) )
				&& account.Eroeffnungsdatum__c > Date.newInstance( 2016, 4, 25 );
	}
	
	private Boolean isConversion84To79Or76 ( Account account ) {
		return ( account.Netzentscheidung_Vorgaengerfiliale__c == 'Formatänderung genehmigt'
				|| account.Aenderungsgrund_Vorgaengerfiliale__c == 'Ersatz für PB FC nach Upgrade' )
				&& account.Filialtyp_OZ_Vorgaengerfiliale__c == '84'
				&& (
				account.Filialtyp_OZ__c == '79'
						|| account.Filialtyp_OZ__c == '76' )
				&& !returnEmptyIfNull( account.Filialart__c ).startsWith( 'DPS' )
				&& account.NL_Brief_Lookup__c != null
				&& isPriorValueNull( account.Id, 'NL_Brief_Lookup__c' )
				&& (
				isChanged( account.Id, 'NL_Brief_Lookup__c' )
						|| isChanged( account.Id, 'RecordTypeId' ) )
				&& account.Eroeffnungsdatum__c > Date.newInstance( 2016, 4, 25 );
	}
	
	private Boolean isConversion84To95 ( Account account ) {
		return ( account.Netzentscheidung_Vorgaengerfiliale__c == 'Formatänderung genehmigt'
				|| account.Aenderungsgrund_Vorgaengerfiliale__c == 'Ersatz für PB FC nach Upgrade' )
				&& account.Filialtyp_OZ__c == '95'
				&& account.Filialtyp_OZ_Vorgaengerfiliale__c == '84'
				&& !returnEmptyIfNull( account.Filialart__c ).startsWith( 'DPS' )
				&& account.NL_Brief_Lookup__c != null
				&& isPriorValueNull( account.Id, 'NL_Brief_Lookup__c' )
				&& (
				isChanged( account.Id, 'NL_Brief_Lookup__c' )
						|| isChanged( account.Id, 'RecordTypeId' ) )
				&& account.Eroeffnungsdatum__c > Date.newInstance( 2016, 4, 25 );
	}
	
	private Boolean isConversion95To84 ( Account account ) {
		return ( account.Netzentscheidung_Vorgaengerfiliale__c == 'Formatänderung genehmigt'
				|| account.Netzentscheidung_Vorgaengerfiliale__c == 'Downgrade OZ 95 in OZ 84' )
				&& account.Filialtyp_OZ__c == '84'
				&& account.Filialtyp_OZ_Vorgaengerfiliale__c == '95'
				&& !returnEmptyIfNull( account.Filialart__c ).startsWith( 'DPS' )
				&& account.NL_Brief_Lookup__c != null
				&& isPriorValueNull( account.Id, 'NL_Brief_Lookup__c' )
				&& (
				isChanged( account.Id, 'NL_Brief_Lookup__c' )
						|| isChanged( account.Id, 'RecordTypeId' ) )
				&& account.Eroeffnungsdatum__c > Date.newInstance( 2016, 4, 25 );
	}
	
	private Boolean isConversion79Or76To95 ( Account account ) {
		return ( account.Netzentscheidung_Vorgaengerfiliale__c == 'Formatänderung genehmigt'
				|| account.Aenderungsgrund_Vorgaengerfiliale__c == 'Ersatz für PB FC nach Upgrade' )
				&& account.Filialtyp_OZ__c == '95'
				&& (
				account.Filialtyp_OZ_Vorgaengerfiliale__c == '79'
						|| account.Filialtyp_OZ_Vorgaengerfiliale__c == '76' )
				&& !returnEmptyIfNull( account.Filialart__c ).startsWith( 'DPS' )
				&& account.NL_Brief_Lookup__c != null
				&& (
				isChanged( account.Id, 'NL_Brief_Lookup__c' )
						|| isChanged( account.Id, 'RecordTypeId' ) )
				&& account.Eroeffnungsdatum__c > Date.newInstance( 2016, 4, 25 );
	}
	
	private Boolean isConversion95To79Or76 ( Account account ) {
		return ( account.Netzentscheidung_Vorgaengerfiliale__c == 'Formatänderung genehmigt'
				|| account.Netzentscheidung_Vorgaengerfiliale__c == 'Downgrade OZ 95 in OZ 79'
				|| account.Aenderungsgrund_Vorgaengerfiliale__c == 'Ersatz für PB FC nach Upgrade' )
				&& account.Filialtyp_OZ_Vorgaengerfiliale__c == '95'
				&& (
				account.Filialtyp_OZ__c == '79'
						|| account.Filialtyp_OZ__c == '76' )
				&& !returnEmptyIfNull( account.Filialart__c ).startsWith( 'DPS' )
				&& account.NL_Brief_Lookup__c != null
				&& (
				isChanged( account.Id, 'NL_Brief_Lookup__c' )
						|| isChanged( account.Id, 'RecordTypeId' ) )
				&& account.Eroeffnungsdatum__c > Date.newInstance( 2016, 4, 25 );
	}
	
	private void addSchliessung ( Account account ) {
		if ( isFilialeExcludingDPS( account ) ) {
			handlerState.terminatedFilalenIdsExcludingDPS.add( account.Id );
			handlerState.terminatedFilialenIds.add( account.Id );
		}
		if ( isDPSInterimFiliale( account ) ) {
			handlerState.terminatedDPSInterimFilialenIds.add( account.Id );
			handlerState.terminatedFilialenIds.add( account.Id );
		}
		if ( isFilialeClassic( account ) ) {
			handlerState.terminatedFilialenClassicIds.add( account.Id );
			handlerState.terminatedFilialenIds.add( account.Id );
		}
		if ( isDPSInterimFilialeSameDate( account ) ) {
			handlerState.terminatedDPSInterimFilialenIdsSameDate.add( account.Id );
			handlerState.terminatedFilialenIds.add( account.Id );
		}
		else if ( isDPSInterimFilialeChangedDate( account ) ) {
			handlerState.terminatedDPSInterimFilialenIdsChangedDate.add( account.Id );
			handlerState.terminatedFilialenIds.add( account.Id );
		}
		else {
			//Sonarqube --> do nothing
		}
		if ( isOZ95OrDPS79( account ) ) {
			handlerState.terminatedOZ95OrDPS79Ids.add( account.Id );
			handlerState.terminatedFilialenIds.add( account.Id );
		}
	}
	
	private Boolean isFilialeExcludingDPS ( Account account ) {
		if ( account.Filialart__c == null || Trigger.isInsert ) {
			return false;
		}
		return !account.Filialart__c.startsWith( 'DPS' )
				&& account.Schliessung_zum__c != null
				&& oldAccountMap.get( account.Id ).Schliessung_zum__c == null
				&& account.Schliessung_zum__c > account.Eroeffnungsdatum__c
				&& account.Aenderungsgrund_FNAE__c != 'Formatänderung'
				&& account.Aenderungsgrund_FNAE__c == oldAccountMap.get( account.Id ).Aenderungsgrund_FNAE__c;
	}
	
	private Boolean isDPSInterimFiliale ( Account account ) {
		if ( account.Filialart__c == null || Trigger.isInsert ) {
			return false;
		}
		return account.Filialart__c.startsWith( 'DPS-Interim' )
				&& account.Schliessung_zum__c != null
				&& oldAccountMap.get( account.Id ).Schliessung_zum__c == null
				&& account.Schliessung_zum__c > account.Eroeffnungsdatum__c
				&& account.Aenderungsgrund_FNAE__c != 'Formatänderung'
				&& account.Aenderungsgrund_FNAE__c == oldAccountMap.get( account.Id ).Aenderungsgrund_FNAE__c;
	}
	
	private Boolean isFilialeClassic ( Account account ) {
		if ( account.Filialart__c == null || Trigger.isInsert ) {
			return false;
		}
		return !account.Filialart__c.startsWith( 'DPS-Interim' )
				&& account.Filialart__c.startsWith( 'DPS' )
				&& account.Schliessung_zum__c != null
				&& oldAccountMap.get( account.Id ).Schliessung_zum__c == null
				&& account.Schliessung_zum__c > account.Eroeffnungsdatum__c
				&& account.Aenderungsgrund_FNAE__c != 'Formatänderung'
				&& account.Aenderungsgrund_FNAE__c == oldAccountMap.get( account.Id ).Aenderungsgrund_FNAE__c;
	}
	
	private Boolean isDPSInterimFilialeSameDate ( Account account ) {
		if ( account.Filialart__c == null || Trigger.isInsert ) {
			return false;
		}
		return account.Filialart__c.contains( 'DPS-Interim' )
				&& account.Schliessung_zum__c != null
				&& oldAccountMap.get( account.Id ).Schliessung_zum__c == null
				&& account.Schliessung_zum__c == account.Eroeffnungsdatum__c
				&& account.Aenderungsgrund_FNAE__c != 'Formatänderung'
				&& account.Aenderungsgrund_FNAE__c == oldAccountMap.get( account.Id ).Aenderungsgrund_FNAE__c;
	}
	
	private Boolean isDPSInterimFilialeChangedDate ( Account account ) {
		if ( account.Filialart__c == null || Trigger.isInsert ) {
			return false;
		}
		return account.Filialart__c.startsWith( 'DPS-Interim' )
				&& account.Schliessung_zum__c != null
				&& oldAccountMap.get( account.Id ).Schliessung_zum__c < account.Schliessung_zum__c;
	}
	
	private Boolean sendEmailZora3600 ( Account account ) {
		return account.aus_Lead_konvertiert__c
				&& account.Betriebsstatus__c != 'vorFACTS-Anlage'
				&& account.Betriebsstatus__c != 'inFACTS-Anlage'
				&& account.NL_Brief_Lookup__c != null
				&& isChanged( account.Id, 'NL_Brief_Lookup__c' );
	}
	
	private void sendEmailsZora3600 ( Set<Id> accountIds ) {
		if ( accountIds.isEmpty() ) {
			return;
		}
		for ( Contract contract : [
				SELECT
						Id,
						AccountId,
						Lead__c
				FROM Contract
				WHERE AccountId IN :accountIds
		] ) {
			addContractRequest(contract, 'E_Mail_an_ZORA_Card_Admin_aus_dem_SDS');
			addContractRequest(contract, 'Abforderung_BGP_aus_SDS_an_3600');
		}
	}
	
	private Boolean isOZ95OrDPS79 ( Account account ) {
		if ( account.Filialart__c == null || Trigger.isInsert ) {
			return false;
		}
		if ( account.Filialtyp_OZ__c == oldAccountMap.get( account.Id ).Filialtyp_OZ__c
				&& account.Filialart__c == oldAccountMap.get( account.Id ).Filialart__c
				&& account.RecordTypeId == oldAccountMap.get( account.Id ).RecordTypeId
				&& account.Schliessung_zum__c == oldAccountMap.get( account.Id ).Schliessung_zum__c ) {
			return false;
		}
		return ( account.Filialtyp_OZ__c == '95'
				|| ( account.Filialtyp_OZ__c == '79' && account.Filialart__c.startsWith( 'DPS' ) ) )
				&& account.Schliessung_zum__c != null;
	}
	
	private Boolean isOZ95 ( Account account ) {
		String priorValueAccountGl = oldAccountMap != null && oldAccountMap.containsKey( account.Id )
				? oldAccountMap.get( account.Id ).NL_Brief_Lookup__c
				: null;
		return account.Filialtyp_OZ__c == '95'
				&& account.Netzentscheidung_Vorgaengerfiliale__c != 'Formatänderung genehmigt'
				&& account.Aenderungsgrund_Vorgaengerfiliale__c != 'Ersatz für PB FC nach Upgrade'
				&& priorValueAccountGl == null
				&& account.NL_Brief_Lookup__c != null
				&& isChanged( account.Id, 'NL_Brief_Lookup__c' )
				&& account.Eroeffnungsdatum__c > Date.newInstance( 2016, 4, 25 );
	}
	
	private Boolean isOZ76 ( Account account ) {
		String priorValueAccountGl = oldAccountMap != null && oldAccountMap.containsKey( account.Id )
				? oldAccountMap.get( account.Id ).NL_Brief_Lookup__c
				: null;
		return account.Filialtyp_OZ__c == '76'
				&& account.Netzentscheidung_Vorgaengerfiliale__c != 'Formatänderung genehmigt'
				&& account.Aenderungsgrund_Vorgaengerfiliale__c != 'Ersatz für PB FC nach Upgrade'
				&& priorValueAccountGl == null
				&& account.NL_Brief_Lookup__c != null
				&& isChanged( account.Id, 'NL_Brief_Lookup__c' )
				&& account.Eroeffnungsdatum__c > Date.newInstance( 2016, 4, 25 );
	}
	
	private Boolean isWerbemedienpflegeFACTS ( Account account ) {
		return (
				(
						isChanged( account.Id, 'ShippingCity' )
								||
								isChanged( account.Id, 'ShippingPostalCode' )
								||
								isChanged( account.Id, 'ShippingCountry' )
								||
								isChanged( account.Id, 'ShippingState' )
								||
								isChanged( account.Id, 'ShippingStreet' )
				)
						&& account.Filialtyp_OZ__c != '78'
						&& account.Filialtyp_OZ__c != '82'
						&& Trigger.isUpdate
						&& account.NL_Brief_Lookup__c != null
						&& oldAccountMap.get( account.Id ).ShippingCity != null )
				|| ( account.NL_Brief_Lookup__c != null
				&& ( isChanged( account.Id, 'RecordTypeId' ) || isChanged( account.Id, 'NL_Brief_Lookup__c' ) )
				&& account.Filialtyp_OZ__c != '78'
				&& account.Filialtyp_OZ__c != '82' );
	}
	
	private void addNeueroeffnung ( Account account ) {
		if ( isWerbemedienpflegeFACTS( account ) ) {
			handlerState.accountIdsWerbemedienFACTS.add( account.Id );
			handlerState.createdFilialenIds.add( account.Id );
		}
		addOZ( account );
	}
	
	private void addOZ ( Account account ) {
		if ( isOZ95( account ) ) {
			handlerState.oz95Ids.add( account.Id );
			handlerState.createdFilialenIds.add( account.Id );
		}
		else if ( isOZ76( account ) ) {
			handlerState.oz76Ids.add( account.Id );
			handlerState.createdFilialenIds.add( account.Id );
		}
		else {
			//Sonarqube --> do nothing
		}
	}
	
	private void setSDSAstID ( Account account ) {
		if ( account.ASt_ID__c != null
				&& account.ASt_ID_SDS__c == null
				&& UserInfo.getUserId() == InterfaceUser.getInstance().getId() ) {
			account.ASt_ID_SDS__c = account.ASt_ID__c;
		}
	}
	
	private void addContractRequest ( Contract contract, String emailSettingDeveloperName ) {
		EmailSettingService.Request request = new EmailSettingService.Request();
		request.recordId = contract.Id;
		request.emailSettingName = emailSettingDeveloperName;
		request.accountId = contract.AccountId;
		request.leadId = contract.Lead__c;
		EmailSettingService.getInstance().requests.add( request );
	}
}