/**
 *@author       Mats Böhler
 *@created      11.10.2019
 *@version      1.0
 *@since        45.0
 *
 *
 *@description  HW_RoleValidator_T
 *
 *
 *@changelog    11.10.2019 Mats Böhler  - Created
 *              
 * 
 */
@IsTest
private class HW_RoleValidator_T {
	
	@IsTest
	static void testVertriebsleiter () {
		
		User vertriebsleiter = Post_TestTools.createUser( 'myPM Vertrieb (VL) - MFA', 'Berlin_Vertriebsleiter_koordinator' );
		
		System.runAs( vertriebsleiter ) {
			Test.startTest();
			String role = new HW_RoleValidator().getPriorisierungshilfeRole();
			Test.stopTest();
			
			System.assertEquals( 'VL', role );
		}
	}
	
	@IsTest
	static void testVertriebskoordinator () {
		
		User vertriebsleiter = Post_TestTools.createUser( 'myPM Vertrieb (VK)', 'Berlin_Vertriebsleiter_koordinator' );
		
		System.runAs( vertriebsleiter ) {
			Test.startTest();
			String role = new HW_RoleValidator().getPriorisierungshilfeRole();
			Test.stopTest();
			
			System.assertEquals( 'VK', role );
		}
	}
	
	@IsTest
	static void testVertriebsmanager () {
		
		User vertriebsleiter = Post_TestTools.createUser( 'myPM Vertrieb (VK)', 'Berlin_Vertriebsmanager' );
		
		System.runAs( vertriebsleiter ) {
			Test.startTest();
			String role = new HW_RoleValidator().getPriorisierungshilfeRole();
			Test.stopTest();
			
			System.assertEquals( 'VM', role );
		}
	}
	
	@IsTest
	static void testAdmin () {
		
		Test.startTest();
		String role = new HW_RoleValidator().getPriorisierungshilfeRole();
		Test.stopTest();
		
		System.assertEquals( 'VL', role );
	}
}