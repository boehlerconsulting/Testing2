/**
 *@author       Mats Böhler
 *@created      27.05.2020
 *
 *
 *@description  LeadTriggerHandler
 *
 *
 *@changelog    27.05.2020 Mats Böhler  - Created
 *              
 * 
 */
public without sharing class LeadTriggerHandler extends TriggerHandler {
	
	private static final String PACKSTATION_RT = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName()
			.get( 'Packstation' ).getRecordTypeId();
	private static final String AKQUISEAUFTRAG_PACKSTATION_RT = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
			.get( 'AkquiseauftragPackstation' ).getRecordTypeId();
	private static final String AKQUISEAUFTRAG_RT = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
			.get( 'Akquiseauftrag' ).getRecordTypeId();
	
	public static Boolean disableValidations = false;
	@TestVisible
	private static Set<Id> processedIds = new Set<Id>();
	@TestVisible
	private static Boolean setPODID = false;
	
	private List<Lead> newLeads;
	private Map<Id, Lead> newLeadMap;
	private Map<Id, Lead> oldLeadMap;
	private List<Task> akquiseauftraege = new List<Task>();
	private Map<Id, Task> vertragErstellenTaskByLeadIds = new Map<Id, Task>();
	private Set<Id> ownerIds = new Set<Id>();
	private Set<String> postalCodes = new Set<String>();
	private Set<String> postalCodesPackstation = new Set<String>();
	private Map<Id, User> userByIds = new Map<Id, User>();
	private Map<String, Account> vertriebsleitungByPostalCodes = new Map<String, Account>();
	private Map<String, Filialnetzaenderung__c> filialnetzaenderungByPostalCodes = new Map<String, Filialnetzaenderung__c>();
	private Map<String, String> profileNameByUserIds = new Map<String, String>();
	private Map<Id, Lead> leadIdsRelevantForPODIDByIds = new Map<Id, Lead>();
	private Map<Id, Lead> leadsChangedZielFachanzahlById = new Map<Id, Lead>();
	private List<Lead> leadsCheckOpenAkquisen = new List<Lead>();
	private Map<Id, SObject> onepagerLeadByIds = new Map<Id, SObject>();
	private Map<Id, List<Lead>> leadsByRemovedPODIDs = new Map<Id, List<Lead>>();
	private Set<Id> leadIdsDummyPackstation = new Set<Id>();
	private Set<Id> leadIdsDummyPackstationCloneAccountCountactRelations = new Set<Id>();
	private Set<Id> leadIdsPackstationAbbau = new Set<Id>();
	
	public LeadTriggerHandler () {
		this.newLeads = ( List<Lead> ) Trigger.new;
		this.newLeadMap = ( Map<Id, Lead> ) Trigger.newMap;
		this.oldLeadMap = ( Map<Id, Lead> ) Trigger.oldMap;
	}
	
	protected override void beforeInsert () {
		resetBeforeInsertSets();
		populateBeforeInsertSets();
		postalCodes.remove( null );
		loadUsers();
		loadVertriebsleitungByPostalCodes();
		loadFilialnetzaenderungByPostalCodes();
		loadProfileNameByUserIds();
		for ( Lead lead : newLeads ) {
			Id originalOwnerId = lead.OwnerId;
			setVertriebsleitung( lead, vertriebsleitungByPostalCodes );
			processPackstationLead( lead );
			if ( lead.OwnerId == null ) {
				lead.OwnerId = originalOwnerId;
			}
			setStandortArtAktion( lead );
			setStatusForInKlaerungWeiden( lead );
		}
	}
	
	protected override void afterInsert () {
		
		processAfterInsert();
	}
	
	protected override void beforeUpdate () {
		identifyRemovedAnlagennummers();
		assignAnlagennummer();
		loadProfileNameByUserIds();
		leadIdsRelevantForPODIDByIds = new Map<Id, Lead>();
		for ( Lead lead : newLeads ) {
			validateDatenaenderung( lead );
			validateStorno( lead );
			Id originalOwnerId = lead.OwnerId;
			emptySalutationFields( lead );
			Boolean continueLoop = processPackstation( lead );
			if ( continueLoop ) {
				continue;
			}
			setOriginalOwner( lead, originalOwnerId );
			if ( isAssignPODID( lead ) ) {
				leadIdsRelevantForPODIDByIds.put( lead.Id, lead );
			}
			if ( lead.STO_disponiert__c == null && oldLeadMap.get( lead.Id ).STO_disponiert__c != null ) {
				lead.ist_disponiert__c = false;
			}
			processEntlastung( lead );
			setStandortArtAktion( lead );
			setStatusForInKlaerungWeiden( lead );
			setWeidenGeeignetValues( lead );
			deactivateIfBewertungVmEqualsAbsageDurchStog( lead );
			deactivateIfBewertungWeidenEqualsNichtGeeignetKeinInteresse( lead );
		}
		generatePODIDs();
	}
	
	private void processEntlastung ( Lead lead ) {
		if ( isKeineEntlastungMoeglich( lead )
				&& !isKeineEntlastungMoeglich( oldLeadMap.get( lead.Id ) ) ) {
			setFieldsKeineEntlastungMoeglich( lead );
		}
		if ( lead.Entlastung_durch_2_Automat_selber_STO__c == 'Ja'
				&& isChanged( lead, 'Entlastung_durch_2_Automat_selber_STO__c' ) ) {
			
			lead.PODID_Lookup__c = null;
			lead.Packstation__c = null;
		}
	}
	
	private void setOriginalOwner ( Lead lead, Id originalOwnerId ) {
		if ( lead.OwnerId == null ) {
			lead.OwnerId = originalOwnerId;
		}
	}
	
	private void generatePODIDs () {
		if ( !leadIdsRelevantForPODIDByIds.isEmpty() ) {
			Map<Id, PODID__c> podIdByLeadIds = new PodIdService().generate( leadIdsRelevantForPODIDByIds.keySet() );
			for ( Lead lead : leadIdsRelevantForPODIDByIds.values() ) {
				if ( podIdByLeadIds.containsKey( lead.Id ) ) {
					lead.PODID_Lookup__c = podIdByLeadIds.get( lead.Id ).Id;
				}
				else {
					lead.PODID_Lookup__c.addError( Label.POIDsVerbraucht );
				}
			}
		}
	}
	
	private Boolean isAssignPODID ( Lead lead ) {
		return lead.Akquisemodus__c == 'Standortaufnahme vor Ort; Danach Übergabe an rVU'
				&& lead.STO_disponiert__c != oldLeadMap.get( lead.Id ).STO_disponiert__c
				&& lead.STO_disponiert__c != null
				&& ( profileNameByUserIds.get( UserInfo.getUserId() ).contains( 'myPM Packstation Vertrieb' ) || setPODID )
				&& lead.PODID_Lookup__c == null;
	}
	
	private Boolean processPackstation ( Lead lead ) {
		Boolean continueLoop = false;
		if ( lead.RecordTypeId == PACKSTATION_RT ) {
			
			if ( lead.PostalCode != oldLeadMap.get( lead.Id ).PostalCode ) {
				lead.OwnerId = LeitregionMapper.getInstance().getKoordinatorForPostalCode( lead.PostalCode );
				continueLoop = true;
			}
			else if ( lead.Bewertung_VM__c != null
					&& oldLeadMap.get( lead.Id ).Bewertung_VM__c != lead.Bewertung_VM__c
					&& !profileNameByUserIds.get( lead.OwnerId ).contains( 'myPM Vertrieb (VM' )
					&& profileNameByUserIds.get( UserInfo.getUserId() ).contains( 'myPM Vertrieb (VM' ) ) {
				
				lead.OwnerId = UserInfo.getUserId();
			}
			else {
				//Sonarqube --> do nothing
			}
		}
		return continueLoop;
	}
	
	private void validateDatenaenderung ( Lead lead ) {
		if ( isVerwendeButtonDatenaenderung( lead )
				|| isBemerkungenZurDispoChanged( lead )
				|| isVertragsfelderChanged( lead ) ) {
			lead.addError( 'Änderungen sind nur noch über die Schaltfläche "Datenänderung" möglich.' );
		}
	}
	
	private void validateStorno ( Lead lead ) {
		if ( isVerwendeButtonStorno( lead ) ) {
			lead.STO_disponiert__c.addError( 'Die Stornierung des Standortes darf ' +
					'nur über die Buttons "Storno vor Dispo" bzw. "Storno nach Dispo" geschehen.' );
		}
		if ( isDisponiertChanged( lead ) ) {
			lead.STO_disponiert__c.addError( 'Das Übergabedatum des STO darf nicht mehr geändert werden.' );
		}
	}
	
	protected override void afterUpdate () {
		
		processAfterUpdate();
	}
	
	protected override void afterDelete () {
		leadsByRemovedPODIDs = new Map<Id, List<Lead>>();
		for ( Lead lead : oldLeadMap.values() ) {
			if ( lead.PODID_Lookup__c != null ) {
				if ( leadsByRemovedPODIDs.containsKey( lead.PODID_Lookup__c ) ) {
					leadsByRemovedPODIDs.get( lead.PODID_Lookup__c ).add( lead );
				}
				else {
					leadsByRemovedPODIDs.put( lead.PODID_Lookup__c, new List<Lead> {
							lead
					} );
				}
			}
		}
		if ( !leadsByRemovedPODIDs.isEmpty() ) {
			updatePODIDs( leadsByRemovedPODIDs );
		}
	}
	
	private void processPackstationLead ( Lead lead ) {
		if ( lead.RecordTypeId == PACKSTATION_RT ) {
			Filialnetzaenderung__c filialnetzaenderung = filialnetzaenderungByPostalCodes.containsKey( lead.PostalCode )
					? filialnetzaenderungByPostalCodes.get( lead.PostalCode )
					: new Filialnetzaenderung__c();
			lead.Filialnetzaenderung__c = filialnetzaenderung.Id;
			lead.VL__c = lead.VL__c == null
					? filialnetzaenderung.Filiale_Filialpartner__c
					: lead.VL__c;
			setMitarbeiterAussenorganisationFields( lead );
			lead.OwnerId = LeitregionMapper.getInstance().getKoordinatorForPostalCode( lead.PostalCode );
			if ( isBewertungVertriebsmanager( lead ) ) {
				lead.OwnerId = UserInfo.getUserId();
			}
		}
	}
	
	private void setMitarbeiterAussenorganisationFields ( Lead lead ) {
		if ( isMitarbeiterAussenorganisation( lead ) ) {
			lead.Bewertung_Zentrale__c = lead.Bewertung_Zentrale__c == null
					? 'Vorläufige Freigabe'
					: lead.Bewertung_Zentrale__c;
			lead.LeadSource = lead.LeadSource == null
					? 'VL'
					: lead.LeadSource;
			lead.Interesse_an__c = lead.Interesse_an__c == null
					? 'Packstation'
					: lead.Interesse_an__c;
			lead.Bewerbung_vom__c = lead.Bewerbung_vom__c == null
					? Date.today()
					: lead.Bewerbung_vom__c;
		}
	}
	
	private Boolean isMitarbeiterAussenorganisation ( Lead lead ) {
		return userByIds.containsKey( lead.OwnerId )
				&& userByIds.get( lead.OwnerId ).MitarbeiterAO__c;
	}
	
	private Boolean isBewertungVertriebsmanager ( Lead lead ) {
		return lead.Bewertung_VM__c != null
				&& !profileNameByUserIds.get( lead.OwnerId ).contains( 'myPM Vertrieb (VM' )
				&& profileNameByUserIds.get( UserInfo.getUserId() ).contains( 'myPM Vertrieb (VM' );
	}
	
	private void setVertriebsleitung ( Lead lead, Map<String, Account> vertriebsleitungByPostalCodes ) {
		if ( lead.RecordTypeId != PACKSTATION_RT && vertriebsleitungByPostalCodes.containsKey( lead.PostalCode ) ) {
			Account vertriebsleitung = vertriebsleitungByPostalCodes.get( lead.PostalCode );
			lead.VL__c = vertriebsleitung.Id;
			lead.OwnerId = LeitregionMapper.getInstance().getKoordinatorForPostalCode( lead.PostalCode );
		}
	}
	
	private void populateBeforeInsertSets () {
		for ( Lead lead : newLeads ) {
			emptySalutationFields( lead );
			ownerIds.add( lead.OwnerId );
			postalCodes.add( lead.PostalCode );
			if ( lead.RecordTypeId == PACKSTATION_RT ) {
				postalCodesPackstation.add( lead.PostalCode );
			}
		}
	}
	
	private void resetBeforeInsertSets () {
		ownerIds = new Set<Id>();
		postalCodes = new Set<String>();
		postalCodesPackstation = new Set<String>();
	}
	
	/**
	 * @description MYPM-455
	 */
	private void processAfterInsert () {
		leadsCheckOpenAkquisen = new List<Lead>();
		for ( Lead lead : newLeads ) {
			addRequestIfSendWeidenEingangsbestaetigung( lead );
			addRequestIfSendKommuneEingangsbestaetigung( lead );
			addRequestIfSendKommunikationAufbautermin( lead );
			addPackstationTasks( lead );
			if ( lead.Bewertung_Zentrale__c == 'Sofortiger Ersatz für' && lead.Filialnetzaenderung__c != null ) {
				leadsCheckOpenAkquisen.add( lead );
			}
		}
		if ( !vertragErstellenTaskByLeadIds.isEmpty() ) {
			closeExistingStandortdokumentationVerschickenTasks();
			insert vertragErstellenTaskByLeadIds.values();
		}
		insert akquiseauftraege;
		sendEmails();
		new OnepagerService( newLeadMap ).execute();
		if ( !leadsCheckOpenAkquisen.isEmpty() ) {
			checkOpenAkquisen( leadsCheckOpenAkquisen );
		}
	}
	
	private void addPackstationTasks ( Lead lead ) {
		if ( FeatureManagement.checkPermission( 'ZusammenlegungLeadmanagement1' ) ) {
			if ( isAkquiseauftragPackstationZusaetzlicheEinrichtung( lead ) ) {
				addAkquiseauftragPackstationZusaetzlicheEinrichtungTask( lead );
			}
			if ( isAkquiseauftragPackstationHotlead( lead ) ) {
				addAkquiseauftragPackstationHotleadTask( lead );
			}
			if ( isAkquiseauftragPackstationStandortaufnahme( lead ) ) {
				addAkquiseauftragPackstationStandortaufnahmeTask( lead );
			}
			if ( isAkquiseauftragPackstationStandortdokumentationVerschicken( lead ) ) {
				
				addAkquiseauftragPackstationStandortdokumentationVerschickenTask( lead );
			}
		}
	}
	
	private void loadUsers () {
		userByIds = new Map<Id, User>( [
				SELECT
						Id,
						MitarbeiterAO__c
				FROM User
				WHERE Id IN :ownerIds
		] );
	}
	
	private Boolean isAkquiseauftragPackstationStandortdokumentationVerschicken ( Lead lead ) {
		return lead.Aufgabenanlage__c
				&& ( Trigger.isInsert
				&& lead.DokumentationDurchRTFreigebenDatum__c != null
				&& lead.Akquisemodus__c != 'Standortaufnahme vor Ort; Danach Übergabe an rVU' )
				|| (
				Trigger.isUpdate
						&& lead.DokumentationDurchRTFreigebenDatum__c != null
						&& lead.DokumentationDurchRTFreigebenDatum__c != oldLeadMap.get( lead.Id ).DokumentationDurchRTFreigebenDatum__c
						&& lead.Akquisemodus__c != 'Standortaufnahme vor Ort; Danach Übergabe an rVU'
		);
	}
	
	private Boolean isAkquiseauftragPackstationVertragErstellen ( Lead lead ) {
		return lead.Aufgabenanlage__c
				&& lead.Freigabe_STOG__c != 'Nein - keine Freigabe STOG'
				&& lead.Freigabe_STOG__c != 'Nein - keine rechtzeitige Rückmeldung STOG'
				&& lead.Freigabe_STOG__c != 'Nein - keine Vermieterfreigabe'
				&& lead.Freigabe_STOG__c != 'Nein - Marktumbau <4Jahre'
				&& lead.DokumentationDurchRTFreigebenDatum__c != null
				&& lead.Akquisemodus__c != 'Standortaufnahme vor Ort; Danach Übergabe an rVU'
				&& ( ( lead.Ergebnis_Bauordnungsrechtliche_Pruefung__c == 'Baugenehmigungsfrei, Amt'
				|| lead.Ergebnis_Bauordnungsrechtliche_Pruefung__c == 'Baugenehmigungsfrei, Netzmanager'
				|| lead.Ergebnis_Bauordnungsrechtliche_Pruefung__c == 'Genehmigt' )
				|| ( lead.Ergebnis_weit_Bauordnungsrechtl_Pruefung__c == 'Genehmigt' ) );
	}
	
	private Boolean isAkquiseauftragPackstationZusaetzlicheEinrichtung ( Lead lead ) {
		return lead.Aufgabenanlage__c
				&& lead.Bewertung_Zentrale__c == 'Geeignet - Priorisierte Bearbeitung'
				&& lead.Akquisemodus__c != 'Standortaufnahme vor Ort; Danach Übergabe an rVU'
				&& ( Trigger.isInsert || oldLeadMap.get( lead.Id ).Bewertung_Zentrale__c != lead.Bewertung_Zentrale__c );
	}
	
	private Boolean isAkquiseauftragPackstationHotlead ( Lead lead ) {
		return lead.Aufgabenanlage__c
				&& lead.Bewertung_Zentrale__c == 'Geeignet - Hotlead'
				&& lead.Akquisemodus__c != 'Standortaufnahme vor Ort; Danach Übergabe an rVU'
				&& ( Trigger.isInsert || oldLeadMap.get( lead.Id ).Bewertung_Zentrale__c != lead.Bewertung_Zentrale__c );
	}
	
	private Boolean isAkquiseauftragPackstationStandortaufnahme ( Lead lead ) {
		return lead.Aufgabenanlage__c
				&& ( lead?.Bewertung_Zentrale__c == 'Geeignet - Priorisierte Bearbeitung'
				|| lead?.Bewertung_Zentrale__c == 'Geeignet - Hotlead' )
				&& lead?.Akquisemodus__c == 'Standortaufnahme vor Ort; Danach Übergabe an rVU'
				&& ( Trigger.isInsert || oldLeadMap.get( lead.Id ).Bewertung_Zentrale__c != lead.Bewertung_Zentrale__c );
	}
	
	private void addAkquiseauftragPackstationStandortdokumentationVerschickenTask ( Lead lead ) {
		akquiseauftraege.add(
				new Task(
						Aufgabenart__c = 'Standortdokumentation verschicken und Freigabe STOG einholen',
						Auftraggeber__c = 'Vertriebsleiter',
						Auftragnehmer__c = 'Inhaber des Leads',
						ActivityDate = Date.today(),
						Erledigung_bis_zum__c = Date.today().addDays( 18 ),
						Status = 'Nicht begonnen',
						Priority = 'Mittel',
						RecordTypeId = AKQUISEAUFTRAG_PACKSTATION_RT,
						WhoId = lead.Id,
						Filialnetzaenderung__c = lead.Filialnetzaenderung__c
				)
		);
	}
	
	private void addAkquiseauftragPackstationZusaetzlicheEinrichtungTask ( Lead lead ) {
		akquiseauftraege.add(
				new Task(
						Aufgabenart__c = 'Akquiseauftrag Packstation - Priorisierte Bearbeitung',
						Auftraggeber__c = 'Vertriebsleiter',
						Auftragnehmer__c = 'Inhaber des Leads',
						ActivityDate = Date.today(),
						Erledigung_bis_zum__c = Date.today().addDays( 84 ),
						Status = 'Nicht begonnen',
						Priority = 'Mittel',
						Typc__c = 'Besuch',
						Filialnetzaenderung__c = lead.Filialnetzaenderung__c,
						RecordTypeId = AKQUISEAUFTRAG_PACKSTATION_RT,
						WhoId = lead.Id,
						ZielFachanzahl__c = lead.Ziel_Fachanzahl__c
				)
		);
		akquiseauftraege.add(
				new Task(
						Aufgabenart__c = 'Standort erschließen',
						Auftraggeber__c = 'Vertriebsleiter',
						Auftragnehmer__c = 'Inhaber des Leads',
						ActivityDate = Date.today(),
						Erledigung_bis_zum__c = Date.today().addDays( 28 ),
						Status = 'Nicht begonnen',
						Priority = 'Mittel',
						Typc__c = 'Intern',
						Filialnetzaenderung__c = lead.Filialnetzaenderung__c,
						RecordTypeId = AKQUISEAUFTRAG_PACKSTATION_RT,
						WhoId = lead.Id
				)
		);
	}
	
	private void addAkquiseauftragPackstationHotleadTask ( Lead lead ) {
		
		akquiseauftraege.add(
				new Task(
						Aufgabenart__c = 'Akquiseauftrag Packstation - Priorisierte Bearbeitung',
						Auftraggeber__c = 'Vertriebsleiter',
						Auftragnehmer__c = 'Inhaber des Leads',
						ActivityDate = Date.today(),
						Erledigung_bis_zum__c = Date.today().addDays( 70 ),
						Status = 'Nicht begonnen',
						Priority = 'Mittel',
						Typc__c = 'Besuch',
						Filialnetzaenderung__c = lead.Filialnetzaenderung__c,
						RecordTypeId = AKQUISEAUFTRAG_PACKSTATION_RT,
						WhoId = lead.Id,
						ZielFachanzahl__c = lead.Ziel_Fachanzahl__c
				)
		);
		akquiseauftraege.add(
				new Task(
						Aufgabenart__c = 'Standort erschließen',
						Auftraggeber__c = 'Vertriebsleiter',
						Auftragnehmer__c = 'Inhaber des Leads',
						ActivityDate = Date.today(),
						Erledigung_bis_zum__c = Date.today().addDays( 14 ),
						Status = 'Nicht begonnen',
						Priority = 'Mittel',
						Typc__c = 'Intern',
						Filialnetzaenderung__c = lead.Filialnetzaenderung__c,
						RecordTypeId = AKQUISEAUFTRAG_PACKSTATION_RT,
						WhoId = lead.Id
				)
		);
	}
	
	private void addAkquiseauftragPackstationStandortaufnahmeTask ( Lead lead ) {
		akquiseauftraege.add(
				new Task(
						Aufgabenart__c = 'Standortaufnahme durchführen',
						Auftraggeber__c = 'Regionale Vertriebsunterstützung',
						Auftragnehmer__c = 'Vertriebskoordinator VGL',
						ActivityDate = Date.today(),
						Erledigung_bis_zum__c = Date.today().addDays( 28 ),
						Status = 'Nicht begonnen',
						Priority = 'Mittel',
						Filialnetzaenderung__c = lead.Filialnetzaenderung__c,
						RecordTypeId = AKQUISEAUFTRAG_PACKSTATION_RT,
						WhoId = lead.Id,
						ZielFachanzahl__c = lead.Ziel_Fachanzahl__c,
						Typc__c = 'Besuch',
						Type = 'Besuch'
				)
		);
	}
	
	private void addRequestIfSendWeidenEingangsbestaetigung ( Lead lead ) {
		if ( lead.Emailanlage__c
				&& lead.RecordTypeId == PACKSTATION_RT
				&& lead.LeadSource != null
				&& lead.LeadSource.contains( 'Weiden' ) ) {
			addRequest( lead.Id, 'WeidenEingangsbestaetigung' );
		}
	}
	
	private void addRequestIfSendKommuneEingangsbestaetigung ( Lead lead ) {
		if ( lead.Emailanlage__c
				&& lead.RecordTypeId == PACKSTATION_RT
				&& lead.LeadSource != null
				&& lead.LeadSource.contains( 'Kommune' ) ) {
			addRequest( lead.Id, 'KommuneEingangsbestaetigung' );
		}
	}
	
	/**
	 * @description MYPM-429
	 */
	private void processAfterUpdate () {
		
		resetAfterUpdateCollections();
		for ( Lead lead : newLeads ) {
			
			if ( processedIds.contains( lead.Id ) ) {
				continue;
			}
			else if ( Trigger.isUpdate ) {
				processedIds.add( lead.Id );
				onepagerLeadByIds.put( lead.Id, lead );
			}
			else {
				//Sonarqube --> do nothing
			}
			addEmails( lead );
			addTasks( lead );
			addRequestIfSendAbbruchBearbeitung( lead );
			addRemovedPODID( lead );
			if ( lead.ist_disponiert__c
					&& !oldLeadMap.get( lead.Id ).ist_disponiert__c ) {
				
				leadIdsDummyPackstation.add( lead.Id );
			}
			addPackstationAbbau( lead );
			if ( lead.Entlastung_durch_2_Automat_selber_STO__c == 'Ja'
					&& isChanged( lead, 'Entlastung_durch_2_Automat_selber_STO__c' ) ) {
				
				leadIdsDummyPackstation.add( lead.Id );
				leadIdsDummyPackstationCloneAccountCountactRelations.add( lead.Id );
			}
			addBeauftragungTvm( lead );
			addPackstationAbbauDatumRequests(lead);
		}
		processOnepager();
		processVertragErstellenTasks();
		insert akquiseauftraege;
		sendEmails();
		updateOpenAkquisen();
		checkOpenAkquisen();
		updatePODIDs();
		createPackstationDummies();
		createAbbauLeads();
	}
	
	private void processOnepager () {
		if ( !onepagerLeadByIds.keySet().isEmpty() ) {
			new OnepagerService( onepagerLeadByIds ).execute();
		}
	}
	
	private void processVertragErstellenTasks () {
		if ( !vertragErstellenTaskByLeadIds.isEmpty() ) {
			closeExistingStandortdokumentationVerschickenTasks();
			insert vertragErstellenTaskByLeadIds.values();
		}
	}
	
	private void updateOpenAkquisen () {
		if ( !leadsChangedZielFachanzahlById.keySet().isEmpty() ) {
			updateOpenAkquisen( leadsChangedZielFachanzahlById );
		}
	}
	
	private void checkOpenAkquisen () {
		if ( !leadsCheckOpenAkquisen.isEmpty() ) {
			checkOpenAkquisen( leadsCheckOpenAkquisen );
		}
	}
	
	private void updatePODIDs () {
		if ( !leadsByRemovedPODIDs.isEmpty() ) {
			updatePODIDs( leadsByRemovedPODIDs );
		}
	}
	
	private void createPackstationDummies () {
		if ( !leadIdsDummyPackstation.isEmpty() ) {
			createPackstationDummies( leadIdsDummyPackstation, leadIdsDummyPackstationCloneAccountCountactRelations );
		}
	}
	
	private void createAbbauLeads () {
		if ( !leadIdsPackstationAbbau.isEmpty() ) {
			new PackstationService().createAbbauLeads( leadIdsPackstationAbbau );
		}
	}
	
	private void sendEmails () {
		EmailSettingService.getInstance().sendBulk();
	}
	
	private void addPackstationAbbau ( Lead lead ) {
		if ( isEntlastungAbbau( lead )
				&& !isEntlastungAbbau( oldLeadMap.get( lead.Id ) ) ) {
			leadIdsPackstationAbbau.add( lead.Id );
		}
		else if ( isFormataenderungAbbau( lead )
				&& !isFormataenderungAbbau( oldLeadMap.get( lead.Id ) ) ) {
			leadIdsPackstationAbbau.add( lead.Id );
		}
		else {
			//Sonarqube --> do nothing
		}
	}
	
	private void addRemovedPODID ( Lead lead ) {
		if ( lead.PODID_Lookup__c == null
				&& oldLeadMap.get( lead.Id ).PODID_Lookup__c != null ) {
			Lead oldLead = oldLeadMap.get( lead.Id );
			if ( leadsByRemovedPODIDs.containsKey( oldLead.PODID_Lookup__c ) ) {
				leadsByRemovedPODIDs.get( oldLead.PODID_Lookup__c ).add( oldLead );
			}
			else {
				leadsByRemovedPODIDs.put( oldLead.PODID_Lookup__c, new List<Lead> {
						oldLead
				} );
			}
		}
	}
	
	private void addTasks ( Lead lead ) {
		if ( FeatureManagement.checkPermission( 'ZusammenlegungLeadmanagement1' ) ) {
			if ( isAkquiseauftragPackstationZusaetzlicheEinrichtung( lead ) ) {
				addAkquiseauftragPackstationZusaetzlicheEinrichtungTask( lead );
			}
			if ( isAkquiseauftragPackstationHotlead( lead ) ) {
				addAkquiseauftragPackstationHotleadTask( lead );
			}
			if ( isAkquiseauftragPackstationStandortaufnahme( lead ) ) {
				addAkquiseauftragPackstationStandortaufnahmeTask( lead );
			}
			addStandortdokumentationVerschicken( lead );
			if ( isZielFachanzahlChanged( lead ) ) {
				leadsChangedZielFachanzahlById.put( lead.Id, lead );
			}
			if ( isCheckOpenAkquisen( lead ) ) {
				leadsCheckOpenAkquisen.add( lead );
			}
		}
	}
	
	private void addStandortdokumentationVerschicken ( Lead lead ) {
		if ( isAkquiseauftragPackstationStandortdokumentationVerschicken( lead )
				&& !isAkquiseauftragPackstationVertragErstellen( lead ) ) {
			
			addAkquiseauftragPackstationStandortdokumentationVerschickenTask( lead );
		}
	}
	
	private Boolean isCheckOpenAkquisen ( Lead lead ) {
		return lead.Bewertung_Zentrale__c == 'Sofortiger Ersatz für'
				&& oldLeadMap.get( lead.Id ).Bewertung_Zentrale__c != 'Sofortiger Ersatz für'
				&& lead.Filialnetzaenderung__c != null;
	}
	
	private Boolean isZielFachanzahlChanged ( Lead lead ) {
		return ( lead.Bewertung_Zentrale__c == 'Geeignet - Priorisierte Bearbeitung'
				|| lead.Bewertung_Zentrale__c == 'Geeignet - Hotlead' )
				&& lead.Ziel_Fachanzahl__c != oldLeadMap.get( lead.Id ).Ziel_Fachanzahl__c;
	}
	
	private void addEmails ( Lead lead ) {
		addRequestIfSendWeidenEignung( lead );
		addRequestIfSendKommuneEignung( lead );
		addRequestIfSendWeidenAbsageFehlenderBedarf( lead );
		addRequestIfSendKommuneAbsageFehlenderBedarf( lead );
		addRequestIfSendWeidenAbsageZuGeringerBedarf( lead );
		addRequestIfSendKommuneAbsageZuGeringerBedarf( lead );
		addRequestIfSendWeidenAbsageMikrostandort( lead );
		addRequestIfSendKommunikationAufbautermin( lead );
		addRequestIfSendKommunikationAufbauterminAenderung( lead );
		addRequestIfSendKommunikationAufbauterminStorno( lead );
	}
	
	private void resetAfterUpdateCollections () {
		leadsChangedZielFachanzahlById = new Map<Id, Lead>();
		leadsCheckOpenAkquisen = new List<Lead>();
		onepagerLeadByIds = new Map<Id, SObject>();
		leadsByRemovedPODIDs = new Map<Id, List<Lead>>();
		leadIdsDummyPackstation = new Set<Id>();
		leadIdsDummyPackstationCloneAccountCountactRelations = new Set<Id>();
		leadIdsPackstationAbbau = new Set<Id>();
	}
	
	private void addRequestIfSendKommunikationAufbautermin ( Lead lead ) {
		if ( lead.Emailanlage__c
				&& lead.RecordTypeId == PACKSTATION_RT
				&& ( ( lead.AufstelldatumADM__c != null
				&& Trigger.isInsert )
				|| ( Trigger.isUpdate
				&& lead.AufstelldatumADM__c != null
				&& oldLeadMap.get( lead.Id ).AufstelldatumADM__c == null ) ) ) {
			
			addRequest( lead.Id, 'KommunikationAufbauterminMYPM915' );
		}
	}
	
	private void addRequestIfSendKommunikationAufbauterminAenderung ( Lead lead ) {
		if ( lead.Emailanlage__c
				&& lead.RecordTypeId == PACKSTATION_RT
				&& lead.AufstelldatumADM__c != null
				&& lead.AufstelldatumADM__c != oldLeadMap.get( lead.Id ).AufstelldatumADM__c
				&& oldLeadMap.get( lead.Id ).AufstelldatumADM__c != null ) {
			
			addRequest( lead.Id, 'KommunikationAufbauterminAenderunMYPM915' );
		}
	}
	
	private void addRequestIfSendKommunikationAufbauterminStorno ( Lead lead ) {
		if ( lead.Emailanlage__c
				&& lead.RecordTypeId == PACKSTATION_RT
				&& lead.AufstelldatumADM__c == null
				&& lead.AufstelldatumADM__c != oldLeadMap.get( lead.Id ).AufstelldatumADM__c
				&& oldLeadMap.get( lead.Id ).AufstelldatumADM__c != null ) {
			
			addRequest( lead.Id, 'KommunikationAufbauterminStornoMYPM915' );
		}
	}
	
	private void addRequestIfSendAbbruchBearbeitung ( Lead lead ) {
		if ( isAbbruchBearbeitung( lead )
				&& !isAbbruchBearbeitung( oldLeadMap.get( lead.Id ) ) ) {
			addRequest(lead.Id, 'AbbruchBearbeitungLead_MYPM682');
		}
	}
	
	private Boolean isAbbruchBearbeitung ( Lead lead ) {
		return lead.Emailanlage__c
				&& lead.Bewertung_Zentrale__c == 'Nicht geeignet, zu nah an Bestand'
				|| lead.Bewertung_Zentrale__c == 'Nicht geeignet, zu geringes Potenzial'
				|| lead.Bewertung_Zentrale__c == 'Durch Zentrale STOG abgelehnt'
				|| lead.Bewertung_Zentrale__c == 'Geeignet, kein Bedarf';
	}
	
	private void addRequestIfSendWeidenEignung ( Lead lead ) {
		if ( lead.Emailanlage__c
				&& lead.RecordTypeId == PACKSTATION_RT
				&& lead.LeadSource != null
				&& lead.LeadSource.contains( 'Weiden' )
				&& lead.Potenzial__c != 'E - PLZ-Gebiet ohne Bedarf'
				&& lead.Bewertung_Zentrale__c == 'Geeignet'
				&& lead.Bewertung_Zentrale__c != oldLeadMap.get( lead.Id ).Bewertung_Zentrale__c ) {
			
			addRequest( lead.Id, 'WeidenEignung' );
		}
	}
	
	private void addRequestIfSendKommuneEignung ( Lead lead ) {
		if ( lead.Emailanlage__c
				&& lead.RecordTypeId == PACKSTATION_RT
				&& lead.LeadSource != null
				&& lead.LeadSource.contains( 'Kommune' )
				&& ( lead.Bewertung_Zentrale__c == 'Geeignet'
				|| lead.Bewertung_Zentrale__c == 'Geeignet - Priorisierte Bearbeitung'
				|| lead.Bewertung_Zentrale__c == 'Geeignet - Hotlead' )
				&& lead.Bewertung_Zentrale__c != oldLeadMap.get( lead.Id ).Bewertung_Zentrale__c ) {
			
			addRequest( lead.Id, 'KommuneEignung' );
		}
	}
	
	private void addRequestAbsageFehlenderBedarf ( Lead lead, String variant ) {
		if ( lead.Emailanlage__c
				&& lead.RecordTypeId == PACKSTATION_RT
				&& lead.LeadSource != null
				&& lead.LeadSource.contains( variant )
				&& ( lead.Bewertung_Zentrale__c == 'Geeignet, kein Bedarf'
				|| lead.Bewertung_Zentrale__c == 'Nicht geeignet, zu nah an Bestand' )
				&& lead.Bewertung_Zentrale__c != oldLeadMap.get( lead.Id ).Bewertung_Zentrale__c ) {
			
			addRequest( lead.Id, variant + 'AbsageFehlenderBedarf' );
		}
		else if ( lead.Emailanlage__c
				&& lead.RecordTypeId == PACKSTATION_RT
				&& lead.LeadSource != null
				&& lead.LeadSource.contains( variant )
				&& lead.Doku_erstellt__c == null
				&& lead.Bewertung_VM__c == 'Absage DHL - kein Potenzial'
				&& lead.Bewertung_VM__c != oldLeadMap.get( lead.Id ).Bewertung_VM__c ) {
			
			addRequest( lead.Id, variant + 'AbsageFehlenderBedarf' );
		}
		else {
			//Sonarqube --> do nothing
		}
	}
	
	private void addRequestIfSendWeidenAbsageFehlenderBedarf ( Lead lead ) {
		addRequestAbsageFehlenderBedarf( lead, 'Weiden' );
	}
	
	private void addRequestIfSendKommuneAbsageFehlenderBedarf ( Lead lead ) {
		addRequestAbsageFehlenderBedarf( lead, 'Kommune' );
	}
	
	private void addRequestIfSendWeidenAbsageZuGeringerBedarf ( Lead lead ) {
		if ( lead.Emailanlage__c
				&& lead.RecordTypeId == PACKSTATION_RT
				&& lead.LeadSource != null
				&& lead.LeadSource.contains( 'Weiden' )
				&& lead.Bewertung_Zentrale__c == 'Nicht geeignet, zu geringes Potenzial'
				&& lead.Bewertung_Zentrale__c != oldLeadMap.get( lead.Id ).Bewertung_Zentrale__c ) {
			
			addRequest( lead.Id, 'WeidenAbsageZuGeringerBedarf' );
		}
	}
	
	private void addRequestIfSendKommuneAbsageZuGeringerBedarf ( Lead lead ) {
		if ( lead.Emailanlage__c
				&& lead.RecordTypeId == PACKSTATION_RT
				&& lead.LeadSource != null
				&& lead.LeadSource.contains( 'Kommune' )
				&& lead.Bewertung_Zentrale__c == 'Nicht geeignet, zu geringes Potenzial'
				&& lead.Bewertung_Zentrale__c != oldLeadMap.get( lead.Id ).Bewertung_Zentrale__c ) {
			
			addRequest( lead.Id, 'KommuneAbsageZuGeringerBedarf' );
		}
	}
	
	private void addRequestIfSendWeidenAbsageMikrostandort ( Lead lead ) {
		if ( lead.Emailanlage__c
				&& lead.RecordTypeId == PACKSTATION_RT
				&& lead.LeadSource != null
				&& lead.LeadSource.contains( 'Weiden' )
				&& lead.Standortaufnahme__c == null
				&& lead.Bewertung_VM__c == 'Absage DHL - kein Mikro-STO'
				&& lead.Bewertung_VM__c != oldLeadMap.get( lead.Id ).Bewertung_VM__c ) {
			
			addRequest( lead.Id, 'WeidenAbsageMikrostandort' );
		}
	}
	
	private void addRequest ( String leadId, String emailSettingDeveloperName ) {
		EmailSettingService.Request request = new EmailSettingService.Request();
		request.recordId = leadId;
		request.emailSettingName = emailSettingDeveloperName;
		request.leadId = leadId;
		EmailSettingService.getInstance().requests.add( request );
	}
	
	private void addPackstationRequest ( Lead lead, String emailSettingDeveloperName ) {
		EmailSettingService.Request request = new EmailSettingService.Request();
		request.recordId = lead.Id;
		request.emailSettingName = emailSettingDeveloperName;
		request.leadId = lead.Id;
		request.accountId = lead.Packstation__c;
		EmailSettingService.getInstance().requests.add( request );
	}
	
	private void assignAnlagennummer () {
		List<Lead> relevantLeadsAnlagennummerAssignment = new List<Lead>();
		for ( Lead lead : newLeadMap.values() ) {
			if ( lead.RelevantFuerZuordnungAnlagennummer__c ) {
				relevantLeadsAnlagennummerAssignment.add( lead );
			}
		}
		if ( relevantLeadsAnlagennummerAssignment.size() > 0 ) {
			new AnlagennummerAssignmentService().assign( relevantLeadsAnlagennummerAssignment );
		}
	}
	
	private void identifyRemovedAnlagennummers () {
		List<Anlagennummer__c> anlagennummers = new List<Anlagennummer__c>();
		List<AnlagennummerHistorie__c> anlagennummerHistories = new List<AnlagennummerHistorie__c>();
		for ( Lead lead : newLeads ) {
			if ( lead.Anlagennummer__c == null && oldLeadMap.get( lead.Id ).Anlagennummer__c != null ) {
				lead.AnlagennummerDuplikatscheck__c = null;
				String removedAnlagennummer = oldLeadMap.get( lead.Id ).Anlagennummer__c;
				anlagennummers.add(
						new Anlagennummer__c(
								Id = removedAnlagennummer,
								Status__c = 'gesperrt'
						)
				);
				anlagennummerHistories.add(
						new AnlagennummerHistorie__c(
								Anlagennummer__c = removedAnlagennummer,
								Aktion__c = 'Entfernt',
								Nachricht__c = 'Die Anlagennummer wurde gesperrt und wird nicht weiterverwendet.',
								Lead__c = lead.Id
						)
				);
			}
		}
		update anlagennummers;
		insert anlagennummerHistories;
	}
	
	private void updateOpenAkquisen ( Map<Id, Lead> leadsById ) {
		
		List<Task> tasks = new List<Task>();
		for ( Task task : [
				SELECT
						Id,
						WhoId
				FROM Task
				WHERE WhoId IN :leadsById.keySet()
				AND RecordTypeId = :AKQUISEAUFTRAG_PACKSTATION_RT
				AND IsClosed = FALSE
		] ) {
			
			task.ZielFachanzahl__c = leadsById.get( task.WhoId ).Ziel_Fachanzahl__c;
			tasks.add( task );
		}
		update tasks;
	}
	
	private void checkOpenAkquisen ( List<Lead> leads ) {
		Set<Id> fnaeIds = new Set<Id>();
		for ( Lead lead : leads ) {
			fnaeIds.add( lead.Filialnetzaenderung__c );
		}
		Map<Id, Task> openAkquisenByFnaeId = new Map<Id, Task>();
		for ( Task task : [
				SELECT
						Id,
						Filialnetzaenderung__c,
						Filialnetzaenderung__r.Filiale_Filialpartner__c
				FROM Task
				WHERE IsClosed = FALSE
				AND RecordTypeId = :AKQUISEAUFTRAG_RT
				AND Filialnetzaenderung__c IN :fnaeIds
		] ) {
			
			openAkquisenByFnaeId.put( task.Filialnetzaenderung__c, task );
		}
		List<Task> newAkquisen = new List<Task>();
		for ( Lead lead : [
				SELECT
						Id,
						Filialnetzaenderung__c,
						Filialnetzaenderung__r.Filiale_Filialpartner__c,
						Filialnetzaenderung__r.Name,
						Filialnetzaenderung__r.Netzentscheidung__c,
						Filialnetzaenderung__r.Zieltermin__c,
						Filialnetzaenderung__r.mit_Postfachanlage__c,
						Filialnetzaenderung__r.Auftrag_Paketausgabe__c,
						Filialnetzaenderung__r.Paketausgabemengen__c,
						Filialnetzaenderung__r.Auftrag_Briefausgabe__c,
						Filialnetzaenderung__r.Briefausgabemenge__c,
						Filialnetzaenderung__r.Grund__c,
						Filialnetzaenderung__r.Neuer_Standort_PLZ__c,
						Filialnetzaenderung__r.Neuer_Standort_Stadt__c,
						Filialnetzaenderung__r.Neuer_Standort_Strasse__c,
						Filialnetzaenderung__r.Letzte_Aenderung_Interessenten_am__c
				FROM Lead
				WHERE Id IN :leads
		] ) {
			if ( !openAkquisenByFnaeId.containsKey( lead.Filialnetzaenderung__c )
					&& newLeadMap.get( lead.Id ).Aufgabenanlage__c ) {
				
				newAkquisen.add(
						new Task(
								WhatId = lead.Filialnetzaenderung__r.Filiale_Filialpartner__c,
								Filialnetzaenderung__c = lead.Filialnetzaenderung__c,
								FNAE_Id__c = lead.Filialnetzaenderung__r.Name,
								RecordTypeId = AKQUISEAUFTRAG_RT,
								Aufgabenart__c = lead.Filialnetzaenderung__r.Netzentscheidung__c != null
										&& lead.Filialnetzaenderung__r.Netzentscheidung__c.contains( 'OZ 82' )
										? 'Akquiseauftrag DHL Paketshop + Detail'
										: 'Akquiseauftrag Filiale + Detail',
								Priority = 'Hoch',
								Auftraggeber__c = '3500 Betriebssteuerung',
								Auftragnehmer__c = 'Vertriebskoordinator VGL',
								ActivityDate = Date.today(),
								Erledigung_bis_zum__c = Date.today().addDays( 28 ),
								Auftrag_zur_PartnerAkquise__c = lead.Filialnetzaenderung__r.Netzentscheidung__c,
								Zieltermin__c = lead.Filialnetzaenderung__r.Zieltermin__c,
								Auftrag_zur_PfA_Akquisition__c = lead.Filialnetzaenderung__r.mit_Postfachanlage__c,
								Auftrag_zur_PA_Akquisition__c = lead.Filialnetzaenderung__r.Auftrag_Paketausgabe__c,
								Paketausgabemenge__c = lead.Filialnetzaenderung__r.Paketausgabemengen__c,
								Auftrag_zur_BA_Akquisition__c = lead.Filialnetzaenderung__r.Auftrag_Briefausgabe__c,
								Briefausgabemenge__c = lead.Filialnetzaenderung__r.Briefausgabemenge__c,
								Aenderungsgrund_Standort__c = lead.Filialnetzaenderung__r.Grund__c
										+ ' / Neuer Standort: ' + lead.Filialnetzaenderung__r.Neuer_Standort_PLZ__c
										+ ' ' + lead.Filialnetzaenderung__r.Neuer_Standort_Stadt__c + ', '
										+ lead.Filialnetzaenderung__r.Neuer_Standort_Strasse__c,
								Letzte_Aenderung_Interessenten_in_FNA_am__c = lead.Filialnetzaenderung__r.Letzte_Aenderung_Interessenten_am__c == null
										? '' : lead.Filialnetzaenderung__r.Letzte_Aenderung_Interessenten_am__c.day()
												+ '.' + lead.Filialnetzaenderung__r.Letzte_Aenderung_Interessenten_am__c.month()
												+ '.' + lead.Filialnetzaenderung__r.Letzte_Aenderung_Interessenten_am__c.year(),
								Zusatzinfo_Akquise__c = 'Neuer Lead im Suchbereich vorhanden',
								Description = 'Neuer Lead/Interessent vorhanden! Bitte im Rahmen der Akquise auf das ' +
										'Online-Lernangebot in Filipedia und das Formular für Partner zur Anzeige ' +
										'gemäß §36 Postgesetz (https://mypm.lightning.force.com/sfc/#version?selectedDocumentId=06924000003YayQ) ' +
										'aufmerksam machen. Bei Upgrade eines DHL Paketshops ist ein Aufhebungsvertrag ' +
										'für den Paketshop abzuschließen und an Weiden zu senden. Vielversprechende ' +
										'potentielle Partner (z.B. aus dem Handelsbesatz) sind als Lead anzulegen ' +
										'und bestenfalls bis zur Vertragsverhandlung und Stammdatenanlage ' +
										'(Konvertierung in eine Filiale) zu bearbeiten. Bei erfolgloser Akquise ' +
										'einer Partner-Filiale sind die Akquiseergebnisse im Handelsbesatz ' +
										'(siehe Dateien zur FNAE) zu dokumentieren und dem Akquiseauftrag anzufügen. ' +
										'Die angegebene Paketausgabekapazität ist zwingend am Nachfolgestandort, ' +
										'im Suchbereich oder als letzte Option in der Gemeinde zu schaffen. Gibt es ' +
										'keinen Vorgängerstandort, der bereits Paketausgabe gemacht hat, muss der ' +
										'Eröffnungstermin und die Ausgabemenge vor Vertragsunterschrift mit der ' +
										'NL Brief abgestimmt werden.',
								Status = 'Nicht begonnen'
						)
				);
			}
		}
		insert newAkquisen;
	}
	
	private void loadVertriebsleitungByPostalCodes () {
		Map<String, String> orgeNameByPostalCodes = new Map<String, String>();
		Set<String> names = new Set<String>();
		for ( PLZ_zu_VGL__c plzZuVGL : [
				SELECT
						Id,
						PLZ_5_stellig__c,
						VGL25_Name__c
				FROM PLZ_zu_VGL__c
				WHERE PLZ_5_stellig__c IN :postalCodes
		] ) {
			
			orgeNameByPostalCodes.put( plzZuVGL.PLZ_5_stellig__c, plzZuVGL.VGL25_Name__c );
			names.add( plzZuVGL.VGL25_Name__c );
		}
		vertriebsleitungByPostalCodes = new Map<String, Account>();
		Map<String, Account> accountByNames = new Map<String, Account>();
		for ( Account account : [
				SELECT
						Id,
						OwnerId,
						Name
				FROM Account
				WHERE Name IN :names
				AND RecordType.DeveloperName = 'OrgE_Dummy'
		] ) {
			accountByNames.put( account.Name, account );
		}
		for ( String postalCode : orgeNameByPostalCodes.keySet() ) {
			if ( accountByNames.containsKey( orgeNameByPostalCodes.get( postalCode ) ) ) {
				vertriebsleitungByPostalCodes.put( postalCode, accountByNames.get( orgeNameByPostalCodes.get( postalCode ) ) );
			}
		}
	}
	
	private void loadFilialnetzaenderungByPostalCodes () {
		filialnetzaenderungByPostalCodes = new Map<String, Filialnetzaenderung__c>();
		for ( Filialnetzaenderung__c filialnetzaenderung : [
				SELECT
						Id,
						Neuer_Standort_PLZ__c,
						VL_Filialvertrieb__c,
						Filiale_Filialpartner__c
				FROM Filialnetzaenderung__c
				WHERE Neuer_Standort_PLZ__c IN :postalCodesPackstation
				AND RecordType.DeveloperName = 'Packstation'
		] ) {
			filialnetzaenderungByPostalCodes.put( filialnetzaenderung.Neuer_Standort_PLZ__c, filialnetzaenderung );
		}
	}
	
	private void loadProfileNameByUserIds () {
		Set<String> userIds = new Set<String>();
		for ( Lead lead : newLeads ) {
			userIds.add( lead.OwnerId );
		}
		userIds.add( UserInfo.getUserId() );
		profileNameByUserIds = new Map<String, String>();
		for ( User user : [
				SELECT
						Id,
						Profile.Name
				FROM User
				WHERE Id IN :userIds
		] ) {
			
			profileNameByUserIds.put( user.Id, user.Profile.Name );
		}
	}
	
	private void closeExistingStandortdokumentationVerschickenTasks () {
		List<Task> tasks = new List<Task>();
		for ( Task task : [
				SELECT
						Id
				FROM Task
				WHERE Aufgabenart__c = 'Standortdokumentation verschicken und Freigabe STOG einholen'
				AND WhoId IN :vertragErstellenTaskByLeadIds.keySet()
				AND IsClosed = FALSE
		] ) {
			
			task.Status = 'Zurückgezogen (Nur AG)';
			task.Erledigungsvermerk__c = 'Aufgabe obsolet, da die Standortdokumentation ' +
					'mit dem Vertrag verschickt und abgenommen wird.';
			tasks.add( task );
		}
		update tasks;
	}
	
	private void emptySalutationFields ( Lead lead ) {
		lead.Salutation = null;
		lead.VP_Anrede__c = null;
	}
	
	private void updatePODIDs ( Map<Id, List<Lead>> leadsByRemovedPODIDs ) {
		Set<Id> existingReferences = new Set<Id>();
		for ( Lead lead : [
				SELECT
						Id,
						PODID_Lookup__c
				FROM Lead
				WHERE PODID_Lookup__c IN :leadsByRemovedPODIDs.keySet()
		] ) {
			existingReferences.add( lead.PODID_Lookup__c );
		}
		for ( Account account : [
				SELECT
						Id,
						PODID__c
				FROM Account
				WHERE PODID__c IN :leadsByRemovedPODIDs.keySet()
		] ) {
			existingReferences.add( account.PODID__c );
		}
		List<PODID__c> podids = new List<PODID__c>();
		for ( PODID__c podId : [
				SELECT
						Id,
						Anmerkung__c,
						Wert__c
				FROM PODID__c
				WHERE Id IN :leadsByRemovedPODIDs.keySet()
		] ) {
			for ( Lead lead : leadsByRemovedPODIDs.get( podId.Id ) ) {
				if ( !existingReferences.contains( podId.Id ) ) {
					podId.Status__c = 'Gelöscht';
				}
				if ( podId.Anmerkung__c == null ) {
					podId.Anmerkung__c = '';
				}
				podId.Anmerkung__c += '\n' + Date.today().format() + ': PODID "' + podId.Wert__c + '" wurde aus dem Lead "'
						+ lead.FirstName + ' ' + lead.LastName + '" (' + lead.Id + ') entfernt.';
			}
			podids.add( podId );
		}
		update podids;
	}
	
	private void createPackstationDummies ( Set<Id> leadIds, Set<Id> leadIdsCloneContacts ) {
		PackstationDummyInitializer packstationDummyInitializer = new PackstationDummyInitializer();
		packstationDummyInitializer.create( leadIds );
		if ( !leadIdsCloneContacts.isEmpty() ) {
			packstationDummyInitializer.cloneAccountContactRelations( leadIdsCloneContacts );
		}
	}
	
	private Boolean isKeineEntlastungMoeglich ( Lead lead ) {
		return lead.Entlastung_durch_mod_Erweiterung__c == 'Nein'
				&& lead.Entlastung_durch_Austausch__c == 'Nein'
				&& lead.Entlastung_durch_2_Automat_selber_STO__c == 'Nein';
	}
	
	private void setFieldsKeineEntlastungMoeglich ( Lead lead ) {
		
		lead.Bewertung_VM__c = 'Absage DHL - Sonstiges (Grund in Freitext)';
		lead.Bewertung_VM_vom__c = Date.today();
		String hinweis = lead.Hinweis_AO__c == null ? '' : lead.Hinweis_AO__c;
		lead.Hinweis_AO__c = 'Entlastung durch Erweiterung / Austausch / 2. Automat nicht möglich. '
				+ '\r\n'
				+ hinweis;
		lead.Aktivitaetsstatus__c = 'inaktiv';
	}
	
	private Boolean isEntlastungAbbau ( Lead lead ) {
		return lead.Entlastung_durch_Austausch__c == 'Ja'
				&& lead.Freigabe_STOG__c == 'Ja';
	}
	
	private Boolean isFormataenderungAbbau ( Lead lead ) {
		return lead.Bestandsmassnahme__c == 'Formatwechsel (Pack-/Poststation) - Aufbau'
				&& lead.Freigabe_STOG__c == 'Ja';
	}
	
	private Boolean isChanged ( Lead lead, String field ) {
		if ( Trigger.isInsert ) {
			return true;
		}
		return lead.get( field ) != oldLeadMap.get( lead.Id ).get( field );
	}
	
	private Boolean isVerwendeButtonDatenaenderung ( Lead lead ) {
		return lead.STO_disponiert__c != null
				&& !FeatureManagement.checkPermission( 'DisableValidationRules' )
				&& InterfaceUser.getInstance().getId() != UserInfo.getUserId()
				&& !disableValidations
				&&
				(
						isChanged( lead, 'Upload_LTE_Messung_MBit__c' )
								||
								isChanged( lead, 'Download_LTE_Messung_MBit__c' )
								||
								isChanged( lead, 'ADM_Typ__c' )
								||
								isChanged( lead, 'ADM_Hersteller__c' )
								||
								isChanged( lead, 'Fundament__c' )
								||
								isChanged( lead, 'Aufbauform__c' )
								||
								isChanged( lead, 'Fachmodule__c' )
								||
								isChanged( lead, 'Unterbrechung__c' )
								||
								isChanged( lead, 'Steuermodule__c' )
								||
								isChanged( lead, 'Eckmodule__c' )
								||
								//Wenn über den Button "Datenänderung" in das Feld eine URL eingetragen wird,
								//dann läuft die Validierung auf Fehler und gibt immer isChanged = TRUE zurück
								//Liegt an der Umwandlung von String nach URL.
								//Fehler tritt nicht auf, wenn Feld über reguläre Oberfläche befüllt wird
								isChanged( lead, 'Anmerkungen_zum_Bau__c' )
				);
	}
	
	private Boolean isVertragsfelderChanged ( Lead lead ) {
		return lead.STO_disponiert__c != null
				&& !FeatureManagement.checkPermission( 'DisableValidationRules' )
				&& !FeatureManagement.checkPermission( 'TeamVertragsmanagement' )
				&& InterfaceUser.getInstance().getId() != UserInfo.getUserId()
				&& !disableValidations
				&&
				(
						isChanged( lead, 'Beauftragung_CSG__c' )
								||
								isChanged( lead, 'Screening__c' )
								||
								isChanged( lead, 'Vertrag_versandt__c' )
								||
								isChanged( lead, 'VertragErstelltAm__c' )
								||
								isChanged( lead, 'VertragVonVLUnterschriebenAm__c' )
								||
								isChanged( lead, 'Zustimmung_Ablehnung_zum_Vertrag_Datum__c' )
								||
								isChanged( lead, 'Vertrag_unterschrieben__c' )
								||
								isChanged( lead, 'Bemerkungen_Vertragsverhandlung__c' )
				);
	}
	
	private Boolean isVerwendeButtonStorno ( Lead lead ) {
		return !disableValidations
				&& !FeatureManagement.checkPermission( 'DisableValidationRules' )
				&& (
				( lead.STO_disponiert__c == null
						&& isChanged( lead.Id, 'STO_disponiert__c' ) )
						|| ( lead.Aufbaufaehig_ab_Datum__c == null
						&& isChanged( lead.Id, 'Aufbaufaehig_ab_Datum__c' ) )
		);
	}
	
	private Boolean isDisponiertChanged ( Lead lead ) {
		return !disableValidations
				&& !FeatureManagement.checkPermission( 'DisableValidationRules' )
				&& lead.STO_disponiert__c != null
				&& isChanged( lead.Id, 'STO_disponiert__c' )
				&& oldLeadMap.get( lead.Id ).STO_disponiert__c != null;
	}
	
	private Boolean isBemerkungenZurDispoChanged ( Lead lead ) {
		return lead.STO_disponiert__c != null
				&& !FeatureManagement.checkPermission( 'DisableValidationRules' )
				&& InterfaceUser.getInstance().getId() != UserInfo.getUserId()
				&& !disableValidations
				&& CurrentUser.getInstance().getProfile().Name != 'myPM Packstation Bauen + Aussenstelle'
				&& isChanged( lead, 'Bemerkungen_zur_Dispo__c' );
	}
	
	private Boolean isRelevantStandortArtAktion ( Lead lead ) {
		return Trigger.isInsert
				|| isChanged( lead, 'Bestandsmassnahme__c' )
				|| isChanged( lead, 'Entlastung_durch_mod_Erweiterung__c' )
				|| isChanged( lead, 'Entlastung_durch_Austausch__c' )
				|| isChanged( lead, 'Entlastung_durch_2_Automat_selber_STO__c' )
				|| isChanged( lead, 'Entlastung_durch_2_Automat_anderer_STO__c' );
	}
	
	private Boolean isNewPackstation ( Lead lead ) {
		return lead.Bestandsmassnahme__c == null
				&& lead.Entlastung_durch_mod_Erweiterung__c == null
				&& lead.Entlastung_durch_Austausch__c == null
				&& lead.Entlastung_durch_2_Automat_selber_STO__c == null
				&& lead.Entlastung_durch_2_Automat_anderer_STO__c == null;
	}
	
	private void setStandortArtAktion ( Lead lead ) {
		if ( lead.RecordTypeId != PACKSTATION_RT ) {
			return;
		}
		if ( isRelevantStandortArtAktion( lead ) ) {
			if ( isNewPackstation( lead )
					|| isEntlastungAufbauDurchEntlastungZweiterAutomatSelberStandort( lead ) ) {
				lead.STO_Art__c = 'Neu';
				lead.Aktion_am_STO__c = 'Aufbau';
			}
			else if ( isBestandAbbau( lead )
					|| isKuendigungAbbau( lead ) ) {
				lead.STO_Art__c = 'Bestand';
				lead.Aktion_am_STO__c = 'Abbau';
			}
			else if ( isEntlastungAbbauAustausch( lead )
					|| isFormatwechselAbbau( lead )
					|| isAutomatentauschAbbau( lead ) ) {
				lead.STO_Art__c = 'Bestand';
				lead.Aktion_am_STO__c = 'Abbau (Austausch)';
			}
			else if ( isFormatwechselAufbau( lead )
					|| isAutomatentauschAufbau( lead )
					|| isEntlastungAufbauDurchAustausch( lead ) ) {
				lead.STO_Art__c = 'Bestand';
				lead.Aktion_am_STO__c = 'Aufbau (Austausch)';
			}
			else if ( isEntlastungAufbauDurchModulareErweiterung( lead ) ) {
				lead.STO_Art__c = 'Bestand';
				lead.Aktion_am_STO__c = 'Erweiterung';
			}
			else if ( isEntlastungAufbauDurchEntlastungZweiterAutomatAndererStandort( lead ) ) {
				lead.STO_Art__c = null;
				lead.Aktion_am_STO__c = null;
			}
			else {
				//Sonarqube --> do nothing
			}
		}
	}
	
	private Boolean isFormatwechselAufbau ( Lead lead ) {
		return lead.Bestandsmassnahme__c == 'Formatwechsel (Pack-/Poststation) - Aufbau'
				&& lead.Entlastung_durch_mod_Erweiterung__c == null
				&& lead.Entlastung_durch_Austausch__c == null
				&& lead.Entlastung_durch_2_Automat_selber_STO__c == null
				&& lead.Entlastung_durch_2_Automat_anderer_STO__c == null;
	}
	
	private Boolean isKuendigungAbbau ( Lead lead ) {
		return lead.Bestandsmassnahme__c == 'Kündigung - Abbau'
				&& lead.Entlastung_durch_mod_Erweiterung__c == null
				&& lead.Entlastung_durch_Austausch__c == null
				&& lead.Entlastung_durch_2_Automat_selber_STO__c == null
				&& lead.Entlastung_durch_2_Automat_anderer_STO__c == null;
	}
	
	private Boolean isBestandAbbau ( Lead lead ) {
		return lead.Bestandsmassnahme__c == 'Abbau'
				&& lead.Entlastung_durch_mod_Erweiterung__c == null
				&& lead.Entlastung_durch_Austausch__c == null
				&& lead.Entlastung_durch_2_Automat_selber_STO__c == null
				&& lead.Entlastung_durch_2_Automat_anderer_STO__c == null;
	}
	
	private Boolean isAutomatentauschAbbau ( Lead lead ) {
		return lead.Bestandsmassnahme__c == 'Automatentausch - Abbau'
				&& lead.Entlastung_durch_mod_Erweiterung__c == null
				&& lead.Entlastung_durch_Austausch__c == null
				&& lead.Entlastung_durch_2_Automat_selber_STO__c == null
				&& lead.Entlastung_durch_2_Automat_anderer_STO__c == null;
	}
	
	private Boolean isAutomatentauschAufbau ( Lead lead ) {
		return lead.Bestandsmassnahme__c == 'Automatentausch - Aufbau'
				&& lead.Entlastung_durch_mod_Erweiterung__c == null
				&& lead.Entlastung_durch_Austausch__c == null
				&& lead.Entlastung_durch_2_Automat_selber_STO__c == null
				&& lead.Entlastung_durch_2_Automat_anderer_STO__c == null;
	}
	
	private Boolean isFormatwechselAbbau ( Lead lead ) {
		return lead.Bestandsmassnahme__c == 'Formatwechsel (Pack-/Poststation) - Abbau'
				&& lead.Entlastung_durch_mod_Erweiterung__c == null
				&& lead.Entlastung_durch_Austausch__c == null
				&& lead.Entlastung_durch_2_Automat_selber_STO__c == null
				&& lead.Entlastung_durch_2_Automat_anderer_STO__c == null;
	}
	
	private Boolean isEntlastungAbbauAustausch ( Lead lead ) {
		return lead.Bestandsmassnahme__c == 'Entlastung - Abbau'
				&& lead.Entlastung_durch_mod_Erweiterung__c == null
				&& lead.Entlastung_durch_Austausch__c == null
				&& lead.Entlastung_durch_2_Automat_selber_STO__c == null
				&& lead.Entlastung_durch_2_Automat_anderer_STO__c == null;
	}
	
	private Boolean isEntlastungAufbauDurchEntlastungZweiterAutomatAndererStandort ( Lead lead ) {
		return lead.Bestandsmassnahme__c == 'Entlastung - Aufbau'
				&& lead.Entlastung_durch_mod_Erweiterung__c == 'Nein'
				&& lead.Entlastung_durch_Austausch__c == 'Nein'
				&& lead.Entlastung_durch_2_Automat_selber_STO__c == 'Nein'
				&& lead.Entlastung_durch_2_Automat_anderer_STO__c == 'Ja';
	}
	
	private Boolean isEntlastungAufbauDurchEntlastungZweiterAutomatSelberStandort ( Lead lead ) {
		return lead.Bestandsmassnahme__c == 'Entlastung - Aufbau'
				&& lead.Entlastung_durch_mod_Erweiterung__c == 'Nein'
				&& lead.Entlastung_durch_Austausch__c == 'Nein'
				&& lead.Entlastung_durch_2_Automat_selber_STO__c == 'Ja'
				&& lead.Entlastung_durch_2_Automat_anderer_STO__c == null;
	}
	
	private Boolean isEntlastungAufbauDurchAustausch ( Lead lead ) {
		return lead.Bestandsmassnahme__c == 'Entlastung - Aufbau'
				&& lead.Entlastung_durch_mod_Erweiterung__c == 'Nein'
				&& lead.Entlastung_durch_Austausch__c == 'Ja'
				&& lead.Entlastung_durch_2_Automat_selber_STO__c == null
				&& lead.Entlastung_durch_2_Automat_anderer_STO__c == null;
	}
	
	private Boolean isEntlastungAufbauDurchModulareErweiterung ( Lead lead ) {
		return lead.Bestandsmassnahme__c == 'Entlastung - Aufbau'
				&& lead.Entlastung_durch_mod_Erweiterung__c == 'Ja'
				&& lead.Entlastung_durch_Austausch__c == null
				&& lead.Entlastung_durch_2_Automat_selber_STO__c == null
				&& lead.Entlastung_durch_2_Automat_anderer_STO__c == null;
	}
	
	private void addBeauftragungTvm ( Lead lead ) {
		if ( isBeauftragungTvm( lead ) ) {
			addBeauftragungTvmTask( lead );
		}
	}
	
	private void addBeauftragungTvmTask ( Lead lead ) {
		akquiseauftraege.add(
				new Task(
						Aufgabenart__c = 'Beauftragung TVM',
						Auftraggeber__c = 'Vertriebsleiter',
						Auftragnehmer__c = 'Inhaber des Leads',
						ActivityDate = Date.today(),
						Erledigung_bis_zum__c = Date.today().addDays( 7 ),
						Status = 'Nicht begonnen',
						Priority = 'Mittel',
						Typc__c = 'Intern',
						Filialnetzaenderung__c = lead.Filialnetzaenderung__c,
						RecordTypeId = AKQUISEAUFTRAG_PACKSTATION_RT,
						WhoId = lead.Id
				)
		);
	}
	
	private Boolean isBeauftragungTvm ( Lead lead ) {
		return lead.Freigabe_STOG__c == 'Ja'
				&& (
				( lead.Ergebnis_Bauordnungsrechtliche_Pruefung__c == 'Baugenehmigungsfrei, Amt'
						|| lead.Ergebnis_Bauordnungsrechtliche_Pruefung__c == 'Baugenehmigungsfrei, Netzmanager'
						|| lead.Ergebnis_Bauordnungsrechtliche_Pruefung__c == 'Genehmigt'
				)
						|| lead.Ergebnis_weit_Bauordnungsrechtl_Pruefung__c == 'Genehmigt' )
				&& lead.Akquisemodus__c != 'Standortaufnahme vor Ort; Danach Übergabe an rVU'
				&& ( isChanged( lead, 'Freigabe_STOG__c' )
				|| isChanged( lead, 'Ergebnis_Bauordnungsrechtliche_Pruefung__c' )
				|| isChanged( lead, 'Ergebnis_weit_Bauordnungsrechtl_Pruefung__c' ) );
	}
	
	private void setStatusForInKlaerungWeiden ( Lead lead ) {
		if ( isChanged( lead.Id, 'Bewertung_Zentrale__c' )
				&& lead.Bewertung_Zentrale__c == 'in Klärung Weiden' ) {
			lead.Aktivitaetsstatus__c = 'inaktiv durch Zentrale';
		}
	}
	
	private void setWeidenGeeignetValues ( Lead lead ) {
		if ( isSetWeidenGeeignetValues( lead )
				&& !isSetWeidenGeeignetValues( oldLeadMap.get( lead.Id ) ) ) {
			lead.Bewertung_Zentrale__c = 'Geeignet';
			lead.Bewertung_Zentrale_vom__c = Date.today();
			lead.Aktivitaetsstatus__c = 'aktiv durch Zentrale';
		}
	}
	
	private Boolean isSetWeidenGeeignetValues ( Lead lead ) {
		return lead.Bewertung_Zentrale__c == 'in Klärung Weiden'
				&& lead.Bewertung_Weiden__c == 'Geeignet';
	}
	
	private void deactivateIfBewertungVmEqualsAbsageDurchStog ( Lead lead ) {
		if ( lead.Bewertung_VM__c == 'Absage durch STOG - Kein Interesse'
				&& isChanged( lead.Id, 'Bewertung_VM__c' ) ) {
			lead.Aktivitaetsstatus__c = 'inaktiv';
		}
	}
	
	private void deactivateIfBewertungWeidenEqualsNichtGeeignetKeinInteresse ( Lead lead ) {
		if ( lead.Bewertung_Weiden__c == 'Nicht geeignet - Kein Interesse'
				&& isChanged( lead.Id, 'Bewertung_Weiden__c' ) ) {
			lead.Aktivitaetsstatus__c = 'inaktiv';
		}
	}
	
	private void addPackstationAbbauDatumRequests(Lead lead){
		if (lead.Abbau_geplant_Datum__c != null
				&& oldLeadMap.get(lead.Id).Abbau_geplant_Datum__c == null ) {
			addPackstationRequest(lead, 'Abbau_geplant');
		}
		else if(lead.Abbau_geplant_Datum__c == null && oldLeadMap.get(lead.Id).Abbau_geplant_Datum__c != null){
			addPackstationRequest(lead, 'Abbau_storno');
		}
		else if(lead.Abbau_geplant_Datum__c != null
				&& isChanged(lead.Id, 'Abbau_geplant_Datum__c')){
			addPackstationRequest(lead, 'Abbau_geandert');
		}
	}
}