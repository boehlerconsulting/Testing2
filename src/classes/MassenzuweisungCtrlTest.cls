/**
 *@author       Mats Böhler
 *@created      21.09.2020
 *
 *
 *@description  MassenzuweisungCtrlTest
 *
 *
 *@changelog    21.09.2020 Mats Böhler  - Created
 *              
 * 
 */
@IsTest
private class MassenzuweisungCtrlTest {
	
	@IsTest
	static void testSearchOwners () {
		
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			Test.startTest();
			List<LookupSearchResult> lookupSearchResults = MassenzuweisungCtrl.searchOwners(
					'test',
					new List<String>()
			);
			Test.stopTest();
			
			System.assertEquals( 1, lookupSearchResults.size() );
		}
	}
	
	@IsTest
	static void testAccountLoad () {
		
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			Account account = createAccount();
			
			Test.startTest();
			MassenzuweisungCtrl instance = ( MassenzuweisungCtrl ) JSON.deserialize(
					MassenzuweisungCtrl.loadData(
							new List<String> {
									'Account', '', '', '', '', '', '', 'true', 'Name', 'asc', '100'
							}
					), MassenzuweisungCtrl.class );
			Test.stopTest();
			
			System.assertEquals( 1, instance.data.size() );
			System.assertEquals( account.Id, instance.data[ 0 ].Id );
		}
	}
	
	@IsTest
	static void testAccountSave () {
		
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			Account account = createAccount();
			List<String> filters = new List<String> {
					'Account', '', '', '', '', '', '', 'true', 'Name', 'asc', '100'
			};
			
			Test.startTest();
			
			MassenzuweisungCtrl instance = ( MassenzuweisungCtrl ) JSON.deserialize(
					MassenzuweisungCtrl.loadData(
							filters
					), MassenzuweisungCtrl.class );
			instance.data[ 0 ].put( 'OwnerId', UserInfo.getUserId() );
			MassenzuweisungCtrl.saveRecords( filters, JSON.serialize( instance.data ), instance.data[ 0 ].Id );
			Test.stopTest();
			
			account = [ SELECT Id, OwnerId FROM Account WHERE Id = :account.Id LIMIT 1 ];
			
			System.assertEquals( UserInfo.getUserId(), account.OwnerId );
		}
	}
	
	@IsTest
	static void testTaskLoad () {
		User testUser = TestUser.create( TestUser.UserType.ADMIN );
		System.runAs( testUser ) {
			
			Account account = createAccount();
			Task task = createTask( account.Id );
			task.OwnerId = testUser.Id;
			update task;
			
			Test.startTest();
			MassenzuweisungCtrl instance = ( MassenzuweisungCtrl ) JSON.deserialize(
					MassenzuweisungCtrl.loadData(
							new List<String> {
									'Task', '', '', '', '', '', 'true', 'Aufgabenart__c', 'asc', '100'
							}
					), MassenzuweisungCtrl.class );
			Test.stopTest();
			
			System.assertEquals( 1, instance.data.size() );
			System.assertEquals( task.Id, instance.data[ 0 ].Id );
		}
	}
	
	@IsTest
	static void testTaskSave () {
		
		User testUser = TestUser.create( TestUser.UserType.ADMIN );
		System.runAs( testUser ) {
			
			Account account = createAccount();
			Task task = createTask( account.Id );
			task.OwnerId = testUser.Id;
			update task;
			update task;
			List<String> filters = new List<String> {
					'Task', '', '', '', '', '', 'true', 'Aufgabenart__c', 'asc', '100'
			};
			
			Test.startTest();
			
			MassenzuweisungCtrl instance = ( MassenzuweisungCtrl ) JSON.deserialize(
					MassenzuweisungCtrl.loadData(
							filters
					), MassenzuweisungCtrl.class );
			instance.data[ 0 ].put( 'OwnerId', UserInfo.getUserId() );
			MassenzuweisungCtrl.saveRecords( filters, JSON.serialize( instance.data ), instance.data[ 0 ].Id );
			Test.stopTest();
			
			task = [ SELECT Id, OwnerId FROM Task WHERE Id = :task.Id LIMIT 1 ];
			
			System.assertEquals( UserInfo.getUserId(), task.OwnerId );
		}
	}
	
	private static Account createAccount () {
		
		Account account = ( Account ) TestFactory.createSObject(
				new Account(
						GL__c = insertOrgEDP( 'VL 2001 Köln' ).Id
				),
				true
		);
		return account;
	}
	
	private static Task createTask ( Id whatID ) {
		
		Task task = ( Task ) TestFactory.createSObject(
				new Task(
						WhatId = whatID,
						OwnerId = UserInfo.getUserId()
				),
				true
		);
		return task;
	}
	
	private static OrgE_DP__c insertOrgEDP ( String name ) {
		
		OrgE_DP__c orgEDP = new OrgE_DP__c(
				Name = name,
				OrgE_DP_Name__c = name,
				Aussenstellen_Ma__c = UserInfo.getUserId(),
				Koordinator__c = UserInfo.getUserId()
		);
		insert orgEDP;
		return orgEDP;
	}
}