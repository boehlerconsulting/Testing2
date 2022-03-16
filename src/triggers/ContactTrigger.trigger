/**
 *@author       Mats Böhler
 *@created      13.01.2021
 *
 *
 *@description  ContactTrigger
 *
 *
 *@changelog    13.01.2021 Mats Böhler  - Created
 *              
 * 
 */
trigger ContactTrigger on Contact (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
	
	if ( TriggerService.isActive( 'ContactTrigger' ) ) {
		new ContactTriggerHandler().run();
	}
}