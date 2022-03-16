/**
 *@author       Mats Böhler
 *@created      17.11.2020
 *
 *
 *@description  StoerungCtrlTest
 *
 *
 *@changelog    17.11.2020 Mats Böhler  - Created
 *              
 * 
 */
@IsTest
private class StoerungCtrlTest {
	
	@IsTest
	static void testInit () {
		
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			Meldung__c release = createStoerung();
			
			Test.startTest();
			StoerungCtrl instance = ( StoerungCtrl ) JSON.deserialize( StoerungCtrl.init(), StoerungCtrl.class );
			Test.stopTest();
			
			System.assertEquals( release.Id, instance.meldung.Id );
		}
	}
	
	@IsTest
	static void testDoNotShowAgain () {
		
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			Test.startTest();
			StoerungCtrl.doNotShowAgain();
			Test.stopTest();
			
			System.assertEquals( false, [
					SELECT
							Id,
							ZeigeAktuelleStoerung__c
					FROM User
					WHERE Id = :UserInfo.getUserId()
					LIMIT 1
			].ZeigeAktuelleStoerung__c );
		}
	}
	
	private static Meldung__c createStoerung () {
		Meldung__c release = new Meldung__c(
				RecordTypeId = Schema.SObjectType.Meldung__c.getRecordTypeInfosByDeveloperName()
						.get( 'Stoerung' ).getRecordTypeId(),
				Titel__c = 'Titel',
				Beschreibung__c = 'Beschreibung',
				IstAktuelleMeldung__c = true
		);
		insert release;
		return release;
	}
}