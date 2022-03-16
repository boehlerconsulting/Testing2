/**
 *@author       Mats Böhler
 *@created      28.04.2021
 *
 *
 *@description  InterfaceUserTest
 *
 *
 *@changelog    28.04.2021 Mats Böhler  - Created
 *              
 * 
 */
@IsTest
private class InterfaceUserTest {
	
	@IsTest
	static void testGetId () {
		
		Test.startTest();
		Id userId = InterfaceUser.getInstance().getId();
		InterfaceUser.getInstance().getUser();
		Test.stopTest();
		
		System.assertNotEquals( null, userId );
	}
}