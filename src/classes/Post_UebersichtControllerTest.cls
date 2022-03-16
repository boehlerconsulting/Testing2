/**
 *@author       Mats Böhler <mats.boehler@boehlerconsulting.com>
 *@created      07.12.2018
 *@version      1.0
 *@since        44.0
 *
 *
 *@description  Post_UebersichtControllerTest
 *
 *
 *@changelog    07.12.2018 Mats Böhler <mats.boehler@boehlerconsulting.com> - Created
 *              
 * 
 */
@IsTest
private class Post_UebersichtControllerTest {
	
	static testMethod void testInitializeComponent () {
		
		Post_TestTools.erzeugeRechteEinstellungenAdmin( UserInfo.getProfileId() );
		Account LO_Filiale = createFiliale();
		
		Test.startTest();
		Post_UebersichtController.initialize( LO_Filiale.Id, '', 'Task' );
		Post_UebersichtController.initialize( LO_Filiale.Id, '', 'Event' );
		Post_UebersichtController.initialize( null, 'AG', 'Task' );
		Post_UebersichtController.initialize( null, 'AN', 'Task' );
		Post_UebersichtController.getFilterCriteria ( LO_Filiale.Id, '', '', 'Task' );
		Post_UebersichtController.getFilterCriteria ( LO_Filiale.Id, '', '', 'Event' );
		Post_UebersichtController.getFilterCriteria ( null, 'AG', '', 'Task' );
		Post_UebersichtController.getFilterCriteria ( null, 'AN', '', 'Task' );
		List<String> recordTypesTask = Post_UebersichtController.fetchRecordTypeValues ( 'Task' );
		Post_UebersichtController.getRecordTypeIds ( 'Task', recordTypesTask[0] );
		List<String> recordTypesEvent = Post_UebersichtController.fetchRecordTypeValues ( 'Event' );
		Post_UebersichtController.getRecordTypeIds ( 'Event', recordTypesEvent[0] );
		Test.stopTest();
	}
	
	private static Account createFiliale () {
		OrgE_DP__c LO_OrgE = new OrgE_DP__c(
				Name = 'Gebiet 1',
				Koordinator__c = UserInfo.getUserId()
		);
		insert( LO_OrgE );
		Account LO_Filiale = new Account(
				Name = 'Filiale 1',
				Ast_ID__c = '12345',
				GL__c = LO_OrgE.Id
		);
		insert LO_Filiale;
		return LO_Filiale;
	}
}