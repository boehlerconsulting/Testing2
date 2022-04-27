/**
 *@author       Mats Böhler
 *@created      04.05.2021
 *
 *
 *@description  OeffnungszeitServiceTest
 *
 *
 *@changelog    04.05.2021 Mats Böhler  - Created
 *              
 * 
 */
@IsTest
private class OeffnungszeitServiceTest {
	/* todo*/
	@IsTest
	static void testGetDefinitionsByAccountId () {
		
		Account account = createAccounts( 1 )[ 0 ];
		
		Test.startTest();
		List<Oeffnungszeiten__c> oeffnungszeitens = OeffnungszeitService.getDefinitionsByAccountId( account.Id );
		Test.stopTest();
		
		System.assertEquals( 7, oeffnungszeitens.size() );
	}

	@IsTest
	static void testGetDefinitions () {
		Account account = createAccounts( 1 )[ 0 ];

		Test.startTest();
		Map<String,List<Oeffnungszeiten__c>> oeffnungszeitensByCat = OeffnungszeitService.createDefinitions( account.Id, new List<String> { 'Filialöffnungszeiten' } );
		Test.stopTest();

		System.assertEquals( 1, oeffnungszeitensByCat.size() );
		System.assert(oeffnungszeitensByCat.containsKey('Filialöffnungszeiten'));
		System.assertEquals( 7, oeffnungszeitensByCat.get('Filialöffnungszeiten').size() );
	}

	private static List<Account> createAccounts ( Integer quantity ) {
		
		return ( List<Account> ) TestFactory.createSObjectList(
				new Account(
				),
				quantity,
				true
		);
	}
}