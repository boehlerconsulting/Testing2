/**
 *@author       Mats Böhler
 *@created      13.08.2020
 *
 *
 *@description  FilialnetzaenderungTrigger
 *
 *
 *@changelog    13.08.2020 Mats Böhler  - Created
 *              
 * 
 */
trigger FilialnetzaenderungTrigger on Filialnetzaenderung__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
	
	if ( TriggerService.isActive( 'FilialnetzaenderungTrigger' ) ) {
		new FilialnetzaenderungTriggerHandler().run();
	}
}