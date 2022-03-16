/**
 *@author       Mats Böhler
 *@created      17.03.2021
 *
 *
 *@description  LeitregionMapperTest
 *
 *
 *@changelog    17.03.2021 Mats Böhler  - Created
 *              
 * 
 */
@IsTest
private class LeitregionMapperTest {
	
	@IsTest
	static void testGetKoordinatorForPostalCode () {
		
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			createLeitregionenMappingEntries( new List<String> {
					'11,12'
			} );
			Lead lead = createPackstationLead();
			
			Test.startTest();
			lead.PostalCode = '11111';
			Test.stopTest();
			
			System.assertEquals( [
					SELECT
							Id
					FROM User
					WHERE IstSchnittstellenbenutzer__c = TRUE
					LIMIT 1
			].Id, [
					SELECT
							OwnerId
					FROM Lead
					WHERE Id = :lead.Id
					LIMIT 1
			].OwnerId );
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
	
	private static void createLeitregionenMappingEntries ( List<String> leitregionen ) {
		List<OrgE_DP__c> orgEDPS = new List<OrgE_DP__c>();
		String recordType = Schema.SObjectType.OrgE_DP__c.getRecordTypeInfosByDeveloperName()
				.get( 'NL_Brief' ).getRecordTypeId();
		Id interfaceUser = [ SELECT Id FROM User WHERE IstSchnittstellenbenutzer__c = TRUE LIMIT 1 ].Id;
		for ( String leitregion : leitregionen ) {
			orgEDPS.add(
					new OrgE_DP__c(
							RecordTypeId = recordType,
							Leitregion__c = leitregion,
							Koordinator__c = interfaceUser
					)
			);
		}
		insert orgEDPS;
	}
}