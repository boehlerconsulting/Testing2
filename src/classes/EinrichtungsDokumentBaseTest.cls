/**
 *@author       Mats Böhler
 *@created      28.04.2021
 *
 *
 *@description  EinrichtungsDokumentBaseTest
 *
 *
 *@changelog    28.04.2021 Mats Böhler  - Created
 *              
 * 
 */
@IsTest
private class EinrichtungsDokumentBaseTest {
	
	@IsTest
	static void testInit () {
		
		Account account = createAccounts( 1 )[ 0 ];
		
		Test.startTest();
		EinrichtungsprozessCtrl instance = ( EinrichtungsprozessCtrl )
				JSON.deserialize( EinrichtungsprozessCtrl.init( account.Id, false, false, false ), EinrichtungsprozessCtrl.class );
		PageReference pageReference = Page.BestellblattLieferant;
		pageReference.getParameters().put( 'id', instance.process.Id );
		pageReference.getParameters().put( 'variant', 'Kühnert' );
		pageReference.getParameters().put( 'process', '' );
		Test.setCurrentPage( pageReference );
		BestellblattLieferantCtrl ctrl = new BestellblattLieferantCtrl( pageReference );
		ctrl = new BestellblattLieferantCtrl();
		ctrl.getContentType();
		ctrl.getVersion();
		ctrl.getRecord();
		ctrl.getTermin();
		ctrl.getWunschlieferuhrzeit();
		ctrl.getSheetName();
		ctrl.saveAsFile(new List<Id>{account.Id});
		Test.stopTest();
		
		System.assertEquals( account.Id, instance.recordId );
	}
	
	private static List<Account> createAccounts ( Integer quantity ) {
		
		return ( List<Account> ) TestFactory.createSObjectList(
				new Account(
						Vertragsbetreuende_Einheit__c = insertOrgEDP().Id,
						NL_Brief__c = 'Bonn'
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