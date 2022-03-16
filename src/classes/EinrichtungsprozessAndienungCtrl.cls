/**
 *@author       Mats Böhler
 *@created      22.03.2021
 *
 *
 *@description  EnrichtungsprozessAndienungCtrl
 *
 *
 *@changelog    22.03.2021 Mats Böhler  - Created
 *              
 * 
 */
public with sharing class EinrichtungsprozessAndienungCtrl extends EinrichtungsprozessBaseCtrl {
	
	private List<Oeffnungszeiten__c> filialOeffnungszeiten = new List<Oeffnungszeiten__c>();
	
	@AuraEnabled
	public static String init ( Id recordId ) {
		EinrichtungsprozessAndienungCtrl instance = new EinrichtungsprozessAndienungCtrl();
		
		try {
			instance.recordId = recordId;
			instance.loadMetadata();
			instance.createOeffnungszeiten();
		}
		catch ( Exception e ) {
			
			throw new AuraHandledException( e.getMessage() );
		}
		
		return JSON.serialize( instance );
	}
	
	@AuraEnabled(Cacheable=true)
	public static String getDocumentUrl ( String recordId ) {
		PageReference pageReference = Page.AuftragVerEntsorgungBriefPaket;
		pageReference.getParameters().put( 'id', recordId );
		return pageReference.getUrl();
	}
	
	@AuraEnabled
	public static String saveDocument ( String recordId ) {
		Savepoint savepoint = Database.setSavepoint();
		EinrichtungsprozessAndienungCtrl instance = new EinrichtungsprozessAndienungCtrl();
		try {
			PageReference pageReference = Page.AuftragVerEntsorgungBriefPaket;
			pageReference.getParameters().put( 'id', recordId );
			AuftragVerEntsorgungBriefPaketCtrl ctrl = new AuftragVerEntsorgungBriefPaketCtrl( pageReference );
			ctrl.saveAsFile( new List<Id> {
					ctrl.getRecord().Filiale__c,
					instance.createEmailDelivery( ctrl.getRecord() )
			} );
			return setLastSentDate( recordId );
		}
		catch ( Exception e ) {
			Database.rollback( savepoint );
			throw new AuraHandledException( e.getMessage() );
		}
	}
	
	@AuraEnabled
	public static void saveWochentag ( String wochentagString ) {
		
		try {
			update ( Oeffnungszeiten__c ) JSON.deserialize( wochentagString, Oeffnungszeiten__c.class );
		}
		catch ( Exception e ) {
			throw new AuraHandledException( e.getMessage() );
		}
	}
	
	private void loadMetadata () {
		
		initializeFieldMetadata();
		loadData();
		initializeSectionMetadata();
		initializeScreenMetadata();
		buildScreens();
	}
	
	private static String setLastSentDate ( Id processId ) {
		String documentVersion = 'Letztmalig erzeugt am ' + Date.today().format()
				+ ' um ' + Datetime.now().format().split( ' ' )[ 1 ] + ' Uhr';
		update new Einrichtungsprozess__c(
				Id = processId,
				Dokumentenversion__c = documentVersion
		);
		return documentVersion;
	}
	
	private Id createEmailDelivery ( Einrichtungsprozess__c einrichtungsprozess ) {
		List<EmailVersand__c> emailVersands = [
				SELECT
						Id
				FROM EmailVersand__c
				WHERE Dokument__c = 'Auftrag Ver- und Entsorgung Brief und Paket'
				AND Account__c = :einrichtungsprozess.Filiale__c
				LIMIT 1
		];
		EmailVersand__c existingEmail = ( emailVersands.size() == 1 ) ? emailVersands.get( 0 ) : null;
		
		EmailSettingService.Request request = new EmailSettingService.Request();
		request.recordId = einrichtungsprozess.Filiale__c;
		request.emailSettingName = FileNameReplacer.replace(einrichtungsprozess.Filiale__r.NL_Brief__c).replace(' ', '_');
		request.accountId = einrichtungsprozess.Filiale__c;
		request.documentName = 'Auftrag Ver- und Entsorgung Brief und Paket';
		EmailSettingService.getInstance().requests.add(request);
		List<EmailVersand__c> emailDeliveries
				= EmailSettingService.getInstance().createMessages().getEmailDispatcherServiceDeliveries();
		if (existingEmail != null ) {
			for ( EmailVersand__c emailVersand : emailDeliveries ) {
				emailVersand.Email_Betreff__c = 'Änderung ' + emailVersand.Email_Betreff__c;
			}
		}
		insert emailDeliveries;
		return emailDeliveries[0].Id;
	}
	
	protected override void initializeAccount ( String fields ) {
		
		account = loadAccount( fields );
		if (account.Telefon_Vertragspartner__c != null && account.Mobil__c == null ) {
			//Sonarqube -> do nothing
		}
		else if ( account.Telefon_Vertragspartner__c != null && account.Mobil__c != null ) {
			account.Telefon_Vertragspartner__c = account.Telefon_Vertragspartner__c + ' oder ' + account.Mobil__c;
		}
		else if (account.Telefon_Vertragspartner__c == null && account.Mobil__c != null ) {
			account.Telefon_Vertragspartner__c = account.Mobil__c;
		}
		else{
			//Sonarqube -> do nothing
		}
	}
	
	protected override void initializeFieldMetadata () {
		for ( Feld__mdt feld : [
				SELECT
						Id,
						Nummerierung__c,
						Sektion__c,
						Objektname__c,
						Feldname__c,
						Feldtyp__c,
						ist_Formelfeld__c,
						Schreibschutz__c,
						Erforderlich__c,
						Ausblenden__c,
						Hilfetext__c,
						Spalte__c,
						Label__c,
						Maximale_Laenge__c,
						Bild__c
				FROM Feld__mdt
				WHERE Prozess__c = 'Einrichtungsprozess'
				AND Sektion__r.Fenster__r.DeveloperName = 'AuftragVerEntsorgungBriefPaket'
				ORDER BY Nummerierung__c ASC NULLS LAST
		] ) {
			
			if ( fieldsBySectionIds.containsKey( feld.Sektion__c ) ) {
				fieldsBySectionIds.get( feld.Sektion__c ).add( feld );
			}
			else {
				fieldsBySectionIds.put( feld.Sektion__c, new List<Feld__mdt> {
						feld
				} );
			}
		}
	}
	
	protected override void initializeSectionMetadata () {
		for ( Sektion__mdt sektion : [
				SELECT
						Id,
						Titel__c,
						Fenster__c,
						Nummerierung__c
				FROM Sektion__mdt
				WHERE Prozess__c = 'Einrichtungsprozess'
				AND Fenster__r.DeveloperName = 'AuftragVerEntsorgungBriefPaket'
				ORDER BY Nummerierung__c ASC NULLS LAST
		] ) {
			
			if ( sectionByScreenIds.containsKey( sektion.Fenster__c ) ) {
				sectionByScreenIds.get( sektion.Fenster__c ).add( sektion );
			}
			else {
				sectionByScreenIds.put( sektion.Fenster__c, new List<Sektion__mdt> {
						sektion
				} );
			}
		}
	}
	
	protected override void initializeScreenMetadata () {
		fensterByIds = new Map<Id, Fenster__mdt>( [
				SELECT
						Id,
						Titel__c,
						Nummerierung__c
				FROM Fenster__mdt
				WHERE Prozess__c = 'Einrichtungsprozess'
				AND DeveloperName = 'AuftragVerEntsorgungBriefPaket'
				ORDER BY Nummerierung__c ASC NULLS LAST
		] );
	}
	
	protected override void buildScreens () {
		for ( Fenster__mdt fenster : fensterByIds.values() ) {
			screens.add(
					new Screen(
							fenster.Titel__c,
							buildSections( fenster ),
							fenster.Id
					)
			);
		}
	}
	
	private void createOeffnungszeiten () {
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
				WHERE Account__c = :account.Id
				AND Kategorie__c = 'Filialöffnungszeiten'
				ORDER BY Name ASC NULLS LAST
		];
		if ( filialOeffnungszeiten.size() == 0 ) {
			filialOeffnungszeiten = OeffnungszeitService.getDefinitionsByAccountId( account.Id );
			insert filialOeffnungszeiten;
		}
		else if ( filialOeffnungszeiten.size() > 0 && !account.FehlendeFactsOez__c ) {
			filialOeffnungszeiten = OeffnungszeitService.getDefinitionsByAccountId( account.Id );
		}
		else{
			//Sonarqube --> do nothing
		}
	}
}