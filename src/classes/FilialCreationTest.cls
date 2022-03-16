/**
 *@author       Mats Böhler
 *@created      20.07.2020
 *
 *
 *@description  AccountCreationServiceTest
 *              MYPM-267 - Aufgabe - autm. Anlage bei Neuanlage einer Filiale
 *
 *
 *@changelog    20.07.2020 Mats Böhler  - Created
 *              
 * 
 */
@IsTest
private class FilialCreationTest {
	
	@TestSetup static void setupRequiredOrgEDPs () {
		List<String> orgEdpNames = new List<String> {
				'3920/30 Aussenstelle',
				'Vertriebsmanager',
				'3910 Immo/Instandh/Automation'
		};
		List<OrgE_DP__c> orgEDPS = new List<OrgE_DP__c>();
		for ( String name : orgEdpNames ) {
			orgEDPS.add(
					new OrgE_DP__c(
							Aussenstellen_Ma__c = UserInfo.getUserId(),
							Koordinator__c = UserInfo.getUserId(),
							OrgE_DP_Name__c = name,
							MA_ASt_PuDS__c = UserInfo.getUserId(),
							MA_ASt_EK__c = UserInfo.getUserId()
					)
			);
		}
		insert orgEDPS;
	}
	
	@IsTest
	static void testBulk () {
		
		System.runAs( TestUser.create( TestUser.UserType.VL2001 ) ) {
			
			List<Account> accounts = new List<Account>();
			OrgE_DP__c orgEDP = insertOrgEDP();
			Integer quantity = 10;
			for ( Integer i = 0; i < quantity; i++ ) {
				accounts.add ( ( Account ) TestFactory.createSObject(
						new Account(
								Vertragsbetreuende_Einheit__c = orgEDP.Id,
								RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
										.get( 'Filiale' ).getRecordTypeId(),
								Filialart__c = '123',
								Eroeffnungsdatum__c = Date.today(),
								Vorgaengerfiliale_Name__c = 'nicht vorhanden',
								GL__c = orgEDP.Id,
								NL_Brief_Lookup__c = orgEDP.Id
						),
						false
				) );
			}
			Test.startTest();
			insert accounts;
			Test.stopTest();
			
			System.assertEquals( quantity * 5, [ SELECT Id FROM Task ].size() );
		}
	}
	
	/**
	 * @description Neue Partner-Filiale (exkl. DPS)
	 */
	@IsTest
	static void testNewPartnerFilialeExcluding_DPS () {
		
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			TriggerHandler.bypass( 'AccountTriggerHandler' );
			Account account = ( Account ) TestFactory.createSObject(
					new Account(
							Vertragsbetreuende_Einheit__c = insertOrgEDP().Id,
							GL__c = insertOrgEDP().Id,
							NL_Brief_Lookup__c = insertOrgEDP().Id,
							RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
									.get( 'Filiale_Dummy' ).getRecordTypeId(),
							Filialart__c = 'DHL-Paketshop'
					),
					true
			);
			
			Filialnetzaenderung__c filialnetzaenderung = new Filialnetzaenderung__c(
					Erledigungsdatum_FNAE__c = null,
					Zu_erwartender_Debitor__c = '12345',
					Schliessung_avisiert_fuer__c = Date.today(),
					Filiale_Filialpartner__c = account.Id
			);
			insert filialnetzaenderung;
			TriggerHandler.clearBypass( 'AccountTriggerHandler' );
			Test.startTest();
			account.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
					.get( 'Filiale' ).getRecordTypeId();
			account.Debitor__c = '12345';
			update account;
			Test.stopTest();
			
			account = [
					SELECT
							Id,
							Eroeffnungsdatum__c
					FROM Account
					WHERE Id = :account.Id
					LIMIT 1
			];
			filialnetzaenderung = [
					SELECT
							Id,
							Neue_Filiale_neuer_Filialpartner__c
					FROM Filialnetzaenderung__c
					WHERE Id = :filialnetzaenderung.Id
			];
			System.assertEquals( account.Id, filialnetzaenderung.Neue_Filiale_neuer_Filialpartner__c );
			
			List<Task> tasks = [
					SELECT
							Id,
							Aufgabenart__c,
							Priority,
							Status,
							ActivityDate,
							Auftraggeber__c,
							Auftragnehmer__c,
							Description,
							Erledigung_bis_zum__c,
							RecordTypeId,
							Typc__c,
							AccountId
					FROM Task
					WHERE AccountId = :account.Id
			];
			
			Integer counter = 0;
			for ( Task task : tasks ) {
				if ( task.Aufgabenart__c == 'Begleitung Eröffnung + Detail' ) {
					counter++;
				}
				if ( task.Aufgabenart__c == 'Ersteinweisung Filiale' ) {
					counter++;
				}
				if ( task.Aufgabenart__c == 'Einrichtungsgespräch Partner-Filiale (ASt)' ) {
					counter++;
				}
				if ( task.Aufgabenart__c == 'Vorbereitung Filialeinrichtung' ) {
					counter++;
				}
				if ( task.Aufgabenart__c == 'Veranlassung SAP Stammdatenpflege (NUR Partner-Filialen)' ) {
					counter++;
				}
			}
			System.assert( counter == 4 );
		}
	}
	
	/**
	 * @description DPS Filiale
	 */
	@IsTest
	static void testNewPartnerFiliale_DPS () {
		
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			TriggerHandler.bypass( 'AccountTriggerHandler' );
			Account account = createAccount();
			Filialnetzaenderung__c filialnetzaenderung = new Filialnetzaenderung__c(
					Erledigungsdatum_FNAE__c = null,
					Zu_erwartender_Debitor__c = '12345',
					Schliessung_avisiert_fuer__c = Date.today(),
					Filiale_Filialpartner__c = account.Id
			);
			insert filialnetzaenderung;
			TriggerHandler.clearBypass( 'AccountTriggerHandler' );
			Test.startTest();
			account.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
					.get( 'Filiale' ).getRecordTypeId();
			account.Debitor__c = '12345';
			account.Filialart__c = 'DPS';
			update account;
			Test.stopTest();
			
			account = [
					SELECT
							Id,
							Eroeffnungsdatum__c
					FROM Account
					WHERE Id = :account.Id
					LIMIT 1
			];
			filialnetzaenderung = [
					SELECT
							Id,
							Neue_Filiale_neuer_Filialpartner__c
					FROM Filialnetzaenderung__c
					WHERE Id = :filialnetzaenderung.Id
			];
			System.assertEquals( account.Id, filialnetzaenderung.Neue_Filiale_neuer_Filialpartner__c );
			
			List<Task> tasks = [
					SELECT
							Id,
							Aufgabenart__c,
							Priority,
							Status,
							ActivityDate,
							Auftraggeber__c,
							Auftragnehmer__c,
							Description,
							Erledigung_bis_zum__c,
							RecordTypeId,
							Typc__c,
							AccountId
					FROM Task
					WHERE AccountId = :account.Id
			];
			System.assertEquals( 8, tasks.size() );
			
			Integer counter = 0;
			for ( Task task : tasks ) {
				
				if ( task.Aufgabenart__c == 'Begleitung Eröffnung + Detail' ) {
					System.assert( task.Priority == 'Hoch' );
					System.assert( task.Status == 'Nicht begonnen' );
					System.assert( account.Eroeffnungsdatum__c == Date.today().addYears( -1 ) );
					System.assertEquals( account.Eroeffnungsdatum__c.addDays( -28 ), task.ActivityDate );
					System.assert( task.Aufgabenart__c == 'Begleitung Eröffnung + Detail' );
					System.assert( task.Auftraggeber__c == '3920/30 Außenstelle' );
					System.assert( task.Auftragnehmer__c == 'Vertriebsmanager' );
					System.assert( task.Erledigung_bis_zum__c == account.Eroeffnungsdatum__c );
					System.assert( task.RecordTypeId == Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
							.get( 'A_Aufgaben_automatische_Anlage' ).getRecordTypeId() );
					System.assert( task.Typc__c == 'Besuch' );
					System.assert( task.Description.contains( 'Filiale gemäß Einrichtungsprozess Partner-Filiale in ' +
							'IPP übernehmen und die Einrichtungsqualität bewerten. Jeder Mangel ist im Aufgabendetail ' +
							'unter Beachtung der Bewertungshinweise https://mypm.lightning.force.com/sfc/#version' +
							'?selectedVersionId=0681p000004chJS zu dokumentieren.' ) );
					counter++;
				}
				if ( task.Aufgabenart__c == 'Ersteinweisung Filiale' ) {
					System.assert( task.Priority == 'Hoch' );
					System.assert( task.Status == 'Nicht begonnen' );
					System.assert( account.Eroeffnungsdatum__c == Date.today().addYears( -1 ) );
					System.assertEquals( account.Eroeffnungsdatum__c.addDays( -28 ), task.ActivityDate );
					System.assert( task.Aufgabenart__c == 'Ersteinweisung Filiale' );
					System.assert( task.Auftraggeber__c == '3540 DP Shop' );
					System.assert( task.Auftragnehmer__c == 'Vertriebsmanager' );
					System.assert( task.Erledigung_bis_zum__c == account.Eroeffnungsdatum__c.addDays( 14 ) );
					System.assert( task.RecordTypeId == Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
							.get( 'A_Aufgaben_automatische_Anlage' ).getRecordTypeId() );
					System.assert( task.Typc__c == 'Besuch' );
					System.assert( task.Description.contains( 'Die Ersteinweisung beginnt am Tag der Eröffnung. ' +
							'Durchführung und Dauer gemäß IPP inkl. Besonderheiten DP Shop.' ) );
					counter++;
				}
				if ( task.Aufgabenart__c == 'DP Shop Gefahren- und Belastungsanalyse bei Neueinrichtung (ASt)' ) {
					System.assert( task.Priority == 'Mittel' );
					System.assert( task.Status == 'Nicht begonnen' );
					System.assert( account.Eroeffnungsdatum__c == Date.today().addYears( -1 ) );
					System.assertEquals( account.Eroeffnungsdatum__c.addDays( -35 ), task.ActivityDate );
					System.assert( task.Aufgabenart__c == 'DP Shop Gefahren- und Belastungsanalyse bei Neueinrichtung (ASt)' );
					System.assertEquals( '3220 Sicherheit', task.Auftraggeber__c );
					System.assert( task.Auftragnehmer__c == '3920/30 Aussenstelle' );
					System.assert( task.Erledigung_bis_zum__c == account.Eroeffnungsdatum__c.addDays( -3 ) );
					System.assert( task.RecordTypeId == Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
							.get( 'A_Aufgaben_automatische_Anlage' ).getRecordTypeId() );
					System.assert( task.Typc__c == 'Besuch' );
					System.assert( task.Description.contains( 'GeBu für DPS-Filiale (https://mypm.lightning.force.com/sfc' +
							'/#version?selectedDocumentId=069240000026lRo) ausfertigen und als Anlage anfügen.' ) );
					counter++;
				}
				if ( task.Aufgabenart__c == 'DP Shop Erstunterweisung Arbeits-/Brandschutz/Gefahrgut' ) {
					System.assert( task.Priority == 'Mittel' );
					System.assert( task.Status == 'Nicht begonnen' );
					System.assert( account.Eroeffnungsdatum__c == Date.today().addYears( -1 ) );
					System.assertEquals( account.Eroeffnungsdatum__c.addDays( -21 ), task.ActivityDate );
					System.assert( task.Aufgabenart__c == 'DP Shop Erstunterweisung Arbeits-/Brandschutz/Gefahrgut' );
					System.assertEquals( '3540 DP Shop', task.Auftraggeber__c );
					System.assert( task.Auftragnehmer__c == 'Vertriebsmanager' );
					System.assert( task.Erledigung_bis_zum__c == account.Eroeffnungsdatum__c );
					System.assert( task.RecordTypeId == Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
							.get( 'A_Aufgaben_automatische_Anlage' ).getRecordTypeId() );
					System.assert( task.Typc__c == 'Besuch' );
					counter++;
				}
				if ( task.Aufgabenart__c == 'DP Shop Übernahme der Räume (ASt)' ) {
					System.assert( task.Priority == 'Hoch' );
					System.assert( task.Status == 'Nicht begonnen' );
					System.assert( account.Eroeffnungsdatum__c == Date.today().addYears( -1 ) );
					System.assertEquals( account.Eroeffnungsdatum__c.addDays( -35 ), task.ActivityDate );
					System.assert( task.Aufgabenart__c == 'DP Shop Übernahme der Räume (ASt)' );
					System.assertEquals( '3910 Immo/Instandh/Automation', task.Auftraggeber__c );
					System.assert( task.Auftragnehmer__c == '3920/30 Aussenstelle' );
					System.assert( task.Erledigung_bis_zum__c == account.Eroeffnungsdatum__c.addDays( -3 ) );
					System.assert( task.RecordTypeId == Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
							.get( 'A_Aufgaben_automatische_Anlage' ).getRecordTypeId() );
					System.assert( task.Typc__c == 'Besuch' );
					System.assert( task.Description.contains( 'Übernahme der Filiale durchführen sowie Übernahme- ' +
							'und Abnahmeprotokoll (https://mypm.lightning.force.com/sfc/#version' +
							'?selectedDocumentId=069240000028YTb) an Aufgabe anhängen.' ) );
					counter++;
				}
				if ( task.Aufgabenart__c == 'DP Shop Filialübergabe (ASt+Ma DPS)' ) {
					System.assert( task.Priority == 'Hoch' );
					System.assert( task.Status == 'Nicht begonnen' );
					System.assert( account.Eroeffnungsdatum__c == Date.today().addYears( -1 ) );
					System.assertEquals( account.Eroeffnungsdatum__c.addDays( -35 ), task.ActivityDate );
					System.assert( task.Aufgabenart__c == 'DP Shop Filialübergabe (ASt+Ma DPS)' );
					System.assertEquals( '3540 DP Shop', task.Auftraggeber__c );
					System.assert( task.Auftragnehmer__c == '3920/30 Aussenstelle' );
					System.assert( task.Erledigung_bis_zum__c == account.Eroeffnungsdatum__c.addDays( -3 ) );
					System.assert( task.RecordTypeId == Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
							.get( 'A_Aufgaben_automatische_Anlage' ).getRecordTypeId() );
					System.assert( task.Typc__c == 'Besuch' );
					System.assert( task.Description.contains( 'Fertiggestellte Filiale und Schlüssel an Ma ' +
							'PDS übergeben und dokumentieren; Übergabedatum = Erledigungsdatum.' ) );
					counter++;
				}
				if ( task.Aufgabenart__c == 'DP Shop Bestellung Bargelderstausstattung (SCF)' ) {
					System.assert( task.Priority == 'Hoch' );
					System.assert( task.Status == 'Nicht begonnen' );
					System.assert( account.Eroeffnungsdatum__c == Date.today().addYears( -1 ) );
					System.assertEquals( account.Eroeffnungsdatum__c.addDays( -7 ), task.ActivityDate );
					System.assert( task.Aufgabenart__c == 'DP Shop Bestellung Bargelderstausstattung (SCF)' );
					System.assertEquals( '3120 Wertlogistik', task.Auftraggeber__c );
					System.assert( task.Auftragnehmer__c == '3540 DP Shop' );
					System.assert( task.Erledigung_bis_zum__c == account.Eroeffnungsdatum__c.addDays( -3 ) );
					System.assert( task.RecordTypeId == Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
							.get( 'A_Aufgaben_automatische_Anlage' ).getRecordTypeId() );
					System.assert( task.Typc__c == 'Intern' );
					System.assert( task.Description.contains( 'Bestellung Erstausstattung Bargeld per WF 330 für ' +
							'DP Shop Filiale. Bei OZ 78 ohne Ausgabe – Typ 1 (200 €), bei OZ 78 mit ' +
							'Ausgabe und OZ 79 – Typ 2 (1.000 €)' ) );
					counter++;
				}
			}
			System.assertEquals( 7, counter );
		}
	}
	
	/**
	 * @description DHL Paketshop (toom)
	 */
	@IsTest
	static void test_DHL_Paketshop_TOOM () {
		
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			TriggerHandler.bypass( 'AccountTriggerHandler' );
			Account account = createAccount();
			Filialnetzaenderung__c filialnetzaenderung = new Filialnetzaenderung__c(
					Erledigungsdatum_FNAE__c = null,
					Zu_erwartender_Debitor__c = '12345',
					Schliessung_avisiert_fuer__c = Date.today(),
					Filiale_Filialpartner__c = account.Id
			);
			insert filialnetzaenderung;
			TriggerHandler.clearBypass( 'AccountTriggerHandler' );
			Test.startTest();
			account.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
					.get( 'DHL_Paketshop' ).getRecordTypeId();
			account.Debitor__c = '12345';
			account.Filialart__c = 'DHL-Paketshop';
			account.Kette__c = 'SP Toom Baumarkt';
			update account;
			Test.stopTest();
			
			account = [
					SELECT
							Id,
							Eroeffnungsdatum__c
					FROM Account
					WHERE Id = :account.Id
					LIMIT 1
			];
			filialnetzaenderung = [
					SELECT
							Id,
							Neue_Filiale_neuer_Filialpartner__c
					FROM Filialnetzaenderung__c
					WHERE Id = :filialnetzaenderung.Id
			];
			System.assertEquals( account.Id, filialnetzaenderung.Neue_Filiale_neuer_Filialpartner__c );
			
			List<Task> tasks = [
					SELECT
							Id,
							Aufgabenart__c,
							Priority,
							Status,
							ActivityDate,
							Auftraggeber__c,
							Auftragnehmer__c,
							Description,
							Erledigung_bis_zum__c,
							RecordTypeId,
							Typc__c,
							AccountId
					FROM Task
					WHERE AccountId = :account.Id
			];
			System.assertEquals( 2, tasks.size() );
			
			Integer counter = 0;
			for ( Task task : tasks ) {
				
				if ( task.Aufgabenart__c == 'DHL Paketshop Terminabstimmung Ersteinweisung' ) {
					System.assert( task.Priority == 'Hoch' );
					System.assert( task.Status == 'Nicht begonnen' );
					System.assert( account.Eroeffnungsdatum__c == Date.today().addYears( -1 ) );
					System.assertEquals( account.Eroeffnungsdatum__c.addDays( -10 ), task.ActivityDate );
					System.assert( task.Aufgabenart__c == 'DHL Paketshop Terminabstimmung Ersteinweisung' );
					System.assert( task.Auftraggeber__c == '5700 Strat. Partnermanagement' );
					System.assertEquals( 'Vertriebskoordinator VGL', task.Auftragnehmer__c );
					System.assert( task.Erledigung_bis_zum__c == account.Eroeffnungsdatum__c.addDays( -7 ) );
					System.assert( task.RecordTypeId == Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
							.get( 'A_Aufgaben_automatische_Anlage' ).getRecordTypeId() );
					System.assert( task.Typc__c == 'Telefonat (Outbound)' );
					System.assert( task.Description.contains( 'Bitte telefonische Terminbestätigung ' +
							'Ersteinweisung DHL Paketshop vornehmen (Ersteinweisung ca. 2 Tage vor EÖ, in der ' +
							'Zielzeit 13h-14h). Ansprechpartner ist Marktleitung. Bitte auf Aufladung ' +
							'Handscanner hinweisen.' ) );
					counter++;
				}
				if ( task.Aufgabenart__c == 'DHL Paketshop Ersteinweisung' ) {
					System.assert( task.Priority == 'Hoch' );
					System.assert( task.Status == 'Nicht begonnen' );
					System.assert( account.Eroeffnungsdatum__c == Date.today().addYears( -1 ) );
					System.assertEquals( account.Eroeffnungsdatum__c.addDays( -3 ), task.ActivityDate );
					System.assert( task.Aufgabenart__c == 'DHL Paketshop Ersteinweisung' );
					System.assert( task.Auftraggeber__c == '5700 Strat. Partnermanagement' );
					System.assert( task.Auftragnehmer__c == 'Vertriebskoordinator VGL' );
					System.assert( task.Erledigung_bis_zum__c == account.Eroeffnungsdatum__c.addDays( -2 ) );
					System.assert( task.RecordTypeId == Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
							.get( 'A_Aufgaben_automatische_Anlage' ).getRecordTypeId() );
					System.assert( task.Typc__c == 'Besuch' );
					System.assert( task.Description.contains( '1) Bitte im Rahmen der Ersteinweisung auf ' +
							'Premium-Hotline hinweisen 2) Bei Sortiment 0 bitte das Handbuch Sortiment 0 ' +
							'https://mypm.lightning.force.com/sfc/#version?selectedVersionId=0681p000005bAJP nutzen' ) );
					counter++;
				}
			}
			System.assertEquals( 2, counter );
		}
	}
	
	/**
	 * @description DHL Paketshop (REWE)
	 */
	@IsTest
	static void test_DHL_Paketshop_REWE () {
		
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			TriggerHandler.bypass( 'AccountTriggerHandler' );
			Account account = createAccount();
			Filialnetzaenderung__c filialnetzaenderung = new Filialnetzaenderung__c(
					Erledigungsdatum_FNAE__c = null,
					Zu_erwartender_Debitor__c = '12345',
					Schliessung_avisiert_fuer__c = Date.today(),
					Filiale_Filialpartner__c = account.Id
			);
			insert filialnetzaenderung;
			TriggerHandler.clearBypass( 'AccountTriggerHandler' );
			Test.startTest();
			account.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
					.get( 'DHL_Paketshop' ).getRecordTypeId();
			account.Debitor__c = '12345';
			account.Filialart__c = 'DHL-Paketshop';
			account.Kette__c = 'REWE';
			update account;
			Test.stopTest();
			
			account = [
					SELECT
							Id,
							Eroeffnungsdatum__c
					FROM Account
					WHERE Id = :account.Id
					LIMIT 1
			];
			filialnetzaenderung = [
					SELECT
							Id,
							Neue_Filiale_neuer_Filialpartner__c
					FROM Filialnetzaenderung__c
					WHERE Id = :filialnetzaenderung.Id
			];
			System.assertEquals( account.Id, filialnetzaenderung.Neue_Filiale_neuer_Filialpartner__c );
			
			List<Task> tasks = [
					SELECT
							Id,
							Aufgabenart__c,
							Priority,
							Status,
							ActivityDate,
							Auftraggeber__c,
							Auftragnehmer__c,
							Description,
							Erledigung_bis_zum__c,
							RecordTypeId,
							Typc__c,
							AccountId
					FROM Task
					WHERE AccountId = :account.Id
			];
			System.assertEquals( 2, tasks.size() );
			
			Integer counter = 0;
			for ( Task task : tasks ) {
				
				if ( task.Aufgabenart__c == 'DHL Paketshop Terminabstimmung Ersteinweisung' ) {
					System.assert( task.Priority == 'Hoch' );
					System.assert( task.Status == 'Nicht begonnen' );
					System.assert( account.Eroeffnungsdatum__c == Date.today().addYears( -1 ) );
					System.assertEquals( account.Eroeffnungsdatum__c.addDays( -10 ), task.ActivityDate );
					System.assert( task.Aufgabenart__c == 'DHL Paketshop Terminabstimmung Ersteinweisung' );
					System.assert( task.Auftraggeber__c == '5700 Strat. Partnermanagement' );
					System.assertEquals( 'Vertriebskoordinator VGL', task.Auftragnehmer__c );
					System.assert( task.Erledigung_bis_zum__c == account.Eroeffnungsdatum__c.addDays( -7 ) );
					System.assert( task.RecordTypeId == Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
							.get( 'A_Aufgaben_automatische_Anlage' ).getRecordTypeId() );
					System.assert( task.Typc__c == 'Telefonat (Outbound)' );
					System.assert( task.Description.contains( 'Bitte telefonische Terminbestätigung Ersteinweisung ' +
							'DHL Paketshop vornehmen (Ersteinweisung ca. 2 Tage vor EÖ, in der Zielzeit 10h-12h). ' +
							'Ansprechpartner ist Marktleitung. Bitte auf Aufladung Handscanner hinweisen.' ) );
					counter++;
				}
				if ( task.Aufgabenart__c == 'DHL Paketshop Ersteinweisung' ) {
					System.assert( task.Priority == 'Hoch' );
					System.assert( task.Status == 'Nicht begonnen' );
					System.assert( account.Eroeffnungsdatum__c == Date.today().addYears( -1 ) );
					System.assertEquals( account.Eroeffnungsdatum__c.addDays( -3 ), task.ActivityDate );
					System.assert( task.Aufgabenart__c == 'DHL Paketshop Ersteinweisung' );
					System.assert( task.Auftraggeber__c == '5700 Strat. Partnermanagement' );
					System.assert( task.Auftragnehmer__c == 'Vertriebskoordinator VGL' );
					System.assert( task.Erledigung_bis_zum__c == account.Eroeffnungsdatum__c.addDays( -2 ) );
					System.assert( task.RecordTypeId == Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
							.get( 'A_Aufgaben_automatische_Anlage' ).getRecordTypeId() );
					System.assert( task.Typc__c == 'Besuch' );
					System.assert( task.Description.contains( 'Bitte Ersteinweisung DHL Paketshop bei REWE vornehmen; ' +
							'Bitte auf Premium-Hotline hinweisen; Bei Sortiment 0 Arbeitshilfe Sortiment 0 ' +
							'nutzen https://mypm.lightning.force.com/sfc/#version?selectedVersionId=0681p000005bAJP; ' +
							'Bitte REWE-Legitimationsschreiben mitbringen https://mypm.lightning.force.com/sfc/#version' +
							'?selectedDocumentId=06924000002inep' ) );
					counter++;
				}
			}
			System.assertEquals( 2, counter );
		}
	}
	
	/**
	 * @description DHL Paketshop
	 */
	@IsTest
	static void test_DHL_Paketshop () {
		
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			TriggerHandler.bypass( 'AccountTriggerHandler' );
			Account account = createAccount();
			Filialnetzaenderung__c filialnetzaenderung = new Filialnetzaenderung__c(
					Erledigungsdatum_FNAE__c = null,
					Zu_erwartender_Debitor__c = '12345',
					Schliessung_avisiert_fuer__c = Date.today(),
					Filiale_Filialpartner__c = account.Id
			);
			insert filialnetzaenderung;
			TriggerHandler.clearBypass( 'AccountTriggerHandler' );
			Test.startTest();
			account.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
					.get( 'DHL_Paketshop' ).getRecordTypeId();
			account.Debitor__c = '12345';
			account.Filialart__c = 'DHL-Paketshop';
			account.Kette__c = '123Meins';
			account.ASt_Name__c = 'AstName';
			update account;
			Test.stopTest();
			
			account = [
					SELECT
							Id,
							Eroeffnungsdatum__c
					FROM Account
					WHERE Id = :account.Id
					LIMIT 1
			];
			filialnetzaenderung = [
					SELECT
							Id,
							Neue_Filiale_neuer_Filialpartner__c
					FROM Filialnetzaenderung__c
					WHERE Id = :filialnetzaenderung.Id
			];
			System.assertEquals( account.Id, filialnetzaenderung.Neue_Filiale_neuer_Filialpartner__c );
			
			List<Task> tasks = [
					SELECT
							Id,
							Aufgabenart__c,
							Priority,
							Status,
							ActivityDate,
							Auftraggeber__c,
							Auftragnehmer__c,
							Description,
							Erledigung_bis_zum__c,
							RecordTypeId,
							Typc__c,
							AccountId
					FROM Task
					WHERE AccountId = :account.Id
			];
			System.assertEquals( 1, tasks.size() );
			
			Integer counter = 0;
			for ( Task task : tasks ) {
				
				if ( task.Aufgabenart__c == 'Kapazitätsabfrage Paketausgabe und -annahme + Detail' ) {
					System.assert( task.Priority == 'Mittel' );
					System.assert( task.Status == 'Nicht begonnen' );
					System.assert( account.Eroeffnungsdatum__c == Date.today().addYears( -1 ) );
					System.assertEquals( account.Eroeffnungsdatum__c.addDays( -8 ), task.ActivityDate );
					System.assert( task.Aufgabenart__c == 'Kapazitätsabfrage Paketausgabe und -annahme + Detail' );
					System.assert( task.Auftraggeber__c == '1L3 Netzmanagement' );
					System.assert( task.Erledigung_bis_zum__c == account.Eroeffnungsdatum__c );
					System.assert( task.RecordTypeId == Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
							.get( 'A_Aufgaben_automatische_Anlage' ).getRecordTypeId() );
					System.assert( task.Typc__c == 'Telefonat (Outbound)' );
					System.assert( task.Description.contains( 'Wird durch einen Prozess befüllt (Aufgaben - Sammelprozess)' ) );
					counter++;
				}
			}
			System.assertEquals( 1, counter );
		}
	}
	
	/**
	 * @description 95 -> 79,76 Formatänderung
	 */
	@IsTest
	static void testConversion_95_To_79_Or_76 () {
		
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			TriggerHandler.bypass( 'AccountTriggerHandler' );
			Account account = createAccount();
			Filialnetzaenderung__c filialnetzaenderung = new Filialnetzaenderung__c(
					Erledigungsdatum_FNAE__c = null,
					Zu_erwartender_Debitor__c = '12345',
					Schliessung_avisiert_fuer__c = Date.today(),
					Filiale_Filialpartner__c = account.Id
			);
			insert filialnetzaenderung;
			TriggerHandler.clearBypass( 'AccountTriggerHandler' );
			Test.startTest();
			account.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
					.get( 'Filiale' ).getRecordTypeId();
			account.Aenderungsgrund_Vorgaengerfiliale__c = 'Ersatz für PB FC nach Upgrade';
			account.Filialtyp_OZ_Vorgaengerfiliale__c = '95';
			account.Filialtyp_OZ__c = '79';
			account.Netzentscheidung_Vorgaengerfiliale__c = 'nicht leer';
			account.Debitor__c = '12345';
			account.Filialart__c = '123';
			update account;
			Test.stopTest();
			
			account = [
					SELECT
							Id,
							Eroeffnungsdatum__c
					FROM Account
					WHERE Id = :account.Id
					LIMIT 1
			];
			filialnetzaenderung = [
					SELECT
							Id,
							Neue_Filiale_neuer_Filialpartner__c
					FROM Filialnetzaenderung__c
					WHERE Id = :filialnetzaenderung.Id
			];
			System.assertEquals( account.Id, filialnetzaenderung.Neue_Filiale_neuer_Filialpartner__c );
			
			List<Task> tasks = [
					SELECT
							Id,
							Aufgabenart__c,
							Priority,
							Status,
							ActivityDate,
							Auftraggeber__c,
							Auftragnehmer__c,
							Description,
							Erledigung_bis_zum__c,
							RecordTypeId,
							Typc__c,
							AccountId
					FROM Task
					WHERE AccountId = :account.Id
			];
			
			Integer counter = 0;
			for ( Task task : tasks ) {
				
				if ( task.Aufgabenart__c == 'Vorbereitung Up-/Downgrade Filialeinrichtung (Formatwechsel)' ) {
					System.assert( task.Priority == 'Hoch' );
					System.assert( task.Status == 'Nicht begonnen' );
					System.assert( account.Eroeffnungsdatum__c == Date.today().addYears( -1 ) );
					System.assertEquals( account.Eroeffnungsdatum__c.addDays( -56 ), task.ActivityDate );
					System.assert( task.Aufgabenart__c == 'Vorbereitung Up-/Downgrade Filialeinrichtung (Formatwechsel)' );
					System.assert( task.Auftraggeber__c == '3920/30 Außenstelle' );
					System.assertEquals( 'Vertriebsmanager', task.Auftragnehmer__c );
					System.assert( task.Erledigung_bis_zum__c == account.Eroeffnungsdatum__c.addDays( -49 ) );
					System.assert( task.RecordTypeId == Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
							.get( 'A_Aufgaben_automatische_Anlage' ).getRecordTypeId() );
					System.assert( task.Typc__c == 'Intern' );
					System.assert( task.Description.contains( 'Auslistung FDL - Einrichtungsdatei ergänzen und ' +
							'als Anhang anfügen (Link: https://mypm.lightning.force.com/sfc/#version?selectedDocumentId=' +
							'069240000026lQq). Nur Ausfertigung des Reiters \'Vorblatt\' & \'DP Shop u. ' +
							'Bestandsfilialen\' inkl. zusätzliche Angaben für die Beräumung im Freitextfeld.' ) );
					counter++;
				}
				if ( task.Aufgabenart__c == 'Begleitung Up-/Downgrade' ) {
					System.assert( task.Priority == 'Hoch' );
					System.assert( task.Status == 'Nicht begonnen' );
					System.assert( account.Eroeffnungsdatum__c == Date.today().addYears( -1 ) );
					System.assertEquals( account.Eroeffnungsdatum__c.addDays( -1 ), task.ActivityDate );
					System.assert( task.Aufgabenart__c == 'Begleitung Up-/Downgrade' );
					System.assert( task.Auftraggeber__c == '3500 Betriebssteuerung' );
					System.assertEquals( 'Vertriebsmanager', task.Auftragnehmer__c );
					System.assert( task.Erledigung_bis_zum__c == account.Eroeffnungsdatum__c );
					System.assert( task.RecordTypeId == Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
							.get( 'A_Aufgaben_automatische_Anlage' ).getRecordTypeId() );
					System.assert( task.Typc__c == 'Besuch' );
					System.assert( task.Description.contains( 'Kassentechnische Abwicklung und Filialübernahme.  ' +
							'HINWEIS: Keine Rücksendung der Produkte und keine Neubelieferung' ) );
					counter++;
				}
				if ( task.Aufgabenart__c == 'Einrichtungsgespräch Partner-Filiale (ASt)' ) {
					System.assert( task.Priority == 'Hoch' );
					System.assert( task.Status == 'Nicht begonnen' );
					System.assert( account.Eroeffnungsdatum__c == Date.today().addYears( -1 ) );
					System.assertEquals( account.Eroeffnungsdatum__c.addDays( -35 ), task.ActivityDate );
					System.assert( task.Aufgabenart__c == 'Einrichtungsgespräch Partner-Filiale (ASt)' );
					System.assert( task.Auftraggeber__c == 'Vertriebskoordinator' );
					System.assertEquals( '3920/30 Aussenstelle', task.Auftragnehmer__c );
					System.assert( task.Erledigung_bis_zum__c == account.Eroeffnungsdatum__c.addDays( -28 ) );
					System.assert( task.RecordTypeId == Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
							.get( 'A_Aufgaben_automatische_Anlage' ).getRecordTypeId() );
					System.assert( task.Typc__c == 'Telefonat (Outbound)' );
					System.assert( task.Description.contains( 'Formatänderung 95 in 79: Anpassung der Filialausstattung ' +
							'(Postbank-Logo + Gefahrenmeldeanlage)' ) );
					counter++;
				}
			}
			System.assertEquals( 2, counter );
		}
	}
	
	/**
	 * @description 79/76 -> 95 Formatänderung
	 */
	@IsTest
	static void testConversion_79_Or_76_To_95 () {
		
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			TriggerHandler.bypass( 'AccountTriggerHandler' );
			Account account = createAccount();
			Filialnetzaenderung__c filialnetzaenderung = new Filialnetzaenderung__c(
					Erledigungsdatum_FNAE__c = null,
					Zu_erwartender_Debitor__c = '12345',
					Schliessung_avisiert_fuer__c = Date.today(),
					Filiale_Filialpartner__c = account.Id
			);
			insert filialnetzaenderung;
			TriggerHandler.clearBypass( 'AccountTriggerHandler' );
			Test.startTest();
			account.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
					.get( 'Filiale' ).getRecordTypeId();
			account.Aenderungsgrund_Vorgaengerfiliale__c = 'Ersatz für PB FC nach Upgrade';
			account.Filialtyp_OZ_Vorgaengerfiliale__c = '79';
			account.Filialtyp_OZ__c = '95';
			account.Netzentscheidung_Vorgaengerfiliale__c = 'nicht leer';
			account.Debitor__c = '12345';
			account.Filialart__c = '123';
			update account;
			Test.stopTest();
			
			account = [
					SELECT
							Id,
							Eroeffnungsdatum__c
					FROM Account
					WHERE Id = :account.Id
					LIMIT 1
			];
			filialnetzaenderung = [
					SELECT
							Id,
							Neue_Filiale_neuer_Filialpartner__c
					FROM Filialnetzaenderung__c
					WHERE Id = :filialnetzaenderung.Id
			];
			System.assertEquals( account.Id, filialnetzaenderung.Neue_Filiale_neuer_Filialpartner__c );
			
			List<Task> tasks = [
					SELECT
							Id,
							Aufgabenart__c,
							Priority,
							Status,
							ActivityDate,
							Auftraggeber__c,
							Auftragnehmer__c,
							Description,
							Erledigung_bis_zum__c,
							RecordTypeId,
							Typc__c,
							AccountId
					FROM Task
					WHERE AccountId = :account.Id
			];
			
			Integer counter = 0;
			for ( Task task : tasks ) {
				
				if ( task.Aufgabenart__c == 'Vorbereitung Up-/Downgrade Filialeinrichtung (Formatwechsel)' ) {
					System.assert( task.Priority == 'Hoch' );
					System.assert( task.Status == 'Nicht begonnen' );
					System.assert( account.Eroeffnungsdatum__c == Date.today().addYears( -1 ) );
					System.assertEquals( account.Eroeffnungsdatum__c.addDays( -56 ), task.ActivityDate );
					System.assert( task.Aufgabenart__c == 'Vorbereitung Up-/Downgrade Filialeinrichtung (Formatwechsel)' );
					System.assert( task.Auftraggeber__c == '3920/30 Außenstelle' );
					System.assertEquals( 'Vertriebsmanager', task.Auftragnehmer__c );
					System.assert( task.Erledigung_bis_zum__c == account.Eroeffnungsdatum__c.addDays( -49 ) );
					System.assert( task.RecordTypeId == Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
							.get( 'A_Aufgaben_automatische_Anlage' ).getRecordTypeId() );
					System.assert( task.Typc__c == 'Intern' );
					System.assert( task.Description.contains( 'Nur Ausfertigung des Reiters \'Vorblatt\' & \'DP Shop ' +
							'u. Bestandsfilialen\' in der Einrichtungsdatei und zusätzliche Angaben für die ' +
							'Beräumung im Freitextfeld.' ) );
					counter++;
				}
				if ( task.Aufgabenart__c == 'Bargeld bestellen' ) {
					System.assert( task.Priority == 'Hoch' );
					System.assert( task.Status == 'Nicht begonnen' );
					System.assert( account.Eroeffnungsdatum__c == Date.today().addYears( -1 ) );
					System.assertEquals( account.Eroeffnungsdatum__c.addDays( -14 ), task.ActivityDate );
					System.assert( task.Aufgabenart__c == 'Bargeld bestellen' );
					System.assertEquals( '3120 Wertlogistik', task.Auftraggeber__c );
					System.assertEquals( 'Vertriebskoordinator VGL', task.Auftragnehmer__c );
					System.assert( task.Erledigung_bis_zum__c == account.Eroeffnungsdatum__c.addDays( -3 ) );
					System.assert( task.RecordTypeId == Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
							.get( 'A_Aufgaben_automatische_Anlage' ).getRecordTypeId() );
					System.assert( task.Typc__c == 'Intern' );
					System.assert( task.Description.contains( 'Über Workflow 330 die Bargelderstausstattung bestellen' ) );
					counter++;
				}
				if ( task.Aufgabenart__c == 'Begleitung Up-/Downgrade' ) {
					System.assert( task.Priority == 'Hoch' );
					System.assert( task.Status == 'Nicht begonnen' );
					System.assert( account.Eroeffnungsdatum__c == Date.today().addYears( -1 ) );
					System.assertEquals( account.Eroeffnungsdatum__c.addDays( -1 ), task.ActivityDate );
					System.assert( task.Aufgabenart__c == 'Begleitung Up-/Downgrade' );
					System.assert( task.Auftraggeber__c == '3500 Betriebssteuerung' );
					System.assertEquals( 'Vertriebsmanager', task.Auftragnehmer__c );
					System.assert( task.Erledigung_bis_zum__c == account.Eroeffnungsdatum__c );
					System.assert( task.RecordTypeId == Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
							.get( 'A_Aufgaben_automatische_Anlage' ).getRecordTypeId() );
					System.assert( task.Typc__c == 'Besuch' );
					System.assert( task.Description.contains( 'Kassentechnische Abwicklung und Filialübernahme.  ' +
							'HINWEIS: Keine Rücksendung der Produkte und keine Neubelieferung' ) );
					counter++;
				}
				if ( task.Aufgabenart__c == 'Einrichtungsgespräch Partner-Filiale (ASt)' ) {
					System.assert( task.Priority == 'Hoch' );
					System.assert( task.Status == 'Nicht begonnen' );
					System.assert( account.Eroeffnungsdatum__c == Date.today().addYears( -1 ) );
					System.assertEquals( account.Eroeffnungsdatum__c.addDays( -35 ), task.ActivityDate );
					System.assert( task.Aufgabenart__c == 'Einrichtungsgespräch Partner-Filiale (ASt)' );
					System.assert( task.Auftraggeber__c == 'Vertriebskoordinator' );
					System.assertEquals( '3920/30 Aussenstelle', task.Auftragnehmer__c );
					System.assert( task.Erledigung_bis_zum__c == account.Eroeffnungsdatum__c.addDays( -28 ) );
					System.assert( task.RecordTypeId == Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
							.get( 'A_Aufgaben_automatische_Anlage' ).getRecordTypeId() );
					System.assert( task.Typc__c == 'Telefonat (Outbound)' );
					System.assert( task.Description.contains( 'Formatänderung 79 in 95: Anpassung der ' +
							'Filialausstattung (Postbank-Logo + Gefahrenmeldeanlage)' ) );
					counter++;
				}
				if ( task.Aufgabenart__c == 'OZ 95 - Besonderheiten bei der Einrichtung/Eröffnung' ) {
					System.assert( task.Priority == 'Hoch' );
					System.assert( task.Status == 'Nicht begonnen' );
					System.assert( account.Eroeffnungsdatum__c == Date.today().addYears( -1 ) );
					System.assertEquals( account.Eroeffnungsdatum__c.addDays( -7 ), task.ActivityDate );
					System.assert( task.Aufgabenart__c == 'OZ 95 - Besonderheiten bei der Einrichtung/Eröffnung' );
					System.assert( task.Auftraggeber__c == '3500 Betriebssteuerung' );
					System.assertEquals( 'Vertriebsmanager', task.Auftragnehmer__c );
					System.assert( task.Erledigung_bis_zum__c == account.Eroeffnungsdatum__c );
					System.assert( task.RecordTypeId == Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
							.get( 'A_Aufgaben_automatische_Anlage' ).getRecordTypeId() );
					System.assert( task.Typc__c == 'Besuch' );
					System.assert( task.Description.contains( 'Bitte vor EÖ einer OZ 95 die Betriebsanweisung ' +
							'Kassen (BAK siehe Link: https://mypm.lightning.force.com/sfc/#version?selectedDocumentId=' +
							'06924000002jzvG) ausstellen, auf den Alarmplan zur GEMA hinwiesen, den/die ' +
							'Vertragspartner und alle Mitarbeiter gemäß GwG auf Zuverlässigkeit prüfen und ' +
							'ALLE Mitarbeiter auf die notwendige Zertifizierung gem. BargeldPrüfV ' +
							'hinweisen. Weitere Details finden Sie in IPP.' ) );
					counter++;
				}
				if ( task.Aufgabenart__c == 'Ersteinweisung Filiale' ) {
					System.assert( task.Priority == 'Hoch' );
					System.assert( task.Status == 'Nicht begonnen' );
					System.assert( account.Eroeffnungsdatum__c == Date.today().addYears( -1 ) );
					System.assertEquals( account.Eroeffnungsdatum__c, task.ActivityDate );
					System.assert( task.Aufgabenart__c == 'Ersteinweisung Filiale' );
					System.assert( task.Auftraggeber__c == '3500 Betriebssteuerung' );
					System.assert( task.Auftragnehmer__c == 'Vertriebsmanager' );
					System.assert( task.Erledigung_bis_zum__c == account.Eroeffnungsdatum__c.addDays( 3 ) );
					System.assert( task.RecordTypeId == Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
							.get( 'A_Aufgaben_automatische_Anlage' ).getRecordTypeId() );
					System.assert( task.Typc__c == 'Besuch' );
					System.assert( task.Description.contains( 'Ersteinweisung Sortimentserweiterung ' +
							'(Dauer ca. 3 Tage)' ) );
					counter++;
				}
			}
			System.assertEquals( 5, counter );
		}
	}
	
	/**
	 * @description 95 -> 84 Formatänderung
	 */
	@IsTest
	static void testConversion_95_To_84 () {
		
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			TriggerHandler.bypass( 'AccountTriggerHandler' );
			
			Account previousAccount = ( Account ) TestFactory.createSObject(
					new Account(
							Vertragsbetreuende_Einheit__c = insertOrgEDP().Id,
							RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
									.get( 'Filiale' ).getRecordTypeId(),
							Filialart__c = '123'
					),
					true
			);
			
			Account account = ( Account ) TestFactory.createSObject(
					new Account(
							Vertragsbetreuende_Einheit__c = insertOrgEDP().Id,
							RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
									.get( 'Filiale' ).getRecordTypeId(),
							Filialart__c = '123',
							Filialtyp_OZ_Vorgaengerfiliale__c = '95',
							Filialtyp_OZ__c = '84',
							Debitor__c = '12345',
							Netzentscheidung_Vorgaengerfiliale__c = 'Formatänderung genehmigt',
							Vorgaengerfiliale__c = previousAccount.Id
					),
					true
			);
			Filialnetzaenderung__c filialnetzaenderung = new Filialnetzaenderung__c(
					Erledigungsdatum_FNAE__c = null,
					Zu_erwartender_Debitor__c = '12345',
					Schliessung_avisiert_fuer__c = Date.today(),
					Filiale_Filialpartner__c = account.Id
			);
			insert filialnetzaenderung;
			TriggerHandler.clearBypass( 'AccountTriggerHandler' );
			Test.startTest();
			account.GL__c = insertOrgEDP().Id;
			account.NL_Brief_Lookup__c = insertOrgEDP().Id;
			update account;
			Test.stopTest();
			
			account = [
					SELECT
							Id,
							Eroeffnungsdatum__c,
							Filialtyp_OZ__c
					FROM Account
					WHERE Id = :account.Id
					LIMIT 1
			];
			System.assertEquals( '84', account.Filialtyp_OZ__c );
			filialnetzaenderung = [
					SELECT
							Id,
							Neue_Filiale_neuer_Filialpartner__c
					FROM Filialnetzaenderung__c
					WHERE Id = :filialnetzaenderung.Id
			];
			System.assertEquals( account.Id, filialnetzaenderung.Neue_Filiale_neuer_Filialpartner__c );
			
			List<Task> tasks = [
					SELECT
							Id,
							Aufgabenart__c,
							Priority,
							Status,
							ActivityDate,
							Auftraggeber__c,
							Auftragnehmer__c,
							Description,
							Erledigung_bis_zum__c,
							RecordTypeId,
							Typc__c,
							AccountId
					FROM Task
					WHERE AccountId = :account.Id OR AccountId = :previousAccount.Id
			];
			
			Integer counter = 0;
			for ( Task task : tasks ) {
				
				if ( task.Aufgabenart__c == 'Vorbereitung Up-/Downgrade Filialeinrichtung (Formatwechsel)' ) {
					System.assert( task.Priority == 'Hoch' );
					System.assert( task.Status == 'Nicht begonnen' );
					System.assert( account.Eroeffnungsdatum__c == Date.today().addYears( -1 ) );
					System.assertEquals( account.Eroeffnungsdatum__c.addDays( -56 ), task.ActivityDate );
					System.assert( task.Aufgabenart__c == 'Vorbereitung Up-/Downgrade Filialeinrichtung (Formatwechsel)' );
					System.assert( task.Auftraggeber__c == '3920/30 Außenstelle' );
					System.assertEquals( 'Vertriebsmanager', task.Auftragnehmer__c );
					System.assert( task.Erledigung_bis_zum__c == account.Eroeffnungsdatum__c.addDays( -49 ) );
					System.assert( task.RecordTypeId == Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
							.get( 'A_Aufgaben_automatische_Anlage' ).getRecordTypeId() );
					System.assert( task.Typc__c == 'Intern' );
					System.assert( task.Description.contains( 'Auslistung FDL - Einrichtungsdatei ergänzen und als ' +
							'Anhang anfügen (Link: https://mypm.lightning.force.com/sfc/#version?selectedDocumentId=' +
							'069240000026lQq). Nur Ausfertigung des Reiters \'Vorblatt\' & \'DP Shop u. ' +
							'Bestandsfilialen\' inkl. zusätzliche Angaben für die Beräumung im Freitextfeld.' ) );
					counter++;
				}
				if ( task.Aufgabenart__c == 'Bargeldentsorgung beauftragen' ) {
					System.assert( task.AccountId == previousAccount.Id );
					System.assert( task.Priority == 'Hoch' );
					System.assert( task.Status == 'Nicht begonnen' );
					System.assert( account.Eroeffnungsdatum__c == Date.today().addYears( -1 ) );
					System.assertEquals( account.Eroeffnungsdatum__c.addDays( -14 ), task.ActivityDate );
					System.assert( task.Aufgabenart__c == 'Bargeldentsorgung beauftragen' );
					System.assert( task.Auftraggeber__c == '3210 Kassenwesen' );
					System.assertEquals( 'Vertriebskoordinator VGL', task.Auftragnehmer__c );
					System.assert( task.Erledigung_bis_zum__c == account.Eroeffnungsdatum__c.addDays( -3 ) );
					System.assert( task.RecordTypeId == Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
							.get( 'A_Aufgaben_automatische_Anlage' ).getRecordTypeId() );
					System.assert( task.Typc__c == 'Intern' );
					System.assert( task.Description.contains( 'Downgrade in OZ 84 - Über Workflow 330 die ' +
							'Bargeldschlussentsorgung beauftragen' ) );
					counter++;
				}
				if ( task.Aufgabenart__c == 'Begleitung Up-/Downgrade' ) {
					System.assert( task.Priority == 'Hoch' );
					System.assert( task.Status == 'Nicht begonnen' );
					System.assert( account.Eroeffnungsdatum__c == Date.today().addYears( -1 ) );
					System.assertEquals( account.Eroeffnungsdatum__c.addDays( -1 ), task.ActivityDate );
					System.assert( task.Aufgabenart__c == 'Begleitung Up-/Downgrade' );
					System.assert( task.Auftraggeber__c == '3500 Betriebssteuerung' );
					System.assertEquals( 'Vertriebsmanager', task.Auftragnehmer__c );
					System.assert( task.Erledigung_bis_zum__c == account.Eroeffnungsdatum__c );
					System.assert( task.RecordTypeId == Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
							.get( 'A_Aufgaben_automatische_Anlage' ).getRecordTypeId() );
					System.assert( task.Typc__c == 'Besuch' );
					System.assert( task.Description.contains( 'Kassentechnische Abwicklung und Filialübernahme.  ' +
							'Entfernung/Entsorgung aller Postbankformblätter, Aushänge, Aufkleber etc. ' +
							'HINWEIS: Vollständige Rücksendung der Produkte und Neubelieferung' ) );
					counter++;
				}
				if ( task.Aufgabenart__c == 'Einrichtungsgespräch Partner-Filiale (ASt)' ) {
					System.assert( task.Priority == 'Hoch' );
					System.assert( task.Status == 'Nicht begonnen' );
					System.assert( account.Eroeffnungsdatum__c == Date.today().addYears( -1 ) );
					System.assertEquals( account.Eroeffnungsdatum__c.addDays( -35 ), task.ActivityDate );
					System.assert( task.Aufgabenart__c == 'Einrichtungsgespräch Partner-Filiale (ASt)' );
					System.assert( task.Auftraggeber__c == 'Vertriebskoordinator' );
					System.assertEquals( '3920/30 Aussenstelle', task.Auftragnehmer__c );
					System.assert( task.Erledigung_bis_zum__c == account.Eroeffnungsdatum__c.addDays( -28 ) );
					System.assert( task.RecordTypeId == Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
							.get( 'A_Aufgaben_automatische_Anlage' ).getRecordTypeId() );
					System.assert( task.Typc__c == 'Telefonat (Outbound)' );
					System.assert( task.Description.contains( 'Formatänderung 95 in 84: Anpassung der ' +
							'Filialausstattung (Postbank-Logo + Gefahrenmeldeanlage)' ) );
					counter++;
				}
			}
			System.assertEquals( 3, counter );
		}
	}
	
	/**
	 * @description 84 -> 95 Formatänderung
	 */
	@IsTest
	static void testConversion_84_To_95 () {
		
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			TriggerHandler.bypass( 'AccountTriggerHandler' );
			Account account = createAccount();
			Filialnetzaenderung__c filialnetzaenderung = new Filialnetzaenderung__c(
					Erledigungsdatum_FNAE__c = null,
					Zu_erwartender_Debitor__c = '12345',
					Schliessung_avisiert_fuer__c = Date.today(),
					Filiale_Filialpartner__c = account.Id
			);
			insert filialnetzaenderung;
			
			Test.startTest();
			account.GL__c = null;
			account.NL_Brief_Lookup__c = null;
			update account;
			TriggerHandler.clearBypass( 'AccountTriggerHandler' );
			account.GL__c = insertOrgEDP().Id;
			account.NL_Brief_Lookup__c = insertOrgEDP().Id;
			account.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
					.get( 'Filiale' ).getRecordTypeId();
			account.Aenderungsgrund_Vorgaengerfiliale__c = 'Ersatz für PB FC nach Upgrade';
			account.Netzentscheidung_Vorgaengerfiliale__c = 'Formatänderung genehmigt';
			account.Filialtyp_OZ_Vorgaengerfiliale__c = '84';
			account.Filialtyp_OZ__c = '95';
			account.Debitor__c = '12345';
			account.Filialart__c = '123';
			update account;
			Test.stopTest();
			
			account = [
					SELECT
							Id,
							Eroeffnungsdatum__c,
							Filialtyp_OZ__c
					FROM Account
					WHERE Id = :account.Id
					LIMIT 1
			];
			
			filialnetzaenderung = [
					SELECT
							Id,
							Neue_Filiale_neuer_Filialpartner__c
					FROM Filialnetzaenderung__c
					WHERE Id = :filialnetzaenderung.Id
			];
			System.assertEquals( account.Id, filialnetzaenderung.Neue_Filiale_neuer_Filialpartner__c );
			
			List<Task> tasks = [
					SELECT
							Id,
							Aufgabenart__c,
							Priority,
							Status,
							ActivityDate,
							Auftraggeber__c,
							Auftragnehmer__c,
							Description,
							Erledigung_bis_zum__c,
							RecordTypeId,
							Typc__c,
							AccountId
					FROM Task
					WHERE AccountId = :account.Id
			];
			
			Integer counter = 0;
			for ( Task task : tasks ) {
				
				if ( task.Aufgabenart__c == 'Vorbereitung Up-/Downgrade Filialeinrichtung (Formatwechsel)' ) {
					System.assert( task.Priority == 'Hoch' );
					System.assert( task.Status == 'Nicht begonnen' );
					System.assert( account.Eroeffnungsdatum__c == Date.today().addYears( -1 ) );
					System.assertEquals( account.Eroeffnungsdatum__c.addDays( -56 ), task.ActivityDate );
					System.assert( task.Aufgabenart__c == 'Vorbereitung Up-/Downgrade Filialeinrichtung (Formatwechsel)' );
					System.assert( task.Auftraggeber__c == '3920/30 Außenstelle' );
					System.assertEquals( 'Vertriebsmanager', task.Auftragnehmer__c );
					System.assert( task.Erledigung_bis_zum__c == account.Eroeffnungsdatum__c.addDays( -49 ) );
					System.assert( task.RecordTypeId == Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
							.get( 'A_Aufgaben_automatische_Anlage' ).getRecordTypeId() );
					System.assert( task.Typc__c == 'Intern' );
					System.assert( task.Description.contains( 'Ausfertigung des Reiters \'Vorblatt\' & \'Bestellliste ' +
							'OZ …\' in der Einrichtungsdatei und zusätzliche Angaben für die Beräumung im Freitextfeld.' ) );
					counter++;
				}
				if ( task.Aufgabenart__c == 'Bargeld bestellen' ) {
					System.assert( task.Priority == 'Hoch' );
					System.assert( task.Status == 'Nicht begonnen' );
					System.assert( account.Eroeffnungsdatum__c == Date.today().addYears( -1 ) );
					System.assertEquals( account.Eroeffnungsdatum__c.addDays( -14 ), task.ActivityDate );
					System.assert( task.Aufgabenart__c == 'Bargeld bestellen' );
					System.assert( task.Auftraggeber__c == '3120 Wertlogistik' );
					System.assertEquals( 'Vertriebskoordinator VGL', task.Auftragnehmer__c );
					System.assert( task.Erledigung_bis_zum__c == account.Eroeffnungsdatum__c.addDays( -3 ) );
					System.assert( task.RecordTypeId == Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
							.get( 'A_Aufgaben_automatische_Anlage' ).getRecordTypeId() );
					System.assert( task.Typc__c == 'Intern' );
					System.assert( task.Description.contains( 'Über Workflow 330 die Bargelderstausstattung bestellen' ) );
					counter++;
				}
				if ( task.Aufgabenart__c == 'Begleitung Up-/Downgrade' ) {
					System.assert( task.Priority == 'Hoch' );
					System.assert( task.Status == 'Nicht begonnen' );
					System.assert( account.Eroeffnungsdatum__c == Date.today().addYears( -1 ) );
					System.assertEquals( account.Eroeffnungsdatum__c.addDays( -1 ), task.ActivityDate );
					System.assert( task.Aufgabenart__c == 'Begleitung Up-/Downgrade' );
					System.assert( task.Auftraggeber__c == '3500 Betriebssteuerung' );
					System.assertEquals( 'Vertriebsmanager', task.Auftragnehmer__c );
					System.assert( task.Erledigung_bis_zum__c == account.Eroeffnungsdatum__c );
					System.assert( task.RecordTypeId == Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
							.get( 'A_Aufgaben_automatische_Anlage' ).getRecordTypeId() );
					System.assert( task.Typc__c == 'Besuch' );
					System.assert( task.Description.contains( 'Kassentechnische Abwicklung und Filialübernahme.  ' +
							'HINWEIS: Vollständige Rücksendung der Produkte und Neubelieferung' ) );
					counter++;
				}
				if ( task.Aufgabenart__c == 'Einrichtungsgespräch Partner-Filiale (ASt)' ) {
					System.assert( task.Priority == 'Hoch' );
					System.assert( task.Status == 'Nicht begonnen' );
					System.assert( account.Eroeffnungsdatum__c == Date.today().addYears( -1 ) );
					System.assertEquals( account.Eroeffnungsdatum__c.addDays( -35 ), task.ActivityDate );
					System.assert( task.Aufgabenart__c == 'Einrichtungsgespräch Partner-Filiale (ASt)' );
					System.assert( task.Auftraggeber__c == 'Vertriebskoordinator' );
					System.assertEquals( '3920/30 Aussenstelle', task.Auftragnehmer__c );
					System.assert( task.Erledigung_bis_zum__c == account.Eroeffnungsdatum__c.addDays( -28 ) );
					System.assert( task.RecordTypeId == Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
							.get( 'A_Aufgaben_automatische_Anlage' ).getRecordTypeId() );
					System.assert( task.Typc__c == 'Telefonat (Outbound)' );
					System.assert( task.Description.contains( 'Formatänderung 84 in 95: Anpassung der ' +
							'Filialausstattung (Postbank-Logo + Gefahrenmeldeanlage)' ) );
					counter++;
				}
				if ( task.Aufgabenart__c == 'OZ 95 - Besonderheiten bei der Einrichtung/Eröffnung' ) {
					System.assert( task.Priority == 'Hoch' );
					System.assert( task.Status == 'Nicht begonnen' );
					System.assert( account.Eroeffnungsdatum__c == Date.today().addYears( -1 ) );
					System.assertEquals( account.Eroeffnungsdatum__c.addDays( -7 ), task.ActivityDate );
					System.assert( task.Aufgabenart__c == 'OZ 95 - Besonderheiten bei der Einrichtung/Eröffnung' );
					System.assert( task.Auftraggeber__c == '3500 Betriebssteuerung' );
					System.assertEquals( 'Vertriebsmanager', task.Auftragnehmer__c );
					System.assert( task.Erledigung_bis_zum__c == account.Eroeffnungsdatum__c );
					System.assert( task.RecordTypeId == Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
							.get( 'A_Aufgaben_automatische_Anlage' ).getRecordTypeId() );
					System.assert( task.Typc__c == 'Besuch' );
					System.assert( task.Description.contains( 'Bitte vor EÖ einer OZ 95 die Betriebsanweisung ' +
							'Kassen (BAK siehe Link: https://mypm.lightning.force.com/sfc/#version?selectedDocumentId=' +
							'06924000002jzvG) ausstellen, auf den Alarmplan zur GEMA hinwiesen, den/die ' +
							'Vertragspartner und alle Mitarbeiter gemäß GwG auf Zuverlässigkeit prüfen und ' +
							'ALLE Mitarbeiter auf die notwendige Zertifizierung gem. BargeldPrüfV hinweisen. ' +
							'Weitere Details finden Sie in IPP.' ) );
					counter++;
				}
				if ( task.Aufgabenart__c == 'Ersteinweisung Filiale' ) {
					System.assert( task.Priority == 'Hoch' );
					System.assert( task.Status == 'Nicht begonnen' );
					System.assert( account.Eroeffnungsdatum__c == Date.today().addYears( -1 ) );
					System.assertEquals( account.Eroeffnungsdatum__c, task.ActivityDate );
					System.assert( task.Aufgabenart__c == 'Ersteinweisung Filiale' );
					System.assert( task.Auftraggeber__c == '3500 Betriebssteuerung' );
					System.assertEquals( 'Vertriebsmanager', task.Auftragnehmer__c );
					System.assert( task.Erledigung_bis_zum__c == account.Eroeffnungsdatum__c.addDays( 3 ) );
					System.assert( task.RecordTypeId == Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
							.get( 'A_Aufgaben_automatische_Anlage' ).getRecordTypeId() );
					System.assert( task.Typc__c == 'Besuch' );
					System.assert( task.Description.contains( 'Ersteinweisung Sortimentserweiterung (Dauer ca. 3 Tage)' ) );
					counter++;
				}
			}
			System.assertEquals( 5, counter );
		}
	}
	
	/**
	 * @description 84 -> 79/76 Formatänderung
	 */
	@IsTest
	static void testConversion_84_To_79_Or_76 () {
		
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			TriggerHandler.bypass( 'AccountTriggerHandler' );
			Account account = createAccount();
			Filialnetzaenderung__c filialnetzaenderung = new Filialnetzaenderung__c(
					Erledigungsdatum_FNAE__c = null,
					Zu_erwartender_Debitor__c = '12345',
					Schliessung_avisiert_fuer__c = Date.today(),
					Filiale_Filialpartner__c = account.Id
			);
			insert filialnetzaenderung;
			
			account.GL__c = null;
			account.NL_Brief_Lookup__c = null;
			update account;
			TriggerHandler.clearBypass( 'AccountTriggerHandler' );
			
			Test.startTest();
			account.GL__c = insertOrgEDP().Id;
			account.NL_Brief_Lookup__c = insertOrgEDP().Id;
			account.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
					.get( 'Filiale' ).getRecordTypeId();
			account.Aenderungsgrund_Vorgaengerfiliale__c = 'Ersatz für PB FC nach Upgrade';
			account.Netzentscheidung_Vorgaengerfiliale__c = 'Formatänderung genehmigt';
			account.Filialtyp_OZ_Vorgaengerfiliale__c = '84';
			account.Filialtyp_OZ__c = '76';
			account.Debitor__c = '12345';
			account.Filialart__c = '123';
			update account;
			Test.stopTest();
			
			account = [
					SELECT
							Id,
							Eroeffnungsdatum__c,
							Filialtyp_OZ__c
					FROM Account
					WHERE Id = :account.Id
					LIMIT 1
			];
			
			filialnetzaenderung = [
					SELECT
							Id,
							Neue_Filiale_neuer_Filialpartner__c
					FROM Filialnetzaenderung__c
					WHERE Id = :filialnetzaenderung.Id
			];
			System.assertEquals( account.Id, filialnetzaenderung.Neue_Filiale_neuer_Filialpartner__c );
			
			List<Task> tasks = [
					SELECT
							Id,
							Aufgabenart__c,
							Priority,
							Status,
							ActivityDate,
							Auftraggeber__c,
							Auftragnehmer__c,
							Description,
							Erledigung_bis_zum__c,
							RecordTypeId,
							Typc__c,
							AccountId
					FROM Task
					WHERE AccountId = :account.Id
			];
			
			Integer counter = 0;
			for ( Task task : tasks ) {
				
				if ( task.Aufgabenart__c == 'Vorbereitung Up-/Downgrade Filialeinrichtung (Formatwechsel)' ) {
					System.assert( task.Priority == 'Hoch' );
					System.assert( task.Status == 'Nicht begonnen' );
					System.assert( account.Eroeffnungsdatum__c == Date.today().addYears( -1 ) );
					System.assertEquals( account.Eroeffnungsdatum__c.addDays( -56 ), task.ActivityDate );
					System.assert( task.Aufgabenart__c == 'Vorbereitung Up-/Downgrade Filialeinrichtung (Formatwechsel)' );
					System.assert( task.Auftraggeber__c == '3920/30 Außenstelle' );
					System.assertEquals( 'Vertriebsmanager', task.Auftragnehmer__c );
					System.assert( task.Erledigung_bis_zum__c == account.Eroeffnungsdatum__c.addDays( -49 ) );
					System.assert( task.RecordTypeId == Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
							.get( 'A_Aufgaben_automatische_Anlage' ).getRecordTypeId() );
					System.assert( task.Typc__c == 'Intern' );
					System.assert( task.Description.contains( 'Ausfertigung des Reiters \'Vorblatt\' & \'Bestellliste ' +
							'OZ …\' in der Einrichtungsdatei und zusätzliche Angaben für die Beräumung im Freitextfeld.' ) );
					counter++;
				}
				if ( task.Aufgabenart__c == 'Begleitung Up-/Downgrade' ) {
					System.assert( task.Priority == 'Hoch' );
					System.assert( task.Status == 'Nicht begonnen' );
					System.assert( account.Eroeffnungsdatum__c == Date.today().addYears( -1 ) );
					System.assertEquals( account.Eroeffnungsdatum__c.addDays( -1 ), task.ActivityDate );
					System.assert( task.Aufgabenart__c == 'Begleitung Up-/Downgrade' );
					System.assert( task.Auftraggeber__c == '3500 Betriebssteuerung' );
					System.assertEquals( 'Vertriebsmanager', task.Auftragnehmer__c );
					System.assert( task.Erledigung_bis_zum__c == account.Eroeffnungsdatum__c );
					System.assert( task.RecordTypeId == Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
							.get( 'A_Aufgaben_automatische_Anlage' ).getRecordTypeId() );
					System.assert( task.Typc__c == 'Besuch' );
					System.assert( task.Description.contains( 'Kassentechnische Abwicklung und Filialübernahme.  ' +
							'HINWEIS: Vollständige Rücksendung der Produkte und Neubelieferung' ) );
					counter++;
				}
				if ( task.Aufgabenart__c == 'Einrichtungsgespräch Partner-Filiale (ASt)' ) {
					System.assert( task.Priority == 'Hoch' );
					System.assert( task.Status == 'Nicht begonnen' );
					System.assert( account.Eroeffnungsdatum__c == Date.today().addYears( -1 ) );
					System.assertEquals( account.Eroeffnungsdatum__c.addDays( -35 ), task.ActivityDate );
					System.assert( task.Aufgabenart__c == 'Einrichtungsgespräch Partner-Filiale (ASt)' );
					System.assert( task.Auftraggeber__c == 'Vertriebskoordinator' );
					System.assertEquals( '3920/30 Aussenstelle', task.Auftragnehmer__c );
					System.assert( task.Erledigung_bis_zum__c == account.Eroeffnungsdatum__c.addDays( -28 ) );
					System.assert( task.RecordTypeId == Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
							.get( 'A_Aufgaben_automatische_Anlage' ).getRecordTypeId() );
					System.assert( task.Typc__c == 'Telefonat (Outbound)' );
					System.assert( task.Description.contains( 'Formatänderung 84 in 79: Anpassung der ' +
							'Filialausstattung (z.B. Gefahrenmeldeanlage)' ) );
					counter++;
				}
				if ( task.Aufgabenart__c == 'Ersteinweisung Filiale' ) {
					System.assert( task.Priority == 'Hoch' );
					System.assert( task.Status == 'Nicht begonnen' );
					System.assert( account.Eroeffnungsdatum__c == Date.today().addYears( -1 ) );
					System.assertEquals( account.Eroeffnungsdatum__c, task.ActivityDate );
					System.assert( task.Aufgabenart__c == 'Ersteinweisung Filiale' );
					System.assert( task.Auftraggeber__c == '3500 Betriebssteuerung' );
					System.assertEquals( 'Vertriebsmanager', task.Auftragnehmer__c );
					System.assert( task.Erledigung_bis_zum__c == account.Eroeffnungsdatum__c.addDays( 1 ) );
					System.assert( task.RecordTypeId == Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
							.get( 'A_Aufgaben_automatische_Anlage' ).getRecordTypeId() );
					System.assert( task.Typc__c == 'Besuch' );
					System.assert( task.Description.contains( 'Ersteinweisung Sortimentserweiterung (Dauer ca. 1 Tag)' ) );
					counter++;
				}
			}
			System.assertEquals( 3, counter );
		}
	}
	
	/**
	 * @description 79/76 -> 84 Formatänderung
	 */
	@IsTest
	static void testConversion_79_Or_76_To_84 () {
		
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			TriggerHandler.bypass( 'AccountTriggerHandler' );
			Account account = createAccount();
			Filialnetzaenderung__c filialnetzaenderung = new Filialnetzaenderung__c(
					Erledigungsdatum_FNAE__c = null,
					Zu_erwartender_Debitor__c = '12345',
					Schliessung_avisiert_fuer__c = Date.today(),
					Filiale_Filialpartner__c = account.Id
			);
			insert filialnetzaenderung;
			
			Test.startTest();
			account.GL__c = null;
			update account;
			TriggerHandler.clearBypass( 'AccountTriggerHandler' );
			account.GL__c = insertOrgEDP().Id;
			account.NL_Brief_Lookup__c = insertOrgEDP().Id;
			account.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
					.get( 'Filiale' ).getRecordTypeId();
			account.Aenderungsgrund_Vorgaengerfiliale__c = 'Ersatz für PB FC nach Upgrade';
			account.Netzentscheidung_Vorgaengerfiliale__c = 'Formatänderung genehmigt';
			account.Filialtyp_OZ_Vorgaengerfiliale__c = '76';
			account.Filialtyp_OZ__c = '84';
			account.Debitor__c = '12345';
			account.Filialart__c = '123';
			update account;
			Test.stopTest();
			
			account = [
					SELECT
							Id,
							Eroeffnungsdatum__c,
							Filialtyp_OZ__c
					FROM Account
					WHERE Id = :account.Id
					LIMIT 1
			];
			
			filialnetzaenderung = [
					SELECT
							Id,
							Neue_Filiale_neuer_Filialpartner__c
					FROM Filialnetzaenderung__c
					WHERE Id = :filialnetzaenderung.Id
			];
			System.assertEquals( account.Id, filialnetzaenderung.Neue_Filiale_neuer_Filialpartner__c );
			
			List<Task> tasks = [
					SELECT
							Id,
							Aufgabenart__c,
							Priority,
							Status,
							ActivityDate,
							Auftraggeber__c,
							Auftragnehmer__c,
							Description,
							Erledigung_bis_zum__c,
							RecordTypeId,
							Typc__c,
							AccountId
					FROM Task
					WHERE AccountId = :account.Id
			];
			
			Integer counter = 0;
			for ( Task task : tasks ) {
				
				if ( task.Aufgabenart__c == 'Vorbereitung Up-/Downgrade Filialeinrichtung (Formatwechsel)' ) {
					System.assert( task.Priority == 'Hoch' );
					System.assert( task.Status == 'Nicht begonnen' );
					System.assert( account.Eroeffnungsdatum__c == Date.today().addYears( -1 ) );
					System.assertEquals( account.Eroeffnungsdatum__c.addDays( -56 ), task.ActivityDate );
					System.assert( task.Aufgabenart__c == 'Vorbereitung Up-/Downgrade Filialeinrichtung (Formatwechsel)' );
					System.assert( task.Auftraggeber__c == '3920/30 Außenstelle' );
					System.assertEquals( 'Vertriebsmanager', task.Auftragnehmer__c );
					System.assert( task.Erledigung_bis_zum__c == account.Eroeffnungsdatum__c.addDays( -49 ) );
					System.assert( task.RecordTypeId == Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
							.get( 'A_Aufgaben_automatische_Anlage' ).getRecordTypeId() );
					System.assert( task.Typc__c == 'Intern' );
					System.assert( task.Description.contains( 'Ausfertigung des Reiters \'Vorblatt\' & \'Bestellliste ' +
							'OZ …\' in der Einrichtungsdatei und zusätzliche Angaben für die Beräumung im Freitextfeld.' ) );
					counter++;
				}
				if ( task.Aufgabenart__c == 'Begleitung Up-/Downgrade' ) {
					System.assert( task.Priority == 'Hoch' );
					System.assert( task.Status == 'Nicht begonnen' );
					System.assert( account.Eroeffnungsdatum__c == Date.today().addYears( -1 ) );
					System.assertEquals( account.Eroeffnungsdatum__c.addDays( -1 ), task.ActivityDate );
					System.assert( task.Aufgabenart__c == 'Begleitung Up-/Downgrade' );
					System.assert( task.Auftraggeber__c == '3500 Betriebssteuerung' );
					System.assertEquals( 'Vertriebsmanager', task.Auftragnehmer__c );
					System.assert( task.Erledigung_bis_zum__c == account.Eroeffnungsdatum__c );
					System.assert( task.RecordTypeId == Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
							.get( 'A_Aufgaben_automatische_Anlage' ).getRecordTypeId() );
					System.assert( task.Typc__c == 'Besuch' );
					System.assert( task.Description.contains( 'Kassentechnische Abwicklung und Filialübernahme.  ' +
							'HINWEIS: Vollständige Rücksendung der Produkte und Neubelieferung' ) );
					counter++;
				}
				if ( task.Aufgabenart__c == 'Einrichtungsgespräch Partner-Filiale (ASt)' ) {
					System.assert( task.Priority == 'Hoch' );
					System.assert( task.Status == 'Nicht begonnen' );
					System.assert( account.Eroeffnungsdatum__c == Date.today().addYears( -1 ) );
					System.assertEquals( account.Eroeffnungsdatum__c.addDays( -35 ), task.ActivityDate );
					System.assert( task.Aufgabenart__c == 'Einrichtungsgespräch Partner-Filiale (ASt)' );
					System.assert( task.Auftraggeber__c == 'Vertriebskoordinator' );
					System.assertEquals( '3920/30 Aussenstelle', task.Auftragnehmer__c );
					System.assert( task.Erledigung_bis_zum__c == account.Eroeffnungsdatum__c.addDays( -28 ) );
					System.assert( task.RecordTypeId == Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
							.get( 'A_Aufgaben_automatische_Anlage' ).getRecordTypeId() );
					System.assert( task.Typc__c == 'Telefonat (Outbound)' );
					System.assert( task.Description.contains( 'Formatänderung 79 in 84: Anpassung der ' +
							'Filialausstattung (z.B. Gefahrenmeldeanlage)' ) );
					counter++;
				}
			}
			System.assertEquals( 2, counter );
		}
	}
	
	/**
	 * @description Aufgabe - Anlage Aufgaben bei Neuanlage OZ 95/76
	 */
	@IsTest
	static void testOZ95 () {
		
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			Test.startTest();
			Account account = ( Account ) TestFactory.createSObject(
					new Account(
							Vertragsbetreuende_Einheit__c = insertOrgEDP().Id,
							GL__c = insertOrgEDP().Id,
							NL_Brief_Lookup__c = insertOrgEDP().Id,
							RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
									.get( 'Filiale' ).getRecordTypeId(),
							Filialtyp_OZ__c = '95',
							Eroeffnungsdatum__c = Date.today()
					),
					true
			);
			Test.stopTest();
			
			List<Task> tasks = [
					SELECT
							Id,
							Aufgabenart__c,
							Priority,
							Status,
							ActivityDate,
							Auftraggeber__c,
							Auftragnehmer__c,
							Description,
							Erledigung_bis_zum__c,
							RecordTypeId,
							Typc__c,
							AccountId
					FROM Task
					WHERE AccountId = :account.Id
			];
			System.assertEquals( 7, tasks.size() );
			Integer counter = 0;
			for ( Task task : tasks ) {
				
				if ( task.Aufgabenart__c == 'OZ 95 - Besonderheiten bei der Einrichtung/Eröffnung' ) {
					System.assert( task.Priority == 'Hoch' );
					System.assert( task.Status == 'Nicht begonnen' );
					System.assertEquals( account.Eroeffnungsdatum__c.addDays( -7 ), task.ActivityDate );
					System.assert( task.Aufgabenart__c == 'OZ 95 - Besonderheiten bei der Einrichtung/Eröffnung' );
					System.assert( task.Auftraggeber__c == '3500 Betriebssteuerung' );
					System.assertEquals( 'Vertriebsmanager', task.Auftragnehmer__c );
					System.assert( task.Erledigung_bis_zum__c == account.Eroeffnungsdatum__c );
					System.assert( task.RecordTypeId == Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
							.get( 'A_Aufgaben_automatische_Anlage' ).getRecordTypeId() );
					System.assert( task.Typc__c == 'Besuch' );
					System.assert( task.Description.contains( 'Bitte vor EÖ einer OZ 95 die Betriebsanweisung Kassen ' +
							'(BAK siehe Link: https://mypm.lightning.force.com/sfc/#version?selectedDocumentId=06924000002jzvG) ' +
							'ausstellen, auf den Alarmplan zur Gefahrenmeldeanlage hinweisen,  den/die Vertragspartner ' +
							'und alle Mitarbeiter gemäß GwG auf Zuverlässigkeit prüfen, und ALLE Mitarbeiter auf die ' +
							'notwendige Zertifizierung gem. BargeldPrüfV hinweisen. Weitere Details finden Sie in IPP.' ) );
					counter++;
				}
				if ( task.Aufgabenart__c == 'Bargeld bestellen' ) {
					System.assert( task.Priority == 'Hoch' );
					System.assert( task.Status == 'Nicht begonnen' );
					System.assertEquals( account.Eroeffnungsdatum__c.addDays( -14 ), task.ActivityDate );
					System.assert( task.Aufgabenart__c == 'Bargeld bestellen' );
					System.assert( task.Auftraggeber__c == '3120 Wertlogistik' );
					System.assertEquals( 'Vertriebskoordinator VGL', task.Auftragnehmer__c );
					System.assert( task.Erledigung_bis_zum__c == account.Eroeffnungsdatum__c.addDays( -5 ) );
					System.assert( task.RecordTypeId == Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
							.get( 'A_Aufgaben_automatische_Anlage' ).getRecordTypeId() );
					System.assert( task.Typc__c == 'Intern' );
					System.assert( task.Description.contains( 'Über Workflow 330 die Bargelderstausstattung bestellen' ) );
					counter++;
				}
			}
			System.assertEquals( 2, counter );
		}
	}
	
	/**
	 * @description Aufgabe - Anlage Aufgaben bei Neuanlage OZ 95/76
	 */
	@IsTest
	static void testOZ76 () {
		
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			Test.startTest();
			Account account = ( Account ) TestFactory.createSObject(
					new Account(
							Vertragsbetreuende_Einheit__c = insertOrgEDP().Id,
							GL__c = insertOrgEDP().Id,
							NL_Brief_Lookup__c = insertOrgEDP().Id,
							RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
									.get( 'Filiale' ).getRecordTypeId(),
							Filialtyp_OZ__c = '76',
							Eroeffnungsdatum__c = Date.today()
					),
					true
			);
			Test.stopTest();
			
			List<Task> tasks = [
					SELECT
							Id,
							Aufgabenart__c,
							Priority,
							Status,
							ActivityDate,
							Auftraggeber__c,
							Auftragnehmer__c,
							Description,
							Erledigung_bis_zum__c,
							RecordTypeId,
							Typc__c,
							AccountId
					FROM Task
					WHERE AccountId = :account.Id
			];
			System.assertEquals( 6, tasks.size() );
			Integer counter = 0;
			for ( Task task : tasks ) {
				
				if ( task.Aufgabenart__c == 'Bargeld bestellen' ) {
					System.assert( task.Priority == 'Hoch' );
					System.assert( task.Status == 'Nicht begonnen' );
					System.assertEquals( account.Eroeffnungsdatum__c.addDays( -14 ), task.ActivityDate );
					System.assert( task.Aufgabenart__c == 'Bargeld bestellen' );
					System.assert( task.Auftraggeber__c == '3120 Wertlogistik' );
					System.assertEquals( 'Vertriebskoordinator VGL', task.Auftragnehmer__c );
					System.assert( task.Erledigung_bis_zum__c == account.Eroeffnungsdatum__c.addDays( -5 ) );
					System.assert( task.RecordTypeId == Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
							.get( 'A_Aufgaben_automatische_Anlage' ).getRecordTypeId() );
					System.assert( task.Typc__c == 'Intern' );
					System.assert( task.Description.contains( 'Über Workflow 330 die Bargelderstausstattung bestellen' ) );
					counter++;
				}
			}
			System.assertEquals( 1, counter );
		}
	}
	
	/**
	 * @description MYPM-962 Neue Aufgabenart "DP Shop Abstimmung Einrichtung und Werbemittel"
	 */
	@IsTest
	static void testNewDPSFiliale () {
		
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			Test.startTest();
			Account account = ( Account ) TestFactory.createSObject(
					new Account(
							RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
									.get( 'Filiale' ).getRecordTypeId(),
							GL__c = insertOrgEDP().Id,
							NL_Brief_Lookup__c = insertOrgEDP().Id,
							Filialtyp_OZ__c = null,
							Eroeffnungsdatum__c = Date.today(),
							Filialart__c = 'DPS-Interimslösung'
					),
					true
			);
			Test.stopTest();
			
			List<Task> tasks = [
					SELECT
							Id,
							Aufgabenart__c,
							Priority,
							Status,
							ActivityDate,
							Auftraggeber__c,
							Auftragnehmer__c,
							Description,
							Erledigung_bis_zum__c,
							RecordTypeId,
							Typc__c,
							AccountId
					FROM Task
					WHERE AccountId = :account.Id
			];
			System.assertEquals( 9, tasks.size() );
			Integer counter = 0;
			for ( Task task : tasks ) {
				
				if ( task.Aufgabenart__c == 'DP Shop Abstimmung Einrichtung & Werbemittel' ) {
					counter++;
				}
			}
			System.assertEquals( 1, counter );
		}
	}
	
	/**
	 * @description MYPM-963 Automatische Anlage Werbemittelpflege in FACTS
	 */
	@IsTest
	static void testWerbemittelpflegeFACTS () {
		
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			Account account = ( Account ) TestFactory.createSObject(
					new Account(
							RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
									.get( 'Filiale_Dummy' ).getRecordTypeId(),
							Filialtyp_OZ__c = '84',
							GL__c = insertOrgEDP().Id,
							NL_Brief_Lookup__c = insertOrgEDP().Id,
							Eroeffnungsdatum__c = Date.today()
					),
					true
			);
			
			Test.startTest();
			AccountBaseHandler.processedIds = new Set<Id>();
			account.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
					.get( 'Filiale' ).getRecordTypeId();
			update account;
			AccountBaseHandler.processedIds = new Set<Id>();
			account.ShippingCity = 'Test';
			update account;
			Test.stopTest();
			
			List<Task> tasks = [
					SELECT
							Id,
							Aufgabenart__c,
							Priority,
							Status,
							ActivityDate,
							Auftraggeber__c,
							Auftragnehmer__c,
							Description,
							Erledigung_bis_zum__c,
							RecordTypeId,
							Typc__c,
							AccountId
					FROM Task
					WHERE AccountId = :account.Id
			];
			System.assertEquals( 5, tasks.size() );
			Integer counter = 0;
			for ( Task task : tasks ) {
				
				if ( task.Aufgabenart__c == 'Werbemedienpflege in FACTS' ) {
					System.assert( task.Priority == 'Niedrig' );
					System.assert( task.Status == 'Nicht begonnen' );
					System.assertEquals( account.Eroeffnungsdatum__c, task.ActivityDate );
					System.assert( task.Aufgabenart__c == 'Werbemedienpflege in FACTS' );
					System.assert( task.Auftraggeber__c == '1T1 Field Sales' );
					System.assertEquals( 'Vertriebsmanager', task.Auftragnehmer__c );
					System.assert( task.Erledigung_bis_zum__c == account.Eroeffnungsdatum__c.addDays( 2 ) );
					System.assert( task.RecordTypeId == Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
							.get( 'A_Aufgaben_automatische_Anlage' ).getRecordTypeId() );
					System.assert( task.Typc__c == 'Intern' );
					System.assert( task.Description.contains( 'Überprüfung und ggf. ' +
							'Korrektur der in Facts hinterlegten Werbemedien' ) );
					counter++;
				}
			}
			System.assertEquals( 1, counter );
		}
	}
	
	/**
	 * @description [MYPM-1171] Afo # 105: Automatische Aufgabenanlage AYH-Call bei Neuanlage DHL Paketshop
	 */
	@IsTest
	static void testAreYouHappyCall () {
		
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			TriggerHandler.bypass( 'AccountTriggerHandler' );
			Account account = ( Account ) TestFactory.createSObject(
					new Account(
							RecordTypeId = RecordTypeState.DHL_PAKETSHOP,
							Filialtyp_OZ__c = '82',
							GL__c = insertOrgEDP().Id,
							NL_Brief_Lookup__c = insertOrgEDP().Id,
							Eroeffnungsdatum__c = Date.today(),
							Filialart__c = 'DHL-Paketshop'
					),
					true
			);
			TriggerHandler.clearBypass( 'AccountTriggerHandler' );
			
			Test.startTest();
			AccountBaseHandler.processedIds = new Set<Id>();
			account.NL_Brief_Lookup__c = insertOrgEDP().Id;
			update account;
			Test.stopTest();
			
			List<Task> tasks = [
					SELECT
							Id,
							Aufgabenart__c,
							Priority,
							Status,
							ActivityDate,
							Auftraggeber__c,
							Auftragnehmer__c,
							Description,
							Erledigung_bis_zum__c,
							RecordTypeId,
							Typc__c,
							AccountId
					FROM Task
					WHERE AccountId = :account.Id
					AND Aufgabenart__c = 'DHL Paketshop AreYouHappy-Call'
			];
			
			Integer counter = 0;
			for ( Task task : tasks ) {
				
				if ( task.Aufgabenart__c == 'DHL Paketshop AreYouHappy-Call' ) {
					System.assert( task.Priority == 'Hoch' );
					System.assert( task.Status == 'Nicht begonnen' );
					System.assertEquals( account.Eroeffnungsdatum__c.addDays( 21 ), task.ActivityDate );
					System.assert( task.Aufgabenart__c == 'DHL Paketshop AreYouHappy-Call' );
					System.assert( task.Auftraggeber__c == '5640 Team DHL Paketshop' );
					System.assertEquals( 'interServ Team DHL Paketshop', task.Auftragnehmer__c );
					System.assert( task.Erledigung_bis_zum__c == account.Eroeffnungsdatum__c.addDays( 28 ) );
					System.assert( task.RecordTypeId == Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
							.get( 'A_Aufgaben_automatische_Anlage' ).getRecordTypeId() );
					System.assert( task.Typc__c == 'Telefonat (Outbound)' );
					System.assert( task.Description.contains( 'AYH-Calls' ) );
					counter++;
				}
			}
			System.assertEquals( 1, counter );
		}
	}
	
	private static Account createAccount () {
		
		Account account = ( Account ) TestFactory.createSObject(
				new Account(
						Vertragsbetreuende_Einheit__c = insertOrgEDP().Id,
						GL__c = insertOrgEDP().Id,
						NL_Brief_Lookup__c = insertOrgEDP().Id,
						RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
								.get( 'Filiale_Dummy' ).getRecordTypeId(),
						Filialart__c = 'DHL-Paketshop'
				),
				true
		);
		return account;
	}
	
	private static OrgE_DP__c insertOrgEDP () {
		
		OrgE_DP__c orgEDP = new OrgE_DP__c(
				Aussenstellen_Ma__c = UserInfo.getUserId(),
				Koordinator__c = UserInfo.getUserId(),
				OrgE_DP_Name__c = String.valueOf( Math.random() ),
				MA_ASt_PuDS__c = UserInfo.getUserId(),
				MA_ASt_EK__c = UserInfo.getUserId()
		);
		insert orgEDP;
		return orgEDP;
	}
}