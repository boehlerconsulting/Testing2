/**
 *@author       Mats Böhler
 *@created      10.02.2022
 *
 *
 *@description  LoginHistoryCtrlTest
 *
 *
 *@changelog    10.02.2022 Mats Böhler  - Created
 *              
 * 
 */
@IsTest
private class LoginHistoryCtrlTest {
	
	@IsTest
	static void testBehavior () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			Test.startTest();
			String instanceString = LoginHistoryCtrl.loadData();
			Test.stopTest();
			
			System.assertNotEquals( null, instanceString );
		}
	}
}