/**
 *@author       Mats Böhler
 *@created      30.08.2021
 *
 *
 *@description  ProductTrigger
 *
 *
 *@changelog    30.08.2021 Mats Böhler  - Created
 *              
 * 
 */
trigger ProductTrigger on Product2 (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
	
	if ( TriggerService.isActive( 'ProductTrigger' ) ) {
		new ProductTriggerHandler().run();
	}
}