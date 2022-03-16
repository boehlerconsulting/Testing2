/**
 *@author       Mats Böhler
 *@created      03.03.2021
 *
 *
 *@description  BestellblattLieferantCtrlTest
 *
 *
 *@changelog    03.03.2021 Mats Böhler  - Created
 *              
 * 
 */
@IsTest
private class BestellblattLieferantCtrlTest {
	
	@IsTest
	static void testInitKuehnert () {
		
		Account account = createAccounts( 1 )[ 0 ];
		createBaseProductStructure( account.Id, null, 'Firma Kühnert' );
		
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
		Test.stopTest();
		
		System.assertEquals( account.Id, instance.recordId );
	}
	
	@IsTest
	static void testInitDHLSolutions () {
		
		Account account = createAccounts( 1 )[ 0 ];
		createBaseProductStructure( account.Id, null, 'Lieferant DHL-Solutions' );
		
		Test.startTest();
		EinrichtungsprozessCtrl instance = ( EinrichtungsprozessCtrl )
				JSON.deserialize( EinrichtungsprozessCtrl.init( account.Id, false, false, false ), EinrichtungsprozessCtrl.class );
		PageReference pageReference = Page.BestellblattLieferant;
		pageReference.getParameters().put( 'id', instance.process.Id );
		pageReference.getParameters().put( 'variant', 'DHL-Solutions' );
		pageReference.getParameters().put( 'process', '' );
		Test.setCurrentPage( pageReference );
		BestellblattLieferantCtrl ctrl = new BestellblattLieferantCtrl( pageReference );
		ctrl = new BestellblattLieferantCtrl();
		ctrl.getContentType();
		ctrl.getVersion();
		Test.stopTest();
		
		System.assertEquals( account.Id, instance.recordId );
	}
	
	@IsTest
	static void testInitEK () {
		
		Account account = createAccounts( 1 )[ 0 ];
		createBaseProductStructure( account.Id, null, 'EK' );
		
		Test.startTest();
		EinrichtungsprozessCtrl instance = ( EinrichtungsprozessCtrl )
				JSON.deserialize( EinrichtungsprozessCtrl.init( account.Id, false, false, false ), EinrichtungsprozessCtrl.class );
		PageReference pageReference = Page.BestellblattLieferant;
		pageReference.getParameters().put( 'id', instance.process.Id );
		pageReference.getParameters().put( 'variant', 'EK' );
		pageReference.getParameters().put( 'process', '' );
		Test.setCurrentPage( pageReference );
		BestellblattLieferantCtrl ctrl = new BestellblattLieferantCtrl( pageReference );
		ctrl = new BestellblattLieferantCtrl();
		ctrl.getContentType();
		ctrl.getVersion();
		Test.stopTest();
		
		System.assertEquals( account.Id, instance.recordId );
	}
	
	@IsTest
	static void testInitSpedition () {
		
		Account account = createAccounts( 1 )[ 0 ];
		createBaseProductStructure( account.Id, null, 'Spedition' );
		
		Test.startTest();
		EinrichtungsprozessCtrl instance = ( EinrichtungsprozessCtrl )
				JSON.deserialize( EinrichtungsprozessCtrl.init( account.Id, false, false, false ), EinrichtungsprozessCtrl.class );
		PageReference pageReference = Page.BestellblattLieferant;
		pageReference.getParameters().put( 'id', instance.process.Id );
		pageReference.getParameters().put( 'variant', 'Spedition' );
		pageReference.getParameters().put( 'process', '' );
		Test.setCurrentPage( pageReference );
		BestellblattLieferantCtrl ctrl = new BestellblattLieferantCtrl( pageReference );
		ctrl = new BestellblattLieferantCtrl();
		ctrl.getContentType();
		ctrl.getVersion();
		Test.stopTest();
		
		System.assertEquals( account.Id, instance.recordId );
	}
	
	@IsTest
	static void testInitGeTBot () {
		
		Account account = createAccounts( 1 )[ 0 ];
		createBaseProductStructure( account.Id, null, 'Firma Kühnert' );
		
		Test.startTest();
		EinrichtungsprozessCtrl instance = ( EinrichtungsprozessCtrl )
				JSON.deserialize( EinrichtungsprozessCtrl.init( account.Id, false, false, false ), EinrichtungsprozessCtrl.class );
		PageReference pageReference = Page.BestellblattLieferant;
		pageReference.getParameters().put( 'id', instance.process.Id );
		pageReference.getParameters().put( 'variant', 'GeT-Bot' );
		pageReference.getParameters().put( 'process', '' );
		Test.setCurrentPage( pageReference );
		BestellblattLieferantCtrl ctrl = new BestellblattLieferantCtrl( pageReference );
		ctrl = new BestellblattLieferantCtrl();
		ctrl.getContentType();
		ctrl.getVersion();
		Test.stopTest();
		
		System.assertEquals( account.Id, instance.recordId );
	}
	
	@IsTest
	static void testInitErsatz () {
		
		Account account = createAccounts( 1 )[ 0 ];
		createBaseProductStructure( account.Id, ' in Ersatzbestellung', 'Firma Kühnert' );
		
		Test.startTest();
		EinrichtungsprozessCtrl instance = ( EinrichtungsprozessCtrl )
				JSON.deserialize( EinrichtungsprozessCtrl.init( account.Id, false, false, false ), EinrichtungsprozessCtrl.class );
		PageReference pageReference = Page.BestellblattLieferant;
		pageReference.getParameters().put( 'id', instance.process.Id );
		pageReference.getParameters().put( 'variant', 'GeT-Bot' );
		pageReference.getParameters().put( 'process', 'Ersatzbestellung' );
		Test.setCurrentPage( pageReference );
		BestellblattLieferantCtrl ctrl = new BestellblattLieferantCtrl( pageReference );
		ctrl = new BestellblattLieferantCtrl();
		ctrl.getContentType();
		ctrl.getVersion();
		Test.stopTest();
		
		System.assertEquals( account.Id, instance.recordId );
	}
	
	@IsTest
	static void testInitZusatz () {
		
		Account account = createAccounts( 1 )[ 0 ];
		createBaseProductStructure( account.Id, 'in Zusätzliche Bestellung', 'Firma Kühnert' );
		
		Test.startTest();
		EinrichtungsprozessCtrl instance = ( EinrichtungsprozessCtrl )
				JSON.deserialize( EinrichtungsprozessCtrl.init( account.Id, false, false, false ), EinrichtungsprozessCtrl.class );
		PageReference pageReference = Page.BestellblattLieferant;
		pageReference.getParameters().put( 'id', instance.process.Id );
		pageReference.getParameters().put( 'variant', 'GeT-Bot' );
		pageReference.getParameters().put( 'process', 'Zusätzliche Bestellung' );
		Test.setCurrentPage( pageReference );
		BestellblattLieferantCtrl ctrl = new BestellblattLieferantCtrl( pageReference );
		ctrl = new BestellblattLieferantCtrl();
		ctrl.getContentType();
		ctrl.getVersion();
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
				Menge__c = 1
		);
		insert thekeAusstattung;
		
		Filialausstattung__c frachtAusstattung = new Filialausstattung__c(
				Filiale__c = accountId,
				Vorgemerkt__c = vorgemerkt,
				Produkt__c = fracht.Id,
				Produktoption__c = produktoptionLevelTwo.Id,
				Produktbuendeloption__c = produktoptionLevelOne.Id,
				Produktbuendel__c = thekeAusstattung.Id,
				Menge__c = 1
		);
		insert frachtAusstattung;
	}
}