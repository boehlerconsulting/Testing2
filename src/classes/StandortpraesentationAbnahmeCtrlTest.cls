/**
 *@author       Mats Böhler
 *@created      07.10.2020
 *
 *
 *@description  StandortpraesentationAbnahmeCtrlTest
 *
 *
 *@changelog    07.10.2020 Mats Böhler  - Created
 *              
 * 
 */
@IsTest
private class StandortpraesentationAbnahmeCtrlTest {
	
	@IsTest
	static void testLoadData () {
		
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			Lead lead = createPackstationLead();
			
			Test.startTest();
			StandortpraesentationAbnahmeCtrl instance = ( StandortpraesentationAbnahmeCtrl ) JSON.deserialize(
					StandortpraesentationAbnahmeCtrl.loadData( lead.Id ),
					StandortpraesentationAbnahmeCtrl.class );
			Test.stopTest();
			
			System.assertEquals( lead.Id, instance.lead.Id );
		}
	}
	
	@IsTest
	static void testSaveDataFreigabe () {
		
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			Lead lead = createPackstationLead();
			
			Test.startTest();
			StandortpraesentationAbnahmeCtrl.saveData( lead.Id, 'Ja', '' );
			Test.stopTest();
			
			System.assertEquals( Date.today(), [
					SELECT DokumentationDurchRTFreigebenDatum__c
					FROM Lead
					WHERE Id = :lead.Id
			].DokumentationDurchRTFreigebenDatum__c );
		}
	}
	
	@IsTest
	static void testSaveDataNachbesserungNachAbnahme () {
		
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			Lead lead = createPackstationLead();
			
			Test.startTest();
			StandortpraesentationAbnahmeCtrl.saveData( lead.Id, 'Nachbesserung nach Abnahme', 'Test Gründe' );
			Test.stopTest();
			
			System.assertEquals( true, [
					SELECT NachbesserungAngefordert__c
					FROM Lead
					WHERE Id = :lead.Id
			].NachbesserungAngefordert__c );
			System.assertEquals( 1, [
					SELECT
							Id
					FROM Task
					WHERE Aufgabenart__c = 'Standortdokumentation nachbessern'
					AND WhoId = :lead.Id
			].size() );
		}
	}
	
	@IsTest
	static void testSaveDataNachbesserungErforderlich () {
		
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			Lead lead = createPackstationLead();
			
			Test.startTest();
			StandortpraesentationAbnahmeCtrl.saveData( lead.Id, 'Nein, Nachbesserung erforderlich', 'Test Gründe' );
			Test.stopTest();
			
			System.assertEquals( true, [
					SELECT NachbesserungAngefordert__c
					FROM Lead
					WHERE Id = :lead.Id
			].NachbesserungAngefordert__c );
			System.assertEquals( 1, [
					SELECT
							Id
					FROM Task
					WHERE Aufgabenart__c = 'Standortdokumentation nachbessern'
					AND WhoId = :lead.Id
			].size() );
		}
	}
	
	@IsTest
	static void testSaveDataStandortaufnahmeErforderlich () {
		
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			Lead lead = createPackstationLead();
			
			Test.startTest();
			StandortpraesentationAbnahmeCtrl.saveData( lead.Id, 'Nein, neue Standortaufnahme erforderlich', 'Test Gründe' );
			Test.stopTest();
			
			System.assertEquals( true, [
					SELECT NachbesserungAngefordert__c
					FROM Lead
					WHERE Id = :lead.Id
			].NachbesserungAngefordert__c );
			System.assertEquals( 1, [
					SELECT
							Id
					FROM Task
					WHERE Aufgabenart__c = 'Standortdokumentation nachbessern'
					AND WhoId = :lead.Id
			].size() );
		}
	}
	
	private static Lead createPackstationLead () {
		Lead lead = ( Lead ) TestFactory.createSObject(
				new Lead(
						RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName()
								.get( 'Packstation' ).getRecordTypeId(),
						PostalCode = '12345'
				),
				true
		);
		return lead;
	}
}