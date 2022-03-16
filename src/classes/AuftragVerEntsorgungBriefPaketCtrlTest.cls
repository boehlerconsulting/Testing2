/**
 *@author       Mats Böhler
 *@created      22.02.2021
 *
 *
 *@description  AuftragVerEntsorgungBriefPaketCtrlTest
 *
 *
 *@changelog    22.02.2021 Mats Böhler  - Created
 *              
 * 
 */
@IsTest
private class AuftragVerEntsorgungBriefPaketCtrlTest {
	
	@IsTest
	static void testInit () {
		
		Account account = createAccounts( 1 )[ 0 ];
		
		Test.startTest();
		EinrichtungsprozessAndienungCtrl instance = ( EinrichtungsprozessAndienungCtrl )
				JSON.deserialize( EinrichtungsprozessAndienungCtrl.init( account.Id ), EinrichtungsprozessAndienungCtrl.class );
		PageReference pageReference = Page.AuftragVerEntsorgungBriefPaket;
		pageReference.getParameters().put( 'id', instance.process.Id );
		Test.setCurrentPage( pageReference );
		AuftragVerEntsorgungBriefPaketCtrl ctrl = new AuftragVerEntsorgungBriefPaketCtrl( pageReference );
		ctrl = new AuftragVerEntsorgungBriefPaketCtrl();
		ctrl.getContentType();
		ctrl.getMontag();
		ctrl.getDienstag();
		ctrl.getMittwoch();
		ctrl.getDonnerstag();
		ctrl.getFreitag();
		ctrl.getSamstag();
		ctrl.getSonntag();
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