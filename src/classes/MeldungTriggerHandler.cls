/**
 *@author       Mats Böhler
 *@created      09.11.2020
 *
 *
 *@description  MeldungTriggerHandler
 *
 *
 *@changelog    09.11.2020 Mats Böhler  - Created
 *              
 * 
 */
public without sharing class MeldungTriggerHandler extends TriggerHandler {
	
	private static final String RELEASE_NOTE_RT = Schema.SObjectType.Meldung__c.getRecordTypeInfosByDeveloperName()
			.get( 'ReleaseNote' ).getRecordTypeId();
	private static final String STOERUNG_RT = Schema.SObjectType.Meldung__c.getRecordTypeInfosByDeveloperName()
			.get( 'Stoerung' ).getRecordTypeId();
	
	private Boolean resetReleaseNotes = false;
	private Boolean resetUsersReleaseNotes = false;
	private Boolean resetStoerungen = false;
	private Boolean resetUsersStoerungen = false;
	private Boolean notifyUsersImmediatelyAboutRelease = false;
	private Boolean notifyUsersImmediatelyAboutStoerung = false;
	
	private List<Meldung__c> newMeldungs;
	private Map<Id, Meldung__c> newMeldungsMap;
	private Map<Id, Meldung__c> oldMeldungsMap;
	
	public MeldungTriggerHandler () {
		this.newMeldungs = ( List<Meldung__c> ) Trigger.new;
		this.newMeldungsMap = ( Map<Id, Meldung__c> ) Trigger.newMap;
		this.oldMeldungsMap = ( Map<Id, Meldung__c> ) Trigger.oldMap;
	}
	
	protected override void beforeInsert () {
		processBefore();
	}
	
	protected override void beforeUpdate () {
		processBefore();
	}
	
	private void processBefore () {
		resetReleaseNotes = false;
		resetUsersReleaseNotes = false;
		resetStoerungen = false;
		resetUsersStoerungen = false;
		notifyUsersImmediatelyAboutRelease = false;
		notifyUsersImmediatelyAboutStoerung = false;
		
		for ( Meldung__c meldung : newMeldungs ) {
			setBooleanFlags( meldung );
		}
		if ( resetUsersReleaseNotes ) {
			resetUsersReleaseNotes();
		}
		if ( resetUsersStoerungen ) {
			resetUsersStoerungen();
		}
		if ( resetReleaseNotes ) {
			resetReleaseNotes();
		}
		if ( resetStoerungen ) {
			resetStoerungen();
		}
		if ( notifyUsersImmediatelyAboutRelease ) {
			EventBus.publish( new List<ReleaseNoteEvent__e> {
					new ReleaseNoteEvent__e()
			} );
		}
		if ( notifyUsersImmediatelyAboutStoerung ) {
			EventBus.publish( new List<StoerungEvent__e> {
					new StoerungEvent__e()
			} );
		}
	}
	
	private void setBooleanFlags ( Meldung__c meldung ) {
		if ( meldung.BenutzerZuruecksetzen__c
				&& meldung.RecordTypeId == RELEASE_NOTE_RT ) {
			resetUsersReleaseNotes = true;
			meldung.BenutzerZuruecksetzen__c = false;
		}
		if ( meldung.BenutzerZuruecksetzen__c
				&& meldung.RecordTypeId == STOERUNG_RT ) {
			resetUsersStoerungen = true;
			meldung.BenutzerZuruecksetzen__c = false;
		}
		if ( meldung.IstAktuelleMeldung__c
				&& meldung.RecordTypeId == RELEASE_NOTE_RT ) {
			resetReleaseNotes = true;
		}
		if ( meldung.IstAktuelleMeldung__c
				&& meldung.RecordTypeId == STOERUNG_RT ) {
			resetStoerungen = true;
		}
		if ( meldung.BenutzerSofortBenachrichtigen__c
				&& meldung.RecordTypeId == RELEASE_NOTE_RT ) {
			notifyUsersImmediatelyAboutRelease = true;
			meldung.BenutzerSofortBenachrichtigen__c = false;
		}
		if ( meldung.BenutzerSofortBenachrichtigen__c
				&& meldung.RecordTypeId == STOERUNG_RT ) {
			notifyUsersImmediatelyAboutStoerung = true;
			meldung.BenutzerSofortBenachrichtigen__c = false;
		}
	}
	
	@Future
	private static void resetUsersReleaseNotes () {
		List<User> users = new List<User>();
		for ( User user : [
				SELECT
						Id
				FROM User
				WHERE IsActive = TRUE
				AND ZeigeAktuellesRelease__c = FALSE
		] ) {
			
			user.ZeigeAktuellesRelease__c = true;
			users.add( user );
		}
		Database.update( users, false );
	}
	
	private void resetReleaseNotes () {
		List<Meldung__c> meldungs = new List<Meldung__c>();
		for ( Meldung__c meldung : [
				SELECT
						Id
				FROM Meldung__c
				WHERE IstAktuelleMeldung__c = TRUE
				AND Id NOT IN :newMeldungs
				AND RecordTypeId = :RELEASE_NOTE_RT
		] ) {
			meldung.IstAktuelleMeldung__c = false;
			meldungs.add( meldung );
		}
		TriggerHandler.bypass( 'MeldungTriggerHandler' );
		update meldungs;
		TriggerHandler.clearBypass( 'MeldungTriggerHandler' );
	}
	
	@Future
	private static void resetUsersStoerungen () {
		List<User> users = new List<User>();
		for ( User user : [
				SELECT
						Id
				FROM User
				WHERE IsActive = TRUE
				AND ZeigeAktuelleStoerung__c = FALSE
		] ) {
			
			user.ZeigeAktuelleStoerung__c = true;
			users.add( user );
		}
		Database.update( users, false );
	}
	
	private void resetStoerungen () {
		List<Meldung__c> meldungs = new List<Meldung__c>();
		for ( Meldung__c meldung : [
				SELECT
						Id
				FROM Meldung__c
				WHERE IstAktuelleMeldung__c = TRUE
				AND Id NOT IN :newMeldungs
				AND RecordTypeId = :STOERUNG_RT
		] ) {
			meldung.IstAktuelleMeldung__c = false;
			meldungs.add( meldung );
		}
		TriggerHandler.bypass( 'MeldungTriggerHandler' );
		update meldungs;
		TriggerHandler.clearBypass( 'MeldungTriggerHandler' );
	}
}