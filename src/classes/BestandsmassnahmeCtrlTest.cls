/**
 *@author       Mats Böhler
 *@created      01.09.2021
 *
 *
 *@description  BestandsmassnahmeCtrlTest
 *
 *
 *@changelog    01.09.2021 Mats Böhler  - Created
 *              
 * 
 */
@IsTest
private class BestandsmassnahmeCtrlTest {
	
	@IsTest
	static void testCreateLead () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			Lead lead = createPackstationLead();
			
			Account account = ( Account ) TestFactory.createSObject(
					new Account(
							Lead__c = lead.Id,
							Bestandsmassnahme__c = 'Entlastung (Erweiterung / Austausch)'
					),
					true
			);
			
			Test.startTest();
			BestandsmassnahmeCtrl.createLead( account.Id, JSON.serialize( account ) );
			BestandsmassnahmeCtrl.saveAccount( account.Id, JSON.serialize( account ) );
			Test.stopTest();
			
			System.assertEquals( 1, [ SELECT Id FROM Lead ].size() );
		}
	}
	
	@IsTest
	static void testCreateLeadFailure () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			Test.startTest();
			try {
				BestandsmassnahmeCtrl.createLead( null, '' );
			}
			catch ( Exception e ) {
				System.assertEquals( 0, [ SELECT Id FROM Lead ].size() );
			}
			Test.stopTest();
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