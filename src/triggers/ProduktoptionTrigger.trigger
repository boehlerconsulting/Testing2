/**
 *@author       Mats Böhler
 *@created      16.08.2021
 *
 *
 *@description  ProduktoptionTrigger
 *
 *
 *@changelog    16.08.2021 Mats Böhler  - Created
 *              
 * 
 */
trigger ProduktoptionTrigger on Produktoption__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
	
	if ( TriggerService.isActive( 'ProduktoptionTrigger' ) ) {
		new ProduktoptionTriggerHandler().run();
	}
}