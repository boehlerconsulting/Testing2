/**
 *@author       Mats Böhler
 *@created      01.12.2020
 *
 *
 *@description  EmailDispatcherBatchTest
 *
 *
 *@changelog    01.12.2020 Mats Böhler  - Created
 *              
 * 
 */
@IsTest
private class EmailSettingBatchTest {
	
	@IsTest
	static void testSuccess () {
		
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			Lead lead = createPackstationLead();
			EmailSettingService.Request request = new EmailSettingService.Request();
			request.recordId = lead.Id;
			request.emailSettingName = 'WeidenEignung';
			request.leadId = lead.Id;
			EmailSettingService.getInstance().requests.add( request );
			
			Test.startTest();
			Database.executeBatch(
					new EmailSettingBatch( EmailSettingService.getInstance().setRequestsByRecordIds(
							EmailSettingService.getInstance().requests
					),
							'Packstation - Emails Weiden / Kommune',
							'Lead' ),
					BatchJobSetting.getDefaultBatchSize()
			);
			Test.stopTest();
			
			System.assertEquals( 1, [
					SELECT
							Id
					FROM EmailVersand__c
					WHERE Dokument__c = 'WeidenEignung'
			].size() );
		}
	}
	
	private static Lead createPackstationLead () {
		Lead lead = ( Lead ) TestFactory.createSObject(
				new Lead(
						RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName()
								.get( 'Packstation' ).getRecordTypeId(),
						PostalCode = '12345'
				),
				true
		);
		return lead;
	}
}