/**
 *@author       Mats Böhler
 *@created      13.01.2021
 *
 *
 *@description  ContactTriggerHandler
 *
 *
 *@changelog    13.01.2021 Mats Böhler  - Created
 *              
 * 
 */
public without sharing class ContactTriggerHandler extends TriggerHandler {
	
	private List<Contact> newContacts;
	private Map<Id, Contact> newContactMap;
	private Map<Id, Contact> oldContactMap;
	
	public ContactTriggerHandler () {
		this.newContacts = ( List<Contact> ) Trigger.new;
		this.newContactMap = ( Map<Id, Contact> ) Trigger.newMap;
		this.oldContactMap = ( Map<Id, Contact> ) Trigger.oldMap;
	}
	
	protected override void beforeInsert () {
		
		for ( Contact contact : newContacts ) {
			emptySalutationFields( contact );
		}
	}
	
	protected override void afterInsert () {
		
		setActiveFlagOnQualifizierungsteilnehmer();
	}
	
	protected override void beforeUpdate () {
		
		for ( Contact contact : newContacts ) {
			emptySalutationFields( contact );
		}
	}
	
	protected override void afterUpdate () {
		
		setActiveFlagOnQualifizierungsteilnehmer();
	}
	
	private void emptySalutationFields ( Contact contact ) {
		contact.Salutation = null;
	}
	
	private void setActiveFlagOnQualifizierungsteilnehmer () {
		List<Qualifizierungsteilnehmer__c> qualifizierungsteilnehmers = new List<Qualifizierungsteilnehmer__c>();
		for ( Qualifizierungsteilnehmer__c qualifizierungsteilnehmer : [
				SELECT
						Id,
						Filialmitarbeiter__c,
						IstAktiv__c
				FROM Qualifizierungsteilnehmer__c
				WHERE Filialmitarbeiter__c IN :newContacts
		] ) {
			Contact filialmitarbeiter = newContactMap.get( qualifizierungsteilnehmer.Filialmitarbeiter__c );
			qualifizierungsteilnehmer.IstAktiv__c = filialmitarbeiter.ZORA_Karte_geloescht_am__c == null;
			qualifizierungsteilnehmers.add( qualifizierungsteilnehmer );
		}
		update qualifizierungsteilnehmers;
	}
}