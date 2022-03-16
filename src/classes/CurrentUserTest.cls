/**
 *@author       Mats Böhler
 *@created      17.11.2021
 *
 *
 *@description  CurrentUserTest
 *
 *
 *@changelog    17.11.2021 Mats Böhler  - Created
 *              
 * 
 */
@IsTest
private class CurrentUserTest {
	@IsTest
	static void testGetId () {
		
		Test.startTest();
		Id userId = CurrentUser.getInstance().getId();
		CurrentUser.getInstance().getUser();
		CurrentUser.getInstance().getProfile();
		Test.stopTest();
		
		System.assertNotEquals( null, userId );
	}
}