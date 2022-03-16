/**
 *@author       Mats Böhler
 *@created      27.05.2020
 *
 *
 *@description  LeadTriggerHandlerTest
 *
 *
 *@changelog    27.05.2020 Mats Böhler  - Created
 *              
 * 
 */
@IsTest
private class LeadTriggerHandlerTest {
	
	@IsTest
	static void testBulk () {
		List<Lead> leads = createLeads( 1 );
		Test.startTest();
		for ( Lead lead : leads ) {
			lead.Bewertung_Zentrale__c = 'Durch Zentrale STOG abgelehnt';
		}
		update leads;
		Test.stopTest();
		
		System.assertEquals( 1, [ SELECT Id FROM Lead ].size() );
	}
	
	@IsTest
	static void testPackstationLeadOwnerAssignment () {
		Account orgE = createOrgE();
		Lead lead = createPackstationLead();
		
		Test.startTest();
		lead.VL__c = null;
		update lead;
		lead.VL__c = [ SELECT Id FROM Account LIMIT 1 ].Id;
		update lead;
		Test.stopTest();
		
		lead = [ SELECT Id, OwnerId, VL__r.OwnerId FROM Lead WHERE Id = :lead.Id ];
		System.assertEquals( lead.OwnerId, lead.VL__r.OwnerId );
	}
	
	@IsTest
	static void testWeidenEingangsbestaetigung () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			EmailDispatcherService.disableDeleteExistingContentDocumentLinks = true;
			
			Test.startTest();
			Lead lead = createLeadWithSource( 'Weiden' );
			Test.stopTest();
			
			System.assertEquals( 1, [
					SELECT
							Id
					FROM EmailVersand__c
					WHERE Dokument__c = 'WeidenEingangsbestaetigung'
					AND Lead__c = :lead.Id
			].size() );
		}
	}
	
	@IsTest
	static void testKommuneEingangsbestaetigung () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			EmailDispatcherService.disableDeleteExistingContentDocumentLinks = true;
			
			Test.startTest();
			Lead lead = createLeadWithSource( 'Kommune' );
			Test.stopTest();
			
			System.assertEquals( 1, [
					SELECT
							Id
					FROM EmailVersand__c
					WHERE Dokument__c = 'KommuneEingangsbestaetigung'
					AND Lead__c = :lead.Id
			].size() );
		}
	}
	
	@IsTest
	static void testWeidenEignung () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			EmailDispatcherService.disableDeleteExistingContentDocumentLinks = true;
			Lead lead = createLeadWithSource( 'Weiden' );
			
			Test.startTest();
			LeadTriggerHandler.processedIds = new Set<Id>();
			lead.Bewertung_Zentrale__c = 'Geeignet';
			update lead;
			Test.stopTest();
			
			System.assertEquals( 1, [
					SELECT
							Id
					FROM EmailVersand__c
					WHERE Dokument__c = 'WeidenEignung'
					AND Lead__c = :lead.Id
			].size() );
		}
	}
	
	@IsTest
	static void testKommuneEignung () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			EmailDispatcherService.disableDeleteExistingContentDocumentLinks = true;
			Lead lead = createLeadWithSource( 'Kommune' );
			
			Test.startTest();
			LeadTriggerHandler.processedIds = new Set<Id>();
			lead.Bewertung_Zentrale__c = 'Geeignet';
			update lead;
			Test.stopTest();
			
			System.assertEquals( 1, [
					SELECT
							Id
					FROM EmailVersand__c
					WHERE Dokument__c = 'KommuneEignung'
					AND Lead__c = :lead.Id
			].size() );
		}
	}
	
	@IsTest
	static void testWeidenAbsageFehlenderBedarf () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			EmailDispatcherService.disableDeleteExistingContentDocumentLinks = true;
			Lead lead = createLeadWithSource( 'Weiden' );
			
			Test.startTest();
			LeadTriggerHandler.processedIds = new Set<Id>();
			lead.Bewertung_VM__c = 'Absage DHL - kein Potenzial';
			update lead;
			Test.stopTest();
			
			System.assertEquals( 1, [
					SELECT
							Id
					FROM EmailVersand__c
					WHERE Dokument__c = 'WeidenAbsageFehlenderBedarf'
					AND Lead__c = :lead.Id
			].size() );
		}
	}
	
	@IsTest
	static void testWeidenAbsageFehlenderBedarfBewertungZentrale () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			EmailDispatcherService.disableDeleteExistingContentDocumentLinks = true;
			Lead lead = createLeadWithSource( 'Weiden' );
			
			Test.startTest();
			LeadTriggerHandler.processedIds = new Set<Id>();
			lead.Bewertung_Zentrale__c = 'Geeignet, kein Bedarf';
			update lead;
			Test.stopTest();
			
			System.assertEquals( 1, [
					SELECT
							Id
					FROM EmailVersand__c
					WHERE Dokument__c = 'WeidenAbsageFehlenderBedarf'
					AND Lead__c = :lead.Id
			].size() );
		}
	}
	
	@IsTest
	static void testKommuneAbsageFehlenderBedarfBewertungZentrale () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			EmailDispatcherService.disableDeleteExistingContentDocumentLinks = true;
			TriggerHandler.bypass('LeadTriggerHandler');
			Lead lead = createLeadWithSource( 'Kommune' );
			TriggerHandler.clearAllBypasses();
			
			Test.startTest();
			LeadTriggerHandler.processedIds = new Set<Id>();
			lead.Bewertung_Zentrale__c = 'Geeignet, kein Bedarf';
			update lead;
			Test.stopTest();

			System.assertEquals( 1, [
					SELECT
							Id
					FROM EmailVersand__c
					WHERE Dokument__c = 'KommuneAbsageFehlenderBedarf'
					AND Lead__c = :lead.Id
			].size() );
		}
	}
	
	@IsTest
	static void testKommuneAbsageFehlenderBedarf () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			EmailDispatcherService.disableDeleteExistingContentDocumentLinks = true;
			Lead lead = createLeadWithSource( 'Kommune' );
			
			Test.startTest();
			LeadTriggerHandler.processedIds = new Set<Id>();
			lead.Bewertung_VM__c = 'Absage DHL - kein Potenzial';
			update lead;
			Test.stopTest();
			
			System.assertEquals( 1, [
					SELECT
							Id
					FROM EmailVersand__c
					WHERE Dokument__c = 'KommuneAbsageFehlenderBedarf'
					AND Lead__c = :lead.Id
			].size() );
		}
	}
	
	@IsTest
	static void testWeidenAbsageZuGeringerBedarf () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			EmailDispatcherService.disableDeleteExistingContentDocumentLinks = true;
			Lead lead = createLeadWithSource( 'Weiden' );
			
			Test.startTest();
			LeadTriggerHandler.processedIds = new Set<Id>();
			lead.Bewertung_Zentrale__c = 'Nicht geeignet, zu geringes Potenzial';
			lead.Potenzial__c = 'E - PLZ-Gebiet ohne Bedarf';
			update lead;
			Test.stopTest();
			
			System.assertEquals( 1, [
					SELECT
							Id
					FROM EmailVersand__c
					WHERE Dokument__c = 'WeidenAbsageZuGeringerBedarf'
					AND Lead__c = :lead.Id
			].size() );
		}
	}
	
	@IsTest
	static void testKommuneAbsageZuGeringerBedarf () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			EmailDispatcherService.disableDeleteExistingContentDocumentLinks = true;
			Lead lead = createLeadWithSource( 'Kommune' );
			
			Test.startTest();
			LeadTriggerHandler.processedIds = new Set<Id>();
			lead.Bewertung_Zentrale__c = 'Nicht geeignet, zu geringes Potenzial';
			lead.Potenzial__c = 'E - PLZ-Gebiet ohne Bedarf';
			update lead;
			Test.stopTest();
			
			System.assertEquals( 1, [
					SELECT
							Id
					FROM EmailVersand__c
					WHERE Dokument__c = 'KommuneAbsageZuGeringerBedarf'
					AND Lead__c = :lead.Id
			].size() );
		}
	}
	
	@IsTest
	static void testWeidenAbsageMikrostandort () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			EmailDispatcherService.disableDeleteExistingContentDocumentLinks = true;
			Lead lead = createLeadWithSource( 'Weiden' );
			
			Test.startTest();
			LeadTriggerHandler.processedIds = new Set<Id>();
			lead.Bewertung_VM__c = 'Absage DHL - kein Mikro-STO';
			update lead;
			Test.stopTest();
			
			System.assertEquals( 1, [
					SELECT
							Id
					FROM EmailVersand__c
					WHERE Dokument__c = 'WeidenAbsageMikrostandort'
					AND Lead__c = :lead.Id
			].size() );
		}
	}
	
	@IsTest
	static void testAkquiseauftragPackstationZusaetzlicheEinrichtung () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			Account account = createOrgE();
			Filialnetzaenderung__c filialnetzaenderung = new Filialnetzaenderung__c(
					Erledigungsdatum_FNAE__c = null,
					Zu_erwartender_Debitor__c = '12345',
					Schliessung_avisiert_fuer__c = Date.today(),
					Filiale_Filialpartner__c = account.Id,
					VL_Filialvertrieb__c = account.Id
			);
			insert filialnetzaenderung;
			Lead lead = ( Lead ) TestFactory.createSObject(
					new Lead(
							RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName()
									.get( 'Packstation' ).getRecordTypeId(),
							PostalCode = '12345',
							LeadSource = 'VL',
							Potenzial__c = '3 - mittel',
							Filialnetzaenderung__c = filialnetzaenderung.Id
					),
					true
			);
			
			Test.startTest();
			LeadTriggerHandler.processedIds = new Set<Id>();
			lead.Bewertung_Zentrale__c = 'Geeignet - Priorisierte Bearbeitung';
			update lead;
			Test.stopTest();
			
			List<Task> tasks = [
					SELECT
							Id,
							Filialnetzaenderung__c,
							WhoId
					FROM Task
					WHERE Aufgabenart__c = 'Akquiseauftrag Packstation - Priorisierte Bearbeitung'
			];
			
			System.assertEquals( 1, tasks.size() );
			System.assertEquals( lead.Id, tasks[ 0 ].WhoId );
		}
	}
	
	/**
	 * @story  [MYPM-1116] Afo # 210: Überarbeitung Akquiseauftrag priorisierte Bearbeitung
	 */
	@IsTest
	static void testAkquiseauftragPackstationHotlead () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			Account account = createOrgE();
			Filialnetzaenderung__c filialnetzaenderung = new Filialnetzaenderung__c(
					Erledigungsdatum_FNAE__c = null,
					Zu_erwartender_Debitor__c = '12345',
					Schliessung_avisiert_fuer__c = Date.today(),
					Filiale_Filialpartner__c = account.Id,
					VL_Filialvertrieb__c = account.Id
			);
			insert filialnetzaenderung;
			Lead lead = ( Lead ) TestFactory.createSObject(
					new Lead(
							RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName()
									.get( 'Packstation' ).getRecordTypeId(),
							PostalCode = '12345',
							LeadSource = 'VL',
							Potenzial__c = '3 - mittel',
							Filialnetzaenderung__c = filialnetzaenderung.Id
					),
					true
			);
			
			Test.startTest();
			LeadTriggerHandler.processedIds = new Set<Id>();
			lead.Bewertung_Zentrale__c = 'Geeignet - Hotlead';
			update lead;
			Test.stopTest();
			
			List<Task> tasks = [
					SELECT
							Id,
							Filialnetzaenderung__c,
							WhoId
					FROM Task
					WHERE Aufgabenart__c = 'Akquiseauftrag Packstation - Priorisierte Bearbeitung'
			];
			
			System.assertEquals( 1, tasks.size() );
			System.assertEquals( lead.Id, tasks[ 0 ].WhoId );
		}
	}
	
	@IsTest
	static void testAkquiseauftragPackstationZusaetzlicheEinrichtungRvu () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			Account account = createOrgE();
			Filialnetzaenderung__c filialnetzaenderung = new Filialnetzaenderung__c(
					Erledigungsdatum_FNAE__c = null,
					Zu_erwartender_Debitor__c = '12345',
					Schliessung_avisiert_fuer__c = Date.today(),
					Filiale_Filialpartner__c = account.Id,
					VL_Filialvertrieb__c = account.Id
			);
			insert filialnetzaenderung;
			Lead lead = ( Lead ) TestFactory.createSObject(
					new Lead(
							RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName()
									.get( 'Packstation' ).getRecordTypeId(),
							PostalCode = '12345',
							LeadSource = 'VL',
							Potenzial__c = '3 - mittel',
							Filialnetzaenderung__c = filialnetzaenderung.Id
					),
					true
			);
			
			Test.startTest();
			lead.Akquisemodus__c = 'Standortaufnahme vor Ort; Danach Übergabe an rVU';
			lead.Bewertung_Zentrale__c = 'Geeignet - Priorisierte Bearbeitung';
			update lead;
			Test.stopTest();
			
			List<Task> tasks = [
					SELECT
							Id,
							Filialnetzaenderung__c,
							WhoId
					FROM Task
					WHERE Aufgabenart__c = 'Akquiseauftrag Packstation - Priorisierte Bearbeitung'
			];
			
			System.assertEquals( 0, tasks.size() );
		}
	}
	
	@IsTest
	static void testAkquiseauftragPackstationStandortdokumentationVerschicken () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			Test.startTest();
			Lead lead = ( Lead ) TestFactory.createSObject(
					new Lead(
							RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName()
									.get( 'Packstation' ).getRecordTypeId(),
							PostalCode = '12345',
							LeadSource = 'VL',
							Potenzial__c = '3 - mittel',
							Bauordnungsrechtliche_Pruefung__c = 'Prüfung der Baugenehmigungsfreiheit',
							Bauordnungsrechtliche_Pruefung_Datum__c = Date.today(),
							Bewertung_Zentrale__c = 'Geeignet',
							DokumentationDurchRTFreigebenDatum__c = Date.today().addDays( 10 )
					),
					true
			);
			Test.stopTest();
			
			List<Task> tasks = [
					SELECT
							Id,
							Filialnetzaenderung__c,
							WhoId
					FROM Task
					WHERE Aufgabenart__c = 'Standortdokumentation verschicken und Freigabe STOG einholen'
			];
			
			System.assertEquals( 1, tasks.size() );
			System.assertEquals( lead.Id, tasks[ 0 ].WhoId );
		}
	}
	
	@IsTest
	static void testDefaultFields () {
		
		System.runAs( TestUser.create( TestUser.UserType.AO ) ) {
			
			Account account = createOrgE();
			Filialnetzaenderung__c filialnetzaenderung = new Filialnetzaenderung__c(
					Erledigungsdatum_FNAE__c = null,
					Zu_erwartender_Debitor__c = '12345',
					Schliessung_avisiert_fuer__c = Date.today(),
					Filiale_Filialpartner__c = account.Id,
					VL_Filialvertrieb__c = account.Id,
					Neuer_Standort_Stadt__c = '123',
					Neuer_Standort_PLZ__c = '123',
					Neuer_Standort_Strasse__c = '123'
			);
			insert filialnetzaenderung;
			
			
			Test.startTest();
			Lead lead = ( Lead ) TestFactory.createSObject(
					new Lead(
							RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName()
									.get( 'Packstation' ).getRecordTypeId(),
							PostalCode = '12345',
							LeadSource = 'VL',
							Bewerbung_vom__c = Date.today().addDays( -1 ),
							Filialnetzaenderung__c = filialnetzaenderung.Id
					),
					true
			);
			update lead;
			Test.stopTest();
			
			lead = [
					SELECT
							Id,
							Bewerbung_vom__c,
							VL__c,
							Bewertung_Zentrale__c,
							LeadSource,
							Interesse_an__c
					FROM Lead
					WHERE Id = :lead.Id
					LIMIT 1
			];
			
			System.assertEquals( 'Vorläufige Freigabe', lead.Bewertung_Zentrale__c );
			System.assertEquals( 'VL', lead.LeadSource );
			System.assertEquals( 'Packstation', lead.Interesse_an__c );
			System.assertEquals( Date.today().addDays( -1 ), lead.Bewerbung_vom__c );
		}
	}
	
	@IsTest
	static void testAbbruchBearbeitung () {
		
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			Lead lead = ( Lead ) TestFactory.createSObject(
					new Lead(
							RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName()
									.get( 'Packstation' ).getRecordTypeId(),
							PostalCode = '12345'
					),
					true
			);
			
			Test.startTest();
			LeadTriggerHandler.processedIds = new Set<Id>();
			lead.Bewertung_Zentrale__c = 'Durch Zentrale STOG abgelehnt';
			update lead;
			Test.stopTest();
			
			System.assertEquals( 1, [
					SELECT
							Id,
							Email_Betreff__c
					FROM EmailVersand__c
					WHERE Email_Betreff__c LIKE '%Abbruch%'
			].size() );
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
			LeadTriggerHandler.processedIds = new Set<Id>();
			lead.Bewertung_Zentrale__c = 'Geeignet - Priorisierte Bearbeitung';
			lead.Ziel_Fachanzahl__c = 160;
			update lead;
			Test.stopTest();
			
			System.assertEquals( 160, [
					SELECT
							ZielFachanzahl__c
					FROM Task
					WHERE WhoId = :lead.Id
					AND Id = :createdTask.Id
			].ZielFachanzahl__c );
		}
	}
	
	/**
	 * @process MYPM-869 Bugfix bei einem neuen Lead an einer Filial-FNAE
	 */
	@IsTest
	static void testBugfixNewLeadFilialFnae () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			Account account = createOrgE();
			Filialnetzaenderung__c filialnetzaenderung = new Filialnetzaenderung__c(
					Erledigungsdatum_FNAE__c = null,
					Zu_erwartender_Debitor__c = '12345',
					Schliessung_avisiert_fuer__c = Date.today(),
					Filiale_Filialpartner__c = account.Id,
					VL_Filialvertrieb__c = account.Id,
					Letzte_Aenderung_Interessenten_am__c = Date.today()
			);
			insert filialnetzaenderung;
			Lead lead = createPackstationLead();
			
			Test.startTest();
			LeadTriggerHandler.processedIds = new Set<Id>();
			lead.Filialnetzaenderung__c = filialnetzaenderung.Id;
			lead.Bewertung_Zentrale__c = 'Sofortiger Ersatz für';
			update lead;
			Test.stopTest();
			List<Task> tasks = [
					SELECT
							Letzte_Aenderung_Interessenten_in_FNA_am__c
					FROM Task
					WHERE Filialnetzaenderung__c = :filialnetzaenderung.Id
					AND IsClosed = FALSE
					AND RecordType.DeveloperName = 'Akquiseauftrag'
			];
			System.assertEquals( 1, tasks.size() );
		}
	}
	
	/**
	 * @process [MYPM-839] Routing Lead
	 */
	@IsTest
	static void testRoutingLeadBewertungAO () {
		User adminUser = TestUser.create( TestUser.UserType.ADMIN );
		System.runAs( TestUser.create( TestUser.UserType.AO ) ) {
			createOrgE();
			Lead lead = createPackstationLead();
			lead.OwnerId = adminUser.Id;
			update lead;
			System.assertNotEquals( UserInfo.getUserId(), [ SELECT OwnerId FROM Lead WHERE Id = :lead.Id LIMIT 1 ].OwnerId );
			
			Test.startTest();
			lead.Bewertung_VM__c = 'Geeignet (in Bearbeitung)';
			update lead;
			Test.stopTest();
			
			System.assertEquals( UserInfo.getUserId(), [ SELECT OwnerId FROM Lead WHERE Id = :lead.Id LIMIT 1 ].OwnerId );
		}
	}
	
	/**
	 * @process MYPM-915 Kommunikation des Aufbautermins
	 */
	@IsTest
	static void testKommunikationAufbautermin () {
		
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			Lead lead = createPackstationLead();
			
			Test.startTest();
			LeadTriggerHandler.processedIds = new Set<Id>();
			lead.AufstelldatumADM__c = Date.today();
			update lead;
			Test.stopTest();
			
			System.assertEquals( 1, [
					SELECT
							Id
					FROM EmailVersand__c
					WHERE Dokument__c = 'KommunikationAufbauterminMYPM915'
			].size() );
		}
	}
	
	/**
	 * @process MYPM-915 Kommunikation des Aufbautermins
	 */
	@IsTest
	static void testKommunikationAufbauterminAenderung () {
		
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			Lead lead = ( Lead ) TestFactory.createSObject(
					new Lead(
							RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName()
									.get( 'Packstation' ).getRecordTypeId(),
							PostalCode = '12345',
							AufstelldatumADM__c = Date.today()
					),
					true
			);
			
			Test.startTest();
			LeadTriggerHandler.processedIds = new Set<Id>();
			lead.AufstelldatumADM__c = Date.today().addDays( 1 );
			update lead;
			Test.stopTest();
			
			System.assertEquals( 1, [
					SELECT
							Id
					FROM EmailVersand__c
					WHERE Dokument__c = 'KommunikationAufbauterminAenderunMYPM915'
			].size() );
		}
	}
	
	/**
	 * @process MYPM-915 Kommunikation des Aufbautermins
	 */
	@IsTest
	static void testKommunikationAufbauterminStorno () {
		
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			Lead lead = ( Lead ) TestFactory.createSObject(
					new Lead(
							RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName()
									.get( 'Packstation' ).getRecordTypeId(),
							PostalCode = '12345',
							AufstelldatumADM__c = Date.today()
					),
					true
			);
			
			Test.startTest();
			LeadTriggerHandler.processedIds = new Set<Id>();
			lead.AufstelldatumADM__c = null;
			update lead;
			Test.stopTest();
			
			System.assertEquals( 1, [
					SELECT
							Id
					FROM EmailVersand__c
					WHERE Dokument__c = 'KommunikationAufbauterminStornoMYPM915'
			].size() );
		}
	}
	
	/**
	 * @process MYPM-915 Kommunikation des Aufbautermins
	 */
	@IsTest
	static void testSettingFilialnetzaenderungFromPostalCode () {
		
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			Filialnetzaenderung__c filialnetzaenderung = new Filialnetzaenderung__c(
					RecordTypeId = Schema.SObjectType.Filialnetzaenderung__c.getRecordTypeInfosByDeveloperName()
							.get( 'Packstation' ).getRecordTypeId(),
					Neuer_Standort_PLZ__c = '11111',
					Wunschformat__c = 'Packstation',
					Filiale_Filialpartner__c = createOrgE().Id
			);
			insert filialnetzaenderung;
			
			Test.startTest();
			Lead lead = ( Lead ) TestFactory.createSObject(
					new Lead(
							RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName()
									.get( 'Packstation' ).getRecordTypeId(),
							PostalCode = '11111'
					),
					true
			);
			Test.stopTest();
			
			System.assertEquals( filialnetzaenderung.Id, [
					SELECT
							Id,
							Filialnetzaenderung__c
					FROM Lead
					WHERE Id = :lead.Id
					LIMIT 1
			].Filialnetzaenderung__c );
		}
	}
	
	/**
	 * @process MYPM-1094 Neue Aufgabe "Standortaufnahme durchführen"
	 */
	@IsTest
	static void testStandortaufnahmeDurchfuehren () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			Test.startTest();
			Lead lead = ( Lead ) TestFactory.createSObject(
					new Lead(
							RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName()
									.get( 'Packstation' ).getRecordTypeId(),
							PostalCode = '11111',
							Bewertung_Zentrale__c = 'Geeignet',
							Akquisemodus__c = 'Standortaufnahme vor Ort; Danach Übergabe an rVU'
					),
					true
			);
			LeadTriggerHandler.processedIds = new Set<Id>();
			lead.Bewertung_Zentrale__c = 'Geeignet - Priorisierte Bearbeitung';
			update lead;
			Test.stopTest();
			
			System.assertEquals( 1, [
					SELECT
							Id,
							Aufgabenart__c
					FROM Task
					WHERE WhoId = :lead.Id
					AND Aufgabenart__c = 'Standortaufnahme durchführen'
			].size() );
		}
	}
	
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
			LeadTriggerHandler.processedIds = new Set<Id>();
			LeadTriggerHandler.setPODID = true;
			lead.STO_disponiert__c = Date.today();
			update lead;
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
			LeadTriggerHandler.processedIds = new Set<Id>();
			LeadTriggerHandler.setPODID = true;
			lead.STO_disponiert__c = Date.today();
			try {
				update lead;
			}
			catch ( Exception e ) {
				System.assert( e.getMessage().contains( 'keine PODIDs mehr verfügbar' ) );
			}
			Test.stopTest();
		}
	}
	
	/**
	 * @process [MYPM-1652] Autom. Erstellung PODIDs
	 */
	@IsTest
	static void testPODIDRemoval () {
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
			LeadTriggerHandler.processedIds = new Set<Id>();
			LeadTriggerHandler.setPODID = true;
			lead.STO_disponiert__c = Date.today();
			update lead;
			LeadTriggerHandler.processedIds = new Set<Id>();
			lead.PODID_Lookup__c = null;
			update lead;
			Test.stopTest();
			
			PODID__c podid = [ SELECT Id, Status__c, Anmerkung__c FROM PODID__c LIMIT 1 ];
			
			System.assertEquals( 'Gelöscht', podid.Status__c );
			System.assert( podid.Anmerkung__c.contains( 'entfernt' ) );
		}
	}
	
	/**
	 * @process [MYPM-1652] Autom. Erstellung PODIDs
	 */
	@IsTest
	static void testPODIDLeadDeletion () {
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
			LeadTriggerHandler.processedIds = new Set<Id>();
			LeadTriggerHandler.setPODID = true;
			lead.STO_disponiert__c = Date.today();
			update lead;
			delete lead;
			Test.stopTest();
			
			PODID__c podid = [ SELECT Id, Status__c, Anmerkung__c FROM PODID__c LIMIT 1 ];
			
			System.assertEquals( 'Gelöscht', podid.Status__c );
			System.assert( podid.Anmerkung__c.contains( 'entfernt' ) );
		}
	}
	
	/**
	 * @process [MYPM-1716] Accountanlage Packstation (Teil 1: Dummy-Account anlegen)
	 */
	@IsTest
	static void testDummyPackstation () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			Anlagennummer__c anlagennummer = new Anlagennummer__c(
					Name = '00000001',
					Status__c = 'verfügbar'
			);
			insert anlagennummer;
			TriggerHandler.bypass( 'LeadTriggerHandler' );
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
			TriggerHandler.clearBypass( 'LeadTriggerHandler' );
			
			Test.startTest();
			LeadTriggerHandler.processedIds = new Set<Id>();
			LeadTriggerHandler.setPODID = true;
			lead.ist_disponiert__c = true;
			update lead;
			Test.stopTest();
			System.assertEquals( 1, [
					SELECT
							Id
					FROM Account
					WHERE RecordType.DeveloperName = 'Packstation_Dummy'
			].size() );
		}
	}
	
	/**
	 * @process [MYPM-1821] Erzeugung Lead aus PS-Account [2] - Leadanlage Änderung
	 */
	@IsTest
	static void testPackstationLeadKeineEntlastung () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			TriggerHandler.bypass( 'LeadTriggerHandler' );
			Lead lead = ( Lead ) TestFactory.createSObject(
					new Lead(
							RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName()
									.get( 'Packstation' ).getRecordTypeId()
					),
					true
			);
			TriggerHandler.clearBypass( 'LeadTriggerHandler' );
			
			Test.startTest();
			lead.Entlastung_durch_mod_Erweiterung__c = 'Nein';
			lead.Entlastung_durch_Austausch__c = 'Nein';
			lead.Entlastung_durch_2_Automat_selber_STO__c = 'Nein';
			update lead;
			Test.stopTest();
			lead = [
					SELECT
							Id,
							Bewertung_VM_vom__c,
							Hinweis_AO__c
					FROM Lead
					WHERE Id = :lead.Id
					LIMIT 1
			];
			System.assertEquals( Date.today(), lead.Bewertung_VM_vom__c );
		}
	}
	
	/**
	 * @process [MYPM-1821] Erzeugung Lead aus PS-Account [2] - Leadanlage Änderung
	 */
	@IsTest
	static void testPackstationLeadEntlastungAbbau () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			Account account = createOrgE();
			TriggerHandler.bypass( 'LeadTriggerHandler' );
			Lead lead = ( Lead ) TestFactory.createSObject(
					new Lead(
							RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName()
									.get( 'Packstation' ).getRecordTypeId(),
							Filiale_Filialpartner__c = account.Id
					),
					true
			);
			TriggerHandler.clearBypass( 'LeadTriggerHandler' );
			
			account.Lead__c = lead.Id;
			update account;
			
			Test.startTest();
			lead.Bestandsmassnahme__c = 'Entlastung - Aufbau';
			lead.Entlastung_durch_mod_Erweiterung__c = 'Nein';
			lead.Entlastung_durch_Austausch__c = 'Ja';
			lead.Freigabe_STOG__c = 'Ja';
			update lead;
			Test.stopTest();
			
			System.assertEquals( 1, [
					SELECT
							Id,
							Bewertung_VM_vom__c,
							Hinweis_AO__c
					FROM Lead
					WHERE Bestandsmassnahme__c = 'Entlastung - Abbau'
					AND VerknuepfterLead__c = :lead.Id
			].size() );
		}
	}
	
	/**
	 * @process [MYPM-1821] Erzeugung Lead aus PS-Account [2] - Leadanlage Änderung
	 */
	@IsTest
	static void testPackstationLeadFormataenderungAbbau () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			Account account = createOrgE();
			TriggerHandler.bypass( 'LeadTriggerHandler' );
			Lead lead = ( Lead ) TestFactory.createSObject(
					new Lead(
							RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName()
									.get( 'Packstation' ).getRecordTypeId(),
							Filiale_Filialpartner__c = account.Id
					),
					true
			);
			TriggerHandler.clearBypass( 'LeadTriggerHandler' );
			
			account.Lead__c = lead.Id;
			update account;
			
			Test.startTest();
			lead.Bestandsmassnahme__c = 'Formatwechsel (Pack-/Poststation) - Aufbau';
			lead.Freigabe_STOG__c = 'Ja';
			update lead;
			Test.stopTest();
			
			System.assertEquals( 1, [
					SELECT
							Id,
							Bewertung_VM_vom__c,
							Hinweis_AO__c
					FROM Lead
					WHERE Bestandsmassnahme__c = 'Formatwechsel (Pack-/Poststation) - Abbau'
					AND VerknuepfterLead__c = :lead.Id
			].size() );
		}
	}
	
	/**
	 * @process MYPM-1968 Anpassungen BEX: Team Vertragsmanagement
	 */
	@IsTest
	static void testBeauftragungTvm () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			Test.startTest();
			Lead lead = ( Lead ) TestFactory.createSObject(
					new Lead(
							RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName()
									.get( 'Packstation' ).getRecordTypeId(),
							PostalCode = '11111',
							Bewertung_Zentrale__c = 'Geeignet'
					),
					true
			);
			LeadTriggerHandler.processedIds = new Set<Id>();
			lead.Freigabe_STOG__c = 'Ja';
			lead.Bauordnungsrechtliche_Pruefung__c = 'formeller Antrag gestellt';
			lead.Bauordnungsrechtliche_Pruefung_Datum__c = Date.today();
			lead.Ergebnis_Bauordnungsrechtliche_Pruefung__c = 'Genehmigt';
			lead.Ergebnis_Bauord_rechtl_Pruefung_Datum__c = Date.today();
			lead.Freigabe_STOG__c = 'Ja';
			update lead;
			Test.stopTest();
			
			System.assertEquals( 1, [
					SELECT
							Id,
							Aufgabenart__c
					FROM Task
					WHERE WhoId = :lead.Id
					AND Aufgabenart__c = 'Beauftragung TVM'
			].size() );
		}
	}
	
	/**
	 * @process MYPM-2050
	 */
	@IsTest
	static void testInsertInKlaerungWeiden () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			Test.startTest();
			Lead lead = ( Lead ) TestFactory.createSObject(
					new Lead(
							RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName()
									.get( 'Packstation' ).getRecordTypeId(),
							PostalCode = '11111',
							Bewertung_Zentrale__c = 'in Klärung Weiden'
					),
					true
			);
			Test.stopTest();
			
			System.assertEquals( 'inaktiv durch Zentrale', [
					SELECT
							Aktivitaetsstatus__c
					FROM Lead
					WHERE Id = :lead.Id
					LIMIT 1
			].Aktivitaetsstatus__c );
		}
	}
	
	/**
	 * @process MYPM-2050
	 */
	@IsTest
	static void testSetWeidenGeeignetValues () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			Lead lead = ( Lead ) TestFactory.createSObject(
					new Lead(
							RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName()
									.get( 'Packstation' ).getRecordTypeId(),
							PostalCode = '11111',
							Bewertung_Zentrale__c = 'in Klärung Weiden'
					),
					true
			);
			
			Test.startTest();
			LeadTriggerHandler.processedIds = new Set<Id>();
			lead.Bewertung_Weiden__c = 'Geeignet';
			update lead;
			Test.stopTest();
			
			lead = [
					SELECT
							Bewertung_Zentrale__c,
							Bewertung_Zentrale_vom__c,
							Aktivitaetsstatus__c
					FROM Lead
					WHERE Id = :lead.Id
					LIMIT 1
			];
			
			System.assertEquals( 'Geeignet', lead.Bewertung_Zentrale__c );
			System.assertEquals( Date.today(), lead.Bewertung_Zentrale_vom__c );
			System.assertEquals( 'aktiv durch Zentrale', lead.Aktivitaetsstatus__c );
		}
	}
	
	/**
	 * @process MYPM-2050
	 */
	@IsTest
	static void testDeactivateIfBewertungVmEqualsAbsageDurchStog () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			Lead lead = ( Lead ) TestFactory.createSObject(
					new Lead(
							RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName()
									.get( 'Packstation' ).getRecordTypeId(),
							PostalCode = '11111',
							Bewertung_Zentrale__c = 'in Klärung Weiden'
					),
					true
			);
			
			Test.startTest();
			LeadTriggerHandler.processedIds = new Set<Id>();
			lead.Bewertung_VM__c = 'Absage durch STOG - Kein Interesse';
			update lead;
			Test.stopTest();
			
			lead = [
					SELECT
							Aktivitaetsstatus__c
					FROM Lead
					WHERE Id = :lead.Id
					LIMIT 1
			];
			
			System.assertEquals( 'inaktiv', lead.Aktivitaetsstatus__c );
		}
	}
	
	private static List<Lead> createLeads ( Integer quantity ) {
		
		return ( List<Lead> ) TestFactory.createSObjectList(
				new Lead(),
				quantity,
				true
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
	
	private static Lead createLeadWithSource ( String leadSource ) {
		Lead lead = ( Lead ) TestFactory.createSObject(
				new Lead(
						RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName()
								.get( 'Packstation' ).getRecordTypeId(),
						Email = 'test@test.de',
						FirstName = 'firstName',
						LastName = 'lastName',
						Company = 'Company',
						LeadSource = leadSource
				),
				true
		);
		return lead;
	}
	
	private static Account createOrgE () {
		PLZ_zu_VGL__c plzZuVGL = new PLZ_zu_VGL__c(
				Name = 'Test',
				PLZ_5_stellig__c = '12345',
				VGL25_OZ__c = '0815',
				VGL25_Name__c = 'Filiale 1'
		);
		insert plzZuVGL;
		OrgE_DP__c LO_OrgE = new OrgE_DP__c(
				Name = 'Gebiet 1',
				GL_OZ__c = 'GL0815',
				Koordinator__c = UserInfo.getUserId()
		);
		insert( LO_OrgE );
		Account LO_Filiale = new Account(
				Name = 'Filiale 1',
				ASt_ID__c = '12345',
				GL__c = LO_OrgE.Id,
				RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
						.get( 'OrgE_Dummy' ).getRecordTypeId()
		);
		insert LO_Filiale;
		return LO_Filiale;
	}
}