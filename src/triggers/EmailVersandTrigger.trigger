/**
 *@author       Mats Böhler
 *@created      16.05.2020
 *
 *
 *@description  EmailVersandTrigger
 *
 *
 *@changelog    16.05.2020 Mats Böhler  - Created
 *              
 * 
 */
trigger EmailVersandTrigger on EmailVersand__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
	
	if ( TriggerService.isActive( 'EmailVersandTrigger' ) ) {
		new EmailVersandTriggerHandler().run();
	}
}