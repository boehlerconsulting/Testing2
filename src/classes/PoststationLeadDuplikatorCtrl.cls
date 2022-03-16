/**
 *@author       Mats Böhler
 *@created      02.02.2021
 *
 *
 *@description  PoststationLeadDuplikatorCtrl
 *
 *
 *@changelog    02.02.2021 Mats Böhler  - Created
 *              
 * 
 */
public without sharing class PoststationLeadDuplikatorCtrl {
	
	private Lead existingLead = new Lead();
	private String duplicatedLeadId;
	
	@AuraEnabled
	public static Id init ( String leadId ) {
		PoststationLeadDuplikatorCtrl instance = new PoststationLeadDuplikatorCtrl();
		Savepoint savepoint = Database.setSavepoint();
		try {
			instance.loadLead( leadId );
			if ( instance.isAllowedOperation() ) {
				instance.duplicatedLeadId = instance.duplicateLead();
				instance.existingLead.PoststationDuplizierterLead__c = instance.duplicatedLeadId;
				update instance.existingLead;
			}
			else {
				throw new PoststationLeadDuplikatorCtrlException( 'Sie sind nicht berechtigt den Lead zu duplizieren!' );
			}
		}
		catch ( Exception e ) {
			Database.rollback( savepoint );
			throw new AuraHandledException( e.getMessage() );
		}
		return instance.duplicatedLeadId;
	}
	
	private Boolean isAllowedOperation () {
		return FeatureManagement.checkPermission( 'PoststationLeadDuplizieren' )
				&& existingLead.Filialnetzaenderung__r.RecordType.DeveloperName == 'Filiale'
				&& existingLead.PoststationDuplizierterLead__c == null;
	}
	
	private void loadLead ( String leadId ) {
		String query = 'SELECT ';
		for ( Schema.FieldSetMember fieldSetMember : SObjectType.Lead.fieldSets.PoststationLeadDuplikator.getFields() ) {
			query += fieldSetMember.getFieldPath() + ',';
		}
		query += 'Filialnetzaenderung__r.RecordType.DeveloperName, PoststationDuplizierterLead__c ' +
				'FROM Lead WHERE Id = :leadId';
		existingLead = Database.query( query );
	}
	
	private Id duplicateLead () {
		Lead lead = new Lead();
		for ( Schema.FieldSetMember fieldSetMember : SObjectType.Lead.fieldSets.PoststationLeadDuplikator.getFields() ) {
			lead.put( fieldSetMember.getFieldPath(), existingLead.get( fieldSetMember.getFieldPath() ) );
		}
		lead.IstDuplikatPoststation__c = true;
		insert lead;
		return lead.Id;
	}
	
	public class PoststationLeadDuplikatorCtrlException extends Exception {
	}
}