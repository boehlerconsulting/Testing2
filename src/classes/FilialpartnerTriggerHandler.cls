/**
 *@author       Mats Böhler
 *@created      23.11.2021
 *
 *
 *@description  FilialpartnerTriggerHandler
 *
 *
 *@changelog    23.11.2021 Mats Böhler  - Created
 *              
 * 
 */
public without sharing class FilialpartnerTriggerHandler extends AccountBaseHandler {
	
	private List<Account> newRecords = new List<Account>();
	private Map<Id, Account> oldRecordsMap;
	
	public FilialpartnerTriggerHandler ( List<Account> newRecords ) {
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
			setAstNameForFilialpartner( account );
			setVertragsbetreuendeEinheit( account );
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
			trackVertriebsleitungChanged( account );
			setVertragsbetreuendeEinheit( account );
			setAstNameForFilialpartner( account );
			trackIsPureFilialpartnerAndVertragsbetreuendeEinheitIsChanged( account );
		}
	}
	
	private void processAfterUpdate () {
		for ( Account account : newRecords ) {
			processAccount( account );
		}
		setNewVertragsbetreuendeEinheitForVertragspartner( handlerState.accountIdsVertragsbetreuendeEinheitChanged );
	}
	
	private void setAstNameForFilialpartner ( Account account ) {
		if ( String.isBlank( account.ASt_Name__c ) ) {
			account.ASt_Name__c = 'Reiner Filialpartner';
		}
	}
	
	private void trackIsPureFilialpartnerAndVertragsbetreuendeEinheitIsChanged ( Account account ) {
		if ( account.Vertragsbetreuende_Einheit__c != oldAccountMap.get( account.Id ).Vertragsbetreuende_Einheit__c
				&& account.Vertragsbetreuende_Einheit__c != null ) {
			
			String newOwnerId = accountsWithRelatedInformationById.get( account.Id ).Vertragsbetreuende_Einheit__r.Koordinator__c;
			account.OwnerId = newOwnerId == null ? account.OwnerId : newOwnerId;
		}
	}
	
	private void processAccount(Account account){
		if ( isVertragsbetreuendeEinheitChanged( account ) ) {
			handlerState.accountIdsVertragsbetreuendeEinheitChanged.add( account.Id );
		}
	}
}