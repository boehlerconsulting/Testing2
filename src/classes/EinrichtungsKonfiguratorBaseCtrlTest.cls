/**
 *@author       Mats Böhler
 *@created      06.05.2021
 *
 *
 *@description  EinrichtungsKonfiguratorBaseCtrlTest
 *
 *
 *@changelog    06.05.2021 Mats Böhler  - Created
 *              
 * 
 */
@IsTest
private class EinrichtungsKonfiguratorBaseCtrlTest {
	
	@IsTest
	static void testInit () {
		
		Account account = createAccounts( 1 )[ 0 ];
		createBaseProductStructure( account.Id, null, 'Firma Kühnert' );
		
		Test.startTest();
		EinrichtungsprozessCtrl.init( account.Id, false, false, false );
		EinrichtungsKonfiguratorBaseCtrl.InitializationResponse response = ( EinrichtungsKonfiguratorBaseCtrl.InitializationResponse )
				JSON.deserialize( EinrichtungsKonfiguratorCtrl.init(
						'95',
						'A',
						'1',
						'XL',
						account.Id,
						'Neubestellung'
				), EinrichtungsKonfiguratorBaseCtrl.InitializationResponse.class );
		List<EinrichtungsKonfiguratorBaseCtrl.Option> options = response.categories[ 0 ].products;
		Einrichtungsprozess__c process = [ SELECT Id FROM Einrichtungsprozess__c LIMIT 1 ];
		EinrichtungsKonfiguratorCtrl.initWithNewVariant(
				'95',
				'A',
				'1',
				'XL',
				account.Id,
				process.Id,
				'Neubestellung'
		);
		delete [ SELECT Id FROM Filialausstattung__c ];
		EinrichtungsKonfiguratorCtrl.saveOptionsState(
				account.Id,
				JSON.serialize( options ),
				JSON.serialize( new List<EinrichtungsKonfiguratorBaseCtrl.Option> {
				} ),
				'Neubestellung'
		);
		EinrichtungsKonfiguratorCtrl.saveOptionQuantity(
				account.Id,
				JSON.serialize( options[0] )
		);
		EinrichtungsKonfiguratorCtrl.saveOptionsState(
				account.Id,
				JSON.serialize( new List<EinrichtungsKonfiguratorBaseCtrl.Option> {
				} ),
				JSON.serialize( options ),
				'Neubestellung'
		);
		Test.stopTest();
		
		System.assertNotEquals( null, response );
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
				Name = 'Neubestellung',
				IsActive = true
		);
		product2s.add( neubestellung );
		
		Product2 theke = new Product2(
				Family = 'Theke',
				Name = 'Theke',
				Lieferant__c = lieferant,
				Lagerprodukt__c = lieferant == 'Spedition',
				IsActive = true
		);
		product2s.add( theke );
		
		Product2 fracht = new Product2(
				Family = 'Fracht',
				Name = 'Theke',
				Lieferant__c = lieferant,
				IsActive = true
		);
		product2s.add( fracht );
		
		insert product2s;
		
		Produktoption__c produktoptionLevelOne = new Produktoption__c(
				Product__c = neubestellung.Id,
				Option__c = theke.Id,
				OZ__c = '95',
				Vertriebssegment__c = 'A',
				AnzahlSchalter__c = 1,
				Variante__c = 'XL',
				Standard__c = true,
				Menge__c = 1
		);
		insert produktoptionLevelOne;
		
		Produktoption__c produktoptionLevelTwo = new Produktoption__c(
				Product__c = theke.Id,
				Option__c = fracht.Id,
				Produktbuendeloption__c = produktoptionLevelOne.Id,
				Standard__c = true,
				Menge__c = 1
		);
		insert produktoptionLevelTwo;
	}
}