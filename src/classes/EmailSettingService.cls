/**
 *@author       Mats Böhler
 *@created      02.07.2020
 *
 *
 *@description  EmailSettingService
 *
 *
 *@changelog    02.07.2020 Mats Böhler  - Created
 *              
 * 
 */
public without sharing class EmailSettingService {
	
	public List<EmailDispatcherService.Message> messages = null;
	public List<Request> requests = null;
	
	private static EmailSettingService instance = null;
	
	private Map<String, EmailEinstellung__mdt> emailSettingByDeveloperName = new Map<String, EmailEinstellung__mdt>();
	private Map<String, String> emailAddressByRecordIdAndFieldName = new Map<String, String>();
	private Set<String> emailSettingNames = new Set<String>();
	private Set<String> recordIds = new Set<String>();
	private Set<String> fieldsToQuery = new Set<String>();
	private String objectName = '';
	
	public static EmailSettingService getInstance () {
		if ( instance == null ) {
			instance = new EmailSettingService();
			instance.requests = new List<Request>();
		}
		return instance;
	}
	
	public void sendBulk () {
		if ( !requests.isEmpty() ) {
			if ( requests.size() > 1 && !Test.isRunningTest() ) {
				startBatchByObject();
			}
			else {
				EmailSettingService.getInstance().createMessages().callEmailDispatcherService();
			}
		}
		requests = new List<EmailSettingService.Request>();
	}
	
	@TestVisible
	private Map<Id, List<Request>> setRequestsByRecordIds (List<Request> objectRequests) {
		Map<Id, List<Request>> requestsByRecordIds = new Map<Id, List<Request>>();
		for ( Request request : objectRequests ) {
			if ( requestsByRecordIds.containsKey( request.recordId ) ) {
				requestsByRecordIds.get( request.recordId ).add( request );
			}
			else {
				requestsByRecordIds.put( request.recordId, new List<Request> {
						request
				} );
			}
		}
		return requestsByRecordIds;
	}
	
	public void callEmailDispatcherService () {
		if ( messages.isEmpty() ) {
			return;
		}
		new EmailDispatcherService( messages ).sendEmail();
		messages = new List<EmailDispatcherService.Message>();
		requests = new List<Request>();
	}
	
	public List<EmailVersand__c> getEmailDispatcherServiceDeliveries () {
		if ( messages.isEmpty() ) {
			return new List<EmailVersand__c>();
		}
		List<EmailVersand__c> emailDeliveries = new EmailDispatcherService( messages ).getEmailDeliveries();
		messages = new List<EmailDispatcherService.Message>();
		requests = new List<Request>();
		return emailDeliveries;
	}
	
	public EmailSettingService createMessages () {
		if ( messages == null ) {
			messages = new List<EmailDispatcherService.Message>();
		}
		if ( requests.isEmpty() ) {
			return this;
		}
		String sObjectName = requests[ 0 ].recordId.getSobjectType().getDescribe().name;
		objectName = sObjectName;
		emailSettingNames = new Set<String>();
		recordIds = new Set<String>();
		fieldsToQuery = new Set<String>();
		for ( Request request : requests ) {
			emailSettingNames.add( request.emailSettingName );
			recordIds.add( request.recordId );
		}
		loadEmailSettings();
		loadRecordInformation();
		for ( Request request : requests ) {
			processRequest( request );
		}
		return this;
	}
	
	private void loadRecordInformation () {
		emailAddressByRecordIdAndFieldName = new Map<String, String>();
		if ( !fieldsToQuery.isEmpty() ) {
			String fields = '';
			for ( String fieldName : fieldsToQuery ) {
				fields += fieldName + ',';
			}
			fields = fields.removeEnd( ',' );
			
			for ( SObject record : Database.query( 'SELECT Id, ' + fields + ' FROM ' + objectName + ' WHERE Id IN :recordIds' ) ) {
				setFieldValues( record );
			}
		}
	}
	
	private void setFieldValues ( SObject record ) {
		for ( String fieldName : fieldsToQuery ) {
			setFieldValue( record, fieldName );
		}
	}
	
	private String setFieldValue ( SObject record, String fieldName ) {
		String fieldValue = '';
		if ( fieldName.contains( '.' ) && fieldName.containsNone( '@' ) ) {
			List<String> splitFieldName = fieldName.split( '\\.' );
			if ( record.getSObject( splitFieldName[ 0 ] ) != null ) {
				switch on splitFieldName.size() {
					when 2 {
						fieldValue = ( String ) record.getSObject( splitFieldName[ 0 ] ).get( splitFieldName[ 1 ] );
					}
					when 3 {
						fieldValue = ( String ) record.getSObject( splitFieldName[ 0 ] )
								.getSObject( splitFieldName[ 1 ] )
								.get( splitFieldName[ 2 ] );
					}
					when 4 {
						fieldValue = ( String ) record.getSObject( splitFieldName[ 0 ] )
								.getSObject( splitFieldName[ 1 ] )
								.getSObject( splitFieldName[ 2 ] )
								.get( splitFieldName[ 3 ] );
					}
					when 5 {
						fieldValue = ( String ) record.getSObject( splitFieldName[ 0 ] )
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
			fieldValue = ( String ) record.get( fieldName );
		}
		emailAddressByRecordIdAndFieldName.put( record.Id + fieldName, fieldValue );
		return fieldValue;
	}
	
	public void addSemikolonSeparatedQueryFields ( String semikolonSeparatedQueryFields ) {
		if ( semikolonSeparatedQueryFields != null ) {
			for ( String fieldName : semikolonSeparatedQueryFields.split( ';' ) ) {
				if ( !fieldName.contains( '$User' ) ) {
					fieldsToQuery.add( fieldName );
				}
			}
		}
	}
	
	private void loadEmailSettings () {
		emailSettingByDeveloperName = new Map<String, EmailEinstellung__mdt>();
		for ( EmailEinstellung__mdt emailSetting : [
				SELECT
						Id,
						DeveloperName,
						EmailVon__c,
						EmailCC__c,
						EmailAn__c,
						EmailAnZusaetzlich__c,
						EmailTemplate__c,
						EmailAnFeld__c,
						EmailVonFeld__c,
						EmailCcFeld__c
				FROM EmailEinstellung__mdt
				WHERE DeveloperName IN :emailSettingNames
		] ) {
			addSemikolonSeparatedQueryFields( emailSetting.EmailVonFeld__c );
			addSemikolonSeparatedQueryFields( emailSetting.EmailAnFeld__c );
			addSemikolonSeparatedQueryFields( emailSetting.EmailCcFeld__c );
			fieldsToQuery.remove( null );
			emailSettingByDeveloperName.put( emailSetting.DeveloperName, emailSetting );
		}
	}
	
	private String returnEmptyIfNull ( String value ) {
		return value == null ? '' : value;
	}
	
	private void setFromAddresses ( Request request, EmailDispatcherService.Message message ) {
		EmailEinstellung__mdt emailEinstellung = emailSettingByDeveloperName.get( request.emailSettingName );
		if ( emailEinstellung.EmailVonFeld__c != null ) {
			for ( String fieldName : emailEinstellung.EmailVonFeld__c.split( ';' ) ) {
				if ( fieldName.contains( '$User' ) ) {
					message.fromAddresses += returnEmptyIfNull( UserInfo.getUserEmail() ) + ';';
				}
				else if ( emailAddressByRecordIdAndFieldName.containsKey( request.recordId + fieldName ) ) {
					message.fromAddresses += returnEmptyIfNull( emailAddressByRecordIdAndFieldName.get( request.recordId + fieldName ) ) + ';';
				}
				else {
					// Sonarqube -> do nothing
				}
			}
		}
		if ( emailEinstellung.EmailVon__c != null ) {
			message.fromAddresses += returnEmptyIfNull( emailEinstellung.EmailVon__c );
		}
		message.fromAddresses = message.fromAddresses.removeEnd( ';' );
	}
	
	private void setToAddresses ( Request request, EmailDispatcherService.Message message ) {
		EmailEinstellung__mdt emailEinstellung = emailSettingByDeveloperName.get( request.emailSettingName );
		if ( emailEinstellung.EmailAnFeld__c != null ) {
			for ( String fieldName : emailEinstellung.EmailAnFeld__c.split( ';' ) ) {
				if ( fieldName.contains( '$User' ) ) {
					message.toAddresses += returnEmptyIfNull( UserInfo.getUserEmail() ) + ';';
				}
				else if ( emailAddressByRecordIdAndFieldName.containsKey( request.recordId + fieldName ) ) {
					message.toAddresses += returnEmptyIfNull( emailAddressByRecordIdAndFieldName.get( request.recordId + fieldName ) ) + ';';
				}
				else {
					// Sonarqube -> do nothing
				}
			}
		}
		if ( emailEinstellung.EmailAn__c != null ) {
			message.toAddresses += returnEmptyIfNull( emailEinstellung.EmailAn__c );
		}
		if ( emailEinstellung.EmailAnZusaetzlich__c != null ) {
			message.toAddresses = returnEmptyIfNull( message.toAddresses ) + ';' + returnEmptyIfNull( emailEinstellung.EmailAnZusaetzlich__c );
		}
		if ( request.additionalAddresses != null ) {
			message.toAddresses = returnEmptyIfNull( message.toAddresses ) + ';' + returnEmptyIfNull( request.additionalAddresses );
		}
		message.toAddresses = message.toAddresses.removeEnd( ';' );
	}
	
	private void setCcAddresses ( Request request, EmailDispatcherService.Message message ) {
		EmailEinstellung__mdt emailEinstellung = emailSettingByDeveloperName.get( request.emailSettingName );
		if ( emailEinstellung.EmailCcFeld__c != null ) {
			for ( String fieldName : emailEinstellung.EmailCcFeld__c.split( ';' ) ) {
				if ( fieldName.contains( '$User' ) ) {
					message.ccAddresses += returnEmptyIfNull( UserInfo.getUserEmail() ) + ';';
				}
				else if ( emailAddressByRecordIdAndFieldName.containsKey( request.recordId + fieldName ) ) {
					message.ccAddresses += returnEmptyIfNull( emailAddressByRecordIdAndFieldName.get( request.recordId + fieldName ) ) + ';';
				}
				else {
					// Sonarqube -> do nothing
				}
			}
		}
		if ( emailEinstellung.EmailCC__c != null ) {
			message.ccAddresses += returnEmptyIfNull( emailEinstellung.EmailCC__c );
		}
		message.ccAddresses = message.ccAddresses.removeEnd( ';' );
	}
	
	private void processRequest ( Request request ) {
		if ( objectName == 'Task' && request.emailTemplateRecordId == null ) {
			throw new DmlException( 'request.emailTemplateRecordId undefined for task record.' );
		}
		if ( request.accountId == null
				&& request.leadId == null
				&& request.fnaeId == null ) {
			throw new DmlException( 'request.relatedRecordId undefined.' );
		}
		if ( request.recordId == null ) {
			throw new DmlException( 'request.recordId undefined.' );
		}
		if ( request.emailSettingName == null ) {
			throw new DmlException( 'request.emailSettingName undefined.' );
		}
		EmailEinstellung__mdt emailEinstellung = emailSettingByDeveloperName.get( request.emailSettingName );
		EmailDispatcherService.Message message = new EmailDispatcherService.Message();
		message.documentName = request.documentName != null ? request.documentName : request.emailSettingName;
		message.selectedFileIds = '';
		message.emailTemplateRecordId = request.emailTemplateRecordId != null
				? request.emailTemplateRecordId
				: request.recordId;
		setFromAddresses( request, message );
		setToAddresses( request, message );
		setCcAddresses( request, message );
		message.emailTemplateDeveloperName = emailEinstellung.EmailTemplate__c;
		message.leadId = request.leadId;
		message.accountId = request.accountId;
		message.contractId = request.contractId;
		message.fnaeId = request.fnaeId;
		message.selectedFileIds = request.selectedFileIds;
		messages.add( message );
	}
	
	private void startBatchByObject () {
		
		Map<String, List<Request>> requestsByObjects = new Map<String, List<Request>>();
		for ( Request request : requests ) {
			String objectName = request.recordId.getSobjectType().getDescribe().name;
			if ( requestsByObjects.containsKey( objectName ) ) {
				requestsByObjects.get( objectName ).add( request );
			}
			else {
				requestsByObjects.put( objectName, new List<Request> {
						request
				} );
			}
		}
		for ( String objectName : requestsByObjects.keySet() ) {
			Database.executeBatch(
					new EmailSettingBatch( setRequestsByRecordIds(requestsByObjects.get(objectName)),
							'EmailSettingService - ' + objectName,
							objectName ),
					BatchJobSetting.getDefaultBatchSize()
			);
		}
	}
	
	public class Request {
		public Id recordId = null;
		public String emailSettingName = null;
		public String additionalAddresses = null;
		public Id leadId = null;
		public Id accountId = null;
		public Id contractId = null;
		public Id fnaeId = null;
		public Id emailTemplateRecordId = null;
		public String documentName = null;
		public String selectedFileIds = null;
	}
}