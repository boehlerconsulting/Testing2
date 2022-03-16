/**
 *@author       Mats Böhler
 *@created      28.04.2021
 *
 *
 *@description  EinrichtungsprozessBaseCtrlTest
 *
 *
 *@changelog    28.04.2021 Mats Böhler  - Created
 *              
 * 
 */
@IsTest
private class EinrichtungsprozessBaseCtrlTest {
	
	@IsTest
	static void testInit () {
		
		Account account = createAccounts( 1 )[ 0 ];
		
		Test.startTest();
		EinrichtungsprozessCtrl instance = ( EinrichtungsprozessCtrl )
				JSON.deserialize( EinrichtungsprozessCtrl.init( account.Id, false, false, false ), EinrichtungsprozessCtrl.class );
		EinrichtungsprozessAndienungCtrl.init( account.Id );
		Test.stopTest();
		
		System.assertEquals( account.Id, instance.recordId );
	}
	
	@IsTest
	static void testSaveValue () {
		
		Account account = createAccounts( 1 )[ 0 ];
		
		Test.startTest();
		EinrichtungsprozessBaseCtrl.saveFieldValue( account.Id, 'Website', 'text', 'Test' );
		Test.stopTest();
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