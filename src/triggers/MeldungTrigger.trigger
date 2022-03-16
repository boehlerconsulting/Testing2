/**
 *@author       Mats Böhler
 *@created      09.11.2020
 *
 *
 *@description  MeldungTrigger
 *
 *
 *@changelog    09.11.2020 Mats Böhler  - Created
 *              
 * 
 */
trigger MeldungTrigger on Meldung__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {

	new MeldungTriggerHandler().run();
}