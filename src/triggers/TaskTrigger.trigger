/**
 *@author       Mats Böhler
 *@created      12.09.2019
 *@version      1.1
 *@since        48.0
 *
 *
 *@description  TaskTrigger
 *
 *
 *@changelog    12.09.2019 Mats Böhler  - Created
 *              
 * 
 */
trigger TaskTrigger on Task (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
	
	if ( TriggerService.isActive( 'TaskTrigger' ) ) {
		new TaskTriggerHandler().run();
	}
}