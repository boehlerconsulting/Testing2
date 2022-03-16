/**
 *@author       Mats Böhler
 *@created      13.08.2020
 *
 *
 *@description  FilialnetzaenderungTriggerHandlerTest
 *
 *
 *@changelog    13.08.2020 Mats Böhler  - Created
 *              
 * 
 */
@IsTest
private class FilialnetzaenderungTriggerHandlerTest {
	
	@IsTest
	static void testLeadDeactivation () {
		
		System.runAs( TestUser.create( TestUser.UserType.VL2001 ) ) {
			TriggerHandler.bypass( 'FilialnetzaenderungTriggerHandler' );
			Account account = ( Account ) TestFactory.createSObject(
					new Account(),
					true
			);
			Filialnetzaenderung__c filialnetzaenderung = new Filialnetzaenderung__c(
					Filiale_Filialpartner__c = account.Id,
					Schliessung_avisiert_fuer__c = Date.today(),
					RecordTypeId = Schema.SObjectType.Filialnetzaenderung__c.getRecordTypeInfosByDeveloperName()
							.get( 'Packstation' ).getRecordTypeId()
			);
			insert filialnetzaenderung;
			Lead lead = ( Lead ) TestFactory.createSObject(
					new Lead(
							PostalCode = '12345',
							Aktivitaetsstatus__c = 'aktiv',
							Filialnetzaenderung__c = filialnetzaenderung.Id
					),
					true
			);
			
			TriggerHandler.clearAllBypasses();
			Test.startTest();
			filialnetzaenderung = [
					SELECT
							Id,
							FaecherAufbauzielSchwellenwert__c
					FROM Filialnetzaenderung__c
					WHERE Id = :filialnetzaenderung.Id
					LIMIT 1
			];
			filialnetzaenderung.Faecher_Gesamtziel__c = filialnetzaenderung.FaecherAufbauzielSchwellenwert__c + 50;
			filialnetzaenderung.Faecher_IST__c = filialnetzaenderung.Faecher_Gesamtziel__c - filialnetzaenderung.FaecherAufbauzielSchwellenwert__c + 1;
			update filialnetzaenderung;
			Test.stopTest();
			
			System.assertEquals( 'inaktiv durch Zentrale', [
					SELECT
							Id,
							Aktivitaetsstatus__c
					FROM Lead
					WHERE Id = :lead.Id
					LIMIT 1
			].Aktivitaetsstatus__c );
		}
	}
	
	@IsTest
	static void testAufbauzielPackstationNew () {
		
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			Account account = ( Account ) TestFactory.createSObject(
					new Account(),
					true
			);
			
			Test.startTest();
			Filialnetzaenderung__c filialnetzaenderung = new Filialnetzaenderung__c(
					Filiale_Filialpartner__c = account.Id,
					Schliessung_avisiert_fuer__c = Date.today(),
					RecordTypeId = Schema.SObjectType.Filialnetzaenderung__c.getRecordTypeInfosByDeveloperName()
							.get( 'Packstation' ).getRecordTypeId(),
					Faecher_Gesamtziel__c = 200,
					Faecher_IST__c = 40,
					Zieltermin__c = Date.today()
			);
			insert filialnetzaenderung;
			Test.stopTest();
			
			filialnetzaenderung = [
					SELECT
							Id,
							Faecher_Aufbauziel__c,
							AufbauzielPackstation__c,
							AufbauzielPackstationAlt__c
					FROM Filialnetzaenderung__c
					WHERE Id = :filialnetzaenderung.Id
					LIMIT 1
			];
			System.assertEquals( 160, filialnetzaenderung.Faecher_Aufbauziel__c );
			System.assertEquals( 2, filialnetzaenderung.AufbauzielPackstation__c );
			System.assertEquals( 2, filialnetzaenderung.AufbauzielPackstationAlt__c );
			
			System.assertEquals( 2, [
					SELECT
							Id,
							Filialnetzaenderung__c
					FROM Task
					WHERE Filialnetzaenderung__c = :filialnetzaenderung.Id
					AND IsClosed = FALSE
					AND Aufgabenart__c = 'Akquiseauftrag Packstation zu FNÄ'
			].size() );
		}
	}
	
	@IsTest
	static void testAufbauzielPackstationExistingAkquise () {
		
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			Account account = ( Account ) TestFactory.createSObject(
					new Account(),
					true
			);
			Filialnetzaenderung__c filialnetzaenderung = new Filialnetzaenderung__c(
					Filiale_Filialpartner__c = account.Id,
					Schliessung_avisiert_fuer__c = Date.today(),
					RecordTypeId = Schema.SObjectType.Filialnetzaenderung__c.getRecordTypeInfosByDeveloperName()
							.get( 'Packstation' ).getRecordTypeId(),
					Zieltermin__c = Date.today()
			);
			insert filialnetzaenderung;
			insert new Task(
					Aufgabenart__c = 'Akquiseauftrag Packstation zu FNÄ',
					Auftraggeber__c = 'Vertriebskoordinator',
					Auftragnehmer__c = 'Vertriebskoordinator VL',
					ActivityDate = Date.today(),
					Erledigung_bis_zum__c = filialnetzaenderung.Zieltermin__c != null
							? filialnetzaenderung.Zieltermin__c.addDays( -61 )
							: null,
					Status = 'Nicht begonnen',
					Priority = 'Mittel',
					Filialnetzaenderung__c = filialnetzaenderung.Id,
					RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
							.get( 'AkquiseauftragPackstation' ).getRecordTypeId(),
					WhatId = filialnetzaenderung.VL_ID__c
			);
			
			Test.startTest();
			filialnetzaenderung.Faecher_Gesamtziel__c = 200;
			filialnetzaenderung.Faecher_IST__c = 40;
			update filialnetzaenderung;
			Test.stopTest();
			
			filialnetzaenderung = [
					SELECT
							Id,
							Faecher_Aufbauziel__c,
							AufbauzielPackstation__c,
							AufbauzielPackstationAlt__c
					FROM Filialnetzaenderung__c
					WHERE Id = :filialnetzaenderung.Id
					LIMIT 1
			];
			System.assertEquals( 160, filialnetzaenderung.Faecher_Aufbauziel__c );
			System.assertEquals( 2, filialnetzaenderung.AufbauzielPackstation__c );
			System.assertEquals( 0, filialnetzaenderung.AufbauzielPackstationAlt__c );
			
			System.assertEquals( 2, [
					SELECT
							Id,
							Filialnetzaenderung__c
					FROM Task
					WHERE Filialnetzaenderung__c = :filialnetzaenderung.Id
					AND IsClosed = FALSE
					AND Aufgabenart__c = 'Akquiseauftrag Packstation zu FNÄ'
			].size() );
		}
	}
	
	@IsTest
	static void testAufbauzielPackstationChangedSendNotification () {
		
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			Account account = ( Account ) TestFactory.createSObject(
					new Account(),
					true
			);
			Filialnetzaenderung__c filialnetzaenderung = new Filialnetzaenderung__c(
					Filiale_Filialpartner__c = account.Id,
					Schliessung_avisiert_fuer__c = Date.today(),
					RecordTypeId = Schema.SObjectType.Filialnetzaenderung__c.getRecordTypeInfosByDeveloperName()
							.get( 'Packstation' ).getRecordTypeId()
			);
			insert filialnetzaenderung;
			insert new Task(
					Aufgabenart__c = 'Akquiseauftrag Packstation zu FNÄ',
					Auftraggeber__c = 'Vertriebskoordinator',
					Auftragnehmer__c = 'Vertriebskoordinator VL',
					ActivityDate = Date.today(),
					Erledigung_bis_zum__c = filialnetzaenderung.Zieltermin__c != null
							? filialnetzaenderung.Zieltermin__c.addDays( -61 )
							: null,
					Status = 'Nicht begonnen',
					Priority = 'Mittel',
					Filialnetzaenderung__c = filialnetzaenderung.Id,
					RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
							.get( 'AkquiseauftragPackstation' ).getRecordTypeId(),
					WhatId = filialnetzaenderung.VL_ID__c
			);
			insert new Task(
					Aufgabenart__c = 'Akquiseauftrag Packstation zu FNÄ',
					Auftraggeber__c = 'Vertriebskoordinator',
					Auftragnehmer__c = 'Vertriebskoordinator VL',
					ActivityDate = Date.today(),
					Erledigung_bis_zum__c = filialnetzaenderung.Zieltermin__c != null
							? filialnetzaenderung.Zieltermin__c.addDays( -61 )
							: null,
					Status = 'Nicht begonnen',
					Priority = 'Mittel',
					Filialnetzaenderung__c = filialnetzaenderung.Id,
					RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
							.get( 'AkquiseauftragPackstation' ).getRecordTypeId(),
					WhatId = filialnetzaenderung.VL_ID__c
			);
			
			Test.startTest();
			filialnetzaenderung.Faecher_Gesamtziel__c = 200;
			filialnetzaenderung.Faecher_IST__c = 120;
			update filialnetzaenderung;
			Test.stopTest();
			
			filialnetzaenderung = [
					SELECT
							Id,
							Faecher_Aufbauziel__c,
							AufbauzielPackstation__c,
							AufbauzielPackstationAlt__c
					FROM Filialnetzaenderung__c
					WHERE Id = :filialnetzaenderung.Id
					LIMIT 1
			];
			System.assertEquals( 80, filialnetzaenderung.Faecher_Aufbauziel__c );
			System.assertEquals( 1, filialnetzaenderung.AufbauzielPackstation__c );
			System.assertEquals( 0, filialnetzaenderung.AufbauzielPackstationAlt__c );
		}
	}
	
	@IsTest
	static void testZielTerminChanged () {
		
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			Account account = ( Account ) TestFactory.createSObject(
					new Account(),
					true
			);
			Filialnetzaenderung__c filialnetzaenderung = new Filialnetzaenderung__c(
					Filiale_Filialpartner__c = account.Id,
					Schliessung_avisiert_fuer__c = Date.today(),
					RecordTypeId = Schema.SObjectType.Filialnetzaenderung__c.getRecordTypeInfosByDeveloperName()
							.get( 'Packstation' ).getRecordTypeId()
			);
			insert filialnetzaenderung;
			Task task = new Task(
					Aufgabenart__c = 'Akquiseauftrag Packstation zu FNÄ',
					Auftraggeber__c = 'Vertriebskoordinator',
					Auftragnehmer__c = 'Vertriebskoordinator VL',
					ActivityDate = Date.today(),
					Erledigung_bis_zum__c = filialnetzaenderung.Zieltermin__c != null
							? filialnetzaenderung.Zieltermin__c.addDays( -61 )
							: null,
					Status = 'Nicht begonnen',
					Priority = 'Mittel',
					Filialnetzaenderung__c = filialnetzaenderung.Id,
					RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
							.get( 'AkquiseauftragPackstation' ).getRecordTypeId(),
					WhatId = filialnetzaenderung.VL_ID__c
			);
			insert task;
			
			Test.startTest();
			filialnetzaenderung.Zieltermin__c = Date.today();
			update filialnetzaenderung;
			Test.stopTest();
			
			System.assertEquals( Date.today().addDays( 7 ), [
					SELECT
							Id,
							Erledigung_bis_zum__c
					FROM Task
					WHERE Id = :task.Id
					LIMIT 1
			].Erledigung_bis_zum__c );
		}
	}
	
	@IsTest
	static void testZielTerminPostponed () {
		
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			Account account = ( Account ) TestFactory.createSObject(
					new Account(),
					true
			);
			TriggerHandler.bypass('FilialnetzaenderungTriggerHandler');
			Filialnetzaenderung__c filialnetzaenderung = new Filialnetzaenderung__c(
					Filiale_Filialpartner__c = account.Id,
					Schliessung_avisiert_fuer__c = Date.today(),
					RecordTypeId = Schema.SObjectType.Filialnetzaenderung__c.getRecordTypeInfosByDeveloperName()
							.get( 'Packstation' ).getRecordTypeId(),
					Faecher_Gesamtziel__c = 200,
					Faecher_IST__c = 120,
					Zieltermin__c = Date.today()
			);
			insert filialnetzaenderung;
			TriggerHandler.clearBypass('FilialnetzaenderungTriggerHandler');
			List<Task> tasks = [
					SELECT
							Id
					FROM Task
					WHERE Aufgabenart__c = 'Akquiseauftrag Packstation zu FNÄ'
					AND Filialnetzaenderung__c = :filialnetzaenderung.Id
			];
			
			System.assertEquals( 0, tasks.size() );
			
			Test.startTest();
			filialnetzaenderung.Zieltermin__c = Date.today().addDays( 1 );
			update filialnetzaenderung;
			Test.stopTest();
			
			tasks = [
					SELECT
							Id
					FROM Task
					WHERE Aufgabenart__c = 'Akquiseauftrag Packstation zu FNÄ'
					AND Filialnetzaenderung__c = :filialnetzaenderung.Id
			];
			
			System.assertEquals( 1, tasks.size() );
		}
	}
}