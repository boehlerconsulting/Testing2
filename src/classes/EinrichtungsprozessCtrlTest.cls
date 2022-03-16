/**
 *@author       Mats Böhler
 *@created      05.02.2021
 *
 *
 *@description  EinrichtungsprozessCtrlTest
 *
 *
 *@changelog    05.02.2021 Mats Böhler  - Created
 *              
 * 
 */
@IsTest
private class EinrichtungsprozessCtrlTest {
	
	@IsTest
	static void testInitStandard () {
		
		Account account = createAccounts( 1 )[ 0 ];
		
		Test.startTest();
		EinrichtungsprozessCtrl instance = ( EinrichtungsprozessCtrl )
				JSON.deserialize( EinrichtungsprozessCtrl.init( account.Id, false, false, false ), EinrichtungsprozessCtrl.class );
		EinrichtungsprozessCtrl.saveAbbauProcess( instance.process.Id, '' );
		EinrichtungsprozessCtrl.triggerBestellung( account.Id, instance.process.Id );
		EinrichtungsprozessCtrl.triggerNachbesserung( account.Id, instance.process.Id, '' );
		EinrichtungsprozessCtrl.triggerNachbesserungAbbau( account.Id, instance.process.Id, '' );
		EinrichtungsprozessCtrl.saveProcessState( instance.process.Id, 0 );
		EinrichtungsprozessCtrl.copyFieldsFromAndienung( instance.process.Id );
		Test.stopTest();
		
		System.assertEquals( account.Id, instance.recordId );
	}
	
	@IsTest
	static void testInitErsatzZusatz () {
		
		Account account = createAccounts( 1 )[ 0 ];
		
		Test.startTest();
		EinrichtungsprozessCtrl instance = ( EinrichtungsprozessCtrl )
				JSON.deserialize( EinrichtungsprozessCtrl.init( account.Id, true, false, true ), EinrichtungsprozessCtrl.class );
		EinrichtungsprozessCtrl.triggerBestellungErsatz( account.Id, instance.process.Id );
		EinrichtungsprozessCtrl.triggerBestellungZusatz( account.Id, instance.process.Id );
		EinrichtungsprozessCtrl.triggerNachbesserungErsatz( account.Id, instance.process.Id, '' );
		EinrichtungsprozessCtrl.triggerNachbesserungZusatz( account.Id, instance.process.Id, '' );
		Test.stopTest();
		
		System.assertEquals( account.Id, instance.recordId );
	}
	
	@IsTest
	static void testDocumentGenerationTeilabbau () {
		
		Account account = createAccounts( 1 )[ 0 ];
		createBaseProductStructure( account.Id, 'in Abbau', 'Firma Kühnert' );
		
		Test.startTest();
		EinrichtungsprozessCtrl instance = ( EinrichtungsprozessCtrl )
				JSON.deserialize( EinrichtungsprozessCtrl.init( account.Id, false, false, false ), EinrichtungsprozessCtrl.class );
		EinrichtungsprozessCtrl.getDocumentUrl( instance.process.Id, '', 'Teilabbau' );
		EinrichtungsprozessCtrl.getPreviewUrl( instance.process.Id, 'Teilabbau' );
		EinrichtungsprozessCtrl.saveDocument( account.Id, instance.process.Id, null, 'Teilabbau' );
		Test.stopTest();
		
		System.assertEquals( account.Id, instance.recordId );
	}
	
	@IsTest
	static void testDocumentGenerationFilialschliessung () {
		
		Account account = createAccounts( 1 )[ 0 ];
		createBaseProductStructure( account.Id, 'in Abbau', 'Firma Kühnert' );
		
		Test.startTest();
		EinrichtungsprozessCtrl instance = ( EinrichtungsprozessCtrl )
				JSON.deserialize( EinrichtungsprozessCtrl.init( account.Id, false, false, false ), EinrichtungsprozessCtrl.class );
		EinrichtungsprozessCtrl.getDocumentUrl( instance.process.Id, '', 'Filialschließung' );
		EinrichtungsprozessCtrl.saveDocument( account.Id, instance.process.Id, null, 'Filialschließung' );
		Test.stopTest();
		
		System.assertEquals( account.Id, instance.recordId );
	}
	
	@IsTest
	static void testDocumentGenerationKuehnert () {
		
		Account account = createAccounts( 1 )[ 0 ];
		createBaseProductStructure( account.Id, null, 'Firma Kühnert' );
		
		Test.startTest();
		EinrichtungsprozessCtrl instance = ( EinrichtungsprozessCtrl )
				JSON.deserialize( EinrichtungsprozessCtrl.init( account.Id, false, false, false ), EinrichtungsprozessCtrl.class );
		EinrichtungsprozessCtrl.getDocumentUrl( instance.process.Id, 'Kühnert', '' );
		EinrichtungsprozessCtrl.saveDocument( account.Id, instance.process.Id, 'Kühnert', '' );
		Test.stopTest();
		
		System.assertEquals( account.Id, instance.recordId );
	}
	
	@IsTest
	static void testDocumentGenerationKuehnertErsatz () {
		
		Account account = createAccounts( 1 )[ 0 ];
		createBaseProductStructure( account.Id, 'in Ersatzbestellung', 'Firma Kühnert' );
		
		Test.startTest();
		EinrichtungsprozessCtrl instance = ( EinrichtungsprozessCtrl )
				JSON.deserialize( EinrichtungsprozessCtrl.init( account.Id, false, false, false ), EinrichtungsprozessCtrl.class );
		EinrichtungsprozessCtrl.getDocumentUrl( instance.process.Id, 'Kühnert', 'Ersatzbestellung' );
		EinrichtungsprozessCtrl.saveDocument( account.Id, instance.process.Id, 'Kühnert', 'Ersatzbestellung' );
		Test.stopTest();
		
		System.assertEquals( account.Id, instance.recordId );
	}
	
	@IsTest
	static void testDocumentGenerationKuehnertZusatz () {
		
		Account account = createAccounts( 1 )[ 0 ];
		createBaseProductStructure( account.Id, 'in Zusätzliche Bestellung', 'Firma Kühnert' );
		
		Test.startTest();
		EinrichtungsprozessCtrl instance = ( EinrichtungsprozessCtrl )
				JSON.deserialize( EinrichtungsprozessCtrl.init( account.Id, false, false, false ), EinrichtungsprozessCtrl.class );
		EinrichtungsprozessCtrl.getDocumentUrl( instance.process.Id, 'Kühnert', 'Zusätzliche Bestellung' );
		EinrichtungsprozessCtrl.saveDocument( account.Id, instance.process.Id, 'Kühnert', 'Zusätzliche Bestellung' );
		Test.stopTest();
		
		System.assertEquals( account.Id, instance.recordId );
	}
	
	@IsTest
	static void testDocumentGenerationVorschau () {
		
		Account account = createAccounts( 1 )[ 0 ];
		createBaseProductStructure( account.Id, 'in Zusätzliche Bestellung', 'Firma Kühnert' );
		
		Test.startTest();
		EinrichtungsprozessCtrl instance = ( EinrichtungsprozessCtrl )
				JSON.deserialize( EinrichtungsprozessCtrl.init( account.Id, false, false, false ), EinrichtungsprozessCtrl.class );
		EinrichtungsprozessCtrl.saveDocumentVorschau( account.Id, instance.process.Id, 'Zusätzliche Bestellung' );
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
	
	private static void createBaseProductStructure ( Id accountId, String vorgemerkt, String lieferant ) {
		
		List<Product2> product2s = new List<Product2>();
		
		Product2 neubestellung = new Product2(
				Family = 'Neubestellung',
				Name = 'Neubestellung'
		);
		product2s.add( neubestellung );
		
		Product2 theke = new Product2(
				Family = 'Theke',
				Name = 'Theke',
				Lieferant__c = lieferant,
				Lagerprodukt__c = lieferant == 'Spedition'
		);
		product2s.add( theke );
		
		Product2 fracht = new Product2(
				Family = 'Fracht',
				Name = 'Theke',
				Lieferant__c = lieferant
		);
		product2s.add( fracht );
		
		insert product2s;
		
		Produktoption__c produktoptionLevelOne = new Produktoption__c(
				Product__c = neubestellung.Id,
				Option__c = theke.Id
		);
		insert produktoptionLevelOne;
		
		Produktoption__c produktoptionLevelTwo = new Produktoption__c(
				Product__c = theke.Id,
				Option__c = fracht.Id,
				Produktbuendeloption__c = produktoptionLevelOne.Id,
				Standard__c = true
		);
		insert produktoptionLevelTwo;
		
		Filialausstattung__c thekeAusstattung = new Filialausstattung__c(
				Filiale__c = accountId,
				Vorgemerkt__c = vorgemerkt,
				Produkt__c = theke.Id,
				Produktoption__c = produktoptionLevelOne.Id,
				Menge__c = 1,
				Menge_Wiedereinsatzfaehig__c = 0
		);
		insert thekeAusstattung;
		
		Filialausstattung__c frachtAusstattung = new Filialausstattung__c(
				Filiale__c = accountId,
				Vorgemerkt__c = vorgemerkt,
				Produkt__c = fracht.Id,
				Produktoption__c = produktoptionLevelTwo.Id,
				Produktbuendeloption__c = produktoptionLevelOne.Id,
				Produktbuendel__c = thekeAusstattung.Id,
				Menge__c = 1,
				Menge_Wiedereinsatzfaehig__c = 0
		);
		insert frachtAusstattung;
	}
}