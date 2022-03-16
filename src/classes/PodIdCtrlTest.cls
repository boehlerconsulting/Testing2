/**
 *@author       Mats Böhler
 *@created      04.08.2021
 *
 *
 *@description  PodIdCtrlTest
 *
 *
 *@changelog    04.08.2021 Mats Böhler  - Created
 *              
 * 
 */
@IsTest
private class PodIdCtrlTest {
	
	/**
	 * @process [MYPM-1652] Autom. Erstellung PODIDs
	 */
	@IsTest
	static void testPODID () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			Anlagennummer__c anlagennummer = new Anlagennummer__c(
					Name = '00000001',
					Status__c = 'verfügbar'
			);
			insert anlagennummer;
			Lead lead = ( Lead ) TestFactory.createSObject(
					new Lead(
							RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName()
									.get( 'Packstation' ).getRecordTypeId(),
							PostalCode = '11111',
							Akquisemodus__c = 'Standortaufnahme vor Ort; Danach Übergabe an rVU',
							Anlagennummer__c = anlagennummer.Id,
							City = 'Berlin'
					),
					true
			);
			
			Test.startTest();
			PodIdCtrl.init( lead.Id );
			Test.stopTest();
			
			System.assertEquals( '11111101', [
					SELECT
							Id,
							PODID_Lookup__r.Wert__c
					FROM Lead
					WHERE Id = :lead.Id
					LIMIT 1
			].PODID_Lookup__r.Wert__c );
		}
	}
	
	/**
	 * @process [MYPM-1652] Autom. Erstellung PODIDs
	 */
	@IsTest
	static void testPODIDNoneAvailable () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			Anlagennummer__c anlagennummer = new Anlagennummer__c(
					Name = '00000001',
					Status__c = 'verfügbar'
			);
			insert anlagennummer;
			Lead lead = ( Lead ) TestFactory.createSObject(
					new Lead(
							RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName()
									.get( 'Packstation' ).getRecordTypeId(),
							PostalCode = '11111',
							Akquisemodus__c = 'Standortaufnahme vor Ort; Danach Übergabe an rVU',
							Anlagennummer__c = anlagennummer.Id
					),
					true
			);
			
			Test.startTest();
			try {
				PodIdCtrl.init( lead.Id );
			}
			catch ( Exception e ) {
				System.assert( e.getMessage().contains( 'Script-thrown exception' ) );
			}
			Test.stopTest();
		}
	}
	
	/**
	 * @process [MYPM-1889] PODID löschen
	 */
	@IsTest
	static void testDeleteId () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			Anlagennummer__c anlagennummer = new Anlagennummer__c(
					Name = '00000001',
					Status__c = 'verfügbar'
			);
			insert anlagennummer;
			Lead lead = ( Lead ) TestFactory.createSObject(
					new Lead(
							RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName()
									.get( 'Packstation' ).getRecordTypeId(),
							PostalCode = '11111',
							Akquisemodus__c = 'Standortaufnahme vor Ort; Danach Übergabe an rVU',
							Anlagennummer__c = anlagennummer.Id,
							City = 'Berlin'
					),
					true
			);
			
			Test.startTest();
			PodIdCtrl.init( lead.Id );
			LeadTriggerHandler.processedIds = new Set<Id>();
			PodIdCtrl.deleteId( [ SELECT Id FROM PODID__c LIMIT 1 ].Id );
			Test.stopTest();
			
			System.assertEquals( 1, [ SELECT Id FROM PODID__c WHERE Status__c = 'Gelöscht'].size() );
		}
	}
}