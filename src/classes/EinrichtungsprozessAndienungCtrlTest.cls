/**
 *@author       Mats Böhler
 *@created      22.03.2021
 *
 *
 *@description  EnrichtungsprozessAndienungCtrlTest
 *
 *
 *@changelog    22.03.2021 Mats Böhler  - Created
 *              
 * 
 */
@IsTest
private class EinrichtungsprozessAndienungCtrlTest {
	
	@IsTest
	static void testInit () {
		
		Account account = createAccounts( 1 )[ 0 ];
		
		Test.startTest();
		EinrichtungsprozessAndienungCtrl instance = ( EinrichtungsprozessAndienungCtrl )
				JSON.deserialize( EinrichtungsprozessAndienungCtrl.init( account.Id ), EinrichtungsprozessAndienungCtrl.class );
		EinrichtungsprozessAndienungCtrl.getDocumentUrl( account.Id );
		EinrichtungsprozessAndienungCtrl.saveDocument( instance.process.Id );
		Test.stopTest();
		
		System.assertEquals( account.Id, instance.recordId );
	}
	
	private static List<Account> createAccounts ( Integer quantity ) {
		
		return ( List<Account> ) TestFactory.createSObjectList(
				new Account(
						Vertragsbetreuende_Einheit__c = insertOrgEDP().Id,
						NL_Brief__c = 'NL München'
				),
				quantity,
				true
		);
	}
	
	private static OrgE_DP__c insertOrgEDP () {
		
		OrgE_DP__c orgEDP = new OrgE_DP__c(
				Aussenstellen_Ma__c = UserInfo.getUserId()
		);
		insert orgEDP;
		return orgEDP;
	}
}