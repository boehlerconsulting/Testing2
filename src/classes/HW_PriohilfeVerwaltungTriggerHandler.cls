/**
 *@author       Mats Böhler
 *@created      12.09.2019
 *@version      1.0
 *@since        45.0
 *
 *
 *@description  HW_PriohilfeVerwaltungTriggerHandler
 *
 *
 *@changelog    12.09.2019 Mats Böhler  - Created
 *              
 * 
 */
public without sharing class HW_PriohilfeVerwaltungTriggerHandler {
	
	private List<PriohilfeVerwaltung__c> newRecords = null;
	private Set<String> activeTaskTypes = new Set<String>();
	
	public HW_PriohilfeVerwaltungTriggerHandler () {
		
		this.newRecords = ( List<PriohilfeVerwaltung__c> ) Trigger.new;
	}
	
	public void matchTaskType () {
		
		loadActiveTaskTypes();
		
		for ( PriohilfeVerwaltung__c priohilfeVerwaltung : newRecords ) {
			priohilfeVerwaltung.Aufgabenart__c = priohilfeVerwaltung.AufgabenartGlobal__c;
			if ( !taskTypeMatches( priohilfeVerwaltung ) ) {
				
				priohilfeVerwaltung.addError( Label.AufgabenartStimmtNichtUeberein );
			}
		}
	}
	
	private Boolean taskTypeMatches ( PriohilfeVerwaltung__c priohilfeVerwaltung ) {
		return activeTaskTypes.contains( priohilfeVerwaltung.Aufgabenart__c );
	}
	
	private void loadActiveTaskTypes () {
		
		for ( PicklistEntry picklistEntry : Task.Aufgabenart__c.getDescribe().getPicklistValues() ) {
			if ( picklistEntry.isActive() ) {
				activeTaskTypes.add( picklistEntry.getValue() );
			}
		}
	}
}