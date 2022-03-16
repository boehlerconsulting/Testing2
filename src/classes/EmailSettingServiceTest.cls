/**
 *@author       Mats Böhler
 *@created      02.07.2020
 *
 *
 *@description  EmailSettingServiceTest
 *
 *
 *@changelog    02.07.2020 Mats Böhler  - Created
 *              
 * 
 */
@IsTest
private class EmailSettingServiceTest {
	
	@IsTest
	static void testExecute () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			Test.startTest();
			Lead lead = createLead('');
			EmailSettingService.Request request = new EmailSettingService.Request();
			request.recordId = lead.Id;
			request.emailSettingName = 'WeidenEingangsbestaetigung';
			request.leadId = lead.Id;
			EmailSettingService.getInstance().requests.add( request );
			EmailSettingService.getInstance().createMessages().callEmailDispatcherService();
			EmailSettingService.getInstance().requests.add( request );
			List<EmailVersand__c> emailVersands = EmailSettingService.getInstance().createMessages().getEmailDispatcherServiceDeliveries();
			insert emailVersands;
			Test.stopTest();
			
			System.assertEquals( 2, [
					SELECT
							Id
					FROM EmailVersand__c
					WHERE Dokument__c = 'WeidenEingangsbestaetigung'
			].size() );
		}
	}
	
	@IsTest
	static void testWeidenEingangsbestaetigung () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			Test.startTest();
			createLead('Weiden');
			Test.stopTest();
			
			System.assertEquals( 1, [
					SELECT
							Id
					FROM EmailVersand__c
					WHERE Dokument__c = 'WeidenEingangsbestaetigung'
			].size() );
		}
	}
	
	private static Lead createLead (String leadSource) {
		Lead lead = ( Lead ) TestFactory.createSObject(
				new Lead(
						RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName()
								.get( 'Packstation' ).getRecordTypeId(),
						Email = 'test@test.de',
						FirstName = 'firstName',
						LastName = 'lastName',
						Company = 'Company',
						LeadSource = leadSource
				),
				true
		);
		return lead;
	}
}