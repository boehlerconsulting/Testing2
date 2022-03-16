/**
 *@author       Mats Böhler
 *@created      23.11.2021
 *
 *
 *@description  PaketshopTriggerHandler
 *
 *
 *@changelog    23.11.2021 Mats Böhler  - Created
 *              
 * 
 */
public without sharing class PaketshopTriggerHandler extends AccountBaseHandler {
	
	private List<Account> newRecords = new List<Account>();
	private Map<Id, Account> oldRecordsMap;
	
	public PaketshopTriggerHandler ( List<Account> newRecords ) {
		this.newRecords = newRecords;
		this.oldRecordsMap = ( Map<Id, Account> ) Trigger.oldMap;
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
			setVertragsbetreuendeEinheit( account );
			setKundenrelevanzklasse( account );
		}
	}
	
	private void processAfterInsert () {
		for ( Account account : newRecords ) {
			processAccount( account );
		}
		setNewVertragsbetreuendeEinheitForVertragspartner( handlerState.accountIdsVertragsbetreuendeEinheitChanged );
	}
	
	private void processBeforeUpdate () {
		loadAccountsWithRelatedInformation();
		for ( Account account : newRecords ) {
			setVertragsbetreuendeEinheit( account );
			trackTerminationDateChanges( account );
			setKundenrelevanzklasse( account );
			trackVertriebsleitungChanged( account );
		}
	}
	
	private void processAfterUpdate () {
		for ( Account account : newRecords ) {
			processAccount( account );
		}
		setNewVertragsbetreuendeEinheitForVertragspartner( handlerState.accountIdsVertragsbetreuendeEinheitChanged );
	}
	
	private void processAccount ( Account account ) {
		trackIsDebitorAdded( account );
		if ( isAreYouHappyCall( account ) ) {
			handlerState.accountIdsAreYouHappyCall.add( account.Id );
			handlerState.createdFilialenIds.add( account.Id );
		}
		if ( isDhlPaketshopTOOM( account ) ) {
			handlerState.dhlPaketshopTOOMIds.add( account.Id );
			handlerState.createdFilialenIds.add( account.Id );
		}
		else if ( isDhlPaketshopREWE( account ) ) {
			handlerState.dhlPaketshopREWEIds.add( account.Id );
			handlerState.createdFilialenIds.add( account.Id );
		}
		else if ( isDhlPaketshop( account ) ) {
			handlerState.dhlPaketshopIds.add( account.Id );
			handlerState.createdFilialenIds.add( account.Id );
		}
		else {
			// Sonarqube -> do nothing
		}
		if ( isNoPops( account ) ) {
			handlerState.accountIdsLaufenderBetriebNoPops.add( account.Id );
			handlerState.laufendeFilialenIds.add( account.Id );
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
	
	private void trackTerminationDateChanges ( Account account ) {
		if ( returnEmptyIfNull( account.Filialart__c ).startsWith( 'DHL-Paketshop' )
				&& account.Schliessung_zum__c != null
				&& oldAccountMap.get( account.Id ).Schliessung_zum__c == null
				&& account.Schliessung_zum__c > account.Eroeffnungsdatum__c ) {
			
			account.Interne_Bemerkungen_SCF__c = String.format(
					'Schließung zum: {0} gesetzt am: {1}',
					new List<Object> {
							String.valueOf( account.Schliessung_zum__c ),
							String.valueOf( Date.today() )
					} );
		}
	}
	
	private Boolean isAreYouHappyCall ( Account account ) {
		return returnEmptyIfNull( account.Filialart__c ).contains( 'DHL-Paketshop' )
				&& account.Kette__c != 'temporärer Paketshop'
				&& account.Kette__c != 'Virtueller Paketshop'
				&& account.Filialtyp_OZ__c == '82'
				&& account.NL_Brief_Lookup__c != null
				&& (
				isChanged( account.Id, 'NL_Brief_Lookup__c' )
						|| isChanged( account.Id, 'RecordTypeId' ) );
	}
	
	private Boolean isDhlPaketshop ( Account account ) {
		return returnEmptyIfNull( account.Filialart__c ).contains( 'DHL-Paketshop' )
				&& account.NL_Brief_Lookup__c != null
				&& (
				isChanged( account.Id, 'NL_Brief_Lookup__c' )
						|| isChanged( account.Id, 'RecordTypeId' ) )
				&& !returnEmptyIfNull( account.ASt_Name__c ).contains( 'virtuell' )
				&& !returnEmptyIfNull( account.ASt_Name__c ).contains( 'temporär' )
				&& !returnEmptyIfNull( account.Kette__c ).contains( 'REWE' )
				&& account.Kette__c != 'SP AWG'
				&& account.Kette__c != 'SP Combi-Verbrauchermarkt'
				&& account.Kette__c != 'SP M Combi-Verbrauchermarkt'
				&& account.Kette__c != 'SP Expert'
				&& account.Kette__c != 'SP Famila'
				&& account.Kette__c != 'SP M Famila'
				&& account.Kette__c != 'SP M Feneberg'
				&& account.Kette__c != 'SP Fritz Feldmann (Markant)'
				&& account.Kette__c != 'SP Geco'
				&& account.Kette__c != 'SP M Geco'
				&& account.Kette__c != 'SP KiK'
				&& account.Kette__c != 'SP McPaper'
				&& account.Kette__c != 'SP M McPaper'
				&& account.Kette__c != 'SP Minit'
				&& account.Kette__c != 'SP M Minit'
				&& account.Kette__c != 'SP Pfennigpfeiffer'
				&& account.Kette__c != 'SP Pitstop'
				&& account.Kette__c != 'SP Staples'
				&& account.Kette__c != 'SP Thalia'
				&& account.Kette__c != 'SP tegut'
				&& account.Kette__c != 'SP M tegut'
				&& account.Kette__c != 'SP Toom Baumarkt'
				&& account.Kette__c != 'SP Unternehmensgruppe Dr. Eckert'
				&& account.Kette__c != 'SP M Unternehmensgruppe Dr. Eckert'
				&& account.Kette__c != 'SP Valora'
				&& account.Kette__c != 'SP M Valora'
				&& account.Kette__c != 'SP Wolsdorff';
	}
	
	private Boolean isDhlPaketshopREWE ( Account account ) {
		return returnEmptyIfNull( account.Filialart__c ).contains( 'DHL-Paketshop' )
				&& account.NL_Brief_Lookup__c != null
				&& (
				isChanged( account.Id, 'NL_Brief_Lookup__c' )
						|| isChanged( account.Id, 'RecordTypeId' ) )
				&& returnEmptyIfNull( account.Kette__c ).contains( 'REWE' );
	}
	
	private Boolean isDhlPaketshopTOOM ( Account account ) {
		return returnEmptyIfNull( account.Filialart__c ).contains( 'DHL-Paketshop' )
				&& account.NL_Brief_Lookup__c != null
				&& (
				isChanged( account.Id, 'NL_Brief_Lookup__c' )
						|| isChanged( account.Id, 'RecordTypeId' ) )
				&& account.Kette__c == 'SP Toom Baumarkt';
	}
	
	private Boolean isNoPops ( Account account ) {
		String priorValueAccountBetriebsstatus = oldRecordsMap != null
				&& oldRecordsMap.containsKey( account.Id )
				? oldRecordsMap.get( account.Id ).Betriebsstatus__c
				: null;
		return account.Filialart__c == 'DHL-Paketshop'
				&& !returnEmptyIfNull( account.ASt_Name__c ).contains( '(virtueller PS)' )
				&& account.Betriebsstatus__c == 'geöffnet'
				&& priorValueAccountBetriebsstatus == 'vorEröffnung'
				&& isChanged( account.Id, 'Betriebsstatus__c' )
				&& account.NameVertragsbetreuendeEinheit__c != '5700 Strat. Partnermanagement'
				&& account.PoPS_Kundennummer__c == null
				&& account.PoPS_Kundennummer_Sammelbesteller__c == null;
	}
}