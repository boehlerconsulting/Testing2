/**
 * @author      Stefan Richter (stefan.richter@hundw.de)
 *              H+W CONSULT GmbH
 *              Bahnhofstr. 3
 *              21244 Buchholz i. d. Nordheide
 *              Germany
 *              https://www.hundw.de
 *
 * @description class for <insert-description-here>
 *
 * TIMELINE
 * 30.10.20      Stefan Richter  Initial release.
 **/
public without sharing class VertragsErstellerCtrl {
	
	private String recordId = '';
	private Boolean hasPermission = false;
	
	@TestVisible
	private Lead lead = new Lead();
	
	@TestVisible
	private StrategischerPartner__mdt partner;
	
	@TestVisible
	private Stromverbrauch__mdt verbrauch;
	
	@AuraEnabled
	public static String loadData ( String recordId ) {
		VertragsErstellerCtrl instance = new VertragsErstellerCtrl();
		try {
			instance.hasPermission = FeatureManagement.checkPermission( 'VertragErstellen' );
			instance.recordId = recordId;
			Lead localLead = instance.loadLead();
			instance.partner = HW_SharedVertragsUtils.getStrategischePartner( localLead );
			instance.verbrauch = HW_SharedVertragsUtils.getStromverbrauch( localLead );
		}
		catch ( Exception e ) {
			throw new AuraHandledException( e.getMessage() );
		}
		return JSON.serialize( instance );
	}
	
	@AuraEnabled
	public static void saveData ( String jsonLead, String contractType ) {
		Lead ld = ( Lead ) JSON.deserialize( jsonLead, Lead.class );
		logActivity( ld, contractType );
		updateLead( ld );
	}
	
	@AuraEnabled
	public static String generateSinglePdf ( String jsonLead, String sp, String mk ) {
		Lead ld = ( Lead ) JSON.deserialize( jsonLead, Lead.class );
		
		PageReference pref = Page.HW_EinzelvertragPdf;
		pref.getParameters().put( 'id', ld.Id );
		pref.getParameters().put( 'sp', sp );
		pref.getParameters().put( 'mk', mk );
		
		String fileName = '2a1_' + ld.City + ld.Street + '_' + ld.Company + '-' + ld.STOG_Gesellschaft__c + '_Einzelvertrag';
		
		//ensure pdf downloads and is assigned with defined name
		pref.getHeaders().put( 'content-disposition',
				'attachment; filename=' + fileName + '.pdf' );
		
		Blob content;
		if ( !Test.isRunningTest() ) {
			content = pref.getContent();
		}
		else {
			content = Blob.valueOf( 'Test' );
		}
		
		logActivity( ld, 'single' );
		updateLead( ld );
		return EncodingUtil.base64Encode( content );
	}
	
	@AuraEnabled
	public static void sendMail ( String jsonLead, String sp, String mk ) {
		Lead lead = ( Lead ) JSON.deserialize( jsonLead, Lead.class );
		String sMessage = '';
		
		try {
			
			String fileName = '2a1_' + lead.City + lead.Street + '_' + lead.Company + '-' + lead.STOG_Gesellschaft__c + '_Einzelvertrag';
			PageReference pref = Page.HW_EinzelvertragPdf;
			pref.getParameters().put( 'id', lead.Id );
			pref.getParameters().put( 'sp', sp );
			pref.getParameters().put( 'mk', mk );
			pref.setRedirect( true );
			Blob content;
			if ( !Test.isRunningTest() ) {
				content = pref.getContent();
			}
			else {
				content = Blob.valueOf( 'Test' );
			}
			
			ContentVersion contentVersion = new ContentVersion();
			contentVersion.VersionData = content;
			contentVersion.Title = fileName;
			contentVersion.PathOnClient = fileName + '.pdf';
			insert contentVersion;
			
			EmailSettingService.Request request = new EmailSettingService.Request();
			request.recordId = lead.Id;
			request.emailSettingName = 'Einzelvertrag';
			request.documentName = 'Packstation - Einzelvertrag';
			request.leadId = lead.Id;
			request.selectedFileIds = [
					SELECT
							ContentDocumentId
					FROM ContentVersion
					WHERE Id = :contentVersion.Id
					LIMIT 1
			].ContentDocumentId;
			EmailSettingService.getInstance().requests.add( request );
			EmailSettingService.getInstance().createMessages().callEmailDispatcherService();
			updateLead( lead );
			sMessage = 'SUCCESS';
		}
		catch ( Exception ex ) {
			sMessage = ex.getMessage() + '\n' + ex.getLineNumber() + '\n' + ex.getCause();
			throw new AuraHandledException( ex.getMessage() );
		}
	}
	
	private static void logActivity ( Lead ld, String contractType ) {
		String subject;
		String description;
		
		if ( contractType == 'frame' ) {
			subject = 'Rahmenvertrag erstellt';
			description = 'Zum Lead ' + ld.Company + ' ' + ld.Street
					+ ' ' + ld.PostalCode + ' ' + ld.City + 'wurde ein Rahmenvertrag auf Basis <Rahmenvertrag> erzeugt.'
					+ 'Bitte prüfen Sie die Übereinstimmung mit dem im Lead hinterlegtem Wert.';
		}
		else {
			subject = 'Einzelvertrag erstellt';
			description = 'Zum Lead ' + ld.Company + ' ' + ld.Street
					+ ' ' + ld.PostalCode + ' ' + ld.City + ' wurde ein Einzelvertrag auf Basis <Einzelvertrag> erzeugt.';
		}
		
		saveAsEvent( ld, subject, description );
	}
	
	private static void saveAsEvent ( Lead ld, String subject, string description ) {
		
		Event logContractCreation = new Event();
		logContractCreation.Subject = subject;
		logContractCreation.WhoId = ld.Id;
		logContractCreation.ActivityDate = Date.today();
		logContractCreation.StartDateTime = Datetime.now();
		logContractCreation.EndDateTime = Datetime.now();
		logContractCreation.Description = description;
		logContractCreation.RecordTypeId = Schema.SObjectType.Event.getRecordTypeInfosByDeveloperName()
				.get( 'Information' ).getRecordTypeId();
		insert logContractCreation;
	}
	
	private static void updateLead ( Lead ld ) {
		ld.VertragErstelltAm__c = Date.today();
		ld.VerkehrssicherungspflichtLiegtBei__c = getSicherungspflicht( ld );
		update ld;
	}
	
	private static String getSicherungspflicht ( Lead ld ) {
		StrategischerPartner__mdt partner = HW_SharedVertragsUtils.getStrategischePartner( ld );
		
		if ( partner != null ) {
			return getReturnValue( partner );
		}
		else {
			return 'Partner';
		}
	}
	
	private static String getReturnValue ( StrategischerPartner__mdt partner ) {
		if ( partner.VerkehrssicherungspflichtAusserhalb__c == 'Standortnehmer'
				&& partner.VerkehrssicherungspflichtInnerhalb__c == 'Standortnehmer' ) {
			return 'DPAG (außerhalb Öffnungszeiten);DPAG (innerhalb Öffnungszeiten)';
		}
		if ( partner.VerkehrssicherungspflichtAusserhalb__c == 'Standortgeber'
				&& partner.VerkehrssicherungspflichtInnerhalb__c == 'Standortnehmer' ) {
			return 'DPAG (innerhalb Öffnungszeiten)';
		}
		if ( partner.VerkehrssicherungspflichtAusserhalb__c == 'Standortnehmer'
				&& partner.VerkehrssicherungspflichtInnerhalb__c == 'Standortgeber' ) {
			return 'DPAG (außerhalb Öffnungszeiten)';
		}
		if ( partner.VerkehrssicherungspflichtAusserhalb__c == 'Standortgeber'
				&& partner.VerkehrssicherungspflichtInnerhalb__c == 'Standortgeber' ) {
			return 'Partner';
		}
		if ( partner.VerkehrssicherungspflichtAusserhalb__c == 'Kein Rahmenvertrag'
				&& partner.VerkehrssicherungspflichtInnerhalb__c == 'Kein Rahmenvertrag' ) {
			return 'Partner';
		}
		return null;
	}
	
	private Lead loadLead () {
		lead = HW_SharedVertragsUtils.getLead( recordId );
		return lead;
	}
}