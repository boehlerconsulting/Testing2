/**
 *@author       Mats Böhler
 *@created      21.09.2020
 *
 *
 *@description  MassenzuweisungFilterCriteriaTest
 *
 *
 *@changelog    21.09.2020 Mats Böhler  - Created
 *              
 * 
 */
@IsTest
private class MassenzuweisungFilterCriteriaTest {
	
	@IsTest
	static void testAccount () {
		
		List<String> filters = new List<String> {
				'Account', '', '', '', '', '', '', '', '', '', '100'
		};
		
		Test.startTest();
		MassenzuweisungFilterCriteria filterCriteria = new MassenzuweisungFilterCriteria( filters );
		Test.stopTest();
		
		System.assertEquals( filters[ 0 ], filterCriteria.getVersion() );
	}
	
	@IsTest
	static void testTask () {
		
		List<String> filters = new List<String> {
				'Task', '', '', '', '', '', '', '', '', '100'
		};
		
		Test.startTest();
		MassenzuweisungFilterCriteria filterCriteria = new MassenzuweisungFilterCriteria( filters );
		Test.stopTest();
		
		System.assertEquals( filters[ 0 ], filterCriteria.getVersion() );
	}
}