/**
 *@author       Mats Böhler
 *@created      12.09.201 * *@version      2.0
 *@since        48.0
 *
 *
 *@description  TaskTriggerHandlerTest.
 *
 *
 *@changelog    12.09.2019 Mats Böhler  - Created
 *              
 *
 */
@IsTest
private class TaskTriggerHandlerTest {
	
	private static final User HW_USER = [
			SELECT
					Id
			FROM User
			WHERE Name = 'Admin HundW'
			LIMIT 1
	];
	
	private static final User INTERFACE_USER = [
			SELECT
					Id
			FROM User
			WHERE IstSchnittstellenbenutzer__c = TRUE
			LIMIT 1
	];
	
	@TestSetup static void setupRequiredOrgEDPs () {
		List<String> orgEdpNames = new List<String> {
				'3920/30 Aussenstelle',
				'Vertriebsmanager',
				'3910 Immo/Instandh/Automation',
				'NL Bonn',
				'3540 DP Shop',
				'3600 Forderungsmgmt Partner',
				'Köln',
				'Support Center Filialen'
		};
		
		List<OrgE_DP__c> orgEDPS = new List<OrgE_DP__c>();
		for ( String name : orgEdpNames ) {
			orgEDPS.add(
					new OrgE_DP__c(
							Aussenstellen_Ma__c = UserInfo.getUserId(),
							Koordinator__c = INTERFACE_USER.Id,
							MA_ASt_PuDS__c = INTERFACE_USER.Id,
							Leiter__c = INTERFACE_USER.Id,
							OrgE_DP_Name__c = name
					)
			);
		}
		insert orgEDPS;
		
		insert new Rechte__c(
				SetupOwnerId = UserInfo.getOrganizationId(),
				darf_Inhaber_aller_Filialen_aendern__c = true
		);
	}
	
	/**
	 * @process Aufgabe - Auftragnehmer->Inhaber zuordnen mit Filialinfo
	 *
	 * @criteria Inhaber der Filiale/DHL Paketshop
	 */
	@IsTest
	static void testOwnerAssignmentFilialeDHLPaketshop () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			Account account = createAccount();
			account.OwnerId = HW_USER.Id;
			update account;
			
			Test.startTest();
			Task task = createTask( 'Vertriebsmanager', account.Id );
			Test.stopTest();
			
			System.assertEquals( [
					SELECT
							Id,
							OwnerId
					FROM Account
					WHERE Id = :account.Id
					LIMIT 1
			].OwnerId, [
					SELECT
							Id,
							OwnerId
					FROM Task
					WHERE Id = :task.Id
					LIMIT 1
			].OwnerId );
		}
	}
	
	/**
	 * @process Aufgabe - Auftragnehmer->Inhaber zuordnen mit Filialinfo
	 *
	 * @criteria Vertragsbetreuende Einheit
	 */
	@IsTest
	static void testOwnerAssignmentVertragsbetreuendeEinheit () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			Account account = createAccount();
			account.OwnerId = HW_USER.Id;
			update account;
			
			Test.startTest();
			Task task = createTask( 'Vertragsbetreuende Einheit', account.Id );
			Test.stopTest();
			
			System.assertEquals( INTERFACE_USER.Id, [
					SELECT
							Id,
							OwnerId
					FROM Task
					WHERE Id = :task.Id
					LIMIT 1
			].OwnerId );
		}
	}
	
	/**
	 * @process Aufgabe - Auftragnehmer->Inhaber zuordnen mit Filialinfo
	 *
	 * @criteria PuDS Aussenstelle zuordnen
	 */
	@IsTest
	static void testOwnerAssignmentPudsAussenstelle () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			Account account = createAccount();
			OrgE_DP__c orgEDP = new OrgE_DP__c(
					Aussenstellen_Ma__c = INTERFACE_USER.Id,
					Name = 'NL Brief',
					OrgE_DP_Name__c = 'NL Brief'
			);
			insert orgEDP;
			account.NL_Brief_Lookup__c = orgEDP.Id;
			update account;
			
			Test.startTest();
			Task task = createTask(
					'Qualitätsmängel Brief/DHL',
					'3920/30 Aussenstelle',
					account.Id );
			Test.stopTest();
			
			System.assertEquals( INTERFACE_USER.Id, [
					SELECT
							Id,
							OwnerId
					FROM Task
					WHERE Id = :task.Id
					LIMIT 1
			].OwnerId );
		}
	}
	
	/**
	 * @process Aufgabe - Auftragnehmer->Inhaber zuordnen mit Filialinfo
	 *
	 * @criteria EK ASt, VL, VK
	 */
	@IsTest
	static void testOwnerAssignmentEKAstVLVK () {
		System.runAs( TestUser.create( TestUser.UserType.VL2001 ) ) {
			Account account = createAccount();
			
			Test.startTest();
			Task task = createTask(
					'Vertriebsleiter',
					account.Id );
			Test.stopTest();
			
			System.assertEquals( INTERFACE_USER.Id, [
					SELECT
							Id,
							OwnerId
					FROM Task
					WHERE Id = :task.Id
					LIMIT 1
			].OwnerId );
		}
	}
	
	/**
	 * @process MYPM-675 Aufgabensteuerung nach NL Brief
	 *
	 * */
	@IsTest
	static void testOwnerAssignmentNLBrief () {
		System.runAs( TestUser.create( TestUser.UserType.VL2001 ) ) {
			
			OrgE_DP__c orgEDP = new OrgE_DP__c(
					OrgE_DP_Name__c = 'NL Mannheim',
					Name = 'NL Mannheim',
					Aussenstellen_Ma__c = UserInfo.getUserId(),
					Leiter__c = INTERFACE_USER.Id
			);
			insert orgEDP;
			
			Account account = ( Account ) TestFactory.createSObject(
					new Account(
							NL_Brief__c = 'Mannheim',
							NL_Brief_Lookup__c = orgEDP.Id
					),
					true
			);
			
			Test.startTest();
			Task task = createTask(
					'Vertriebsleiter',
					account.Id );
			Test.stopTest();
			
			System.assertEquals( INTERFACE_USER.Id, [
					SELECT
							Id,
							OwnerId
					FROM Task
					WHERE Id = :task.Id
					LIMIT 1
			].OwnerId );
		}
	}
	
	/**
	 * @process Aufgabe - Auftragnehmer->Inhaber zuordnen mit Filialinfo
	 *
	 * @criteria Zentrale Einheit
	 */
	@IsTest
	static void testOwnerAssignmentZentraleEinheit () {
		System.runAs( TestUser.create( TestUser.UserType.VL2001 ) ) {
			Account account = createAccount();
			
			Test.startTest();
			Task task = createTask(
					'Support Center Filialen',
					account.Id );
			Test.stopTest();
			
			System.assertEquals( INTERFACE_USER.Id, [
					SELECT
							Id,
							OwnerId
					FROM Task
					WHERE Id = :task.Id
					LIMIT 1
			].OwnerId );
		}
	}
	
	/**
	 * @process Aufgabe - Auftragnehmer->Inhaber zuordnen mit Filialinfo
	 *
	 * @criteria 3600 Forderungsmgmt + Besicherungswerte
	 */
	@IsTest
	static void testOwnerAssignment3600ForderungsmanagementAndBesicherungswerte () {
		System.runAs( TestUser.create( TestUser.UserType.VL2001 ) ) {
			Account account = createAccount();
			
			Test.startTest();
			Task task = createTask(
					'Besicherungswerte zu Akquiseauftrag Filiale ermitteln',
					'3600 Forderungsmgmt Partner',
					account.Id );
			Test.stopTest();
			
			System.assertEquals( INTERFACE_USER.Id, [
					SELECT
							Id,
							OwnerId
					FROM Task
					WHERE Id = :task.Id
					LIMIT 1
			].OwnerId );
		}
	}
	
	/**
	 * @process Aufgabe - Auftragnehmer->Inhaber zuordnen mit Filialinfo
	 *
	 * @criteria 3540 DP Shop
	 */
	@IsTest
	static void testOwnerAssignment3540DPShop () {
		System.runAs( TestUser.create( TestUser.UserType.VL2001 ) ) {
			Account account = createAccount();
			
			Test.startTest();
			Task task = ( Task ) TestFactory.createSObject(
					new Task(
							Auftragnehmer__c = '3540 DP Shop',
							Auftraggeber__c = '3540 DP Shop',
							Aufgabenart__c = 'DP Shop Personalsuche im lfd. Betrieb - Mitarbeiter',
							WhatId = account.Id
					),
					true
			);
			Test.stopTest();
			
			System.assertEquals( INTERFACE_USER.Id, [
					SELECT
							Id,
							OwnerId
					FROM Task
					WHERE Id = :task.Id
					LIMIT 1
			].OwnerId );
		}
	}
	
	/**
	 * @process Aufgaben - Sammelprozess - bei Datensatzanlage
	 *
	 * @criteria Einbruch / Überfall Filiale
	 */
	@IsTest
	static void testEinbruchUeberfallFiliale_DPS () {
		System.runAs( TestUser.create( TestUser.UserType.VL2001 ) ) {
			Account account = createAccount();
			account.Filialart__c = 'DPS';
			update account;
			
			Test.startTest();
			Task createdTask = ( Task ) TestFactory.createSObject(
					new Task(
							Filialart_OZ__c = 'DPS',
							Auftraggeber__c = '3600 Forderungsmgmt Partner',
							Aufgabenart__c = 'Einbruch/Überfall Filiale',
							WhatId = account.Id
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
							Type,
							AccountId
					FROM Task
			];
			
			System.assertEquals( 3, tasks.size() );
			Integer counter = 0;
			for ( Task task : tasks ) {
				if ( task.Aufgabenart__c == 'DP Shop Unvermutete Kassenprüfung + Detail' ) {
					System.assertEquals( Date.today(), task.ActivityDate );
					System.assertEquals( '3540 DP Shop', task.Auftraggeber__c );
					System.assertEquals( 'Vertriebsmanager', task.Auftragnehmer__c );
					System.assertEquals( 'Diese Aufgaben basiert auf der ' +
							'Aufgabe \'Einbruch/Überfall Filiale\': https://mypm.lightning.force.com/' + createdTask.Id,
							task.Description );
					System.assertEquals( Date.today().addDays( 1 ), task.Erledigung_bis_zum__c );
					System.assertEquals( 'Hoch', task.Priority );
					System.assert( task.RecordTypeId == Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
							.get( 'A_Aufgaben_automatische_Anlage' ).getRecordTypeId() );
					System.assertEquals( 'Nicht begonnen', task.Status );
					System.assertEquals( 'Besuch', task.Typc__c );
					System.assertEquals( 'Besuch', task.Type );
					System.assertEquals( account.Id, task.AccountId );
					counter++;
				}
				if ( task.Aufgabenart__c == 'Beauftragung und Begleitung Inventur/Teilinventur + Detail' ) {
					System.assertEquals( Date.today(), task.ActivityDate );
					System.assertEquals( '3540 DP Shop', task.Auftraggeber__c );
					System.assertEquals( 'Vertriebsmanager', task.Auftragnehmer__c );
					System.assertEquals( 'Diese Aufgaben basiert auf der ' +
							'Aufgabe \'Einbruch/Überfall Filiale\': https://mypm.lightning.force.com/' + createdTask.Id,
							task.Description );
					System.assertEquals( Date.today().addDays( 1 ), task.Erledigung_bis_zum__c );
					System.assertEquals( 'Hoch', task.Priority );
					System.assert( task.RecordTypeId == Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
							.get( 'A_Aufgaben_automatische_Anlage' ).getRecordTypeId() );
					System.assertEquals( 'Nicht begonnen', task.Status );
					System.assertEquals( 'Besuch', task.Typc__c );
					System.assertEquals( 'Besuch', task.Type );
					System.assertEquals( account.Id, task.AccountId );
					counter++;
				}
			}
			System.assertEquals( 2, counter );
		}
	}
	
	/**
	 * @process Aufgaben - Sammelprozess - bei Datensatzanlage
	 *
	 * @criteria Einbruch / Überfall Filiale
	 */
	@IsTest
	static void testEinbruchUeberfallFiliale () {
		System.runAs( TestUser.create( TestUser.UserType.VL2001 ) ) {
			Account account = createAccount();
			account.Filialart__c = 'DPS';
			
			Test.startTest();
			Task createdTask = ( Task ) TestFactory.createSObject(
					new Task(
							Auftraggeber__c = '3600 Forderungsmgmt Partner',
							Aufgabenart__c = 'Einbruch/Überfall Filiale',
							WhatId = account.Id
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
							Type,
							AccountId
					FROM Task
			];
			
			System.assertEquals( 3, tasks.size() );
			Integer counter = 0;
			for ( Task task : tasks ) {
				if ( task.Aufgabenart__c == 'Begleiteter S-I-V + Detail' ) {
					System.assertEquals( Date.today(), task.ActivityDate );
					System.assertEquals( 'Vertriebsleiter', task.Auftraggeber__c );
					System.assertEquals( 'Vertriebsmanager', task.Auftragnehmer__c );
					System.assertEquals( Date.today().addDays( 1 ), task.Erledigung_bis_zum__c );
					System.assertEquals( 'Hoch', task.Priority );
					System.assert( task.RecordTypeId == Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
							.get( 'A_Aufgaben_automatische_Anlage' ).getRecordTypeId() );
					System.assertEquals( 'Nicht begonnen', task.Status );
					System.assertEquals( 'Besuch', task.Typc__c );
					System.assertEquals( 'Besuch', task.Type );
					System.assertEquals( account.Id, task.AccountId );
					counter++;
				}
				if ( task.Aufgabenart__c == 'Beauftragung und Begleitung Inventur/Teilinventur + Detail' ) {
					System.assertEquals( Date.today(), task.ActivityDate );
					System.assertEquals( 'Vertriebsleiter', task.Auftraggeber__c );
					System.assertEquals( 'Vertriebsmanager', task.Auftragnehmer__c );
					System.assertEquals( 'Diese Aufgaben basiert auf der ' +
							'Aufgabe \'Einbruch/Überfall Filiale\': https://mypm.lightning.force.com/' + createdTask.Id,
							task.Description );
					System.assertEquals( Date.today().addDays( 1 ), task.Erledigung_bis_zum__c );
					System.assertEquals( 'Hoch', task.Priority );
					System.assert( task.RecordTypeId == Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
							.get( 'A_Aufgaben_automatische_Anlage' ).getRecordTypeId() );
					System.assertEquals( 'Nicht begonnen', task.Status );
					System.assertEquals( 'Besuch', task.Typc__c );
					System.assertEquals( 'Besuch', task.Type );
					System.assertEquals( account.Id, task.AccountId );
					counter++;
				}
			}
			System.assertEquals( 2, counter );
		}
	}
	
	/**
	 * @process Aufgaben - Sammelprozess - bei Datensatzanlage
	 *
	 * @criteria Akquiseauftrag Filiale erstellt?
	 */
	@IsTest
	static void testAkquiseauftragFilialeErstellt () {
		System.runAs( TestUser.create( TestUser.UserType.VL2001 ) ) {
			Account account = createAccount();
			account.Filialart__c = 'DPS';
			Filialnetzaenderung__c filialnetzaenderung = new Filialnetzaenderung__c(
					Erledigungsdatum_FNAE__c = null,
					Zu_erwartender_Debitor__c = '12345',
					Schliessung_avisiert_fuer__c = Date.today(),
					Filiale_Filialpartner__c = account.Id
			);
			insert filialnetzaenderung;
			Test.startTest();
			Task createdTask = ( Task ) TestFactory.createSObject(
					new Task(
							Auftraggeber__c = '3600 Forderungsmgmt Partner',
							Aufgabenart__c = 'Akquiseauftrag Filiale + Detail',
							Auftrag_zur_PartnerAkquise__c = '79',
							WhatId = account.Id,
							Filialnetzaenderung__c = filialnetzaenderung.Id
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
							Type,
							AccountId,
							Auftrag_zur_PartnerAkquise__c,
							Erledigt_am__c,
							Erledigungsvermerk__c,
							FNAE_Id__c,
							Filialnetzaenderung__c
					FROM Task
			];
			
			System.assertEquals( 2, tasks.size() );
			Integer counter = 0;
			for ( Task task : tasks ) {
				if ( task.Aufgabenart__c == 'Besicherungswerte zu Akquiseauftrag Filiale ermitteln' ) {
					System.assertEquals( Date.today(), task.ActivityDate );
					System.assertEquals( '79', task.Auftrag_zur_PartnerAkquise__c );
					System.assertEquals( '3600 Forderungsmgmt Partner', task.Auftraggeber__c );
					System.assertEquals( 'Vertriebskoordinator VGL', task.Auftragnehmer__c );
					System.assert( task.Description.contains( 'Für Erstgespräch! Vorläufiger pauschaler ' +
							'Durchschnittswert auf OZ/VL-Ebene. Abweichungen nach oben können sich insb. ' +
							'bei haftungsbeschränkterer Rechtsform (UG, GmbH), schlechter Bonität bzw. bei ' +
							'Partnern mit mehreren Standorten ergeben. Für finales Partnergespräch BGP unter ' +
							'Angabe des konkreten Partners und der Referenzfiliale anfordern.' ) );
					System.assertEquals( Date.today(), task.Erledigt_am__c );
					System.assertEquals( Date.today(), task.Erledigung_bis_zum__c );
					System.assert( task.Erledigungsvermerk__c.contains( 'Wert konnte nicht ermittelt werden, bitte an 3600 wenden' ) );
					System.assertEquals( 'Mittel', task.Priority );
					System.assert( task.RecordTypeId == Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
							.get( 'Aufgaben_zu_FNAE' ).getRecordTypeId() );
					System.assertEquals( 'Erledigt', task.Status );
					System.assertEquals( 'Intern', task.Typc__c );
					System.assertEquals( 'Intern', task.Type );
					System.assertEquals( account.Id, task.AccountId );
					counter++;
				}
			}
			System.assertEquals( 1, counter );
		}
	}
	
	/**
	 * @process Aufgaben - Sammelprozess - bei Datensatzanlage
	 *
	 * @criteria Akquiseauftrag Filiale erstellt? -> Würzburg
	 */
	@IsTest
	static void testAkquiseauftragFilialeErstellt_Wuerzburg () {
		System.runAs( TestUser.create( TestUser.UserType.VL2001 ) ) {
			Account account = createAccount( 'Würzburg' );
			
			Test.startTest();
			List<Task> tasks = new List<Task>();
			tasks.add( addTask( account ) );
			insert tasks;
			Test.stopTest();
			
			tasks = [
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
							Type,
							AccountId,
							Auftrag_zur_PartnerAkquise__c,
							Erledigt_am__c,
							Erledigungsvermerk__c,
							FNAE_Id__c,
							Filialnetzaenderung__c
					FROM Task
					WHERE Aufgabenart__c = 'Besicherungswerte zu Akquiseauftrag Filiale ermitteln'
			];
			
			System.assertEquals( 1, tasks.size() );
		}
	}
	
	/**
	 * @process Aufgaben - Sammelprozess - bei Datensatzanlage
	 *
	 * @criteria Akquiseauftrag Filiale erstellt? -> München
	 */
	@IsTest
	static void testAkquiseauftragFilialeErstellt_Muenchen () {
		System.runAs( TestUser.create( TestUser.UserType.VL2001 ) ) {
			Account account = createAccount( 'München' );
			
			Test.startTest();
			List<Task> tasks = new List<Task>();
			tasks.add( addTask( account ) );
			insert tasks;
			Test.stopTest();
			
			tasks = [
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
							Type,
							AccountId,
							Auftrag_zur_PartnerAkquise__c,
							Erledigt_am__c,
							Erledigungsvermerk__c,
							FNAE_Id__c,
							Filialnetzaenderung__c
					FROM Task
					WHERE Aufgabenart__c = 'Besicherungswerte zu Akquiseauftrag Filiale ermitteln'
			];
			
			System.assertEquals( 1, tasks.size() );
		}
	}
	
	/**
	 * @process Aufgaben - Sammelprozess - bei Datensatzanlage
	 *
	 * @criteria Akquiseauftrag Filiale erstellt? -> Berlin
	 */
	@IsTest
	static void testAkquiseauftragFilialeErstellt_Berlin () {
		System.runAs( TestUser.create( TestUser.UserType.VL2001 ) ) {
			Account account = createAccount( 'Berlin' );
			
			Test.startTest();
			List<Task> tasks = new List<Task>();
			tasks.add( addTask( account ) );
			insert tasks;
			Test.stopTest();
			
			tasks = [
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
							Type,
							AccountId,
							Auftrag_zur_PartnerAkquise__c,
							Erledigt_am__c,
							Erledigungsvermerk__c,
							FNAE_Id__c,
							Filialnetzaenderung__c
					FROM Task
					WHERE Aufgabenart__c = 'Besicherungswerte zu Akquiseauftrag Filiale ermitteln'
			];
			
			System.assertEquals( 1, tasks.size() );
		}
	}
	
	/**
	 * @process Aufgaben - Sammelprozess - bei Datensatzanlage
	 *
	 * @criteria Akquiseauftrag Filiale erstellt? -> Mainz
	 */
	@IsTest
	static void testAkquiseauftragFilialeErstellt_Mainz () {
		System.runAs( TestUser.create( TestUser.UserType.VL2001 ) ) {
			Account account = createAccount( 'Mainz' );
			
			Test.startTest();
			List<Task> tasks = new List<Task>();
			tasks.add( addTask( account ) );
			insert tasks;
			Test.stopTest();
			
			tasks = [
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
							Type,
							AccountId,
							Auftrag_zur_PartnerAkquise__c,
							Erledigt_am__c,
							Erledigungsvermerk__c,
							FNAE_Id__c,
							Filialnetzaenderung__c
					FROM Task
					WHERE Aufgabenart__c = 'Besicherungswerte zu Akquiseauftrag Filiale ermitteln'
			];
			
			System.assertEquals( 1, tasks.size() );
		}
	}
	
	/**
	 * @process Aufgaben - Sammelprozess - bei Datensatzanlage
	 *
	 * @criteria Akquiseauftrag Filiale erstellt? -> Freiburg
	 */
	@IsTest
	static void testAkquiseauftragFilialeErstellt_Freiburg () {
		System.runAs( TestUser.create( TestUser.UserType.VL2001 ) ) {
			Account account = createAccount( 'Freiburg' );
			
			Test.startTest();
			List<Task> tasks = new List<Task>();
			tasks.add( addTask( account ) );
			insert tasks;
			Test.stopTest();
			
			tasks = [
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
							Type,
							AccountId,
							Auftrag_zur_PartnerAkquise__c,
							Erledigt_am__c,
							Erledigungsvermerk__c,
							FNAE_Id__c,
							Filialnetzaenderung__c
					FROM Task
					WHERE Aufgabenart__c = 'Besicherungswerte zu Akquiseauftrag Filiale ermitteln'
			];
			
			System.assertEquals( 1, tasks.size() );
		}
	}
	
	/**
	 * @process Aufgaben - Sammelprozess - bei Datensatzanlage
	 *
	 * @criteria Akquiseauftrag Filiale erstellt? -> Nürnberg
	 */
	@IsTest
	static void testAkquiseauftragFilialeErstellt_Nuernberg () {
		System.runAs( TestUser.create( TestUser.UserType.VL2001 ) ) {
			Account account = createAccount( 'Nürnberg' );
			
			Test.startTest();
			List<Task> tasks = new List<Task>();
			tasks.add( addTask( account ) );
			insert tasks;
			Test.stopTest();
			
			tasks = [
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
							Type,
							AccountId,
							Auftrag_zur_PartnerAkquise__c,
							Erledigt_am__c,
							Erledigungsvermerk__c,
							FNAE_Id__c,
							Filialnetzaenderung__c
					FROM Task
					WHERE Aufgabenart__c = 'Besicherungswerte zu Akquiseauftrag Filiale ermitteln'
			];
			
			System.assertEquals( 1, tasks.size() );
		}
	}
	
	/**
	 * @process Aufgaben - Sammelprozess - bei Datensatzanlage
	 *
	 * @criteria Akquiseauftrag Filiale erstellt? -> Frankfurt
	 */
	@IsTest
	static void testAkquiseauftragFilialeErstellt_Frankfurt () {
		System.runAs( TestUser.create( TestUser.UserType.VL2001 ) ) {
			Account account = createAccount( 'Frankfurt' );
			
			Test.startTest();
			List<Task> tasks = new List<Task>();
			tasks.add( addTask( account ) );
			insert tasks;
			Test.stopTest();
			
			tasks = [
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
							Type,
							AccountId,
							Auftrag_zur_PartnerAkquise__c,
							Erledigt_am__c,
							Erledigungsvermerk__c,
							FNAE_Id__c,
							Filialnetzaenderung__c
					FROM Task
					WHERE Aufgabenart__c = 'Besicherungswerte zu Akquiseauftrag Filiale ermitteln'
			];
			
			System.assertEquals( 1, tasks.size() );
		}
	}
	
	/**
	 * @process Aufgaben - Sammelprozess - bei Datensatzanlage
	 *
	 * @criteria Akquiseauftrag Filiale erstellt? -> Kassel
	 */
	@IsTest
	static void testAkquiseauftragFilialeErstellt_Kassel () {
		System.runAs( TestUser.create( TestUser.UserType.VL2001 ) ) {
			Account account = createAccount( 'Kassel' );
			
			Test.startTest();
			List<Task> tasks = new List<Task>();
			tasks.add( addTask( account ) );
			insert tasks;
			Test.stopTest();
			
			tasks = [
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
							Type,
							AccountId,
							Auftrag_zur_PartnerAkquise__c,
							Erledigt_am__c,
							Erledigungsvermerk__c,
							FNAE_Id__c,
							Filialnetzaenderung__c
					FROM Task
					WHERE Aufgabenart__c = 'Besicherungswerte zu Akquiseauftrag Filiale ermitteln'
			];
			
			System.assertEquals( 1, tasks.size() );
		}
	}
	
	/**
	 * @process Aufgaben - Sammelprozess - bei Datensatzanlage
	 *
	 * @criteria Akquiseauftrag Filiale erstellt? -> Hannover
	 */
	@IsTest
	static void testAkquiseauftragFilialeErstellt_Hannover () {
		System.runAs( TestUser.create( TestUser.UserType.VL2001 ) ) {
			Account account = createAccount( 'Hannover' );
			
			Test.startTest();
			List<Task> tasks = new List<Task>();
			tasks.add( addTask( account ) );
			insert tasks;
			Test.stopTest();
			
			tasks = [
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
							Type,
							AccountId,
							Auftrag_zur_PartnerAkquise__c,
							Erledigt_am__c,
							Erledigungsvermerk__c,
							FNAE_Id__c,
							Filialnetzaenderung__c
					FROM Task
					WHERE Aufgabenart__c = 'Besicherungswerte zu Akquiseauftrag Filiale ermitteln'
			];
			
			System.assertEquals( 1, tasks.size() );
		}
	}
	
	/**
	 * @process Aufgaben - Sammelprozess - bei Datensatzanlage
	 *
	 * @criteria Akquiseauftrag Filiale erstellt? -> Muenster
	 */
	@IsTest
	static void testAkquiseauftragFilialeErstellt_Muenster () {
		System.runAs( TestUser.create( TestUser.UserType.VL2001 ) ) {
			Account account = createAccount( 'Münster' );
			
			Test.startTest();
			List<Task> tasks = new List<Task>();
			tasks.add( addTask( account ) );
			insert tasks;
			Test.stopTest();
			
			tasks = [
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
							Type,
							AccountId,
							Auftrag_zur_PartnerAkquise__c,
							Erledigt_am__c,
							Erledigungsvermerk__c,
							FNAE_Id__c,
							Filialnetzaenderung__c
					FROM Task
					WHERE Aufgabenart__c = 'Besicherungswerte zu Akquiseauftrag Filiale ermitteln'
			];
			
			System.assertEquals( 1, tasks.size() );
		}
	}
	
	/**
	 * @process Aufgaben - Sammelprozess - bei Datensatzanlage
	 *
	 * @criteria Akquiseauftrag Filiale erstellt? -> Hamburg
	 */
	@IsTest
	static void testAkquiseauftragFilialeErstellt_Hamburg () {
		System.runAs( TestUser.create( TestUser.UserType.VL2001 ) ) {
			Account account = createAccount( 'Hamburg' );
			
			Test.startTest();
			List<Task> tasks = new List<Task>();
			tasks.add( addTask( account ) );
			insert tasks;
			Test.stopTest();
			
			tasks = [
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
							Type,
							AccountId,
							Auftrag_zur_PartnerAkquise__c,
							Erledigt_am__c,
							Erledigungsvermerk__c,
							FNAE_Id__c,
							Filialnetzaenderung__c
					FROM Task
					WHERE Aufgabenart__c = 'Besicherungswerte zu Akquiseauftrag Filiale ermitteln'
			];
			
			System.assertEquals( 1, tasks.size() );
		}
	}
	
	/**
	 * @process Aufgaben - Sammelprozess - bei Datensatzanlage
	 *
	 * @criteria Akquiseauftrag Filiale erstellt? -> Dortmund
	 */
	@IsTest
	static void testAkquiseauftragFilialeErstellt_Dortmund () {
		System.runAs( TestUser.create( TestUser.UserType.VL2001 ) ) {
			Account account = createAccount( 'Dortmund' );
			
			Test.startTest();
			List<Task> tasks = new List<Task>();
			tasks.add( addTask( account ) );
			insert tasks;
			Test.stopTest();
			
			tasks = [
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
							Type,
							AccountId,
							Auftrag_zur_PartnerAkquise__c,
							Erledigt_am__c,
							Erledigungsvermerk__c,
							FNAE_Id__c,
							Filialnetzaenderung__c
					FROM Task
					WHERE Aufgabenart__c = 'Besicherungswerte zu Akquiseauftrag Filiale ermitteln'
			];
			
			System.assertEquals( 1, tasks.size() );
		}
	}
	
	/**
	 * @process Aufgaben - Sammelprozess - bei Datensatzanlage
	 *
	 * @criteria Akquiseauftrag Filiale erstellt? -> Köln
	 */
	@IsTest
	static void testAkquiseauftragFilialeErstellt_Koeln () {
		System.runAs( TestUser.create( TestUser.UserType.VL2001 ) ) {
			Account account = createAccount( 'Köln' );
			
			Test.startTest();
			List<Task> tasks = new List<Task>();
			tasks.add( addTask( account ) );
			insert tasks;
			Test.stopTest();
			
			tasks = [
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
							Type,
							AccountId,
							Auftrag_zur_PartnerAkquise__c,
							Erledigt_am__c,
							Erledigungsvermerk__c,
							FNAE_Id__c,
							Filialnetzaenderung__c
					FROM Task
					WHERE Aufgabenart__c = 'Besicherungswerte zu Akquiseauftrag Filiale ermitteln'
			];
			
			System.assertEquals( 1, tasks.size() );
		}
	}
	
	/**
	 * @process Aufgaben - Sammelprozess - bei Datensatzanlage
	 *
	 * @criteria Akquiseauftrag Filiale erstellt? -> Leipzig
	 */
	@IsTest
	static void testAkquiseauftragFilialeErstellt_Leipzig () {
		System.runAs( TestUser.create( TestUser.UserType.VL2001 ) ) {
			Account account = createAccount( 'Leipzig' );
			
			Test.startTest();
			List<Task> tasks = new List<Task>();
			tasks.add( addTask( account ) );
			insert tasks;
			Test.stopTest();
			
			tasks = [
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
							Type,
							AccountId,
							Auftrag_zur_PartnerAkquise__c,
							Erledigt_am__c,
							Erledigungsvermerk__c,
							FNAE_Id__c,
							Filialnetzaenderung__c
					FROM Task
					WHERE Aufgabenart__c = 'Besicherungswerte zu Akquiseauftrag Filiale ermitteln'
			];
			
			System.assertEquals( 1, tasks.size() );
		}
	}
	
	/**
	 * @process Aufgaben - Sammelprozess - bei Datensatzanlage
	 *
	 * @criteria Akquiseauftrag Filiale erstellt? -> Stuttgart
	 */
	@IsTest
	static void testAkquiseauftragFilialeErstellt_Stuttgart () {
		System.runAs( TestUser.create( TestUser.UserType.VL2001 ) ) {
			Account account = createAccount( 'Stuttgart' );
			
			Test.startTest();
			List<Task> tasks = new List<Task>();
			tasks.add( addTask( account ) );
			insert tasks;
			Test.stopTest();
			
			tasks = [
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
							Type,
							AccountId,
							Auftrag_zur_PartnerAkquise__c,
							Erledigt_am__c,
							Erledigungsvermerk__c,
							FNAE_Id__c,
							Filialnetzaenderung__c
					FROM Task
					WHERE Aufgabenart__c = 'Besicherungswerte zu Akquiseauftrag Filiale ermitteln'
			];
			
			System.assertEquals( 1, tasks.size() );
		}
	}
	
	/**
	 * @process Aufgaben - Sammelprozess - bei Datensatzanlage
	 *
	 * @criteria Anmerkung leer?
	 */
	@IsTest
	static void testAnmerkungLeer () {
		System.runAs( TestUser.create( TestUser.UserType.VL2001 ) ) {
			Account account = createAccount();
			
			Test.startTest();
			Task createdTask = ( Task ) TestFactory.createSObject(
					new Task(
							Aufgabenart__c = 'PoPS Akquise',
							WhatId = account.Id
					),
					true
			);
			
			Test.stopTest();
			
			createdTask = [ SELECT Id, Description, Aufgabenart__c FROM Task WHERE Id = :createdTask.Id LIMIT 1 ];
			System.assert( createdTask.Description.contains( 'Partner für PoPS akquirieren' ) );
		}
	}
	
	/**
	 * @process Aufgaben - Sammelprozess - bei Datensatzanlage
	 *
	 * @criteria Typ__c in Typ kopieren
	 */
	@IsTest
	static void testCopyType () {
		System.runAs( TestUser.create( TestUser.UserType.VL2001 ) ) {
			Account account = createAccount();
			
			Test.startTest();
			Task createdTask = ( Task ) TestFactory.createSObject(
					new Task(
							Aufgabenart__c = 'PoPS Akquise',
							Typc__c = 'Besuch',
							WhatId = account.Id
					),
					true
			);
			
			Test.stopTest();
			
			createdTask = [ SELECT Id, Description, TypInitial__c, Type FROM Task WHERE Id = :createdTask.Id LIMIT 1 ];
			System.assertEquals( 'Besuch', createdTask.TypInitial__c );
			System.assertEquals( 'Besuch', createdTask.Type );
		}
	}
	
	/**
	 * @process Aufgaben - Sammelprozess - bei Datensatzanlage
	 *
	 * @criteria Aufgabenart in Thema kopieren
	 */
	@IsTest
	static void testCopyAufgabenartToThema () {
		System.runAs( TestUser.create( TestUser.UserType.VL2001 ) ) {
			Account account = createAccount();
			
			Test.startTest();
			Task createdTask = ( Task ) TestFactory.createSObject(
					new Task(
							Aufgabenart__c = 'PoPS Akquise',
							Typc__c = 'Besuch',
							WhatId = account.Id
					),
					true
			);
			
			Test.stopTest();
			
			createdTask = [ SELECT Id, Subject FROM Task WHERE Id = :createdTask.Id LIMIT 1 ];
			System.assertEquals( 'PoPS Akquise', createdTask.Subject );
		}
	}
	
	/**
	 * @process Aufgaben - Sammelprozess - bei Datensatzanlage
	 *
	 * @criteria Filiale vorhanden?
	 */
	@IsTest
	static void testFilialeVorhanden () {
		System.runAs( TestUser.create( TestUser.UserType.VL2001 ) ) {
			
			OrgE_DP__c orgEDP = new OrgE_DP__c(
					Aussenstellen_Ma__c = UserInfo.getUserId(),
					Koordinator__c = INTERFACE_USER.Id,
					OrgE_DP_Name__c = 'Test',
					Name = 'Test'
			);
			insert orgEDP;
			
			Account account = ( Account ) TestFactory.createSObject(
					new Account(
							Vertragsbetreuende_Einheit__c = orgEDP.Id,
							ASt_Nummer__c = '123',
							ASt_ID__c = '1234',
							ASt_Name__c = 'astName',
							Debitor__c = 'debitor',
							Filialart__c = 'DHL',
							Filialtyp_OZ__c = '95',
							ShippingStreet = 'TestStreet',
							Phone = '0815',
							GL_Name__c = 'glName',
							Vertriebssegment__c = 'vertrieb'
					),
					true
			);
			
			Test.startTest();
			Task createdTask = ( Task ) TestFactory.createSObject(
					new Task(
							Aufgabenart__c = 'PoPS Akquise',
							Typc__c = 'Besuch',
							WhatId = account.Id
					),
					true
			);
			
			Test.stopTest();
			
			createdTask = [
					SELECT
							Id,
							ASt_Nummer__c,
							Ast_Id__c,
							Ast_Name__c,
							Debitor__c,
							Filialart_OZ__c,
							Strasse_Filialanschrift__c,
							Telefon__c,
							VG__c,
							Vertriebssegment_Filiale__c
					FROM Task
					WHERE Id = :createdTask.Id
					LIMIT 1
			];
			System.assertEquals( '123', createdTask.ASt_Nummer__c );
			System.assertEquals( '1234', createdTask.Ast_Id__c );
			System.assertEquals( 'astName', createdTask.Ast_Name__c );
			System.assertEquals( 'debitor', createdTask.Debitor__c );
			System.assertEquals( 'DHL/95', createdTask.Filialart_OZ__c );
			System.assertEquals( 'TestStreet', createdTask.Strasse_Filialanschrift__c );
			System.assertEquals( '0815', createdTask.Telefon__c );
			System.assertEquals( 'glName', createdTask.VG__c );
			System.assertEquals( 'vertrieb', createdTask.Vertriebssegment_Filiale__c );
		}
	}
	
	/**
	 * @process Aufgaben - Sammelprozess - bei Datensatzanlage
	 *
	 * @criteria Kapazitäts- abfrage Paketausgabe
	 */
	@IsTest
	static void testKapazitaetsabfragePaketausgabe () {
		System.runAs( TestUser.create( TestUser.UserType.VL2001 ) ) {
			Account account = createAccount();
			
			Test.startTest();
			Task createdTask = ( Task ) TestFactory.createSObject(
					new Task(
							Aufgabenart__c = 'Kapazitätsabfrage Paketausgabe und -annahme + Detail',
							WhatId = account.Id
					),
					true
			);
			
			Test.stopTest();
			
			createdTask = [ SELECT Id, Description FROM Task WHERE Id = :createdTask.Id LIMIT 1 ];
			System.assert( createdTask.Description.contains( 'Aktuell Ausgabe benachrichtigter Pakete:' ) );
		}
	}
	
	/**
	 * @process Aufgaben - Sammelprozess - bei Datensatzanlage
	 *
	 * @criteria Kontaktaufnahme nach (angezeigter/vermuteter) Filialschließung
	 */
	@IsTest
	static void testKontaktaufnahmNachVermuteterFilialschliessung () {
		System.runAs( TestUser.create( TestUser.UserType.VL2001 ) ) {
			Account account = createAccount();
			
			Test.startTest();
			List<Task> tasks = new List<Task>();
			tasks.add( addTask( account, '1T1 Field Sales' ) );
			tasks.add( addTask( account, 'Vertriebsmanager' ) );
			tasks.add( addTask( account, 'Vertriebskoordinator' ) );
			tasks.add( addTask( account, 'Vertriebsleiter' ) );
			tasks.add( addTask( account, '3500 Betriebssteuerung' ) );
			insert tasks;
			Test.stopTest();
			
			Integer counter = 0;
			for ( Task task : [ SELECT Id, Aufgabenart__c, Auftraggeber__c, Description FROM Task ] ) {
				if ( task.Aufgabenart__c == 'Nachfass: Kontakt nach (angezeigter/vermuteter) Filialschließung + Detail'
						&& ( task.Auftraggeber__c == '1T1 Field Sales'
						|| task.Auftraggeber__c == 'Vertriebsmanager'
						|| task.Auftraggeber__c == 'Vertriebskoordinator'
						|| task.Auftraggeber__c == 'Vertriebsleiter' ) ) {
					counter++;
				}
				else if ( task.Aufgabenart__c == 'Nachfass: Kontakt nach (angezeigter/vermuteter) Filialschließung + Detail' ) {
					counter++;
				}
			}
			System.assertEquals( 5, counter );
		}
	}
	
	/**
	 * @process Aufgaben - Sammelprozess - bei Datensatzanlage
	 *
	 * @criteria Kontaktaufnahme aufgrund Coronavirus
	 */
	@IsTest
	static void testKontaktaufnahmeCoronavirus () {
		System.runAs( TestUser.create( TestUser.UserType.VL2001 ) ) {
			Account account = createAccount();
			
			Test.startTest();
			Task createdTask = ( Task ) TestFactory.createSObject(
					new Task(
							Aufgabenart__c = 'Kontaktaufnahme aufgrund Coronavirus + Detail',
							WhatId = account.Id
					),
					true
			);
			
			Test.stopTest();
			
			createdTask = [ SELECT Id, Description FROM Task WHERE Id = :createdTask.Id LIMIT 1 ];
			System.assert( createdTask.Description.contains( 'Aufgrund der aktuellen Lage wurde entschieden, ' +
					'alle Partner und Paketshops via Outboundcall anzurufen. Bitte in diesem Call den Partner auf ' +
					'seine Rechte und Pflichten hinweisen, den Partner beruhigen und zur weiteren Öffnung motivieren. ' +
					'Wenn Öffnungszeiten geändert werden oder Filialen schließen bitte den VP auf die entsprechenden ' +
					'Prozesse hinweisen (HDF, Partnerportal).' ) );
		}
	}
	
	/**
	 * @process Aufgabe -> Aufgabendetail
	 *
	 * @criteria Aufgabendetail vorhanden?
	 */
	@IsTest
	static void testAufgabendetailVorhanden () {
		System.runAs( TestUser.create( TestUser.UserType.VL2001 ) ) {
			Account account = createAccount();
			Aufgabendetail1__c aufgabendetail1 = new Aufgabendetail1__c(
					Bezug_zu__c = account.Id
			);
			insert aufgabendetail1;
			
			Test.startTest();
			Task createdTask = ( Task ) TestFactory.createSObject(
					new Task(
							Aufgabenart__c = 'Kontaktaufnahme aufgrund Coronavirus + Detail',
							WhatId = account.Id,
							Aufgabendetail__c = aufgabendetail1.Id
					),
					true
			);
			
			Test.stopTest();
			
			createdTask = [
					SELECT
							Id,
							Ablehnungsgrund__c,
							Aktivitaets_ID_Eindeutig__c,
							Aufgabenart__c,
							Auftraggeber__c,
							Auftragnehmer__c,
							Erledigt_am__c,
							Erledigung_bis_zum__c,
							FNAEM_ID__c,
							ActivityDate,
							Ast_Name__c,
							WhoId,
							Priority,
							Referenz_ID_Fachseitensystem__c,
							Status,
							Typc__c,
							OwnerId
					FROM Task
					WHERE Id = :createdTask.Id
					LIMIT 1
			];
			
			aufgabendetail1 = [
					SELECT
							Id,
							Ablehnungsgrund__c,
							Aktivitaets_ID_Eindeutig__c,
							Aufgabenart__c,
							Auftraggeber__c,
							Auftragnehmer__c,
							Erledigt_am__c,
							Erledigung_bis_zum__c,
							FNAEM_ID__c,
							Faelligkeitsdatum__c,
							Name,
							Prioritaet__c,
							Referenz_ID_Fachseitensystem__c,
							Status__c,
							Typ__c,
							Zugeordnet_zu__c,
							Name__c
					FROM Aufgabendetail1__c
					WHERE Id = :aufgabendetail1.Id
					LIMIT 1
			];
			
			System.assertEquals( createdTask.Ablehnungsgrund__c, aufgabendetail1.Ablehnungsgrund__c );
			System.assertEquals( createdTask.Aktivitaets_ID_Eindeutig__c, aufgabendetail1.Aktivitaets_ID_Eindeutig__c );
			System.assertEquals( createdTask.Aufgabenart__c, aufgabendetail1.Aufgabenart__c );
			System.assertEquals( createdTask.Auftraggeber__c, aufgabendetail1.Auftraggeber__c );
			System.assertEquals( createdTask.Auftragnehmer__c, aufgabendetail1.Auftragnehmer__c );
			System.assertEquals( createdTask.Erledigt_am__c, aufgabendetail1.Erledigt_am__c );
			System.assertEquals( createdTask.Erledigung_bis_zum__c, aufgabendetail1.Erledigung_bis_zum__c );
			System.assertEquals( createdTask.FNAEM_ID__c, aufgabendetail1.FNAEM_ID__c );
			System.assertEquals( createdTask.ActivityDate, aufgabendetail1.Faelligkeitsdatum__c );
			System.assertEquals( createdTask.WhoId, aufgabendetail1.Name__c );
			String astName = createdTask.Ast_Name__c == null ? '' : createdTask.Ast_Name__c;
			System.assertEquals( astName + '/ ' + createdTask.Aufgabenart__c, aufgabendetail1.Name );
			System.assertEquals( createdTask.Priority, aufgabendetail1.Prioritaet__c );
			System.assertEquals( createdTask.Referenz_ID_Fachseitensystem__c, aufgabendetail1.Referenz_ID_Fachseitensystem__c );
			System.assertEquals( createdTask.Status, aufgabendetail1.Status__c );
			System.assertEquals( createdTask.Typc__c, aufgabendetail1.Typ__c );
			System.assertEquals( createdTask.OwnerId, aufgabendetail1.Zugeordnet_zu__c );
		}
	}
	
	/**
	 * @process FNÄ - autom. Aktualisierung Aufgabenstatus und Erledigt am
	 *
	 * @criteria Akquiseauftrag
	 */
	@IsTest
	static void testFNAEAkquiseauftrag () {
		System.runAs( TestUser.create( TestUser.UserType.VL2001 ) ) {
			Account account = createAccount();
			Filialnetzaenderung__c filialnetzaenderung = new Filialnetzaenderung__c(
					Schliessung_avisiert_fuer__c = Date.today(),
					Filiale_Filialpartner__c = account.Id
			);
			insert filialnetzaenderung;
			
			Test.startTest();
			Task createdTask = ( Task ) TestFactory.createSObject(
					new Task(
							Aufgabenart__c = 'Vorbereitung Leistungsanpassung',
							RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
									.get( 'Akquiseauftrag' ).getRecordTypeId(),
							WhatId = account.Id,
							Status = 'Nicht begonnen',
							Filialnetzaenderung__c = filialnetzaenderung.Id
					),
					true
			);
			TaskTriggerHandler.processedIds = new Set<Id>();
			createdTask.Status = 'Erledigt';
			update createdTask;
			
			Test.stopTest();
			
			createdTask = [
					SELECT
							Id,
							CreatedDate,
							Erledigt_am__c,
							Status,
							Status_Anmerkung__c,
							Teilweise_Ausgabeverlagerung_Menge__c
					FROM Task
					WHERE Id = :createdTask.Id
					LIMIT 1
			];
			
			filialnetzaenderung = [
					SELECT
							Id,
							Akquise_beauftragt_am__c,
							Akquise_erledigt_am__c,
							Status_Akquise__c,
							Status_Anmerkung_Akquise__c,
							moegliche_Paketausgabemenge__c
					FROM Filialnetzaenderung__c
					WHERE Id = :filialnetzaenderung.Id
					LIMIT 1
			];
			
			System.assertEquals( createdTask.CreatedDate.date(), filialnetzaenderung.Akquise_beauftragt_am__c );
			System.assertEquals( createdTask.Status, filialnetzaenderung.Status_Akquise__c );
			System.assertEquals( createdTask.Status_Anmerkung__c, filialnetzaenderung.Status_Anmerkung_Akquise__c );
			System.assertEquals( createdTask.Teilweise_Ausgabeverlagerung_Menge__c, filialnetzaenderung.moegliche_Paketausgabemenge__c );
		}
	}
	
	/**
	 * @process FNÄ - autom. Aktualisierung Aufgabenstatus und Erledigt am
	 *
	 * @criteria DP Shop Immobiliensuche
	 */
	@IsTest
	static void testFNAEDPShopImmobiliensuche () {
		System.runAs( TestUser.create( TestUser.UserType.VL2001 ) ) {
			Account account = createAccount();
			Filialnetzaenderung__c filialnetzaenderung = new Filialnetzaenderung__c(
					Schliessung_avisiert_fuer__c = Date.today(),
					Filiale_Filialpartner__c = account.Id
			);
			insert filialnetzaenderung;
			
			Test.startTest();
			Task createdTask = ( Task ) TestFactory.createSObject(
					new Task(
							Aufgabenart__c = 'DP Shop Immobiliensuche',
							WhatId = account.Id,
							Status = 'Nicht begonnen',
							Filialnetzaenderung__c = filialnetzaenderung.Id
					),
					true
			);
			TaskTriggerHandler.processedIds = new Set<Id>();
			createdTask.Status = 'Erledigt';
			createdTask.Typc__c = 'Intern';
			update createdTask;
			
			Test.stopTest();
			
			createdTask = [
					SELECT
							Id,
							Erledigungsvermerk__c,
							Status_Anmerkung__c,
							Status,
							CreatedDate,
							Erledigt_am__c
					FROM Task
					WHERE Id = :createdTask.Id
					LIMIT 1
			];
			
			filialnetzaenderung = [
					SELECT
							Id,
							Immosuche_Sachstand__c,
							Immosuche_Status_Anmerkung__c,
							Immosuche_Status__c,
							Immosuche_beauftragt_am__c,
							Immosuche_erledigt_am__c
					FROM Filialnetzaenderung__c
					WHERE Id = :filialnetzaenderung.Id
					LIMIT 1
			];
			
			System.assertEquals( createdTask.Erledigungsvermerk__c, filialnetzaenderung.Immosuche_Sachstand__c );
			System.assertEquals( createdTask.Status_Anmerkung__c, filialnetzaenderung.Immosuche_Status_Anmerkung__c );
			System.assertEquals( createdTask.Status, filialnetzaenderung.Immosuche_Status__c );
			System.assertEquals( createdTask.CreatedDate.date(), filialnetzaenderung.Immosuche_beauftragt_am__c );
		}
	}
	
	/**
	 * @process FNÄ - autom. Aktualisierung Aufgabenstatus und Erledigt am
	 *
	 * @criteria Vorbereitung Filialumzug
	 */
	@IsTest
	static void testFNAEVorbereitungFilialumzug () {
		System.runAs( TestUser.create( TestUser.UserType.VL2001 ) ) {
			Account account = createAccount();
			Filialnetzaenderung__c filialnetzaenderung = new Filialnetzaenderung__c(
					Schliessung_avisiert_fuer__c = Date.today(),
					Filiale_Filialpartner__c = account.Id
			);
			insert filialnetzaenderung;
			
			Test.startTest();
			Task createdTask = ( Task ) TestFactory.createSObject(
					new Task(
							Aufgabenart__c = 'Vorbereitung Filialumzug',
							WhatId = account.Id,
							Status = 'Nicht begonnen',
							Filialnetzaenderung__c = filialnetzaenderung.Id
					),
					true
			);
			TaskTriggerHandler.processedIds = new Set<Id>();
			createdTask.Status = 'Erledigt';
			createdTask.Typc__c = 'Intern';
			update createdTask;
			
			Test.stopTest();
			
			createdTask = [
					SELECT
							Id,
							Erledigungsvermerk__c,
							Status_Anmerkung__c,
							Status,
							CreatedDate,
							Erledigt_am__c
					FROM Task
					WHERE Id = :createdTask.Id
					LIMIT 1
			];
			
			filialnetzaenderung = [
					SELECT
							Id,
							Akquise_beauftragt_am__c,
							Akquise_erledigt_am__c,
							Status_Akquise__c,
							Status_Anmerkung_Akquise__c,
							moegliche_Paketausgabemenge__c
					FROM Filialnetzaenderung__c
					WHERE Id = :filialnetzaenderung.Id
					LIMIT 1
			];
			
			System.assertEquals( createdTask.CreatedDate.date(), filialnetzaenderung.Akquise_beauftragt_am__c );
			System.assertEquals( createdTask.Status, filialnetzaenderung.Status_Akquise__c );
		}
	}
	
	/**
	 * @process FNÄ - autom. Aktualisierung Aufgabenstatus und Erledigt am
	 *
	 * @criteria DP Shop Personalgewinnung
	 */
	@IsTest
	static void testFNAEDPShopPersonalgewinnung () {
		System.runAs( TestUser.create( TestUser.UserType.VL2001 ) ) {
			Account account = createAccount();
			Filialnetzaenderung__c filialnetzaenderung = new Filialnetzaenderung__c(
					Schliessung_avisiert_fuer__c = Date.today(),
					Filiale_Filialpartner__c = account.Id
			);
			insert filialnetzaenderung;
			
			Test.startTest();
			Task createdTask = ( Task ) TestFactory.createSObject(
					new Task(
							Aufgabenart__c = 'DP Shop Personalgewinnung',
							WhatId = account.Id,
							Status = 'Nicht begonnen',
							Filialnetzaenderung__c = filialnetzaenderung.Id
					),
					true
			);
			TaskTriggerHandler.processedIds = new Set<Id>();
			createdTask.Status = 'Erledigt';
			createdTask.Typc__c = 'Intern';
			update createdTask;
			
			Test.stopTest();
			
			createdTask = [
					SELECT
							Id,
							Erledigungsvermerk__c,
							Status_Anmerkung__c,
							Status,
							CreatedDate,
							Erledigt_am__c
					FROM Task
					WHERE Id = :createdTask.Id
					LIMIT 1
			];
			
			filialnetzaenderung = [
					SELECT
							Id,
							Personalsuche_Sachstand__c,
							Personalsuche_Status_Anmerkung__c,
							Personalsuche_Status__c,
							Personalsuche_beauftragt_am__c,
							Personalsuche_erledigt_am__c
					FROM Filialnetzaenderung__c
					WHERE Id = :filialnetzaenderung.Id
					LIMIT 1
			];
			
			System.assertEquals( createdTask.Erledigungsvermerk__c, filialnetzaenderung.Personalsuche_Sachstand__c );
			System.assertEquals( createdTask.Status_Anmerkung__c, filialnetzaenderung.Personalsuche_Status_Anmerkung__c );
			System.assertEquals( createdTask.Status, filialnetzaenderung.Personalsuche_Status__c );
			System.assertEquals( createdTask.CreatedDate.date(), filialnetzaenderung.Personalsuche_beauftragt_am__c );
		}
	}
	
	/**
	 * @process FNÄ - autom. Aktualisierung Aufgabenstatus und Erledigt am
	 *
	 * @criteria Vergütungsberechnung
	 */
	@IsTest
	static void testFNAEVerguetungsberechnung () {
		System.runAs( TestUser.create( TestUser.UserType.VL2001 ) ) {
			Account account = createAccount();
			Filialnetzaenderung__c filialnetzaenderung = new Filialnetzaenderung__c(
					Schliessung_avisiert_fuer__c = Date.today(),
					Filiale_Filialpartner__c = account.Id
			);
			insert filialnetzaenderung;
			
			Test.startTest();
			Task createdTask = ( Task ) TestFactory.createSObject(
					new Task(
							Aufgabenart__c = 'Vergütungsberechnung',
							WhatId = account.Id,
							Status = 'Nicht begonnen',
							Filialnetzaenderung__c = filialnetzaenderung.Id
					),
					true
			);
			createdTask.Status = 'Erledigt';
			createdTask.Typc__c = 'Intern';
			update createdTask;
			
			Test.stopTest();
			
			createdTask = [
					SELECT
							Id,
							Referenz_ID_Fachseitensystem__c,
							Erledigung_bis_zum__c,
							CreatedDate
					FROM Task
					WHERE Id = :createdTask.Id
					LIMIT 1
			];
			
			filialnetzaenderung = [
					SELECT
							Id,
							Referenz_Id_VerA__c,
							Verguetungsberechnung_gueltig_bis__c,
							Verguetungsberechnung_vom__c
					FROM Filialnetzaenderung__c
					WHERE Id = :filialnetzaenderung.Id
					LIMIT 1
			];
			
			System.assertEquals( createdTask.Referenz_ID_Fachseitensystem__c, filialnetzaenderung.Referenz_Id_VerA__c );
			System.assertEquals( createdTask.Erledigung_bis_zum__c, filialnetzaenderung.Verguetungsberechnung_gueltig_bis__c );
			System.assertEquals( createdTask.CreatedDate.date(), filialnetzaenderung.Verguetungsberechnung_vom__c );
		
		}
	}
	
	/**
	 * @process FNÄ - autom. Aktualisierung Aufgabenstatus und Erledigt am
	 *
	 * @criteria Kündigungsrückgewinnung erfolgreich
	 */
	@IsTest
	static void testFNAEKuendigungsrueckgewinnungErfolgreich () {
		System.runAs( TestUser.create( TestUser.UserType.VL2001 ) ) {
			Account account = createAccount();
			Filialnetzaenderung__c filialnetzaenderung = new Filialnetzaenderung__c(
					Schliessung_avisiert_fuer__c = Date.today(),
					Filiale_Filialpartner__c = account.Id
			);
			insert filialnetzaenderung;
			
			Test.startTest();
			Task createdTask = ( Task ) TestFactory.createSObject(
					new Task(
							Aufgabenart__c = 'DHL Paketshop Kündigungsrückgewinnung',
							WhatId = account.Id,
							Filialnetzaenderung__c = filialnetzaenderung.Id
					),
					true
			);
			TaskTriggerHandler.processedIds = new Set<Id>();
			createdTask.Status = 'Erfolgreich';
			update createdTask;
			
			Test.stopTest();
			
			filialnetzaenderung = [
					SELECT
							Id,
							Grund__c
					FROM Filialnetzaenderung__c
					WHERE Id = :filialnetzaenderung.Id
					LIMIT 1
			];
			
			System.assertEquals( 'Kündigung zurückgezogen', filialnetzaenderung.Grund__c );
		}
	}
	
	/**
	 * @process MYPM-653 Erweiterung PrioHilfe - Filterung Niederlassung
	 */
	@IsTest
	static void testSettingNLBrief () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			Account account = createAccount();
			OrgE_DP__c orgEDP = new OrgE_DP__c(
					Aussenstellen_Ma__c = UserInfo.getUserId(),
					Koordinator__c = INTERFACE_USER.Id,
					Name = 'NL Brief'
			);
			insert orgEDP;
			account.NL_Brief_Lookup__c = orgEDP.Id;
			update account;
			
			Test.startTest();
			Task createdTask = ( Task ) TestFactory.createSObject(
					new Task(
							Aufgabenart__c = 'DHL Paketshop Kündigungsrückgewinnung',
							WhatId = account.Id
					),
					true
			);
			
			Test.stopTest();
			
			System.assertEquals( 'NL Brief', [
					SELECT
							NL_Brief__c
					FROM Task
					WHERE WhatId = :account.Id
					AND Id = :createdTask.Id
					LIMIT 1
			].NL_Brief__c );
		}
	}
	
	/**
	 * @process MYPM-863 Berücksichtigung Fächeranzahl in Akquiseauftrag Packstation
	 */
	@IsTest
	static void testChangedZielFachanzahl () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			Lead lead = createPackstationLead();
			Task createdTask = ( Task ) TestFactory.createSObject(
					new Task(
							Aufgabenart__c = 'Akquiseauftrag Packstation zu FNÄ',
							WhoId = lead.Id,
							RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
									.get( 'AkquiseauftragPackstation' ).getRecordTypeId()
					
					),
					true
			);
			
			Test.startTest();
			TaskTriggerHandler.processedIds = new Set<Id>();
			createdTask.ZielFachanzahl__c = 80;
			update createdTask;
			Test.stopTest();
			
			System.assertEquals( 1, [ SELECT Id FROM EmailVersand__c ].size() );
		}
	}
	
	/**
	 * @process MYPM-967] Aufgabe DP Shop Übernahme
	 */
	@IsTest
	static void testBegleitungUmzugUndUebernahmeFiliale () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			Account account = createAccount();
			account.Filialart__c = 'DPS';
			update account;
			
			Filialnetzaenderung__c filialnetzaenderung = new Filialnetzaenderung__c(
					Erledigungsdatum_FNAE__c = null,
					Schliessung_avisiert_fuer__c = Date.today(),
					Filiale_Filialpartner__c = account.Id,
					Grund__c = 'Umzug der Filiale'
			);
			insert filialnetzaenderung;
			
			Test.startTest();
			TriggerHandler.bypass( 'TaskTriggerHandler' );
			Task task = ( Task ) TestFactory.createSObject(
					new Task(
							Filialnetzaenderung__c = filialnetzaenderung.Id,
							Aufgabenart__c = 'DP Shop Immobiliensuche',
							RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
									.get( 'Aufgaben_zu_FNAE' ).getRecordTypeId(),
							Wiedervorlage_am__c = Datetime.now()
					),
					true
			);
			TriggerHandler.clearBypass( 'TaskTriggerHandler' );
			task.Status = 'Erledigt';
			update task;
			Test.stopTest();
			
			System.assertEquals( 1, [
					SELECT
							Id
					FROM Task
					WHERE Aufgabenart__c = 'Begleitung Umzug und Übernahme der Filiale + Detail'
			].size() );
		}
	}
	
	/**
	 * @process MYPM-968 Abänderung "Ermittlung Postfachsendungsmenge"
	 */
	@IsTest
	static void testErmittlungPostfachsendungsmenge () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			Account account = ( Account ) TestFactory.createSObject(
					new Account(
							Vertragsbetreuende_Einheit__c = insertOrgEDP().Id,
							Postfach_Betreiber__c = 'Partner'
					),
					true
			);
			insert new Abrechnungsinformation__c(
					SAP_Buchungsdatum__c = Date.today(),
					Filiale_Filialpartner__c = account.Id,
					Postfach__c = 500
			);
			
			
			Test.startTest();
			Task task = ( Task ) TestFactory.createSObject(
					new Task(
							Aufgabenart__c = 'Akquiseauftrag Filiale + Detail',
							RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
									.get( 'Akquiseauftrag' ).getRecordTypeId(),
							Auftrag_zur_PfA_Akquisition__c = 'mit Test',
							WhatId = account.Id
					),
					true
			);
			Test.stopTest();
			
			System.assertEquals( 1, [
					SELECT
							Id
					FROM Task
					WHERE Aufgabenart__c = 'Ermittlung Postfachsendungsmengen + Detail'
			].size() );
		}
	}
	
	/**
	 * @process MYPM-1965 Email Kündigugnsrückgewinnung Post- und Packstation
	 */
	@IsTest
	static void testEmailKuendigungsrueckgewinnung () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			Account account = ( Account ) TestFactory.createSObject(
					new Account(
							Vertragsbetreuende_Einheit__c = insertOrgEDP().Id,
							Postfach_Betreiber__c = 'Partner',
							GL__c = insertOrgEDP().Id
					),
					true
			);
			Task task = ( Task ) TestFactory.createSObject(
					new Task(
							WhatId = account.Id,
							Aufgabenart__c = 'Kündigungsrückgewinnung Pack-/Poststation',
							Auftraggeber__c = 'Regionale Vertriebsunterstützung',
							Auftragnehmer__c = 'Vertriebsmanager',
							ActivityDate = Date.today(),
							Erledigung_bis_zum__c = Date.today().addDays( 7 ),
							Priority = 'Mittel',
							Status = 'Nicht begonnen',
							Typc__c = 'Call',
							RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
									.get( 'AkquiseauftragPackstation' ).getRecordTypeId(),
							Filialnetzaenderung__c = account.Filialnetzaenderung__c
					),
					true
			);
			
			Test.startTest();
			TaskTriggerHandler.processedIds = new Set<Id>();
			task.Status = 'Erfolgreich';
			update task;
			Test.stopTest();
			
			System.assertEquals( 1, [ SELECT Id FROM EmailVersand__c ].size() );
		}
	}
	
	private static Account createAccount () {
		
		Account account = ( Account ) TestFactory.createSObject(
				new Account(
						Vertragsbetreuende_Einheit__c = insertOrgEDP().Id
				),
				true
		);
		return account;
	}
	
	private static Account createAccount ( String orgEDP ) {
		
		Account account = ( Account ) TestFactory.createSObject(
				new Account(
						GL__c = insertOrgEDP( orgEDP ).Id
				),
				true
		);
		return account;
	}
	
	private static Task createTask ( String auftragnehmer, Id whatID ) {
		
		Task task = ( Task ) TestFactory.createSObject(
				new Task(
						Auftragnehmer__c = auftragnehmer,
						WhatId = whatID
				),
				true
		);
		return task;
	}
	
	private static Task createTask ( String aufgabenart, String auftragnehmer, Id whatID ) {
		
		Task task = ( Task ) TestFactory.createSObject(
				new Task(
						Aufgabenart__c = aufgabenart,
						Auftragnehmer__c = auftragnehmer,
						WhatId = whatID,
						OwnerId = UserInfo.getUserId()
				),
				true
		);
		return task;
	}
	
	private static OrgE_DP__c insertOrgEDP () {
		
		OrgE_DP__c orgEDP = new OrgE_DP__c(
				Aussenstellen_Ma__c = UserInfo.getUserId(),
				Koordinator__c = INTERFACE_USER.Id,
				RVU_Team__c = insertRVU().Id
		);
		insert orgEDP;
		return orgEDP;
	}
	
	private static OrgE_DP__c insertRVU () {
		
		OrgE_DP__c orgEDP = new OrgE_DP__c(
				Aussenstellen_Ma__c = UserInfo.getUserId(),
				Koordinator__c = INTERFACE_USER.Id
		);
		insert orgEDP;
		return orgEDP;
	}
	
	private static OrgE_DP__c insertOrgEDP ( String name ) {
		
		OrgE_DP__c orgEDP = new OrgE_DP__c(
				Aussenstellen_Ma__c = UserInfo.getUserId(),
				Koordinator__c = INTERFACE_USER.Id,
				OrgE_DP_Name__c = name,
				RVU_Team__c = insertRVU().Id
		);
		insert orgEDP;
		return orgEDP;
	}
	
	private static Task addTask ( Account account ) {
		return ( Task ) TestFactory.createSObject(
				new Task(
						Auftraggeber__c = '3600 Forderungsmgmt Partner',
						Aufgabenart__c = 'Akquiseauftrag Filiale + Detail',
						Auftrag_zur_PartnerAkquise__c = '79',
						WhatId = account.Id
				),
				false
		);
	}
	
	private static Task addTask ( Account account, String auftraggeber ) {
		return ( Task ) TestFactory.createSObject(
				new Task(
						Auftraggeber__c = auftraggeber,
						Aufgabenart__c = 'Nachfass: Kontakt nach (angezeigter/vermuteter) Filialschließung + Detail',
						WhatId = account.Id
				),
				false
		);
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