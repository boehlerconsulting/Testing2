/**
 *@author       Mats Böhler
 *@created      24.05.2021
 *
 *
 *@description  BestellvorschauVMCtrl
 *
 *
 *@changelog    24.05.2021 Mats Böhler  - Created
 *              
 * 
 */
public with sharing class BestellvorschauVMCtrl extends EinrichtungsDokumentBase {
	
	private Map<String, List<Option>> optionsByParentProductOptionId = new Map<String, List<Option>>();
	private Integer highestProductStructureLevel = 0;
	private List<Option> optionsOneLevel = new List<Option>();
	public Boolean hasMissingValues = false;
	
	public BestellvorschauVMCtrl () {
		currentPage = ApexPages.currentPage();
		initialize();
	}
	
	public BestellvorschauVMCtrl ( PageReference page ) {
		currentPage = page;
		initialize();
	}
	
	public String getTitle () {
		switch on process {
			when 'Ersatzbestellung' {
				return 'Auftrag Ersatzbestellung durch VM';
			}
			when 'Zusätzliche Bestellung' {
				return 'Auftrag Zusatzbestellung durch VM';
			}
			when 'Teilabbau' {
				return 'Auftrag Teilabbau durch VM';
			}
			when 'Filialschließung' {
				return 'Auftrag Schließung durch VM';
			}
			when else {
				return 'Auftrag Filialausstattung durch VM';
			}
		}
	}
	
	public String getBestellgrund () {
		return process == '' ? getRecord().Geschaeftsvorfall__c : process;
	}
	
	public Boolean getIsAbbau () {
		return process == 'Teilabbau' || process == 'Filialschließung';
	}
	
	public Boolean getIsErsatz () {
		return process == 'Ersatzbestellung';
	}
	
	public Boolean getIsZusatz () {
		return process == 'Zusätzliche Bestellung';
	}
	
	public Boolean getIsNeubestellung () {
		return process == '';
	}
	
	protected override void initialize () {
		
		loadData();
		process = currentPage.getParameters().get( 'process' );
		loadCategories();
	}
	
	protected override String getFileName () {
		
		switch on process {
			when 'Ersatzbestellung' {
				return 'VM_Bestellvorschau_Ersatz_'
						+ einrichtungsprozess.Filiale__r.ASt_Name__c;
			}
			when 'Zusätzliche Bestellung' {
				return 'VM_Bestellvorschau_Zusatz_'
						+ einrichtungsprozess.Filiale__r.ASt_Name__c;
			}
			when 'Teilabbau' {
				return 'VM_Auftrag_Teilabbau_'
						+ einrichtungsprozess.Filiale__r.ASt_Name__c;
			}
			when 'Filialschließung' {
				return 'VM_Auftrag_Rückbau_'
						+ einrichtungsprozess.Filiale__r.ASt_Name__c;
			}
			when else {
				return 'VM_Bestellvorschau_'
						+ einrichtungsprozess.Filiale__r.ASt_Name__c;
			}
		}
	}
	
	private void loadCategories () {
		
		categories = new List<Category>();
		
		for ( Filialausstattung__c option : loadFirstLevelProducts( buildTopLevelQuery() ) ) {
			if ( option.Menge_Wiedereinsatzfaehig__c == null && getIsAbbau() ) {
				hasMissingValues = true;
			}
			addOption( option );
		}
		
		for ( String categoryTitle : produktoptionenByCategories.keySet() ) {
			Category category = new Category( categoryTitle );
			
			for ( Filialausstattung__c produktoption : produktoptionenByCategories.get( categoryTitle ) ) {
				Option option = new Option(
						produktoption, null
				);
				category.products.add(
						option
				);
			}
			categories.add( category );
		}
		if ( !getIsAbbau() ) {
			loadProductStructure( productOptionByOptionId );
		}
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
				'AND Produktbuendel__c = NULL ';
		
		query += addProcessFilter();
		query += 'ORDER BY Produktoption__r.Nummerierung__c ASC NULLS LAST';
		return query;
	}
	
	private String addProcessFilter () {
		
		switch on process {
			when 'Ersatzbestellung' {
				return 'AND Vorgemerkt__c = \'in Ersatzbestellung\' ';
			}
			when 'Zusätzliche Bestellung' {
				return 'AND Vorgemerkt__c = \'in Zusätzliche Bestellung\' ';
			}
			when 'Teilabbau' {
				return 'AND (Vorgemerkt__c = \'in Abbau\' OR Vorgemerkt__c = \'in Abbau zusätzlich\') ';
			}
			when 'Filialschließung' {
				return 'AND (Vorgemerkt__c = \'in Abbau\' OR Vorgemerkt__c = \'in Abbau zusätzlich\') ';
			}
			when else {
				return 'AND Vorgemerkt__c = NULL ';
			}
		}
	}
	
	private void buildProductStructure ( List<Option> options ) {
		
		for ( Option option : options ) {
			
			optionsOneLevel.add( option );
			
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
		productBundleOptionIds.remove(null);
		
		while ( keepLoading ) {
			
			Map<String, List<Filialausstattung__c>> produktoptionenByParentProductOptionId = loadOptionsByParentProductOptionIds( productBundleOptionIds );
			productBundleOptionIds = new Set<String>();
			for ( String parentProductOptionId : produktoptionenByParentProductOptionId.keySet() ) {
				
				for ( Filialausstattung__c produktoption : produktoptionenByParentProductOptionId.get( parentProductOptionId ) ) {
					
					produktoption.Name += ' (Zubehör)';
					Option option = new Option(
							produktoption,null
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
			productBundleOptionIds.remove(null);
			keepLoading = productBundleOptionIds.size() > 0;
			productLevel++;
		}
	}
	
	private Map<String, List<Filialausstattung__c>> loadOptionsByParentProductOptionIds ( Set<String> productBundleOptionIds ) {
		if ( productBundleOptionIds.isEmpty()) {
			return new Map<String, List<Filialausstattung__c>>();
		}
		Map<String, List<Filialausstattung__c>> optionsByParentProductOptionId = new Map<String, List<Filialausstattung__c>>();
		Id accountId = einrichtungsprozess.Filiale__c;
		
		String query = 'SELECT ' + QUERY_FIELDS + ' ' +
				'FROM Filialausstattung__c ' +
				'WHERE Filiale__c = :accountId ' +
				'AND Produktbuendeloption__c IN :productBundleOptionIds ';
		
		query += addProcessFilter();
		query += 'ORDER BY Produktoption__r.Nummerierung__c ASC NULLS LAST';
		
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
	
	protected override String getFileExtension () {
		return '.pdf';
	}
}