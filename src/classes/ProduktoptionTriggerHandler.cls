/**
 *@author       Mats Böhler
 *@created      16.08.2021
 *
 *
 *@description  ProduktoptionTriggerHandler
 *
 *
 *@changelog    16.08.2021 Mats Böhler  - Created
 *              
 * 
 */
public without sharing class ProduktoptionTriggerHandler extends TriggerHandler{
	
	private List<Produktoption__c> oldProduktoptionen = null;
	
	public ProduktoptionTriggerHandler () {
		
		this.oldProduktoptionen = ( List<Produktoption__c> ) Trigger.old;
	}
	
	public override void beforeDelete () {
		
		for ( Produktoption__c produktoption : oldProduktoptionen ) {
			produktoption.addError('Produktoptionen dürfen nur über den "Löschen" Button gelöscht werden.');
		}
	}
}