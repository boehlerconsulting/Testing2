/**
 *@author       Mats Böhler
 *@created      10.08.2020
 *
 *
 *@description  TriggerServiceTest
 *
 *
 *@changelog    10.08.2020 Mats Böhler  - Created
 *              
 * 
 */
@IsTest
private class TriggerServiceTest {
	@IsTest
	static void testLoad () {
		
		Test.startTest();
		TriggerEinstellung__mdt triggerEinstellung = TriggerService.getSetting( 'Post_AccountTrigger' );
		Test.stopTest();
		
		System.assertNotEquals( null, triggerEinstellung );
	}
}