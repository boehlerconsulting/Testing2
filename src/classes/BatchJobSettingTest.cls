/**
 *@author       Mats Böhler
 *@created      01.12.2020
 *
 *
 *@description  BatchJobSettingTest
 *
 *
 *@changelog    01.12.2020 Mats Böhler  - Created
 *              
 * 
 */
@IsTest
private class BatchJobSettingTest {
	
	@IsTest
	static void testDefault () {
		
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			Test.startTest();
			Integer defaultBatchSize = BatchJobSetting.getDefaultBatchSize();
			Test.stopTest();
			
			System.assertNotEquals( null, defaultBatchSize );
		}
	}
	
	@IsTest
	static void testSpecific () {
		
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			Test.startTest();
			Integer defaultBatchSize = BatchJobSetting.getBatchSize('RecordDeleterBatch');
			Test.stopTest();
			
			System.assertNotEquals( null, defaultBatchSize );
		}
	}
}