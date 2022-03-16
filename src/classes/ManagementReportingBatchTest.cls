/**
 *@author       Mats Böhler
 *@created      23.11.2020
 *
 *
 *@description  ManagementReportingBatchTest
 *
 *
 *@changelog    23.11.2020 Mats Böhler  - Created
 *              
 * 
 */
@IsTest
private class ManagementReportingBatchTest {
	
	@IsTest
	static void testBatch () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			createPackstationLead();
			
			Test.startTest();
			Database.executeBatch( new ManagementReportingBatch (), 200 );
			Test.stopTest();
		}
	}
	
	@IsTest
	static void testSchedule () {
		
		Test.startTest();
		System.schedule( 'ManagementReportingBatchTest', '0 0 13 * * ? *', new ManagementReportingBatch() );
		Test.stopTest();
	}
	
	private static Lead createPackstationLead () {
		Lead lead = ( Lead ) TestFactory.createSObject(
				new Lead(
						RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName()
								.get( 'Packstation' ).getRecordTypeId(),
						PostalCode = '12345',
						go_live__c = Date.today()
				),
				true
		);
		return lead;
	}
}