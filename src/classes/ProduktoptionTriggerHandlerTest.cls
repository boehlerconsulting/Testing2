/**
 *@author       Mats Böhler
 *@created      16.08.2021
 *
 *
 *@description  ProduktoptionTriggerHandlerTest
 *
 *
 *@changelog    16.08.2021 Mats Böhler  - Created
 *              
 * 
 */
@IsTest
private class ProduktoptionTriggerHandlerTest {
	
	@IsTest
	static void testDelete () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			insert new Produktoption__c();
			
			Test.startTest();
			try {
				delete [ SELECT Id FROM Produktoption__c ];
			}
			catch ( Exception e ) {
				System.assert( e.getMessage().contains( 'Produktoptionen dürfen nur über den "Löschen" Button gelöscht werden' ) );
			}
			Test.stopTest();
		}
	}
}