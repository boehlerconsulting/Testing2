/**
 *@author       Mats Böhler
 *@created      28.04.2021
 *
 *
 *@description  AuftragRueckbauCtrlTest
 *
 *
 *@changelog    28.04.2021 Mats Böhler  - Created
 *              
 * 
 */
@IsTest
private class AuftragRueckbauCtrlTest {
	
	@IsTest
	static void testInitTeilabbau () {
		
		Account account = createAccounts( 1 )[ 0 ];
		createAbbauAusstattung(account.Id);
		
		Test.startTest();
		EinrichtungsprozessCtrl instance = ( EinrichtungsprozessCtrl )
				JSON.deserialize( EinrichtungsprozessCtrl.init( account.Id, false, true, false ), EinrichtungsprozessCtrl.class );
		PageReference pageReference = Page.AuftragRueckbau;
		pageReference.getParameters().put( 'id', instance.process.Id );
		pageReference.getParameters().put( 'process', 'Teilabbau' );
		Test.setCurrentPage( pageReference );
		AuftragRueckbauCtrl ctrl = new AuftragRueckbauCtrl( pageReference );
		ctrl = new AuftragRueckbauCtrl();
		ctrl.getContentType();
		Test.stopTest();
		
		System.assertEquals( account.Id, instance.recordId );
	}
	
	@IsTest
	static void testInitFilialschliessung () {
		
		Account account = createAccounts( 1 )[ 0 ];
		createAbbauAusstattung(account.Id);
		
		Test.startTest();
		EinrichtungsprozessCtrl instance = ( EinrichtungsprozessCtrl )
				JSON.deserialize( EinrichtungsprozessCtrl.init( account.Id, false, true, false ), EinrichtungsprozessCtrl.class );
		PageReference pageReference = Page.AuftragRueckbau;
		pageReference.getParameters().put( 'id', instance.process.Id );
		pageReference.getParameters().put( 'process', 'Filialschließung' );
		Test.setCurrentPage( pageReference );
		AuftragRueckbauCtrl ctrl = new AuftragRueckbauCtrl( pageReference );
		ctrl = new AuftragRueckbauCtrl();
		ctrl.getContentType();
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
	
	private static void createAbbauAusstattung(Id accountId){
		insert new Filialausstattung__c(
				Filiale__c = accountId,
				Vorgemerkt__c = 'in Abbau'
		);
	}
}