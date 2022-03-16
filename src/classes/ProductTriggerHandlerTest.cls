/**
 *@author       Mats Böhler
 *@created      30.08.2021
 *
 *
 *@description  ProductTriggerHandlerTest
 *
 *
 *@changelog    30.08.2021 Mats Böhler  - Created
 *              
 * 
 */
@IsTest
private class ProductTriggerHandlerTest {
	
	@IsTest
	static void testDelete () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			insert new Product2(
					Name = 'Test'
			);
			
			Test.startTest();
			try {
				delete [ SELECT Id FROM Product2 ];
			}
			catch ( Exception e ) {
				System.assert( e.getMessage().contains( 'Produkte dürfen nicht gelöscht werden.' ) );
			}
			Test.stopTest();
		}
	}
}