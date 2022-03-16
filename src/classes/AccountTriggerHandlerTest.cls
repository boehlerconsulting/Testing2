/**
 *@author       Mats Böhler
 *@created      08.04.2020
 *
 *
 *@description  Post_AccountTriggerHandlerTest
 *              MYPM-89
 *
 *
 *@changelog    08.04.2020 Mats Böhler  - Created
 *              
 * 
 */
@IsTest
private class AccountTriggerHandlerTest {

	private static final String FILIALPARTNER = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
			.get( 'Filialpartner' ).getRecordTypeId();
	private static final String PARTNERMITARBEITER = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName()
			.get( 'Partnermitarbeiter' ).getRecordTypeId();
	
	private static List<OrgE_DP__c> orgEDPS = new List<OrgE_DP__c>();
	
	@TestSetup static void setup () {
		insert new Rechte__c(
				SetupOwnerId = UserInfo.getOrganizationId(),
				darf_Inhaber_aller_Filialen_aendern__c = true
		);
	}
	
	private static void setupRequiredOrgEDPs () {
		List<String> orgEdpNames = new List<String> {
				'3920/30 Aussenstelle',
				'Vertriebsmanager',
				'3910 Immo/Instandh/Automation',
				'3540 DP Shop'
		};
		for ( String name : orgEdpNames ) {
			orgEDPS.add(
					new OrgE_DP__c(
							Aussenstellen_Ma__c = UserInfo.getUserId(),
							Koordinator__c = UserInfo.getUserId(),
							OrgE_DP_Name__c = name
					)
			);
		}
		insert orgEDPS;
	}
	
	@IsTest
	static void testBulkProcessing () {
		System.runAs( TestUser.create( TestUser.UserType.VL2001 ) ) {
			setupRequiredOrgEDPs();
			List<Account> accounts = createAccounts( 5 );
			List<Task> tasks = new List<Task>();
			for ( Account account : accounts ) {
				tasks.add( ( Task ) TestFactory.createSObject(
						new Task(
								Auftragnehmer__c = '5640 Team PoPS',
								WhatId = account.Id,
								Status = 'Nicht begonnen',
								ActivityDate = Date.today().addDays( 60 )
						),
						false
				) );
			}
			Filialnetzaenderung__c filialnetzaenderung = new Filialnetzaenderung__c(
					Erledigungsdatum_FNAE__c = null,
					Zu_erwartender_Debitor__c = '12345',
					Schliessung_avisiert_fuer__c = Date.today(),
					Filiale_Filialpartner__c = accounts[ 0 ].Id
			);
			insert filialnetzaenderung;
			Test.startTest();
			insert tasks;
			for ( Account account : accounts ) {
				accounts[ 0 ].Debitor__c = '12345';
				account.Schliessung_zum__c = Date.today();
			}
			update accounts;
			Test.stopTest();
		}
	}
	
	@IsTest
	static void testIsFiliale_DHL_PaketshopAnd_GL_Changed () {
		
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			setupRequiredOrgEDPs();
			List<Account> accounts = createAccounts( 1 );
			
			Test.startTest();
			AccountBaseHandler.processedIds = new Set<Id>();
			System.assert( orgEDPS[ 0 ].Id != null );
			System.assert( orgEDPS[ 0 ].Koordinator__c != null );
			
			for ( Account account : accounts ) {
				account.RecordTypeId =RecordTypeState.FILIALE;
				account.GL__c = orgEDPS[ 0 ].Id;
				account.NL_Brief_Lookup__c = orgEDPS[ 0 ].Id;
			}
			update accounts;
			Test.stopTest();
			
			System.assertEquals( orgEDPS[ 0 ].Koordinator__c, [
					SELECT
							Id,
							OwnerId
					FROM Account
					WHERE Id = :accounts[ 0 ].Id
			].OwnerId );
		}
	}
	
	@IsTest
	static void testIsPureFilialpartnerAndVertragsbetreuendeEinheitIsChanged () {
		
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			setupRequiredOrgEDPs();
			List<Account> accounts = createAccounts( 1 );
			
			Test.startTest();
			
			System.assert( orgEDPS[ 0 ].Id != null );
			System.assert( orgEDPS[ 0 ].Koordinator__c != null );
			
			for ( Account account : accounts ) {
				System.assert( account.Vertragsbetreuende_Einheit__c != null );
				
				account.RecordTypeId = FILIALPARTNER;
				account.Vertragsbetreuende_Einheit__c = orgEDPS[ 0 ].Id;
			}
			update accounts;
			Test.stopTest();
			
			System.assertEquals( orgEDPS[ 0 ].Koordinator__c, [
					SELECT
							Id,
							OwnerId
					FROM Account
					WHERE Id = :accounts[ 0 ].Id
			].OwnerId );
		}
	}
	
	@IsTest
	static void testDebitorAdded () {
		
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			TriggerHandler.bypass( 'AccountTriggerHandler' );
			List<Account> accounts = createAccounts( 1 );
			Filialnetzaenderung__c filialnetzaenderung = new Filialnetzaenderung__c(
					Erledigungsdatum_FNAE__c = null,
					Zu_erwartender_Debitor__c = '12345',
					Schliessung_avisiert_fuer__c = Date.today(),
					Filiale_Filialpartner__c = accounts[ 0 ].Id
			);
			insert filialnetzaenderung;
			TriggerHandler.clearBypass( 'AccountTriggerHandler' );
			Test.startTest();
			AccountBaseHandler.processedIds = new Set<Id>();
			for ( Account account : accounts ) {
				
				account.Debitor__c = '12345';
				account.RecordTypeId = RecordTypeState.DHL_PAKETSHOP;
			}
			update accounts;
			Test.stopTest();
			
			System.assertEquals( accounts[ 0 ].Id, [
					SELECT
							Id,
							Neue_Filiale_neuer_Filialpartner__c
					FROM Filialnetzaenderung__c
					WHERE Zu_erwartender_Debitor__c = '12345'
			].Neue_Filiale_neuer_Filialpartner__c );
		}
	}
	
	/**
	 * @process Account - Ast-Name bei Filialpartner füllen
	 *
	 * @criteria Account ist Filialpartner & Ast-Name leer
	 */
	@IsTest
	static void testSetAstNameForFilialpartner () {
		
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			Test.startTest();
			Account account = ( Account ) TestFactory.createSObject(
					new Account(
							RecordTypeId = FILIALPARTNER
					),
					true
			);
			Test.stopTest();
			
			System.assertEquals( 'Reiner Filialpartner', [
					SELECT
							Id,
							ASt_Name__c
					FROM Account
					WHERE Id = :account.Id
					LIMIT 1
			].ASt_Name__c );
		}
	}
	
	/**
	 * @process Aufgabe/Kontakt - Übertragung der Aufgaben/Kontakte bei Filialinhaberwechsel
	 *
	 * @criteria Filialinhaber/Eigentümer gewechselt??
	 */
	@IsTest
	static void testFilialinhaberEigentuemerGewechselt () {
		
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			Account account = ( Account ) TestFactory.createSObject(
					new Account(
							RecordTypeId = RecordTypeState.DHL_PAKETSHOP
					),
					true
			);
			insert new Contact(
					LastName = 'Test',
					Filiale_Partnermitarbeiter__c = account.Id,
					AccountId = account.Id,
					RecordTypeId = PARTNERMITARBEITER
			);
			createTask( 'Vertriebsmanager', account.Id );
			createTask( 'Vertriebsleiter', account.Id );
			
			User newOwner = TestUser.create( TestUser.UserType.VL2001 );
			
			Test.startTest();
			account.OwnerId = newOwner.Id;
			update account;
			Test.stopTest();
			
			List<Contact> contacts = [
					SELECT
							Id,
							OwnerId,
							Filiale_Partnermitarbeiter__c
					FROM Contact
					WHERE Filiale_Partnermitarbeiter__c = :account.Id
			];
			
			List<Task> tasks = [
					SELECT
							Id,
							OwnerId,
							Auftragnehmer__c,
							Status
					FROM Task
					WHERE AccountId = :account.Id
			];
			Integer counter = 0;
			for ( Contact contact : contacts ) {
				System.assertEquals( newOwner.Id, contact.OwnerId );
				counter++;
			}
			System.assertEquals( 1, counter );
			for ( Task task : tasks ) {
				if ( task.Status == 'Nicht begonnen'
						&& task.Auftragnehmer__c == 'Vertriebsmanager' ) {
					
					System.assertEquals( newOwner.Id, task.OwnerId );
					counter++;
				}
				else if ( task.Status == 'Nicht begonnen'
						&& task.Auftragnehmer__c == 'Vertriebsleiter' ) {
					counter++;
				}
			}
			System.assertEquals( 3, counter );
		}
	}
	
	/**
	 * @process Account - Vertragsbetreuende OrgE setzen + Link Partnerakte
	 *
	 * @criteria Vertragspartner neu bzw. geändert
	 */
	@IsTest
	static void testVertragspartnerNewOrChanged () {
		
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			OrgE_DP__c orgEDP = insertOrgEDP();
			Account betreiber = ( Account ) TestFactory.createSObject(
					new Account(
							RecordTypeId =RecordTypeState.FILIALE,
							Vertragsbetreuende_Einheit__c = orgEDP.Id,
							Debitor__c = '12345'
					),
					false
			);
			insert betreiber;
			System.assertEquals( orgEDP.Id, [
					SELECT
							Id,
							Vertragsbetreuende_Einheit__c
					FROM Account
					WHERE Id = :betreiber.Id
					LIMIT 1
			].Vertragsbetreuende_Einheit__c );
			
			Test.startTest();
			Account account = ( Account ) TestFactory.createSObject(
					new Account(
							RecordTypeId =RecordTypeState.FILIALE,
							Betreiber__c = betreiber.Id,
							VertragspartnerId__c = betreiber.Debitor__c
					),
					true
			);
			Test.stopTest();
			System.assertEquals( betreiber.Id, [
					SELECT
							Id,
							Betreiber__c
					FROM Account
					WHERE Id = :account.Id
					LIMIT 1
			].Betreiber__c );
			System.assertEquals( betreiber.Vertragsbetreuende_Einheit__c, [
					SELECT
							Id,
							Vertragsbetreuende_Einheit__c
					FROM Account
					WHERE Id = :account.Id
					LIMIT 1
			].Vertragsbetreuende_Einheit__c );
		}
	}
	
	/**
	 * @process Account - Vertragsbetreuende OrgE setzen + Link Partnerakte
	 *
	 * @criteria Betreiber neu gesetzt bei bestehender Filiale
	 */
	@IsTest
	static void testNewBetreiberExistingFiliale () {
		
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			OrgE_DP__c orgEDP = insertOrgEDP();
			Account betreiber = ( Account ) TestFactory.createSObject(
					new Account(
							RecordTypeId =RecordTypeState.FILIALE,
							Vertragsbetreuende_Einheit__c = orgEDP.Id,
							Debitor__c = '12345'
					),
					false
			);
			insert betreiber;
			System.assertEquals( orgEDP.Id, [
					SELECT
							Id,
							Vertragsbetreuende_Einheit__c
					FROM Account
					WHERE Id = :betreiber.Id
					LIMIT 1
			].Vertragsbetreuende_Einheit__c );
			AccountBaseHandler.processedIds = new Set<Id>();
			Account account = ( Account ) TestFactory.createSObject(
					new Account(
							RecordTypeId = RecordTypeState.FILIALE,
							Name = 'ICH'
					),
					true
			);
			System.assertEquals( null, [
					SELECT
							Id,
							Vertragsbetreuende_Einheit__c
					FROM Account
					WHERE Id = :account.Id
					LIMIT 1
			].Vertragsbetreuende_Einheit__c );
			
			Test.startTest();
			AccountBaseHandler.processedIds = new Set<Id>();
			account.Betreiber__c = betreiber.Id;
			account.VertragspartnerId__c = '12345';
			update account;
			Test.stopTest();
			
			System.assertEquals( betreiber.Vertragsbetreuende_Einheit__c, [
					SELECT
							Id,
							Vertragsbetreuende_Einheit__c
					FROM Account
					WHERE Id = :account.Id
					LIMIT 1
			].Vertragsbetreuende_Einheit__c );
		}
	}
	
	/**
	 * @process Account - Vertragsbetreuende OrgE setzen + Link Partnerakte
	 *
	 * @criteria VGL vorhanden
	 */
	@IsTest
	static void testVGLVorhanden () {
		
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			OrgE_DP__c orgEDP = insertOrgEDP();
			
			Test.startTest();
			Account account = ( Account ) TestFactory.createSObject(
					new Account(
							RecordTypeId =RecordTypeState.FILIALE,
							GL__c = orgEDP.Id,
							NL_Brief_Lookup__c = orgEDP.Id
					),
					true
			);
			Test.stopTest();
			
			System.assertEquals( account.GL__c, [
					SELECT
							Id,
							Vertragsbetreuende_Einheit__c
					FROM Account
					WHERE Id = :account.Id
					LIMIT 1
			].Vertragsbetreuende_Einheit__c );
		}
	}
	
	/**
	 * @process Account - Vertragsbetreuende OrgE setzen + Link Partnerakte
	 *
	 * @criteria Vertrags.Einheit geändert
	 */
	@IsTest
	static void testVertragEinheitGeaendert () {
		
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			TriggerHandler.bypass( 'AccountTriggerHandler' );
			
			OrgE_DP__c orgEDP = insertOrgEDP();
			Account betreiber = ( Account ) TestFactory.createSObject(
					new Account(
							RecordTypeId =RecordTypeState.FILIALE,
							Vertragsbetreuende_Einheit__c = orgEDP.Id,
							Debitor__c = '12345'
					),
					true
			);
			Account account = ( Account ) TestFactory.createSObject(
					new Account(
							RecordTypeId =RecordTypeState.FILIALE,
							Betreiber__c = betreiber.Id,
							VertragspartnerId__c = betreiber.Debitor__c
					),
					true
			);
			TriggerHandler.clearBypass( 'AccountTriggerHandler' );
			Test.startTest();
			OrgE_DP__c newOrgEDP = insertOrgEDP();
			AccountBaseHandler.processedIds = new Set<Id>();
			betreiber.Vertragsbetreuende_Einheit__c = newOrgEDP.Id;
			update betreiber;
			Test.stopTest();
			
			System.assertEquals( newOrgEDP.Id, [
					SELECT
							Id,
							Vertragsbetreuende_Einheit__c
					FROM Account
					WHERE Id = :account.Id
					LIMIT 1
			].Vertragsbetreuende_Einheit__c );
		}
	}
	
	/**
	 * @process Aufgaben/FNÄ - Autom. Zurückziehen nicht geschlossener Aufgaben bei schließenden Filialen und vice versa
	 *
	 * @criteria Schließdatum gesetzt und größer EÖ
	 */
	@IsTest
	static void testSchliessungsdatumGesetztGroesserEroeffnungsdatum () {
		
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			Account account = ( Account ) TestFactory.createSObject(
					new Account(
							RecordTypeId =RecordTypeState.FILIALE
					),
					true
			);
			Task task = ( Task ) TestFactory.createSObject(
					new Task(
							WhatId = account.Id,
							ActivityDate = Date.today().addDays( 8 ),
							Status = 'Nicht begonnen',
							RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
									.get( 'A_Aufgaben_automatische_Anlage' ).getRecordTypeId()
					),
					true
			);
			Test.startTest();
			account.Schliessung_zum__c = Date.today().addDays( 7 );
			update account;
			Test.stopTest();
			
			task = [
					SELECT
							Id,
							Status,
							Erledigungsvermerk__c
					FROM Task
					WHERE Id = :task.Id
					LIMIT 1
			];
			
			System.assertEquals( '"Die Aufgabe ist erst nach Schließung fällig bzw. die Filiale wird nicht eröffnet."', task.Erledigungsvermerk__c );
			System.assertEquals( 'Zurückgezogen (Nur AG)', task.Status );
		}
	}
	
	/**
	 * @process Aufgaben/FNÄ - Autom. Zurückziehen nicht geschlossener Aufgaben bei schließenden Filialen und vice versa
	 *
	 * @criteria Schließdatum gesetzt und gleich EÖ
	 */
	@IsTest
	static void testSchliessungsdatumGesetztGleichEroeffnungsdatum () {
		
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			Account account = ( Account ) TestFactory.createSObject(
					new Account(
							RecordTypeId =RecordTypeState.FILIALE,
							Eroeffnungsdatum__c = Date.today()
					),
					true
			);
			Task task = ( Task ) TestFactory.createSObject(
					new Task(
							WhatId = account.Id,
							ActivityDate = Date.today(),
							Status = 'Nicht begonnen',
							RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
									.get( 'A_Aufgaben_automatische_Anlage' ).getRecordTypeId()
					),
					true
			);
			Test.startTest();
			account.Schliessung_zum__c = Date.today();
			update account;
			Test.stopTest();
			
			task = [
					SELECT
							Id,
							Status,
							Erledigungsvermerk__c
					FROM Task
					WHERE Id = :task.Id
					LIMIT 1
			];
			
			System.assertEquals( '"Die Aufgabe ist erst nach Schließung fällig bzw. die Filiale wird nicht eröffnet."', task.Erledigungsvermerk__c );
			System.assertEquals( 'Zurückgezogen (Nur AG)', task.Status );
		}
	}
	
	/**
	 * @process Aufgaben/FNÄ - Autom. Zurückziehen nicht geschlossener Aufgaben bei schließenden Filialen und vice versa
	 *
	 * @criteria Filiale bleibt am Netz
	 */
	@IsTest
	static void testFilialeBleibtAmNetz () {
		
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			TriggerHandler.bypass( 'AccountTriggerHandler' );
			
			Account account = ( Account ) TestFactory.createSObject(
					new Account(
							RecordTypeId =RecordTypeState.FILIALE,
							Eroeffnungsdatum__c = Date.today()
					),
					true
			);
			Task task = ( Task ) TestFactory.createSObject(
					new Task(
							WhatId = account.Id,
							ActivityDate = Date.today(),
							Status = 'Zurückgezogen (Nur AG)',
							RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
									.get( 'A_Aufgaben_automatische_Anlage' ).getRecordTypeId(),
							Erledigungsvermerk__c = '"Die Aufgabe ist erst nach Schließung ' +
									'fällig bzw. die Filiale wird nicht eröffnet."'
					),
					true
			);
			TriggerHandler.clearBypass( 'AccountTriggerHandler' );
			Test.startTest();
			account.Schliessung_zum__c = Date.today();
			update account;
			AccountBaseHandler.processedIds = new Set<Id>();
			task = [
					SELECT
							Id,
							Status,
							Erledigungsvermerk__c
					FROM Task
					WHERE Id = :task.Id
					LIMIT 1
			];
			
			System.assertEquals( '"Die Aufgabe ist erst nach Schließung fällig bzw. die Filiale wird nicht eröffnet."', task.Erledigungsvermerk__c );
			System.assertEquals( 'Zurückgezogen (Nur AG)', task.Status );
			account.Schliessung_zum__c = null;
			update account;
			Test.stopTest();
			
			task = [
					SELECT
							Id,
							Status,
							Erledigungsvermerk__c
					FROM Task
					WHERE Id = :task.Id
					LIMIT 1
			];
			
			System.assertEquals( null, task.Erledigungsvermerk__c );
			System.assertEquals( 'Nicht begonnen', task.Status );
		}
	}
	
	/**
	 * @process Aufgabe - autm. Anlage im lfd. Betrieb einer Filiale
	 *
	 * @criteria DHL Paketshop ohne PoPS eröffnet
	 */
	@IsTest
	static void testDHLPaketshopOhnePoPSEroeffnet () {
		
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			TriggerHandler.bypass( 'AccountTriggerHandler' );
			Account account = ( Account ) TestFactory.createSObject(
					new Account(
							Vertragsbetreuende_Einheit__c = insertOrgEDP().Id,
							GL__c = insertOrgEDP().Id,
							NL_Brief_Lookup__c = insertOrgEDP().Id,
							RecordTypeId = RecordTypeState.DHL_PAKETSHOP,
							Filialart__c = 'DHL-Paketshop',
							ASt_Name__c = 'Test',
							Betriebsstatus__c = 'vorEröffnung'
					),
					true
			);
			TriggerHandler.clearBypass( 'AccountTriggerHandler' );
			
			Test.startTest();
			AccountBaseHandler.processedIds = new Set<Id>();
			account.Betriebsstatus__c = 'geöffnet';
			account.PoPS_Kundennummer__c = null;
			account.PoPS_Kundennummer_Sammelbesteller__c = null;
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
				if ( task.Aufgabenart__c == 'PoPS Akquise' ) {
					System.assert( task.Priority == 'Hoch' );
					System.assert( task.Status == 'Nicht begonnen' );
					System.assert( account.Eroeffnungsdatum__c == Date.today().addYears( -1 ) );
					System.assertEquals( Date.today(), task.ActivityDate );
					System.assert( task.Aufgabenart__c == 'PoPS Akquise' );
					System.assert( task.Auftraggeber__c == '1T1 Field Sales' );
					System.assert( task.Erledigung_bis_zum__c == Date.today().addDays( 21 ) );
					System.assert( task.RecordTypeId == Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
							.get( 'Aufgaben_PoPS' ).getRecordTypeId() );
					System.assert( task.Typc__c == 'Besuch' );
					System.assert( task.Description.contains( 'Neue/n DHL Paketshop-Partner/in für den Post-Partner-Shop ' +
							'akquirieren. Die erfolgreiche Akquise löst autom. den Registrierungsprozess aus. ' +
							'Bei erfolgloser Akquise bitte Grund angeben.' ) );
					counter++;
				}
			}
			System.assert( counter == 1 );
		}
	}
	
	/**
	 * @process Aufgabe - autm. Anlage im lfd. Betrieb einer Filiale
	 *
	 * @criteria Partnerjubiläum erreicht
	 */
	@IsTest
	static void testPartnerjubilaeumErreicht () {
		
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			TriggerHandler.bypass( 'AccountTriggerHandler' );
			Account account = ( Account ) TestFactory.createSObject(
					new Account(
							Vertragsbetreuende_Einheit__c = insertOrgEDP().Id,
							GL__c = insertOrgEDP().Id,
							NL_Brief_Lookup__c = insertOrgEDP().Id,
							RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
									.get( 'Filiale' ).getRecordTypeId(),
							Filialart__c = 'DHL-Paketshop',
							ASt_Name__c = 'Test',
							Betriebsstatus__c = 'geöffnet'
					),
					true
			);
			TriggerHandler.clearBypass( 'AccountTriggerHandler' );
			
			Test.startTest();
			AccountBaseHandler.processedIds = new Set<Id>();
			account.EOE_Datum_Partnerjubilaeum__c = Date.today().addYears( -15 ).addDays( 55 );
			update account;
			
			Test.stopTest();
			
			account = [
					SELECT
							Id,
							Eroeffnungsdatum__c,
							Jahr_letzte_Anlage_Partnerjubilaeum__c
					FROM Account
					WHERE Id = :account.Id
					LIMIT 1
			];
			
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
				if ( task.Aufgabenart__c == 'Durchführung Partnerjubiläum' ) {
					System.assert( task.Priority == 'Mittel' );
					System.assert( task.Status == 'Nicht begonnen' );
					System.assert( account.Eroeffnungsdatum__c == Date.today().addYears( -1 ) );
					System.assert( account.Jahr_letzte_Anlage_Partnerjubilaeum__c == Date.today().year() );
					System.assertEquals( Date.today().addDays( 14 ), task.ActivityDate );
					System.assert( task.Aufgabenart__c == 'Durchführung Partnerjubiläum' );
					System.assert( task.Auftraggeber__c == '1T1 Field Sales' );
					System.assert( task.Auftragnehmer__c == 'Vertriebskoordinator VGL' );
					System.assert( task.RecordTypeId == Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
							.get( 'A_Aufgaben_automatische_Anlage' ).getRecordTypeId() );
					System.assert( task.Typc__c == 'Intern' );
					System.assert( task.Description.contains( 'hat der Partner sein Jubiläum. Bitte stellen Sie sicher, ' +
							'dass alle Jubiläumsunterlagen (Urkunde, Briefmarkenbögen, Fensteraufkleber, ' +
							'Überreichmappe und Rahmen) vorliegen, die Urkunde von der/dem VL unterschrieben wird ' +
							'und koordinieren Sie die Übergabe an den Partner.' ) );
					counter++;
				}
			}
			System.assert( counter == 1 );
		}
	}
	
	/**
	 * @process Aufgabe - autm. Anlage im lfd. Betrieb einer Filiale
	 *
	 * @criteria E-Mail an ZORA und 3600
	 */
	@IsTest
	static void testEMailAnZORAUnd3600 () {
		
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			TriggerHandler.bypass( 'AccountTriggerHandler' );
			
			Lead lead = ( Lead ) TestFactory.createSObject(
					new Lead(
							RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName()
									.get( 'Packstation' ).getRecordTypeId(),
							Email = 'test@test.de',
							FirstName = 'firstName',
							LastName = 'lastName',
							Company = 'Company'
					),
					true
			);
			
			Account account = ( Account ) TestFactory.createSObject(
					new Account(
							Vertragsbetreuende_Einheit__c = insertOrgEDP().Id,
							GL__c = insertOrgEDP().Id,
							RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
									.get( 'Filiale' ).getRecordTypeId(),
							Filialart__c = 'DHL-Paketshop',
							ASt_Name__c = 'Test',
							Lead__c = lead.Id,
							Betriebsstatus__c = 'vorFACTS-Anlage'
					),
					true
			);
			
			TriggerHandler.clearBypass( 'AccountTriggerHandler' );
			
			Test.startTest();
			account.Betriebsstatus__c = 'vorEröffnung';
			account.NL_Brief_Lookup__c = insertOrgEDP().Id;
			update account;
			Test.stopTest();
		}
	}
	
	@IsTest
	static void testSetKundenrelevanzklasse_Update () {
		
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			Account accoVoFi = ( Account ) TestFactory.createSObject(
					new Account(
							RecordTypeId =RecordTypeState.FILIALE,
							Kundenrelevanz_Klasse__c = 'KK1'
					),
					true
			);
			
			Account accoFi = ( Account ) TestFactory.createSObject(
					new Account(
							RecordTypeId =RecordTypeState.FILIALE
					),
					true
			);
			
			Test.startTest();
			accoFi.Vorgaengerfiliale__c = accoVoFi.Id;
			update accoFi;
			Test.stopTest();
			
			accoFi = [ SELECT Id, Kundenrelevanz_Klasse__c FROM Account WHERE Id = :accoFi.Id ];
			
			System.assertEquals( accoFi.Kundenrelevanz_Klasse__c, accoVoFi.Kundenrelevanz_Klasse__c );
		
		}
	}
	
	
	@IsTest
	static void testSetKundenrelevanzklasse_Insert () {
		
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			Account accoVoFi = ( Account ) TestFactory.createSObject(
					new Account(
							RecordTypeId =RecordTypeState.FILIALE,
							Kundenrelevanz_Klasse__c = 'KK1'
					),
					true
			);
			
			Test.startTest();
			Account accoFi = ( Account ) TestFactory.createSObject(
					new Account(
							RecordTypeId =RecordTypeState.FILIALE,
							Vorgaengerfiliale__c = accoVoFi.Id
					),
					true
			);
			Test.stopTest();
			
			accoFi = [ SELECT Id, Kundenrelevanz_Klasse__c FROM Account WHERE Id = :accoFi.Id ];
			
			System.assertEquals( accoFi.Kundenrelevanz_Klasse__c, accoVoFi.Kundenrelevanz_Klasse__c );
		
		}
	}
	
	/**
	 * @process [MYPM-1652] Autom. Erstellung PODIDs
	 */
	@IsTest
	static void testPODIDAccountDeletion () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
				
				PODID__c podid = new PODID__c(
						Name = '64653111',
						Wert__c = '64653111',
						Ort__c = 'Lorsch'
				);
				insert podid;
				
				Account account = ( Account ) TestFactory.createSObject(
						new Account(
								RecordTypeId = RecordTypeState.PACKSTATION,
								Kundenrelevanz_Klasse__c = 'KK1',
								PODID__c = podid.Id
						),
						true
				);
				
				Test.startTest();
				delete account;
				Test.stopTest();
				
				podid = [ SELECT Id, Status__c, Anmerkung__c FROM PODID__c LIMIT 1 ];
				
				System.assertEquals( 'Gelöscht', podid.Status__c );
				System.assert( podid.Anmerkung__c.contains( 'entfernt' ) );
			}
		}
	}
	
	/**
	 * @process [MYPM-1652] Autom. Erstellung PODIDs
	 */
	@IsTest
	static void testPODIDRemoval () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			PODID__c podid = new PODID__c(
					Name = '64653111',
					Wert__c = '64653111',
					Ort__c = 'Lorsch'
			);
			insert podid;
			
			Account account = ( Account ) TestFactory.createSObject(
					new Account(
							RecordTypeId = RecordTypeState.PACKSTATION,
							Kundenrelevanz_Klasse__c = 'KK1',
							PODID__c = podid.Id
					),
					true
			);
			
			Test.startTest();
			account.PODID__c = null;
			update account;
			Test.stopTest();
			
			podid = [ SELECT Id, Status__c, Anmerkung__c FROM PODID__c LIMIT 1 ];
			
			System.assertEquals( 'Gelöscht', podid.Status__c );
			System.assert( podid.Anmerkung__c.contains( 'entfernt' ) );
		}
	}
	
	/**
	 * @process [MYPM-1718] Aufgabenanlage auf dem Account [2] - Kündigung
	 */
	@IsTest
	static void testAddTaskKuendigungsrueckgewinnung () {
		
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			TriggerHandler.bypass( 'AccountTriggerHandler' );
			Account account = ( Account ) TestFactory.createSObject(
					new Account(
							RecordTypeId =RecordTypeState.PACKSTATION,
							Kundenrelevanz_Klasse__c = 'KK1'
					),
					true
			);
			TriggerHandler.clearAllBypasses();
			
			Test.startTest();
			account.Bestandsmassnahme__c = 'Kündigung';
			account.Rueckgewinnung_erforderlich__c = true;
			update account;
			Test.stopTest();
			
			System.assertEquals( 1, [
					SELECT
							Id
					FROM Task
					WHERE Aufgabenart__c = 'Kündigungsrückgewinnung Pack-/Poststation'
			].size() );
		}
	}
	
	/**
	 * @process [MYPM-1735] Aufgabenanlage auf dem Account [1] - Entlastung
	 */
	@IsTest
	static void testAddTaskEntlastungPackstation () {
		
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			TriggerHandler.bypass( 'AccountTriggerHandler' );
			Account account = ( Account ) TestFactory.createSObject(
					new Account(
							RecordTypeId = RecordTypeState.PACKSTATION,
							Kundenrelevanz_Klasse__c = 'KK1',
							Ziel_Fachanzahl__c = 100,
							Ziel_Format__c = 'Packstation'
					),
					true
			);
			TriggerHandler.clearAllBypasses();
			
			Test.startTest();
			account.Bestandsmassnahme__c = 'Entlastung (Erweiterung / Austausch)';
			update account;
			Test.stopTest();
			
			List<Task> tasks = [
					SELECT
							Id,
							Description
					FROM Task
					WHERE Aufgabenart__c = 'Akquiseauftrag Entlastung Packstation'
			];
			System.assertEquals( 1, tasks.size() );
		}
	
	}
	
	/**
	 * @process [MYPM-1838] Aufgabenanlage auf dem Account- Formatwechsel
	 */
	@IsTest
	static void testAddTaskFormatwechsel () {
		
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			TriggerHandler.bypass( 'AccountTriggerHandler' );
			Account account = ( Account ) TestFactory.createSObject(
					new Account(
							RecordTypeId = RecordTypeState.PACKSTATION,
							Kundenrelevanz_Klasse__c = 'KK1',
							Ziel_Fachanzahl__c = 100,
							Ziel_Format__c = 'Packstation'
					),
					true
			);
			TriggerHandler.clearAllBypasses();
			
			Test.startTest();
			account.Bestandsmassnahme__c = 'Formatwechsel (Pack-/Poststation)';
			update account;
			Test.stopTest();
			
			List<Task> tasks = [
					SELECT
							Id,
							Description
					FROM Task
					WHERE Aufgabenart__c = 'Formatwechsel (Pack-/Poststation)'
			];
			System.assertEquals( 1, tasks.size() );
		}
	
	}
	
	/**
	 * @process [MYPM-1842] Anpassungen für Bestandsmaßnahme "Kündigung zurückgezogen"
	 */
	@IsTest
	static void testDeactivateKuendigungAbbauLeads () {
		
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			TriggerHandler.bypass( 'AccountTriggerHandler' );
			Account account = ( Account ) TestFactory.createSObject(
					new Account(
							RecordTypeId =RecordTypeState.PACKSTATION
					),
					true
			);
			TriggerHandler.clearAllBypasses();
			
			Test.startTest();
			account.Bestandsmassnahme__c = 'Kündigung';
			update account;
			AccountBaseHandler.processedIds = new Set<Id>();
			account.Kuendigung_durch__c = 'Kündigung zurückgezogen';
			update account;
			Test.stopTest();
			
			List<Lead> leads = [
					SELECT
							Id,
							Hinweis_AO__c
					FROM Lead
					WHERE Filiale_Filialpartner__c = :account.Id
					AND Bestandsmassnahme__c = 'Kündigung - Abbau'
			];
			System.assertEquals( 1, leads.size() );
			System.assertEquals( 'Kündigung wurde zurückgezogen', leads[ 0 ].Hinweis_AO__c );
		}
	}
	
	@IsTest
	static void testLookupUpdate () {
		Post_TestTools.erzeugeRechteEinstellungenAdmin( UserInfo.getUserId() );
		List< Account > vertragspartner = new List< Account >();
		
		Account vertragspartner1 = createFiliale( 'Filiale', 'Deb-2', Date.today() - 30 );
		vertragspartner.add( vertragspartner1 );
		
		Account vertragspartner2 = createFiliale( 'Filiale', 'Deb-3', Date.today() - 15 );
		vertragspartner.add( vertragspartner2 );
		
		insert( vertragspartner );
		
		Test.startTest();
		
		Account filiale = createFiliale( 'Filiale', 'Deb-1', Date.today() );
		filiale.VertragspartnerId__c = vertragspartner2.Debitor__c;
		filiale.Immobiliengeber__c = vertragspartner1.Id;
		filiale.Lieferant1Id__c = vertragspartner1.Debitor__c;
		insert( filiale );
		
		Test.stopTest();
		
		filiale = [
				SELECT
						Id,
						Betreiber__c,
						Immobiliengeber__c,
						Lieferant_1__c,
						Lieferant_2__c,
						Franchisegeber__c,
						Gesellschafter_1__c,
						Gesellschafter_2__c,
						Vermittler__c
				FROM Account
				WHERE ( Id = :filiale.Id )
		];
		System.assertEquals( vertragspartner2.Id, filiale.Betreiber__c );
		System.assertEquals( null, filiale.Immobiliengeber__c );
		System.assertEquals( vertragspartner1.Id, filiale.Lieferant_1__c );
		System.assertEquals( null, filiale.Lieferant_2__c );
		System.assertEquals( null, filiale.Franchisegeber__c );
		System.assertEquals( null, filiale.Gesellschafter_1__c );
		System.assertEquals( null, filiale.Gesellschafter_2__c );
		System.assertEquals( null, filiale.Vermittler__c );
	}
	
	/**
	 * @process [MYPM-2044] Packstation ANP: Deaktivierung des Leads wenn PS Dummy gewandelt wird
	 */
	@IsTest
	static void testDeactivateLeadsAfterUmwandlung () {
		
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			TriggerHandler.bypass('LeadTriggerHandler');
			TriggerHandler.bypass('AccountTriggerHandler');
			TriggerHandler.bypass('PackstationTriggerHandler');
			Lead lead = createPackstationLead();
			new PackstationDummyInitializer().create( new Set<Id> {
					lead.Id
			} );
			TriggerHandler.clearAllBypasses();
			
			Test.startTest();
			Account account = [
					SELECT
							Id,
							Lead__c
					FROM Account
					WHERE RecordType.DeveloperName = 'Packstation_Dummy'
					LIMIT 1
			];
			account.RecordTypeId = RecordTypeState.PACKSTATION;
			update account;
			Test.stopTest();
			
			System.assertEquals('inaktiv', [ SELECT Aktivitaetsstatus__c FROM Lead WHERE Id = :account.Lead__c LIMIT 1].Aktivitaetsstatus__c);
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
	
	private static List<Account> createAccounts ( Integer quantity ) {
		
		return ( List<Account> ) TestFactory.createSObjectList(
				new Account(
						Vertragsbetreuende_Einheit__c = insertOrgEDP().Id
				),
				quantity,
				true
		);
	}
	
	private static OrgE_DP__c insertOrgEDP () {
		
		OrgE_DP__c orgEDP = new OrgE_DP__c(
				Aussenstellen_Ma__c = UserInfo.getUserId(),
				Koordinator__c = [ SELECT Id FROM User WHERE Name = 'Marcel Schulz' ].Id
		);
		insert orgEDP;
		return orgEDP;
	}
	
	private static Task createTask ( String auftragnehmer, Id whatID ) {
		
		Task task = ( Task ) TestFactory.createSObject(
				new Task(
						Auftragnehmer__c = auftragnehmer,
						WhatId = whatID,
						Status = 'Nicht begonnen'
				),
				true
		);
		return task;
	}
	
	private static Account createFiliale ( String datensatztyp, String name, Date eroeffnungsdatum ) {
		String filialtyp = '';
		if ( datensatztyp == 'Filiale' ) {
			filialtyp = '76';
		}
		Account filiale = new Account(
				RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
						.get( datensatztyp ).getRecordTypeId(),
				Name = 'Filiale ' + name,
				ASt_ID__c = name,
				Debitor__c = name,
				Eroeffnungsdatum__c = eroeffnungsdatum,
				Filialtyp_OZ__c = filialtyp
		);
		return filiale;
	}
}