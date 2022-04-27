/**
 *@author       Mats Böhler
 *@created      16.04.2019
 *@version      1.0
 *@since        45.0
 *
 *
 *@description  HW_Stammdatensammler_LC_T
 *
 *
 *@changelog    16.04.2019 Mats Böhler  - Created
 *              
 * 
 */
@IsTest
private class HW_Stammdatensammler_LC_T {
	/* todo*/
	@IsTest
	static void testFirstDataLoad () {
		
		Lead lo_Lead = createLead();
		
		Test.startTest();
		
		String lv_StateString = HW_Stammdatensammler_LC.loadData( lo_Lead.Id, false );
		
		Test.stopTest();
		
		System.assertEquals( null, lv_StateString );
	}
	
	@IsTest
	static void testFirstDataFnaeLoad () {
		
		Account lo_partner = createAccount();
		
		Filialnetzaenderung__c lo_fnae = createFilialnetzaenderung( lo_partner );
		
		Lead lo_Lead = createLead();
		lo_Lead.Filialnetzaenderung__c = lo_fnae.Id;
		update lo_Lead;
		
		Test.startTest();
		
		String lv_StateString = HW_Stammdatensammler_LC.loadData( lo_Lead.Id, false );
		
		Test.stopTest();
		
		System.assertEquals( null, lv_StateString );
	}
	
	@IsTest
	static void testSecondDataLoad () {
		
		Lead lo_Lead = createLead();
		
		Test.startTest();
		
		HW_Stammdatensammler_LC.loadData( lo_Lead.Id, false );
		String lv_StateString = HW_Stammdatensammler_LC.loadData( lo_Lead.Id, false );
		
		Test.stopTest();
		
		HW_Stammdatensammler_LC.State lo_State = ( HW_Stammdatensammler_LC.State )
				JSON.deserialize( lv_StateString, HW_Stammdatensammler_LC.State.class );
		
		System.assertNotEquals( null, lo_State );
	}
	
	@IsTest
	static void testSaveSteps () {
		
		Lead lo_Lead = createLead();
		
		Test.startTest();
		
		HW_Stammdatensammler_LC.loadData( lo_Lead.Id, false );
		String lv_StateString = HW_Stammdatensammler_LC.loadData( lo_Lead.Id, false );
		HW_Stammdatensammler_LC.State lo_State = ( HW_Stammdatensammler_LC.State )
				JSON.deserialize( lv_StateString, HW_Stammdatensammler_LC.State.class );
		HW_Stammdatensammler_LC.saveSteps( JSON.serialize( lo_State.steps ) );
		
		Test.stopTest();
		
		System.assertNotEquals( null, lo_State.steps );
	}
	
	@IsTest
	static void testSaveSObject () {
		
		Lead lo_Lead = createLead();
		
		Test.startTest();
		
		HW_Stammdatensammler_LC.loadData( lo_Lead.Id, false );
		String lv_StateString = HW_Stammdatensammler_LC.loadData( lo_Lead.Id, false );
		HW_Stammdatensammler_LC.State lo_State = ( HW_Stammdatensammler_LC.State )
				JSON.deserialize( lv_StateString, HW_Stammdatensammler_LC.State.class );
		Account lo_Account = [ SELECT Id FROM Account LIMIT 1 ];
		HW_Stammdatensammler_LC.saveSObject( JSON.serialize( lo_Account ), new List<String> {
				'Id'
		}, new List<String> {
				'Id'
		}, lo_Account.Id );
		
		Test.stopTest();
		
		System.assertNotEquals( null, lo_State );
	}
	
	@IsTest
	static void testSaveDocument () {
		
		User interfaceUser = TestUser.create( TestUser.UserType.ADMIN );
		interfaceUser.IstSchnittstellenbenutzer__c = true;
		update interfaceUser;
		
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			Lead lo_Lead = createLead();
			
			Test.startTest();
			HW_Stammdatensammler_LC.loadData( lo_Lead.Id, false );
			Account lo_Account = [ SELECT Id FROM Account LIMIT 1 ];
			HW_Stammdatensammler_LC.saveDocument( lo_Account.Id, 'HW_Selbstauskunft', 'pdf', 'false' );
			Test.stopTest();
		}
	}
	
	@IsTest
	static void testForCoverage () {
		
		User interfaceUser = TestUser.create( TestUser.UserType.ADMIN );
		interfaceUser.IstSchnittstellenbenutzer__c = true;
		update interfaceUser;
		
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			Filialnetzaenderung__c filialnetzaenderung = createFilialnetzaenderung(  createAccount() );
			
			Lead lead = createLead();
			lead.Filialnetzaenderung__c = filialnetzaenderung.Id;
			lead.Formataenderung__c = true;
			update lead;
			
			Test.startTest();
			HW_Stammdatensammler_LC.loadData( lead.Id, false );
			HW_Stammdatensammler_LC.loadData( lead.Id, true );
			Account account = [ SELECT Id FROM Account LIMIT 1 ];
			HW_Stammdatensammler_LC.getDocumentUrl( account.Id, 'HW_Selbstauskunft', 'pdf', 'false' );
			HW_Stammdatensammler_LC.validateAstId( account.Id );
			Test.stopTest();
		}
	}
	
	private static Lead createLead () {
		Lead lo_Lead = new Lead(
				LastName = 'Test',
				Company = 'Test',
				PostalCode = '12345',
				RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName()
						.get( 'Interessent' ).getRecordTypeId()
		);
		insert lo_Lead;
		return lo_Lead;
	}
	
	private static OrgE_DP__c insertOrgEDP () {
		
		OrgE_DP__c orgEDP = new OrgE_DP__c(
				Aussenstellen_Ma__c = UserInfo.getUserId(),
				Koordinator__c = UserInfo.getUserId(),
				OrgE_DP_Name__c = String.valueOf( Math.random() ),
				MA_ASt_PuDS__c = UserInfo.getUserId(),
				MA_ASt_EK__c = UserInfo.getUserId()
		);
		insert orgEDP;
		return orgEDP;
	}
	
	private static Account createAccount () {
		
		Account account = ( Account ) TestFactory.createSObject(
				new Account(
						Vertragsbetreuende_Einheit__c = insertOrgEDP().Id,
						GL__c = insertOrgEDP().Id,
						RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
								.get( 'Filiale_Dummy' ).getRecordTypeId(),
						Filialart__c = 'DHL-Paketshop'
				),
				true
		);
		return account;
	}
	private static Filialnetzaenderung__c createFilialnetzaenderung ( Account account ) {
		
		Filialnetzaenderung__c filialnetzaenderung = new Filialnetzaenderung__c(
				Schliessung_avisiert_fuer__c = Date.today(),
				Filiale_Filialpartner__c = account.Id,
				Wunschformat__c = 'Partner-Filiale (OZ 84)'
		);
		insert filialnetzaenderung;
		return filialnetzaenderung;
	}
	
	@IsTest
	static void testResetFirstLoad () {
		Account lo_Account = new Account( Name = 'UTest' );
		insert lo_Account;
		Lead ld = createLead();
		Contract con = new Contract(
				Name = 'Vertrag SDS',
				Lead__c = ld.Id,
				AccountId = lo_Account.Id,
				StartDate = Date.today(),
				SDS_Helper_FirstRun__c = true,
				ContractTerm = 48,
				RecordTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByDeveloperName()
						.get( 'Partnerfiliale_Vertrag' ).getRecordTypeId()
		);
		insert con;
		
		Boolean isFirstRun;
		Test.startTest();
		isFirstRun = HW_Stammdatensammler_LC.resetFirstRunHelper( JSON.serialize( con ) );
		Test.stopTest();
		
		System.assertEquals( false, isFirstRun );
		System.assertEquals( false, [ SELECT Id, SDS_Helper_FirstRun__c FROM Contract WHERE Id = :con.Id ].SDS_Helper_FirstRun__c );
	}
}