/**
 *@author       Mats Böhler
 *@created      20.08.2020
 *
 *
 *@description  WartezeitrisikoDataCtrlTest
 *
 *
 *@changelog    20.08.2020 Mats Böhler  - Created
 *              
 * 
 */
@IsTest
private class WartezeitrisikoDataCtrlTest {
	
	@IsTest
	static void testLoadData () {
		
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			Account account = ( Account ) TestFactory.createSObject(
					new Account(
							RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
									.get( 'Filiale' ).getRecordTypeId(),
							Filialart__c = 'DHL-Paketshop'
					),
					true
			);
			
			Qualityinformation__c qualitaetsinformation = new Qualityinformation__c(
					RecordTypeId = Schema.SObjectType.Qualityinformation__c.getRecordTypeInfosByDeveloperName()
							.get( 'Wartezeitrisiko' ).getRecordTypeId(),
					Filiale__c = account.Id
			);
			insert qualitaetsinformation;
			
			Wartezeitrisiko__c wartezeitrisiko = new Wartezeitrisiko__c(
					Qualitaetsinformation__c = qualitaetsinformation.Id,
					Calendarweek__c = 1,
					Year__c = 2020,
					Risiko__c = 100
			);
			insert wartezeitrisiko;
			
			Test.startTest();
			String response = WartezeitrisikoDataCtrl.loadData( qualitaetsinformation.Id, 1, 1, 2020 );
			
			Test.stopTest();
			
			WartezeitrisikoDataCtrl.Dataset instance = ( WartezeitrisikoDataCtrl.Dataset ) JSON.deserialize( response, WartezeitrisikoDataCtrl.Dataset.class );
			System.assertEquals('["1"]', instance.labels);
			System.assertEquals('["100"]', instance.datas[0].detail);
		}
	}
}