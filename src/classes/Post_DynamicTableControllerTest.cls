/**
 *@author       Mats Böhler <mats.boehler@boehlerconsulting.com>
 *@created      07.12.2018
 *@version      1.0
 *@since        44.0
 *
 *
 *@description  Post_DynamicTableControllerTest
 *
 *
 *@changelog    07.12.2018 Mats Böhler <mats.boehler@boehlerconsulting.com> - Created
 *              
 * 
 */
@IsTest
private class Post_DynamicTableControllerTest {
	
	static testMethod void testInitializeComponent () {
		
		Post_TestTools.erzeugeRechteEinstellungenAdmin( UserInfo.getProfileId() );
		Account LO_Filiale = createFiliale();
		List< Event > LL_Ereignisse = createEreignisse( LO_Filiale );
		List< Task > LL_Aufgaben = createAufgaben( LO_Filiale );
		
		Test.startTest();
		Post_DynamicTableController.getColumnMetadata('Task', new List<String>{'Id','Subject'}, new List<String>{'Id','Subject'}, new List<String>{'Id','Subject'}, new List<String>(), new List<String>());
		Post_DynamicTableController.getColumnMetadata('Event', new List<String>{'Id','Subject'}, new List<String>{'Id','Subject'}, new List<String>{'Id','Subject'}, new List<String>(), new List<String>{'Subject:STRING'});
		try {
			Post_DynamicTableController.getTotalRecords(LO_Filiale.Id, 'AG', 'OrgE', 'Task');
			Post_DynamicTableController.getTaskRecords(LO_Filiale.Id, 'AG', 'OrgE', 'Id', 'ASC');
			Post_DynamicTableController.getEventRecords(LO_Filiale.Id, 'AG', 'OrgE', 'Id', 'ASC');
			Post_DynamicTableController.getTotalRecords(LO_Filiale.Id, 'AG', 'OrgE', 'TEST');
		}
		catch ( Exception e ) {
			
		}
		Map<String, SObjectField> sObjectFieldsByStrings = Schema.getGlobalDescribe().get( 'Task' ).getDescribe().fields.getMap();
		new Post_DynamicTableController.ColumnMetadata('', 'Task', 'Account.Id').populateRelationshipFieldDescribe( '', 'Account.Id'.split( '\\.' ), sObjectFieldsByStrings);
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
	
	private static List< Event > createEreignisse( Account PO_Filiale ) {
		List< Event > LL_Ereignisse = new List< Event >();
		for( Integer i = 1; i <= 20; i++ ) {
			Event LO_Ereignis = new Event(
					WhatId = PO_Filiale.Id,
					Subject = 'Subject',
					ActivityDateTime = DateTime.now().addDays( i ),
					DurationInMinutes = 60
			);
			LL_Ereignisse.add( LO_Ereignis );
		}
		insert( LL_Ereignisse );
		
		return LL_Ereignisse;
	}
	
	private static List< Task > createAufgaben( Account PO_Filiale ) {
		List< Task > LL_Aufgaben = new List< Task >();
		for( Integer I = 1; i <= 20; i++ ) {
			Task LO_Aufgabe = new Task(
					WhatId = PO_Filiale.Id,
					Subject = 'Subject',
					ActivityDate = Date.today()
			);
			LL_Aufgaben.add( LO_Aufgabe );
		}
		insert( LL_Aufgaben );
		
		return LL_Aufgaben;
	}
}