/**
 *@author       Mats Böhler
 *@created      23.11.2020
 *
 *
 *@description  ManagementReportingTest
 *
 *
 *@changelog    23.11.2020 Mats Böhler  - Created
 *              
 * 
 */
@IsTest
private class ManagementReportingServiceTest {

	@IsTest
	static void testOhneBewertungZentrale () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			TriggerHandler.bypass( 'LeadTriggerHandler' );
			Lead lead = createPackstationLead();
			
			Test.startTest();
			new ManagementReportingService().setClassification( new Map<Id, Lead>( new List<Lead> {
					lead
			} ).keySet() );
			TriggerHandler.clearAllBypasses();
			Test.stopTest();
			
			lead = [ SELECT Id, KlassifizierungManagementReporting__c FROM Lead WHERE Id = :lead.Id LIMIT 1 ];
			System.assertEquals( 'Ohne Bewertung (Zentrale)', lead.KlassifizierungManagementReporting__c );
		}
	}
	
	@IsTest
	static void testUngeeignetZentrale () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			TriggerHandler.bypass( 'LeadTriggerHandler' );
			Lead lead = createPackstationLead();
			
			Test.startTest();
			lead.Bewertung_Zentrale__c = 'Nicht geeignet, zu geringes Potenzial';
			update lead;
			new ManagementReportingService().setClassification( new Map<Id, Lead>( new List<Lead> {
					lead
			} ).keySet() );
			TriggerHandler.clearAllBypasses();
			Test.stopTest();
			
			lead = [ SELECT Id, KlassifizierungManagementReporting__c FROM Lead WHERE Id = :lead.Id LIMIT 1 ];
			System.assertEquals( 'Ungeeignet (Zentrale)', lead.KlassifizierungManagementReporting__c );
		}
	}
	
	@IsTest
	static void testGeeignetZentrale () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			TriggerHandler.bypass( 'LeadTriggerHandler' );
			Lead lead = createPackstationLead();
			
			Test.startTest();
			lead.Bewertung_Zentrale__c = 'Geeignet';
			update lead;
			new ManagementReportingService().setClassification( new Map<Id, Lead>( new List<Lead> {
					lead
			} ).keySet() );
			TriggerHandler.clearAllBypasses();
			Test.stopTest();
			
			lead = [ SELECT Id, KlassifizierungManagementReporting__c FROM Lead WHERE Id = :lead.Id LIMIT 1 ];
			System.assertEquals( 'Geeignet (Zentrale)', lead.KlassifizierungManagementReporting__c );
		}
	}
	
	@IsTest
	static void testGeeignetZentraleOhneBewertungAO () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			TriggerHandler.bypass( 'LeadTriggerHandler' );
			Lead lead = createPackstationLead();
			
			Test.startTest();
			lead.Bewertung_Zentrale__c = 'Geeignet';
			lead.Bewertung_Zentrale_vom__c = Date.today().addDays( -100 );
			update lead;
			new ManagementReportingService().setClassification( new Map<Id, Lead>( new List<Lead> {
					lead
			} ).keySet() );
			TriggerHandler.clearAllBypasses();
			Test.stopTest();
			
			lead = [ SELECT Id, KlassifizierungManagementReporting__c FROM Lead WHERE Id = :lead.Id LIMIT 1 ];
			System.assertEquals( 'Geeignet (Zentrale), ohne Bewertung (AO)', lead.KlassifizierungManagementReporting__c );
		}
	}
	
	@IsTest
	static void testUngeeignetAO () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			TriggerHandler.bypass( 'LeadTriggerHandler' );
			Lead lead = createPackstationLead();
			
			Test.startTest();
			lead.Bewertung_Zentrale__c = 'Geeignet';
			lead.Bewertung_VM__c = 'Dublette';
			update lead;
			new ManagementReportingService().setClassification( new Map<Id, Lead>( new List<Lead> {
					lead
			} ).keySet() );
			TriggerHandler.clearAllBypasses();
			Test.stopTest();
			
			lead = [ SELECT Id, KlassifizierungManagementReporting__c FROM Lead WHERE Id = :lead.Id LIMIT 1 ];
			System.assertEquals( 'Ungeeignet (AO)', lead.KlassifizierungManagementReporting__c );
		}
	}
	
	@IsTest
	static void testGeeignetAO () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			TriggerHandler.bypass( 'LeadTriggerHandler' );
			Lead lead = createPackstationLead();
			
			Test.startTest();
			lead.Bewertung_Zentrale__c = 'Geeignet';
			lead.Bewertung_VM__c = 'Geeignet (noch nicht in Bearbeitung)';
			update lead;
			new ManagementReportingService().setClassification( new Map<Id, Lead>( new List<Lead> {
					lead
			} ).keySet() );
			TriggerHandler.clearAllBypasses();
			Test.stopTest();
			
			lead = [ SELECT Id, KlassifizierungManagementReporting__c FROM Lead WHERE Id = :lead.Id LIMIT 1 ];
			System.assertEquals( 'Geeignet (AO)', lead.KlassifizierungManagementReporting__c );
		}
	}
	
	@IsTest
	static void testGeeignetAOMitStandortdoku () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			TriggerHandler.bypass( 'LeadTriggerHandler' );
			Lead lead = createPackstationLead();
			
			Test.startTest();
			lead.Bewertung_Zentrale__c = 'Geeignet';
			lead.Bewertung_VM__c = 'Geeignet (noch nicht in Bearbeitung)';
			lead.DokumentationErstelltDatum__c = Date.today();
			update lead;
			new ManagementReportingService().setClassification( new Map<Id, Lead>( new List<Lead> {
					lead
			} ).keySet() );
			TriggerHandler.clearAllBypasses();
			Test.stopTest();
			
			lead = [ SELECT Id, KlassifizierungManagementReporting__c FROM Lead WHERE Id = :lead.Id LIMIT 1 ];
			System.assertEquals( 'Geeignet (AO) mit erstellter Standortdoku', lead.KlassifizierungManagementReporting__c );
		}
	}
	
	@IsTest
	static void testGeeignetAOOhneStandortdoku () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			TriggerHandler.bypass( 'LeadTriggerHandler' );
			Lead lead = createPackstationLead();
			
			Test.startTest();
			lead.Bewertung_Zentrale__c = 'Geeignet';
			lead.Bewertung_VM__c = 'Geeignet (noch nicht in Bearbeitung)';
			lead.Bewertung_VM_vom__c = Date.today().addDays( -100 );
			update lead;
			new ManagementReportingService().setClassification( new Map<Id, Lead>( new List<Lead> {
					lead
			} ).keySet() );
			TriggerHandler.clearAllBypasses();
			Test.stopTest();
			
			lead = [ SELECT Id, KlassifizierungManagementReporting__c FROM Lead WHERE Id = :lead.Id LIMIT 1 ];
			System.assertEquals( 'Geeignet (AO) ohne Standortdoku', lead.KlassifizierungManagementReporting__c );
		}
	}
	
	@IsTest
	static void testStandortdokuWartetAufFreigabe () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			TriggerHandler.bypass( 'LeadTriggerHandler' );
			Lead lead = createPackstationLead();
			
			Test.startTest();
			lead.Bewertung_Zentrale__c = 'Geeignet';
			lead.Bewertung_VM__c = 'Geeignet (noch nicht in Bearbeitung)';
			lead.DokumentationErstelltDatum__c = Date.today().addDays( -100 );
			update lead;
			new ManagementReportingService().setClassification( new Map<Id, Lead>( new List<Lead> {
					lead
			} ).keySet() );
			TriggerHandler.clearAllBypasses();
			Test.stopTest();
			
			lead = [ SELECT Id, KlassifizierungManagementReporting__c FROM Lead WHERE Id = :lead.Id LIMIT 1 ];
			System.assertEquals( 'Standortdoku wartet auf Freigabe (rVU)', lead.KlassifizierungManagementReporting__c );
		}
	}
	
	@IsTest
	static void testStandortdokuInNachbesserung () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			TriggerHandler.bypass( 'LeadTriggerHandler' );
			Lead lead = createPackstationLead();
			
			Test.startTest();
			lead.DokumentationErstelltDatum__c = Date.today();
			lead.NachbesserungAngefordert__c = true;
			update lead;
			new ManagementReportingService().setClassification( new Map<Id, Lead>( new List<Lead> {
					lead
			} ).keySet() );
			TriggerHandler.clearAllBypasses();
			Test.stopTest();
			
			lead = [ SELECT Id, KlassifizierungManagementReporting__c FROM Lead WHERE Id = :lead.Id LIMIT 1 ];
			System.assertEquals( 'Standortdoku in Nachbesserung (rVU/VM)', lead.KlassifizierungManagementReporting__c );
		}
	}
	
	@IsTest
	static void testStandortdokuFreigegeben () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			TriggerHandler.bypass( 'LeadTriggerHandler' );
			Lead lead = createPackstationLead();
			
			Test.startTest();
			lead.Bewertung_VM__c = 'Geeignet (in Bearbeitung)';
			lead.DokumentationErstelltDatum__c = Date.today();
			lead.DokumentationDurchRTFreigebenDatum__c = Date.today();
			update lead;
			new ManagementReportingService().setClassification( new Map<Id, Lead>( new List<Lead> {
					lead
			} ).keySet() );
			TriggerHandler.clearAllBypasses();
			Test.stopTest();
			
			lead = [ SELECT Id, KlassifizierungManagementReporting__c FROM Lead WHERE Id = :lead.Id LIMIT 1 ];
			System.assertEquals( 'Standortdoku freigegeben (rVU)', lead.KlassifizierungManagementReporting__c );
		}
	}
	
	@IsTest
	static void testStandortdokuFreigegebenSTOG () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			TriggerHandler.bypass( 'LeadTriggerHandler' );
			Lead lead = createPackstationLead();
			
			Test.startTest();
			lead.DokumentationDurchRTFreigebenDatum__c = Date.today();
			lead.Freigabe_STOG__c = 'Ja';
			update lead;
			new ManagementReportingService().setClassification( new Map<Id, Lead>( new List<Lead> {
					lead
			} ).keySet() );
			TriggerHandler.clearAllBypasses();
			Test.stopTest();
			
			lead = [ SELECT Id, KlassifizierungManagementReporting__c FROM Lead WHERE Id = :lead.Id LIMIT 1 ];
			System.assertEquals( 'Standortdoku freigegeben (STOG)', lead.KlassifizierungManagementReporting__c );
		}
	}
	
	@IsTest
	static void testStandortdokuAbgelehnt () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			TriggerHandler.bypass( 'LeadTriggerHandler' );
			Lead lead = createPackstationLead();
			
			Test.startTest();
			lead.DokumentationDurchRTFreigebenDatum__c = Date.today();
			lead.Freigabe_STOG__c = 'Nein - keine Freigabe STOG';
			update lead;
			new ManagementReportingService().setClassification( new Map<Id, Lead>( new List<Lead> {
					lead
			} ).keySet() );
			TriggerHandler.clearAllBypasses();
			Test.stopTest();
			
			lead = [ SELECT Id, KlassifizierungManagementReporting__c FROM Lead WHERE Id = :lead.Id LIMIT 1 ];
			System.assertEquals( 'Standortdoku abgelehnt (STOG)', lead.KlassifizierungManagementReporting__c );
		}
	}
	
	@IsTest
	static void testStandortdokuInWarteschleife () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			TriggerHandler.bypass( 'LeadTriggerHandler' );
			Lead lead = createPackstationLead();
			
			Test.startTest();
			lead.Freigabe_STOG__c = 'Offen - Doku in Nachbesserung';
			update lead;
			new ManagementReportingService().setClassification( new Map<Id, Lead>( new List<Lead> {
					lead
			} ).keySet() );
			TriggerHandler.clearAllBypasses();
			Test.stopTest();
			
			lead = [ SELECT Id, KlassifizierungManagementReporting__c FROM Lead WHERE Id = :lead.Id LIMIT 1 ];
			System.assertEquals( 'Standortdoku in Warteschleife (STOG)', lead.KlassifizierungManagementReporting__c );
		}
	}

	@IsTest
	static void testBaufreigabeInPruefung () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			TriggerHandler.bypass( 'LeadTriggerHandler' );
			Lead lead = createPackstationLead();
			
			Test.startTest();
			lead.Bauordnungsrechtliche_Pruefung__c = 'formeller Antrag gestellt';
			lead.Bauordnungsrechtliche_Pruefung_Datum__c = Date.today();
			update lead;
			new ManagementReportingService().setClassification( new Map<Id, Lead>( new List<Lead> {
					lead
			} ).keySet() );
			TriggerHandler.clearAllBypasses();
			Test.stopTest();
			
			lead = [ SELECT Id, KlassifizierungManagementReporting__c FROM Lead WHERE Id = :lead.Id LIMIT 1 ];
			System.assertEquals( 'Baufreigabe in Prüfung', lead.KlassifizierungManagementReporting__c );
		}
	}
	
	@IsTest
	static void testBaufreigabeVorhanden () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			TriggerHandler.bypass( 'LeadTriggerHandler' );
			Lead lead = createPackstationLead();
			
			Test.startTest();
			lead.Freigabe_STOG__c = 'Ja';
			lead.Bauordnungsrechtliche_Pruefung__c = 'formeller Antrag gestellt';
			lead.Bauordnungsrechtliche_Pruefung_Datum__c = Date.today();
			lead.Ergebnis_Bauordnungsrechtliche_Pruefung__c = 'Genehmigt';
			lead.Ergebnis_Bauord_rechtl_Pruefung_Datum__c = Date.today();
			update lead;
			new ManagementReportingService().setClassification( new Map<Id, Lead>( new List<Lead> {
					lead
			} ).keySet() );
			TriggerHandler.clearAllBypasses();
			Test.stopTest();
			
			lead = [ SELECT Id, KlassifizierungManagementReporting__c FROM Lead WHERE Id = :lead.Id LIMIT 1 ];
			System.assertEquals( 'Baufreigabe vorhanden', lead.KlassifizierungManagementReporting__c );
		}
	}
	
	@IsTest
	static void testBaufreigabeAbgelehnt () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			TriggerHandler.bypass( 'LeadTriggerHandler' );
			Lead lead = createPackstationLead();
			
			Test.startTest();
			lead.Freigabe_STOG__c = 'Ja';
			lead.Bauordnungsrechtliche_Pruefung__c = 'formeller Antrag gestellt';
			lead.Bauordnungsrechtliche_Pruefung_Datum__c = Date.today();
			lead.Ergebnis_Bauordnungsrechtliche_Pruefung__c = 'Nicht genehmigt';
			lead.Ergebnis_Bauord_rechtl_Pruefung_Datum__c = Date.today();
			update lead;
			new ManagementReportingService().setClassification( new Map<Id, Lead>( new List<Lead> {
					lead
			} ).keySet() );
			TriggerHandler.clearAllBypasses();
			Test.stopTest();
			
			lead = [ SELECT Id, KlassifizierungManagementReporting__c FROM Lead WHERE Id = :lead.Id LIMIT 1 ];
			System.assertEquals( 'Baufreigabe abgelehnt', lead.KlassifizierungManagementReporting__c );
		}
	}
	
	@IsTest
	static void testBaupruefungOffen () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			TriggerHandler.bypass( 'LeadTriggerHandler' );
			Lead lead = createPackstationLead();
			
			Test.startTest();
			lead.Freigabe_STOG__c = 'Ja';
			lead.DokumentationDurchRTFreigebenDatum__c = Date.today();
			lead.Freigabe_STOG_Datum__c = Date.today().addDays( -100 );
			update lead;
			new ManagementReportingService().setClassification( new Map<Id, Lead>( new List<Lead> {
					lead
			} ).keySet() );
			TriggerHandler.clearAllBypasses();
			Test.stopTest();
			
			lead = [ SELECT Id, KlassifizierungManagementReporting__c FROM Lead WHERE Id = :lead.Id LIMIT 1 ];
			System.assertEquals( 'Freigabe STOG vorhanden, Bauprüfung offen', lead.KlassifizierungManagementReporting__c );
		}
	}
	
	@IsTest
	static void testVertragAbgelehnt () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			TriggerHandler.bypass( 'LeadTriggerHandler' );
			Lead lead = createPackstationLead();
			
			Test.startTest();
			lead.Vertrag_unterschrieben__c = 'Nein';
			update lead;
			new ManagementReportingService().setClassification( new Map<Id, Lead>( new List<Lead> {
					lead
			} ).keySet() );
			TriggerHandler.clearAllBypasses();
			Test.stopTest();
			
			lead = [ SELECT Id, KlassifizierungManagementReporting__c FROM Lead WHERE Id = :lead.Id LIMIT 1 ];
			System.assertEquals( 'Vertrag abgelehnt (STOG/VP)', lead.KlassifizierungManagementReporting__c );
		}
	}
	
	@IsTest
	static void testVertragUnterzeichnet () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			TriggerHandler.bypass( 'LeadTriggerHandler' );
			Lead lead = createPackstationLead();
			
			Test.startTest();
			lead.Vertrag_unterschrieben__c = 'Ja';
			lead.Bauordnungsrechtliche_Pruefung__c = 'formeller Antrag gestellt';
			lead.Bauordnungsrechtliche_Pruefung_Datum__c = Date.today();
			lead.Ergebnis_Bauordnungsrechtliche_Pruefung__c = 'Genehmigt';
			lead.Ergebnis_Bauord_rechtl_Pruefung_Datum__c = Date.today();
			update lead;
			new ManagementReportingService().setClassification( new Map<Id, Lead>( new List<Lead> {
					lead
			} ).keySet() );
			TriggerHandler.clearAllBypasses();
			Test.stopTest();
			
			lead = [ SELECT Id, KlassifizierungManagementReporting__c FROM Lead WHERE Id = :lead.Id LIMIT 1 ];
			System.assertEquals( 'Vertrag unterzeichnet (STOG/VP)', lead.KlassifizierungManagementReporting__c );
		}
	}
	
	@IsTest
	static void testVertragWartetAufFreigabe () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			TriggerHandler.bypass( 'LeadTriggerHandler' );
			Lead lead = createPackstationLead();
			
			Test.startTest();
			lead.Vertrag_versandt__c = Date.today();
			lead.Bauordnungsrechtliche_Pruefung__c = 'formeller Antrag gestellt';
			lead.Bauordnungsrechtliche_Pruefung_Datum__c = Date.today();
			lead.Ergebnis_Bauordnungsrechtliche_Pruefung__c = 'Genehmigt';
			lead.Ergebnis_Bauord_rechtl_Pruefung_Datum__c = Date.today();
			update lead;
			new ManagementReportingService().setClassification( new Map<Id, Lead>( new List<Lead> {
					lead
			} ).keySet() );
			TriggerHandler.clearAllBypasses();
			Test.stopTest();
			
			lead = [ SELECT Id, KlassifizierungManagementReporting__c FROM Lead WHERE Id = :lead.Id LIMIT 1 ];
			System.assertEquals( 'Vertrag wartet auf Freigabe (STOG/VP)', lead.KlassifizierungManagementReporting__c );
		}
	}
	
	@IsTest
	static void testVertragNochNichtVersendet () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			TriggerHandler.bypass( 'LeadTriggerHandler' );
			Lead lead = createPackstationLead();
			
			Test.startTest();
			lead.Freigabe_STOG__c = 'Ja';
			lead.Bauordnungsrechtliche_Pruefung__c = 'formeller Antrag gestellt';
			lead.Bauordnungsrechtliche_Pruefung_Datum__c = Date.today();
			lead.Ergebnis_Bauordnungsrechtliche_Pruefung__c = 'Genehmigt';
			lead.Ergebnis_Bauord_rechtl_Pruefung_Datum__c = Date.today().addDays( -100 );
			update lead;
			new ManagementReportingService().setClassification( new Map<Id, Lead>( new List<Lead> {
					lead
			} ).keySet() );
			TriggerHandler.clearAllBypasses();
			Test.stopTest();
			
			lead = [ SELECT Id, KlassifizierungManagementReporting__c FROM Lead WHERE Id = :lead.Id LIMIT 1 ];
			System.assertEquals( 'Baufreigabe vorhanden, Vertrag noch nicht versendet', lead.KlassifizierungManagementReporting__c );
		}
	}
	
	@IsTest
	static void testVertragUnterzeichnetDPAG () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			TriggerHandler.bypass( 'LeadTriggerHandler' );
			Lead lead = createPackstationLead();
			
			Test.startTest();
			lead.Vertrag_unterschrieben__c = 'Ja';
			lead.VertragVonVLUnterschriebenAm__c = Date.today();
			update lead;
			new ManagementReportingService().setClassification( new Map<Id, Lead>( new List<Lead> {
					lead
			} ).keySet() );
			TriggerHandler.clearAllBypasses();
			Test.stopTest();
			
			lead = [ SELECT Id, KlassifizierungManagementReporting__c FROM Lead WHERE Id = :lead.Id LIMIT 1 ];
			System.assertEquals( 'Vertrag unterzeichnet (DPAG)', lead.KlassifizierungManagementReporting__c );
		}
	}
	
	@IsTest
	static void testVertragWartetAufUnterzeichnungDPAG () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			TriggerHandler.bypass( 'LeadTriggerHandler' );
			Lead lead = createPackstationLead();
			
			Test.startTest();
			lead.Vertrag_unterschrieben__c = 'Ja';
			lead.Zustimmung_Ablehnung_zum_Vertrag_Datum__c = Date.today().addDays( -100 );
			update lead;
			new ManagementReportingService().setClassification( new Map<Id, Lead>( new List<Lead> {
					lead
			} ).keySet() );
			TriggerHandler.clearAllBypasses();
			Test.stopTest();
			
			lead = [ SELECT Id, KlassifizierungManagementReporting__c FROM Lead WHERE Id = :lead.Id LIMIT 1 ];
			System.assertEquals( 'Vertrag wartet auf Unterzeichnung (DPAG)', lead.KlassifizierungManagementReporting__c );
		}
	}
	
	@IsTest
	static void testUebergebenAnTeamBauen () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			TriggerHandler.bypass( 'LeadTriggerHandler' );
			Lead lead = createPackstationLead();
			
			Test.startTest();
			lead.STO_disponiert__c = Date.today();
			update lead;
			new ManagementReportingService().setClassification( new Map<Id, Lead>( new List<Lead> {
					lead
			} ).keySet() );
			TriggerHandler.clearAllBypasses();
			Test.stopTest();
			
			lead = [ SELECT Id, KlassifizierungManagementReporting__c FROM Lead WHERE Id = :lead.Id LIMIT 1 ];
			System.assertEquals( 'Übergeben an Team Bauen', lead.KlassifizierungManagementReporting__c );
		}
	}
	
	@IsTest
	static void testBaucheckErfolgreich () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			TriggerHandler.bypass( 'LeadTriggerHandler' );
			Lead lead = createPackstationLead();
			
			Test.startTest();
			lead.Baucheck_erfolgt_Datum__c = Date.today();
			lead.STO_disponiert__c = Date.today();
			update lead;
			new ManagementReportingService().setClassification( new Map<Id, Lead>( new List<Lead> {
					lead
			} ).keySet() );
			TriggerHandler.clearAllBypasses();
			Test.stopTest();
			
			lead = [ SELECT Id, KlassifizierungManagementReporting__c FROM Lead WHERE Id = :lead.Id LIMIT 1 ];
			System.assertEquals( 'Bau-Check erfolgreich', lead.KlassifizierungManagementReporting__c );
		}
	}
	
	@IsTest
	static void testPackstationAufgebaut () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			TriggerHandler.bypass( 'LeadTriggerHandler' );
			Lead lead = createPackstationLead();
			
			Test.startTest();
			lead.AufstelldatumADM__c = Date.today();
			update lead;
			new ManagementReportingService().setClassification( new Map<Id, Lead>( new List<Lead> {
					lead
			} ).keySet() );
			TriggerHandler.clearAllBypasses();
			Test.stopTest();
			
			lead = [ SELECT Id, KlassifizierungManagementReporting__c FROM Lead WHERE Id = :lead.Id LIMIT 1 ];
			System.assertEquals( 'Packstation aufgebaut', lead.KlassifizierungManagementReporting__c );
		}
	}
	
	@IsTest
	static void testPackstationInBetrieb () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			TriggerHandler.bypass( 'LeadTriggerHandler' );
			Lead lead = createPackstationLead();
			
			Test.startTest();
			lead.go_live__c = Date.today();
			update lead;
			new ManagementReportingService().setClassification( new Map<Id, Lead>( new List<Lead> {
					lead
			} ).keySet() );
			TriggerHandler.clearAllBypasses();
			Test.stopTest();
			
			lead = [ SELECT Id, KlassifizierungManagementReporting__c FROM Lead WHERE Id = :lead.Id LIMIT 1 ];
			System.assertEquals( 'Packstation in Betrieb', lead.KlassifizierungManagementReporting__c );
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