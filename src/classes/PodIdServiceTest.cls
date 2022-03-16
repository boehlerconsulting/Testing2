/**
 *@author       Mats Böhler
 *@created      02.08.2021
 *
 *
 *@description  PodIdServiceTest
 *
 *
 *@changelog    02.08.2021 Mats Böhler  - Created
 *              
 * 
 */
@IsTest
private class PodIdServiceTest {
	
	@IsTest
	static void testNoExistingPODID () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			String postalCode = '10115';
			
			Lead lead = createPackstationLead( postalCode, 'Berlin', null, null );
			
			Test.startTest();
			Map<Id, PODID__c> podIdByLeadIds = new PodIdService().generate( new Set<Id> {
					lead.Id
			} );
			Test.stopTest();
			
			System.assertEquals( postalCode + '101', podIdByLeadIds.get( lead.Id ).Wert__c );
		}
	}
	
	@IsTest
	static void testNoExistingPODIDCityUniqueness () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			String postalCode = '10115';
			
			createPODIDs( 101, 101, postalCode, 'Berlin' );
			createPODIDs( 102, 102, '10178', 'Berlin' );
			
			Lead lead = createPackstationLead( postalCode, 'Berlin', null, null );
			
			Test.startTest();
			Map<Id, PODID__c> podIdByLeadIds = new PodIdService().generate( new Set<Id> {
					lead.Id
			} );
			Test.stopTest();
			
			System.assertEquals( postalCode + '103', podIdByLeadIds.get( lead.Id ).Wert__c );
		}
	}
	
	@IsTest
	static void testNoExistingPODIDPoststation () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			String postalCode = '10115';
			
			Lead lead = createPackstationLead( postalCode, 'Berlin', 'Poststation', null );
			
			Test.startTest();
			Map<Id, PODID__c> podIdByLeadIds = new PodIdService().generate( new Set<Id> {
					lead.Id
			} );
			Test.stopTest();
			
			System.assertEquals( postalCode + '701', podIdByLeadIds.get( lead.Id ).Wert__c );
		}
	}
	
	@IsTest
	static void testNoExistingPODIDPrototyp () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			String postalCode = '10115';
			
			Lead lead = createPackstationLead( postalCode, 'Berlin', 'Prototyp', null );
			
			Test.startTest();
			Map<Id, PODID__c> podIdByLeadIds = new PodIdService().generate( new Set<Id> {
					lead.Id
			} );
			Test.stopTest();
			
			System.assertEquals( postalCode + '901', podIdByLeadIds.get( lead.Id ).Wert__c );
		}
	}
	
	@IsTest
	static void testNoExistingPODIDOeffentlicherZugang () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			String postalCode = '10115';
			
			Lead lead = createPackstationLead( postalCode, 'Berlin', null, 'Nein' );
			
			Test.startTest();
			Map<Id, PODID__c> podIdByLeadIds = new PodIdService().generate( new Set<Id> {
					lead.Id
			} );
			Test.stopTest();
			
			System.assertEquals( postalCode + '801', podIdByLeadIds.get( lead.Id ).Wert__c );
		}
	}
	
	@IsTest
	static void testWithExistingPODID () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			String postalCode = '10115';
			String city = 'Berlin';
			
			createPODIDs( 199, 199, postalCode, city );
			
			Lead lead = createPackstationLead( postalCode, city, null, null );
			
			Test.startTest();
			Map<Id, PODID__c> podIdByLeadIds = new PodIdService().generate( new Set<Id> {
					lead.Id
			} );
			Test.stopTest();
			
			System.assertEquals( postalCode + '201', podIdByLeadIds.get( lead.Id ).Wert__c );
		}
	}
	
	@IsTest
	static void testWithExistingPODIDNoZero () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			String postalCode = '10115';
			String city = 'Berlin';
			
			createPODIDs( 109, 109, postalCode, city );
			
			Lead lead = createPackstationLead( postalCode, city, null, null );
			
			Test.startTest();
			Map<Id, PODID__c> podIdByLeadIds = new PodIdService().generate( new Set<Id> {
					lead.Id
			} );
			Test.stopTest();
			
			System.assertEquals( postalCode + '111', podIdByLeadIds.get( lead.Id ).Wert__c );
		}
	}
	
	@IsTest
	static void testWithExistingPODIDNoThree () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			String postalCode = '10115';
			String city = 'Berlin';
			
			createPODIDs( 299, 299, postalCode, city );
			
			Lead lead = createPackstationLead( postalCode, city, null, null );
			
			Test.startTest();
			Map<Id, PODID__c> podIdByLeadIds = new PodIdService().generate( new Set<Id> {
					lead.Id
			} );
			Test.stopTest();
			
			System.assertEquals( postalCode + '401', podIdByLeadIds.get( lead.Id ).Wert__c );
		}
	}
	
	@IsTest
	static void testWithExistingPODIDPoststation () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			String postalCode = '10115';
			String city = 'Berlin';
			
			createPODIDs( 701, 709, postalCode, city );
			
			Lead lead = createPackstationLead( postalCode, city, 'Poststation', null );
			
			Test.startTest();
			Map<Id, PODID__c> podIdByLeadIds = new PodIdService().generate( new Set<Id> {
					lead.Id
			} );
			Test.stopTest();
			
			System.assertEquals( postalCode + '711', podIdByLeadIds.get( lead.Id ).Wert__c );
		}
	}
	
	@IsTest
	static void testWithExistingPODIDPrototyp () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			String postalCode = '10115';
			String city = 'Berlin';
			
			createPODIDs( 901, 909, postalCode, city );
			
			Lead lead = createPackstationLead( postalCode, city, 'Prototyp', null );
			
			Test.startTest();
			Map<Id, PODID__c> podIdByLeadIds = new PodIdService().generate( new Set<Id> {
					lead.Id
			} );
			Test.stopTest();
			
			System.assertEquals( postalCode + '911', podIdByLeadIds.get( lead.Id ).Wert__c );
		}
	}
	
	@IsTest
	static void testWithExistingPODIDOeffentlicherZugang () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			String postalCode = '10115';
			String city = 'Berlin';
			
			createPODIDs( 801, 809, postalCode, city );
			
			Lead lead = createPackstationLead( postalCode, 'Berlin', null, 'Nein' );
			
			Test.startTest();
			Map<Id, PODID__c> podIdByLeadIds = new PodIdService().generate( new Set<Id> {
					lead.Id
			} );
			Test.stopTest();
			
			System.assertEquals( postalCode + '811', podIdByLeadIds.get( lead.Id ).Wert__c );
		}
	}
	
	@IsTest
	static void testWithExistingPODIDLueckenfueller () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			String postalCode = '10115';
			String city = 'Berlin';
			
			createPODIDs( 101, 109, postalCode, city );
			createPODIDs( 699, 699, postalCode, city );
			
			Lead lead = createPackstationLead( postalCode, city, null, null );
			
			Test.startTest();
			Map<Id, PODID__c> podIdByLeadIds = new PodIdService().generate( new Set<Id> {
					lead.Id
			} );
			Test.stopTest();
			
			System.assertEquals( postalCode + '111', podIdByLeadIds.get( lead.Id ).Wert__c );
		}
	}
	
	@IsTest
	static void testWithExistingPODIDPoststationLueckenfueller () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			String postalCode = '10115';
			String city = 'Berlin';
			
			createPODIDs( 701, 709, postalCode, city );
			createPODIDs( 799, 799, postalCode, city );
			
			Lead lead = createPackstationLead( postalCode, city, 'Poststation', null );
			
			Test.startTest();
			Map<Id, PODID__c> podIdByLeadIds = new PodIdService().generate( new Set<Id> {
					lead.Id
			} );
			Test.stopTest();
			
			System.assertEquals( postalCode + '711', podIdByLeadIds.get( lead.Id ).Wert__c );
		}
	}
	
	@IsTest
	static void testWithExistingPODIDPrototypLueckenfueller () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			String postalCode = '10115';
			String city = 'Berlin';
			
			createPODIDs( 901, 909, postalCode, city );
			createPODIDs( 999, 999, postalCode, city );
			
			Lead lead = createPackstationLead( postalCode, city, 'Prototyp', null );
			
			Test.startTest();
			Map<Id, PODID__c> podIdByLeadIds = new PodIdService().generate( new Set<Id> {
					lead.Id
			} );
			Test.stopTest();
			
			System.assertEquals( postalCode + '911', podIdByLeadIds.get( lead.Id ).Wert__c );
		}
	}
	
	@IsTest
	static void testWithExistingPODIDOeffentlicherZugangLueckenfueller () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			String postalCode = '10115';
			String city = 'Berlin';
			
			createPODIDs( 801, 809, postalCode, city );
			createPODIDs( 899, 899, postalCode, city );
			
			Lead lead = createPackstationLead( postalCode, 'Berlin', null, 'Nein' );
			
			Test.startTest();
			Map<Id, PODID__c> podIdByLeadIds = new PodIdService().generate( new Set<Id> {
					lead.Id
			} );
			Test.stopTest();
			
			System.assertEquals( postalCode + '811', podIdByLeadIds.get( lead.Id ).Wert__c );
		}
	}
	
	@IsTest
	static void testWithExistingPODIDLeitregion () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			String postalCode = '10115';
			String postalCodeWithDifferentLeitregion = '12051';
			String city = 'Berlin';
			
			createPODIDs( 101, 109, postalCode, city );
			createPODIDs( 115, 699, postalCode, city );
			createPODIDs( 101, 699, postalCodeWithDifferentLeitregion, city );
			
			Lead lead = createPackstationLead( postalCode, city, null, null );
			
			Test.startTest();
			Map<Id, PODID__c> podIdByLeadIds = new PodIdService().generate( new Set<Id> {
					lead.Id
			} );
			Test.stopTest();
			
			System.assertEquals( postalCode + '111', podIdByLeadIds.get( lead.Id ).Wert__c );
		}
	}
	
	@IsTest
	static void testWithExistingPODIDPoststationLeitregion () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			String postalCode = '10115';
			String postalCodeWithDifferentLeitregion = '12051';
			String city = 'Berlin';
			
			createPODIDs( 701, 709, postalCode, city );
			createPODIDs( 715, 799, postalCode, city );
			createPODIDs( 701, 799, postalCodeWithDifferentLeitregion, city );
			
			Lead lead = createPackstationLead( postalCode, city, 'Poststation', null );
			
			Test.startTest();
			Map<Id, PODID__c> podIdByLeadIds = new PodIdService().generate( new Set<Id> {
					lead.Id
			} );
			Test.stopTest();
			
			System.assertEquals( postalCode + '711', podIdByLeadIds.get( lead.Id ).Wert__c );
		}
	}
	
	@IsTest
	static void testWithExistingPODIDPrototypLeitregion () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			String postalCode = '10115';
			String postalCodeWithDifferentLeitregion = '12051';
			String city = 'Berlin';
			
			createPODIDs( 901, 909, postalCode, city );
			createPODIDs( 915, 999, postalCode, city );
			createPODIDs( 901, 999, postalCodeWithDifferentLeitregion, city );
			
			Lead lead = createPackstationLead( postalCode, city, 'Prototyp', null );
			
			Test.startTest();
			Map<Id, PODID__c> podIdByLeadIds = new PodIdService().generate( new Set<Id> {
					lead.Id
			} );
			Test.stopTest();
			
			System.assertEquals( postalCode + '911', podIdByLeadIds.get( lead.Id ).Wert__c );
		}
	}
	
	@IsTest
	static void testWithExistingPODIDOeffentlicherZugangLeitregion () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			String postalCode = '10115';
			String postalCodeWithDifferentLeitregion = '12051';
			String city = 'Berlin';
			
			createPODIDs( 801, 809, postalCode, city );
			createPODIDs( 815, 899, postalCode, city );
			createPODIDs( 801, 899, postalCodeWithDifferentLeitregion, city );
			
			Lead lead = createPackstationLead( postalCode, 'Berlin', null, 'Nein' );
			
			Test.startTest();
			Map<Id, PODID__c> podIdByLeadIds = new PodIdService().generate( new Set<Id> {
					lead.Id
			} );
			Test.stopTest();
			
			System.assertEquals( postalCode + '811', podIdByLeadIds.get( lead.Id ).Wert__c );
		}
	}
	
	@IsTest
	static void testNoNumbersAvailable () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			String postalCode = '10115';
			String city = 'Berlin';
			
			createPODIDs( 801, 899, postalCode, city );
			
			Lead lead = createPackstationLead( postalCode, 'Berlin', null, 'Nein' );
			
			Test.startTest();
			Map<Id, PODID__c> podIdByLeadIds = new PodIdService().generate( new Set<Id> {
					lead.Id
			} );
			Test.stopTest();
			
			System.assert(!podIdByLeadIds.containsKey(lead.Id));
		}
	}
	
	private static void createPODIDs ( Integer startNumber, Integer endNumber, String postalCode, String city ) {
		List<PODID__c> podids = new List<PODID__c>();
		for ( Integer i = startNumber; i <= endNumber; i++ ) {
			podids.add( addPODID( postalCode + String.valueOf( i ), city ) );
		}
		insert podids;
	}
	
	private static PODID__c addPODID ( String value, String city ) {
		return new PODID__c(
				Name = value,
				Wert__c = value,
				Status__c = 'Vergeben',
				Ort__c = city
		);
	}
	
	private static Lead createPackstationLead ( String postalCode, String city, String type, String oeffentlicherZugang ) {
		Lead lead = ( Lead ) TestFactory.createSObject(
				new Lead(
						RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName()
								.get( 'Packstation' ).getRecordTypeId(),
						PostalCode = postalCode,
						City = city,
						ADM_Typ__c = type,
						Oeffentlicher_Zugang__c = oeffentlicherZugang
				),
				true
		);
		return lead;
	}
}