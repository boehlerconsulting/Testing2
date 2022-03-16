/**
 *@author       Mats Böhler
 *@created      29.10.2020
 *
 *
 *@description  FileNameReplacerTest
 *
 *
 *@changelog    29.10.2020 Mats Böhler  - Created
 *              
 * 
 */
@IsTest
private class FileNameReplacerTest {
	@IsTest
	static void testReplacement () {
		
		Test.startTest();
		String fileName = '123ÖäÜß+*#';
		fileName = FileNameReplacer.replace( fileName );
		Test.stopTest();
		
		System.assertEquals( '123OeaeUess+*_', fileName );
	}
}