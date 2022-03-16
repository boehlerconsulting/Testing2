/**
 *@author       Mats Böhler
 *@created      30.03.2020
 *
 *
 *@description  PriorizationHelpAccountsTest
 *
 *
 *@changelog    30.03.2020 Mats Böhler  - Created
 *              
 * 
 */
@IsTest
private class PriorizationHelpAccountsTest {
	@IsTest
	static void testLoad () {
		
		setupTestData( 'ohne Akquise' );
		
		TestFactoryDefaults.FilterCriteria filterCriteria = new TestFactoryDefaults.FilterCriteria(
				false,
				1,
				[ SELECT Id FROM Account LIMIT 1 ].Id,
				'Account',
				'ohne Akquise',
				'KennzifferPrioritaet__c',
				'desc',
				'offen',
				''
		);
		
		Test.startTest();
		PriorizationHelpAccounts instance =
				( PriorizationHelpAccounts )
						JSON.deserialize(
								HW_Priorisierungshilfe_LC.loadData(
										JSON.serialize( filterCriteria )
								),
								PriorizationHelpAccounts.class
						) ;
		Test.stopTest();
		
		System.assertNotEquals( null, instance.columns );
		System.assertNotEquals( null, instance.filialen );
	
	}
	
	private static Task setupTestData ( String version ) {
		
		Account account = new Account(
				Name = 'Test',
				RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
						.get( 'Filiale_Dummy' ).getRecordTypeId()
		);
		insert account;
		
		PriohilfeAufgabenverwaltung__c verwaltung = ( PriohilfeAufgabenverwaltung__c ) TestFactory.createSObject(
				new PriohilfeAufgabenverwaltung__c(
						Version__c = version
				),
				'TestFactoryDefaults.PriohilfeAufgabenverwaltungDefaults',
				true
		);
		
		Task task = new Task(
				Verfallsdatum__c = Date.today().addDays( 28 ),
				Status = 'Nicht begonnen',
				Aufgabenart__c = 'Partnerkontaktpflege',
				RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
						.get( 'Aufgaben_ZG_Vertrieb' ).getRecordTypeId(),
				Erledigung_bis_zum__c = Date.today().addDays( 14 ),
				WhatId = account.Id,
				PriohilfeAufgabenverwaltung__c = verwaltung.Id
		);
		insert task;
		
		Account rankingAccount = new Account(
				Name = 'Test',
				RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
						.get( 'Filiale_Dummy' ).getRecordTypeId()
		);
		insert rankingAccount;
		
		Task rankingTask = new Task(
				Verfallsdatum__c = Date.today().addDays( 28 ),
				Status = 'Nicht begonnen',
				Aufgabenart__c = 'Partnerkontaktpflege',
				RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
						.get( 'Aufgaben_ZG_Vertrieb' ).getRecordTypeId(),
				Erledigung_bis_zum__c = Date.today().addDays( 14 ),
				WhatId = rankingAccount.Id,
				PriohilfeAufgabenverwaltung__c = verwaltung.Id
		);
		insert rankingTask;
		return rankingTask;
	}
}