/**
 *@author       Mats Böhler
 *@created      12.09.2019
 *@version      1.0
 *@since        45.0
 *
 *
 *@description  HW_PriohilfeVerwaltungTrigger
 *
 *
 *@changelog    12.09.2019 Mats Böhler  - Created
 *              
 * 
 */
trigger HW_PriohilfeVerwaltungTrigger on PriohilfeVerwaltung__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
	
	if ( TriggerService.isActive( 'HW_PriohilfeVerwaltungTrigger' ) ) {
		if ( Trigger.isBefore ) {
			if ( Trigger.isInsert ) {
				new HW_PriohilfeVerwaltungTriggerHandler().matchTaskType();
			}
		}
		if ( Trigger.isBefore ) {
			if ( Trigger.isUpdate ) {
				new HW_PriohilfeVerwaltungTriggerHandler().matchTaskType();
			}
		}
	}
}