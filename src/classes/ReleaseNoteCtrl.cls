/**
 *@author       Mats Böhler
 *@created      04.11.2020
 *
 *
 *@description  ReleaseNoteCtrl
 *
 *
 *@changelog    04.11.2020 Mats Böhler  - Created
 *              
 * 
 */
public without sharing class ReleaseNoteCtrl {
	
	private static final String RELEASE_NOTE_RT = Schema.SObjectType.Meldung__c.getRecordTypeInfosByDeveloperName()
			.get( 'ReleaseNote' ).getRecordTypeId();
	
	@TestVisible
	private Meldung__c meldung = null;
	private Boolean showMeldung = null;
	
	@AuraEnabled
	public static String init () {
		ReleaseNoteCtrl instance = new ReleaseNoteCtrl();
		List<Meldung__c> meldungs = [
				SELECT
						Id,
						Beschreibung__c,
						Titel__c
				FROM Meldung__c
				WHERE IstAktuelleMeldung__c = TRUE
				AND RecordTypeId = :RELEASE_NOTE_RT
				LIMIT 1
		];
		instance.meldung = ( meldungs.size() == 1 ) ? meldungs.get( 0 ) : null;

		instance.showMeldung = [
				SELECT
						ZeigeAktuellesRelease__c
				FROM User
				WHERE Id = :UserInfo.getUserId()
				LIMIT 1
		].ZeigeAktuellesRelease__c;
		return JSON.serialize( instance );
	}
	
	@AuraEnabled
	public static void doNotShowAgain () {
		update new User(
				Id = UserInfo.getUserId(),
				ZeigeAktuellesRelease__c = false
		);
	}
}