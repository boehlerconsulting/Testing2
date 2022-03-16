/**
 *@author       Mats Böhler
 *@created      17.11.2020
 *
 *
 *@description  MeldungTriggerHandlerTest
 *
 *
 *@changelog    17.11.2020 Mats Böhler  - Created
 *              
 * 
 */
@IsTest
private class MeldungTriggerHandlerTest {
	
	private static final String RELEASE_NOTE_RT = Schema.SObjectType.Meldung__c.getRecordTypeInfosByDeveloperName()
			.get( 'ReleaseNote' ).getRecordTypeId();
	private static final String STOERUNG_RT = Schema.SObjectType.Meldung__c.getRecordTypeInfosByDeveloperName()
			.get( 'Stoerung' ).getRecordTypeId();
	
	@IsTest
	static void testResetUsersReleaseNotes () {
		
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			Meldung__c release = createMeldung( RELEASE_NOTE_RT );
			
			Test.startTest();
			release.BenutzerZuruecksetzen__c = true;
			release.BenutzerSofortBenachrichtigen__c = true;
			update release;
			Test.stopTest();
			
			System.assertEquals( true, [
					SELECT
							Id,
							ZeigeAktuellesRelease__c
					FROM User
					WHERE Id = :UserInfo.getUserId()
					LIMIT 1
			].ZeigeAktuellesRelease__c );
		}
	}
	
	@IsTest
	static void testResetUsersStoerungen () {
		
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			Meldung__c release = createMeldung( STOERUNG_RT );
			
			Test.startTest();
			release.BenutzerZuruecksetzen__c = true;
			release.BenutzerSofortBenachrichtigen__c = true;
			update release;
			Test.stopTest();
			
			System.assertEquals( true, [
					SELECT
							Id,
							ZeigeAktuelleStoerung__c
					FROM User
					WHERE Id = :UserInfo.getUserId()
					LIMIT 1
			].ZeigeAktuelleStoerung__c );
		}
	}
	
	private static Meldung__c createMeldung ( Id recordTypeId ) {
		Meldung__c release = new Meldung__c(
				RecordTypeId = recordTypeId,
				Titel__c = 'Titel',
				Beschreibung__c = 'Beschreibung',
				IstAktuelleMeldung__c = true
		);
		insert release;
		return release;
	}
}