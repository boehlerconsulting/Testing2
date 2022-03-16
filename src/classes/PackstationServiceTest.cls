/**
 *@author       Mats Böhler
 *@created      01.09.2021
 *
 *
 *@description  PackstationServiceTest
 *
 *
 *@changelog    01.09.2021 Mats Böhler  - Created
 *              
 * 
 */
@IsTest
private class PackstationServiceTest {

	@IsTest
	static void testCreateLeadsEntlastung () {
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
			new PackstationService().createLeads( new Set<Id> {
					account.Id
			} );
			Test.stopTest();
			
			System.assertEquals( 2, [ SELECT Id FROM Lead ].size() );
		}
	}
	
	@IsTest
	static void testCreateLeadsFormatwechsel () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			Lead lead = createPackstationLead();
			
			Account account = ( Account ) TestFactory.createSObject(
					new Account(
							Lead__c = lead.Id,
							Bestandsmassnahme__c = 'Formatwechsel (Pack-/Poststation)'
					),
					true
			);
			
			Test.startTest();
			new PackstationService().createLeads( new Set<Id> {
					account.Id
			} );
			Test.stopTest();
			
			System.assertEquals( 2, [ SELECT Id FROM Lead ].size() );
		}
	}
	
	@IsTest
	static void testCreateLeadsAutomatentausch () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			Lead lead = createPackstationLead();
			
			Account account = ( Account ) TestFactory.createSObject(
					new Account(
							Lead__c = lead.Id,
							Bestandsmassnahme__c = 'Automatentausch'
					),
					true
			);
			
			Test.startTest();
			new PackstationService().createLeads( new Set<Id> {
					account.Id
			} );
			Test.stopTest();
			
			System.assertEquals( 3, [ SELECT Id FROM Lead ].size() );
		}
	}
	
	@IsTest
	static void testCreateLeadsAbbau () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			Lead lead = createPackstationLead();
			
			Account account = ( Account ) TestFactory.createSObject(
					new Account(
							Lead__c = lead.Id,
							Bestandsmassnahme__c = 'Abbau'
					),
					true
			);
			
			Test.startTest();
			new PackstationService().createLeads( new Set<Id> {
					account.Id
			} );
			Test.stopTest();
			
			System.assertEquals( 2, [ SELECT Id FROM Lead ].size() );
		}
	}
	
	@IsTest
	static void testCreateLeadsKuendigung () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			Lead lead = createPackstationLead();
			
			Account account = ( Account ) TestFactory.createSObject(
					new Account(
							Lead__c = lead.Id,
							Bestandsmassnahme__c = 'Kündigung'
					),
					true
			);
			
			Test.startTest();
			new PackstationService().createLeads( new Set<Id> {
					account.Id
			} );
			Test.stopTest();
			
			System.assertEquals( 2, [ SELECT Id FROM Lead ].size() );
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