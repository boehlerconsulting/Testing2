/**
 *@author       Mats Böhler
 *@created      13.06.2020
 *
 *
 *@description  AnlagennummerTrigger
 *
 *
 *@changelog    13.06.2020 Mats Böhler  - Created
 *              
 * 
 */
trigger AnlagennummerTrigger on Anlagennummer__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
	
	if ( TriggerService.isActive( 'AnlagennummerTrigger' ) ) {
		new AnlagennummerTriggerHandler().run();
	}
}