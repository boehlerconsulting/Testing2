/**
 *@author       Mats Böhler
 *@created      05.02.2021
 *
 *
 *@description  EinrichtungsprozessCtrl
 *
 *
 *@changelog    05.02.2021 Mats Böhler  - Created
 *              
 * 
 */
public with sharing class EinrichtungsprozessCtrl extends EinrichtungsprozessBaseCtrl {
	
	private Id einrichtungsprozessId;
	private Boolean isEinrichtungskoordinator = FeatureManagement.checkPermission( 'Einrichtungskoordinator' );
	private List<Filialausstattung__c> filialausstattungsUpdate = new List<Filialausstattung__c>();
	private List<Filialausstattung__c> filialausstattungsInsert = new List<Filialausstattung__c>();
	private Map<Id, Filialausstattung__c> filialausstattungByProductIds = new Map<Id, Filialausstattung__c>();
	private String documentUrl;
	
	@AuraEnabled
	public static String init ( Id recordId, Boolean isErsatzZusatz, Boolean isAbbau, Boolean isErsatz ) {
		EinrichtungsprozessCtrl instance = new EinrichtungsprozessCtrl();
		
		try {
			instance.recordId = recordId;
			instance.isErsatzZusatz = isErsatzZusatz;
			instance.isErsatz = isErsatz;
			instance.isAbbau = isAbbau;
			instance.loadMetadata();
		}
		catch ( Exception e ) {
			
			throw new AuraHandledException( e.getMessage() );
		}
		return JSON.serialize( instance );
	}
	
	@AuraEnabled
	public static void saveAbbauProcess ( Id recordId, String abbauProcess ) {
		
		try {
			update new Einrichtungsprozess__c(
					Id = recordId,
					ProzessAbbau__c = abbauProcess
			);
		}
		catch ( Exception e ) {
			
			throw new AuraHandledException( e.getMessage() );
		}
	}
	
	@AuraEnabled
	public static String triggerBestellung ( Id accountId, Id einrichtungsprozessId ) {
		EinrichtungsprozessCtrl instance = new EinrichtungsprozessCtrl();
		Savepoint savepoint = Database.setSavepoint();
		try {
			instance.recordId = accountId;
			instance.einrichtungsprozessId = einrichtungsprozessId;
			instance.createBestellungTask(
					'Filialausstattung bestellen',
					'TaskIdFilialausstattungBestellen__c',
					null
			);
			instance.saveProcessStep( 'NeubestellungAusgeloest__c', true );
		}
		catch ( Exception e ) {
			Database.rollback( savepoint );
			throw new AuraHandledException( e.getMessage() );
		}
		return JSON.serialize( instance );
	}
	
	@AuraEnabled
	public static String triggerBestellungErsatz ( Id accountId, Id einrichtungsprozessId ) {
		EinrichtungsprozessCtrl instance = new EinrichtungsprozessCtrl();
		Savepoint savepoint = Database.setSavepoint();
		try {
			instance.recordId = accountId;
			instance.einrichtungsprozessId = einrichtungsprozessId;
			instance.createBestellungTask(
					'Filialausstattung bestellen – Ersatz/Zusatz',
					'TaskIdFilialausstattungBestellenErsatz__c',
					'Bitte bestellen bzw. beauftragen Sie die Filialausstattung gemäß Bestellung im ' +
							'Registerblatt „Ersatz“ und beauftragen Sie (wenn erforderlich) den Abbau.'
			);
			instance.saveProcessStep( 'ErsatzAusgeloest__c', true );
		}
		catch ( Exception e ) {
			Database.rollback( savepoint );
			throw new AuraHandledException( e.getMessage() );
		}
		return JSON.serialize( instance );
	}
	
	@AuraEnabled
	public static String triggerBestellungZusatz ( Id accountId, Id einrichtungsprozessId ) {
		EinrichtungsprozessCtrl instance = new EinrichtungsprozessCtrl();
		Savepoint savepoint = Database.setSavepoint();
		try {
			instance.recordId = accountId;
			instance.einrichtungsprozessId = einrichtungsprozessId;
			instance.createBestellungTask(
					'Filialausstattung bestellen – Ersatz/Zusatz',
					'TaskIdFilialausstattungBestellenZusatz__c',
					'Bitte bestellen bzw. beauftragen Sie die Filialausstattung gemäß Bestellung im ' +
							'Registerblatt „Zusatz“ und beauftragen Sie (wenn erforderlich) den Abbau.'
			);
			instance.saveProcessStep( 'ZusatzAusgeloest__c', true );
		}
		catch ( Exception e ) {
			Database.rollback( savepoint );
			throw new AuraHandledException( e.getMessage() );
		}
		return JSON.serialize( instance );
	}
	
	@AuraEnabled
	public static String triggerNachbesserung ( Id accountId, Id einrichtungsprozessId, String beschreibung ) {
		EinrichtungsprozessCtrl instance = new EinrichtungsprozessCtrl();
		Savepoint savepoint = Database.setSavepoint();
		try {
			instance.recordId = accountId;
			instance.einrichtungsprozessId = einrichtungsprozessId;
			instance.resetScreenIndex();
			instance.saveProcessStep( 'NeubestellungAusgeloest__c', false );
			instance.createNachbesserungTask(
					'Nachbesserung Filialausstattung',
					beschreibung
			);
			instance.closeExistingEinrichtungskoordinatorTask( 'TaskIdFilialausstattungBestellen__c' );
		}
		catch ( Exception e ) {
			Database.rollback( savepoint );
			throw new AuraHandledException( e.getMessage() );
		}
		return JSON.serialize( instance );
	}
	
	@AuraEnabled
	public static String triggerNachbesserungErsatz ( Id accountId, Id einrichtungsprozessId, String beschreibung ) {
		EinrichtungsprozessCtrl instance = new EinrichtungsprozessCtrl();
		Savepoint savepoint = Database.setSavepoint();
		try {
			instance.recordId = accountId;
			instance.einrichtungsprozessId = einrichtungsprozessId;
			instance.resetScreenIndex();
			instance.saveProcessStep( 'ErsatzAusgeloest__c', false );
			instance.createNachbesserungTask(
					'Nachbesserung Filialausstattung',
					beschreibung
			);
			instance.closeExistingEinrichtungskoordinatorTask( 'TaskIdFilialausstattungBestellenErsatz__c' );
		}
		catch ( Exception e ) {
			Database.rollback( savepoint );
			throw new AuraHandledException( e.getMessage() );
		}
		
		return JSON.serialize( instance );
	}
	
	@AuraEnabled
	public static String triggerNachbesserungZusatz ( Id accountId, Id einrichtungsprozessId, String beschreibung ) {
		EinrichtungsprozessCtrl instance = new EinrichtungsprozessCtrl();
		Savepoint savepoint = Database.setSavepoint();
		try {
			instance.recordId = accountId;
			instance.einrichtungsprozessId = einrichtungsprozessId;
			instance.resetScreenIndex();
			instance.saveProcessStep( 'ZusatzAusgeloest__c', false );
			instance.createNachbesserungTask(
					'Nachbesserung Filialausstattung',
					beschreibung
			);
			instance.closeExistingEinrichtungskoordinatorTask( 'TaskIdFilialausstattungBestellenZusatz__c' );
		}
		catch ( Exception e ) {
			Database.rollback( savepoint );
			throw new AuraHandledException( e.getMessage() );
		}
		
		return JSON.serialize( instance );
	}
	
	@AuraEnabled
	public static String triggerNachbesserungAbbau ( Id accountId, Id einrichtungsprozessId, String beschreibung ) {
		EinrichtungsprozessCtrl instance = new EinrichtungsprozessCtrl();
		Savepoint savepoint = Database.setSavepoint();
		try {
			instance.recordId = accountId;
			instance.einrichtungsprozessId = einrichtungsprozessId;
			instance.resetScreenIndex();
			instance.saveProcessStep( 'AbbauAusgeloest__c', false );
			instance.createNachbesserungTask(
					'Nachbesserung Filialausstattung',
					beschreibung
			);
			instance.closeExistingEinrichtungskoordinatorTask( 'TaskIdBeraeumungBeauftragen__c' );
		}
		catch ( Exception e ) {
			Database.rollback( savepoint );
			throw new AuraHandledException( e.getMessage() );
		}
		
		return JSON.serialize( instance );
	}
	
	@AuraEnabled
	public static void saveProcessState ( String processId, Integer indexAktivesFenster ) {
		EinrichtungsprozessCtrl instance = new EinrichtungsprozessCtrl();
		try {
			instance.einrichtungsprozessId = processId;
			instance.setScreenIndexTo( indexAktivesFenster );
		}
		catch ( Exception e ) {
			throw new AuraHandledException( e.getMessage() );
		}
	}
	
	@AuraEnabled
	public static String copyFieldsFromAndienung ( String processId ) {
		EinrichtungsprozessCtrl instance = new EinrichtungsprozessCtrl();
		try {
			instance.einrichtungsprozessId = processId;
			return JSON.serialize(
					instance.copyFields()
			);
		}
		catch ( Exception e ) {
			throw new AuraHandledException( e.getMessage() );
		}
	}
	
	@AuraEnabled(Cacheable=true)
	public static String getDocumentUrl ( String recordId, String variant, String process ) {
		EinrichtungsprozessCtrl instance = new EinrichtungsprozessCtrl();
		try {
			instance.einrichtungsprozessId = recordId;
			switch on process {
				when 'Teilabbau' {
					instance.generateAuftragRueckbauUrl( process );
				}
				when 'Filialschließung' {
					instance.generateAuftragRueckbauUrl( process );
				}
				when else {
					instance.generateBestellblattUrl( variant, process );
				}
			}
		}
		catch ( Exception e ) {
			
			throw new AuraHandledException( e.getMessage() );
		}
		return instance.documentUrl;
	}
	
	@AuraEnabled(Cacheable=true)
	public static String getPreviewUrl ( String recordId, String process ) {
		EinrichtungsprozessCtrl instance = new EinrichtungsprozessCtrl();
		try {
			instance.einrichtungsprozessId = recordId;
			instance.generateBestellvorschauUrl( process );
		}
		catch ( Exception e ) {
			
			throw new AuraHandledException( e.getMessage() );
		}
		return instance.documentUrl;
	}
	
	@AuraEnabled
	public static String saveDocument ( String accountId, String recordId, String variants, String process ) {
		Savepoint savepoint = Database.setSavepoint();
		EinrichtungsprozessCtrl instance = new EinrichtungsprozessCtrl();
		try {
			instance.recordId = accountId;
			instance.einrichtungsprozessId = recordId;
			switch on process {
				when 'Teilabbau' {
					instance.processAbbau( process );
					instance.saveProcessStep( 'AbbauAusgeloest__c', false );
				}
				when 'Filialschließung' {
					instance.processAbbau( process );
					instance.saveProcessStep( 'AbbauAusgeloest__c', false );
					instance.saveProcessStep( 'SchliessungAbgeschlossen__c', true );
				}
				when 'Ersatzbestellung' {
					instance.generateBestelldokumente( variants, process );
					instance.processErsatzbestellung( process );
					instance.saveProcessStep( 'ErsatzAusgeloest__c', false );
				}
				when 'Zusätzliche Bestellung' {
					instance.generateBestelldokumente( variants, process );
					instance.processZusatzbestellung( process );
					instance.saveProcessStep( 'ZusatzAusgeloest__c', false );
				}
				when else {
					instance.generateBestelldokumente( variants, process );
					instance.saveProcessStep( 'NeubestellungAusgeloest__c', false );
					instance.saveProcessStep( 'NeubestellungAbgeschlossen__c', true );
				}
			}
			return process;
		}
		catch ( Exception e ) {
			Database.rollback( savepoint );
			throw new AuraHandledException( e.getMessage() );
		}
	}
	
	@AuraEnabled
	public static String saveDocumentVorschau ( String accountId, String recordId, String process ) {
		Savepoint savepoint = Database.setSavepoint();
		EinrichtungsprozessCtrl instance = new EinrichtungsprozessCtrl();
		try {
			instance.recordId = accountId;
			instance.einrichtungsprozessId = recordId;
			instance.processVorschauVM( process );
			return process;
		}
		catch ( Exception e ) {
			Database.rollback( savepoint );
			throw new AuraHandledException( e.getMessage() );
		}
	}
	
	private void processVorschauVM ( String type ) {
		PageReference pageReference = Page.BestellvorschauVM;
		pageReference.getParameters().put( 'id', einrichtungsprozessId );
		pageReference.getParameters().put( 'process', type );
		BestellvorschauVMCtrl ctrl = new BestellvorschauVMCtrl( pageReference );
		
		if ( type == 'Teilabbau' || type == 'Filialschließung' ) {
			if ( ctrl.hasMissingValues ) {
				throw new VisualforceException( 'Es kann kein Dokument generiert werden, ' +
						'weil "Menge Wiedereinsatzfähig" nicht gepflegt wurde.' );
			}
			createBestellungTask(
					'Beräumung beauftragen',
					'TaskIdBeraeumungBeauftragen__c',
					null
			);
			saveProcessStep( 'AbbauAusgeloest__c', true );
		}
		if ( ctrl.categories.size() < 1 ) {
			throw new VisualforceException( 'Es kann kein Dokument generiert werden, ' +
					'weil keine relevante Ausstattung gefunden wurde.' );
		}
		else {
			
			ctrl.saveAsFile( new List<Id> {
					ctrl.getRecord().Filiale__c
			} );
		}
	}
	
	private void generateBestelldokumente ( String variants, String processType ) {
		for ( String variant : variants.split( ',' ) ) {
			PageReference pageReference = Page.BestellblattLieferant;
			pageReference.getParameters().put( 'id', einrichtungsprozessId );
			pageReference.getParameters().put( 'variant', variant );
			pageReference.getParameters().put( 'process', processType );
			BestellblattLieferantCtrl ctrl = new BestellblattLieferantCtrl( pageReference );
			if ( ctrl.categories.size() > 0 ) {
				
				ctrl.saveAsFile( new List<Id> {
						ctrl.getRecord().Filiale__c
				} );
			}
		}
	}
	
	private void generateAuftragRueckbauUrl ( String processType ) {
		
		PageReference pageReference = Page.AuftragRueckbau;
		pageReference.getParameters().put( 'id', einrichtungsprozessId );
		pageReference.getParameters().put( 'process', processType );
		AuftragRueckbauCtrl ctrl = new AuftragRueckbauCtrl( pageReference );
		
		if ( ctrl.categories.size() < 1 ) {
			throw new VisualforceException( 'Es kann keine Vorschau generiert werden, ' +
					'weil keine relevante Ausstattung gefunden wurde.' );
		}
		if ( ctrl.hasMissingValues ) {
			throw new VisualforceException( 'Es kann keine Vorschau generiert werden, ' +
					'weil "Menge Wiedereinsatzfähig" nicht gepflegt wurde.' );
		}
		documentUrl = pageReference.getUrl();
	}
	
	private void generateBestellblattUrl ( String variant, String processType ) {
		PageReference pageReference = Page.BestellblattLieferant;
		pageReference.getParameters().put( 'id', einrichtungsprozessId );
		pageReference.getParameters().put( 'variant', variant );
		pageReference.getParameters().put( 'process', processType );
		BestellblattLieferantCtrl ctrl = new BestellblattLieferantCtrl( pageReference );
		if ( ctrl.categories.size() < 1 ) {
			throw new VisualforceException( 'Für "' + variant + '" kann keine Vorschau generiert werden, ' +
					'weil keine relevante Ausstattung gefunden wurde.' );
		}
		documentUrl = pageReference.getUrl();
	}
	
	private void generateBestellvorschauUrl ( String processType ) {
		PageReference pageReference = Page.BestellvorschauVM;
		pageReference.getParameters().put( 'id', einrichtungsprozessId );
		pageReference.getParameters().put( 'process', processType );
		BestellvorschauVMCtrl ctrl = new BestellvorschauVMCtrl( pageReference );
		if ( ctrl.categories.size() < 1 ) {
			throw new VisualforceException( 'Es kann keine Vorschau generiert werden, ' +
					'weil keine relevante Ausstattung gefunden wurde.' );
		}
		documentUrl = pageReference.getUrl();
	}
	
	private Einrichtungsprozess__c copyFields () {
		process = [
				SELECT
						Id,
						Filiale_im_Einkaufszentrum__c,
						Etage_der_Postfiliale_ggf_Lage__c,
						Fussgaengerzone__c,
						EinschraenkungenFussgaengerzone__c,
						Halteverbote__c,
						EinschraenkungenHalteverbote__c,
						Markttage__c,
						EinschraenkungenMarkttage__c,
						RampeVorhanden__c,
						HubladebuehneErforderlich__c,
						WeitereBesonderheiten__c,
						GenehmigungenErforderlich__c,
						ErforderlicheGenehmigungen__c,
						StufenVorhanden__c,
						AnzahlStufen__c,
						AnlieferungUeberAufzug__c,
						AngabeMasseTragkraftUndZugaenglichkeit__c
				FROM Einrichtungsprozess__c
				WHERE Id = :einrichtungsprozessId
				LIMIT 1
		];
		process.BA_Filiale_im_Einkaufszentrum__c = process.Filiale_im_Einkaufszentrum__c;
		process.BA_Etage_der_Postfiliale_ggf_Lage__c = process.Etage_der_Postfiliale_ggf_Lage__c;
		process.BA_Fu_g_ngerzone__c = process.Fussgaengerzone__c;
		process.BA_Einschr_nkungen_Fu_g_ngerzone__c = process.EinschraenkungenFussgaengerzone__c;
		process.BA_Halteverbote__c = process.Halteverbote__c;
		process.BA_Einschr_nkungen_Halteverbote__c = process.EinschraenkungenHalteverbote__c;
		process.BA_Markttage__c = process.Markttage__c;
		process.BA_Einschr_nkungen_Markttage__c = process.EinschraenkungenMarkttage__c;
		process.BA_Rampe_vorhanden__c = process.RampeVorhanden__c;
		process.BA_Hubladeb_hne_erforderlich__c = process.HubladebuehneErforderlich__c;
		process.BA_WeitereBesonderheiten__c = process.WeitereBesonderheiten__c;
		process.BA_Genehmigungen_erforderlich__c = process.GenehmigungenErforderlich__c;
		process.BA_Erforderliche_Genehmigungen__c = process.ErforderlicheGenehmigungen__c;
		process.BA_Stufen_vorhanden__c = process.StufenVorhanden__c;
		process.BA_AnzahlStufen__c = process.AnzahlStufen__c;
		process.BA_Anlieferung_ber_Aufzug__c = process.AnlieferungUeberAufzug__c;
		process.BA_Angabe_Ma_e_Tragkraft_und_Zug_nglich__c = process.AngabeMasseTragkraftUndZugaenglichkeit__c;
		update process;
		return process;
	}
	
	private void resetScreenIndex () {
		update new Einrichtungsprozess__c(
				Id = einrichtungsprozessId,
				IndexAktivesFenster__c = 0
		);
	}
	
	private void setScreenIndexTo ( Integer index ) {
		update new Einrichtungsprozess__c(
				Id = einrichtungsprozessId,
				IndexAktivesFenster__c = index
		);
	}
	
	private void closeExistingEinrichtungskoordinatorTask ( String taskIdField ) {
		SObject sobj = [
				SELECT
						Id,
						TaskIdFilialausstattungBestellen__c,
						TaskIdFilialausstattungBestellenErsatz__c,
						TaskIdFilialausstattungBestellenZusatz__c,
						TaskIdBeraeumungBeauftragen__c
				FROM Einrichtungsprozess__c
				WHERE Id = :einrichtungsprozessId
				LIMIT 1
		];
		Id taskToCloseId = ( Id ) sobj.get( taskIdField );
		if ( taskToCloseId == null ) {
			return;
		}
		update new Task(
				Id = taskToCloseId,
				Erledigungsvermerk__c = 'Nachbesserung angefordert am ' + Date.today().format(),
				Erledigt_am__c = Date.today(),
				Status = 'Erledigt',
				Typc__c = 'Intern'
		);
	}
	
	private Task createNachbesserungTask ( String title, String beschreibung ) {
		Task task = new Task(
				Subject = title,
				Aufgabenart__c = title,
				RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
						.get( 'A_Aufgaben_automatische_Anlage' ).getRecordTypeId(),
				Auftraggeber__c = '3920/30 Außenstelle',
				Auftragnehmer__c = 'Vertriebsmanager',
				WhatId = recordId,
				ActivityDate = Date.today(),
				Erledigung_bis_zum__c = Date.today().addDays( 2 ),
				Description = beschreibung,
				Kommentar_Kopie__c = beschreibung,
				Type = 'Intern',
				Typc__c = 'Intern'
		);
		insert task;
		return task;
	}
	
	private void createBestellungTask ( String title, String taskField, String description ) {
		Task task = new Task(
				Subject = title,
				Aufgabenart__c = title,
				RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
						.get( 'A_Aufgaben_automatische_Anlage' ).getRecordTypeId(),
				Auftraggeber__c = 'Vertriebsmanager',
				Auftragnehmer__c = '3920/30 Aussenstelle',
				WhatId = recordId,
				Priority = 'Hoch',
				ActivityDate = Date.today(),
				Erledigung_bis_zum__c = Date.today().addDays( 7 ),
				Description = description
		);
		insert task;
		
		SObject sobj = new Einrichtungsprozess__c(
				Id = einrichtungsprozessId,
				IndexAktivesFenster__c = 0
		);
		sobj.put( taskField, task.Id );
		update sobj;
	}
	
	private void saveProcessStep ( String processField, Boolean value ) {
		SObject sobj = new Account(
				Id = recordId
		);
		sobj.put( processField, value );
		update sobj;
	}
	
	private void processAbbau ( String type ) {
		
		PageReference pageReference = Page.AuftragRueckbau;
		pageReference.getParameters().put( 'id', einrichtungsprozessId );
		pageReference.getParameters().put( 'process', type );
		AuftragRueckbauCtrl ctrl = new AuftragRueckbauCtrl( pageReference );
		
		if ( ctrl.categories.size() < 1 ) {
			throw new VisualforceException( 'Es kann kein Dokument generiert werden, ' +
					'weil keine relevante Ausstattung gefunden wurde.' );
		}
		if ( ctrl.hasMissingValues ) {
			throw new VisualforceException( 'Es kann kein Dokument generiert werden, ' +
					'weil "Menge Wiedereinsatzfähig" nicht gepflegt wurde.' );
		}
		if ( ctrl.categories.size() > 0 ) {
			ctrl.saveAsFile( new List<Id> {
					ctrl.getRecord().Filiale__c
			} );
			dismantleProducts();
		}
	}
	
	private void dismantleProducts () {
		List<Filialausstattung__c> filialausstattungUpdate = new List<Filialausstattung__c>();
		List<Filialausstattung__c> filialausstattungDelete = new List<Filialausstattung__c>();
		for ( Filialausstattung__c filialausstattung : [
				SELECT
						Id,
						Menge__c,
						Menge_Abbau__c,
						Menge_Wiedereinsatzfaehig__c,
						Vorgemerkt__c
				FROM Filialausstattung__c
				WHERE Filiale__c = :recordId
				AND Vorgemerkt__c LIKE 'in Abbau%'
		] ) {
			
			filialausstattung.Menge__c = returnZeroIfNull( filialausstattung.Menge__c )
					- returnZeroIfNull( filialausstattung.Menge_Abbau__c );
			filialausstattung.Vorgemerkt__c = null;
			if ( filialausstattung.Menge__c == 0 ) {
				filialausstattungDelete.add( filialausstattung );
			}
			else {
				filialausstattung.Menge_Abbau__c = null;
				filialausstattung.Menge_Wiedereinsatzfaehig__c = null;
				filialausstattungUpdate.add( filialausstattung );
			}
		}
		update filialausstattungUpdate;
		if ( !filialausstattungDelete.isEmpty() ) {
			delete filialausstattungDelete;
			Database.emptyRecycleBin( filialausstattungDelete );
		}
	}
	
	private Decimal returnZeroIfNull ( Decimal value ) {
		return value == null ? 0 : value;
	}
	
	private void processZusatzbestellung ( String processType ) {
		List<Filialausstattung__c> filialausstattungs = new List<Filialausstattung__c>();
		String vorgemerktValue = 'in ' + processType;
		for ( Filialausstattung__c filialausstattung : [
				SELECT
						Id
				FROM Filialausstattung__c
				WHERE Vorgemerkt__c = :vorgemerktValue
				AND Filiale__c = :recordId
		] ) {
			filialausstattung.Vorgemerkt__c = null;
			filialausstattungs.add( filialausstattung );
		}
		update filialausstattungs;
	}
	
	private void processErsatzbestellung ( String processType ) {
		String vorgemerktValue = 'in ' + processType;
		for ( Filialausstattung__c filialausstattung : [
				SELECT
						Id,
						ErsatzFuer__c,
						Menge__c
				FROM Filialausstattung__c
				WHERE Vorgemerkt__c = :vorgemerktValue
				AND Filiale__c = :recordId
		] ) {
			filialausstattung.Vorgemerkt__c = null;
			filialausstattungsUpdate.add( filialausstattung );
			if ( filialausstattung.ErsatzFuer__c != null ) {
				filialausstattungByProductIds.put( filialausstattung.ErsatzFuer__c, filialausstattung );
			}
		}
		Set<String> productIds = flagAbbauForExistingAusstattung();
		for ( Id key : filialausstattungByProductIds.keySet() ) {
			if ( productIds.contains( key ) ) {
				filialausstattungByProductIds.remove( key );
			}
		}
		flagAbbauForNewAusstattung();
		insert filialausstattungsInsert;
		update filialausstattungsUpdate;
	}
	
	private void flagAbbauForNewAusstattung () {
		for ( Produktoption__c produktoption : [
				SELECT
						Id,
						Option__c,
						Option__r.Name,
						Produktbuendeloption__c
				FROM Produktoption__c
				WHERE Option__c IN :filialausstattungByProductIds.keySet()
				AND Product__r.Family = 'Vorgängerfiliale'
		] ) {
			if ( !filialausstattungByProductIds.containsKey( produktoption.Option__c ) ) {
				continue;
			}
			Filialausstattung__c ersatz = filialausstattungByProductIds.get( produktoption.Option__c );
			filialausstattungsInsert.add(
					new Filialausstattung__c(
							Filiale__c = recordId,
							Name = NameFieldLimiter.getValue( produktoption.Option__r.Name ),
							Produkt__c = produktoption.Option__c,
							Produktoption__c = produktoption.Id,
							Menge__c = ersatz.Menge__c,
							Menge_Abbau__c = ersatz.Menge__c,
							Menge_Wiedereinsatzfaehig__c = 0,
							Produktbuendeloption__c = produktoption.Produktbuendeloption__c,
							Vorgemerkt__c = 'in Abbau zusätzlich'
					)
			);
			filialausstattungByProductIds.remove( produktoption.Option__c );
		}
	}
	
	private Set<String> flagAbbauForExistingAusstattung () {
		Set<String> productBundleIds = new Set<String>();
		Set<String> productIds = new Set<String>();
		Map<String, Filialausstattung__c> filialausstattungById = new Map<String, Filialausstattung__c>();
		for ( Filialausstattung__c filialausstattung : [
				SELECT
						Id,
						Menge__c,
						Produktoption__c,
						Produkt__c
				FROM Filialausstattung__c
				WHERE Filiale__c = :recordId
				AND Produkt__c IN :filialausstattungByProductIds.keySet()
				AND Vorgemerkt__c = NULL
		] ) {
			productBundleIds.add( filialausstattung.Produktoption__c );
			productIds.add( filialausstattung.Produkt__c );
			filialausstattung.Vorgemerkt__c = 'in Abbau';
			filialausstattung.Menge_Abbau__c = filialausstattungByProductIds.get( filialausstattung.Produkt__c ).Menge__c;
			if ( filialausstattung.Menge_Abbau__c > filialausstattung.Menge__c ) {
				filialausstattung.Menge_Abbau__c = filialausstattung.Menge__c;
			}
			filialausstattung.Menge_Wiedereinsatzfaehig__c = 0;
			filialausstattungsUpdate.add( filialausstattung );
			filialausstattungById.put( filialausstattung.Id, filialausstattung );
		}
		setChildren( productBundleIds, filialausstattungById );
		return productIds;
	}
	
	private void setChildren ( Set<String> productBundleIds, Map<String, Filialausstattung__c> filialausstattungById ) {
		Boolean keepLoading = true;
		Integer productLevel = 1;
		Set<String> productBundleOptionIds = productBundleIds;
		
		while ( keepLoading ) {
			
			Map<String, List<Filialausstattung__c>> produktoptionenByParentProductOptionId = loadOptionsByParentProductOptionIds( productBundleOptionIds );
			productBundleOptionIds = new Set<String>();
			for ( String parentProductOptionId : produktoptionenByParentProductOptionId.keySet() ) {
				
				for ( Filialausstattung__c produktoption : produktoptionenByParentProductOptionId.get( parentProductOptionId ) ) {
					
					Filialausstattung__c parent = filialausstattungById.get( produktoption.Produktbuendel__c );
					
					produktoption.Vorgemerkt__c = 'in Abbau';
					produktoption.Menge_Abbau__c = parent.Menge_Abbau__c * ( produktoption.Menge__c / parent.Menge__c );
					produktoption.Menge_Wiedereinsatzfaehig__c = 0;
					filialausstattungsUpdate.add( produktoption );
					productBundleOptionIds.add( produktoption.Produktoption__c );
					filialausstattungById.put( produktoption.Id, produktoption );
				}
			}
			keepLoading = produktoptionenByParentProductOptionId.keySet().size() > 0;
			productLevel++;
		}
	}
	
	private Map<String, List<Filialausstattung__c>> loadOptionsByParentProductOptionIds ( Set<String> productBundleOptionIds ) {
		Map<String, List<Filialausstattung__c>> optionsByParentProductOptionId = new Map<String, List<Filialausstattung__c>>();
		
		for ( Filialausstattung__c option : [
				SELECT
						Id,
						Menge__c,
						Produktoption__c,
						Produkt__c,
						Produktbuendeloption__c,
						Produktbuendeloption__r.Option__c,
						Produktbuendel__c
				FROM Filialausstattung__c
				WHERE Filiale__c = :recordId
				AND Produktbuendeloption__c IN :productBundleOptionIds
				AND Vorgemerkt__c = NULL
		] ) {
			
			if ( optionsByParentProductOptionId.containsKey( option.Produktbuendeloption__c ) ) {
				optionsByParentProductOptionId.get( option.Produktbuendeloption__c ).add( option );
			}
			else {
				optionsByParentProductOptionId.put( option.Produktbuendeloption__c, new List<Filialausstattung__c> {
						option
				} );
			}
		}
		
		return optionsByParentProductOptionId;
	}
	
	protected override void initializeEroeffnungsprozess ( String fields ) {
		setEroeffnungsprozess( fields );
		setPhoneNumberVertriebsmanager();
		setPhoneNumberRegionalerVertriebssteuerer();
		
		if ( account.Filialtyp_OZ__c == '82' ) {
			process.Geschaeftsvorfall__c = 'Zusatz-/Ersatzbeschaffung';
		}
		process.Einrichtungskoordinator_Name__c =
				process.Einrichtungskoordinator_Name__c == null
						? process.Filiale__r.NL_Brief_Lookup__r.Aussenstellen_Ma__r.Name
						: process.Einrichtungskoordinator_Name__c;
		String phoneNumber = process.Filiale__r.NL_Brief_Lookup__r.Aussenstellen_Ma__r.MobilePhone == null
				? process.Filiale__r.NL_Brief_Lookup__r.Aussenstellen_Ma__r.Phone
				: process.Filiale__r.NL_Brief_Lookup__r.Aussenstellen_Ma__r.Phone
						+ ' oder '
						+ process.Filiale__r.NL_Brief_Lookup__r.Aussenstellen_Ma__r.MobilePhone;
		process.Einrichtungskoordinator_Telefon__c =
				process.Einrichtungskoordinator_Telefon__c == null
						? phoneNumber
						: process.Einrichtungskoordinator_Telefon__c;
		process.Einrichtungskoordinator_E_Mail__c =
				process.Einrichtungskoordinator_E_Mail__c == null
						? process.Filiale__r.NL_Brief_Lookup__r.Aussenstellen_Ma__r.Email
						: process.Einrichtungskoordinator_E_Mail__c;
		setOeffnungszeiten();
		update process;
	}
	
	private void setOeffnungszeiten(){
		List<Oeffnungszeiten__c> filialOeffnungszeiten = new List<Oeffnungszeiten__c>();
		filialOeffnungszeiten = [
				SELECT
						Name,
						Id,
						Kategorie__c,
						Wochentag__c,
						vm_von__c,
						vm_bis__c,
						nm_von__c,
						nm_bis__c,
						Account__c
				FROM Oeffnungszeiten__c
				WHERE Account__c = :process.Filiale__c
				AND Kategorie__c = 'Filialöffnungszeiten'
				AND Prozess__c = :HW_Stammdatensammler_LC.mainProcess
				ORDER BY Name ASC NULLS LAST
		];
		if ( filialOeffnungszeiten.size() == 0 ) {
			filialOeffnungszeiten = OeffnungszeitService.getDefinitionsByAccountId( process.Filiale__c );
			insert filialOeffnungszeiten;
		}
		else if ( filialOeffnungszeiten.size() > 0 && !process.Filiale__r.FehlendeFactsOez__c ) {
			filialOeffnungszeiten = OeffnungszeitService.getDefinitionsByAccountId( process.Filiale__c );
		}
		else{
			//Sonarqube --> do nothing
		}
		String montag = getMontag( filialOeffnungszeiten[ 0 ] );
		String dienstag = getDienstag( filialOeffnungszeiten[ 1 ] );
		String mittwoch = getMittwoch( filialOeffnungszeiten[ 2 ] );
		String donnerstag = getDonnerstag( filialOeffnungszeiten[ 3 ] );
		String freitag = getFreitag( filialOeffnungszeiten[ 4 ] );
		process.Montag__c = process.Montag__c == null ? montag : process.Montag__c;
		process.Dienstag__c = process.Dienstag__c == null ? dienstag : process.Dienstag__c;
		process.Mittwoch__c = process.Mittwoch__c == null ? mittwoch : process.Mittwoch__c;
		process.Donnerstag__c = process.Donnerstag__c == null ? donnerstag : process.Donnerstag__c;
		process.Freitag__c = process.Freitag__c == null ? freitag : process.Freitag__c;
		process.Anfahrt_LWK_moeglich__c = process.Anfahrt_LWK_moeglich__c == null
				? 'LKW bis 12t'
				: process.Anfahrt_LWK_moeglich__c;
		process.BA_Bohrfreigaben_erteilt__c = process.BA_Bohrfreigaben_erteilt__c == null
				? 'Ja'
				: process.BA_Bohrfreigaben_erteilt__c;
		process.ProzessAbbau__c = process.ProzessAbbau__c == null ? 'Teilabbau' : process.ProzessAbbau__c;
	}
	
	private String getMontag ( Oeffnungszeiten__c day ) {
		
		String montag = '';
		if ( day.vm_von__c != null ) {
			montag += day.vm_von__c + ' Uhr ';
		}
		if ( day.vm_bis__c != null ) {
			montag += 'bis ' + day.vm_bis__c + ' Uhr ';
		}
		if ( day.nm_von__c != null ) {
			montag += 'und ' + day.nm_von__c + ' Uhr ';
		}
		if ( day.nm_bis__c != null ) {
			montag += 'bis ' + day.nm_bis__c + ' Uhr ';
		}
		return montag;
	}
	
	private String getDienstag ( Oeffnungszeiten__c day ) {
		
		String dienstag = '';
		if ( day.vm_von__c != null ) {
			dienstag += day.vm_von__c + ' Uhr ';
		}
		if ( day.vm_bis__c != null ) {
			dienstag += 'bis ' + day.vm_bis__c + ' Uhr ';
		}
		if ( day.nm_von__c != null ) {
			dienstag += 'und ' + day.nm_von__c + ' Uhr ';
		}
		if ( day.nm_bis__c != null ) {
			dienstag += 'bis ' + day.nm_bis__c + ' Uhr ';
		}
		return dienstag;
	}
	
	private String getMittwoch ( Oeffnungszeiten__c day ) {
		
		String mittwoch = '';
		if ( day.vm_von__c != null ) {
			mittwoch += day.vm_von__c + ' Uhr ';
		}
		if ( day.vm_bis__c != null ) {
			mittwoch += 'bis ' + day.vm_bis__c + ' Uhr ';
		}
		if ( day.nm_von__c != null ) {
			mittwoch += 'und ' + day.nm_von__c + ' Uhr ';
		}
		if ( day.nm_bis__c != null ) {
			mittwoch += 'bis ' + day.nm_bis__c + ' Uhr ';
		}
		return mittwoch;
	}
	
	private String getDonnerstag ( Oeffnungszeiten__c day ) {
		
		String donnerstag = '';
		if ( day.vm_von__c != null ) {
			donnerstag += day.vm_von__c + ' Uhr ';
		}
		if ( day.vm_bis__c != null ) {
			donnerstag += 'bis ' + day.vm_bis__c + ' Uhr ';
		}
		if ( day.nm_von__c != null ) {
			donnerstag += 'und ' + day.nm_von__c + ' Uhr ';
		}
		if ( day.nm_bis__c != null ) {
			donnerstag += 'bis ' + day.nm_bis__c + ' Uhr ';
		}
		return donnerstag;
	}
	
	private String getFreitag ( Oeffnungszeiten__c day ) {
		
		String freitag = '';
		if ( day.vm_von__c != null ) {
			freitag += day.vm_von__c + ' Uhr ';
		}
		if ( day.vm_bis__c != null ) {
			freitag += 'bis ' + day.vm_bis__c + ' Uhr ';
		}
		if ( day.nm_von__c != null ) {
			freitag += 'und ' + day.nm_von__c + ' Uhr ';
		}
		if ( day.nm_bis__c != null ) {
			freitag += 'bis ' + day.nm_bis__c + ' Uhr ';
		}
		return freitag;
	}
	
	private void loadMetadata () {
		
		initializeFieldMetadata();
		loadData();
		initializeSectionMetadata();
		initializeScreenMetadata();
		buildScreens();
	}
}