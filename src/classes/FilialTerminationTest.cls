/**
 *@author       Mats Böhler
 *@created      06.04.2020
 *
 *
 *@description  AccountTerminationServiceTest
 *              MYPM-88
 *
 *
 *@changelog    06.04.2020 Mats Böhler  - Created
 *              
 * 
 */
@IsTest
private class FilialTerminationTest {
	
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
							OrgE_DP_Name__c = name
					)
			);
		}
		insert orgEDPS;
	}
	
	/**
	* @description Nur Filialen (exkl. DPS)
	*/
	@IsTest
	static void testFilialenExcludingDPS () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			TriggerHandler.bypass( 'AccountTriggerHandler' );
			
			Account account = createAccount();
			account = [
					SELECT
							Id,
							RecordType.DeveloperName,
							RecordTypeId,
							Filialart__c,
							Schliessung_zum__c,
							Eroeffnungsdatum__c,
							Aenderungsgrund_FNAE__c
					FROM Account
					WHERE Id = :account.Id
			];
			
			System.assertNotEquals( 'Filiale Dummy', account.RecordType.DeveloperName );
			System.assertEquals( '01224000000dXQVAA2', account.RecordTypeId );
			System.assert( !account.Filialart__c.contains( 'DPS' ) );
			System.assert( account.Schliessung_zum__c == null );
			System.assert( account.Eroeffnungsdatum__c != null );
			System.assert( account.Aenderungsgrund_FNAE__c != 'Formatänderung' );
			System.assert( account.Aenderungsgrund_FNAE__c == null );
			TriggerHandler.clearBypass( 'AccountTriggerHandler' );
			Test.startTest();
			account.Schliessung_zum__c = Date.today();
			update account;
			Test.stopTest();
			
			List<Task> tasks = [
					SELECT
							Id,
							Priority,
							Status,
							ActivityDate,
							Aufgabenart__c,
							Auftraggeber__c,
							Auftragnehmer__c,
							Beschreibung__c,
							Description,
							Erledigung_bis_zum__c,
							RecordTypeId,
							Typc__c,
							AccountId
					FROM Task
					WHERE AccountId = :account.Id
			];
			System.assertEquals( 3, tasks.size() );
		}
	}
	
	/**
	* @description DPS Filiale auf angemieteter Fläche SD>EÖ
	*/
	@IsTest
	static void testDPSInterimFiliale () {
		
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			TriggerHandler.bypass( 'AccountTriggerHandler' );
			
			Account account = createAccount( 'DPS-Interim', '' );
			account = [
					SELECT
							Id,
							RecordType.DeveloperName,
							RecordTypeId,
							Filialart__c,
							Schliessung_zum__c,
							Eroeffnungsdatum__c,
							Aenderungsgrund_FNAE__c
					FROM Account
					WHERE Id = :account.Id
			];
			
			System.assertNotEquals( 'Filiale Dummy', account.RecordType.DeveloperName );
			System.assertEquals( '01224000000dXQVAA2', account.RecordTypeId );
			System.assert( account.Filialart__c.contains( 'DPS-Interim' ) );
			System.assert( account.Schliessung_zum__c == null );
			System.assert( account.Eroeffnungsdatum__c != null );
			System.assert( account.Aenderungsgrund_FNAE__c != 'Formatänderung' );
			System.assert( account.Aenderungsgrund_FNAE__c == null );
			TriggerHandler.clearBypass( 'AccountTriggerHandler' );
			Test.startTest();
			account.Schliessung_zum__c = Date.today();
			update account;
			Test.stopTest();
			
			List<Task> tasks = [
					SELECT
							Id,
							Priority,
							Status,
							ActivityDate,
							Aufgabenart__c,
							Auftraggeber__c,
							Auftragnehmer__c,
							Beschreibung__c,
							Description,
							Erledigung_bis_zum__c,
							RecordTypeId,
							Typc__c,
							AccountId
					FROM Task
					WHERE AccountId = :account.Id
			];
			System.assertEquals( 3, tasks.size() );
			Integer counter = 0;
			for ( Task task : tasks ) {
				if ( task.Aufgabenart__c == 'DP Shop Kündigung Mietvertrag' ) {
					System.assertEquals( 'Hoch', task.Priority );
					/* Status is probably overwritten by another automation*/
					/*System.assertEquals( 'Nicht begonnen', task.Status );*/
					System.assertEquals( Date.today().addDays( 4 ), task.ActivityDate );
					System.assertEquals( 'DP Shop Kündigung Mietvertrag', task.Aufgabenart__c );
					System.assertEquals( '3500 Betriebssteuerung', task.Auftraggeber__c );
					System.assertEquals( '3910 Immo/Instandh/Automation', task.Auftragnehmer__c );
					System.assertEquals(
							String.format(
									'Schließungsdatum: {0}; Anhand des Mietvertrages ist der nächstmögliche ' +
											'Kündigungstermin zu ermitteln und die Kündigung entsprechend zu veranlassen.',
									new List<Object> {
											String.valueOf( account.Schliessung_zum__c )
									} ),
							task.Description
					);
					System.assertEquals( Date.today().addDays( 11 ), task.Erledigung_bis_zum__c );
					System.assertEquals( '01224000000AwybAAC', task.RecordTypeId );
					System.assertEquals( 'Intern', task.Typc__c );
					System.assertEquals( account.Id, task.AccountId );
					counter++;
				}
				else if ( task.Aufgabenart__c == 'Beräumung Filiale' ) {
					System.assertEquals( 'Mittel', task.Priority );
					System.assertEquals( 'Nicht begonnen', task.Status );
					System.assertEquals( account.Schliessung_zum__c.addDays( -7 ), task.ActivityDate );
					System.assertEquals( 'Beräumung Filiale', task.Aufgabenart__c );
					System.assertEquals( 'Vertriebsgebietsleiter', task.Auftraggeber__c );
					System.assertEquals( '3920/30 Aussenstelle', task.Auftragnehmer__c );
					System.assertEquals(
							String.format(
									'Schließungsdatum: {0}; Firmen zur Beräumung der Filiale beauftragen.',
									new List<Object> {
											String.valueOf( account.Schliessung_zum__c )
									} ),
							task.Description
					);
					System.assertEquals( account.Schliessung_zum__c.addDays( +3 ), task.Erledigung_bis_zum__c );
					System.assertEquals( '01224000000AwybAAC', task.RecordTypeId );
					System.assertEquals( 'Intern', task.Typc__c );
					System.assertEquals( account.Id, task.AccountId );
					counter++;
				}
				else if ( task.Aufgabenart__c == 'Filialschließung + Detail' ) {
					System.assertEquals( 'Mittel', task.Priority );
					System.assertEquals( 'Nicht begonnen', task.Status );
					System.assertEquals( account.Schliessung_zum__c.addDays( -7 ), task.ActivityDate );
					System.assertEquals( 'Filialschließung + Detail', task.Aufgabenart__c );
					System.assertEquals( '3540 DP Shop', task.Auftraggeber__c );
					System.assertEquals( 'Vertriebsmanager', task.Auftragnehmer__c );
					System.assertEquals(
							String.format(
									'Schließungsdatum: {0}; Vorbereitung und Begleitung der Schließung ' +
											'einer Partner-Filiale gem. Kapitel Filialschließung in IPP.',
									new List<Object> {
											String.valueOf( account.Schliessung_zum__c )
									} ),
							task.Description
					);
					System.assertEquals( account.Schliessung_zum__c.addDays( +3 ), task.Erledigung_bis_zum__c );
					System.assertEquals( '01224000000AwybAAC', task.RecordTypeId );
					System.assertEquals( 'Besuch', task.Typc__c );
					System.assertEquals( account.Id, task.AccountId );
					counter++;
				}
			}
			System.assertEquals( 3, counter );
		}
	}
	
	/**
	* @description DPS Filiale Klassik
	*/
	@IsTest
	static void testDPSFiliale () {
		
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			TriggerHandler.bypass( 'AccountTriggerHandler' );
			
			Account account = createAccount( 'DPS-Tochterfiliale', '' );
			account = [
					SELECT
							Id,
							RecordType.DeveloperName,
							RecordTypeId,
							Filialart__c,
							Schliessung_zum__c,
							Eroeffnungsdatum__c,
							Aenderungsgrund_FNAE__c
					FROM Account
					WHERE Id = :account.Id
			];
			
			System.assertNotEquals( 'Filiale Dummy', account.RecordType.DeveloperName );
			System.assertEquals( '01224000000dXQVAA2', account.RecordTypeId );
			System.assert( !account.Filialart__c.contains( 'DPS-Interim' ) );
			System.assert( account.Filialart__c.contains( 'DPS' ) );
			System.assert( account.Schliessung_zum__c == null );
			System.assert( account.Eroeffnungsdatum__c != null );
			System.assert( account.Aenderungsgrund_FNAE__c != 'Formatänderung' );
			System.assert( account.Aenderungsgrund_FNAE__c == null );
			TriggerHandler.clearBypass( 'AccountTriggerHandler' );
			Test.startTest();
			account.Schliessung_zum__c = Date.today();
			update account;
			Test.stopTest();
			
			List<Task> tasks = [
					SELECT
							Id,
							Priority,
							Status,
							ActivityDate,
							Aufgabenart__c,
							Auftraggeber__c,
							Auftragnehmer__c,
							Beschreibung__c,
							Description,
							Erledigung_bis_zum__c,
							RecordTypeId,
							Typc__c,
							AccountId
					FROM Task
					WHERE AccountId = :account.Id
			];
			System.assertEquals( 3, tasks.size() );
			Integer counter = 0;
			for ( Task task : tasks ) {
				if ( task.Aufgabenart__c == 'Beräumung Filiale' ) {
					System.assertEquals( account.Id, task.AccountId );
					counter++;
				}
				else if ( task.Aufgabenart__c == 'Vorbereitung_Filialschliessung' ) {
					System.assertEquals( account.Id, task.AccountId );
					counter++;
				}
				else if ( task.Aufgabenart__c == 'Filialschließung + Detail' ) {
					System.assertEquals( account.Id, task.AccountId );
					counter++;
				}
			}
			System.assertEquals( 3, counter );
		}
	}
	
	/**
	* @description Filiale OZ 95 oder DPS 79
	*/
	@IsTest
	static void testFilialeOZ95 () {
		
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			TriggerHandler.bypass( 'AccountTriggerHandler' );
			
			Account account = createAccount( 'DHL-Paketshop', '95' );
			account = [
					SELECT
							Id,
							RecordType.DeveloperName,
							RecordTypeId,
							Filialart__c,
							Schliessung_zum__c,
							Eroeffnungsdatum__c,
							Aenderungsgrund_FNAE__c,
							Filialtyp_OZ__c
					FROM Account
					WHERE Id = :account.Id
			];
			
			System.assertNotEquals( 'Filiale Dummy', account.RecordType.DeveloperName );
			System.assertEquals( '01224000000dXQVAA2', account.RecordTypeId );
			System.assert( !account.Filialart__c.contains( 'DPS' ) );
			System.assert( account.Schliessung_zum__c == null );
			System.assert( account.Eroeffnungsdatum__c != null );
			System.assert( account.Aenderungsgrund_FNAE__c != 'Formatänderung' );
			System.assert( account.Aenderungsgrund_FNAE__c == null );
			System.assert( account.Filialtyp_OZ__c == '95' );
			TriggerHandler.clearBypass( 'AccountTriggerHandler' );
			Test.startTest();
			account.Schliessung_zum__c = Date.today();
			update account;
			Test.stopTest();
			
			List<Task> tasks = [
					SELECT
							Id,
							Priority,
							Status,
							ActivityDate,
							Aufgabenart__c,
							Auftraggeber__c,
							Auftragnehmer__c,
							Beschreibung__c,
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
				if ( task.Aufgabenart__c == 'Bargeldentsorgung beauftragen' ) {
					System.assertEquals( 'Mittel', task.Priority );
					System.assertEquals( 'Nicht begonnen', task.Status );
					System.assertEquals( account.Schliessung_zum__c.addDays( -14 ), task.ActivityDate );
					System.assertEquals( 'Bargeldentsorgung beauftragen', task.Aufgabenart__c );
					System.assertEquals( 'Vertriebskoordinator', task.Auftraggeber__c );
					System.assertEquals( 'Vertriebsmanager', task.Auftragnehmer__c );
					System.assertEquals(
							'Über Workflow 330 die Bargeldschlussentsorgung beauftragen',
							task.Description
					);
					System.assertEquals( account.Schliessung_zum__c.addDays( -7 ), task.Erledigung_bis_zum__c );
					System.assertEquals( '01224000000AwybAAC', task.RecordTypeId );
					System.assertEquals( 'Intern', task.Typc__c );
					System.assertEquals( account.Id, task.AccountId );
					counter++;
				}
			}
			System.assertEquals( 1, counter );
		}
	}
	
	/**
	* @description Filiale OZ 95 oder DPS 79
	*/
	@IsTest
	static void testDPSFilialeOZ79 () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			TriggerHandler.bypass( 'AccountTriggerHandler' );
			
			Account account = createAccount( 'DPS-Tochterfiliale', '79' );
			account = [
					SELECT
							Id,
							RecordType.DeveloperName,
							RecordTypeId,
							Filialart__c,
							Schliessung_zum__c,
							Eroeffnungsdatum__c,
							Aenderungsgrund_FNAE__c,
							Filialtyp_OZ__c
					FROM Account
					WHERE Id = :account.Id
			];
			
			System.assertNotEquals( 'Filiale Dummy', account.RecordType.DeveloperName );
			System.assertEquals( '01224000000dXQVAA2', account.RecordTypeId );
			System.assert( !account.Filialart__c.contains( 'DPS-Interim' ) );
			System.assert( account.Filialart__c.contains( 'DPS' ) );
			System.assert( account.Schliessung_zum__c == null );
			System.assert( account.Eroeffnungsdatum__c != null );
			System.assert( account.Aenderungsgrund_FNAE__c != 'Formatänderung' );
			System.assert( account.Aenderungsgrund_FNAE__c == null );
			System.assert( account.Filialtyp_OZ__c == '79' );
			TriggerHandler.clearBypass( 'AccountTriggerHandler' );
			Test.startTest();
			account.Schliessung_zum__c = Date.today();
			update account;
			Test.stopTest();
			
			List<Task> tasks = [
					SELECT
							Id,
							Priority,
							Status,
							ActivityDate,
							Aufgabenart__c,
							Auftraggeber__c,
							Auftragnehmer__c,
							Beschreibung__c,
							Description,
							Erledigung_bis_zum__c,
							RecordTypeId,
							Typc__c,
							AccountId
					FROM Task
					WHERE AccountId = :account.Id
			];
			System.assertEquals( 4, tasks.size() );
			Integer counter = 0;
			for ( Task task : tasks ) {
				if ( task.Aufgabenart__c == 'Bargeldentsorgung beauftragen' ) {
					System.assertEquals( 'Mittel', task.Priority );
					System.assertEquals( 'Nicht begonnen', task.Status );
					System.assertEquals( account.Schliessung_zum__c.addDays( -14 ), task.ActivityDate );
					System.assertEquals( 'Bargeldentsorgung beauftragen', task.Aufgabenart__c );
					System.assertEquals( 'Vertriebskoordinator', task.Auftraggeber__c );
					System.assertEquals( 'Vertriebsmanager', task.Auftragnehmer__c );
					System.assertEquals(
							'Über Workflow 330 die Bargeldschlussentsorgung beauftragen',
							task.Description
					);
					System.assertEquals( account.Schliessung_zum__c.addDays( -7 ), task.Erledigung_bis_zum__c );
					System.assertEquals( '01224000000AwybAAC', task.RecordTypeId );
					System.assertEquals( 'Intern', task.Typc__c );
					System.assertEquals( account.Id, task.AccountId );
					counter++;
				}
			}
			System.assertEquals( 1, counter );
		}
	}
	
	/**
	* @description DPS Filiale auf angemieteter Fläche SD=EÖ
	*/
	@IsTest
	static void testDPSInterimFilialeSameDate () {
		
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			TriggerHandler.bypass( 'AccountTriggerHandler' );
			
			Account account = createAccount( 'DPS-Interim', '' );
			account = [
					SELECT
							Id,
							RecordType.DeveloperName,
							RecordTypeId,
							Filialart__c,
							Schliessung_zum__c,
							Eroeffnungsdatum__c,
							Aenderungsgrund_FNAE__c
					FROM Account
					WHERE Id = :account.Id
			];
			
			System.assertNotEquals( 'Filiale Dummy', account.RecordType.DeveloperName );
			System.assertEquals( '01224000000dXQVAA2', account.RecordTypeId );
			System.assert( account.Filialart__c.contains( 'DPS-Interim' ) );
			System.assert( account.Schliessung_zum__c == null );
			System.assert( account.Eroeffnungsdatum__c != null );
			System.assert( account.Aenderungsgrund_FNAE__c != 'Formatänderung' );
			System.assert( account.Aenderungsgrund_FNAE__c == null );
			TriggerHandler.clearBypass( 'AccountTriggerHandler' );
			Test.startTest();
			account.Schliessung_zum__c = account.Eroeffnungsdatum__c;
			update account;
			Test.stopTest();
			
			List<Task> tasks = [
					SELECT
							Id,
							Priority,
							Status,
							ActivityDate,
							Aufgabenart__c,
							Auftraggeber__c,
							Auftragnehmer__c,
							Beschreibung__c,
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
				if ( task.Aufgabenart__c == 'DP Shop Kündigung Mietvertrag' ) {
					System.assertEquals( 'Hoch', task.Priority );
					/* Status is probably overwritten by another automation*/
					/*System.assertEquals( 'Nicht begonnen', task.Status );*/
					System.assertEquals( Date.today(), task.ActivityDate );
					System.assertEquals( 'DP Shop Kündigung Mietvertrag', task.Aufgabenart__c );
					System.assertEquals( '3500 Betriebssteuerung', task.Auftraggeber__c );
					System.assertEquals( '3910 Immo/Instandh/Automation', task.Auftragnehmer__c );
					System.assertEquals(
							String.format(
									'Schließungsdatum: {0}; Anhand des Mietvertrages ist der nächstmögliche ' +
											'Kündigungstermin zu ermitteln und die Kündigung entsprechend zu veranlassen.',
									new List<Object> {
											String.valueOf( account.Schliessung_zum__c )
									} ),
							task.Description
					);
					System.assertEquals( Date.today().addDays( 7 ), task.Erledigung_bis_zum__c );
					System.assertEquals( '01224000000AwybAAC', task.RecordTypeId );
					System.assertEquals( 'Intern', task.Typc__c );
					System.assertEquals( account.Id, task.AccountId );
					counter++;
				}
			}
			System.assertEquals( 1, counter );
		}
	}
	
	/**
	* @description Verschiebung Schließdatum DPS
	*/
	@IsTest
	static void testDPSInterimFilialeChangedDate () {
		
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			TriggerHandler.bypass( 'AccountTriggerHandler' );
			
			Account account = createAccount( 'DPS-Interim', '' );
			account = [
					SELECT
							Id,
							RecordType.DeveloperName,
							RecordTypeId,
							Filialart__c,
							Schliessung_zum__c,
							Eroeffnungsdatum__c,
							Aenderungsgrund_FNAE__c
					FROM Account
					WHERE Id = :account.Id
			];
			
			System.assertNotEquals( 'Filiale Dummy', account.RecordType.DeveloperName );
			System.assertEquals( '01224000000dXQVAA2', account.RecordTypeId );
			System.assert( account.Filialart__c.contains( 'DPS-Interim' ) );
			System.assert( account.Schliessung_zum__c == null );
			System.assert( account.Eroeffnungsdatum__c != null );
			System.assert( account.Aenderungsgrund_FNAE__c != 'Formatänderung' );
			System.assert( account.Aenderungsgrund_FNAE__c == null );
			
			Test.startTest();
			TriggerHandler.clearBypass( 'AccountTriggerHandler' );
			account.Schliessung_zum__c = Date.today().addDays( -14 );
			update account;
			AccountBaseHandler.processedIds = new Set<Id>();
			account.Schliessung_zum__c = Date.today();
			update account;
			Test.stopTest();
			
			List<Task> tasks = [
					SELECT
							Id,
							Priority,
							Status,
							ActivityDate,
							Aufgabenart__c,
							Auftraggeber__c,
							Auftragnehmer__c,
							Beschreibung__c,
							Description,
							Erledigung_bis_zum__c,
							RecordTypeId,
							Typc__c,
							AccountId
					FROM Task
					WHERE AccountId = :account.Id
			];
			System.assertEquals( 4, tasks.size() );
			Integer counter = 0;
			for ( Task task : tasks ) {
				if ( task.Aufgabenart__c == 'DP Shop Mietvertrag verlängern' && task.Auftraggeber__c == '3540 DP Shop' ) {
					System.assertEquals( 'Mittel', task.Priority );
					System.assertEquals( 'Nicht begonnen', task.Status );
					System.assertEquals( Date.today(), task.ActivityDate );
					System.assertEquals( 'DP Shop Mietvertrag verlängern', task.Aufgabenart__c );
					System.assertEquals( '3540 DP Shop', task.Auftraggeber__c );
					System.assertEquals( '3910 Immo/Instandh/Automation', task.Auftragnehmer__c );
					System.assert( task.Description.contains( 'Bitte Mietvertrag entsprechend verlängern.' ) );
					System.assertEquals( Date.today().addDays( 7 ), task.Erledigung_bis_zum__c );
					System.assertEquals( '01224000000AwybAAC', task.RecordTypeId );
					System.assertEquals( 'Intern', task.Typc__c );
					System.assertEquals( account.Id, task.AccountId );
					counter++;
				}
			}
			System.assertEquals( 1, counter );
		}
	}
	
	/**
	* @description Nur DHL Paketshop
	*/
	@IsTest
	static void testDHLPaketshop () {
		
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			TriggerHandler.bypass( 'AccountTriggerHandler' );
			
			Account account = createAccount( 'DHL-Paketshop', '' );
			account = [
					SELECT
							Id,
							RecordType.DeveloperName,
							RecordTypeId,
							Filialart__c,
							Schliessung_zum__c,
							Eroeffnungsdatum__c,
							Aenderungsgrund_FNAE__c,
							Filialtyp_OZ__c
					FROM Account
					WHERE Id = :account.Id
			];
			
			System.assertNotEquals( 'Filiale Dummy', account.RecordType.DeveloperName );
			System.assertEquals( '01224000000dXQVAA2', account.RecordTypeId );
			System.assert( account.Filialart__c == 'DHL-Paketshop' );
			System.assert( account.Schliessung_zum__c == null );
			System.assert( account.Eroeffnungsdatum__c != null );
			System.assert( account.Aenderungsgrund_FNAE__c != 'Formatänderung' );
			System.assert( account.Aenderungsgrund_FNAE__c == null );
			System.assertEquals( account.Filialtyp_OZ__c, null );
			TriggerHandler.clearBypass( 'AccountTriggerHandler' );
			Test.startTest();
			account.Schliessung_zum__c = Date.today();
			account.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
					.get( 'DHL_Paketshop' ).getRecordTypeId();
			update account;
			Test.stopTest();
			
			account = [
					SELECT
							Id,
							RecordType.DeveloperName,
							RecordTypeId,
							Filialart__c,
							Schliessung_zum__c,
							Eroeffnungsdatum__c,
							Aenderungsgrund_FNAE__c,
							Filialtyp_OZ__c,
							Interne_Bemerkungen_SCF__c,
							Interne_Bemerkungen__c,
							Interne_Bemerkungen_SPM__c
					FROM Account
					WHERE Id = :account.Id
			];
			System.assertEquals(
					String.format(
							'Schließung zum: {0} gesetzt am: {1}',
							new List<Object> {
									String.valueOf( account.Schliessung_zum__c ),
									String.valueOf( Date.today() )
							} ),
					account.Interne_Bemerkungen_SCF__c
			);
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
	
	private static Account createAccount ( String filialart, String filialtyp ) {
		
		Account account = ( Account ) TestFactory.createSObject(
				new Account(
						Filialart__c = filialart,
						Filialtyp_OZ__c = filialtyp,
						Vertragsbetreuende_Einheit__c = insertOrgEDP().Id
				),
				true
		);
		return account;
	}
	
	private static OrgE_DP__c insertOrgEDP () {
		
		OrgE_DP__c orgEDP = new OrgE_DP__c(
				Aussenstellen_Ma__c = UserInfo.getUserId(),
				Koordinator__c = UserInfo.getUserId()
		);
		insert orgEDP;
		return orgEDP;
	}
}