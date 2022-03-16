/**
 *@author       Mats Böhler
 *@created      26.04.2019
 *@version      1.0
 *@since        45.0
 *
 *
 *@description  HW_LeadTrigger
 *
 *
 *@changelog    26.04.2019 Mats Böhler  - Created
 *              
 * 
 */
trigger HW_LeadTrigger on Lead (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
	
	if ( TriggerService.isActive( 'HW_LeadTrigger' ) ) {
		new LeadTriggerHandler().run();
	}
}