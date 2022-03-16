/**
 *@author       Mats Böhler
 *@created      17.11.2020
 *
 *
 *@description  StoerungCtrl
 *
 *
 *@changelog    17.11.2020 Mats Böhler  - Created
 *              
 * 
 */
public without sharing class StoerungCtrl {
	
	private static final String STOERUNG_RT = Schema.SObjectType.Meldung__c.getRecordTypeInfosByDeveloperName()
			.get( 'Stoerung' ).getRecordTypeId();
	
	@TestVisible
	private Meldung__c meldung = null;
	private Boolean showMeldung = null;
	
	@AuraEnabled
	public static String init () {
		StoerungCtrl instance = new StoerungCtrl();
		List<Meldung__c> meldungs = [
				SELECT
						Id,
						Beschreibung__c,
						Titel__c
				FROM Meldung__c
				WHERE IstAktuelleMeldung__c = TRUE
				AND RecordTypeId = :STOERUNG_RT
				LIMIT 1
		];
		instance.meldung = ( meldungs.size() == 1 ) ? meldungs.get( 0 ) : null;
		instance.showMeldung = [
				SELECT
						ZeigeAktuelleStoerung__c
				FROM User
				WHERE Id = :UserInfo.getUserId()
				LIMIT 1
		].ZeigeAktuelleStoerung__c;
		return JSON.serialize( instance );
	}
	
	@AuraEnabled
	public static void doNotShowAgain () {
		update new User(
				Id = UserInfo.getUserId(),
				ZeigeAktuelleStoerung__c = false
		);
	}
}