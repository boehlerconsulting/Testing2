/**
 *@author       Mats Böhler
 *@created      03.03.2021
 *
 *
 *@description  BestellblattLieferantCtrl
 *
 *
 *@changelog    03.03.2021 Mats Böhler  - Created
 *              
 * 
 */
public with sharing class BestellblattLieferantCtrl extends EinrichtungsDokumentBase {
	
	private String variant = '';
	private Map<String, List<Option>> optionsByParentProductOptionId = new Map<String, List<Option>>();
	private Integer highestProductStructureLevel = 0;
	private List<Option> optionsOneLevel = new List<Option>();
	private Map<Id, Decimal> priceByProductId = new Map<Id, Decimal>();
	
	public BestellblattLieferantCtrl () {
		currentPage = ApexPages.currentPage();
		initialize();
	}
	
	public BestellblattLieferantCtrl ( PageReference page ) {
		currentPage = page;
		initialize();
	}
	
	public String getVersion () {
		return variant;
	}
	
	protected override void initialize () {
		
		loadData();
		variant = currentPage.getParameters().get( 'variant' );
		process = currentPage.getParameters().get( 'process' );
		loadPricesByProductId();
		loadCategories();
	}
	
	protected override String getFileName () {
		switch on process {
			when 'Ersatzbestellung' {
				return 'Bestellung_Ersatz_' + variant + '_'
						+ einrichtungsprozess.Filiale__r.ASt_Name__c;
			}
			when 'Zusätzliche Bestellung' {
				return 'Bestellung_Zusatz_' + variant + '_'
						+ einrichtungsprozess.Filiale__r.ASt_Name__c;
			}
			when else {
				return 'Bestellung_' + variant + '_'
						+ einrichtungsprozess.Filiale__r.ASt_Name__c;
			}
		}
	}
	
	private void loadCategories () {
		
		categories = new List<Category>();
		
		for ( Filialausstattung__c option : loadFirstLevelProducts( buildTopLevelQuery() ) ) {
			
			addOption( option );
		}
		
		for ( String categoryTitle : produktoptionenByCategories.keySet() ) {
			Category category = new Category( categoryTitle );
			
			for ( Filialausstattung__c produktoption : produktoptionenByCategories.get( categoryTitle ) ) {
				Option option = new Option(
						produktoption,
						priceByProductId.containsKey( produktoption.Produkt__c )
								? priceByProductId.get( produktoption.Produkt__c )
								: null
				);
				category.products.add(
						option
				);
			}
			categories.add( category );
		}
		
		loadProductStructure( productOptionByOptionId );
		for ( Category category : categories ) {
			optionsOneLevel = new List<Option>();
			buildProductStructure( category.products );
			category.products = optionsOneLevel;
		}
		List<Category> categoriesWithProducts = new List<Category>();
		for ( Category category : categories ) {
			if ( category.products.size() > 0 ) {
				categoriesWithProducts.add( category );
			}
		}
		categories = categoriesWithProducts;
	}
	
	private String buildTopLevelQuery () {
		
		String query = 'SELECT ' + QUERY_FIELDS + ' ' +
				'FROM Filialausstattung__c ' +
				'WHERE Filiale__c = :accountId ' +
				'AND Produktbuendel__c = NULL ' +
				'AND Produktoption__r.Product__r.Family = \'Neubestellung\' ';
		
		query += addProcessFilter();
		query += 'ORDER BY Produktoption__r.Nummerierung__c ASC NULLS LAST';
		return query;
	}
	
	private String getAdditionalFilter () {
		
		switch on variant {
			when 'Kühnert' {
				return 'AND Produkt__r.Lieferant__c IN :kuehnertLieferanten ';
			}
			when 'DHL-Solutions' {
				return 'AND Produkt__r.Lieferant__c = :dhlSolutions ';
			}
			when 'EK' {
				return 'AND Produkt__r.Lieferant__c LIKE \'%EK%\' ';
			}
			when 'Spedition' {
				return 'AND Produkt__r.Lagerprodukt__c = TRUE AND Produktoption__r.Produktbuendeloption__c = NULL ';
			}
			when 'GeT-Bot' {
				return 'AND Produkt__r.Lieferant__c LIKE \'Firma%\' ';
			}
			when else {
				return '';
			}
		}
	}
	
	private String addProcessFilter () {
		
		switch on process {
			when 'Ersatzbestellung' {
				return 'AND Vorgemerkt__c = \'in Ersatzbestellung\' ';
			}
			when 'Zusätzliche Bestellung' {
				return 'AND Vorgemerkt__c = \'in Zusätzliche Bestellung\' ';
			}
			when else {
				return 'AND Vorgemerkt__c = NULL ';
			}
		}
	}
	
	private void buildKuehnert ( Option option ) {
		if ( option.product.Produkt__r.Lieferant__c == 'Lieferant Fa. Kühnert'
				|| option.product.Produkt__r.Lieferant__c == 'Firma Kühnert' ) {
			
			optionsOneLevel.add( option );
		}
		else if ( ( option.product.Produkt__r.Lieferant__c == 'Lieferant Fa. Kühnert'
				|| option.product.Produkt__r.Lieferant__c == 'Firma Kühnert' )
				&& option.product.Produkt__r.Lagerprodukt__c
				&& option.product.Produktbuendel__c == null ) {
			
			optionsOneLevel.add( option );
		}
		else {
			//Sonarqube --> do nothing
		}
	}
	
	private void buildDhlSolutions ( Option option ) {
		if ( option.product.Produkt__r.Lieferant__c == 'Lieferant DHL-Solutions' ) {
			
			optionsOneLevel.add( option );
		}
		else if ( option.product.Produkt__r.Lieferant__c == 'Lieferant DHL-Solutions'
				&& option.product.Produkt__r.Lagerprodukt__c
				&& option.product.Produktbuendel__c == null ) {
			
			optionsOneLevel.add( option );
		}
		else {
			//Sonarqube --> do nothing
		}
	}
	
	private void buildEk ( Option option ) {
		if ( option.product.Produkt__r.Lieferant__c != null
				&& option.product.Produkt__r.Lieferant__c.startsWith( 'EK' ) ) {
			
			optionsOneLevel.add( option );
		}
		else if ( option.product.Produkt__r.Lieferant__c != null
				&& option.product.Produkt__r.Lieferant__c.startsWith( 'EK' )
				&& option.product.Produkt__r.Lagerprodukt__c
				&& option.product.Produktbuendel__c == null ) {
			
			optionsOneLevel.add( option );
		}
		else {
			//Sonarqube --> do nothing
		}
	}
	
	private void buildSpedition ( Option option ) {
		if ( option.product.Produkt__r.Lagerprodukt__c == true
				&& option.product.Produktbuendel__c == null ) {
			
			optionsOneLevel.add( option );
		}
	}
	
	private void buildGetBot ( Option option ) {
		if ( option.product.Produkt__r.Lieferant__c != null
				&& option.product.Produkt__r.Lieferant__c.startsWith( 'Firma' ) ) {
			
			optionsOneLevel.add( option );
		}
		else if ( option.product.Produkt__r.Lieferant__c != null
				&& option.product.Produkt__r.Lieferant__c.startsWith( 'Firma' )
				&& option.product.Produkt__r.Lagerprodukt__c
				&& option.product.Produktbuendel__c == null ) {
			
			optionsOneLevel.add( option );
		}
		else {
			//Sonarqube --> do nothing
		}
	}
	
	private void buildProductStructure ( List<Option> options ) {
		
		for ( Option option : options ) {
			
			switch on variant {
				when 'Kühnert' {
					buildKuehnert( option );
				}
				when 'DHL-Solutions' {
					buildDhlSolutions( option );
				}
				when 'EK' {
					buildEk( option );
				}
				when 'Spedition' {
					buildSpedition( option );
				}
				when 'GeT-Bot' {
					buildGetBot( option );
				}
				when else {
					//Sonarqube --> do nothing
				}
			}
			if ( optionsByParentProductOptionId.containsKey( option.product.Produktoption__c ) ) {
				
				option.options.addAll( optionsByParentProductOptionId.get( option.product.Produktoption__c ) );
				
				if ( option.options.size() > 0 ) {
					option.hasOptions = true;
					buildProductStructure( option.options );
				}
			}
		}
	}
	
	private void loadProductStructure ( Map<String, Filialausstattung__c> productOptionByOptionId ) {
		
		Boolean keepLoading = true;
		Integer productLevel = 1;
		Set<String> productBundleOptionIds = productOptionByOptionId.keySet();
		
		while ( keepLoading ) {
			
			Map<String, List<Filialausstattung__c>> produktoptionenByParentProductOptionId = loadOptionsByParentProductOptionIds( productBundleOptionIds );
			productBundleOptionIds = new Set<String>();
			for ( String parentProductOptionId : produktoptionenByParentProductOptionId.keySet() ) {
				
				for ( Filialausstattung__c produktoption : produktoptionenByParentProductOptionId.get( parentProductOptionId ) ) {
					
					Option option = new Option(
							produktoption,
							priceByProductId.containsKey( produktoption.Produkt__c )
									? priceByProductId.get( produktoption.Produkt__c )
									: null
					);
					
					if ( optionsByParentProductOptionId.containsKey( parentProductOptionId ) ) {
						optionsByParentProductOptionId.get( parentProductOptionId ).add( option );
					}
					else {
						optionsByParentProductOptionId.put( parentProductOptionId, new List<Option> {
								option
						} );
					}
					productBundleOptionIds.add( produktoption.Produktoption__c );
				}
			}
			highestProductStructureLevel = productLevel;
			keepLoading = produktoptionenByParentProductOptionId.keySet().size() > 0;
			productLevel++;
		}
	}
	
	private Map<String, List<Filialausstattung__c>> loadOptionsByParentProductOptionIds ( Set<String> productBundleOptionIds ) {
		Map<String, List<Filialausstattung__c>> optionsByParentProductOptionId = new Map<String, List<Filialausstattung__c>>();
		
		Id accountId = einrichtungsprozess.Filiale__c;
		
		String query = 'SELECT ' + QUERY_FIELDS + ' ' +
				'FROM Filialausstattung__c ' +
				'WHERE Filiale__c = :accountId ' +
				'AND Produktbuendeloption__c IN :productBundleOptionIds ';
		
		query += getAdditionalFilter();
		query += addProcessFilter();
		query += 'ORDER BY Produktoption__r.Nummerierung__c ASC NULLS LAST';
		
		List<String> kuehnertLieferanten = new List<String>();
		kuehnertLieferanten.add( 'Lieferant Fa. Kühnert' );
		kuehnertLieferanten.add( 'Firma Kühnert' );
		String dhlSolutions = 'Lieferant DHL-Solutions';
		
		for ( Filialausstattung__c option : Database.query( query ) ) {
			
			if ( optionsByParentProductOptionId.containsKey( option.Produktbuendeloption__c ) ) {
				optionsByParentProductOptionId.get( option.Produktbuendeloption__c ).add( option );
			}
			else {
				optionsByParentProductOptionId.put( option.Produktbuendeloption__c, new List<Filialausstattung__c> {
						option
				} );
			}
		}
		
		return optionsByParentProductOptionId;
	}
	
	private void loadPricesByProductId () {
		
		for ( PricebookEntry pricebookEntry : [
				SELECT
						Product2Id,
						UnitPrice
				FROM PricebookEntry
				WHERE Pricebook2.IsStandard = TRUE
		] ) {
			
			priceByProductId.put( pricebookEntry.Product2Id, pricebookEntry.UnitPrice );
		}
	}
}