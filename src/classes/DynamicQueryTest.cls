/**
 *@author       Mats Böhler
 *@created      18.11.2021
 *
 *
 *@description  DynamicQueryTest
 *
 *
 *@changelog    18.11.2021 Mats Böhler  - Created
 *              
 * 
 */
@IsTest
private class DynamicQueryTest {
	
	@IsTest
	static void testRemoveRestrictedCharacters () {
	
		String searchTerm = '_Test%';
		
		Test.startTest();
		searchTerm = DynamicQuery.removeRestrictedCharacters(searchTerm);
		Test.stopTest();
		
		System.assertEquals('Test', searchTerm);
	}
}