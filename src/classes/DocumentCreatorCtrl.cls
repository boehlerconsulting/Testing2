/**
 *@author       Mats Böhler
 *@created      22.03.2022
 *
 *
 *@description  DocumentCreatorCtrl
 *
 *
 *@changelog    22.03.2022 Mats Böhler  - Created
 *              
 * 
 */
public without sharing class DocumentCreatorCtrl {
	
	private Id recordId;
	private List<String> relateToRecordFieldNames = new List<String>();
	private String sourceDocumentIndexName;
	private String emailSettingDeveloperName;
	private String encodedPdf;
	private String fileName;
	private List<PDF_LIB_Mapping__mdt> pdflibMappings = new List<PDF_LIB_Mapping__mdt>();
	private List<Mapping> mappings = new List<DocumentCreatorCtrl.Mapping>();
	private SObject record;
	private Id contentDocumentId;
	private List<Id> emailDeliveryIds = new List<Id>();
	private List<Id> linkedEntityIds = new List<Id>();
	
	@AuraEnabled
	public static String initialize ( Id recordId, String relateToRecordFieldName, String sourceDocumentIndexName ) {
		DocumentCreatorCtrl instance = new DocumentCreatorCtrl();
		try {
			instance.recordId = recordId;
			instance.relateToRecordFieldNames.addAll( relateToRecordFieldName.split( ',' ) );
			instance.sourceDocumentIndexName = sourceDocumentIndexName;
			instance.loadPdf();
			instance.loadMetadata();
			instance.loadSObject();
			instance.createMappings();
			return JSON.serialize(
					new DocumentCreatorResponse( instance.encodedPdf, instance.mappings )
			);
		}
		catch ( Exception e ) {
			throw new AuraHandledException( e.getMessage() );
		}
	}
	
	@AuraEnabled
	public static String save ( String data, Id recordId, String relateToRecordFieldName, String sourceDocumentIndexName, String emailSettingDeveloperName, String fileName ) {
		Savepoint savepoint = Database.setSavepoint();
		DocumentCreatorCtrl instance = new DocumentCreatorCtrl();
		try {
			instance.fileName = fileName;
			instance.recordId = recordId;
			instance.relateToRecordFieldNames.addAll( relateToRecordFieldName.split( ',' ) );
			instance.sourceDocumentIndexName = sourceDocumentIndexName;
			instance.emailSettingDeveloperName = emailSettingDeveloperName;
			instance.loadMetadata();
			instance.loadSObject();
			instance.setLinkedEntityIds();
			instance.sendEmail();
			instance.saveFile( data );
		}
		catch ( Exception e ) {
			Database.rollback( savepoint );
			throw new AuraHandledException( e.getMessage() );
		}
		return instance.contentDocumentId;
	}
	
	private String getSObjectName ( Id objectId ) {
		return objectId.getSobjectType().getDescribe().getName();
	}
	
	private void sendEmail () {
		if ( String.isBlank( emailSettingDeveloperName ) ) {
			return;
		}
		EmailSettingService.Request request = new EmailSettingService.Request();
		request.recordId = recordId;
		addRelationIds( request, recordId );
		request.emailSettingName = emailSettingDeveloperName;
		for ( Id objectId : linkedEntityIds ) {
			addRelationIds( request, objectId );
		}
		EmailSettingService.getInstance().requests.add( request );
		List<EmailVersand__c> emailDeliveries =
				EmailSettingService.getInstance().createMessages().getEmailDispatcherServiceDeliveries();
		for ( EmailVersand__c emailVersand : emailDeliveries ) {
			emailVersand.Anhang__c = true;
		}
		insert emailDeliveries;
		for ( EmailVersand__c emailVersand : emailDeliveries ) {
			emailDeliveryIds.add( emailVersand.Id );
		}
	}
	
	private EmailSettingService.Request addRelationIds ( EmailSettingService.Request request, Id objectId ) {
		String sObjectName = getSObjectName( objectId );
		if ( sObjectName == 'Lead' ) {
			request.leadId = objectId;
		}
		if ( sObjectName == 'Account' ) {
			request.accountId = objectId;
		}
		if ( sObjectName == 'Contract' ) {
			request.contractId = objectId;
		}
		if ( sObjectName == 'Filialnetzaenderung__c' ) {
			request.fnaeId = objectId;
		}
		return request;
	}
	
	private String getFileName () {
		String name = fileName;
		if ( name.contains( 'TODAY()' ) ) {
			name = name.replace( 'TODAY()', Date.today().format() );
		}
		return FileNameReplacer.replace(name);
	}
	
	private String getFileNameWithExtension () {
		return getFileName() + '.pdf';
	}
	
	private void loadPdf () {
		ContentVersion contentVersion = [
				SELECT
						Id,
						VersionData
				FROM ContentVersion
				WHERE IsLatest = TRUE
				AND Index__c = :sourceDocumentIndexName
				LIMIT 1
		];
		encodedPdf = EncodingUtil.base64Encode( contentVersion.VersionData );
	}
	
	private void loadMetadata () {
		pdflibMappings = [
				SELECT
						Id,
						Nummerierung__c,
						Dokument__c,
						DokumentFeldname__c,
						DokumentFeldtyp__c,
						Feldname__c,
						Schreibschutz__c,
						Info__c,
						Feldwert__c
				FROM PDF_LIB_Mapping__mdt
				WHERE Dokument__c = :sourceDocumentIndexName
				AND Objekt__c = :getSObjectName( recordId )
				ORDER BY Nummerierung__c ASC NULLS LAST
		];
	}
	
	private void loadSObject () {
		Set<String> fieldNames = new Set<String>();
		for ( PDF_LIB_Mapping__mdt pdflibMapping : pdflibMappings ) {
			fieldNames.add( pdflibMapping.Feldname__c );
		}
		fieldNames.addAll( relateToRecordFieldNames );
		fieldNames.add( 'Id' );
		fieldNames.remove( null );
		String commaSeparatedFields = String.join( new List<String>( fieldNames ), ',' );
		String query = 'SELECT '
				+ commaSeparatedFields
				+ ' FROM ' + recordId.getSobjectType().getDescribe().getName()
				+ ' WHERE Id = :recordId LIMIT 1';
		record = Database.query( query );
	}
	
	private String returnEmptyIfNull ( String value ) {
		return value == null ? '' : value;
	}
	
	private void createMappings () {
		for ( PDF_LIB_Mapping__mdt pdflibMapping : pdflibMappings ) {
			String value;
			if ( String.isNotBlank( pdflibMapping.Feldwert__c ) ) {
				value = pdflibMapping.Feldwert__c;
			}
			if ( String.isNotBlank( pdflibMapping.Feldname__c ) ) {
				value = returnEmptyIfNull( setFieldValue( record, pdflibMapping ) );
			}
			mappings.add( new Mapping( pdflibMapping, value ) );
		}
	}
	
	private String setFieldValue ( SObject record, PDF_LIB_Mapping__mdt pdflibMapping ) {
		String fieldValue = '';
		Object value;
		if ( pdflibMapping.Feldname__c.contains( '.' ) ) {
			List<String> splitFieldName = pdflibMapping.Feldname__c.split( '\\.' );
			if ( record.getSObject( splitFieldName[ 0 ] ) != null ) {
				switch on splitFieldName.size() {
					when 2 {
						value = record.getSObject( splitFieldName[ 0 ] ).get( splitFieldName[ 1 ] );
					}
					when 3 {
						value = record.getSObject( splitFieldName[ 0 ] )
								.getSObject( splitFieldName[ 1 ] )
								.get( splitFieldName[ 2 ] );
					}
					when 4 {
						value = record.getSObject( splitFieldName[ 0 ] )
								.getSObject( splitFieldName[ 1 ] )
								.getSObject( splitFieldName[ 2 ] )
								.get( splitFieldName[ 3 ] );
					}
					when 5 {
						value = record.getSObject( splitFieldName[ 0 ] )
								.getSObject( splitFieldName[ 1 ] )
								.getSObject( splitFieldName[ 2 ] )
								.getSObject( splitFieldName[ 3 ] )
								.get( splitFieldName[ 4 ] );
					}
					when else {
						//Sonarqube --> do nothing
					}
				}
			}
		}
		else {
			value = record.get( pdflibMapping.Feldname__c );
		}
		if ( pdflibMapping.DokumentFeldtyp__c == 'TextFieldDate' ) {
			Date dateValue = (Date) value;
			if ( dateValue != null ) {
				fieldValue = dateValue.format();
			}
		}
		else {
			fieldValue = (String) value;
		}
		return fieldValue;
	}
	
	private void setLinkedEntityIds () {
		for ( String relateToRecordFieldName : relateToRecordFieldNames ) {
			linkedEntityIds.add( (Id) record.get( relateToRecordFieldName ) );
		}
	}
	
	private void saveFile ( String data ) {
		Set<Id> existingContentDocumentIds = new Set<Id>();
		Id linkedEntityId = linkedEntityIds[ 0 ];
		
		List<ContentDocumentLink> existingContentDocumentLinks = [
				SELECT ContentDocumentId
				FROM ContentDocumentLink
				WHERE LinkedEntityId = :linkedEntityId
		];
		for ( ContentDocumentLink contentDocumentLink : existingContentDocumentLinks ) {
			existingContentDocumentIds.add( contentDocumentLink.ContentDocumentId );
		}
		
		List<ContentVersion> existingConentVersions = [
				SELECT ContentDocumentId
				FROM ContentVersion
				WHERE ContentDocumentId IN :existingContentDocumentIds
				AND PathOnClient = :getFileNameWithExtension()
				AND IsLatest = TRUE
				LIMIT 1
		];
		
		ContentVersion newContentVersion = new ContentVersion(
				Title = FileNameReplacer.replace( getFileName() ),
				PathOnClient = getFileNameWithExtension(),
				VersionData = EncodingUtil.base64Decode( data ),
				ContentLocation = 'S',
				ContentDocumentId = existingConentVersions.isEmpty() ? null : existingConentVersions[ 0 ].ContentDocumentId
		);
		insert newContentVersion;
		
		contentDocumentId = existingConentVersions.isEmpty()
				? [
						SELECT
								ContentDocumentId
						FROM ContentVersion
						WHERE Id = :newContentVersion.Id
				].ContentDocumentId
				: existingConentVersions[ 0 ].ContentDocumentId;
		
		List<ContentDocumentLink> contentDocumentLinks = new List<ContentDocumentLink>();
		for ( Id newLinkRecordId : linkedEntityIds ) {
			contentDocumentLinks.add( createLink( newLinkRecordId, 'I' ) );
		}
		for ( Id newLinkRecordId : emailDeliveryIds ) {
			contentDocumentLinks.add( createLink( newLinkRecordId, 'I' ) );
		}
		if ( String.isNotBlank( emailSettingDeveloperName ) ) {
			contentDocumentLinks.add( createLink( InterfaceUser.getInstance().getId(), 'V' ) );
		}
		List<Database.SaveResult> saveResults = Database.insert( contentDocumentLinks, false );
		for ( Database.SaveResult saveResult : saveResults ) {
			if ( !saveResult.isSuccess()
					&& !saveResult.getErrors()[ 0 ].getMessage().toLowerCase().contains( 'already linked' )
					&& !saveResult.getErrors()[ 0 ].getMessage().toLowerCase().contains(
					'ist bereits mit der entität mit folgender id verknüpft' ) ) {
				Database.Error error = saveResult.getErrors()[ 0 ];
				throw new DmlException( error.getStatusCode() + ': ' + error.getMessage() );
			}
		}
	}
	
	private ContentDocumentLink createLink ( Id linkedEntityId, String shareType ) {
		return new ContentDocumentLink(
				ContentDocumentId = contentDocumentId,
				LinkedEntityId = linkedEntityId,
				ShareType = shareType,
				Visibility = 'AllUsers'
		);
	}
	
	public class DocumentCreatorResponse {
		public String encodedPdf;
		public List<Mapping> mappings = new List<DocumentCreatorCtrl.Mapping>();
		
		public DocumentCreatorResponse ( String encodedPdf, List<Mapping> mappings ) {
			this.encodedPdf = encodedPdf;
			this.mappings = mappings;
		}
	}
	
	public class Mapping {
		public String type;
		public String name;
		public String value;
		public Boolean isReadOnly;
		
		public Mapping ( PDF_LIB_Mapping__mdt pdflibMapping, String value ) {
			this.type = pdflibMapping.DokumentFeldtyp__c;
			this.name = pdflibMapping.DokumentFeldname__c;
			this.value = value;
			this.isReadOnly = pdflibMapping.Schreibschutz__c;
		}
	}
}