/**
 *@author       Mats Böhler
 *@created      17.11.2020
 *
 *
 *@description  ReleaseNoteCtrlTest
 *
 *
 *@changelog    17.11.2020 Mats Böhler  - Created
 *              
 * 
 */
@IsTest
private class ReleaseNoteCtrlTest {
	
	@IsTest
	static void testInit () {
		
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			Meldung__c release = createRelease();
			
			Test.startTest();
			ReleaseNoteCtrl instance = ( ReleaseNoteCtrl ) JSON.deserialize( ReleaseNoteCtrl.init(), ReleaseNoteCtrl.class );
			Test.stopTest();
			
			System.assertEquals( release.Id, instance.meldung.Id );
		}
	}
	
	@IsTest
	static void testDoNotShowAgain () {
		
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			Test.startTest();
			ReleaseNoteCtrl.doNotShowAgain();
			Test.stopTest();
			
			System.assertEquals( false, [
					SELECT
							Id,
							ZeigeAktuellesRelease__c
					FROM User
					WHERE Id = :UserInfo.getUserId()
					LIMIT 1
			].ZeigeAktuellesRelease__c );
		}
	}
	
	private static Meldung__c createRelease () {
		Meldung__c release = new Meldung__c(
				RecordTypeId = Schema.SObjectType.Meldung__c.getRecordTypeInfosByDeveloperName()
						.get( 'ReleaseNote' ).getRecordTypeId(),
				Titel__c = 'Titel',
				Beschreibung__c = 'Beschreibung',
				IstAktuelleMeldung__c = true
		);
		insert release;
		return release;
	}
}