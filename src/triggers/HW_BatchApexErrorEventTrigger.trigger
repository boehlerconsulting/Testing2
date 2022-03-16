/**
 *@author       Mats Böhler
 *@created      19.09.2019
 *@version      1.0
 *@since        45.0
 *
 *
 *@description  HW_BatchApexErrorEventTrigger
 *
 *
 *@changelog    19.09.2019 Mats Böhler  - Created
 *              
 * 
 */
trigger HW_BatchApexErrorEventTrigger on BatchApexErrorEvent (after insert) {
	
	new HW_ErrorLogging().logBatchException( ( List<BatchApexErrorEvent> ) Trigger.new );
}